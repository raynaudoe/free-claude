#!/usr/bin/env bash
set -euo pipefail

# Build a complete free-claude-code npm package from the original @anthropic-ai/claude-code
# Usage: ./build-package.sh <claude-version> [output-dir]

CLAUDE_VERSION="${1:-latest}"
OUTPUT_DIR="${2:-./dist}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "🚀 Building free-claude-code package v${CLAUDE_VERSION}"

# Create working directory
WORK_DIR=$(mktemp -d)
trap "rm -rf $WORK_DIR" EXIT

cd "$WORK_DIR"

echo "📥 Downloading original Claude Code package..."
# Download and extract the original package
npm pack "@anthropic-ai/claude-code@${CLAUDE_VERSION}"
TARBALL=$(ls anthropic-ai-claude-code-*.tgz)
tar -xzf "$TARBALL"

# Move into the package directory
cd package

echo "🔧 Applying patches to cli.js..."
# Apply our patches to the cli.js file
python3 "$PROJECT_ROOT/scripts/patch.py" ./cli.js

# Verify patches were applied
if ! grep -q "globalThis.__TASK_DEPTH__" ./cli.js; then
    echo "❌ Sub-agent recursion patch failed"
    exit 1
fi

echo "✅ Sub-agent recursion patch applied successfully"

if grep -q "I had strings, but now I'm free" ./cli.js; then
    echo "✅ Welcome message patch applied successfully"
    WELCOME_PATCHED=true
else
    echo "⚠️ Welcome message patch failed (non-critical)"
    WELCOME_PATCHED=false
fi

echo "📝 Modifying package.json..."
# Read original package.json and make minimal changes
jq --arg name "free-claude-code" \
   --arg version "$CLAUDE_VERSION" \
   --arg desc "Patched Claude Code with recursive sub-agent support - based on @anthropic-ai/claude-code@$CLAUDE_VERSION" \
   '.name = $name | 
    .version = $version | 
    .description = $desc |
    .bin.claude = "./cli.js" |
    .bin["free-claude"] = "./cli.js" |
    .scripts.postinstall = "node -e \"console.log(\\\"\\\\n🎉 Free Claude (patched) installed!\\\\n- ✅ Sub-agent recursion enabled\\\\n- 🔗 Based on Claude Code v\($version)\\\\n\\\")\"" |
    del(.scripts.prepare) |
    del(.scripts.prepublishOnly)' \
   package.json > package.json.new

mv package.json.new package.json

echo "📄 Adding patch information to README..."
# Preserve original README and add patch notice at the top
cat > README_PATCHES.md << EOF
# 🎉 PATCHED VERSION - Free Claude Code v${CLAUDE_VERSION}

**This is a patched version of @anthropic-ai/claude-code@${CLAUDE_VERSION} with sub-agent recursion enabled.**

## What's Patched
- ✅ **Sub-agent recursion** - Sub-agents can now invoke other sub-agents via Task tool
- 📦 **Package name** - Published as \`free-claude-code\` to avoid conflicts  
- 🔄 **Same functionality** - Works exactly like original Claude Code

## Original README Below
---

EOF

# Append original README to preserve Anthropic's documentation  
cat README.md >> README_PATCHES.md
mv README_PATCHES.md README.md

echo "📦 Creating package tarball..."
# Create the final package directory
mkdir -p "$OUTPUT_DIR"
OUTPUT_PATH="$OUTPUT_DIR/free-claude-code-${CLAUDE_VERSION}.tgz"

# Package it up
npm pack --pack-destination "$OUTPUT_DIR"

# Rename to our expected filename
mv "$OUTPUT_DIR"/free-claude-code-*.tgz "$OUTPUT_PATH"

echo "🧪 Verifying built package..."
# Test install the package to verify it works
npm install -g "$OUTPUT_PATH" >/dev/null 2>&1

# Test that claude command exists and shows version
if command -v claude >/dev/null 2>&1; then
    echo "✅ Claude command available"
    if claude --version >/dev/null 2>&1; then
        echo "✅ Claude --version works"
    else
        echo "⚠️ Claude --version failed (non-critical)"
    fi
else
    echo "❌ Claude command not found after installation"
    exit 1
fi

# Uninstall test package
npm uninstall -g free-claude-code >/dev/null 2>&1 || true

echo "✅ Package built and verified successfully!"
echo "📍 Location: $OUTPUT_PATH"  
echo "📊 Size: $(du -h "$OUTPUT_PATH" | cut -f1)"

# Show package contents
echo ""
echo "📋 Package contents:"
tar -tzf "$OUTPUT_PATH" | head -20
if [ $(tar -tzf "$OUTPUT_PATH" | wc -l) -gt 20 ]; then
    echo "... and $(( $(tar -tzf "$OUTPUT_PATH" | wc -l) - 20 )) more files"
fi

echo ""
echo "🎯 To test the package:"
echo "  npm install -g '$OUTPUT_PATH'"
echo "  claude --version"

echo ""
echo "🚀 To publish (when ready):"
echo "  cd $(dirname "$OUTPUT_PATH") && tar -xzf $(basename "$OUTPUT_PATH")"
echo "  cd package && npm publish"
