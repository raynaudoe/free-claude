#!/bin/bash
# Test Patches Script
# This script installs Claude Code, applies patches, and verifies the results

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
}

# Function to extract Claude version from PR (if running in CI)
get_claude_version() {
    if [ -n "${GITHUB_EVENT_NAME}" ] && [ "${GITHUB_EVENT_NAME}" = "pull_request" ]; then
        if command -v gh &> /dev/null; then
            PR_TITLE=$(gh pr view "${GITHUB_EVENT_NUMBER}" --json title --jq '.title' 2>/dev/null || echo "")
            if [ -n "$PR_TITLE" ]; then
                echo "$PR_TITLE" | grep -oP '@anthropic-ai/claude-code@\K[0-9]+\.[0-9]+\.[0-9]+' || echo "latest"
                return
            fi
        fi
    fi
    echo "latest"
}

# Function to install Claude Code
install_claude() {
    local version="$1"
    log_info "Installing Claude Code v${version}..."

    if [ "$version" = "latest" ]; then
        npm install -g @anthropic-ai/claude-code@latest
    else
        npm install -g "@anthropic-ai/claude-code@${version}"
    fi

    if [ $? -eq 0 ]; then
        log_success "Claude Code installed successfully"
    else
        log_error "Failed to install Claude Code"
        exit 1
    fi
}

# Function to apply patches
apply_patches() {
    log_info "Applying patches..."

    # Get Claude Code path
    CLAUDE_PATH=$(npm root -g)/@anthropic-ai/claude-code/cli.js

    if [ ! -f "$CLAUDE_PATH" ]; then
        log_error "Claude Code binary not found at: $CLAUDE_PATH"
        exit 1
    fi

    log_info "Found Claude Code at: $CLAUDE_PATH"

    # Apply patches using the patch script
    if python3 scripts/patch.py "$CLAUDE_PATH" 2>&1 | tee patch_output.log; then
        log_success "Patches applied successfully"
    else
        log_error "Failed to apply patches"
        return 1
    fi
}

# Function to verify patches
verify_patches() {
    local claude_path="$1"
    log_info "Verifying patches..."

    local verification_passed=true

    # Check if both patches were applied
    if grep -q "✓ All patches\|✓ Sub-agent recursion:" patch_output.log 2>/dev/null; then
        log_success "Patch script reported success"

        # Verify sub-agent recursion patch
        if grep -q "globalThis.__TASK_DEPTH__" "$claude_path"; then
            log_success "✓ Sub-agent recursion: ENABLED"
        else
            log_error "✗ Sub-agent recursion: DISABLED"
            verification_passed=false
        fi

        # Verify welcome message patch
        if grep -q "I had strings, but now I'm free" "$claude_path"; then
            log_success "✓ Welcome message: MODIFIED"
        else
            log_warning "✗ Welcome message: ORIGINAL (optional)"
        fi
    else
        log_error "Patch script did not report success"
        verification_passed=false
    fi

    # Show version info
    if command -v claude &> /dev/null; then
        local version=$(claude --version 2>/dev/null || echo "Version check failed")
        log_info "Claude Code version: $version"
    fi

    if [ "$verification_passed" = true ]; then
        log_success "✅ All patches verified successfully!"
        return 0
    else
        log_error "❌ Patch verification failed"
        return 1
    fi
}

# Main execution
main() {
    log_header "Free Claude Code Patch Testing"

    # Get Claude version
    CLAUDE_VERSION=$(get_claude_version)
    log_info "Testing patches for Claude Code v${CLAUDE_VERSION}"

    # Install Claude Code
    install_claude "$CLAUDE_VERSION"

    # Apply patches
    if ! apply_patches; then
        log_error "Patch application failed"
        exit 1
    fi

    # Get Claude path for verification
    CLAUDE_PATH=$(npm root -g)/@anthropic-ai/claude-code/cli.js

    # Verify patches
    if verify_patches "$CLAUDE_PATH"; then
        log_success "🎉 All tests passed!"
        exit 0
    else
        log_error "❌ Tests failed"
        exit 1
    fi
}

# Run main function
main "$@"
