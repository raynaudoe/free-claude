FROM node:20-alpine

RUN apk add --no-cache python3 bash

WORKDIR /app
COPY scripts/patch.py /app/patch.py

# Install Claude Code and apply patch
RUN npm install -g @anthropic-ai/claude-code@latest && \
    python3 /app/patch.py /usr/local/lib/node_modules/@anthropic-ai/claude-code/cli.js

# Simple verification
CMD claude --version && \
    echo "===== Patch Status =====" && \
    grep -q "globalThis.__TASK_DEPTH__" /usr/local/lib/node_modules/@anthropic-ai/claude-code/cli.js && \
    echo "Sub-agent recursion: ENABLED" || echo "Sub-agent recursion: DISABLED"