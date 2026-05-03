# Claude Code Global Configuration

Claude Code 的全局設置倉庫。將 `~/.claude/` 下可版控的設置集中管理，透過遠端倉儲追蹤變更，換機時執行安裝腳本即可還原完整設置，無須手動重建。

## 目錄結構

```
.
├── CLAUDE.md        # 全局行為指引
├── settings.json    # 全局設定檔
├── hooks/           # Lifecycle hook 腳本
├── profiles/        # 專案類型 profile（由 hook 動態載入）
├── rules/           # 跨專案共用規則（尚未建立）
├── agents/          # 自訂 subagent 定義（尚未建立）
└── skills/          # 自訂 slash command 實作（尚未建立）
```

### CLAUDE.md

每次 session 啟動時，Claude Code 會自動讀取 `~/.claude/CLAUDE.md` 並注入系統提示。此檔案存放跨專案通用的行為指引，包含語言偏好、設計原則與程式碼品質規範。子目錄的 `CLAUDE.md` 可以用 `@path/to/file` 語法引用其他規則檔，避免重複。

### settings.json

控制 Claude Code 全局行為的設定檔。涵蓋 `effortLevel`、tool 權限白名單、以及 hook 掛載點。設定優先順序（由高至低）：managed settings → CLI arguments → project local → project shared → **user global（此檔）**。

### hooks/

存放對應 Claude Code lifecycle 事件的 shell 腳本，並在 `settings.json` 的 `hooks` 欄位中宣告觸發條件。目前包含：

| 檔案 | 事件 | 用途 |
|------|------|------|
| `load-profile.sh` | `SessionStart` | 偵測專案類型，動態注入對應 profile 的 CLAUDE.md |

Hook 腳本從 stdin 接收 Claude Code 注入的 JSON context（含 `cwd`、`tool_name` 等欄位），以 exit code 0 表示成功、exit code 2 表示阻斷操作。

### profiles/

依專案類型分組的設置集合，由 `hooks/load-profile.sh` 在 `SessionStart` 時根據專案特徵（如 `AndroidManifest.xml`、`build.gradle`）自動選取並輸出至 Claude Code 系統提示。每個 profile 是獨立目錄，結構與 `.claude/` 相同，可包含自己的 `CLAUDE.md`、`rules/`、`skills/` 等。

### rules/（尚未建立）

以獨立 Markdown 檔案封裝的模組化規則。支援在 YAML frontmatter 中設定 `paths` 欄位，讓規則僅在 Claude 操作符合路徑 glob 的檔案時才載入，減少無關規則佔用 context。

### agents/（尚未建立）

自訂 subagent 的定義檔，每個 `.md` 檔描述一個專責特定任務的 subagent，含系統提示、可用工具與權限設定。全局 agents 存放於此目錄，專案級別則放在 `.claude/agents/`。

### skills/（尚未建立）

以目錄為單位封裝的可重用工作流，透過 `/skill-name` 呼叫。每個 skill 至少包含 `SKILL.md`（入口指引），可選擇性附加 `template.md`、`examples/` 及 `scripts/`。Skill 內容僅在呼叫時載入，不佔用平時的 context。

---

### 排除的檔案與目錄

下列項目屬於 runtime 產物或機器本地狀態，不進版控：

| 路徑 | 排除原因 |
|------|----------|
| `cache/` | 暫存資料，可自動重建 |
| `sessions/`、`history.jsonl` | 對話記錄，含個人隱私 |
| `projects/` | Claude Code 自動產生的 per-project memory |
| `settings.local.json` | 機器本地覆蓋值，不應共享 |
| `.DS_Store` | macOS 系統產物 |

## 安裝

> 前提：已安裝 Claude Code CLI。

```bash
git clone <repo-url> ~/path/to/global-configuration
cd ~/path/to/global-configuration
bash install.sh
```

`install.sh` 會將倉庫中的每個受控項目複製並覆蓋至 `~/.claude/`（`cp -rf`）。僅處理倉庫中實際存在的項目。

## 版本

當前版本記錄於 [`VERSION`](VERSION)，以 [SemVer](https://semver.org/) 管理：

| 版本號 | 情境 |
|--------|------|
| PATCH | 修正現有規則措辭、修正 hook 邏輯 bug |
| MINOR | 新增 profile、rule、skill 或 agent |
| MAJOR | 破壞性變更（如調整目錄結構、修改 install.sh 行為）|
