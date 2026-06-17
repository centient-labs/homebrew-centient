class Cl < Formula
  desc "centient-labs workspace CLI — tidy, note, recall"
  homepage "https://github.com/centient-labs/cli"
  version "0.4.0"

  depends_on :macos
  depends_on arch: :arm64

  url "https://github.com/centient-labs/homebrew-centient/releases/download/cl-v#{version}/cl-macos-arm64.tar.gz"
  # Placeholder until the first `make publish` from centient-labs/cli runs
  # update_formula with the real tarball checksum (cli#3 release flow).
  sha256 "6a0d62baa474450a3559c84702673d3ce5b5add7fd15d33f0ff08e5b87e73c23"

  def install
    bin.install "cl"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/cl --version")
  end
end