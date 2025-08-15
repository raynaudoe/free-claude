# free-claude

Patches Claude Code to enable nested sub-agent calls - allowing sub-agents to invoke other sub-agents via the Task tool, creating deeper automation chains.

**Note:** Tested on Claude 1.0.81 only.

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