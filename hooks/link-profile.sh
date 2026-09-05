#!/usr/bin/env bash
# 把指定 profile 的 CLAUDE.md / rules / skills symlink 進專案的 .claude/，
# 並把這些 symlink 路徑排除進該專案 git 的 info/exclude（若是 git repo），
# 避免個人專屬 symlink 被誤 commit 進團隊共用 repo。
#
# 用法：link-profile.sh <PROFILE_NAME> <PROJECT_DIR>
set -euo pipefail

PROFILE_NAME="$1"
PROJECT_DIR="$2"

PROFILES_DIR="$HOME/.claude/profiles"
PROFILE_DIR="$PROFILES_DIR/$PROFILE_NAME"
PROJECT_CLAUDE_DIR="$PROJECT_DIR/.claude"
ACTIVE_MAP_FILE="$PROJECT_CLAUDE_DIR/.active-profile-map"

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
