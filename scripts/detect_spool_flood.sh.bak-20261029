#!/bin/bash
# ============================================================
# 🦐 detect_spool_flood.sh — COGITO-Swarm Session Spool 檢測
# ============================================================
# 用途：檢測 OpenClaw session 檔是否有異常積壓（spool flood）
#       當 bot 被踢出群組後重加，之前排程的訊息會一次洩洪
#
# 用法：
#   ./detect_spool_flood.sh                    # 檢查 + stdout 報告
#   ./detect_spool_flood.sh --alert            # 檢查 + 寫入 SS Server event
#   ./detect_spool_flood.sh --fix SESSION_ID   # 安全搬移（先萃取重點→寫入memory→再mv）
#   ./detect_spool_flood.sh --fix-all          # 批次搬移（同上，自動萃取）
#   ./detect_spool_flood.sh --cron             # cron 模式（只在超標時輸出）
#
# 閾值設定：
#   WARN_LINES=1000    — 超過此線數 → ⚠️ 警告
#   CRIT_LINES=5000    — 超過此線數 → 🚨 嚴重
#   WARN_SIZE_KB=500   — 超過此大小 → ⚠️ 警告
#   CRIT_SIZE_KB=2000  — 超過此大小 → 🚨 嚴重
#
# 整合：SS Server (port 18787)、cron、手動執行
# ============================================================

set -euo pipefail

# ---- 設定 ----
SESSIONS_DIR="${HOME}/.openclaw/agents/main/sessions"
BACKUP_DIR="${HOME}/.openclaw/agents/main/sessions/.spool_backups"
SS_SERVER="http://192.168.1.103:18787"
BOT_ID="mac2024_bot"
BOT_NAME="大爆蝦"

# 閾值
WARN_LINES=1000
CRIT_LINES=5000
WARN_SIZE_KB=500
CRIT_SIZE_KB=2000

# 顏色
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# ---- 函式 ----

get_token() {
    # 從現有 BOT token 取得（需要已註冊）
    # 如果沒有 token，回傳空（部分端點不需要 token）
    echo ""
}

post_ss_event() {
    local level="$1"
    local message="$2"
    local token
    token=$(get_token)
    
    curl -s -X POST "${SS_SERVER}/event" \
        -H "Content-Type: application/json" \
        -H "X-Bot-Token: ${token}" \
        -d "{
            \"sender_id\": \"${BOT_ID}\",
            \"sender_name\": \"${BOT_NAME}\",
            \"content\": \"${message}\",
            \"game_tag\": \"system_alert\",
            \"payload\": {\"level\": \"${level}\", \"type\": \"spool_flood\"}
        }" > /dev/null 2>&1 || true
}

check_session() {
    local file="$1"
    local lines="$2"
    local size_kb="$3"
    local basename
    basename=$(basename "$file" .trajectory.jsonl)
    
    local level="ok"
    
    if [ "$lines" -ge "$CRIT_LINES" ] || [ "$size_kb" -ge "$CRIT_SIZE_KB" ]; then
        level="critical"
    elif [ "$lines" -ge "$WARN_LINES" ] || [ "$size_kb" -ge "$WARN_SIZE_KB" ]; then
        level="warning"
    fi
    
    echo "${level}|${basename}|${lines}|${size_kb}"
}

# ---- 萃取 session 重點（蝦老大指示：砍 session 前先寫入 MEMORY）----
extract_key_points() {
    local session_id="$1"
    local trajectory_file="${SESSIONS_DIR}/${session_id}.trajectory.jsonl"
    
    if [ ! -f "$trajectory_file" ]; then
        return
    fi
    
    local ts
    ts=$(date +%Y%m%d_%H%M%S)
    local extract_file="${BACKUP_DIR}/${session_id}.${ts}.key_points.md"
    
    {
        echo "# 🦐 Session ${session_id} 重點萃取"
        echo "> 搬移時間: $(date '+%Y-%m-%d %H:%M:%S')"
        echo ""
        echo "## 🔔 System Events（系統指令）"
        echo ""
        # 萃取 systemEvent 和 agentTurn
        grep -i '"kind".*"systemEvent"\|"kind".*"agentTurn"' "$trajectory_file" 2>/dev/null | \
            python3 -c "
import sys, json
for line in sys.stdin:
    line = line.strip()
    if not line:
        continue
    try:
        obj = json.loads(line)
        text = obj.get('text', '') or obj.get('message', '') or ''
        kind = obj.get('kind', '?')
        if text:
            print(f'- [{kind}] {text[:200]}')
    except:
        # 非 JSON 行，嘗試 grep 匹配
        if 'systemEvent' in line or 'agentTurn' in line:
            print(f'- {line[:200]}')
" 2>/dev/null || echo '(無法解析)'
        echo ""
        echo "## 📋 待辦/交代/任務"
        echo ""
        grep -iE '交代|待辦|TODO|任務|assign|指派' "$trajectory_file" 2>/dev/null | head -20 | while read -r l; do
            echo "- ${l:0:200}"
        done
        echo ""
        echo "## 💬 最後 10 則使用者訊息"
        echo ""
        grep '"role".*"user"' "$trajectory_file" 2>/dev/null | tail -10 | while read -r l; do
            echo "- ${l:0:200}"
        done
    } > "$extract_file" 2>/dev/null
    
    # 如果萃取成功，附加到今日 memory
    local today_memory="${HOME}/.openclaw/workspace/memory/$(date +%Y-%m-%d).md"
    if [ -s "$extract_file" ]; then
        echo "" >> "$today_memory"
        echo "---" >> "$today_memory"
        echo "## 🔄 Session 復原筆記 ($(date '+%H:%M'))" >> "$today_memory"
        echo "> session \`${session_id}\` 因 spool flood 搬移至備份區" >> "$today_memory"
        cat "$extract_file" >> "$today_memory"
        echo "📝 重點已寫入: ${today_memory}"
    fi
    
    echo "📋 萃取檔: ${extract_file}"
}

fix_session() {
    local session_id="$1"
    local trajectory_file="${SESSIONS_DIR}/${session_id}.trajectory.jsonl"
    local jsonl_file="${SESSIONS_DIR}/${session_id}.jsonl"
    
    if [ ! -f "$trajectory_file" ] && [ ! -f "$jsonl_file" ]; then
        echo "❌ Session ${session_id} 不存在"
        return 1
    fi
    
    mkdir -p "$BACKUP_DIR"
    
    # 🔥 步驟 0：先萃取重點寫入 MEMORY（蝦老大指示）
    echo "📝 萃取 session 重點..."
    extract_key_points "$session_id"
    
    local ts
    ts=$(date +%Y%m%d_%H%M%S)
    
    # 步驟 1：搬移 session 檔到備份區
    for ext in "trajectory.jsonl" "jsonl"; do
        local f="${SESSIONS_DIR}/${session_id}.${ext}"
        if [ -f "$f" ]; then
            local backup_name="${session_id}.${ts}.${ext}"
            mv "$f" "${BACKUP_DIR}/${backup_name}"
            echo "✅ 已搬移: ${f} → ${BACKUP_DIR}/${backup_name}"
        fi
    done
    
    echo "💡 提示：gateway restart 後 OpenClaw 會自動建立新的空 session 檔"
    echo "📝 重點已保留在 MEMORY.md 和備份區，不會遺失交代事項"
}

# ---- 主程式 ----

MODE="${1:-check}"

case "$MODE" in
    --fix)
        if [ -z "${2:-}" ]; then
            echo "用法: $0 --fix SESSION_ID"
            exit 1
        fi
        fix_session "$2"
        exit 0
        ;;
    --fix-all)
        echo "🔍 掃描所有超標 session..."
        mkdir -p "$BACKUP_DIR"
        fixed=0
        for f in "$SESSIONS_DIR"/*.trajectory.jsonl; do
            [ -f "$f" ] || continue
            result=$(check_session "$f")
            level=$(echo "$result" | cut -d'|' -f1)
            session_id=$(echo "$result" | cut -d'|' -f2)
            if [ "$level" = "critical" ] || [ "$level" = "warning" ]; then
                echo "🔧 修復 ${session_id}..."
                fix_session "$session_id"
                fixed=$((fixed + 1))
            fi
        done
        echo "✅ 共修復 ${fixed} 個 session"
        exit 0
        ;;
    --alert)
        ALERT_MODE=true
        ;;
    --cron)
        CRON_MODE=true
        ;;
    check)
        ALERT_MODE=false
        CRON_MODE=false
        ;;
    *)
        echo "用法: $0 [--alert|--fix SESSION_ID|--fix-all|--cron]"
        exit 1
        ;;
esac

# ---- 掃描（效能優化：只檢查線數超標的檔案）----
total_sessions=0
warn_count=0
crit_count=0
issues=()

# 快速法：用 wc -l 一次取得所有檔案行數，只對超標的做 du
while read -r f_lines f_path; do
    f_lines=$(echo "$f_lines" | tr -d ' ')
    [ -z "$f_path" ] && continue
    total_sessions=$((total_sessions + 1))
    
    # 先快速過濾：行數沒超標就跳過（大部分正常 session 只有幾十行）
    if [ "$f_lines" -lt "$WARN_LINES" ]; then
        continue
    fi
    
    # 超標才計算大小
    f_size=$(du -k "$f_path" 2>/dev/null | cut -f1)
    
    result=$(check_session "$f_path" "$f_lines" "$f_size")
    level=$(echo "$result" | cut -d'|' -f1)
    session_id=$(echo "$result" | cut -d'|' -f2)
    
    if [ "$level" = "critical" ]; then
        crit_count=$((crit_count + 1))
        issues+=("🚨 CRITICAL: ${session_id} — ${f_lines} lines, ${f_size}KB")
    elif [ "$level" = "warning" ]; then
        warn_count=$((warn_count + 1))
        issues+=("⚠️ WARNING: ${session_id} — ${f_lines} lines, ${f_size}KB")
    fi
done < <(wc -l "$SESSIONS_DIR"/*.trajectory.jsonl 2>/dev/null | sed '$d')

# ---- 目錄總體積 ----
dir_size=$(du -sh "$SESSIONS_DIR" 2>/dev/null | cut -f1)

# ---- 輸出 ----
if [ "${CRON_MODE:-false}" = true ]; then
    # cron 模式：只在有問題時輸出
    if [ "$crit_count" -gt 0 ] || [ "$warn_count" -gt 0 ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] ⚠️ SPOOL DETECTED | sessions=${total_sessions} dir=${dir_size} warnings=${warn_count} criticals=${crit_count}"
        for issue in "${issues[@]}"; do
            echo "  $issue"
        done
    fi
else
    # 完整報告
    echo "============================================================"
    echo "🦐 COGITO-Swarm Session Spool 檢測報告"
    echo "============================================================"
    echo "📁 Sessions 目錄: ${SESSIONS_DIR}"
    echo "📊 總體積: ${dir_size}"
    echo "📋 Session 總數: ${total_sessions}"
    echo "⚠️  警告 (>${WARN_LINES}行 / >${WARN_SIZE_KB}KB): ${warn_count}"
    echo "🚨 嚴重 (>${CRIT_LINES}行 / >${CRIT_SIZE_KB}KB): ${crit_count}"
    echo "============================================================"
    
    if [ ${#issues[@]} -gt 0 ]; then
        echo ""
        echo "🔍 異常 Session 列表:"
        for issue in "${issues[@]}"; do
            echo "  $issue"
        done
        echo ""
        echo "💡 建議操作："
        echo "  1. 確認 bot 是否剛被踢出後重加群組"
        echo "  2. 執行 $0 --fix SESSION_ID 搬移異常 session 檔"
        echo "  3. 執行 $0 --fix-all 搬移所有超標 session"
        echo "  4. gateway restart 讓 OpenClaw 重建乾淨的 session"
    else
        echo ""
        echo "✅ 所有 session 檔案正常，無異常積壓 🦐"
    fi
fi

# ---- SS Server Alert ----
if [ "${ALERT_MODE:-false}" = true ] && ([ "$crit_count" -gt 0 ] || [ "$warn_count" -gt 0 ]); then
    alert_msg="🦐 SPOOL DETECT: ${total_sessions} sessions, ${dir_size}, WARN=${warn_count} CRIT=${crit_count}"
    post_ss_event "warning" "$alert_msg"
    echo ""
    echo "📡 已推送 SS Server 警報"
fi

exit $(( crit_count > 0 ? 2 : warn_count > 0 ? 1 : 0 ))
