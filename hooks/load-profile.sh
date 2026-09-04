#!/usr/bin/env bash
# Profile mapper — triggered by SessionStart.
#
# 偵測目前專案的語言/框架，把符合的 profile 的 CLAUDE.md / rules / skills
# symlink 進「當前專案」的 .claude/ 目錄。此 hook 只做檔案系統副作用
# （symlink），不輸出任何內容到 stdout、不注入 context —— 實際「什麼時候
# 該被讀進 context」交給 Claude Code 原生機制決定：
#   - rules 是否載入：.claude/rules/*.md 的 `paths:` frontmatter
#   - skills 是否載入：description 與當前任務比對
set -euo pipefail

INPUT=$(cat)
PROJECT_DIR=$(printf '%s' "$INPUT" | jq -r '.cwd // empty')

[[ -z "$PROJECT_DIR" ]] && exit 0

PROFILES_DIR="$HOME/.claude/profiles"
PROJECT_CLAUDE_DIR="$PROJECT_DIR/.claude"
ACTIVE_MAP_FILE="$PROJECT_CLAUDE_DIR/.active-profile-map"

# ── 清除上次 session 在本專案留下的 mapping ──────────────────────────────
if [[ -f "$ACTIVE_MAP_FILE" ]]; then
  while IFS= read -r rel_path; do
    [[ -n "$rel_path" && -L "$PROJECT_DIR/$rel_path" ]] && rm -f "$PROJECT_DIR/$rel_path"
  done < "$ACTIVE_MAP_FILE"
  rm -f "$ACTIVE_MAP_FILE"
fi

# ── 泛化偵測：讀取各 profile 的 detect.json ──────────────────────────────
# 新增 profile 只需在 profiles/<name>/detect.json 宣告偵測條件，不用改這支腳本。
LOADED_PROFILE=""
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
    LOADED_PROFILE="$profile_name"
    break
  fi
done

# ── 無符合條件：靜默退出（清除動作已在上方完成） ─────────────────────────
[[ -z "$LOADED_PROFILE" ]] && exit 0

PROFILE_DIR="$PROFILES_DIR/$LOADED_PROFILE"
mkdir -p "$PROJECT_CLAUDE_DIR/rules" "$PROJECT_CLAUDE_DIR/skills"
: > "$ACTIVE_MAP_FILE"

# 建立單一 symlink；若目的地已存在且不是我們建立的 symlink（即專案自己的檔案），
# 略過並警告，絕不覆蓋專案既有內容。
link_one() {
  local src="$1" rel_dest="$2"
  local dest="$PROJECT_DIR/$rel_dest"
  if [[ -e "$dest" && ! -L "$dest" ]]; then
    echo "[profile-mapper] WARNING: $rel_dest 已存在且非 symlink，略過以避免覆蓋專案既有檔案" >&2
    return
  fi
  ln -sfn "$src" "$dest"
  echo "$rel_dest" >> "$ACTIVE_MAP_FILE"
}

# ── CLAUDE.md ────────────────────────────────────────────────────────────
[[ -f "$PROFILE_DIR/CLAUDE.md" ]] && link_one "$PROFILE_DIR/CLAUDE.md" ".claude/CLAUDE.md"

# ── rules（遞迴 symlink，保留子目錄結構如 templates/，供 paths: frontmatter 生效
#     及規則檔之間的相對路徑引用如 `rules/templates/testing.md` 正常運作） ──
if [[ -d "$PROFILE_DIR/rules" ]]; then
  while IFS= read -r -d '' rule_file; do
    rel_path="${rule_file#"$PROFILE_DIR/rules/"}"
    mkdir -p "$PROJECT_CLAUDE_DIR/rules/$(dirname "$rel_path")"
    link_one "$rule_file" ".claude/rules/$rel_path"
  done < <(find "$PROFILE_DIR/rules" -type f -name '*.md' -print0)
fi

# ── skills ───────────────────────────────────────────────────────────────
if [[ -d "$PROFILE_DIR/skills" ]]; then
  for skill_dir in "$PROFILE_DIR/skills"/*/; do
    [[ -d "$skill_dir" ]] || continue
    skill_name="$(basename "$skill_dir")"
    link_one "$skill_dir" ".claude/skills/$skill_name"
  done
fi

# ── 若專案是 git repo，避免這些個人專屬 symlink 被誤 commit 進團隊共用 repo ──
if git -C "$PROJECT_DIR" rev-parse --git-dir >/dev/null 2>&1; then
  EXCLUDE_FILE="$(git -C "$PROJECT_DIR" rev-parse --git-path info/exclude)"
  while IFS= read -r rel_path; do
    [[ -n "$rel_path" ]] || continue
    grep -qxF "$rel_path" "$EXCLUDE_FILE" 2>/dev/null || echo "$rel_path" >> "$EXCLUDE_FILE"
  done < "$ACTIVE_MAP_FILE"
  grep -qxF ".claude/.active-profile-map" "$EXCLUDE_FILE" 2>/dev/null || echo ".claude/.active-profile-map" >> "$EXCLUDE_FILE"
fi

exit 0
