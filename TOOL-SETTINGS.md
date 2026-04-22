# OpenClaw 工具設定記錄

## 📋 模型配置
- **主力模型**：`openrouter/free`（自動選擇免費模型池中的最佳模型）
- **備用模型**：`anthropic/claude-sonnet-4-6`（付費，僅在任務需要時使用）
- **Ollama 14B**：`qwen3:14b-opt`（已配置，待 debug）

## 🔊 語音 (TTS) 設定
- **引擎**：`edge-tts` (Microsoft Azure TTS)
- **語音**：`zh-CN-XiaoxiaoNeural`（中文女聲）
- **腳本**：
  - `/Users/ericsu/.openclaw/workspace/create-voice.py` - 生成 MP3
  - `/Users/ericsu/.openclaw/workspace/send-voice.sh` - 發送語音
- **API**：Telegram Bot `sendVoice`（原生語音泡泡）
- **使用**：說「用語音回答」自動發送語音

## ⚙️ 執行批准策略
- **安全模式**：`allowlist`（只允許白名單內的命令）
- **自動執行**：常用命令、語音腳本、工具命令
- **需要批准**：刪除檔案、上傳金鑰/帳密、inline 代碼執行
- **批准方式**：Telegram 輸入 `/approve <id> allow-always`

## 📁 關鍵檔案位置
- 主配置：`~/.openclaw/openclaw.json`
- 批准設定：`~/.openclaw/exec-approvals.json`
- 每日記錄：`/Users/ericsu/.openclaw/workspace/memory/YYYY-MM-DD.md`
- 語音腳本：`/Users/ericsu/.openclaw/workspace/*.py`, `send-*.sh`

## 🚀 快速指令
- 「用語音回答」→ 自動發送語音泡泡
- 「現在的時間」→ 語音回覆當前時間
- 「放飯去」→ 語音祝福
- `/approve <id> allow-always` → 永久允許命令

---
**最後更新**：2026-04-02 12:00
**設定者**：蝦老大
**AI 助手**：爆蝦 🦐
