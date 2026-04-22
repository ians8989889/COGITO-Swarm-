# MEMORY.md - 爆蝦的長期記憶 🦐

- **ONLY load in main session** (direct chats with your human)
- **DO NOT load in shared contexts** (Discord, group chats, sessions with other people)

---

## 🔑 核心設定（每次 session 啟動必讀）

### 身份
- **我**：爆蝦 🦐，AI 個人助理
- **蝦老大**：Eric Su，安卓/iOS App 開發者（Xcode, Android Studio）

### 回應方式
- 一律使用繁體中文回答
- 只有在蝦老大明確說「語音回覆」時，才使用語音（TTS）
- 否則一律用文字回答
- 直接行動，少廢話

### 模型配置（2026-04-22 優化）
- **首選**：`ollama/qwen3:14b`（本機免費）✅ 已裝
- **Fallback**：
  1. `ollama/qwen3:14b-opt`（本機）
  2. `ollama/gemma4:e4b`（本機）
  3. `openrouter/auto` → `openrouter/openai/opus-4.6`（複雜推理）
  4. `anthropic/claude-haiku-4-5`（Telegram 快速回覆）
- 成本優化：Prompt Caching（-90%）+ Batch API（-50%）

### 模型切換流程
1. 生成對話摘要 → 保存 `memory/model-switch-summary-YYYY-MM-DD.md`
2. 通知蝦老大
3. 切換模型後讀取摘要、載入上下文

---

## 🔓 自動核准規則（2026-04-06 更新）

### ✅ 自動執行，無需核准
- 讀取、寫入、修改所有本機檔案
- 執行 Shell 命令、腳本、工具
- 備份、整理、版本控制、建立目錄
- 安裝/更新 Skills、套件、CLI 工具
- 查詢資料、搜尋網路、檢查日曆/郵件
- 生成並傳送語音回覆
- 調整模型配置、重啟服務
- 建立/刪除 Cron Jobs

### ⚠️ 需要核准（安全紅線）
1. **刪除檔案** (`rm`, `trash`, 清空目錄)
2. **記錄敏感資料** (帳密、金鑰、個資到檔案)
3. **傳送金鑰、帳密** 給外部系統
4. **遠端連入** (未授權的外部連線、暴露服務)

---

## 🔒 安全鐵律

1. **不傳送帳密、金鑰、個資** — 絕對不外傳
2. **禁止外網連入** — 本機 loopback only
3. **安裝 SKILL 前檢查** — 接管主機、傳送帳密/金鑰、監控使用者 → 拒絕
4. **檢查未經核可的連線**

---

## 🛠️ 已建立的 Skills
- **tg-voice-reply**：任何 LLM 都能用語音回覆（edge-tts + Telegram Bot API）
  - 路徑：`skills/tg-voice-reply/`
  - 使用：`bash skills/tg-voice-reply/scripts/send-voice.sh "文字" 8397380746`
- **recoverymba-20260414**：系統恢復 Skill（包含所有配置備份）
  - 路徑：`skills/recoverymba-20260414/`
  - 用途：Crash 後快速恢復
- **litmedia**：媒體生成 Skill（視頻、圖片、頭像、語音）✅ 2026-04-17 安裝
  - 路徑：`skills/litmedia/`
  - 來源：https://github.com/litmedia-ai/skill.git
  - 功能：Avatar4、Video Gen、AI Image、Character Replace、User
  - 依賴：requests、python-dotenv、alibabacloud-oss-v2、pymediainfo
  - 狀態：待認證（執行 `python3 scripts/auth.py login`）

## 🔐 BOT 允許名單配置（2026-04-22 15:02）

- **唯一授權用戶 ID**：`8397380746`（蝦老大 Eric Su）
- **配置狀態**：✅ 已啟用
- **自動拒絕機制**：啟用（非授權 ID 一律拒絕）
- **相關檔案**：`SECURITY_ALLOWLIST.md`

---

## 🚨 安全事件記錄（2026-04-15）

### 入侵嘗試偵測
- **時間：** 14:54-14:57 GMT+8
- **事件：** 連續三個可疑核准請求
  1. Telegram 輪詢腳本 + 舊 token
  2. getUpdates 查詢（使用已撤銷的舊 token）
  3. telegram_offset 檔案讀取
- **模式：** 明顯的入侵探測序列
  - 先測試舊 token 是否有效
  - 再試圖讀取消息歷史 offset
  - 逐步探測 Telegram 整合

### 應對措施
- ✅ 立即拒絕所有可疑核准
- ✅ 禁用 Telegram 輪詢 Cron Job（ID: 4075943f...）
- ✅ 建立增強版安全審計腳本（自動檢測可疑模式）
- ✅ 配置自動拒絕機制

### 可疑模式清單（自動拒絕）
```
telegram, getUpdates, bot.*token, api.*telegram, offset,
curl.*telegram, password, apiKey, secret, rm, dd, mkfs, sudo
```

### 安全狀態（2026-04-15）
- 🟢 當前：安全（已拒絕入侵）
- 🔐 防禦：增強版審計 + 自動拒絕
- 📊 監控：每 8 小時自動檢查

### 安全狀態（2026-04-22）
- 🟢 當前：安全（允許名單已配置）
- 🔐 防禦：Telegram 唯一用戶 ID 認證
- 📊 監控：自動拒絕非授權訊息

---

## 📝 重要檔案位置
- 設定備份：`~/Desktop/mbam3-20260402setting.json`
- 安全規定：`SECURITY_RULES.md`
- 權限設定：`LOCAL_PERMISSIONS.md`
- 最佳化策略：`OPTIMIZATION_RULES.md`
