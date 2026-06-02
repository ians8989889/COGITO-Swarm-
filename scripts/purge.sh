#!/usr/bin/env bash
# ============================================================
# purge.sh — clear expired boards and logs by retention period (PDPA retention, $0)
# Usage: purge.sh [--apply]
# Reads config's PRIVACY_DATA_RETENTION_DAYS, deletes over-age events/ and old log lines.
# Defaults to safe dry-run mode; add --apply to actually delete.
# ============================================================
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
CONFIG="${SKILL_DIR}/config.env"
# shellcheck disable=SC1090
[[ -f "$CONFIG" ]] && source "$CONFIG" 2>/dev/null || true
: "${PRIVACY_DATA_RETENTION_DAYS:=7}"

MODE="dry"
[[ "${1:-}" == "--apply" ]] && MODE="apply"

echo "Retention: ${PRIVACY_DATA_RETENTION_DAYS} days  Mode: ${MODE}"
EVENTS_DIR="${SKILL_DIR}/events"

if [[ -d "$EVENTS_DIR" ]]; then
  # Find files past the retention period
  while IFS= read -r f; do
    if [[ "$MODE" == "apply" ]]; then
      rm -f "$f" && echo "deleted: $f"
    else
      echo "[dry-run] would delete: $f"
    fi
  done < <(find "$EVENTS_DIR" -type f -mtime "+${PRIVACY_DATA_RETENTION_DAYS}" 2>/dev/null)
else
  echo "(no events/ directory, skipping)"
fi

echo "Done. dry-run does not actually delete; once confirmed, use: purge.sh --apply"
