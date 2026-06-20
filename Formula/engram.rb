# typed: false
# frozen_string_literal: true

require "json"

class Engram < Formula
  desc "Local memory daemon for AI agents — embedded PostgreSQL + pgvector + ONNX embeddings"
  homepage "https://github.com/centient-labs/engram-server"
  version "0.43.0"
  # license - TBD

  depends_on :macos
  depends_on arch: :arm64

  url "https://github.com/centient-labs/homebrew-centient/releases/download/engram-v#{version}/engram-macos-arm64.tar.gz"
  sha256 "654eb506aa47868050101f2b7dfedc1bcbb870b70fddd7483c668a1b5b51ce37"

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
