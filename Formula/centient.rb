# typed: false
# frozen_string_literal: true

require "json"

class Centient < Formula
  desc "Context engineering MCP server for Claude Code with local memory"
  homepage "https://github.com/centient-labs/centient"
  version "0.23.0"
  # license - TBD

  # Currently only macOS ARM64 (Apple Silicon) is supported
  # Intel Mac and Linux builds are disabled in CI
  depends_on :macos
  depends_on arch: :arm64

  url "https://github.com/centient-labs/homebrew-centient/releases/download/v#{version}/centient-macos-arm64.tar.gz"
  sha256 "238955873373c0714443c72f8e43e99ccd2b98143f1106a258ccff3086f9061c"

  def install
    bin.install "centient"
    bin.install "engram"

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
        begin
          symlinks = JSON.parse(File.read(symlinks_file))
          symlinks.each do |link|
            # Paths in JSON are like "native/lib/..." but we installed to "lib/..."
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

    # Install ONNX Runtime for local embeddings (Transformers.js)
    # Structure: onnx/napi-v3/{platform}/{arch}/ to match onnx-resolver.ts search paths
    if File.directory?("onnx")
      # Install next to binary so onnx-resolver.ts finds it at {execDir}/onnx/...
      (bin/"onnx").install Dir["onnx/*"]
    end

    # Sharp is shimmed in the binary - no native files needed
    # Text embeddings (EmbeddingGemma) work without image processing

    # Install centient-web and its static files if present
    if File.exist?("centient-web")
      bin.install "centient-web"
    end
    if File.directory?("centient-web-dist")
      (share/"centient"/"centient-web-dist").install Dir["centient-web-dist/*"]
    end

    # Install command templates to share directory (installed to ~/.claude by centient setup)
    if File.directory?("templates/commands")
      (share/"centient"/"templates"/"commands").install Dir["templates/commands/*.md"]
    end

    # Install crucible command templates
    if File.directory?("templates/crucible-commands")
      (share/"centient"/"templates"/"crucible-commands").install Dir["templates/crucible-commands/*.md"]
    end
  end

  def post_install
    (var/"engram").mkpath
  end

  def caveats
    channel_note = <<~EOS

      Pre-release channels available:
        brew install centient-labs/centient/centient-beta   # beta/RC releases
        brew install centient-labs/centient/centient-alpha  # alpha/dev releases
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
    run [opt_bin/"engram", "start", "--foreground"]
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
    assert_match(/\d+\.\d+\.\d+/, shell_output("#{bin}/engram --version"))
  end
end
