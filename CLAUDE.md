# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

This repository contains patches for the Claude CLI to re-enable recursive Task tool usage by sub-agents. It modifies the Claude Code bundle to:
1. Remove the depth limitation on sub-agent Task tool calls
2. Add a custom message to the welcome screen

## Project Structure

```
├── Makefile              # Build automation
├── scripts/
│   ├── patch.py         # Applies patches to Claude bundle
│   ├── apply.sh         # Main setup script
│   └── restore.sh       # Restore from backup
└── README.md            # User documentation
```

## Key Files

- `scripts/patch.py`: Python script that applies two patches to Claude Code bundle files
  - Sub-agent depth counter patch: Enables recursive Task tool usage
  - Welcome message patch: Adds custom text to welcome screen
  
- `scripts/apply.sh`: Bash script that automates the patching process
  - Finds the Claude binary location
  - Creates a backup before patching
  - Applies the patch
  - Creates a `free_claude` symlink in `~/.local/bin`
  - Updates PATH in `.zshrc` if needed

- `scripts/restore.sh`: Restore Claude from backup
  - Finds most recent backup or uses specified file
  - Confirms before restoration
  - Shows SHA256 hashes for verification

## Development Commands

```bash
# Apply patches using Makefile
make patch                        # Auto-detect Claude
make patch CLAUDE=/path/to/claude # Specify path

# Restore from backup
make restore                      # Use most recent backup
make restore BACKUP=/path/to/backup.file

# Direct script usage
./scripts/apply.sh [path-to-claude-binary]
./scripts/restore.sh [backup-file]

# Manual patch application
python3 scripts/patch.py <path-to-claude-bundle-file>

# Clean up backup files
make clean
```

## Architecture

The patching system works by:

1. **Binary Modification**: Both patches modify the compiled JavaScript bundle directly
   - Text-based regex replacement for sub-agent logic
   - Binary pattern matching for welcome message insertion

2. **Depth Counter Logic**: Implements a global counter (`globalThis.__TASK_DEPTH__`) to track recursive Task tool calls, wrapping the original run function to increment/decrement the counter

3. **Installation Flow**:
   - Locates Claude CLI binary (searches common paths)
   - Creates timestamped backup
   - Applies patches in-place
   - Creates symlink for easy access
   - Ensures PATH configuration

## Important Notes

- The patches modify the Claude Code bundle directly - always backup before patching
- The script assumes a Unix-like environment (bash, python3)
- Default installation creates `free_claude` command accessible via `~/.local/bin`