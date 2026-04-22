# 🦐 大爆蝦遠端優化指南

**對象：** 192.168.1.101 (Mac mini M4)

由於 SSH 金鑰限制，請在大爆蝦上手動執行以下步驟：

## 步驟 1: 複製 Skill 檔案

在你的筆記本上執行：
```bash
scp -r ~/.openclaw/workspace/skills/recoverymba-20260414 \
  ericsu@192.168.1.101:~/.openclaw/workspace/skills/
```

或在大爆蝦上手動複製檔案。

## 步驟 2: 在大爆蝦上執行優化

SSH 連接大爆蝦：
```bash
ssh ericsu@192.168.1.101
```

然後執行：
```bash
bash ~/.openclaw/workspace/skills/recoverymba-20260414/scripts/recover.sh
```

## 步驟 3: 監控進度

腳本會輸出詳細日誌，包括：
- ✅ Ollama 狀態檢查
- ✅ 環境變數恢復
- ✅ OpenClaw Gateway 重啟
- ✅ 系統驗證
- ✅ Cron Jobs 檢查

## 步驟 4: 完成通知

優化完成後，大爆蝦會：
1. 生成恢復日誌：`~/.openclaw/workspace/recovery-*.log`
2. 驗證所有系統已就緒

然後在筆記本上執行：
```bash
bash ~/.openclaw/workspace/skills/recoverymba-20260414/scripts/notify-telegram.sh 192.168.1.101 success
```

發送完成通知給你的 Telegram。

---

**預計耗時：** 5-10 分鐘

準備好後告訴我！ 🦐
