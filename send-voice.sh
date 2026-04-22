#!/bin/bash
BOT_TOKEN="8673082349:AAHPzOsrC9bG1ZvtvGxh5UCnWp9OZMMzgIg"
CHAT_ID="8397380746"
VOICE_FILE="${1:-/Users/ericsu/.openclaw/workspace/output.mp3}"
CAPTION="${2:-🦐}"

curl -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendVoice" \
  -F "chat_id=${CHAT_ID}" \
  -F "voice=@${VOICE_FILE}" \
  -F "caption=${CAPTION}"
