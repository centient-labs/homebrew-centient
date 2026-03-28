# typed: false
# frozen_string_literal: true

require "json"

class Centient < Formula
  desc "Context engineering MCP server for Claude Code with local memory"
  homepage "https://github.com/centient-labs/centient"
  version "0.25.3"
  # license - TBD

  depends_on :macos
  depends_on arch: :arm64

  # Centient MCP server binary + command templates
  url "https://github.com/centient-labs/centient/releases/download/v#{version}/centient-macos-arm64.tar.gz"
  sha256 "PLACEHOLDER_CENTIENT_SHA256"

  # Engram memory daemon + PostgreSQL + pgvector + ONNX + web UI
  resource "engram" do
    url "https://github.com/centient-labs/engram-server/releases/download/v0.22.0/engram-macos-arm64.tar.gz"
    sha256 "PLACEHOLDER_ENGRAM_SHA256"
  end

  def install
    # Install centient binary and templates (from main tarball)
    bin.install "centient"

    if File.directory?("templates/commands")
      (share/"centient"/"templates"/"commands").install Dir["templates/commands/*.md"]
    end

    # Install crucible command templates
    if File.directory?("templates/crucible-commands")
      (share/"centient"/"templates"/"crucible-commands").install Dir["templates/crucible-commands/*.md"]
    end

    # Install engram components (from resource)
    resource("engram").stage do
      bin.install "engram" => "engram-local"

      # Install embedded PostgreSQL binaries
      if File.directory?("postgres")
        (share/"centient"/"postgres").install Dir["postgres/*"]
        Dir[share/"centient"/"postgres"/"bin"/"*"].each do |f|
          chmod 0755, f if File.file?(f)
        end
        # Create required library symlinks from pg-symlinks.json
        symlinks_file = share/"centient"/"postgres"/"pg-symlinks.json"
        if File.exist?(symlinks_file)
          begin
            symlinks = JSON.parse(File.read(symlinks_file))
            symlinks.each do |link|
              source = link["source"].sub("native/", "")
              target = link["target"].sub("native/", "")
              # Validate paths don't escape postgres directory
              next if source.include?("..") || target.include?("..")
              next if source.start_with?("/") || target.start_with?("/")
              source_path = share/"centient"/"postgres"/source
              target_path = share/"centient"/"postgres"/target
              if File.exist?(source_path) && !File.exist?(target_path)
                ln_s source_path.basename, target_path
              end
            end
          rescue JSON::ParserError => e
            opoo "Failed to parse pg-symlinks.json: #{e.message}"
          end
        end
      end

      # Install ONNX Runtime for local embeddings
      if File.directory?("onnx")
        (bin/"onnx").install Dir["onnx/*"]
      end

      # Install engram-web and static files
      if File.exist?("engram-web")
        bin.install "engram-web" => "centient-web"
      end
      if File.directory?("engram-web-dist")
        (share/"centient"/"centient-web-dist").install Dir["engram-web-dist/*"]
      end
    end
  end

  def post_install
    (var/"engram").mkpath
  end

  def caveats
    channel_note = <<~EOS

      Pre-release channels available:
        brew install centient-labs/centient/centient-beta   # beta/RC releases
        brew install centient-labs/centient/centient-dev    # dev releases
      See: https://github.com/centient-labs/centient/blob/main/docs/guides/CHANNELS.md
    EOS

    if Dir.exist?(var/"engram"/"data")
      <<~EOS
        Upgrade complete! Run:
          centient update

        Then restart Claude Code for changes to take effect.
      EOS
    else
      <<~EOS
        Welcome to Centient! To get started, run:
          centient setup

        Then restart Claude Code for changes to take effect.
      EOS
    end + channel_note
  end

  service do
    run [opt_bin/"engram-local", "start", "--foreground"]
    keep_alive true
    working_dir var/"engram"
    log_path var/"log/engram.log"
    error_log_path var/"log/engram.log"
    environment_variables ENGRAM_HOME: "#{Dir.home}/.engram",
                          ENGRAM_PORT: "3100",
                          ENGRAM_LOCAL_PORT: "3100",
                          ENGRAM_PG_PORT: "5433",
                          CENTIENT_WEB_PORT: "3101",
                          CENTIENT_SHARE_DIR: "#{HOMEBREW_PREFIX}/share/centient"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/centient --version")
    assert_match(/\d+\.\d+\.\d+/, shell_output("#{bin}/engram-local --version"))
  end
end
