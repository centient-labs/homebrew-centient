class Maintainer < Formula
  desc "Automated PR review pipeline for centient-labs"
  homepage "https://github.com/centient-labs/maintainer"
  version "0.15.0"

  depends_on :macos
  depends_on arch: :arm64
  depends_on "centient-labs/centient/engram" => :recommended

  url "https://github.com/centient-labs/homebrew-centient/releases/download/maintainer-v#{version}/maintainer-macos-arm64.tar.gz"
  sha256 "b59a2d812386a076d2635b3f09b25194678f4ddf92184cd5d314f721f586d279"

  def install
    bin.install "maintainer"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/maintainer --version")
  end
end