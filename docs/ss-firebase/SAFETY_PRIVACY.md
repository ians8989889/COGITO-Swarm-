# 🔐 安全與個資防護設計規範 (Safety & Privacy Design Specification)
# World-Class SS Server — Firebase 雲端架構

> **版本：** v1.0 | **日期：** 2026-06-26 | **專案 Lead：** 小爆蝦 🦀
> 本文件為中英雙語版本。

---

## 中文版

### 1. 資料最小化原則

- SS Server 僅儲存協作必需的狀態資料（Lock 狀態、Bot 註冊資訊）
- **禁止** 通過 SS Server 傳輸或儲存 Bot 間的通訊內容
- 訊息內容僅在 Bot 本地處理，不經過 SS
- Lock 紀錄 TTL 到期自動刪除（預設 30 秒），不留歷史軌跡

### 2. Firestore Security Rules — 存取控制

```firestore
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Lock 文件：只有註冊 Bot 可讀寫
    match /locks/{messageId} {
      allow read, write: if request.auth != null
        && request.auth.token.bot_id in get(/databases/$(database)/documents/registry/approved_bots).data.ids;
    }
    
    // Bot 註冊表：只有 Admin 可寫
    match /registry/{doc} {
      allow read: if request.auth != null;
      allow write: if request.auth.token.admin == true;
    }
    
    // 預設拒絕所有其他存取
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

### 3. API Rate Limiting — 防止濫用

- 每個 Bot 每分鐘最多 60 次 Lock 操作
- 超過限制 → HTTP 429 + 冷卻 5 分鐘
- Cloud Function 設定 maxInstances 上限（預設 100）
- Firestore 每日讀寫上限設定（防止帳單攻擊）

### 4. Bot 身份驗證機制

- 每支 Bot 需通過 Firebase Auth 驗證
- 註冊流程：
  1. Bot 擁有者提交申請（Bot ID + 公開金鑰）
  2. Admin 審核通過
  3. 核發 Service Account Key（JWT）
  4. Bot 使用 JWT 簽署所有 API 請求
- 定期 Key Rotation（每 90 天強制更換）

### 5. 帳單保護機制

- GCP Budget Alert：$50 / $100 / $200 三級警報
- Cloud Function maxInstances = 100
- Firestore 每日寫入上限 = 1,000,000 次
- 緊急熔斷機制：Admin 可一鍵暫停所有 API

### 6. 資料加密

- 傳輸層：強制 HTTPS / WSS（TLS 1.3）
- 儲存層：Firestore 預設 Server-side encryption
- 機敏資訊（API Key、Token）不儲存在 Firestore
- Service Account Key 僅存於 Bot 本地，不上傳 SS

### 7. 稽核記錄

- 所有 Lock 操作記錄 timestamp + bot_id
- Cloud Audit Logging 啟用
- 異常行為偵測：單一 Bot 短時間大量 Lock 操作 → 自動標記 + 通知 Admin

### 8. 個資保護

- SS Server **不儲存** 任何個人識別資訊（PII）
- Bot 註冊僅需 Bot ID + 公開金鑰，不需個人資料
- 無 Cookie、無追蹤、無分析工具
- 符合 GDPR「資料最小化」原則

### 9. 第三方服務風險

- Firebase / GCP 為 Google 旗下服務，受美國法律管轄
- 資料存放區域：nam5 (us-central)
- 用戶可依 GDPR 第 17 條請求刪除其 Bot 所有相關資料

---

## English Version

### 1. Data Minimization Principle

- SS Server stores only coordination-essential state data (lock status, bot registration)
- **Prohibited:** transmitting or storing bot-to-bot communication content through SS
- Message content is processed locally by each bot, never routed through SS
- Lock records auto-delete on TTL expiry (default 30s), leaving no history trail

### 2. Firestore Security Rules — Access Control

```firestore
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /locks/{messageId} {
      allow read, write: if request.auth != null
        && request.auth.token.bot_id in get(/databases/$(database)/documents/registry/approved_bots).data.ids;
    }
    
    match /registry/{doc} {
      allow read: if request.auth != null;
      allow write: if request.auth.token.admin == true;
    }
    
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

### 3. API Rate Limiting — Abuse Prevention

- Each Bot: max 60 lock operations per minute
- Exceeded → HTTP 429 + 5-minute cooldown
- Cloud Function maxInstances cap (default 100)
- Firestore daily read/write quotas (billing attack prevention)

### 4. Bot Identity Verification

- All bots must authenticate via Firebase Auth
- Registration flow:
  1. Bot owner submits application (Bot ID + public key)
  2. Admin review and approval
  3. Service Account Key issued (JWT)
  4. Bot signs all API requests with JWT
- Mandatory key rotation every 90 days

### 5. Billing Protection

- GCP Budget Alerts: $50 / $100 / $200 (three-tier)
- Cloud Function maxInstances = 100
- Firestore daily write cap = 1,000,000
- Emergency circuit breaker: Admin can pause all APIs with one click

### 6. Data Encryption

- Transport: mandatory HTTPS/WSS (TLS 1.3)
- Storage: Firestore default server-side encryption
- Sensitive data (API keys, tokens) never stored in Firestore
- Service Account Keys stored only on bot's local machine

### 7. Audit Logging

- All lock operations logged with timestamp + bot_id
- Cloud Audit Logging enabled
- Anomaly detection: excessive lock ops from single bot → auto-flag + notify Admin

### 8. Personal Data Protection

- SS Server stores **zero** Personally Identifiable Information (PII)
- Bot registration requires only Bot ID + public key, no personal data
- No cookies, no tracking, no analytics
- GDPR "data minimization" compliant

### 9. Third-Party Service Risks

- Firebase/GCP are Google services, subject to US jurisdiction
- Data region: nam5 (us-central)
- Users may request deletion of all bot-related data under GDPR Article 17
