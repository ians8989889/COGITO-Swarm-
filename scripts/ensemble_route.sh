#!/usr/bin/env bash
# ============================================================
# ensemble_route.sh — auto-route the ensemble mode ($0 local)
# Usage: ensemble_route.sh <task_class> <is_verifiable 0|1> <is_hard 0|1> <is_critical 0|1>
#   task_class: routine | verify | generate | critical
# Output: skip | bag | boost | boost_then_bag
# Rules in protocols/ENSEMBLE.md
# If config's ENSEMBLE_MODE is not auto, return that value directly (override)
# Token cost: $0
# ============================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
CONFIG="${SKILL_DIR}/config.env"
# shellcheck disable=SC1090
[[ -f "$CONFIG" ]] && source "$CONFIG" 2>/dev/null || true
: "${ENSEMBLE_MODE:=auto}"

# Hard-set value overrides auto
case "$ENSEMBLE_MODE" in
  bag|boost|boost_then_bag|off|skip)
    [[ "$ENSEMBLE_MODE" == "off" ]] && echo "skip" || echo "$ENSEMBLE_MODE"
    exit 0 ;;
esac

TASK_CLASS="${1:-routine}"
VERIFIABLE="${2:-0}"
HARD="${3:-0}"
CRITICAL="${4:-0}"

# Routine/internal → no ensemble
if [[ "$TASK_CLASS" == "routine" ]]; then echo "skip"; exit 0; fi

# Hard AND critical AND verifiable → refine first, then vote
if [[ "$CRITICAL" == "1" && "$HARD" == "1" && "$VERIFIABLE" == "1" ]]; then
  echo "boost_then_bag"; exit 0
fi

# Has right/wrong, guard random hallucination → Bagging vote
if [[ "$VERIFIABLE" == "1" || "$TASK_CLASS" == "verify" ]]; then
  echo "bag"; exit 0
fi

# Hard, needs stepwise refinement → Boosting
if [[ "$HARD" == "1" || "$TASK_CLASS" == "generate" ]]; then
  echo "boost"; exit 0
fi

# critical but neither clearly verifiable nor clearly hard → conservatively use bag (anti-hallucination first)
if [[ "$TASK_CLASS" == "critical" || "$CRITICAL" == "1" ]]; then
  echo "bag"; exit 0
fi

echo "skip"
