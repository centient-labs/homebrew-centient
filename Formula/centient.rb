# typed: false
# frozen_string_literal: true

class Centient < Formula
  desc "Context engineering MCP server for Claude Code with local memory"
  homepage "https://github.com/centient-labs/centient"
  version "0.1.6"
  # license - TBD

  on_macos do
    on_arm do
      url "https://github.com/centient-labs/homebrew-centient/releases/download/v#{version}/centient-macos-arm64.tar.gz"
      sha256 "b62d3adfa6b582323871835d2ce1d8724c529e3b3edfac69d07112f75dc2e9b3"
    end
    on_intel do
      url "https://github.com/centient-labs/homebrew-centient/releases/download/v#{version}/centient-macos-x64.tar.gz"
      sha256 "43aab3de19dc9e0f3ca89bc32a175ee8d69a90b7ba00234ee2eca9528bdea97f"
    end
  end

  on_linux do
    on_intel do
      url "https://github.com/centient-labs/homebrew-centient/releases/download/v#{version}/centient-linux-x64.tar.gz"
      sha256 "b770a9b007a48f209b44a934f2d94406afceeb553dfaa93a0cb09a495470de88"
    end
  end

  def install
    bin.install "centient"
    bin.install "engram-local"

    # Install embedded PostgreSQL binaries
    if File.directory?("postgres")
      (share/"centient"/"postgres").install Dir["postgres/*"]
      # Make binaries executable
      Dir[share/"centient"/"postgres"/"bin"/"*"].each do |f|
        chmod 0755, f if File.file?(f)
      end
    end

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
