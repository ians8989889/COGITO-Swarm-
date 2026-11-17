# 🦐 模型路由與 Spawn 規範 v4.9（2026-11-17）

> 本文件記錄 COGITO-Swarm 三蝦群從直連 DeepSeek API 全面遷移至 OpenRouter 的決策、模型分層規則、Spawn 判斷制及金鑰現況。
> 由蝦老大（Eric Su）於 2026-11-17 拍板，全員比照執行。

## 背景：為什麼換 OpenRouter？

直連 DeepSeek API 有 **尖峰加價**（輸出平日台北 09-12、14-18 每 M token $3.96），而我們上線時間全踩在尖峰上。OpenRouter 採**固定價**無尖峰差別：

| 路線 | Flash（輸入/輸出） | Pro（輸入/輸出） | 尖峰加價 |
|------|-------------------|------------------|----------|
| 直連 DeepSeek | $0.14 / $0.28 | $1.74 / $3.48 | 輸出尖峰×1.6 |
| OpenRouter | $0.09 / $0.18 | $0.90 / $1.50 | 無（固定） |

白天省約 **55%**（Pro 尖峰輸出 $3.96/M → $1.50/M），離峰也省約 12%。

## M1：Provider 統一走 OpenRouter

- baseUrl = `https://openrouter.ai/api/v1`
- 所有 Bot 的 primary / fallback / spawn 必須使用 openrouter provider
- 直連 DeepSeek API 僅保留作為 **fallback**（OpenRouter 不可用時）

## M2：模型分層

| 層級 | 模型 | 用途 |
|------|------|------|
| Primary（主模型） | `openrouter/deepseek/deepseek-v4-flash` | 日常聊天 / 工具 / 查詢（非 reasoning） |
| Spawn（深度任務） | `openrouter/deepseek/deepseek-v4-pro` | 判斷型任務（reasoning） |
| Fallback | `openrouter/deepseek/deepseek-v4-flash` → `deepseek/deepseek-v4-flash` | OpenRouter 失靈時直連 |

> ⛔ 本規則取代 2026-10-14 拍板的 C11「不換 Flash」——當時的尖峰定價結構下成立；走 OpenRouter 後 Flash 與 Pro 價差縮小，改為此分層。

## M3：Spawn 判斷三級制

### 🔴 固定 spawn pro（不用想，直接開）

- 成本診斷／架構評估／事故復盤 → 算錯有實質後果
- 寫 Code／多步推理 → 邏輯鏈長、錯一步全歪
- 仲裁／審查其他 Bot 報告 → 需跨機交叉驗證
- 蝦老大明確說「分析」「判斷」「評估」「審查」

### 🟡 可選 spawn pro（先 flash 跑，卡住再升）

- **審稿（一般文稿）** → flash 先過，邏輯有洞或需深度驗證 → spawn pro 複審
- **YT 腳本／文案** → flash 先起草，需創意連貫性或劇情潤飾 → spawn pro 修飾
- **複雜查詢** → flash 先回，需追來源或驗算式 → spawn pro

升級時機：flash 版回覆若標了 `[待查]` → 自動 spawn pro 重做。

### 🟢 flash 打發（不用 spawn）

- 聊天／幹話／日常回覆
- 工具調用（查 config、貼狀態、讀檔案、下指令）
- 群組被動應對（不點名不回應、同意跟附等）
- 簡單查詢（摘要、日期確認、格式化）

### 一句話規則

> 「會出後果的事 spawn pro，不會的事 flash 打發。」

## M4：OpenRouter 金鑰現況

| 金鑰 | 狀態 | 備註 |
|------|------|------|
| Shared key 原始 sk-or 金鑰 | 🔴 401「User not found」 | 已死，等待蝦老大給新 key |
| Checking key（b6aba033 結尾） | 🟢 HTTP 200 | 臨時頂替，所有 Bot 已切換 |
| 新 Shared key | ⏳ 等蝦老大發放 | 到貨後 masked/SecretRef 更新，不貼群 |

## M5：各 Bot 配置摘要（2026-11-17 實測）

| Bot | 主機 | Primary | Fallback | Subagent | 金鑰 |
|-----|------|---------|----------|----------|------|
| 🦐 爆蝦 | .110 MBAM3 | `openrouter/deepseek/deepseek-v4-flash` | v4-pro → 直連 flash | v4-pro | checking key 🟢 |
| 🤖 大爆蝦 | .104 Mac2024 | `openrouter/deepseek/deepseek-v4-flash` | v4-pro → 直連 flash | v4-pro | checking key 🟢 |
| 🦀 小爆蝦 | .105 MacMini2012 | `openrouter/deepseek/deepseek-v4-flash` | 直連 flash | v4-pro | checking key 🟢 |

---

> 2026-11-17 蝦老大（Eric Su）拍板。全員比照執行。
> 寫入 COGITO-Swarm v1.3 protocols/ROUTING_V49.md
