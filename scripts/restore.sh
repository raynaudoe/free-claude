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

# Find Claude installation
TARGET_DEFAULT=$(find_claude_binary)
ORIG_SYMLINK="${TARGET_DEFAULT:-claude}"
REAL_PATH=$(readlink -f "$ORIG_SYMLINK" 2>/dev/null) || err "Could not find Claude installation"

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