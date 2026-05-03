#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

mkdir -p "$CLAUDE_DIR"

TARGETS=(CLAUDE.md settings.json hooks profiles rules agents skills)

for t in "${TARGETS[@]}"; do
  [[ -e "$REPO_DIR/$t" ]] || continue
  cp -rf "$REPO_DIR/$t" "$CLAUDE_DIR/$t"
  echo "  copied: $REPO_DIR/$t -> $CLAUDE_DIR/$t"
done

echo "Done."
