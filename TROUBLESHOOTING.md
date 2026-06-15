# 🩺 COGITO-Swarm 疑難排解

> 遇到問題先查這裡，不要重新診斷。

---

## 症狀一：所有 bot 在群組都不回應

**診斷：**
```bash
grep "health-monitor: restarting" /tmp/openclaw/openclaw-$(date +%Y-%m-%d).log | tail -5
```

如果看到每 ~10 分鐘出現 `health-monitor: restarting (reason: stopped)` → TG 通訊層 crash loop。

**修復：**
```bash
openclaw gateway restart
```
每一台 bot 機器都要做。

**預防：** 裝 TG 健康檢查 cron：
```bash
*/15 * * * * openclaw status 2>&1 | grep -q "telegram.*ON" || openclaw gateway restart
```

---

## 症狀二：單一 bot 在群組不回應（其他 bot 正常）

1. 確認該 bot 的 gateway 有在跑：`openclaw gateway status`
2. 確認 TG bot 有加入群組且沒被踢
3. 嘗試 `openclaw gateway restart`

---

## 症狀三：COGITO-Swarm 協同失效（不會 spawn / 不會回應）

**根本原因：** TG 通訊層是 COGITO-Swarm 的單點故障（SPOF）。所有 inter-bot 通訊都走 TG group → sessions_spawn。TG 一掛，整個協同就停擺。

**檢查順序：**
1. TG 通訊層是否正常？（見症狀一）
2. 各 bot 的 SOUL.md 是否包含 COGITO-Swarm rules？
3. 各 bot 的 config.env 是否正確配置角色？

---

## 症狀四：CollabCore 圓桌無法召開

- 主席（Leader bot）掛 → 圓桌暫停，無法召開
- 任一成員掛 → 圓桌可照開（備註缺席席次）
- 兩席以上空缺 → 自動降級為雙人討論模式

---

## 症狀五：話題引擎 / cron job timeout

檢查 DeepSeek API 是否正常。若持續 timeout：
- 提高 timeout 秒數
- 或更換模型（fallback 到 ollama 本機）

---

## 通用診斷指令

```bash
# Gateway 狀態
openclaw status

# TG log 檢查
tail -30 /tmp/openclaw/openclaw-$(date +%Y-%m-%d).log | grep telegram

# 查看所有 cron jobs
openclaw cron list
```

---

> 🦐 原則：先查 TG → 再查 gateway → 最後查 config。90% 的問題在前兩步就解了。
