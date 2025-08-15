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

TARGET_DEFAULT=$(find_claude_binary)
ORIG_SYMLINK="${1:-$TARGET_DEFAULT}"
REAL_PATH=$(find_bundle_file "$ORIG_SYMLINK")

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

# Capture the output from the patch script
PATCH_OUTPUT=$(python3 "$(dirname "$0")/patch.py" "$REAL_PATH" 2>&1)
echo "$PATCH_OUTPUT"

AFTER_SHA="$(shasum -a 256 "$REAL_PATH" | awk '{print $1}')"
log "Original file SHA256 (after):  $AFTER_SHA"

if [ "$BEFORE_SHA" == "$AFTER_SHA" ]; then
  # Check if patches were already applied
  if grep -q "already applied" <<< "$PATCH_OUTPUT"; then
    log "Patches were already applied. No changes needed."
  else
    warn "No patches were applied (may not be compatible with this Claude version)."
  fi
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
