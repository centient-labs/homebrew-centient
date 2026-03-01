# typed: false
# frozen_string_literal: true

require "json"

class CentientATbeta < Formula
  desc "Context engineering MCP server for Claude Code (beta channel)"
  homepage "https://github.com/centient-labs/centient"
  version "0.22.0-beta.1"
  # license - TBD

  # Currently only macOS ARM64 (Apple Silicon) is supported
  depends_on :macos
  depends_on arch: :arm64

  url "https://github.com/centient-labs/homebrew-centient/releases/download/v#{version}/centient-macos-arm64.tar.gz"
  sha256 "0582d307fa6127fd1cfa165cb80e6d0da454592f3da3afb4fec2182cb66178c1"

  conflicts_with "centient", because: "centient and centient@beta install conflicting binaries"
  conflicts_with "centient@alpha", because: "centient@beta and centient@alpha install conflicting binaries"

  def install
    bin.install "centient"
    bin.install "engram"

    # Install embedded PostgreSQL binaries
    if File.directory?("postgres")
      (share/"centient-beta"/"postgres").install Dir["postgres/*"]
      # Make binaries executable
      Dir[share/"centient-beta"/"postgres"/"bin"/"*"].each do |f|
        chmod 0755, f if File.file?(f)
      end
      # Create required library symlinks from pg-symlinks.json
      symlinks_file = share/"centient-beta"/"postgres"/"pg-symlinks.json"
      if File.exist?(symlinks_file)
        begin
          symlinks = JSON.parse(File.read(symlinks_file))
          symlinks.each do |link|
            source = link["source"].sub("native/", "")
            target = link["target"].sub("native/", "")
            # Validate paths don't escape postgres directory
            next if source.include?("..") || target.include?("..")
            next if source.start_with?("/") || target.start_with?("/")
            source_path = share/"centient-beta"/"postgres"/source
            target_path = share/"centient-beta"/"postgres"/target
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
      (share/"centient-beta"/"centient-web-dist").install Dir["centient-web-dist/*"]
    end

    # Install command templates
    if File.directory?("templates/commands")
      (share/"centient-beta"/"templates"/"commands").install Dir["templates/commands/*.md"]
    end

    # Install crucible command templates
    if File.directory?("templates/crucible-commands")
      (share/"centient-beta"/"templates"/"crucible-commands").install Dir["templates/crucible-commands/*.md"]
    end
  end

  def post_install
    (var/"engram-beta").mkpath
  end

  def caveats
    <<~EOS
      Centient BETA channel installed.

      Data isolation: beta uses separate storage to protect your stable data.
        Data directory: ~/.engram-beta
        API port:       3150
        Web UI port:    3151
        PostgreSQL:     5450

      To get started:
        ENGRAM_HOME=~/.engram-beta ENGRAM_PORT=3150 ENGRAM_PG_PORT=5450 centient setup

      To seed data from your stable install:
        cp -r ~/.engram/data ~/.engram-beta/data

      WARNING: Beta releases may include irreversible database migrations.
      Never copy beta data back to your stable install.

      Switch back to stable:
        brew uninstall centient@beta && brew install centient
    EOS
  end

  service do
    run [opt_bin/"engram", "start", "--foreground"]
    keep_alive true
    working_dir var/"engram-beta"
    log_path var/"log/engram-beta.log"
    error_log_path var/"log/engram-beta.log"
    environment_variables ENGRAM_HOME: "#{Dir.home}/.engram-beta",
                          ENGRAM_PORT: "3150",
                          ENGRAM_PG_PORT: "5450",
                          CENTIENT_WEB_PORT: "3151"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/centient --version")
    assert_match(/\d+\.\d+\.\d+/, shell_output("#{bin}/engram --version"))
  end
end