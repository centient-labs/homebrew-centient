# Homebrew Tap for Centient

This is the official Homebrew tap for [Centient](https://github.com/centient-labs/centient) - a context engineering MCP server for Claude Code.

## Installation

```bash
brew install centient-labs/centient/centient
```

Or:

```bash
brew tap centient-labs/centient
brew install centient
```

## What's Included

| Binary | Description |
|--------|-------------|
| `centient` | MCP server providing context engineering tools |
| `engram-local` | Local PostgreSQL + pgvector memory server |
| `local-ui` | Web dashboard at http://localhost:3101 |

## Quick Start

1. Start the memory server:
   ```bash
   engram-local start
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

## Background Service

To have engram-local start automatically:

```bash
brew services start centient
```

## Documentation

See the main repository: https://github.com/centient-labs/centient
