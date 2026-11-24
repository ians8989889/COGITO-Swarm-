#!/bin/bash
source "$HOME/.openclaw/credentials/telegram_bot_token"
CHAT_ID="8397380746"
VOICE_FILE="${1:-/Users/ericsu/.openclaw/workspace/output.mp3}"
CAPTION="${2:-🦐}"

curl -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendVoice" \
  -F "chat_id=${CHAT_ID}" \
  -F "voice=@${VOICE_FILE}" \
  -F "caption=${CAPTION}"
