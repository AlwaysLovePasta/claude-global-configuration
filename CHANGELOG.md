# Changelog

All notable changes to this project will be documented in this file.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versioning follows [SemVer](https://semver.org/).

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
