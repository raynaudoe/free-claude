#!/usr/bin/env bash
set -euo pipefail

# Restore the original Claude CLI bundle from the most recent backup
# Usage: ./restore.sh [backup-file]

# Find Claude binary with intelligent fallback strategy
find_claude_binary() {
  # Try command in PATH first
  command -v claude 2>/dev/null && return
  
  # Try common installation paths
  local candidates=(
    "$HOME/.claude/local/node_modules/.bin/claude"
    "/usr/local/bin/claude"
    "/opt/claude/bin/claude"
    "$HOME/.local/bin/claude"
  )
  
  for path in "${candidates[@]}"; do
    [[ -x "$path" ]] && echo "$path" && return
  done
  
  return 1
}

log() { printf "[+] %s\n" "$*"; }
warn() { printf "[!] %s\n" "$*"; }
err()  { printf "[x] %s\n" "$*" >&2; exit 1; }

# Find the actual JavaScript bundle file
find_bundle_file() {
  local wrapper="$1"
  
  # If it's the wrapper script at ~/.claude/local/claude, get the actual bundle
  if [[ "$wrapper" == "$HOME/.claude/local/claude" ]] && [[ -f "$HOME/.claude/local/node_modules/@anthropic-ai/claude-code/cli.js" ]]; then
    echo "$HOME/.claude/local/node_modules/@anthropic-ai/claude-code/cli.js"
    return
  fi
  
  # Check if it's a bash wrapper script that execs another file
  if file "$wrapper" | grep -q "shell script"; then
    # Extract the exec path from the wrapper
    local exec_path=$(grep -E "^exec " "$wrapper" 2>/dev/null | sed 's/^exec "\([^"]*\)".*/\1/')
    if [[ -n "$exec_path" ]]; then
      # If exec_path is relative, make it absolute based on wrapper's directory
      if [[ ! "$exec_path" = /* ]]; then
        exec_path="$(dirname "$wrapper")/$exec_path"
      fi
      # Follow the exec path and check if it's a symlink
      if [[ -L "$exec_path" ]]; then
        readlink -f "$exec_path"
      else
        echo "$exec_path"
      fi
      return
    fi
  fi
  
  # Otherwise try to resolve symlinks normally
  readlink -f "$wrapper"
}

# Find Claude installation
TARGET_DEFAULT=$(find_claude_binary)
ORIG_SYMLINK="${TARGET_DEFAULT:-claude}"
REAL_PATH=$(find_bundle_file "$ORIG_SYMLINK")

log "Found Claude bundle: $REAL_PATH"

# Find backup file
if [ $# -eq 1 ]; then
  # User specified backup file
  BACKUP_FILE="$1"
  [ -f "$BACKUP_FILE" ] || err "Backup file not found: $BACKUP_FILE"
else
  # Find most recent backup
  BACKUP_FILE=$(ls -t "${REAL_PATH}".bak.* 2>/dev/null | head -1)
  [ -z "$BACKUP_FILE" ] && err "No backup files found for: $REAL_PATH"
fi

log "Using backup file: $BACKUP_FILE"

# Show file information
log "Current file SHA256: $(shasum -a 256 "$REAL_PATH" | awk '{print $1}')"
log "Backup file SHA256:  $(shasum -a 256 "$BACKUP_FILE" | awk '{print $1}')"

# Confirm restoration
read -p "Restore from backup? This will overwrite the current Claude bundle. (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  log "Restoration cancelled"
  exit 0
fi

# Perform restoration
cp -p "$BACKUP_FILE" "$REAL_PATH" || err "Failed to restore backup"

log "Restoration complete!"
log "Restored file SHA256: $(shasum -a 256 "$REAL_PATH" | awk '{print $1}')"

cat <<EOF

Done. The original Claude bundle has been restored.
You can now run: claude

To re-apply patches, run: make patch
EOF