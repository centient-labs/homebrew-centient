class Cl < Formula
  desc "centient-labs workspace CLI — tidy, note, recall"
  homepage "https://github.com/centient-labs/cli"
  version "0.2.0"

  depends_on :macos
  depends_on arch: :arm64

  url "https://github.com/centient-labs/homebrew-centient/releases/download/cl-v#{version}/cl-macos-arm64.tar.gz"
  # Placeholder until the first `make publish` from centient-labs/cli runs
  # update_formula with the real tarball checksum (cli#3 release flow).
  sha256 "ab20d3293634901e61f8a2a98c7be6c4da5bb17ca4d42c1cbc939379b9d2a42f"

  def install
    bin.install "cl"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/cl --version")
  end
end