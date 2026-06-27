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

## Session & Knowledge Management

This project participates in the centient knowledge management system. When `mcp__centient__*` tools are available, **always initialize a session at the start of every conversation** and use knowledge tools throughout:

1. **Always start a session** — Call `start_session_coordination` with `sessionId` (format: `YYYY-MM-DD-topic`) and `projectPath` before doing any work
2. **Search first** — Call `search_crystals` with your task topic to find prior work and decisions
3. **Check duplicates** — Call `check_duplicate_work` before implementing non-trivial changes
4. **Save knowledge** — Call `save_session_note` for important decisions, findings, and blockers
5. **End** — Call `finalize_session_coordination` to persist session artifacts

See `.agent/procedures/session-management.md` for tool parameters and additional tools.
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
