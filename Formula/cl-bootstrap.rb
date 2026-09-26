# typed: false
# frozen_string_literal: true

class ClBootstrap < Formula
  desc "Bootstrap shim for the centient-labs development system (co-developers; gate is GitHub org membership)"
  homepage "https://github.com/centient-labs/homebrew-centient"
  version "0.2.0"
  # license - TBD

  depends_on :macos
  depends_on arch: :arm64

  url "https://github.com/centient-labs/homebrew-centient/releases/download/cl-bootstrap-v#{version}/cl-bootstrap-macos-arm64.tar.gz"
  sha256 "506f87526620f7cecc7fceb7c1a8e62beaf504c4e2a187e54b1e36bc3e17a5b2"

  def install
    bin.install "cl-bootstrap"
  end

  def caveats
    <<~EOS
      cl-bootstrap sets up the centient-labs development system for CL
      co-developers. The binary is public and carries no secrets; every
      asset it fetches is gated by GitHub org membership, enforced
      server-side. Run:
        cl-bootstrap
    EOS
  end

  test do
    system "#{bin}/cl-bootstrap", "--help"
  end
end
