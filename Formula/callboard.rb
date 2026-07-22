# typed: false
# frozen_string_literal: true
#
# publish via an operator-run tap PR (design D7). It is versioned in-repo so
# the shape is reviewed alongside the build recipe; `make publish` uploads the
# release assets and prints the tap-PR steps, it does NOT patch the tap.
#
# On each release the tap PR bumps `version` and `sha256` (from
# dist/checksums-macos-arm64.txt) — nothing else changes.

class Callboard < Formula
  desc "Persona-management flagship daemon — roster, deploy board, agent API + MCP"
  homepage "https://github.com/centient-labs/callboard"
  version "0.5.0"
  # license - TBD

  depends_on :macos
  depends_on arch: :arm64

  url "https://github.com/centient-labs/homebrew-centient/releases/download/callboard-v#{version}/callboard-macos-arm64.tar.gz"
  sha256 "bf577ae850d5eaaeb687780169b9f695ff522fb3e94756a553297a81a5d5254c"

  def install
    # The binary is the server; the UI build is data in share/ (design D3).
    bin.install "callboard"
    (share/"callboard").install "web-dist" if File.directory?("web-dist")
  end

  def post_install
    # launchd chdir's into `working_dir` and writes `log_path`/`error_log_path`
    # (the service block below); neither exists until we create it, and a missing
    # working_dir fails the service at boot. Mirror engram's post_install var
    # handling.
    (var/"callboard").mkpath
    (var/"log").mkpath
  end

  def caveats
    <<~EOS
      callboard daemon installed.

      Start the daemon:
        brew services start callboard
        # or: callboard start

      The daemon listens on:
        Agent HTTP API:  http://127.0.0.1:4110
        Human web UI:    http://127.0.0.1:4111

      It reads personas from engram at http://127.0.0.1:3100 (start engram first).

      Register the MCP service with your agent harness (.mcp.json):
        { "mcpServers": { "callboard": { "type": "stdio",
            "command": "callboard", "args": ["mcp"] } } }
    EOS
  end

  service do
    # opt_bin, not the Cellar path — the launchd program must survive version
    # bumps (resolveStableProgramPath spirit; `-f` runs in the foreground so
    # launchd supervises the real process, not a detached child).
    run [opt_bin/"callboard", "start", "-f"]
    keep_alive true
    working_dir var/"callboard"
    log_path var/"log/callboard.log"
    error_log_path var/"log/callboard.log"
    environment_variables CALLBOARD_PORT: "4110",
                          CALLBOARD_WEB_PORT: "4111",
                          CALLBOARD_HOST: "127.0.0.1",
                          CALLBOARD_SHARE_DIR: "#{HOMEBREW_PREFIX}/share/callboard"
  end

  test do
    assert_match(/\d+\.\d+\.\d+/, shell_output("#{bin}/callboard --version"))
  end
end
