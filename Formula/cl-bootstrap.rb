# typed: false
# frozen_string_literal: true

class ClBootstrap < Formula
  desc "Bootstrap shim for the centient-labs development system (co-developers; gate is GitHub org membership)"
  homepage "https://github.com/centient-labs/homebrew-centient"
  version "0.1.0"
  # license - TBD

  depends_on :macos
  depends_on arch: :arm64

  url "https://github.com/centient-labs/homebrew-centient/releases/download/cl-bootstrap-v#{version}/cl-bootstrap-macos-arm64.tar.gz"
  sha256 "672efa9b75a87ee62840e21b4b30b5504e0475e6feff51cd4d48685e9548d98b"

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
