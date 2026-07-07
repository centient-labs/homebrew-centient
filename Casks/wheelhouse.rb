cask "wheelhouse" do
  version "0.1.0"
  sha256 "35b9874ec666cf9fbe5ae97e837ac39427da9e76aae76a52d7cd789037e4e0b4"

  url "https://github.com/centient-labs/homebrew-centient/releases/download/wheelhouse-v#{version}/Wheelhouse-macos-arm64.zip"
  name "Wheelhouse"
  desc "Centient Labs operator console (menu-bar app)"
  homepage "https://github.com/centient-labs/wheelhouse"

  # Bare symbol = MINIMUM version ("Sonoma or newer"), NOT an exact-OS pin:
  # Homebrew 6 deprecated the ">= :sonoma" string form with the bare symbol
  # as its prescribed replacement — Homebrew/brew#22549 ("Homebrew 6
  # deprecations", commit bc44e3d019); the cask DSL parses a bare symbol
  # with comparator ">=" (cask/dsl/depends_on.rb). Live-verified on
  # Homebrew 6.0.8 / macOS 26: a cask with `depends_on macos: :sonoma`
  # reports comparator ">=" and is satisfied on the newer host (see
  # wheelhouse PR #64 thread for the brew-ruby transcript).
  depends_on macos: :sonoma
  depends_on arch: :arm64

  app "Wheelhouse.app"

  caveats <<~EOS
    Unsigned build (internal org distribution — signing is deferred; see the
    wheelhouse repo's docs/release/README.md). Gatekeeper quarantines the
    downloaded app (Homebrew 6 removed the --no-quarantine flag); after
    install, clear the quarantine attribute with:
      xattr -dr com.apple.quarantine /Applications/Wheelhouse.app
  EOS
end
