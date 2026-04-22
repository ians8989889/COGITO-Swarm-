# OpenClaw 優化配置手冊

## 🔧 Compaction Buffer 調整

### 當前問題
- Token budget: 200,000
- Compaction reserve: 預設（太低）
- 結果：頻繁重置，丟失 context

### 修復方法

#### 1. 編輯 OpenClaw 全域配置
```bash
# macOS/Linux
cat ~/.openclaw/config.json
```

#### 2. 新增或修改 compaction 設定
```json
{
  "agents": {
    "defaults": {
      "compaction": {
        "reserveTokensFloor": 30000
      }
    }
  }
}
```

#### 3. 重啟 OpenClaw Gateway
```bash
openclaw gateway restart
```

---

## 📋 已執行優化清單

✅ **MEMORY.md 壓縮**
- 合併重複模型配置
- 簡化模型切換流程
- 減少約 30% 冗餘內容

✅ **Daily Notes 歸檔**
- 移動 2026-03-*.md 至 `memory/archive/`
- 保持工作目錄精簡

✅ **.gitignore 建立**
- 排除測試檔案（.mp3, .py）
- 排除舊日報告
- 保留必要的 Skills 和配置

❌ **待執行**
- Compaction reserve 調整（需要 openclaw config 編輯）
- 清理冗餘測試檔案（send-*.sh, *.mp3 等）
- 設定 Cron 自動化清理

---

## 🎯 下一步行動

1. 手動編輯 `~/.openclaw/config.json` 或執行：
   ```bash
   openclaw config set agents.defaults.compaction.reserveTokensFloor 30000
   ```

2. 重啟 Gateway：
   ```bash
   openclaw gateway restart
   ```

3. 測試新 context 限制是否生效
