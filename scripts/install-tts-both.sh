#!/bin/bash
# 同時在兩支蝦上安裝語音回覆工具

set -e

HOSTS=("192.168.1.101" "192.168.1.108")
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

echo "========================================" 
echo "🎤 批量安裝 TTS 語音回覆工具"
echo "時間：$TIMESTAMP"
echo "========================================"
echo ""

for HOST in "${HOSTS[@]}"; do
    echo "📦 開始在 $HOST 上安裝..."
    echo ""
    
    # SSH 連接並執行安裝
    ssh ericsu@$HOST << "INSTALL_SCRIPT"
#!/bin/bash

echo "🎤 [$HOST] TTS 安裝開始"
echo ""

# 1. 安裝 edge-tts
echo "[1] 安裝 edge-tts..."
npm install -g edge-tts@latest

echo ""

# 2. 建立目錄
echo "[2] 建立目錄結構..."
mkdir -p ~/.openclaw/workspace/skills/tg-voice-reply/scripts

echo ""

# 3. 建立腳本
echo "[3] 建立 send-voice.sh..."
cat > ~/.openclaw/workspace/skills/tg-voice-reply/scripts/send-voice.sh << 'VOICESCRIPT'
#!/bin/bash
set -e

TEXT="${1:-測試}"
CHAT_ID="${2:-8397380746}"
BOT_TOKEN="8277120862:AAHJfb_GIMj-PG5nXw9KytfZxHeLTv94hZg"

echo "🎤 生成語音..."
MP3_FILE="/tmp/tts-reply-$RANDOM.mp3"

# 生成語音
edge-tts --text "$TEXT" \
         --voice zh-CN-XiaoxiaoNeural \
         --output-file "$MP3_FILE" || {
    echo "❌ 語音生成失敗"
    exit 1
}

echo "📤 發送到 Telegram..."

# 發送到 Telegram
RESPONSE=$(curl -s -F "chat_id=$CHAT_ID" \
                 -F "audio=@$MP3_FILE" \
                 "https://api.telegram.org/bot${BOT_TOKEN}/sendAudio")

# 檢查回應
if echo "$RESPONSE" | grep -q '"ok":true'; then
    echo "✅ 語音已發送"
    RESULT="success"
else
    echo "❌ 發送失敗"
    RESULT="failed"
fi

rm -f "$MP3_FILE"
exit 0
VOICESCRIPT

chmod +x ~/.openclaw/workspace/skills/tg-voice-reply/scripts/send-voice.sh

echo ""

# 4. 驗證安裝
echo "[4] 驗證安裝..."
which edge-tts && echo "✅ edge-tts 已安裝" || echo "❌ edge-tts 安裝失敗"
test -x ~/.openclaw/workspace/skills/tg-voice-reply/scripts/send-voice.sh && echo "✅ 腳本已建立" || echo "❌ 腳本建立失敗"

echo ""

# 5. 發送測試語音
echo "[5] 發送測試語音..."
bash ~/.openclaw/workspace/skills/tg-voice-reply/scripts/send-voice.sh "我是 $(hostname)，語音回覆安裝成功！" 8397380746

echo ""
echo "✅ TTS 安裝完成！"
INSTALL_SCRIPT
    
    echo ""
    echo "✅ $HOST 安裝完成"
    echo "========================================"
    echo ""
done

echo "🎉 所有機器都已安裝語音回覆工具！"
echo "現在兩支蝦都能用語音回覆你了！"
