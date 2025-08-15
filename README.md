# free-claude

<img src="res/msg.png" alt="free-claude message" width="400">

Patches Claude Code to enable nested sub-agent calls - allowing sub-agents to invoke other sub-agents via the Task tool, creating deeper automation chains.

**Note:** Tested on Claude Code *1.0.81*.

## What It Does

This tool removes the depth limitation that prevents sub-agents from using the Task tool, enabling recursive agent chains. Sub-agents can now invoke other sub-agents, creating deeper automation workflows.

## Quick Start

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

The patcher:
1. Locates your Claude Code installation (supports wrapper scripts)
2. Finds the actual JavaScript bundle (`cli.js`)
3. Creates a timestamped backup before patching
4. Applies the patch to enable recursive sub-agents
5. Creates a `free_claude` command in `~/.local/bin`