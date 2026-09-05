# Changelog

All notable changes to this project will be documented in this file.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versioning follows [SemVer](https://semver.org/).

## [2.1.0] - 2026-09-05

### Added
- 新增 `SessionEnd` hook（`hooks/session-end.sh`），session 正常結束（`/clear`、`/exit`、登出）時立即清除 `load-profile.sh` 建立的 profile symlink，不再需要等到下次 SessionStart

### Changed
- `hooks/load-profile.sh` 拆分為 `detect-profile.sh`（偵測符合的 profile）與 `link-profile.sh`（symlink 建立、git `info/exclude` 維護），`load-profile.sh` 改為純協調角色
- SessionStart 不再前置清除上次殘留的 symlink（改由 SessionEnd hook 負責），簡化為「開始建立、結束清除」的單向流程

## [2.0.0] - 2026-09-05

### Changed
- `install.sh` 清空 `~/.claude/` 時排除 `skills/`，保留本機既有、repo 未管理的個人 skill

## [1.0.0] - 2026-09-05

### Changed
- `hooks/load-profile.sh` 改為將偵測到的 profile 內容 symlink 進當前專案的 `.claude/`，不再把規則內容直接注入 context
- profile 偵測邏輯改為讀取 `profiles/<name>/detect.json`，新增 profile 免修改 hook 腳本
- `install.sh` 改為安裝前完全清空並重建 `~/.claude/`，且加上執行前確認提示避免誤刪本機狀態
- `profiles/android/rules/architecture.md` 三層架構圖改用 mermaid 繪製，並補上 `paths:` frontmatter
- `skills/create-profile/SKILL.md` 同步更新以反映上述機制變動

## [0.2.0] - 2026-06-25

### Added
- `SessionStart` hook 自動將偵測到的 profile skills symlink 進 `~/.claude/skills/`，使其成為可呼叫的 slash command
- `~/.claude/.active-profile-skills` 追蹤當前 session 的 profile skill symlinks，確保切換專案時正確清除

## [0.1.1] - 2026-06-25

### Fixed
- `.gitmodules` submodule 路徑由 `profiles/android-dev` 更正為 `profiles/android`

## [0.1.0] - 2026-05-03

### Added
- 初始 Claude Code global configuration（CLAUDE.md、settings.json、hooks、profiles、skills）
- `SessionStart` hook (`load-profile.sh`) 自動偵測專案類型並注入對應 profile 規則
- Android profile（Clean Architecture 規則、Kotlin 慣例、Jetpack Compose 規範）
- `create-profile` meta-skill 用於 scaffold 新 profile
- `install.sh` 將配置同步至 `~/.claude/`
