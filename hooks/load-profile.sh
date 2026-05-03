#!/usr/bin/env bash
# Profile auto-loader — triggered by SessionStart
# Reads stdin JSON from Claude Code, detects project type, outputs profile content

set -euo pipefail

# 從 stdin 讀取 Claude Code 注入的 JSON context
INPUT=$(cat)
PROJECT_DIR=$(echo "$INPUT" | jq -r '.cwd // empty')

# 若無法取得專案目錄則靜默退出
[[ -z "$PROJECT_DIR" ]] && exit 0

PROFILES_DIR="$HOME/.claude/profiles"
LOADED_PROFILE=""

# ── Android ──────────────────────────────────────────────────────────────
if [[ -f "$PROJECT_DIR/build.gradle.kts" ]] || \
   [[ -f "$PROJECT_DIR/build.gradle" ]] || \
   [[ -f "$PROJECT_DIR/app/build.gradle.kts" ]] || \
   [[ -f "$PROJECT_DIR/app/build.gradle" ]] || \
   find "$PROJECT_DIR" -maxdepth 5 -name "AndroidManifest.xml" -print -quit 2>/dev/null | grep -q .; then
  LOADED_PROFILE="android"
fi

# ── 未來可擴充其他 profile ────────────────────────────────────────────────
# if [[ -f "$PROJECT_DIR/Cargo.toml" ]]; then LOADED_PROFILE="rust"; fi
# if [[ -f "$PROJECT_DIR/go.mod" ]]; then LOADED_PROFILE="golang"; fi

# ── 無符合條件：靜默退出 ─────────────────────────────────────────────────
[[ -z "$LOADED_PROFILE" ]] && exit 0

PROFILE_DIR="$PROFILES_DIR/$LOADED_PROFILE"
PROFILE_FILE="$PROFILE_DIR/CLAUDE.md"

# Profile 檔案不存在時警告
if [[ ! -f "$PROFILE_FILE" ]]; then
  echo "[profile-loader] WARNING: Profile '$LOADED_PROFILE' matched but '$PROFILE_FILE' not found." >&2
  exit 0
fi

# 輸出 profile 根目錄 CLAUDE.md
echo "## Loaded Profile: $LOADED_PROFILE"
echo ""
cat "$PROFILE_FILE"

# 遞迴輸出 profile 目錄下所有文字檔（排除 .git、README.md、.DS_Store、.gitignore）
while IFS= read -r -d '' file; do
  [[ "$file" == "$PROFILE_FILE" ]] && continue
  echo ""
  echo "### profile file: ${file#"$PROFILE_DIR"/}"
  echo ""
  cat "$file"
done < <(find "$PROFILE_DIR" \
    -not -path '*/.git/*' \
    -not -name '.DS_Store' \
    -not -name 'README.md' \
    -not -name '.gitignore' \
    -type f -print0 | sort -z)