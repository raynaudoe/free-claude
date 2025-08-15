.PHONY: help patch restore clean

# Default target
help:
	@echo "free-claude - Enable nested sub-agent calls in Claude Code"
	@echo ""
	@echo "Available targets:"
	@echo "  make patch    - Apply patches to Claude Code (creates backup)"
	@echo "  make restore  - Restore from most recent backup"
	@echo "  make clean    - Remove all backup files"
	@echo "  make help     - Show this help message"
	@echo ""
	@echo "Usage:"
	@echo "  make patch             # Auto-detect Claude installation"
	@echo "  make patch CLAUDE=/path/to/claude  # Specify Claude path"

# Apply patches to Claude Code
patch:
	@echo "Applying patches to Claude Code..."
	@if [ -n "$(CLAUDE)" ]; then \
		./scripts/apply.sh "$(CLAUDE)"; \
	else \
		./scripts/apply.sh; \
	fi

# Restore from backup
restore:
	@echo "Restoring Claude Code from backup..."
	@if [ -n "$(BACKUP)" ]; then \
		./scripts/restore.sh "$(BACKUP)"; \
	else \
		./scripts/restore.sh; \
	fi

# Remove all backup files
clean:
	@echo "Removing backup files..."
	@find . -name "*.bak.*" -type f -exec rm -v {} \;
	@echo "Cleanup complete"