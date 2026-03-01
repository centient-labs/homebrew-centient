# typed: false
# frozen_string_literal: true

require "json"

class CentientATalpha < Formula
  desc "Context engineering MCP server for Claude Code (alpha channel)"
  homepage "https://github.com/centient-labs/centient"
  version "0.0.0-alpha.0"
  # license - TBD

  # Currently only macOS ARM64 (Apple Silicon) is supported
  depends_on :macos
  depends_on arch: :arm64

  url "https://github.com/centient-labs/homebrew-centient/releases/download/v#{version}/centient-macos-arm64.tar.gz"
  sha256 "0000000000000000000000000000000000000000000000000000000000000000"

  conflicts_with "centient", because: "centient and centient@alpha install conflicting binaries"
  conflicts_with "centient@beta", because: "centient@alpha and centient@beta install conflicting binaries"

  def install
    bin.install "centient"
    bin.install "engram"

    # Install embedded PostgreSQL binaries
    if File.directory?("postgres")
      (share/"centient-alpha"/"postgres").install Dir["postgres/*"]
      # Make binaries executable
      Dir[share/"centient-alpha"/"postgres"/"bin"/"*"].each do |f|
        chmod 0755, f if File.file?(f)
      end
      # Create required library symlinks from pg-symlinks.json
      symlinks_file = share/"centient-alpha"/"postgres"/"pg-symlinks.json"
      if File.exist?(symlinks_file)
        begin
          symlinks = JSON.parse(File.read(symlinks_file))
          symlinks.each do |link|
            source = link["source"].sub("native/", "")
            target = link["target"].sub("native/", "")
            # Validate paths don't escape postgres directory
            next if source.include?("..") || target.include?("..")
            next if source.start_with?("/") || target.start_with?("/")
            source_path = share/"centient-alpha"/"postgres"/source
            target_path = share/"centient-alpha"/"postgres"/target
            if File.exist?(source_path) && !File.exist?(target_path)
              ln_s source_path.basename, target_path
            end
          end
        rescue JSON::ParserError => e
          opoo "Failed to parse pg-symlinks.json: #{e.message}"
        end
      end
    end

    # Install ONNX Runtime for local embeddings (Transformers.js)
    if File.directory?("onnx")
      (bin/"onnx").install Dir["onnx/*"]
    end

    # Install centient-web and its static files if present
    if File.exist?("centient-web")
      bin.install "centient-web"
    end
    if File.directory?("centient-web-dist")
      (share/"centient-alpha"/"centient-web-dist").install Dir["centient-web-dist/*"]
    end

    # Install command templates
    if File.directory?("templates/commands")
      (share/"centient-alpha"/"templates"/"commands").install Dir["templates/commands/*.md"]
    end

    # Install crucible command templates
    if File.directory?("templates/crucible-commands")
      (share/"centient-alpha"/"templates"/"crucible-commands").install Dir["templates/crucible-commands/*.md"]
    end
  end

  def post_install
    (var/"engram-alpha").mkpath
  end

  def caveats
    <<~EOS
      Centient ALPHA channel installed.

      WARNING: Alpha builds are UNSTABLE. Expect breaking changes, data loss,
      and incomplete features. Use only for development and early testing.

      Data isolation: alpha uses separate storage to protect your stable data.
        Data directory: ~/.engram-alpha
        API port:       3160
        PostgreSQL:     5460

      To get started:
        ENGRAM_HOME=~/.engram-alpha ENGRAM_PORT=3160 ENGRAM_PG_PORT=5460 centient setup

      To seed data from your stable install:
        cp -r ~/.engram/data ~/.engram-alpha/data

      WARNING: Alpha releases may include irreversible database migrations.
      Never copy alpha data back to your stable or beta install.

      Switch to beta:
        brew uninstall centient@alpha && brew install centient@beta

      Switch back to stable:
        brew uninstall centient@alpha && brew install centient
    EOS
  end

  service do
    run [opt_bin/"engram", "start", "--foreground"]
    keep_alive true
    working_dir var/"engram-alpha"
    log_path var/"log/engram-alpha.log"
    error_log_path var/"log/engram-alpha.log"
    environment_variables ENGRAM_HOME: "#{Dir.home}/.engram-alpha",
                          ENGRAM_PORT: "3160",
                          ENGRAM_PG_PORT: "5460"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/centient --version")
    assert_match(/\d+\.\d+\.\d+/, shell_output("#{bin}/engram --version"))
  end
end
