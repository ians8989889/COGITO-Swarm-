# 🔐 Telegram Bot Token 重置指南

**狀態：** 🚨 舊 token 已暴露，需要立即重置

---

## 步驟 1：Deny 可疑核准

```
/approve a4635a80-acb2-4117-883f-4c3cdb92523c deny
```

---

## 步驟 2：重置 Token（在 Telegram 上）

1. **打開 Telegram，搜尋 @BotFather**
2. **發送指令：** `/revoke`
3. **選擇你的 bot：** @Mba_M3_bot
4. **確認撤銷** — 舊 token 立即失效
5. **複製新 token**

新 token 格式：`123456789:ABCdef...xyz`

---

## 步驟 3：更新 OpenClaw 配置

編輯 `~/.openclaw/openclaw.json`，找到：

```json
"telegram": {
  "botToken": "8673082349:AAHPzOsrC9bG1ZvtvGxh5UCnWp9OZMMzgIg"
}
```

改成：

```json
"telegram": {
  "botToken": "你的新Token"
}
```

---

## 步驟 4：重啟 OpenClaw Gateway

```bash
openclaw gateway restart
```

---

## ✅ 驗證

```bash
openclaw status
```

檢查 Telegram 是否正常連接（應該顯示 OK）

---

## 安全提示

- ✅ 舊 token 被撤銷後，任何人都無法用它控制你的 bot
- ✅ 新 token 只會出現在你的配置文件中
- ✅ 不要在公開地方分享 token
- ✅ 定期檢查可疑的核准請求

---

**時間：** 2026-04-15 08:57 GMT+8  
**優先級：** 🚨 高  
**状態：** 待執行
