class Maintainer < Formula
  desc "Automated PR review pipeline for centient-labs"
  homepage "https://github.com/centient-labs/maintainer"
  version "0.19.12"

  depends_on :macos
  depends_on arch: :arm64
  depends_on "centient-labs/centient/engram" => :recommended

  url "https://github.com/centient-labs/homebrew-centient/releases/download/maintainer-v#{version}/maintainer-macos-arm64.tar.gz"
  sha256 "ff448be25f09ed88e35c8b009b5bc458253c21eb18a1d689582f6ed8fad7cd3e"

  def install
    bin.install "maintainer"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/maintainer --version")
  end
end