# typed: false
# frozen_string_literal: true

class Centient < Formula
  desc "Context engineering MCP server for Claude Code with local memory"
  homepage "https://github.com/centient-labs/centient"
  version "0.2.13"
  # license - TBD

  on_macos do
    on_arm do
      url "https://github.com/centient-labs/homebrew-centient/releases/download/v#{version}/centient-macos-arm64.tar.gz"
      sha256 "8a23179cdac8b586a600ce0a703565a551a08ff98a9e45c5a134aa044e0e4162"
    end
    on_intel do
      url "https://github.com/centient-labs/homebrew-centient/releases/download/v#{version}/centient-macos-x64.tar.gz"
      sha256 "e7cef446041964c3dcfdb7687fd863c5e4443aed44c74755b7371c3b144c0d00"
    end
  end

  on_linux do
    on_intel do
      url "https://github.com/centient-labs/homebrew-centient/releases/download/v#{version}/centient-linux-x64.tar.gz"
      sha256 "6e3b43567bcd7c24deaff6a575ab5b978a1ae83b22dc1ec5ca5fe3a725b98d96"
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
      # Create required library symlinks from pg-symlinks.json
      symlinks_file = share/"centient"/"postgres"/"pg-symlinks.json"
      if File.exist?(symlinks_file)
        require "json"
        symlinks = JSON.parse(File.read(symlinks_file))
        symlinks.each do |link|
          # Paths in JSON are like "native/lib/..." but we installed to "lib/..."
          source = link["source"].sub("native/", "")
          target = link["target"].sub("native/", "")
          source_path = share/"centient"/"postgres"/source
          target_path = share/"centient"/"postgres"/target
          if File.exist?(source_path) && !File.exist?(target_path)
            ln_s source_path.basename, target_path
          end
        end
      end
    end

    # Install ONNX Runtime for local embeddings (Transformers.js)
    # The dylib is installed alongside the binary so it can be found at runtime
    if File.directory?("onnxruntime")
      # Install to share for the .node file
      (share/"centient"/"onnxruntime").install Dir["onnxruntime/*"]
      # Also copy dylib to bin directory (same dir as binary) for rpath resolution
      Dir["onnxruntime/*.dylib"].each do |f|
        cp f, bin
      end
    end

    # Install Sharp for image processing (required by transformers.js)
    if File.directory?("sharp")
      (share/"centient"/"sharp").install Dir["sharp/*"]
      # Copy dylibs to bin directory for rpath resolution
      Dir["sharp/*.dylib"].each do |f|
        cp f, bin
      end
    end

    # Install centient-web and its static files if present
    if File.exist?("centient-web")
      bin.install "centient-web"
    end
    if File.directory?("centient-web-dist")
      (share/"centient"/"centient-web-dist").install Dir["centient-web-dist/*"]
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
         centient-web
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