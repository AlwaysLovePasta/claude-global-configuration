#!/usr/bin/env bash
# 偵測指定專案符合哪個 profile。
#
# 用法：detect-profile.sh <PROJECT_DIR>
# 輸出：符合的 profile 名稱（單行，到 stdout）；無符合條件則不輸出任何內容。
#
# 新增 profile 只需在 profiles/<name>/detect.json 宣告偵測條件，不用改這支腳本。
set -euo pipefail

PROJECT_DIR="$1"
PROFILES_DIR="$HOME/.claude/profiles"

for manifest in "$PROFILES_DIR"/*/detect.json; do
  [[ -f "$manifest" ]] || continue
  profile_name="$(basename "$(dirname "$manifest")")"
  matched=false

  while IFS= read -r marker_path; do
    [[ -n "$marker_path" ]] || continue
    if [[ -f "$PROJECT_DIR/$marker_path" ]]; then
      matched=true
      break
    fi
  done < <(jq -r '.markers[]?.path // empty' "$manifest")

  if [[ "$matched" == false ]]; then
    while IFS= read -r glob_name; do
      [[ -n "$glob_name" ]] || continue
      maxdepth=$(jq -r --arg g "$glob_name" '.markers[] | select(.glob==$g) | (.maxdepth // 5)' "$manifest")
      if find "$PROJECT_DIR" -maxdepth "$maxdepth" -name "$glob_name" -print -quit 2>/dev/null | grep -q .; then
        matched=true
        break
      fi
    done < <(jq -r '.markers[]?.glob // empty' "$manifest")
  fi

  if [[ "$matched" == true ]]; then
    echo "$profile_name"
    exit 0
  fi
done

exit 0
