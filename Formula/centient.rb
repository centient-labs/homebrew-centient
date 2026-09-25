# typed: false
# frozen_string_literal: true

class Centient < Formula
  desc "Context engineering MCP server for Claude Code"
  homepage "https://github.com/centient-labs/centient"
  version "0.35.0"
  # license - TBD

  on_macos do
    # macOS is Apple Silicon only — no Intel Mac binary is produced.
    depends_on arch: :arm64

    # Recommend engram for local development (developer machines).
    # Containers and CI can skip engram — centient connects to a remote engram via ENGRAM_URL.
    #
    # Keep the recommended dependency scoped to macOS: engram currently ships
    # only Linux x64, while centient also supports Linux arm64. A remote engram
    # works for both Linux architectures without requiring a local daemon.
    depends_on "centient-labs/centient/engram" => :recommended

    # Nested under on_arm rather than sitting directly in on_macos:
    # FormulaAudit/ComponentsOrder allows only a further on_intel/on_arm
    # selector as a child of on_macos, and `brew style` fails otherwise.
    on_arm do
      url "https://github.com/centient-labs/homebrew-centient/releases/download/centient-v#{version}/centient-macos-arm64.tar.gz"
      sha256 "fb782eb2f4f56b46e09c3f8f2e2b20df16d0981d77de81db3b372b36023de1a9"
    end
  end

  on_linux do
    on_intel do
      url "https://github.com/centient-labs/homebrew-centient/releases/download/centient-v#{version}/centient-linux-x64.tar.gz"
      sha256 "f20ef20f1cacad6426df1514d9358e7f9d0022a0e9bbfd38258210d12f8c3716"
    end

    on_arm do
      url "https://github.com/centient-labs/homebrew-centient/releases/download/centient-v#{version}/centient-linux-arm64.tar.gz"
      sha256 "e24da522c1349e17dcb599f1da21ece0cb6da46d769f9f85fc7e59cad8be5380"
    end
  end

  def install
    bin.install "centient"

    if File.directory?("templates/commands")
      (share/"centient"/"templates"/"commands").install Dir["templates/commands/*.md"]
    end

    if File.directory?("templates/crucible-commands")
      (share/"centient"/"templates"/"crucible-commands").install Dir["templates/crucible-commands/*.md"]
    end
  end

  def caveats
    # SETUP-VS-UPDATE IS A QUESTION ABOUT CENTIENT'S OWN STATE, and only that.
    # It must never key on a DEPENDENCY being present: engram is `:recommended`
    # inside on_macos, so brew installs it BEFORE this formula on a clean
    # machine. Keying on it greeted every first-time macOS user — the default
    # path, not an edge case — with "Upgrade complete! Run centient update",
    # while the `centient setup` they actually needed never printed. A
    # dependency being installed says nothing about whether the dependent has
    # ever run.
    #
    # centient's own state directory is $CENTIENT_HOME, else ~/.centient.
    # centient creates it itself, so it exists only once centient has actually
    # run — exactly the question being asked here.
    centient_home = ENV.fetch("CENTIENT_HOME", nil)
    centient_home = File.join(Dir.home, ".centient") if centient_home.blank?

    if File.directory?(centient_home)
      <<~EOS
        Upgrade complete! Run:
          centient update

        Then restart Claude Code for changes to take effect.
      EOS
    elsif OS.linux?
      <<~EOS
        Centient installed (MCP server only).

        Configure centient to connect to your engram instance:
          export ENGRAM_URL=http://your-engram-host:3100

        Then run:
          centient setup
      EOS
    else
      <<~EOS
        Centient installed (MCP server only).

        For local memory, also install engram:
          brew install centient-labs/centient/engram

        To skip engram (connect to remote):
          export ENGRAM_URL=http://your-engram-host:3100

        Then run:
          centient setup
      EOS
    end
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/centient --version")
  end
end
