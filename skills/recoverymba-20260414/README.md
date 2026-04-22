# 🦐 RecoveryMBA-20260414

**一鍵恢復 OpenClaw + Ollama 系統**

Crash 後能在 5 分鐘內恢復完整系統配置。

## 快速開始

```bash
# 方式 1：自動恢復（最簡單）
bash ~/.openclaw/workspace/skills/recoverymba-20260414/scripts/recover.sh

# 方式 2：手動恢復（按步驟）
cat ~/.openclaw/workspace/SYSTEM_STATE_SNAPSHOT.md
# 然後按照文件中的「恢復步驟」執行
```

## 包含內容

📄 **SKILL.md** — 完整恢復指南  
🔧 **scripts/recover.sh** — 自動恢復腳本  
📋 **相關文件：**
- `SYSTEM_STATE_SNAPSHOT.md` — 完整系統快照
- `security-audit.sh` — 安全檢查腳本
- `OLLAMA_OPTIMIZATION_COMPLETE.md` — 優化詳情

## 恢復內容

✅ Ollama 環境變數（GPU、CPU、內存配置）  
✅ OpenClaw 配置（模型、Telegram、權限）  
✅ Cron Jobs（安全檢查、心跳）  
✅ 系統驗證  

## 時間表

- **自動恢復：** 5-10 分鐘
- **手動恢復：** 15-20 分鐘

## 關鍵指標

| 項目 | 數值 |
|------|------|
| Ollama 模型 | qwen3:14b-opt (本機免費) |
| GPU 加速 | Metal 4 |
| 推理速度 | +40-60% |
| Token 成本 | $0 (本機) |

## 故障排查

遇到問題？查看：
```
SKILL.md → Troubleshooting 章節
```

## 支持

由爆蝦 🦐 為蝦老大建立

---

**Created:** 2026-04-15  
**Version:** 1.0.0  
**Status:** ✅ Production Ready
