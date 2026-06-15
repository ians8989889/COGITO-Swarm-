# 🚨 三支小蝦緊急應變 SOP v1.0

> 建檔日期：2026-06-15
> 適用對象：爆蝦 🦐、大爆蝦 🤖、小荷 🌸
> 更新時機：每次故障復原後補上原因+解法

---

## 一、緊急聯絡清單

| bot | 機器 | IP（內網） | Tailscale | 位置 | 管理者 |
|-----|------|-----------|-----------|------|--------|
| 🦐 爆蝦 | Mac M3 (MBAM3) | 192.168.1.105 | ❌ 待裝 | Mac M3 | 蝦老大 |
| 🤖 大爆蝦 | Mac2024 | 192.168.1.111 | ❌ 待裝 | Mac2024 | 蝦老大 |
| 🌸 小荷 | Win10 | ❓ 待補 | ❌ 待裝 | Win10 | 蝦老大 |

---

## 二、故障分級

| 級別 | 症狀 | 影響 | 處理時限 |
|------|------|------|---------|
| 🟢 Level 0 | 單隻 bot 慢回（>2min） | 輕微延遲 | 有空再查 |
| 🟡 Level 1 | 單隻 bot 不回應 | 部分功能失效 | 30 分鐘內 |
| 🟠 Level 2 | 兩隻 bot 不回應 | 群組協同中斷 | 15 分鐘內 |
| 🔴 Level 3 | 三隻全掛 | 全系統停擺 | 立即處理 |

---

## 三、診斷流程

### Step 1: 確認存活

在群組 @ 點名三隻 bot，等 2 分鐘：

```
@MbaM32026_bot @Mac2024_bot @Win10AI_bot 報到
```

哪隻沒回 → 進入 Step 2。

### Step 2: 遠端診斷（需 Tailscale / 內網）

```bash
# 登入該台機器
ssh user@<IP>

# 一鍵診斷
openclaw status

# 看 TG 是否有 crash loop
grep "health-monitor: restarting" /tmp/openclaw/openclaw-$(date +%Y-%m-%d).log | tail -5
```

### Step 3: 依症狀處理

| 症狀 | 指令 |
|------|------|
| TG crash loop | `openclaw gateway restart` |
| gateway 沒在跑 | `openclaw gateway start` |
| 模型 API 掛了 | 自動切 fallback（已配置） |
| 整機離線 | 檢查機器電源/網路 |
| TG API 全域掛掉 | 等 Telegram 恢復，不需處理 |

### Step 4: 確認修復

修復後在群組再點名一次，確認能回。

---

## 四、自動化監控（建議安裝）

### TG 健康檢查 cron（每 15 分鐘）

```bash
# 加到 crontab
*/15 * * * * openclaw status 2>&1 | grep -q "telegram.*ON" || openclaw gateway restart
```

### 存活心跳（寫入 Google Drive）

每 5 分鐘各 bot 寫 timestamp 到共用區：
```
Google Drive/2026-OPENCLAW-BAK/heartbeat/
  baoxia.txt    → 2026-06-15T10:30:00+08:00
  dabaoxia.txt  → 2026-06-15T10:30:00+08:00
  xiaohe.txt    → 2026-06-15T10:30:00+08:00
```
任何 bot 超過 15 分鐘沒更新 → 視為可能故障。

---

## 五、爆蝦存活時的代理職責

當爆蝦 🦐 存活但其他 bot 掛掉時：

1. 幫蝦老大診斷（看 log 判斷原因）
2. 告知修復步驟（直接給指令）
3. 記錄故障到 `memory/YYYY-MM-DD.md`
4. 等 bot 回來後在群組確認

---

## 六、故障記錄格式

每次故障復原後記錄：

```markdown
### YYYY-MM-DD HH:MM - [bot名稱] [症狀]
- 原因：xxx
- 解法：xxx
- 停機時間：xx 分鐘
- 影響：xxx
```

---

## 七、每月檢查清單

- [ ] 三台 gateway 版本一致
- [ ] TG health check cron 正常運作
- [ ] 存活心跳正常寫入
- [ ] Tailscale 連線正常
- [ ] 備份 cron 有在跑
- [ ] 故障記錄簿有更新
- [ ] 緊急聯絡清單 IP 正確

---

## 八、CollabCore 圓桌會議容錯

CollabCore 依賴三支 bot 同時在線才能開圓桌。

**誰掛了的影響：**
- 主席（爆蝦）掛 → 圓桌無法召開，其他 bot 只能被動等 @
- 任一成員掛 → 圓桌可照開，但該席次空缺，決策需備註「缺 X 席」
- 兩席以上空缺 → 圓桌自動降級為雙人討論模式，不做正式決策

**復原後：**
- 掛掉的 bot 回來後，主席補送上次會議摘要給它
- 如果會議只缺它一席 + 決策尚未執行，可重新表決

> 🦐 記住：不是不會掛，是掛了知道怎麼修。每次故障都是一次 upgrade SOP 的機會。
