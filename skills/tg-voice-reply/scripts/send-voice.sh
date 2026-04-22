#!/usr/bin/env bash
# Usage: send-voice.sh "TEXT TO SPEAK" CHAT_ID [voice]

TEXT="$1"
CHAT_ID="$2"
VOICE="${3:-zh-CN-XiaoxiaoNeural}"
TMP_FILE="/tmp/tts-reply-$$.mp3"
EDGE_TTS="$HOME/.openclaw/workspace/skills/edge-tts/scripts/tts-converter.js"

if [ -z "$TEXT" ] || [ -z "$CHAT_ID" ]; then
  echo "Usage: $0 <text> <chat_id> [voice]"
  exit 1
fi

# Get bot token directly from JSON
BOT_TOKEN=$(python3 -c "
import json
with open('$HOME/.openclaw/openclaw.json') as f:
    d = json.load(f)
print(d.get('channels', {}).get('telegram', {}).get('botToken', ''))
")

if [ -z "$BOT_TOKEN" ]; then
  echo "Error: Could not read bot token"
  exit 1
fi

# Generate audio
echo "Generating audio..."
node "$EDGE_TTS" "$TEXT" --voice "$VOICE" --output "$TMP_FILE"

if [ ! -f "$TMP_FILE" ]; then
  echo "Error: Audio generation failed"
  exit 1
fi

# Send to Telegram
echo "Sending to Telegram..."
RESULT=$(curl -s -F "chat_id=$CHAT_ID" -F "audio=@$TMP_FILE" \
  "https://api.telegram.org/bot${BOT_TOKEN}/sendAudio")

rm -f "$TMP_FILE"

if python3 -c "import json,sys; d=json.loads('$RESULT'.replace(\"'\",'')); exit(0 if d.get('ok') else 1)" 2>/dev/null || echo "$RESULT" | grep -q '"ok":true'; then
  echo "Voice sent successfully"
else
  echo "Result: $RESULT"
fi
