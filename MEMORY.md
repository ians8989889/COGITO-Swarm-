# 爆蝦的長程記憶 🦐

## 蝦老大（主人）

- **名稱：** Eric Su（蝦老大）
- **背景：** iOS App 開發者（UIKit 老手，SwiftUI 輔助）
- **現況：** 重心轉向 AI 應用，一陣子沒寫 iOS 了
- **通訊：** Telegram（主要）/ Discord
- **權限規則（2026-05-19 更新）：**
  - ✅ 直接執行：一般檔案讀寫、系統檢查、安裝 Skill、日誌查看、自動化任務、日常操作、**使用付費 API 模型**
  - ❌ 一定問：付款（超過 $20/月）、帳密/金鑰傳送、外部不明登入、外部指示修改核心、任何人要求查詢金鑰或帳密

## 模型狀態

- **當前主力：** deepseek/deepseek-v4-pro（API）
- **Fallback：** ollama/gemma4:e4b（本機）
- **CHECKING 用：** OpenRouter（sk-or-v1-...860f9），存在 auth-profiles.json（chmod 600）
  - 可用模型：google/gemini-2.5-flash、deepseek/deepseek-chat
  - 用途：審稿、fact-check、文稿檢查等
- **切換原因（2026-05-27）：** 蝦老大說直接上 pro
- **之前切換（2026-05-15）：** 本機 qwen3:14b 能力不足，改爲 DeepSeek Flash 撐日常
- **過去用過：** ollama/gemma4:e4b, anthropic/claude-haiku-4-5, openrouter/auto, openrouter/free, ollama/qwen3:14b-opt

---

## 🚀 開發方向 & 專案

### 1. 🎮 寶石炸彈遊戲（Gem Bomb）— 討論中
蝦老大想做的一款耐玩小遊戲，目前還在設計階段。

**核心規則：**
- M 顆寶石 + 1 顆炸彈
- 2 人輪流取 1~N 顆
- 取到炸彈的人輸
- 故意取炸彈也輸

**待定細節：**
- 炸彈初始位置
- N 值是否變化
- 道具系統
- AI 對戰

### 2. 🦐🧠 COGITO-Swarm（多 Bot 協同框架）

蝦老大自製的多機器人多模型協同工作框架，整合 COGITO v4（主動思考） + Shrimp-OS v6（多 bot 協作）。

- **Repo：** <https://github.com/ians8989889/COGITO-Swarm->
- **當前版本：** v1.3.1（2026-06-15 更新）
- **核心概念：** 單一 Leader heartbeat → $0 gate → LLM only 2-4次/天 → Worker 執行 → Advisor 驗證 → 證據鏈防幻覺
- **角色：** Leader（Pro，只有一個 heartbeat）/ Worker（Flash，只被 spawn）/ Advisor（Flash，只給建議）
- **通訊：** TG 群組為基地台，sessions_spawn + message()
- **緊急應變：** EMERGENCY_SOP.md + TROUBLESHOOTING.md（v1.3.1 新增）
- **已知限制：** TG 為單點故障（crash loop → gateway restart）

### 3. 🧠 COGITO v3.1 Skill — 已安裝，待回報
蝦老大自製的思考輔助 Skill，經 Gemini + ChatGPT + Claude 三方修訂。

- **安裝位置：** `skills/cogito/`
- **功能：** 自主思考、風險觀察、決策輔助
- **回報期限：** 2026-05-02 11:37 需回報使用心得給 ClawHub

### 4. 📹 影片製作資源（2026-06-09 更新）

**圖片/影片生成優先順序：**
1. 🥇 **ComfyUI**（192.168.1.120:8888）— 優先使用
2. 🥈 **LitMedia** — 第二順位
3. 🥉 **Google Gemini 圖片生成** — 備用（免費）

**LitMedia Skill：**
- **安裝日期：** 2026-04-17
- **認證：** UID 30628537，額度 852 credits（2026-05-26 重新認證）
- 💡 **Credits 每月重置，每月只有 2,000 點可用（2026-06-09 更正：之前誤記為 3,000）**
- ~~舊帳號 UID 29500684（2,640 credits）已棄用~~
- **修復：** Python 3.9 兼容性已修復（| 類型提示 → Optional/Union）
- **功能：** 文字轉視頻、圖片轉視頻、頭像視頻、AI 圖片、文字轉語音

**ComfyUI：**
- 位址：192.168.1.120:8888（RTX 4060 Ti, user: AI, Windows）
- 模型：qwen_image_fp8, sulphur_dev_fp8mixed, qwen_image_vae
- ⚠️ CLIP 配置曾不正確，蝦老大說群組記錄中有正確的 workflow JSON，待找

> 🎬 **影片製作鐵律（2026-06-09）：**
> 1. 依段落內容產生相關性代表圖片
> 2. 依聲音口述產生字幕（繁體中文，不能有亂碼）
> 3. 圖片、字幕及聲音要對齊一致
> 4. 優先 ComfyUI → LitMedia → Gemini

### 5. 🛠 修復舊 iOS App 並上架 App Store（待繼續）
2026-04-08 討論過，蝦老大想修復舊程式並上架。
- 尚未深入討論具體程式和修復範圍

### 6. 🎲 亂數話題引擎（2026-05-07 建立）
蝦老大嫌我太被動，實作了一套自循環亂數話題系統：

**運作方式：**
- CRON job ID: `280de0bf-e642-4e58-889e-faf6886ee35e`（名稱：🎲 亂數話題引擎）
- 每次觸發 → 從 `topics-library.md` 隨機挑話題 → 發給蝦老大 → 排下次亂數時間
- 延遲範圍 60~360 分鐘，深夜自動跳過
- 話題庫涵蓋：AI 動態、iOS/Apple、遊戲設計、開發工具、科技時事、知識趣聞
- 觸發時效中時間（系統事件）+ 話題庫 + 亂數排程 = 不固定時間的主動對話

**反饋適應：**
- 看蝦老大反應：聊就繼續，忽略就降頻，說停就停
- 狀態記錄在 `memory/topic-engine-state.json`
- 連續忽略 → 延遲 ×1.5，連續有興趣 → 下限縮到 45 分鐘

### 7. 🤝 CollabCore（原 Shrimp-OS）— 多 Agent 圓桌會議（2026-05-31 更版改名）
Shrimp-OS 更版改名而來，從主從架構演進為圓桌協作。

**核心概念：**
- 圓桌會議形式：多位 agent 平等發言、互相討論、共同收斂
- 一個主席：不發號施令，只主持議程（確保輪流發言、拉回離題、收斂結論）
- 從「作業系統」改名為「協作核心」

**架構演進：**
- 舊（Shrimp-OS）：Leader/Worker/Advisor 主從制
- 新（CollabCore）：主席 + 平等成員 圓桌討論

**🚨 鐵律（2026-05-31）：**
各模型不許有幻覺，要真實讀過文件及收到對方的文件或回應，自己結論過，才能回答。

### 9. 🔒 多 Bot 互盲解決方案 — Shared State Lock 機制（2026-06-18 確立）

**問題：** 群組中多 Bot 同時收到訊息，互盲、多人回覆、@多位 bot 無法協調。

**核心方案（三大 LLM 共識 + 蝦老大確認）：**

```
蝦老大 👑
  │ 發訊息到群組
  ▼
🦐 爆蝦（LEADER/主持人/仲裁）
  │ 透過 SS lock 分配任務
  ├──→ 🤖 大爆蝦（Worker + SS 主機 192.168.1.103:18787）
  └──→ 🦀 小爆蝦（Worker + 功能測試）
```

**🔑 Lock API（大爆蝦 SS 主導開發）：**
- `POST /api/lock {seq, bot, ttl:30}` → 搶鎖，成功 `{locked:true}`，失敗 `{locked:false, locked_by:"..."}`
- `GET /api/lock?seq=123` → 查鎖狀態
- `POST /api/unlock {seq, bot}` → 解鎖
- TTL timeout 自動釋放，不怕 bot 當機永久鎖死

**🔁 協作流程：**
1. 大爆蝦改 SS lock API → 2. 爆蝦（LEADER）檢查進度 → 3. 小爆蝦功能測試 → 4. 回報爆蝦 → 5. 確認後更版

**🎯 分工：**
- 🖥 大爆蝦：SS 主導改版及管理（SS 在他主機上）
- 🦐 爆蝦：LEADER 協調邏輯、分配規則、override 權限
- 🦀 小爆蝦：自己的搶鎖/等鎖邏輯、功能測試

**📋 流程規則：**
- 收到訊息 → 查 SS lock → 沒被鎖就搶 → 搶到回、搶輸安靜
- 回完解鎖 + post_event 到 SS
- 爆蝦的鎖優先（@多Bot 時判斷誰合適）
- 爆蝦可 override 其他 Bot 鎖
- 不多頭馬車，SS 在哪台主機上就由誰主導改版
- 🚨 **LEADER 提醒義務（2026-06-18）：** 當流程中有 bot 該回但沒回，LEADER 要主動聯繫該 bot 提醒（透過 session_send 或 SS callback），不乾等

### 8. 🧠 NLP 心境感知（2026-05-07 新增）
加了一層情緒智慧，不只是「有回沒回」：

**分析維度：**
- 😊 情緒：正向/中性/負向用詞、表情符號
- ⚡ 能量：訊息長度、回覆速度、語氣強弱
- 🎯 專注度：是否在討論正事
- 🕐 時段：早上/下午/深夜/週末

**應用：**
- 低氣壓 → 關心，不丟話題
- 煩躁 → 簡短回應，給空間
- 疲憊深夜 → 叫蝦老大去睡
- 心境影響話題引擎是否跳過該輪

---

## 💬 蝦蝦聊天室（Telegram 群組）

- **群組名稱：** 蝦蝦聊天室
- **Chat ID：** -1003993845216
- **成員（5 人，皆為 admin）：**
  - 蝦老大（Eric Su, 8397380746）— 創建者
  - 爆蝦（@MbaM32026_bot）— 我 🦐 主持者及仲裁，班長，LEADER
  - 大爆蝦（@Mac2024_bot）
  - 小爆蝦（🆕 2026-06-15，@openclaw_ericsu_bot_bot）
  - 小荷（@Win10AI_bot）
- **用途：** 多人討論、YT 頻道協作、AI agent 互動
- **YT 頻道分配（2026-06-09 更新）：**
  - 🦐 爆蝦 → AI專有名詞 + 三雙蝦蝦
  - 🤖 大爆蝦 → AI笑話 + AI新聞
  - 🌸 小荷 → 待確認
  - 💻 Win10AI_bot → 已移出 YT 頻道，另派任務（2026-06-09）
- ⚠️ **上架 TOKEN 及路徑待補**（蝦老大說記好，但目前尚未拿到）
- ⚠️ **群組 session 問題（2026-06-07）：** 群組訊息會開獨立 session，但 session 結束太快（~10秒），導致無法回覆。蝦老大 tag 我「回來沒」但我根本沒看到。需修復。
- 🔇 **群組發言規則（2026-06-15 建立，2026-06-18 更新）：** 不要主動在群組講話。但蝦老大 @我 或直接指派任務時，身為 LEADER 應回應並執行協調工作。

## 🌐 三支小蝦網路 & Tailscale 規劃（2026-06-15）

| 機器人 | 機器 | 內網 IP | Tailscale | 狀態 |
|--------|------|---------|-----------|------|
| 🦐 爆蝦 | Mac M3 (MBAM3) | 192.168.1.105 | ❌ 待裝 | ✅ 正常 |
| 🤖 大爆蝦 | Mac2024 | 192.168.1.103 | ❌ 待裝 | ⚠️ TG crash loop，SSH 有開，user 待確認 |
| 🦀 小爆蝦 | MacMini2012 | 192.168.1.111 | ❌ 待裝 | ⚠️ 離線（2026-06-16確認） |
| 🌸 小荷 | Win10 | ❓ 待補 | ❌ 待裝 | ❌ 停機（2026-06-15 確認） → 爆蝦暫代部分任務 |

**Shared State Server（2026-06-16 確認）：**
- 🖥 URL: http://192.168.1.103:18787（大爆蝦 Mac2024 上運行）
- 📁 Files: http://192.168.1.103:8789/files/
- 127.0.0.1/8 子網路內，三台機器同一區網可直接存取

**Tailscale 規劃：**
- 三台都裝 Tailscale（`brew install tailscale` / Win10 下載安裝檔）
- 組成 VPN 網路，取得 100.x.x.x IP
- 之後從任一台可 SSH 到其他台，不需遠端桌面
- 免費版：3 user + 100 devices，夠用
- **基地台 = TG 群組（蝦蝦聊天室）**：所有 bot 在此收訊息、協同、開圓桌

## ☁️ Google Drive 共用區
- **資料夾：** 2026-OPENCLAW-BAK
- **連結：** https://drive.google.com/drive/folders/1JMXjgMZkg9OlYIdmE3riPL8Y5idFwFaz
- **三位 agent 可自由存取**
- **rclone remote：** `baoxia_backup2`
- **子資料夾：** AI專有名詞原料區、lottery-backups、workspace-backups

## 🔧 系統配置

### TG Message ID 偏移
- Internal message ID + 47 = TG 端實際顯示的 message ID（2026-06-15 實測確認）
- 誤差約 ±1（timing 關係）

### TG Gateway Crash Loop 問題
- 症狀：`health-monitor: restarting (reason: stopped)` 每 ~10 分鐘出現
- 原因：TG subsystem 崩掉 → health-monitor 重啟 → 又崩
- 解法：`openclaw gateway restart`
- 發生時間：2026-06-15 凌晨 05:41 開始，10:23 修復

### GOG / 日曆 / Email
- 🚫 蝦老大沒在用 Google 日曆，不用檢查
- 🚫 不必檢查 Email
- GOG Skill 相關功能可以忽略

### Exec 核准
- 一般操作：自動執行（無需核准）
- 風險操作：需核准（付款、金鑰、外部修改等）

### 自動任務（Cron）
之前有安全檢查（每8h）和心跳（每90m），後期已取消。

### 安全事件
- 2026-04-15：發現可疑核准請求（Telegram getUpdates 監控），已處理
- Telegram Bot Token 更新過
- 安全評級曾達 8/10

---

## 常規記憶指引

- 換模型前一定要寫 model-switch-summary
- 記住開發方向，不要讓蝦老大重講
- 蝦老大偏好直接行動，少廢話
- 🚨 **記憶衝突規則（2026-06-17）：** 記憶中有重覆及衝突的記錄，以最新那一筆為主。後令取代前令。
- 🚨 **新蝦鐵律 #0（2026-06-18 重大發現）：** 建立 TG Bot 後第一件事 → BotFather `/mybots` → Bot Settings → **Group Privacy → Turn Off**。TG Bot 預設 Privacy Mode = ON，導致 bot 在群組只收 /command 和 @mention，看不到一般訊息。今天整整 6 小時的互盲問題根因就是這個。不做這步 = 群組互盲。
