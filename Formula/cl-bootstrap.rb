# typed: false
# frozen_string_literal: true

class ClBootstrap < Formula
  desc "Bootstrap shim for the centient-labs development system (co-developers; gate is GitHub org membership)"
  homepage "https://github.com/centient-labs/homebrew-centient"
  version "0.3.0"
  # license - TBD

  on_macos do
    on_arm do
      url "https://github.com/centient-labs/homebrew-centient/releases/download/cl-bootstrap-v#{version}/cl-bootstrap-macos-arm64.tar.gz"
      sha256 "8290090e625419ff29e73c2624f7fad47bc28d7fdf1a8301ee06a7d17adbff07"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/centient-labs/homebrew-centient/releases/download/cl-bootstrap-v#{version}/cl-bootstrap-linux-arm64.tar.gz"
      sha256 "bd07ae64c851f7a47353a404a0bc7e24932d06c5b52ee523d5c2d3d45c355af6"
    end
    on_intel do
      url "https://github.com/centient-labs/homebrew-centient/releases/download/cl-bootstrap-v#{version}/cl-bootstrap-linux-x64.tar.gz"
      sha256 "281605cac329c71b46b19e4551a1f412eb3de1091c1b8711ff60ae39c1bed9bc"
    end
  end

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
