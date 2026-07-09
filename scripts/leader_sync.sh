#!/bin/bash
# ============================================
# leader_sync.sh — 更新當家 Bot 狀態
# 用法: leader_sync.sh <BOT_NAME> <assigned_by> [task]
#       assigned_by: human | negotiated
# Token 花費: $0
# ============================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
BOARD_DIR="${SKILL_DIR}/board"
TIMESTAMP=$(date -Iseconds)

LEADER="${1:-unknown}"
ASSIGNED_BY="${2:-human}"
TASK="${3:-}"

mkdir -p "$BOARD_DIR"

cat > "${BOARD_DIR}/leader.status" <<EOF
leader: ${LEADER}
assigned_by: ${ASSIGNED_BY}
assigned_at: ${TIMESTAMP}
current_task: ${TASK}
EOF

echo "✅ 當家: ${LEADER} (${ASSIGNED_BY}) | 任務: ${TASK}"
