#!/usr/bin/env bash
# Profile mapper — triggered by SessionStart.
#
# 協調者：讀取 stdin 的 cwd，交給 detect-profile.sh 判斷符合哪個 profile，
# 再交給 link-profile.sh 把該 profile 的內容 symlink 進當前專案的 .claude/。
# 此 hook 本身及其協作腳本只做檔案系統副作用，不輸出任何內容到 stdout、
# 不注入 context —— 實際「什麼時候該被讀進 context」交給 Claude Code 原生
# 機制決定：
#   - rules 是否載入：.claude/rules/*.md 的 `paths:` frontmatter
#   - skills 是否載入：description 與當前任務比對
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

INPUT=$(cat)
PROJECT_DIR=$(printf '%s' "$INPUT" | jq -r '.cwd // empty')

[[ -z "$PROJECT_DIR" ]] && exit 0

LOADED_PROFILE="$("$SCRIPT_DIR/detect-profile.sh" "$PROJECT_DIR")"

[[ -z "$LOADED_PROFILE" ]] && exit 0

"$SCRIPT_DIR/link-profile.sh" "$LOADED_PROFILE" "$PROJECT_DIR"

exit 0
