# typed: false
# frozen_string_literal: true

class Centient < Formula
  desc "Context engineering MCP server for Claude Code"
  homepage "https://github.com/centient-labs/centient"
  version "0.26.16"
  # license - TBD

  depends_on :macos
  depends_on arch: :arm64

  # Recommend engram for local development (developer machines).
  # Containers and CI can skip engram — centient connects to a remote engram via ENGRAM_URL.
  depends_on "centient-labs/centient/engram" => :recommended

  url "https://github.com/centient-labs/homebrew-centient/releases/download/centient-v#{version}/centient-macos-arm64.tar.gz"
  sha256 "d934326bc7216d290743e62bac1c81def665c504ceb18efffd9cda0f2b707e3f"

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
    engram_installed = Formula["centient-labs/centient/engram"].any_version_installed? rescue false

    base = if engram_installed
      <<~EOS
        Upgrade complete! Run:
          centient update

        Then restart Claude Code for changes to take effect.
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

    base + <<~EOS

      Pre-release channels available:
        brew install centient-labs/centient/centient-beta   # beta/RC releases
        brew install centient-labs/centient/centient-dev    # dev releases
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/centient --version")
  end
end