#!/usr/bin/env bash
# ============================================================
# heartbeat.sh — the Leader's only heartbeat (only the Leader runs this cron)
# Flow: wake → gate.sh ($0) → fail: journal / pass: hand off to the Leader LLM to act
# Usage (cron example): */90 * * * * /path/scripts/heartbeat.sh
# This script itself is $0; only the "pass gate" path triggers the LLM via OpenClaw.
# ============================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
CONFIG="${SKILL_DIR}/config.env"
DAILY="${SKILL_DIR}/cogito/daily.md"
TOPICS="${SKILL_DIR}/board/topics.md"

# shellcheck disable=SC1090
[[ -f "$CONFIG" ]] && source "$CONFIG" || true
: "${HEARTBEAT_ENABLED:=true}"
: "${BOT_ROLE:=worker}"

# Only the Leader heartbeats; other roles exit immediately (zero idle)
if [[ "$HEARTBEAT_ENABLED" != "true" || "$BOT_ROLE" != "leader" ]]; then
  exit 0
fi

TS="$(date -Iseconds)"

# ── 1. Collect local signals (all $0): any stuck tasks, risk flags ──
#    This shows the interface; wire the real signal sources to your OpenClaw session/board.
RISK_SCORE="${COGITO_RISK_SCORE:-0}"          # supplied by monitor script/environment
HUMAN_ONLINE="${COGITO_HUMAN_ONLINE:-0}"      # 1 = human recently active
CANDIDATE="${COGITO_CANDIDATE:-routine heartbeat check}"  # candidate topic (can be produced by a pre-script)

# ── 2. Pass the gate ──
DECISION="$("${SCRIPT_DIR}/gate.sh" "$CANDIDATE" "$RISK_SCORE" "$HUMAN_ONLINE" || true)"

case "$DECISION" in
  MUTE)
    echo "[$TS] 💤 Budget exhausted, staying silent." ;;
  JOURNAL)
    # Don't broadcast; do one cheap "think" → write to the journal (daily practice)
    {
      echo ""
      echo "### Heartbeat thought ($TS) — gate did not authorize, journaling"
      echo "- candidate: ${CANDIDATE}"
      echo '- (here the Leader produces one practice note via a cogito/MODES.md mode, very low cost)'
    } >> "$DAILY"
    echo "[$TS] ✍️  JOURNAL: thought recorded, did not speak." ;;
  BROADCAST)
    # Passed the gate → log one entry to topics (tagged PROACTIVE for quota counting), hand off to the Leader LLM
    echo "${TS} [PROACTIVE] ${CANDIDATE} | risk=${RISK_SCORE}" >> "$TOPICS"
    echo "[$TS] 📣 BROADCAST: gate authorized, Leader enters proactive action (speak/dispatch/convene)."
    echo "ACTION_REQUIRED=true"   # the OpenClaw wrapper triggers the Leader LLM on this
    ;;
  *)
    echo "[$TS] ⚠️  Unknown gate decision: $DECISION" ;;
esac
