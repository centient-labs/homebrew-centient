# homebrew-centient

Official Homebrew tap for centient + engram-local distribution.

## Critical Rules

1. Never commit secrets
2. Always test formula locally before pushing (`brew install --build-from-source ./Formula/centient.rb`)
3. Update SHA256 checksums when updating versions
4. Test service start/stop after formula changes

## Formula

- `Formula/centient.rb` — Installs centient binary, engram-local (PostgreSQL + pgvector memory server), centient-web dashboard
- **Platform**: macOS ARM64 only (Apple Silicon)
- **Post-install**: Runs `centient doctor --fix` to auto-configure MCP settings
- **Service**: Manages engram-local as a background process via `brew services`

## Common Commands

```bash
# Install
brew tap centient-labs/centient
brew install centient

# Service management
brew services start centient    # start engram-local daemon
brew services stop centient
brew services restart centient

# Test formula locally
brew install --build-from-source ./Formula/centient.rb
brew test centient

# Audit formula
brew audit --strict Formula/centient.rb
```

## Release Workflow

1. Update version and URL in `Formula/centient.rb`
2. Update SHA256 checksum for new tarball
3. Test locally with `brew install --build-from-source`
4. Verify service starts: `brew services start centient`
5. Verify post-install: `centient doctor --fix`
6. Push to main
