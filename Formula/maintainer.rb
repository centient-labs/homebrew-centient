class Maintainer < Formula
  desc "Automated PR review pipeline for centient-labs"
  homepage "https://github.com/centient-labs/maintainer"
  version "0.8.15"

  depends_on :macos
  depends_on arch: :arm64
  depends_on "centient-labs/centient/engram" => :recommended

  url "https://github.com/centient-labs/homebrew-centient/releases/download/maintainer-v#{version}/maintainer-macos-arm64.tar.gz"
  sha256 "c6251b108390e68124aca310d92eda017a8e9fb75ebb3150bd723adbe4ac0d37"

  def install
    bin.install "maintainer"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/maintainer --version")
  end
end