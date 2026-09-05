#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

# 完全取代：清空 ~/.claude 下除 skills/ 以外的所有內容，再轉移 repo 內容，確保安裝結果與 repo 一致。
# 注意：這會一併刪除 repo 未管理的本機專屬狀態（cache/、sessions/、history.jsonl、
# projects/ 含 auto memory、settings.local.json），且無法復原。
# 例外：skills/ 保留不刪，本機既有、repo 未管理的個人 skill 不受影響。
if [[ -d "$CLAUDE_DIR" ]]; then
  read -r -p "此操作將清空並重建 $CLAUDE_DIR（skills/ 除外），包含對話紀錄與 auto memory，且無法復原。是否繼續？[y/N] " confirm
  if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "已取消。"
    exit 1
  fi
  find "$CLAUDE_DIR" -mindepth 1 -maxdepth 1 ! -name skills -exec rm -rf {} +
fi

mkdir -p "$CLAUDE_DIR"

TARGETS=(CLAUDE.md settings.json hooks profiles rules agents skills)

for t in "${TARGETS[@]}"; do
  [[ -e "$REPO_DIR/$t" ]] || continue
  rsync -a --exclude='.git' --exclude='.gitmodules' --exclude='.gitignore' \
    "$REPO_DIR/$t" "$CLAUDE_DIR/"
  echo "  copied: $REPO_DIR/$t -> $CLAUDE_DIR/$t"
done

echo "Done."
