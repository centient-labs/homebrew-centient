# typed: false
# frozen_string_literal: true

require "json"

class Centient < Formula
  desc "Context engineering MCP server for Claude Code with local memory"
  homepage "https://github.com/centient-labs/centient"
  version "0.6.5"
  # license - TBD

  # Currently only macOS ARM64 (Apple Silicon) is supported
  # Intel Mac and Linux builds are disabled in CI
  depends_on :macos
  depends_on arch: :arm64

  url "https://github.com/centient-labs/homebrew-centient/releases/download/v#{version}/centient-macos-arm64.tar.gz"
  sha256 "06a4be85b423b50c72a148b0e6a37135b4b2a4ffbc2015c6987cda076066e5ce"

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
    # Structure: onnx/napi-v3/{platform}/{arch}/ to match onnx-resolver.ts search paths
    if File.directory?("onnx")
      # Install next to binary so onnx-resolver.ts finds it at {execDir}/onnx/...
      (bin/"onnx").install Dir["onnx/*"]
    end

    # Install Sharp for image processing (required by transformers.js)
    if File.directory?("sharp")
      (share/"centient"/"sharp").install Dir["sharp/*"]
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

    # Install command templates to share directory (installed to ~/.claude by centient doctor)
    if File.directory?("templates/commands")
      (share/"centient"/"templates"/"commands").install Dir["templates/commands/*.md"]
    end
  end

  def post_install
    (var/"engram").mkpath
  end

  def caveats
    <<~EOS
      Centient installed!

      Run this to complete setup:
        centient doctor --fix

      This will:
        - Install commands to ~/.claude/commands/
        - Configure MCP server in ~/.claude/settings.json

      Then RESTART CLAUDE CODE to activate.

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