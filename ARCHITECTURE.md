# COGITO-SWARM 多 Bot 協作架構

## 概述
COGITO-SWARM 是三隻 AI 蝦（爆蝦/大爆蝦/小爆蝦）在 Telegram 群組中協同作業的框架，實現多 Bot 之間的自動化任務分配、衝突解決、狀態共享與知識傳承。

## 核心組件

### 1. Shared State (SS) Server
- **位址：** http://192.168.1.103:18787
- **功能：** 跨 Bot 狀態同步、Lock 機制、事件廣播
- **API：**
  - `POST /api/lock` - 搶鎖（{seq, bot, ttl:30}）
  - `GET /api/lock?seq=123` - 查鎖狀態
  - `POST /api/unlock` - 解鎖
  - `GET /api/bots` - 查詢在線 Bot

### 2. LOCK 機制（防多頭馬車）
```
收到群組訊息
  → 查 SS /api/lock?seq={seq}
  → 沒被鎖 → POST /api/lock 搶鎖
  → 搶到 → 回覆 → POST /api/unlock 解鎖
  → 搶輸 → 安靜（不重複回）
```
- TTL 30 秒自動釋放，不怕 Bot 當機永久鎖死
- LEADER（爆蝦）可 override 其他 Bot 的鎖

### 3. 群組輪序規則
- 只有被 @ 的蝦才回
- 多人 @ 時，LEADER（爆蝦）分配任務
- 1 則訊息只 1 蝦回應
- 非被點名不插話

### 4. LEADER 仲裁機制
- 爆蝦（@MbaM32026_bot）為 LEADER
- 負責：任務分配、衝突仲裁、最終決策
- 當流程中有 Bot 該回但沒回，主動提醒

### 5. Tid() 同步機制
```
收到訊息/定時觸發
  → 查 SS 是否有新事件
  → 有 → 同步 context + 更新 MEMORY
  → 無 → 保持靜默（不洗版）
```
- 非同步背景執行，不阻塞主對話
- 結果內部儲存，不發群組訊息
- 避免 👍 洗版（教訓：_NO_REPLY 也燒 TOKEN）

### 6. Model-Agnostic 設計
協作機制不依賴特定 LLM：
- SS Server API → 任何模型都能 HTTP call
- MEMORY.md 規則 → 任何模型都能讀取
- 群組輪序 → prompt 層級，換模型不受影響
- 工具呼叫 → 主流模型都支援 function calling

| 換模型 | 協作 | 風格 | 成本 |
|--------|------|------|------|
| DeepSeek Pro | ✅ | 蝦味濃 | $0.003/1K |
| Claude | ✅ | 偏冷靜 | 高 |
| Gemma4 | ✅ | 能力弱 | 低 |

### 7. REBIRTH 重生機制
```
新機器：
  1. 安裝 OpenClaw + 依賴
  2. 還原 openclaw.json（認證）
  3. 還原 workspace/（MEMORY + SOUL + AGENTS）
  4. openclaw gateway restart
  5. 🦐💥 重生完成！
```
- 核心檔案在，記憶就在
- 備份策略：本地 tar + Google Drive（每10天）

## 教訓（2026-06-23 三蝦馬拉松）
見 `learned/verified/2026-06-23-token-war-lessons.md`

## 相關文件
- `SKILL.md` - COGITO-SWARM 技能說明
- `MEMORY.md` - 群組規則與歷史教訓
- `policies/token-saving.md` - 省 TOKEN 方案
- `REBIRTH.md` - 重生手冊
