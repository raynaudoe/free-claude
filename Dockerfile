FROM node:20-alpine

RUN apk add --no-cache python3 bash

WORKDIR /app
COPY scripts/patch.py /app/patch.py

# Install Claude Code and apply patch
RUN npm install -g @anthropic-ai/claude-code@latest && \
    python3 /app/patch.py /usr/local/lib/node_modules/@anthropic-ai/claude-code/cli.js

# Verification with detailed status
CMD claude --version && \
    echo "\n===== VERIFICATION =====" && \
    echo "Checking patches..." && \
    if grep -q "globalThis.__TASK_DEPTH__" /usr/local/lib/node_modules/@anthropic-ai/claude-code/cli.js; then \
        echo "✓ Sub-agent recursion: ENABLED"; \
    else \
        echo "✗ Sub-agent recursion: DISABLED"; \
    fi && \
    if grep -q "I had strings, but now I'm free" /usr/local/lib/node_modules/@anthropic-ai/claude-code/cli.js; then \
        echo "✓ Welcome message: MODIFIED"; \
    else \
        echo "✗ Welcome message: ORIGINAL"; \
    fi