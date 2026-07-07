cask "wheelhouse" do
  version "0.1.0"
  sha256 "35b9874ec666cf9fbe5ae97e837ac39427da9e76aae76a52d7cd789037e4e0b4"

  url "https://github.com/centient-labs/homebrew-centient/releases/download/wheelhouse-v#{version}/Wheelhouse-macos-arm64.zip"
  name "Wheelhouse"
  desc "Centient Labs operator console (menu-bar app)"
  homepage "https://github.com/centient-labs/wheelhouse"

  depends_on macos: ">= :sonoma"
  depends_on arch: :arm64

  app "Wheelhouse.app"

  caveats <<~EOS
    Unsigned build (internal org distribution — signing is deferred; see the
    wheelhouse repo's docs/release/README.md). Gatekeeper will quarantine a
    normal download; install with:
      brew install --cask --no-quarantine centient-labs/centient/wheelhouse
  EOS
end