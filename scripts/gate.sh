#!/usr/bin/env bash
# ============================================================
# gate.sh — proactivity gate ($0 local check, runs first on every heartbeat)
# Usage: gate.sh "<candidate topic one-liner>" [risk_score] [human_online:0|1]
# Output: BROADCAST | JOURNAL | MUTE
# Exit code: 0=BROADCAST (may act)  1=JOURNAL/MUTE (journal only)
# Token cost: $0 (no LLM call)
# ============================================================
set -uo pipefail   # no -e; use stepwise fault tolerance instead

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
CONFIG="${SKILL_DIR}/config.env"
TOPICS="${SKILL_DIR}/board/topics.md"
TOKEN_LOG="${SKILL_DIR}/token_usage.log"

# shellcheck disable=SC1090
[[ -f "$CONFIG" ]] && source "$CONFIG" 2>/dev/null || true
: "${TOKEN_DAILY_BUDGET:=20000}"
: "${GATE_NOVELTY_LOOKBACK:=5}"
: "${GATE_MAX_PROACTIVE_PER_DAY:=3}"
: "${GATE_RISK_MIN_THRESHOLD:=0.6}"
: "${GATE_QUIET_IF_NO_HUMAN:=true}"

CANDIDATE="${1:-}"
RISK="${2:-0}"
HUMAN_ONLINE="${3:-0}"
TODAY="$(date +%Y-%m-%d)"

journal() { echo "JOURNAL"; exit 1; }
mute()    { echo "MUTE";    exit 1; }

# 1) Budget gate
if [[ -f "$TOKEN_LOG" ]]; then
  USED_TODAY="$(grep -F "$TODAY" "$TOKEN_LOG" 2>/dev/null | awk -F'token=' '{s+=$2} END{print s+0}' || echo 0)"
  if awk "BEGIN{exit !(${USED_TODAY:-0} >= ${TOKEN_DAILY_BUDGET})}"; then mute; fi
fi

# 2) Novelty gate (use cut for the first 6 chars as a fingerprint, avoids unicode tr issues)
if [[ -n "$CANDIDATE" && -f "$TOPICS" ]]; then
  KEY="$(printf '%s' "$CANDIDATE" | cut -c1-6)"
  RECENT="$(grep -v '^#' "$TOPICS" 2>/dev/null | grep -v '^[[:space:]]*$' 2>/dev/null | tail -n "$GATE_NOVELTY_LOOKBACK" || true)"
  if [[ -n "$KEY" ]] && printf '%s' "$RECENT" | grep -qF "$KEY" 2>/dev/null; then journal; fi
fi

# 3) Value gate (risk meeting threshold always broadcasts)
if awk "BEGIN{exit !(${RISK:-0} >= ${GATE_RISK_MIN_THRESHOLD})}"; then
  echo "BROADCAST"; exit 0
fi

# 4) Presence gate (nobody online and not a risk → journal)
if [[ "$GATE_QUIET_IF_NO_HUMAN" == "true" && "$HUMAN_ONLINE" != "1" ]]; then journal; fi

# 5) Quota gate
PROACTIVE_TODAY="$(grep -c "${TODAY}.*\[PROACTIVE\]" "$TOPICS" 2>/dev/null || echo 0)"
PROACTIVE_TODAY="${PROACTIVE_TODAY//[^0-9]/}"; PROACTIVE_TODAY="${PROACTIVE_TODAY:-0}"
if [[ "$PROACTIVE_TODAY" -ge "$GATE_MAX_PROACTIVE_PER_DAY" ]]; then journal; fi

echo "BROADCAST"
exit 0
