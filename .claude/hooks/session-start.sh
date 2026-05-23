#!/bin/bash
set -euo pipefail

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

pip install \
  -r "$CLAUDE_PROJECT_DIR/skills/slack-gif-creator/requirements.txt" \
  -r "$CLAUDE_PROJECT_DIR/skills/mcp-builder/scripts/requirements.txt" \
  --user --quiet
