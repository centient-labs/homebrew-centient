# typed: false
# frozen_string_literal: true

class Centient < Formula
  desc "Context engineering MCP server for Claude Code with local memory"
  homepage "https://github.com/centient-labs/centient"
  version "0.5.0"
  # license - TBD

  on_macos do
    on_arm do
      url "https://github.com/centient-labs/homebrew-centient/releases/download/v#{version}/centient-macos-arm64.tar.gz"
      sha256 "aeb80ded0f65dbfe63e5e370d5a880801ea42e255856b7de92ce71deef17e35e"
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

    # Install command templates to share directory
    if File.directory?("templates/commands")
      (share/"centient"/"templates"/"commands").install Dir["templates/commands/*.md"]
    end
  end

  def post_install
    (var/"engram").mkpath

    claude_dir = Pathname.new(Dir.home)/".claude"
    commands_dir = claude_dir/"commands"
    commands_dir.mkpath

    # 1. Install commands (preserve user customizations)
    source_dir = share/"centient"/"templates"/"commands"
    if source_dir.exist?
      Dir[source_dir/"*.md"].each do |template|
        dest = commands_dir/File.basename(template)
        if dest.exist?
          # Only update if has centient-version header (our managed file)
          next unless dest.read.include?("centient-version:")
        end
        FileUtils.cp(template, dest)
      end
    end

    # 2. Configure MCP server
    settings_path = claude_dir/"settings.json"
    settings = settings_path.exist? ? (JSON.parse(settings_path.read) rescue {}) : {}
    settings["mcpServers"] ||= {}
    settings["mcpServers"]["centient"] = {
      "type" => "stdio",
      "command" => "#{HOMEBREW_PREFIX}/bin/centient",
      "args" => []
    }
    claude_dir.mkpath
    settings_path.write(JSON.pretty_generate(settings) + "\n")
  end

  def caveats
    <<~EOS
      Centient installed and configured!

      RESTART CLAUDE CODE to activate.

      Commands installed to ~/.claude/commands/
      MCP server added to ~/.claude/settings.json

      To uninstall: centient uninstall
      To start memory server: brew services start centient
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