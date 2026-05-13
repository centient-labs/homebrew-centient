class Maintainer < Formula
  desc "Automated PR review pipeline for centient-labs"
  homepage "https://github.com/centient-labs/maintainer"
  version "0.19.8"

  depends_on :macos
  depends_on arch: :arm64
  depends_on "centient-labs/centient/engram" => :recommended

  url "https://github.com/centient-labs/homebrew-centient/releases/download/maintainer-v#{version}/maintainer-macos-arm64.tar.gz"
  sha256 "31f6833d894460056683eda19596eb654d5e37951de0506f67f0a9720f6680b1"

  def install
    bin.install "maintainer"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/maintainer --version")
  end
end