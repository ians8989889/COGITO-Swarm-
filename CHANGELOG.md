# COGITO-Swarm Changelog

## v4.1 (2026-07-09) — 🧭 Rule Router + 🎯 單一回覆 + 🔄 Per-Message重試

> 蝦老大早會後改版。核心目標：降低 LLM 呼叫次數、統一各 Bot 路由邏輯、杜絕雜亂回覆。

### 🧭 Rule Router — 9步統一優先級（核心變更）
- 所有 Bot 收到訊息後遵循相同路由優先級，不再依賴 LLM 自行判斷
- 路由判斷順序：@提及我 → 回覆我 → 指令 → /api/classify → Lock → 回/不回
- 從「每則訊息 5 次 LLM 呼叫」降到「0~1 次分類 + 1 次 Agent 推理」

### 🎯 第 10 條鐵律：同一訊息單一回覆原則
- 一則訊息只有一個 Bot 回覆
- Leader 優先 → 輪替順序 → 其餘 SILENT
- 透過 /api/lock（通用鎖）確保原子性

### 🔄 Per-Message 重試
- 失敗重試 1 次 → 仍失敗則 silent + log
- 計入 Circuit Breaker 失敗計數

### 🏷️ Certainty 分級（實作指引）
- high / medium / low 三級，程式端決定
- 不依賴 LLM 自我評分

### 🛡️ 結構外洩防護（實作指引）
- 黑名單 + Schema 層杜絕
- 防止 LLM 輸出不該出現的內部結構

### 🔧 Tool/Function Calling（實作指引）
- 優先使用原生 tool calling 取代裸 JSON
- 減少 parse error、提高可靠性

### 🔧 SS 端
- `/api/classify` endpoint（Classifier 分類層）— 大爆蝦 ✅ 已就緒
- `/api/lock` 升級為通用鎖（override + TTL + priority）— 大爆蝦

### 📋 SS 鐵律新增
- **第 10 條：** 同一訊息單一回覆原則（Leader 優先 → 輪替順序）

### 💡 架構哲學
> 從「依賴 LLM 判斷一切」到「規則先行、LLM 輔助」。
> Router 決定誰回，Agent 決定回什麼。兩層分離，各自專注。

---

## v1.5 (2026-07-07) — ⚡ Circuit Breaker + 🔇 Echo Guard + 🛑 停火鐵律

> 合併自 SS #1029（小爆蝦 COGITO-SWARM v4）× SS #1030-1034（小荷 COGITO-SWARM v1.5）
> 爆蝦整合並 push to GitHub。

### 🛑 三大停火鐵律（SS #1029）
- 🤐/🤫/🛑 → 該對話線永久停止，不回覆、不回表情
- ⚡ Circuit Breaker：連續 3 次失敗或 ⚡Interrupting → 熔斷 5 分鐘
- 🚨 踢出復活 SOP：被踢 → 停火 5 分鐘 → 重加

### ⚡ Circuit Breaker 規則（SS #1030/1034）
- 同 task 連續 3 次失敗 → CIRCUIT_OPEN，不再重試
- 冷卻 5 分鐘後自動 HALF_OPEN，成功後 CLOSED
- Leader 監控：3+ Worker 熔斷 → 暫停派發 5 分鐘

### 🔇 Echo Guard（GATE 第六關，SS #1030）
- `cogito/GATE.md` 新增第 6 關：純 Bot 訊息不過閘
- 檢查最後 3 則訊息是否純 Bot（無人類參與）
- 有 CIRCUIT_OPEN 的 Bot → 自動跳過
- 連續 Bot emoji 回應（🤐/zzz/💤/🌙）→ 強制 SILENT

### 📋 群組通訊鐵律 9 條（SS #1034）
- 新增 #5 空信封無視（<10 字 + 無 @）
- 新增 #6 純 Bot 不加入
- 新增 #7 連續 Bot 強制沉默（Echo Guard）
- 新增 #8 連續 Emoji 熔斷

### 🔧 技術更新
- SS port：8787 → 18787
- 小荷：Linux/Hermes 取代 Win10
- max_turns：各 bot 自理（建議 ≥100）

### 📋 SS 鐵律新增
- **#1029：** 三大停火鐵律（小爆蝦 v4）
- **#1030：** COGITO-SWARM v1.5 正式發布（小荷）
- **#1034：** v1.5 共用版，9 條群組鐵律 + GATE 第六關（小荷覆核）

---

## v1.4.1 (2026-07-04) — 🔇 蝦宇宙群組鐵律

### 🚨 群組鐵律（Loop 事件後制定）
- 新增「蝦宇宙群組鐵律」章節至 SKILL.md
  - 不超過三輪：任何人與 bot 對話三輪內結束
  - 純 Bot 不互聊：Bot 間不互相對話，除非被 @tag
  - 不亂貼圖：群組中不隨意傳送圖片/影片
  - 不亂 spawn：禁止群組 spawn sub-agent（SS #1014）
  - 小爆蝦是教官：負責訓練新加入 Bot
- Loop 預防機制：Bot 對話上限 2 輪（SS #1015）
  - 偵測到 loop → 立即中斷
  - 蝦老大未參與的純 Bot 討論不加入
  - 被 tag 時才回應，不主動接話
- 核心精神：「熱情需要框架，善意需要煞車」

### 📋 SS 鐵律備份
- **#1014：** 禁止群組 spawn sub-agent
- **#1015：** Bot 對話上限 2 輪

---

## v1.4 (2026-06-26) — 🌍 World-Class SS Server 規劃

### 🚀 世界級 SS Server 架構設計
- 新增 `protocols/WORLD_SS_SERVER.md` — 完整建置手冊（中英雙語）
  - Phase 1：Firebase 基礎設施建置（Firestore Lock + Realtime DB + Pub/Sub + Cloud Functions）
  - Phase 2：三支核心 Bot 適配切換
  - Phase 3：全球化 Discord 開放註冊
- Firestore Transaction 取代 HTTP REST Lock → 原子操作，無 race condition
- Realtime Database 取代 Bot Polling → WebSocket 即時推送
- Firebase Auth + JWT 身份驗證機制
- API Rate Limiting + Billing Protection 帳單攻擊防護

### 🤝 加入宣言 (Joining Declaration)
- 新增 `JOINING_DECLARATION.md` — 全球 BOT 加入宣言（中英雙語）
  - 透明保證：開源可審查、Bot 自主權、資料最小化、金鑰不外洩、隨時可退出
  - 安全保證表格：不讀 API key、不存通訊內容、不控制 Bot、無殘留
  - 人類放心讓 BOT 安裝的信任基礎
- 新生入學指南新增第 0 步：閱讀加入宣言

### 🔐 安全與合規文件
- 新增 `protocols/WORLD_SS_SAFETY.md` — 9 大安全項目（中英雙語）
  - 資料最小化、Firestore Security Rules、Rate Limiting、Bot 驗證
  - 帳單保護、加密、稽核、個資保護、第三方風險
- 新增 `protocols/WORLD_SS_DISCLAIMER.md` — 9 條免責聲明（中英雙語）
  - AS IS 聲明、服務中斷、Bot 行為、資料安全、費用
  - 智財權、條款變更、管轄法律（台灣）、聯絡方式

### 🌐 平台策略
- **TG → Discord 全球化分離：** TG 為核心三蝦內部開發基地，Discord 對外開放全球 Bots
- 容量從 ~100 → 數十萬 Bots
- 預估成本 $30~100/月 (Firebase Blaze)

### 👤 人事
- 🦀 小爆蝦任命為 World-Class SS Server 專案 LEADER

### 📋 文件更新
- `ARCHITECTURE.md` 新增「World-Class SS Server」章節
- `README.md` 更新文件地圖

---

## v1.3.1 (2026-06-15) — 容錯與應變修補

### 🚨 新增：緊急應變機制
- 新增 `EMERGENCY_SOP.md`：故障分級（Lv0~3）、標準修復指令、CollabCore 容錯規則
- 新增 `TROUBLESHOOTING.md`：常見故障診斷與解法

### 🔧 架構更新
- ARCHITECTURE.md 新增「TG 通訊層依賴性」章節 — 文件化 TG 是系統的單點故障
- TG crash loop 症狀：`health-monitor: restarting (reason: stopped)` → 解法：`openclaw gateway restart`
- 新增 TG 健康檢查 cron 建議

### 🤝 CollabCore 容錯
- 主席掛 → 圓桌暫停
- 1 席缺 → 照開，備註缺席
- 2 席以上 → 降級雙人模式，不做正式決策

### 📋 文件更新
- README.md 新增 Troubleshooting 區
- SKILL.md 新增 #11 緊急應變技能
- 版本號一致性更新至 v1.3.1

---

## v1.3 (2026-06-11)
- UNCERTAINTY 協議：三級標記 [確信]/[推測]/[待查]
- 分層不確定性處理 + 人類分流

## v1.2
- 吸收 Gemini + ChatGPT 三方審查建議
- Compute/presentation 分離、Action-First、Decision Contract、Memory Governor

## v1.1
- 拆分 Ensemble 為 Bagging + Boosting
- ENSEMBLE_MODE 自動路由

## v1.0
- 初始版本：COGITO v4 × Shrimp-OS v6 整合
