class Cl < Formula
  desc "centient-labs workspace CLI — tidy, note, recall"
  homepage "https://github.com/centient-labs/cli"
  version "0.2.0"

  depends_on :macos
  depends_on arch: :arm64

  url "https://github.com/centient-labs/homebrew-centient/releases/download/cl-v#{version}/cl-macos-arm64.tar.gz"
  # Placeholder until the first `make publish` from centient-labs/cli runs
  # update_formula with the real tarball checksum (cli#3 release flow).
  sha256 "30351985bae22f5cea06d42b5861eac723bf22ab86bfd515e02e4e56cba889d6"

  def install
    bin.install "cl"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/cl --version")
  end
end