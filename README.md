# Claude Code Global Configuration

Claude Code 的全局設置倉庫。將 `~/.claude/` 下可版控的設置集中管理，透過遠端倉儲追蹤變更，換機時執行安裝腳本即可還原完整設置，無須手動重建。

## 目錄結構

```
.
├── CLAUDE.md        # 全局行為指引
├── settings.json    # 全局設定檔
├── hooks/           # Lifecycle hook 腳本
├── profiles/        # 專案類型 profile（由 hook 映射進當前專案的 .claude/）
├── rules/           # 跨專案共用規則（尚未建立）
├── agents/          # 自訂 subagent 定義（尚未建立）
└── skills/          # 自訂 slash command 實作
```

### CLAUDE.md

每次 session 啟動時，Claude Code 會自動讀取 `~/.claude/CLAUDE.md` 並注入系統提示。此檔案存放跨專案通用的行為指引，包含語言偏好、設計原則與程式碼品質規範。子目錄的 `CLAUDE.md` 可以用 `@path/to/file` 語法引用其他規則檔，避免重複。

### settings.json

控制 Claude Code 全局行為的設定檔。涵蓋 `effortLevel`、tool 權限白名單、以及 hook 掛載點。設定優先順序（由高至低）：managed settings → CLI arguments → project local → project shared → **user global（此檔）**。

### hooks/

存放對應 Claude Code lifecycle 事件的 shell 腳本，「建立」與「清除」成對存在：

| Lifecycle 事件 | 職責 |
|---|---|
| `SessionStart` | 偵測當前專案類型，把符合的 profile 內容 symlink 進**當前專案**的 `.claude/` |
| `SessionEnd` | session 正常結束（`/clear`、`/exit`、登出）時清除上面建立的 symlink；接續舊 session 的 `resume` 不觸發，因為工作尚未結束 |

Hook 只負責這些確定性的檔案系統動作，內容什麼時候該真正載入 context，交給 Claude Code 原生的 rules（`paths:` frontmatter）與 skills（description 比對）機制決定，不由 hook 越俎代庖。

### profiles/

依專案類型分組的設置集合，每個 profile 是獨立目錄，可包含自己的 `CLAUDE.md`、`rules/`、`skills/`、`detect.json`（宣告偵測條件）。新增 profile 只需新增目錄，不用改動 `hooks/load-profile.sh`。

部分 profile（如 `profiles/android`）是獨立 repo，以 git submodule 掛載。更新流程：

1. 到該 profile 自己的 repo（獨立 clone）修改內容、commit、push
2. 回到 `profiles/<name>` 執行 `git pull`，同步最新內容
3. 回外層 repo 根目錄 `git add profiles/<name>` 並 commit，把新的 submodule commit 指標記錄下來

不要直接在 `profiles/<name>` 這個 submodule checkout 裡編輯內容，避免跟獨立 repo 分岔。

### rules/（尚未建立）

跨專案共用（不限特定 profile）的模組化規則，結構與用法比照 `.claude/rules/` 原生機制：獨立 Markdown 檔案，可在 YAML frontmatter 設定 `paths` 欄位，讓規則僅在 Claude 操作符合路徑 glob 的檔案時才載入。

### agents/（尚未建立）

自訂 subagent 的定義檔，每個 `.md` 檔描述一個專責特定任務的 subagent，含系統提示、可用工具與權限設定。全局 agents 存放於此目錄，專案級別則放在 `.claude/agents/`。

### skills/

以目錄為單位封裝的可重用工作流，透過 `/skill-name` 呼叫。每個 skill 至少包含 `SKILL.md`（入口指引），可選擇性附加 `templates/`、`examples/` 及 `scripts/`。Skill 內容僅在呼叫時載入，不佔用平時的 context。目前包含 `create-profile`（互動式 scaffold 新 profile）。

---

### 不進版控的項目

下列項目屬於 runtime 產物或機器本地狀態，不進版控——且會在安裝時被**完全清除**（見下方安裝章節的警告）：

| 路徑 | 說明 |
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

`install.sh` 會先清空並重建 `~/.claude/`（`skills/` 目錄除外），確保安裝結果與倉庫內容一致——這代表上方「不進版控的項目」會被永久刪除，無法復原，執行前會跳出確認提示。`skills/` 保留不刪，本機既有、repo 未管理的個人 skill 不受影響；repo 有同名 skill 時仍會以 repo 內容覆蓋。

## 版本

變更歷史記錄於 [`CHANGELOG.md`](CHANGELOG.md)，以 [SemVer](https://semver.org/) 管理：

| 版本號 | 情境 |
|--------|------|
| PATCH | 修正現有規則措辭、修正 hook/腳本邏輯 bug |
| MINOR | 新增 profile、rule、skill 或 agent |
| MAJOR | 破壞性變更（如調整目錄結構、修改 install.sh 行為）|
