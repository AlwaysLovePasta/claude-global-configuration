---
name: create-profile
description: 互動式建立新 Claude Code profile：scaffold CLAUDE.md、rules/*.md、detect.json。
allowed-tools: Read, Write, Edit, Bash
---

# Create Profile

## 前提

確認 `profiles/` 與 `hooks/load-profile.sh` 存在，否則停止並告知使用者從 repo 根目錄執行。

## 運作原理（供產生內容時參考）

`hooks/load-profile.sh` 在 `SessionStart` 時讀取每個 `profiles/<slug>/detect.json`，比對目前專案特徵；命中後把該 profile 的 `CLAUDE.md`、`rules/`（遞迴，保留子目錄結構）、`skills/*` symlink 進**當前專案**的 `.claude/` 目錄（不分 profile 子目錄，直接對應 `.claude/rules/`、`.claude/skills/`）。Hook 本身不輸出任何內容，實際是否載入進 context 由 Claude Code 原生機制決定：
- `rules/*.md` 若有 `paths:` frontmatter → 只在 Claude 讀寫符合 glob 的檔案時載入；沒有則每個 session 無條件載入（適合跨檔案類型的通用規則，如任務工作流程）
- `skills/*` → 依 description 與當前任務比對決定是否載入

## Phase 1 — 蒐集需求（單次發問）

必填：
1. **Slug** — 小寫連字號，例如 `ios-dev`（→ `profiles/` 目錄名與 detection key）
2. **Tech stack** — 語言、框架、關鍵函式庫（→ CLAUDE.md Tech Stack 表格）
3. **偵測信號** — 唯一識別此類專案的檔案，例如 `Package.swift`、`Cargo.toml`

選填（是/否）：
4. 回應語言（預設 English）
5. 需要哪些 rule files：`coding` / `architecture` / `solid` / `testing` / `workflow` / `templates`（列出樣板名稱，供其他 rule 檔引用）；每個檔案是否要 `paths:` frontmatter 及對應 glob（無 `paths:` 代表無條件每次載入，僅適合跨檔案類型的通用規則）
6. Skill stubs 名稱列表（只建 TODO stub）

收集後輸出確認摘要，確認再進行 Phase 2。

## Phase 2 — 產生檔案

**固定產生** `profiles/<slug>/CLAUDE.md`，含四個 section，且比照 `profiles/android/CLAUDE.md` 的慣例——內文以 `.claude/rules/<file>.md` 這種路徑引用規則檔（不是 `.claude/rules/<slug>/<file>.md`），因為 hook 映射時是直接對應到當前專案的 `.claude/rules/`，不分 profile 子目錄：

```
## 1. Tech Stack        — 表格，填入 stack 資訊
## 2. Architecture      — 一段說明；若有 architecture.md 加引用
## 3. Design Principles — SOLID / YAGNI / DRY 條列
## 4. Response Rules    — Language / Warnings / Citations；有 workflow.md 加 Task mode
```

**依確認產生**（未確認 = 不產生）：

| 檔案 | 必要內容 | `paths:` frontmatter |
|------|----------|----------|
| `rules/architecture.md` | 層次圖、依賴方向、目錄結構範例 | 該語言原始碼與 build 設定檔 glob |
| `rules/coding.md` | 命名慣例、慣用語法、錯誤處理偏好 | 該語言原始碼 glob |
| `rules/solid.md` | 每個原則附此語言的具體程式碼範例 | 該語言原始碼 glob |
| `rules/testing.md` | 框架角色、必測項目、命名慣例 | 測試檔案 glob |
| `rules/workflow.md` | 任務模式、PR/commit 紀律 | 無（跨檔案類型的通用規則，session 內無條件載入） |
| `rules/templates/<name>.md` | 給其他 rule 檔引用的詳細範例（真實程式碼，非描述） | 不需要，本身不會被單獨載入，只在對應的 rule 檔（如 `testing.md`）內文用相對路徑引用（如「詳見 `rules/templates/testing.md`」）時，由 Claude 依需要另外 Read |
| `skills/<name>/SKILL.md` | frontmatter + `# TODO` body | 不適用（skill 依 description 比對載入） |

`rules/templates/` 是規則的一部分（供規則引用的詳細說明），不是給這支 `create-profile` skill 自己 scaffold 用的樣板——兩者無關，不要混淆。hook 會遞迴 symlink 整個 `rules/` 目錄，`templates/` 子目錄結構會被保留，確保規則檔裡的相對路徑引用在專案端依然有效。

## Phase 3 — 寫入 detect.json

產生 `profiles/<slug>/detect.json`，格式：

```json
{
  "markers": [
    { "path": "<相對於專案根目錄的檔案路徑>" },
    { "glob": "<檔名 pattern>", "maxdepth": <搜尋深度，預設 5> }
  ]
}
```

- 根目錄或固定子路徑的檔案（如 `Cargo.toml`、`ios/Podfile`）用 `path`
- 檔名固定但位置不確定（如 `AndroidManifest.xml`、`*.xcodeproj`）用 `glob`
- 多個信號視為 OR（任一命中即判定為此 profile）

寫入後不需要修改 `hooks/load-profile.sh`——它會自動掃描所有 `profiles/*/detect.json`。

## Phase 4 — 驗證

```bash
find profiles/<slug> -type f | sort
cat profiles/<slug>/detect.json | jq .
bash -n hooks/load-profile.sh
```

輸出已建立的檔案清單、`detect.json` 內容，並提醒使用者審閱內容後 commit。
