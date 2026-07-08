#!/bin/bash
# ============================================================
# detect_spool_flood.sh — COGITO-Swarm v1.5+
# 檢查群組 session 檔積壓量，防止 Spool Flood
#
# 用法：./detect_spool_flood.sh [--threshold KB] [--auto-clean]
# 預設閾值：100KB
# ============================================================

set -euo pipefail

THRESHOLD_KB=${THRESHOLD_KB:-100}
AUTO_CLEAN=false
SESSIONS_DIR="${HOME}/.openclaw/agents/main/sessions"

# ============================================================
# 參數解析
# ============================================================
while [[ $# -gt 0 ]]; do
    case "$1" in
        --threshold)
            THRESHOLD_KB="$2"
            shift 2
            ;;
        --auto-clean)
            AUTO_CLEAN=true
            shift
            ;;
        --help|-h)
            echo "用法: $0 [--threshold KB] [--auto-clean]"
            echo ""
            echo "  檢查 OpenClaw 群組 session 檔案積壓量"
            echo "  超過閾值 → 發出警告（或自動清除）"
            echo ""
            echo "  --threshold KB    積壓閾值（KB），預設 100"
            echo "  --auto-clean      超過閾值時自動備份+清除"
            exit 0
            ;;
        *)
            echo "未知參數: $1"
            exit 1
            ;;
    esac
done

# ============================================================
# 檢查 session 目錄
# ============================================================
if [[ ! -d "$SESSIONS_DIR" ]]; then
    echo "❌ Session 目錄不存在: $SESSIONS_DIR"
    exit 1
fi

# ============================================================
# 找出最大的 jsonl 檔案（可能是群組 session）
# ============================================================
LARGEST_FILE=$(find "$SESSIONS_DIR" -name "*.jsonl" -type f -exec ls -1t {} + 2>/dev/null | head -1)

if [[ -z "$LARGEST_FILE" ]]; then
    echo "✅ 無 session 檔案，安全"
    exit 0
fi

# ============================================================
# 計算大小
# ============================================================
FILE_SIZE_BYTES=$(stat -f%z "$LARGEST_FILE" 2>/dev/null || stat -c%s "$LARGEST_FILE" 2>/dev/null || echo 0)
FILE_SIZE_KB=$((FILE_SIZE_BYTES / 1024))
LINE_COUNT=$(wc -l < "$LARGEST_FILE" 2>/dev/null || echo 0)

# ============================================================
# 判斷
# ============================================================
FILENAME=$(basename "$LARGEST_FILE")

if [[ "$FILE_SIZE_KB" -gt "$THRESHOLD_KB" ]]; then
    echo "🚨 SPOOL FLOOD 風險！"
    echo "   檔案: $FILENAME"
    echo "   大小: ${FILE_SIZE_KB}KB (閾值: ${THRESHOLD_KB}KB)"
    echo "   行數: ~${LINE_COUNT} 條訊息"
    echo ""

    if [[ "$AUTO_CLEAN" == "true" ]]; then
        BACKUP_FILE="${LARGEST_FILE}.spool_backup_$(date +%Y%m%d_%H%M%S)"
        cp "$LARGEST_FILE" "$BACKUP_FILE"
        truncate -s 0 "$LARGEST_FILE"
        echo "✅ 已自動清除：備份至 $BACKUP_FILE"
        echo "   建議：重啟 gateway → openclaw gateway restart"
    else
        echo "⚠️  建議動作："
        echo "   1. 備份: cp $FILENAME ${FILENAME}.spool_backup"
        echo "   2. 清除: truncate -s 0 $FILENAME"
        echo "   3. 重啟: openclaw gateway restart"
        echo ""
        echo "   或使用 --auto-clean 自動處理"
        exit 2
    fi
else
    echo "✅ 正常 — $FILENAME: ${FILE_SIZE_KB}KB / ${LINE_COUNT} 行 (閾值: ${THRESHOLD_KB}KB)"
fi
