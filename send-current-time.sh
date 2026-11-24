#!/bin/bash
source "$HOME/.openclaw/credentials/telegram_bot_token"
CHAT_ID="8397380746"
VOICE_FILE="/Users/ericsu/.openclaw/workspace/current-time.mp3"

curl -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendVoice" \
  -F "chat_id=${CHAT_ID}" \
  -F "voice=@${VOICE_FILE}" \
  -F "caption=現在的時間 🕐"
