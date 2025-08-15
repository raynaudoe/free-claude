# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

This repository contains patches for the Claude CLI to re-enable recursive Task tool usage by sub-agents. It modifies the Claude Code bundle to:
1. Remove the depth limitation on sub-agent Task tool calls (enables unlimited agent recursion)
2. Add a custom message to the welcome screen ("I had strings, but now I'm free")

## Project Structure

```
├── Makefile              # Build automation
├── scripts/
│   ├── patch.py         # Core patching logic (handles minified & non-minified code)
│   ├── apply.sh         # Main setup script with bundle detection
│   └── restore.sh       # Restore from backup with bundle detection
├── res/
│   └── msg.png          # Welcome message screenshot
└── README.md            # User documentation
```

## Key Files

### `scripts/patch.py`
Python script that applies two patches to the Claude Code JavaScript bundle:
- **Sub-agent depth counter patch**: 
  - Injects `globalThis.__TASK_DEPTH__` counter to track recursion depth
  - Wraps Task tool's run function to increment/decrement counter
  - Supports both minified and non-minified code patterns
  - Idempotent: detects if already applied and skips
- **Welcome message patch**: 
  - Inserts custom message after "Claude Code" in welcome screen
  - Binary pattern matching to preserve exact formatting
  - Idempotent: detects if already applied and skips

### `scripts/apply.sh`
Sophisticated bash script that automates the patching process:
- **Bundle Detection**: 
  - Identifies wrapper scripts vs actual JavaScript bundles
  - Follows exec commands in wrapper scripts
  - Resolves symlinks to find actual `cli.js` file
- **Safety Features**:
  - Creates timestamped backups before any modifications
  - Verifies patches with SHA256 checksums
  - Reports clear status for each patch (applied/already applied/failed)
- **Installation**:
  - Creates `free_claude` command in `~/.local/bin`
  - Updates PATH in `.zshrc` if needed
  - Preserves original wrapper script structure

### `scripts/restore.sh`
Restore script with intelligent file detection:
- Uses same bundle detection logic as apply.sh
- Finds most recent backup automatically
- Confirms restoration with SHA256 verification
- Supports manual backup file specification

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

## Technical Architecture

### Bundle Resolution Strategy
The patching system handles complex Claude installations:

1. **Wrapper Script Detection**:
   - Identifies bash wrapper scripts (e.g., `~/.claude/local/claude`)
   - Extracts exec commands to find actual Node.js entry points
   - Follows symlink chains to locate the real JavaScript bundle
   - Typical resolution: `claude` → `wrapper.sh` → `node_modules/.bin/claude` → `cli.js`

2. **File Locations** (typical local installation):
   - Wrapper: `~/.claude/local/claude` (73 bytes bash script)
   - Symlink: `~/.claude/local/node_modules/.bin/claude`
   - Bundle: `~/.claude/local/node_modules/@anthropic-ai/claude-code/cli.js` (8.7MB)

### Patch Implementation Details

#### Sub-agent Recursion Patch
- **Pattern Detection**: Searches for two critical code patterns:
  - Check pattern: `if(W.name===k7)return!1` (prevents sub-agent Task usage)
  - Logic pattern: `let{toolName:J}=CC(W);if(J===k7){G.push(W);continue}`
- **Modification Strategy**:
  - Injects depth check: `if(W.name===k7&&(globalThis.__TASK_DEPTH__||0)>=2)return!1`
  - Wraps Task tool execution with counter increment/decrement
  - Preserves async behavior and error handling
- **Minified Code Support**: Handles both formatted and minified JavaScript

#### Welcome Message Patch
- **Binary Pattern Matching**: Searches for exact byte sequence
- **Insertion Point**: After `"Claude Code"),"!"`
- **Message Format**: `PQ.createElement(T,null," - I had strings, but now I'm free")`
- **Preservation**: Maintains React element structure

### Idempotency Mechanisms

Both patches include idempotency checks to prevent duplicate application:

1. **Sub-agent Patch Check**:
   - Searches for `globalThis.__TASK_DEPTH__` presence
   - If found, skips patch with "already applied" message
   - Prevents counter logic duplication

2. **Welcome Message Check**:
   - Searches for custom message bytes in bundle
   - If found, skips patch with "already applied" message
   - Prevents message concatenation

3. **SHA256 Verification**:
   - Compares before/after hashes
   - Identical hashes with "already applied" = success
   - Identical hashes without "already applied" = compatibility issue

### Backup & Recovery System

- **Backup Naming**: `cli.js.bak.YYYYMMDDHHMMSS`
- **Automatic Backup**: Created before every patch attempt
- **Recovery Options**:
  - Auto-detect most recent backup
  - Manual backup specification
  - SHA256 verification before and after restore

## Known Issues & Solutions

### Issue: Patches Not Applying
**Symptoms**: Both patches show "applied: False"
**Cause**: Claude version incompatibility or already modified bundle
**Solution**: 
- Check Claude version (tested with 1.0.81)
- Restore from backup and retry
- Verify bundle file location is correct

### Issue: Welcome Message Not Appearing
**Symptoms**: Patch applies but message doesn't show
**Cause**: React component structure changed
**Solution**: Check for Claude updates that may have altered UI structure

### Issue: Multiple Patch Applications
**Symptoms**: Running patch multiple times
**Status**: RESOLVED - Idempotency checks prevent issues
**Behavior**: Safe to run multiple times, will skip if already applied

## Important Notes

- **Direct Bundle Modification**: Patches modify the JavaScript bundle in-place
- **Backup Strategy**: Always creates timestamped backups before modification
- **Environment Requirements**: Unix-like system with bash and python3
- **PATH Setup**: Automatically configures `~/.local/bin` in PATH via `.zshrc`
- **Compatibility**: Tested with Claude Code 1.0.81, may need updates for other versions