# typed: false
# frozen_string_literal: true

require "json"

class CentientBeta < Formula
  desc "Context engineering MCP server for Claude Code (beta channel)"
  homepage "https://github.com/centient-labs/centient"
  version "0.16.0-beta.10"
  # license - TBD

  # Currently only macOS ARM64 (Apple Silicon) is supported
  depends_on :macos
  depends_on arch: :arm64

  url "https://github.com/centient-labs/homebrew-centient/releases/download/v#{version}/centient-macos-arm64.tar.gz"
  sha256 "0576015911c432e40236bf1a131d6e7b7121214ac827d7323706e66b144f7562"

  def install
    # Install binaries to libexec (not bin) to avoid conflicts with stable
    libexec.install "centient"
    libexec.install "engram"

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

    # Install ONNX Runtime next to binaries in libexec (sibling lookup)
    if File.directory?("onnx")
      (libexec/"onnx").install Dir["onnx/*"]
    end

    # Install centient-web to libexec
    if File.exist?("centient-web")
      libexec.install "centient-web"
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

    # Create suffixed wrapper scripts in bin/
    env_vars = {
      "ENGRAM_HOME" => "~/.engram-beta",
      "ENGRAM_PORT" => "3150",
      "ENGRAM_LOCAL_PORT" => "3150",
      "ENGRAM_PG_PORT" => "5450",
      "CENTIENT_WEB_PORT" => "3151",
      "CENTIENT_SHARE_DIR" => "#{share}/centient-beta",
      "CENTIENT_BINARY_NAME" => "centient-beta",
      "CENTIENT_CHANNEL" => "beta",
    }

    env_block = env_vars.map { |k, v| "export #{k}=\"#{v}\"" }.join("\n")

    %w[centient engram centient-web].each do |binary|
      next unless File.exist?(libexec/binary)
      (bin/"#{binary}-beta").write <<~BASH
        #!/bin/bash
        #{env_block}
        exec "#{libexec}/#{binary}" "$@"
      BASH
      chmod 0755, bin/"#{binary}-beta"
    end
  end

  def post_install
    (var/"engram-beta").mkpath
  end

  def caveats
    <<~EOS
      Centient BETA channel installed (coexists with stable).

      Binaries are suffixed to avoid conflicts:
        centient-beta        (instead of centient)
        engram-beta          (instead of engram)
        centient-web-beta    (instead of centient-web)

      Data isolation: beta uses separate storage to protect your stable data.
        Data directory: ~/.engram-beta
        API port:       3150
        Web UI port:    3151
        PostgreSQL:     5450

      To get started:
        centient-beta setup

      To seed data from your stable install:
        cp -r ~/.engram/data ~/.engram-beta/data

      WARNING: Beta releases may include irreversible database migrations.
      Never copy beta data back to your stable install.
    EOS
  end

  service do
    run [opt_libexec/"engram", "start", "--foreground"]
    keep_alive true
    working_dir var/"engram-beta"
    log_path var/"log/engram-beta.log"
    error_log_path var/"log/engram-beta.log"
    environment_variables ENGRAM_HOME: "#{Dir.home}/.engram-beta",
                          ENGRAM_PORT: "3150",
                          ENGRAM_LOCAL_PORT: "3150",
                          ENGRAM_PG_PORT: "5450",
                          CENTIENT_WEB_PORT: "3151",
                          CENTIENT_SHARE_DIR: "#{HOMEBREW_PREFIX}/share/centient-beta",
                          CENTIENT_BINARY_NAME: "centient-beta",
                          CENTIENT_CHANNEL: "beta"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/centient-beta --version")
    assert_match(/\d+\.\d+\.\d+/, shell_output("#{bin}/engram-beta --version"))
  end
end