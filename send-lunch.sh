#!/bin/bash
BOT_TOKEN="8673082349:AAHPzOsrC9bG1ZvtvGxh5UCnWp9OZMMzgIg"
CHAT_ID="8397380746"
VOICE_FILE="/Users/ericsu/.openclaw/workspace/lunch.mp3"

curl -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendVoice" \
  -F "chat_id=${CHAT_ID}" \
  -F "voice=@${VOICE_FILE}" \
  -F "caption="
