class Maintainer < Formula
  desc "Automated PR review pipeline for centient-labs"
  homepage "https://github.com/centient-labs/maintainer"
  version "0.19.9"

  depends_on :macos
  depends_on arch: :arm64
  depends_on "centient-labs/centient/engram" => :recommended

  url "https://github.com/centient-labs/homebrew-centient/releases/download/maintainer-v#{version}/maintainer-macos-arm64.tar.gz"
  sha256 "a0bdeb98f9da338efb0e778f68a04436d88aa2ad97b1711c7aa7de54ae55e673"

  def install
    bin.install "maintainer"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/maintainer --version")
  end
end