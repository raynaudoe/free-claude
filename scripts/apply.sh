#!/usr/bin/env bash
set -euo pipefail

# Create a patched copy of the Claude CLI bundle that re-enables subagents to use the Task tool.
# The copy is named "free_claude" and a symlink is created in ~/.local/bin/free_claude.
# Usage: ./apply.sh [path-to-original-claude]

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

TARGET_DEFAULT=$(find_claude_binary)
ORIG_SYMLINK="${1:-$TARGET_DEFAULT}"
REAL_PATH=$(readlink -f "$ORIG_SYMLINK")

USER_BIN="$HOME/.local/bin"
LINK_PATH="$USER_BIN/free_claude"
ZSHRC="$HOME/.zshrc"

log() { printf "[+] %s\n" "$*"; }
warn() { printf "[!] %s\n" "$*"; }
err()  { printf "[x] %s\n" "$*" >&2; exit 1; }

# Pre-flight
command -v python3 >/dev/null 2>&1 || err "python3 is required"
[ -f "$REAL_PATH" ] || err "Original bundle not found: $REAL_PATH"
[ -r "$REAL_PATH" ] || err "Original bundle is not readable: $REAL_PATH"

log "Original bundle: $REAL_PATH"

# Create a backup of the original file
TS="$(date +%Y%m%d%H%M%S)"
BKP="${REAL_PATH}.bak.${TS}"
cp -p "$REAL_PATH" "$BKP"
log "Backed up original file to: $BKP"

# Apply patch to the original file
BEFORE_SHA="$(shasum -a 256 "$REAL_PATH" | awk '{print $1}')"
log "Original file SHA256 (before): $BEFORE_SHA"

python3 "$(dirname "$0")/patch.py" "$REAL_PATH"

AFTER_SHA="$(shasum -a 256 "$REAL_PATH" | awk '{print $1}')"
log "Original file SHA256 (after):  $AFTER_SHA"

if [ "$BEFORE_SHA" == "$AFTER_SHA" ]; then
  warn "Patching failed: SHA256 hashes are identical."
else
  log "Patching successful: SHA256 hashes are different."
fi

# Create user bin dir and symlink
mkdir -p "$USER_BIN"
ln -sfn "$ORIG_SYMLINK" "$LINK_PATH"
log "Symlink created: $LINK_PATH -> $ORIG_SYMLINK"

# Ensure ~/.local/bin is on PATH for zsh
NEED_PATH_ADD=1
case ":$PATH:" in
  *":$USER_BIN:"*) NEED_PATH_ADD=0 ;;
esac

if [ $NEED_PATH_ADD -eq 1 ]; then
  TS="$(date +%Y-%m-%d)"
  {
    echo ""
    echo "# Added by free-claude on $TS"
    echo "if [[ \":\$PATH:\" != *:\$HOME/.local/bin:* ]]; then"
    echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
    echo "fi"
  } >> "$ZSHRC"
  log "Updated $ZSHRC to include ~/.local/bin in PATH."
  log "Run: source $ZSHRC   or open a new terminal session."
else
  log "~/.local/bin already in PATH."
fi

cat <<EOF

Done.
- Original (patched): $REAL_PATH
- Launcher:            $LINK_PATH (ensure PATH includes ~/.local/bin)

You can now run: free_claude
If it is not found, run: source $ZSHRC  or start a new terminal.
EOF
