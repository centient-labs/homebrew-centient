# Homebrew Tap for Centient

Official Homebrew tap for [Centient](https://github.com/centient-labs/centient) — a context engineering MCP server for Claude Code.

## Installation

```bash
brew install centient-labs/centient/centient   # MCP server (recommends engram)
brew install centient-labs/centient/engram     # local memory daemon
```

## What's Included

| Formula | Binaries | Description |
|---------|----------|-------------|
| `centient` | `centient` | MCP server providing context engineering tools |
| `engram` | `engram` (alias `engram-local`), `engram-web`, `engram-comms` | Local PostgreSQL + pgvector memory daemon; web UI at http://localhost:3101 |

## Quick Start

1. Start the memory daemon:
   ```bash
   brew services start engram
   ```

2. Add to Claude Code MCP settings (`~/.claude/settings.json`):
   ```json
   {
     "mcpServers": {
       "centient": {
         "command": "centient",
         "args": []
       }
     }
   }
   ```

3. Restart Claude Code.

## Documentation

See the main repository: https://github.com/centient-labs/centient
