# typed: false
# frozen_string_literal: true

class Centient < Formula
  desc "Context engineering MCP server for Claude Code with local memory"
  homepage "https://github.com/centient-labs/centient"
  version "0.1.0"
  license "MIT"

  on_macos do
    on_arm do
      url "https://github.com/centient-labs/centient/releases/download/v#{version}/centient-macos-arm64.tar.gz"
      # sha256 "PLACEHOLDER" # Updated by release workflow
    end
    on_intel do
      url "https://github.com/centient-labs/centient/releases/download/v#{version}/centient-macos-x64.tar.gz"
      # sha256 "PLACEHOLDER" # Updated by release workflow
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/centient-labs/centient/releases/download/v#{version}/centient-linux-arm64.tar.gz"
      # sha256 "PLACEHOLDER" # Updated by release workflow
    end
    on_intel do
      url "https://github.com/centient-labs/centient/releases/download/v#{version}/centient-linux-x64.tar.gz"
      # sha256 "PLACEHOLDER" # Updated by release workflow
    end
  end

  def install
    bin.install "centient"
    bin.install "engram-local"

    # Install local-ui and its static files if present
    if File.exist?("local-ui")
      bin.install "local-ui"
    end
    if File.directory?("local-ui-dist")
      (share/"centient"/"local-ui-dist").install Dir["local-ui-dist/*"]
    end
  end

  def post_install
    # Create engram data directory
    (var/"engram").mkpath
  end

  def caveats
    <<~EOS
      Centient has been installed!

      QUICK START
      ===========

      1. Start the memory server (runs in background):
         engram-local start

      2. Add to Claude Code MCP settings.

         Run this command to see your current config location:
           claude config

         Add to the "mcpServers" section of your settings file:
         {
           "mcpServers": {
             "centient": {
               "command": "#{HOMEBREW_PREFIX}/bin/centient",
               "args": []
             }
           }
         }

      3. Restart Claude Code to load the MCP server.

      4. (Optional) Open the dashboard:
         local-ui
         Then visit http://localhost:3101

      SERVICES
      ========

      To have engram-local start automatically at login:
        brew services start centient

      To stop the service:
        brew services stop centient

      DATA LOCATION
      =============

      Session data is stored in: ~/.engram/
      Logs are in: ~/.engram/logs/
    EOS
  end

  service do
    run [opt_bin/"engram-local", "start", "--foreground"]
    keep_alive true
    working_dir var/"engram"
    log_path var/"log/engram-local.log"
    error_log_path var/"log/engram-local.log"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/centient --version")
    assert_match version.to_s, shell_output("#{bin}/engram-local --version")
  end
end
