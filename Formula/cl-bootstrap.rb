# typed: false
# frozen_string_literal: true

class ClBootstrap < Formula
  desc "Bootstrap shim for the centient-labs development system (co-developers; gate is GitHub org membership)"
  homepage "https://github.com/centient-labs/homebrew-centient"
  version "0.2.0"
  # license - TBD

  on_macos do
    on_arm do
      url "https://github.com/centient-labs/homebrew-centient/releases/download/cl-bootstrap-v#{version}/cl-bootstrap-macos-arm64.tar.gz"
      sha256 "506f87526620f7cecc7fceb7c1a8e62beaf504c4e2a187e54b1e36bc3e17a5b2"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/centient-labs/homebrew-centient/releases/download/cl-bootstrap-v#{version}/cl-bootstrap-linux-arm64.tar.gz"
      sha256 "eda615f45628bbb83e9fdb4a7a58ec158851c739128e8135344a35415f6d26dc"
    end
    on_intel do
      url "https://github.com/centient-labs/homebrew-centient/releases/download/cl-bootstrap-v#{version}/cl-bootstrap-linux-x64.tar.gz"
      sha256 "4abe70e44e2c3f3078ed8d6a84dbd0450e8dc15a4fe7e561a7a1d6c2bb91dbd0"
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
