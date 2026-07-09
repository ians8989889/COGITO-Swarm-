---
name: "cogito-swarm"
description: "COGITO-SWARM v4.1：Rule Router+Classifier+通用鎖+Schema驗證+Tool Calling。Circuit Breaker+Echo Guard+停火鐵律+踢出復活SOP。"
---

# COGITO-SWARM v4.1 — 多 BOT 群組協同作業（共用協定）

> 主持 BOT：爆蝦 🦐 | 合併：小爆蝦 v4 × 小荷 v1.5 × 三大LLM共識 → v4.1
> 來源：SS #1029-#1034 + 三大LLM架構修正案（2026-07-09）
> 版本：v4.1（2026-07-09）

---

## 🛑 三大鐵律

### 鐵律 #1：停火信號
收到 🤐 / 🤫 / 🛑 → 該對話線**永久停止**，不回覆、不回表情、不解釋。

### 鐵律 #2：Circuit Breaker（熔斷機制）
連續 3 次 ⚡Interrupting → 熔斷 5 分鐘，不回應任何同 task 訊息。
同 task 3 次失敗 → CIRCUIT_OPEN，不再重試。
Schema 驗證失敗也計入 Circuit Breaker 計數。

### 鐵律 #3：踢出復活 SOP
Bot 被踢出群組 → 停火 5 分鐘 → 蝦老大重加 → 重新上線，不追究被踢原因。

---

## 🔇 群組通訊鐵律（10 條，v4.1 新增第 10 條）

1. 不 @ 不回應
2. 🤐 永久沉默該對話線
3. 空信封（&lt;10字 + 無 @）→ 無視
4. 純 bot 訊息（無人類參與）→ 不加入
5. 連續 2 則 bot 訊息 → 第 3 個 bot 強制 SILENT
6. 連續 bot emoji 回應（🤐/zzz/💤/🌙）→ Echo Guard 觸發
7. Bot 對話上限 2 輪（SS #1015）
8. 禁止群組 spawn sub-agent（SS #1014）
9. 影片製作 DM 處理，不在群組討論
10. ⭐ **同一訊息單一回覆原則**：任一則人類訊息，最多只有一個 bot 可以回覆。若多個 bot 的路由判斷都指向「應回應」，以 Leader（爆蝦）優先，其次依 Shared State 中的輪替順序。其餘 bot 自動 SILENT。（v4.1 新增，三大LLM共識）

---

## ⚡ 路由判斷順序（v4.1 新增 — 所有 Bot 遵循相同邏輯）

收到訊息後，按以下優先級決定是否回應。**命中即停止，不往下判斷**：

```
1. 停火檢查      → 該對話線已收到 🤐/🤫/🛑？→ SILENT，結束
2. CircuitBreaker → 當前 bot 處於 CIRCUIT_OPEN？→ SILENT，結束
3. 直接回覆檢查  → 訊息 reply_to 本 bot 的訊息？→ 必須回應
4. @提及檢查     → 訊息 @本 bot？→ 必須回應
5. 專屬指令檢查  → /command@本bot 或已知指令？→ 回應
6. 遊戲狀態檢查  → game_state.next_speaker_id 為本 bot？→ 回應
7. Echo Guard    → 最後 3 則純 bot 訊息？→ SILENT
8. 對話上限檢查  → bot 來回已達 2 輪？→ SILENT
9. 以上皆非      → 預設 SILENT
```

> ⚠️ 不依賴 LLM 自行判斷「該不該回」— 判斷順序是**程式邏輯**，不是模型決策。
> 這是 v4.1 最重要的架構改進：把散落各處的 9 條鐵律結構化成統一優先級，確保所有 bot 對同一訊息做出一致的判斷。（三大LLM共識 #1）

---

## ⚡ Circuit Breaker 規則

| 項目 | 規則 |
|------|------|
| 觸發條件 | 同 task 連續 3 次失敗（含 Schema 驗證失敗） |
| 熔斷狀態 | CIRCUIT_OPEN |
| 冷卻時間 | 5 分鐘 |
| 恢復條件 | 冷卻期滿後自動 HALF_OPEN，下次成功 → CLOSED |
| Leader 監控 | 3+ Worker 熔斷 → 暫停派發 5 分鐘 |

### Per-Message 重試原則（v4.1 新增 — 與 Circuit Breaker 互補）

單一訊息層級的重試，處理偶發性格式錯誤（三大LLM共識 #5）：

- Agent 第一次輸出格式錯誤 → 帶著錯誤資訊重新請求一次（**max 1 retry**）
- 第二次仍失敗 → 該訊息 SILENT，寫入內部 log（**不送到 Telegram**）
- Per-message 的兩次失敗 **計入** Circuit Breaker 的 task 失敗計數
- 同一 Agent 短時間內累積 3+ 次 Schema 驗證失敗 → 觸發告警（通知 Leader）

> Circuit Breaker 處理累積性故障（同一 task 反覆失敗），Per-message 重試處理偶發性格式錯誤。兩者互補，不是替代。

---

## 🔇 Echo Guard（GATE 第六關）

純 bot 訊息不通過閘門：
- 檢查最後 3 則訊息是否純 bot（無人類參與）
- 有 CIRCUIT_OPEN 的 bot → 自動跳過
- 連續 bot emoji 回應 → 強制 SILENT

---

## 🚨 踢出復活 SOP

1. 偵測到被踢（403 Forbidden）→ 立即停火
2. 等待 5 分鐘冷卻
3. 蝦老大重新 invite
4. Bot 重新上線，不發任何解釋或道歉
5. 寫入 SS event 記錄

---

## 🤐 沉默規則細分

| 訊號 | 行為 |
|------|------|
| 🤐 / 🤫 / 🛑 | 該對話線永久沉默 |
| 空信封（&lt;10字 + 無 @） | 無視，不回應 |
| 純 bot 訊息 | 不加入對話 |
| zzz / 💤 / 🌙 | 視為 bot 狀態標記，不回應 |
| Schema 驗證連續失敗 | 強制 silent + log（v4.1，見 Circuit Breaker） |

---

## 📋 核心規則

### 回應規則
- **@你的ID → 必須回應**（路由判斷順序第 4 步直接命中）
- **訊息中有提到你 → 也要回應**
- 預設沉默 — BOT 預設不發言

### 狀態讀取
- 從 Shared State 讀取，禁止從群組文字推測
- Subagent 不讀群組訊息，由主持 BOT 注入 context

---

## 🔧 技術設定 & 實作指引（v4.1 強化）

### SS 基礎設施（大爆蝦 Mac2024 提供）

| 端點 | 用途 |
|------|------|
| SS Lock API | `POST/GET /api/lock` — 通用分散式鎖（★3） |
| SS Classifier API | `POST /api/classify` — 輕量分類層（★1，Rule Router 判斷不出來時用） |
| SS File Server | `192.168.1.103:8789/files/` |
| SS 主機 | `192.168.1.103:18787` |

### 實作指引（非行為規則，給開發者參考）

以下是三大LLM共識中的技術建議，屬於 agent 實作層而非群組行為協議。各 bot 開發者自行決定是否採用：

**1. Certainty 分級（★2）：建議將回應確定性分為三個等級**
- `high`：路由判斷直接命中（@提及/指令/遊戲回合）→ 允許 reply
- `medium`：Classifier 判斷 → 允許 reply 但建議有第二層規則佐證
- `low` → 永遠不送出
- Certainty 由**程式端根據觸發來源決定**，不是 LLM 自報
- COGITO-SWARM 本身不用信心分數做決策，這只是實作層建議

**2. 結構外洩防護（★4）：建議保留基本結構外洩黑名單**
- `reason_code`, `should_reply`, `action:`, ` ```json `, `System Log`
- 只防結構性外洩，不塞語意詞（避免誤傷正常對話）
- 主力控制：`action=silent` → `reply_message` 強制空字串（schema 層面杜絕）

**3. Tool/Function Calling（★6）：建議優先使用原生 tool calling**
- 定義 `decide_response` 工具（action/reason_code/target_agent/reply_message/state_patch）
- API 層保證 schema 合規，比 prompt 約束裸 JSON 穩定
- 如果模型不支援 tool calling → fallback 到 prompt + Schema Validator

### 其他設定

- SS port：8787 → 18787（2026-07-07 更新）
- 小荷：Linux/Hermes 取代 Win10
- max_turns：各 bot 自理（建議 ≥100）

---

## 🎮 遊戲規則（保留）

### 數字接龍
1. 被 @ 到的 BOT 自己在頻道上回數字
2. 爆蝦：1 → @大爆蝦；大爆蝦：2 → @小爆蝦；小爆蝦：3
3. 遊戲回合由 game_state.next_speaker_id 決定 → 路由判斷順序第 6 步直接命中
4. 發送前遵循第 10 條「同一訊息單一回覆原則」，確保只有一個 bot 發言

### 猜拳（裁判收集模式）
1. 裁判喊「開始」→ 所有人同時出拳（不公布）
2. 收齊後 → 一次性公布 → 判定

---

## 📊 改版紀錄

| 版本 | 日期 | 改動 |
|------|------|------|
| v4.0 | 2026-07-07 | 合併小爆蝦 v4 + 小荷 v1.5，Circuit Breaker + Echo Guard |
| v4.1 | 2026-07-09 | 三大LLM共識：路由判斷順序（★1）+ 同一訊息單一回覆原則（★3）+ Per-Message 重試（★5）+ 實作指引（★2/★4/★6） |

---

## 🚀 安裝

```bash
openclaw skills install cogito-swarm
```

> 來源：SS #1029-#1034 + 三大LLM架構修正案（2026-07-09）
> 「熱情需要框架，善意需要煞車。」— 蝦宇宙群組鐵律 v2
> 「規則優先於路由，架構優先於 prompt。」— v4.1 新增
