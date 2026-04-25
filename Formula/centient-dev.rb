# typed: false
# frozen_string_literal: true

require "json"

class CentientDev < Formula
  desc "Context engineering MCP server for Claude Code (dev channel)"
  homepage "https://github.com/centient-labs/centient"
  version "0.21.0-dev.1"
  # license - TBD

  depends_on :macos
  depends_on arch: :arm64

  # Centient MCP server binary + command templates
  url "https://github.com/centient-labs/homebrew-centient/releases/download/centient-v#{version}/centient-macos-arm64.tar.gz"
  sha256 "2530b435f199289338053c23262b5a12b83c84dffe7b0ec8fa1ce350720b404b"

  # Engram memory daemon + PostgreSQL + pgvector + ONNX + web UI
  resource "engram" do
    url "https://github.com/centient-labs/homebrew-centient/releases/download/engram-v0.22.0-dev.1/engram-macos-arm64.tar.gz"
    sha256 "3ea4c0aef3273633ed5bb6fb875b3fbfb1ac423745852a047a32207e42c0db03"
  end

  def install
    # Install centient binary to libexec (not bin) to avoid conflicts with stable/beta
    libexec.install "centient"

    # Install command templates
    if File.directory?("templates/commands")
      (share/"centient-dev"/"templates"/"commands").install Dir["templates/commands/*.md"]
    end

    if File.directory?("templates/crucible-commands")
      (share/"centient-dev"/"templates"/"crucible-commands").install Dir["templates/crucible-commands/*.md"]
    end

    # Install engram components (from resource)
    resource("engram").stage do
      libexec.install "engram"

      # Install embedded PostgreSQL binaries
      if File.directory?("postgres")
        (share/"centient-dev"/"postgres").install Dir["postgres/*"]
        Dir[share/"centient-dev"/"postgres"/"bin"/"*"].each do |f|
          chmod 0755, f if File.file?(f)
        end
        symlinks_file = share/"centient-dev"/"postgres"/"pg-symlinks.json"
        if File.exist?(symlinks_file)
          begin
            symlinks = JSON.parse(File.read(symlinks_file))
            symlinks.each do |link|
              source = link["source"].sub("native/", "")
              target = link["target"].sub("native/", "")
              next if source.include?("..") || target.include?("..")
              next if source.start_with?("/") || target.start_with?("/")
              source_path = share/"centient-dev"/"postgres"/source
              target_path = share/"centient-dev"/"postgres"/target
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

      # Install engram-web to libexec under its canonical name so the engram
      # daemon's sibling lookup (`join(dirname(execPath), "engram-web")`)
      # finds it. Renaming this to `centient-web` was the root cause of the
      # dashboard not starting on dev — see homebrew-centient#11.
      if File.exist?("engram-web")
        libexec.install "engram-web"
      end
      if File.directory?("engram-web-dist")
        (share/"centient-dev"/"engram-web-dist").install Dir["engram-web-dist/*"]
      end
    end

    # Create suffixed wrapper scripts in bin/
    env_vars = {
      "ENGRAM_HOME" => "~/.engram-dev",
      "ENGRAM_PORT" => "3160",
      "ENGRAM_LOCAL_PORT" => "3160",
      "ENGRAM_PG_PORT" => "5460",
      "CENTIENT_WEB_PORT" => "3161",
      "CENTIENT_SHARE_DIR" => "#{share}/centient-dev",
      "CENTIENT_BINARY_NAME" => "centient-dev",
      "CENTIENT_CHANNEL" => "dev",
    }

    env_block = env_vars.map { |k, v| "export #{k}=\"#{v}\"" }.join("\n")

    # Direct (name-preserving) wrappers: bin/centient-dev -> libexec/centient,
    # bin/engram-dev -> libexec/engram.
    %w[centient engram].each do |binary|
      next unless File.exist?(libexec/binary)
      (bin/"#{binary}-dev").write <<~BASH
        #!/bin/bash
        #{env_block}
        exec "#{libexec}/#{binary}" "$@"
      BASH
      chmod 0755, bin/"#{binary}-dev"
    end

    # Web SPA wrapper: keep the user-facing name `centient-web-dev` for
    # backward compatibility (caveats and existing scripts), but exec the
    # canonically-named binary in libexec so engram's sibling lookup works.
    if File.exist?(libexec/"engram-web")
      (bin/"centient-web-dev").write <<~BASH
        #!/bin/bash
        #{env_block}
        exec "#{libexec}/engram-web" "$@"
      BASH
      chmod 0755, bin/"centient-web-dev"
    end
  end

  def post_install
    (var/"engram-dev").mkpath
  end

  def caveats
    <<~EOS
      Centient DEV channel installed (coexists with stable and beta).

      Binaries are suffixed to avoid conflicts:
        centient-dev         (instead of centient)
        engram-dev           (instead of engram)
        centient-web-dev     (instead of centient-web)

      Data isolation: dev uses separate storage to protect your stable/beta data.
        Data directory: ~/.engram-dev
        API port:       3160
        Web UI port:    3161
        PostgreSQL:     5460

      To get started:
        centient-dev setup

      WARNING: Dev releases are unstable and may include breaking changes.
      Do not use dev channel data with stable or beta installs.
    EOS
  end

  service do
    run [opt_libexec/"engram", "start", "--foreground"]
    keep_alive true
    working_dir var/"engram-dev"
    log_path var/"log/engram-dev.log"
    error_log_path var/"log/engram-dev.log"
    environment_variables ENGRAM_HOME: "#{Dir.home}/.engram-dev",
                          ENGRAM_PORT: "3160",
                          ENGRAM_LOCAL_PORT: "3160",
                          ENGRAM_PG_PORT: "5460",
                          CENTIENT_WEB_PORT: "3161",
                          CENTIENT_SHARE_DIR: "#{HOMEBREW_PREFIX}/share/centient-dev",
                          CENTIENT_BINARY_NAME: "centient-dev",
                          CENTIENT_CHANNEL: "dev"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/centient-dev --version")
    assert_match(/\d+\.\d+\.\d+/, shell_output("#{bin}/engram-dev --version"))
  end
end