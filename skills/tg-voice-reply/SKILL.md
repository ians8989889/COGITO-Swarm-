---
name: tg-voice-reply
description: Send voice/audio replies via Telegram using edge-tts TTS. Works with any LLM model. Use when user asks for voice reply, spoken response, TTS output, or says "語音回覆". Generates MP3 audio from text and sends it to the user's Telegram chat.
---

# TG Voice Reply Skill

## Workflow

1. Generate audio with edge-tts script
2. Send the MP3 to Telegram via Bot API
3. Clean up temp file

## Step 1: Generate Audio

```bash
node ~/.openclaw/workspace/skills/edge-tts/scripts/tts-converter.js "TEXT" \
  --voice zh-CN-XiaoxiaoNeural \
  --output /tmp/tts-reply.mp3
```

**Voice options:**
- Chinese: `zh-CN-XiaoxiaoNeural` (female), `zh-CN-YunxiNeural` (male)
- English: `en-US-AriaNeural` (female), `en-US-GuyNeural` (male)

## Step 2: Send to Telegram

Get bot token from config and send audio:

```bash
BOT_TOKEN=$(cat ~/.openclaw/openclaw.json | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('channels',{}).get('telegram',{}).get('botToken',''))")
CHAT_ID="USER_CHAT_ID"
curl -s -F chat_id=$CHAT_ID -F audio=@/tmp/tts-reply.mp3 \
  "https://api.telegram.org/bot${BOT_TOKEN}/sendAudio"
```

**Get chat_id:** Use `openclaw status` sessions to find the user's Telegram ID (sender_id from message metadata).

## Step 3: Cleanup

```bash
rm -f /tmp/tts-reply.mp3
```

## Notes

- Always use `node ~/.openclaw/workspace/skills/edge-tts/scripts/tts-converter.js` (not the skill-creator path)
- Default voice: `zh-CN-XiaoxiaoNeural` for Chinese text
- The bot token in openclaw.json may be masked; use `openclaw config get channels.telegram.botToken` — if redacted, read it directly from the JSON file
