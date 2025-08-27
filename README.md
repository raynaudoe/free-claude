# free-claude

<img src="res/msg.png" alt="free-claude message" width="400">

Patches Claude Code to enable nested sub-agent calls - allowing sub-agents to invoke other sub-agents via the Task tool, creating deeper automation chains.

**Note:** Automatically tested and released for latest Claude Code versions.

## What It Does

This tool removes the depth limitation that prevents sub-agents from using the Task tool, enabling recursive agent chains. Sub-agents can now invoke other sub-agents, creating deeper automation workflows.

## Quick Start

### Option 1: Complete npm Package (Recommended)

```bash
# Install the complete patched package directly from GitHub releases
npm install -g https://github.com/yourusername/free-claude/releases/latest/download/free-claude-code-*.tgz

# Verify installation
claude --version
```

Alternative download method:
```bash
# Download and install manually
wget $(curl -s https://api.github.com/repos/yourusername/free-claude/releases/latest | grep "browser_download_url.*free-claude-code.*\.tgz" | cut -d '"' -f 4)
npm install -g free-claude-code-*.tgz
```

### Option 2: Manual Patching

```bash
# Apply patches to Claude Code
make patch

# Or specify Claude binary path
make patch CLAUDE=/path/to/claude

# Run the patched version
free_claude

# Restore original Claude Code from backup
make restore
```

## How It Works

### Complete Package Approach
The auto-release system:
1. **Downloads** the complete `@anthropic-ai/claude-code` npm package
2. **Extracts** all files (binary, vendor files, SDK, etc.)
3. **Applies patches** to the `cli.js` file for sub-agent recursion
4. **Repackages** as `free-claude-code` with modified `package.json`
5. **Releases** complete npm package ready for installation

### Manual Patching (Alternative)
The manual patcher:
1. Locates your Claude Code installation (supports wrapper scripts)
2. Finds the actual JavaScript bundle (`cli.js`)
3. Creates a timestamped backup before patching
4. Applies the patch to enable recursive sub-agents
5. Creates a `free_claude` command in `~/.local/bin`

### Rollback Options
```bash
# From complete package installation
npm uninstall -g free-claude-code
npm install -g @anthropic-ai/claude-code@latest

# From manual patching
make restore
```

## Automatic Releases & Auto-Fix

This repository automatically creates new releases whenever Claude Code is updated, with intelligent auto-repair capabilities:

- **🤖 Dependabot** monitors for new Claude Code versions daily
- **🧪 Auto-testing** verifies patches work with the new version  
- **🔧 Auto-fix** uses Claude AI to repair broken patches automatically
- **📦 Auto-release** creates complete npm package if tests pass
- **⚠️ Alerts** notify if manual intervention is needed

### Required Secrets

For the auto-fix functionality to work, the following secrets must be configured in the repository:

| Secret | Description | Required | Default |
|--------|-------------|----------|---------|
| `ANTHROPIC_API_KEY` | Your Anthropic API key for Claude | ✅ Yes | - |
| `ANTHROPIC_BASE_URL` | Custom Anthropic API base URL | ❌ Optional | `https://api.anthropic.com` |
| `ANTHROPIC_AUTH_TOKEN` | Alternative auth token (instead of API key) | ❌ Optional | - |

**To add secrets:**
1. Go to your repository Settings → Secrets and variables → Actions
2. Click "New repository secret"
3. Add the required secrets:
   - `ANTHROPIC_API_KEY` - Your Anthropic API key (required)
   - `ANTHROPIC_BASE_URL` - Only if using custom endpoint (optional)
   - `ANTHROPIC_AUTH_TOKEN` - Only if using auth token instead of API key (optional)

**Notes:**
- `GITHUB_TOKEN` is automatically provided by GitHub Actions - no setup needed
- For most users, only `ANTHROPIC_API_KEY` is required
- Enterprise or regional setups may need `ANTHROPIC_BASE_URL`
- `ANTHROPIC_AUTH_TOKEN` is an alternative to `ANTHROPIC_API_KEY` (use one or the other)

Each release includes:
- **Complete npm package** (77MB) - Drop-in replacement for `@anthropic-ai/claude-code`
- **All vendor files** - ripgrep binaries, JetBrains plugin, SDK, etc.
- **Sub-agent recursion enabled** - The critical patch for nested Task tool usage
- **Easy installation** - Single npm command installation
- **Simple rollback** - Uninstall and reinstall original package

### Getting Updates

1. **Watch this repository** for release notifications
2. **Check [Releases](../../releases)** for the latest patched version
3. **Install the complete package** that matches your Claude Code version:
   ```bash
   npm install -g https://github.com/yourusername/free-claude/releases/download/vX.Y.Z/free-claude-code-X.Y.Z.tgz
   ```

### Package Details

- **Package name**: `free-claude-code` (instead of `@anthropic-ai/claude-code`)
- **Size**: ~35MB compressed, ~77MB unpacked  
- **Files**: 53 files including all platform binaries
- **Installation**: Standard npm global install
- **Compatibility**: 100% compatible with original Claude Code

### Release Process

```mermaid
graph LR
    A[Dependabot detects<br/>Claude update] --> B[Auto-test patches]
    B --> C{Tests pass?}
    C -->|✅ Yes| D[Create release<br/>with patched binary]
    C -->|❌ No| E[Auto-fix patches<br/>using Claude AI]
    E --> F{Auto-fix<br/>successful?}
    F -->|✅ Yes| G[Merge PR] --> D
    F -->|❌ No| H[Label PR<br/>'claude-failed']
    D --> I[Close/Merged PR]
    H --> J[Manual intervention<br/>required]
```

### Manual Trigger

You can also manually trigger the auto-fix workflow:

1. **Go to Actions** → Auto Fix Patches → Run workflow
2. **Enter Claude version** (e.g., `1.0.87`)
3. **Optionally specify PR number** to update existing PR, or leave empty to create new PR
4. **Let Claude fix the patches** automatically

### How Auto-Fix Works

When Claude Code updates break the patches, the auto-fix system:

1. **🔍 Detects failure** - Test patches workflow fails on Dependabot PR
2. **🤖 Calls Claude** - Uses [Claude Code Action](https://github.com/anthropics/claude-code-action) with the `claude-patch-updater` agent
3. **🔧 Analyzes patterns** - Claude examines the new version and identifies changed variable names/patterns
4. **✏️ Updates patterns** - Automatically updates regex patterns in `scripts/patch.py`
5. **🧪 Tests fixes** - Validates patches work with Docker build
6. **🔀 Merges automatically** - If successful, merges the PR and triggers release
7. **⚠️ Escalates if needed** - Labels PR for manual review if auto-fix fails

**Benefits:**
- ⚡ **Faster recovery** - Minutes instead of manual hours
- 🧠 **Intelligent analysis** - Claude understands code patterns and variable changes  
- 🛡️ **Safe validation** - Always tests before applying
- 📝 **Full transparency** - All changes logged and auditable

### Getting Updates

1. **Watch this repository** for release notifications
2. **Check [Releases](../../releases)** for the latest patched version
3. **Install the complete package** that matches your Claude Code version:
   ```bash
   npm install -g https://github.com/yourusername/free-claude/releases/download/vX.Y.Z/free-claude-code-X.Y.Z.tgz
   ```

### Package Details

- **Package name**: `free-claude-code` (instead of `@anthropic-ai/claude-code`)
- **Size**: ~35MB compressed, ~77MB unpacked  
- **Files**: 53 files including all platform binaries
- **Installation**: Standard npm global install
- **Compatibility**: 100% compatible with original Claude Code