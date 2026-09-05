#!/usr/bin/env bash
# Profile mapper 的收尾 — 觸發於 SessionEnd。
#
# 清掉 load-profile.sh 在本次 session 於「當前專案」建立的 profile symlink。
# 不處理 resume（見 settings.json 的 matcher）：resume 是接續同一個 session，
# 不是真正結束，symlink 應該繼續有效，等下一次真正的 SessionEnd 或
# SessionStart 再清。
set -euo pipefail

INPUT=$(cat)
PROJECT_DIR=$(printf '%s' "$INPUT" | jq -r '.cwd // empty')

[[ -z "$PROJECT_DIR" ]] && exit 0

ACTIVE_MAP_FILE="$PROJECT_DIR/.claude/.active-profile-map"

if [[ -f "$ACTIVE_MAP_FILE" ]]; then
  while IFS= read -r rel_path; do
    [[ -n "$rel_path" && -L "$PROJECT_DIR/$rel_path" ]] && rm -f "$PROJECT_DIR/$rel_path"
  done < "$ACTIVE_MAP_FILE"
  rm -f "$ACTIVE_MAP_FILE"
fi

exit 0
