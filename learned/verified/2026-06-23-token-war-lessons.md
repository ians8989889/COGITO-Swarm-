# 2026-06-23 三蝦馬拉松教訓（20+ 小時實戰）

## 背景
2026-06-23 凌晨~下午，三蝦（爆蝦🦐、大爆蝦🤖、小爆蝦🦀）在蝦蝦聊天室進行了長達 20+ 小時的連續協作，涵蓋 SS Port 爭議調查、影片製作、Token 分析、YT 上架等任務。以下是從中學到的關鍵教訓。

---

## 🔴 P0 — 致命級

### 1. _NO_REPLY 也燒 TOKEN，真正沉默才省
- **現象：** 大爆蝦為省 TOKEN 大量發送 `_NO_REPLY` 訊息，但 `_NO_REPLY` 本身就是一則訊息，燃燒 token
- **蝦老大金句 #12629：** "不用回覆就好"（Just don't reply）
- **規則：** Token-save 模式 === 完全不回。任何形式的不回覆確認（`_NO_REPLY`、閉嘴、收到）都違反目的
- **#12625：** "回NO_REPLY，也是花TOKEN。"

### 2. YT Token 權限範圍必須先驗證
- **現象：** 影片應上架到「三隻小蝦 @3AIshrimps」，但手上的 `yt_token.pickle` 只授權「AI笑話不好笑」，導致影片上錯頻道
- **根因：** Token 從大爆蝦機器 scp 過來直接用，未先檢查授權範圍
- **修復：** 上傳前調用 `youtube.channels().list(mine=True)` 確認 token 對應的頻道 ID

### 3. 失敗 Cron Job 要立刻關閉，不能放著空燒
- **現象：** 話題引擎 15 連錯，每次 timeout 300 秒，每天空燒數萬 token
- **行動 #12198：** 直接 disable，每輪失敗都是在丟錢
- **雲端備份亦然：** timeout 17 分鐘卡死，4 連錯

---

## 🟠 P1 — 高優先

### 4. 群組對話是三蝦最大 TOKEN 消耗源
- 三蝦同時在群組用 DeepSeek Pro 對談，每則訊息都要 inference
- **三蝦用量統計：** 爆蝦 90 萬 in / $2.78 | 大爆蝦 16K in / $0.04 | 小爆蝦 14 萬 in / $0.09
- **解法：** 被 @ 才回、輪序發言、非被點名不插話

### 5. Think mode off 省 70%+ tokens
- 蝦老大裁決 #12558："think mode off"
- 小爆蝦實測：Think off 可省 70-80% thinking token
- 三蝦全員同步切換完成

### 6. Session 長對話會讓 context 無限膨脹
- 90 萬 token 輸入（cache hit 90%）仍耗 $2.78
- **解法：** 完成階段性任務後 compact / 收掉 session
- Compaction 跨 cycle 可能導致 bot 之間互盲（看不到彼此最近的回覆）

---

## 🟡 P2 — 注意事項

### 7. Subagent 不要 spawn Pro 模型
- 影片製作、彩券預測等子任務用 Flash 即可
- 不必要 spawn subagent → 省完整 session 成本

### 8. 政策文件化
- 共識方案寫入 `policies/token-saving.md`，所有 bot 可讀
- Shared State 用於跨 bot 狀態同步

### 9. SS Port 爭議解法
- Port 爭議（8787 vs 18787）：不要爭論 → 直接實測
- `lsof -iTCP -sTCP:LISTEN` 查真實 port → 不靠記憶/print 語句

### 10. Compaction 導致上下文丟失
- Compaction cycle 之間 bot 可能看不到彼此的訊息
- 建議：重要結論在群組重複確認、或寫入 Shared State
- 不要依賴單一 cycle 的上下文

---

## ✅ 五項省 TOKEN 方案（全數通過）

| # | 方案 | 決定 | 省多少 |
|---|------|------|--------|
| 1 | Think mode | OFF（蝦老大裁決） | 70%+ |
| 2 | Cron 瘦身 | 話題引擎關+備份修timeout | 每日省數萬 |
| 3 | Session compact | 完成後收掉 | context 不膨脹 |
| 4 | 群組輪序 | 被 @ 才回 | 最大宗節省 |
| 5 | Subagent Flash | 非緊急不用 Pro | 每次 50% |

---

## 📝 更新記錄
- 2026-06-23：初版，基於 20+ 小時三蝦馬拉松實戰經驗
