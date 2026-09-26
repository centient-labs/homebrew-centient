# typed: false
# frozen_string_literal: true

require "json"

class Engram < Formula
  desc "Local memory daemon for AI agents — embedded PostgreSQL + pgvector + ONNX embeddings"
  homepage "https://github.com/centient-labs/engram-server"
  version "0.68.0"
  # license - TBD

  # One release serves two platforms, so the url/sha256 pair lives in a
  # selector block per platform rather than at the top level. Both tarballs
  # come from the SAME `engram-v#{version}` release on this tap: engram-server's
  # Makefile builds linux-x64 in `release-artifacts` and its publish.sh attaches
  # `engram-linux-x64.tar.gz` + `checksums-linux-x64.txt` as pre-built assets,
  # so the Linux artifact ships with the release and is verified present on
  # engram-v0.67.8. Only this formula was macOS-only, which is why no Linux
  # host could install it (es#2241).
  #
  # The shape is load-bearing for the release flow, not a style choice.
  # `tap_pr` (release-toolkit lib/tap-pr.sh) bumps a multi-platform formula by
  # pairing each in-scope `url` with the `sha256` that follows it and resolving
  # the pair through the asset the url names — so EVERY platform's digest is
  # bumped from the release's own published checksums. Keeping a top-level
  # macOS digest with Linux tucked below it would render, and then bump only
  # macOS: every later release would ship a stale Linux digest and fail its
  # checksum on Linux alone, on a release that looked complete from every
  # other angle. That per-asset bump is release-toolkit#440 (PR #464); a
  # consumer whose submodule predates it cannot bump this formula.
  #
  # The url/sha256 pair sits one level deeper than the platform selector on
  # purpose: `brew style`'s FormulaAudit/ComponentsOrder cop rejects a `url` or
  # `sha256` written DIRECTLY inside `on_macos`/`on_linux`, and admits them
  # under a nested `on_arm`/`on_intel`.
  #
  # Only the two combinations the release actually builds resolve to a url, and
  # the other two fail at LOAD time rather than with an arch-specific message —
  # measured with Homebrew's own simulator, `SimulateSystem.with(os:, arch:)`:
  #
  #   macos/arm    -> engram-macos-arm64.tar.gz
  #   linux/intel  -> engram-linux-x64.tar.gz
  #   macos/intel  -> FormulaSpecificationError: formula requires at least a URL
  #   linux/arm    -> FormulaSpecificationError: formula requires at least a URL
  #
  # The `depends_on arch:` lines therefore document the supported architecture
  # and gate an install that gets that far; they do NOT dress the two
  # unbuilt combinations in a nicer error, because the missing url is raised
  # first. Serving those platforms is a build question, not a formula one.
  on_macos do
    depends_on arch: :arm64

    on_arm do
      url "https://github.com/centient-labs/homebrew-centient/releases/download/engram-v#{version}/engram-macos-arm64.tar.gz"
      sha256 "efdb12c30bb10966c30bba666fb5af604c666ec742da7f230d6aab32f41e2cd6"
    end
  end

  on_linux do
    depends_on arch: :x86_64

    on_intel do
      url "https://github.com/centient-labs/homebrew-centient/releases/download/engram-v#{version}/engram-linux-x64.tar.gz"
      sha256 "d86b126b331d94d23c45d23c060520059c4a571a715fd2d70793ef7d2b2ffae9"
    end
  end

  def install
    # Install the real binary under the canonical name "engram". The
    # `engram-local` alias is kept as a symlink for backwards-compat with
    # centient's EngramLocalManager and doctor, which historically looked
    # for `engram-local` in PATH. Installing the other way around (real
    # file = engram-local, symlink = engram) caused `engram start` to
    # detach children with `process.execPath` resolving to the real path
    # — so `ps` showed `engram-local start -f`, which obscured which
    # component was running and made per-binary greps confusing.
    bin.install "engram"
    bin.install_symlink "engram" => "engram-local"

    # Install embedded PostgreSQL binaries
    if File.directory?("postgres")
      (share/"engram"/"postgres").install Dir["postgres/*"]
      Dir[share/"engram"/"postgres"/"bin"/"*"].each do |f|
        chmod 0755, f if File.file?(f)
      end
      # Create required library symlinks from pg-symlinks.json
      symlinks_file = share/"engram"/"postgres"/"pg-symlinks.json"
      if File.exist?(symlinks_file)
        begin
          symlinks = JSON.parse(File.read(symlinks_file))
          symlinks.each do |link|
            source = link["source"].sub("native/", "")
            target = link["target"].sub("native/", "")
            next if source.include?("..") || target.include?("..")
            next if source.start_with?("/") || target.start_with?("/")
            source_path = share/"engram"/"postgres"/source
            target_path = share/"engram"/"postgres"/target
            if File.exist?(source_path) && !File.exist?(target_path)
              ln_s source_path.basename, target_path
            end
          end
        rescue JSON::ParserError => e
          opoo "Failed to parse pg-symlinks.json: #{e.message}"
        end
      end
    end

    # Install ONNX Runtime for local embeddings
    if File.directory?("onnx")
      (share/"engram"/"onnx").install Dir["onnx/*"]
    end

    # Install engram-web and static files
    if File.exist?("engram-web")
      bin.install "engram-web"
    end
    # engram-comms — third binary, ship-together (no separate formula).
    # No ONNX bundle for comms (deliberate — comms does no embeddings);
    # it shares engram's bundled PostgreSQL binaries at runtime via the
    # same install-relative resolver (execDir/../share/<channel>/postgres).
    if File.exist?("engram-comms")
      bin.install "engram-comms"
    end
    if File.directory?("engram-web-dist")
      (share/"engram"/"engram-web-dist").install Dir["engram-web-dist/*"]
    end
  end

  def post_install
    (var/"engram").mkpath

    # Symlink shared dir for centient compatibility
    share_link = share/"centient"/"postgres"
    unless File.exist?(share_link)
      (share/"centient").mkpath
      ln_s share/"engram"/"postgres", share_link if File.directory?(share/"engram"/"postgres")
    end
  end

  def caveats
    <<~EOS
      Engram memory daemon installed.

      Start the daemon:
        brew services start engram
        # or: engram-local start

      The daemon listens on:
        REST API:  http://localhost:3100
        PostgreSQL: localhost:5433
        Web UI:    http://localhost:3101

      Data stored in: #{var}/engram
    EOS
  end

  # One `service` block covers both platforms: `brew services` renders this DSL
  # as a launchd plist on macOS and a systemd user unit on Linux, so there is no
  # systemd counterpart to hand-write (es#2241 ask 2). The interpolations are
  # resolved per-host — HOMEBREW_PREFIX differs on Linux — so nothing here is
  # macOS-shaped beyond what Homebrew itself translates.
  service do
    run [opt_bin/"engram-local", "start", "--foreground"]
    keep_alive true
    working_dir var/"engram"
    log_path var/"log/engram.log"
    error_log_path var/"log/engram.log"
    environment_variables ENGRAM_HOME: "#{Dir.home}/.engram",
                          ENGRAM_PORT: "3100",
                          ENGRAM_LOCAL_PORT: "3100",
                          ENGRAM_PG_PORT: "5433",
                          CENTIENT_WEB_PORT: "3101",
                          CENTIENT_SHARE_DIR: "#{HOMEBREW_PREFIX}/share/engram"
  end

  test do
    assert_match(/\d+\.\d+\.\d+/, shell_output("#{bin}/engram-local --version"))
  end
end
