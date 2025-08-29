# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

This repository patches Claude Code to enable recursive sub-agent calls, allowing sub-agents to invoke other sub-agents via the Task tool for deeper automation chains.

## Updating Patches for New Claude Versions

### When Patches Break
1. **Monitor System Alerts**: Dependabot PR labeled "patches-broken" indicates incompatibility
2. **Test Current Patches**: `./scripts/test-patches.sh` or `npm install -g @anthropic-ai/claude-code@latest && python3 scripts/patch.py $(npm root -g)/@anthropic-ai/claude-code/cli.js`
3. **Identify Changes**: Extract and examine new Claude bundle to find pattern changes

### Finding New Patterns
```bash
# Extract Claude bundle for analysis
cp ~/.claude/local/node_modules/@anthropic-ai/claude-code/cli.js ./cli_new.js

# Search for key patterns that may have changed
grep -E "W\.name\s*===\s*k7" cli_new.js  # Sub-agent check pattern
grep -E "toolName.*k7.*push" cli_new.js   # Task tool logic pattern
grep "Claude Code" cli_new.js             # Welcome message location

# Compare with known patterns
diff <(grep -o "if.*k7.*return" cli_new.js) <(echo "if(W.name===k7)return!1")
```

### Updating `scripts/patch.py`

#### Sub-agent Recursion Patch Updates
Key patterns to update in patch.py:
- **Lines 15-17**: `pattern_sub_agent_check` - Checks if tool is k7 (Task)
- **Lines 21-23**: `pattern_sub_agent_logic` - Task tool handling logic
- **Variable names**: May change (W, J, k7, G, CC/VC) - use regex `[A-Z]{2}` for functions

Common changes in new versions:
- Variable minification (k7 might become different identifier)
- Function names (CC/VC might change)
- Whitespace differences in minified vs non-minified

#### Welcome Message Patch Updates
- **Line 82**: `original_pattern` - React component structure for welcome text
- Binary search pattern - must match exact bytes

### Testing Updated Patches
```bash
# 1. Backup current working patches
cp scripts/patch.py scripts/patch.py.bak

# 2. Apply updated patches
python3 scripts/patch.py ~/.claude/local/node_modules/@anthropic-ai/claude-code/cli.js

# 3. Verify patches applied
grep -q "globalThis.__TASK_DEPTH__" ~/.claude/local/node_modules/@anthropic-ai/claude-code/cli.js && echo "✓ Sub-agent patch found"

# 4. Test functionality
python3 scripts/test-patches.sh

# 5. Restore if failed
cp scripts/patch.py.bak scripts/patch.py
```

### Pattern Debugging Tips
- Use `--color=always` with grep to highlight matches
- Test both minified and non-minified patterns
- Check for Unicode or encoding issues with `file` and `hexdump`
- Variable names often follow patterns: single letters for minified, descriptive for non-minified

## Key Commands

```bash
# Primary workflow - apply patches
make patch                        # Auto-detect Claude installation
make patch CLAUDE=/path/to/claude # Specify Claude binary path

# Testing and verification
make help                         # Show available commands
./scripts/test-patches.sh         # Test patches directly

# Restore original Claude
make restore                      # Use most recent backup
make restore BACKUP=/path/to/file # Use specific backup

# Cleanup
make clean                        # Remove backup files

# Direct script usage (advanced)
./scripts/apply.sh [claude-path]
./scripts/restore.sh [backup-file]
python3 scripts/patch.py <bundle-file>
```

## Critical Patterns to Track

### Sub-agent Task Detection
The patches work by finding and modifying two critical code sections:

1. **Task Tool Check** (`pattern_sub_agent_check` in patch.py:15-17)
   - Original: `if(W.name===k7)return!1` 
   - Modified: Adds depth counter check
   - Variables to watch: `W` (tool object), `k7` (Task tool identifier)

2. **Task Tool Handler** (`pattern_sub_agent_logic` in patch.py:21-23)
   - Original: `let{toolName:J}=CC(W);if(J===k7){G.push(W);continue}`
   - Modified: Wraps with depth counter increment/decrement
   - Variables to watch: `J` (toolName), `CC/VC` (helper function), `G` (queue)

### Version Compatibility Matrix
| Claude Version | Sub-agent Var | Task ID | Helper Func | Status |
|---------------|---------------|---------|-------------|---------|
| 1.0.81        | W             | k7      | CC/VC       | ✓ Working |
| 1.0.86        | W             | k7      | CC/VC       | ✓ Working |
| Future        | Track changes | Track   | Track       | Update patterns |

## Architecture Overview

### Core Components
- **`scripts/patch.py`**: Pattern-based patcher (handles minified/non-minified)
- **`scripts/apply.sh`**: Bundle detection and backup automation
- **`scripts/restore.sh`**: Recovery from timestamped backups
- **`Makefile`**: User-facing interface

### Patch Safety
- Idempotency: Checks for `globalThis.__TASK_DEPTH__` before applying
- Backups: Timestamped `.bak.YYYYMMDDHHMMSS` files
- Verification: SHA256 comparison before/after patching

## Continuous Integration

### Monitoring System (`/monitor/`)
- **Dependabot**: Tracks `@anthropic-ai/claude-code` updates in `monitor/package.json`
- **GitHub Action**: Auto-tests patches on version updates via direct execution
- **Auto-Release**: Creates binary releases when patches pass testing
- **Workflow**: New version → Dependabot PR → Automated patch testing → Auto-release if working, label "patches-broken" if failed

### Auto-Release Workflow (`.github/workflows/auto-release.yml`)

The new auto-release system creates pre-built patched binaries automatically:

**Trigger**: When Test Patches workflow completes successfully for Dependabot PRs
**Process**:
1. Verifies patches passed testing
2. Extracts Claude Code version from Dependabot PR
3. Installs specific Claude Code version and applies patches
4. Creates release package with:
   - Patched `claude-code-patched.js` binary
   - Automatic installation script (`install.sh`)
   - README with version info and instructions
   - Complete tarball for easy distribution
5. Creates GitHub release with proper versioning (`vX.Y.Z` matching Claude Code version)
6. Uploads release assets and generates release notes
7. Closes Dependabot PR with success comment linking to release

**Release Artifacts**:
- `free-claude-vX.Y.Z.tar.gz` - Complete package
- Release notes with installation instructions
- Automatic version tagging and change tracking

### Testing
- **Direct execution**: Tests patches in GitHub Actions environment
- **Verification**: Checks for `globalThis.__TASK_DEPTH__` presence and "ENABLED" status
- **Manual testing**: `./scripts/test-patches.sh` or `npm install -g @anthropic-ai/claude-code@latest && python3 scripts/patch.py $(npm root -g)/@anthropic-ai/claude-code/cli.js`
- **Auto-Release Testing**: Full end-to-end verification with binary packaging before release

### Release Management

**Automatic Release Creation**:
```bash
# Testing the auto-release workflow (manual trigger)
gh workflow run auto-release.yml

# Monitoring release status
gh release list
gh release view vX.Y.Z

# Manual release verification
wget https://github.com/owner/repo/releases/download/vX.Y.Z/free-claude-vX.Y.Z.tar.gz
tar -xzf free-claude-vX.Y.Z.tar.gz
./install.sh --dry-run  # Test installation script
```

**Release Verification Checklist**:
- ✅ Patched binary includes both sub-agent and welcome message patches
- ✅ Installation script detects Claude Code paths correctly  
- ✅ Backup creation works as expected
- ✅ Release notes include correct version and dependency information
- ✅ Tarball contains all necessary files (binary, script, README)

## Troubleshooting Pattern Updates

### Debugging Failed Patches
```bash
# 1. Extract patterns from new Claude version
node -e "const fs=require('fs'); const content=fs.readFileSync('cli.js','utf8'); console.log(content.match(/if.*k7.*return.*!1/g))"

# 2. Check variable name changes
grep -o "[a-zA-Z0-9_]\+\.name===[a-zA-Z0-9_]\+" cli.js | sort -u

# 3. Find Task tool identifier (may not be k7)
grep -B2 -A2 '"Task"' cli.js

# 4. Locate tool handling logic
grep -E "toolName|push.*continue" cli.js
```

### Common Pattern Evolution
- **Minification changes**: Whitespace removal, semicolon variations
- **Variable renames**: k7→k8, W→X, CC→DD (track in compatibility matrix)
- **Structure changes**: React component updates affect welcome message
- **Function wrapping**: New build tools may add additional layers

## Environment Requirements

- Unix-like system with bash and python3
- Claude Code installation (tested with v1.0.81-1.0.86)
- Node.js and npm for patch testing
- PATH configured to `~/.local/bin`