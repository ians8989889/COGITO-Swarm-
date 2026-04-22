#!/bin/bash
# Telegram Bot Long Polling Script
# Periodically fetches updates and forwards them to OpenClaw

set -e

BOT_TOKEN="8673082349:AAHPzOsrC9bG1ZvtvGxh5UCnWp9OZMMzgIg"
OFFSET_FILE="$HOME/.openclaw/workspace/state/telegram_offset"
GATEWAY_URL="http://localhost:18789"
GATEWAY_TOKEN="4885b728c3ab2eff987e850d5ca113460eb0f9f4aa729a43"

# Initialize offset file if it doesn't exist
mkdir -p "$(dirname "$OFFSET_FILE")"
if [ ! -f "$OFFSET_FILE" ]; then
  echo "0" > "$OFFSET_FILE"
fi

OFFSET=$(cat "$OFFSET_FILE")

# Fetch updates from Telegram
RESPONSE=$(curl -s "https://api.telegram.org/bot${BOT_TOKEN}/getUpdates?offset=${OFFSET}&timeout=0")

# Parse updates
echo "$RESPONSE" | python3 << 'PYTHON_SCRIPT'
import sys
import json
import os

offset_file = os.path.expanduser("~/.openclaw/workspace/state/telegram_offset")

try:
    data = json.load(sys.stdin)
    
    if not data.get("ok"):
        sys.exit(1)
    
    updates = data.get("result", [])
    
    if not updates:
        sys.exit(0)
    
    # Update offset to next unprocessed message
    max_update_id = max([u.get("update_id") for u in updates])
    with open(offset_file, "w") as f:
        f.write(str(max_update_id + 1))
    
    # Log updates for debugging
    for update in updates:
        update_id = update.get("update_id")
        
        # Check what type of update it is
        if "message" in update:
            msg = update["message"]
            from_id = msg.get("from", {}).get("id")
            text = msg.get("text", "")
            print(f"Message from {from_id}: {text[:50]}", file=sys.stderr)
        elif "callback_query" in update:
            cq = update["callback_query"]
            from_id = cq.get("from", {}).get("id")
            data_val = cq.get("data", "")
            print(f"Callback from {from_id}: {data_val}", file=sys.stderr)
        
except json.JSONDecodeError:
    sys.exit(1)
PYTHON_SCRIPT
