#!/bin/bash
# Telegram 通知腳本 - 完成後通知蝦老大

# 配置
TELEGRAM_BOT_TOKEN="8277120862:AAHJfb_GIMj-PG5nXw9KytfZxHeLTv94hZg"
TELEGRAM_CHAT_ID="8397380746"
TELEGRAM_API="https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage"

# 參數
HOSTNAME=${1:-"192.168.1.101"}
STATUS=${2:-"success"}
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# 構建消息
if [ "$STATUS" = "success" ]; then
  MESSAGE="🦐 大爆蝦優化完成！

✅ RecoveryMBA Skill 已成功部署並執行

主機：$HOSTNAME (Mac mini M4)
時間：$TIMESTAMP

系統已恢復完整配置：
✅ Ollama 優化（Metal GPU + 8 CPU 線程）
✅ OpenClaw 配置（qwen3:14b-opt 主力）
✅ Cron Jobs（安全檢查 + 心跳）
✅ Telegram 集成

狀態：就緒 ✨"
else
  MESSAGE="⚠️ 大爆蝦優化失敗

主機：$HOSTNAME
時間：$TIMESTAMP
狀態：$STATUS

請檢查大爆蝦的日誌進行故障排除"
fi

# 發送通知
curl -s -X POST "$TELEGRAM_API" \
  -d "chat_id=$TELEGRAM_CHAT_ID" \
  -d "text=$MESSAGE" \
  -d "parse_mode=Markdown" \
  >/dev/null 2>&1

echo "✅ Telegram 通知已發送"
