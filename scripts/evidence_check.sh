#!/usr/bin/env bash
# ============================================================
# evidence_check.sh — verify evidence ($0 local first anti-hallucination gate)
# Usage: evidence_check.sh <result_file>
#   result_file contains RESULT/STATUS/EVIDENCE blocks (see protocols/EVIDENCE.md)
# Output: VERIFIED | UNVERIFIED | FAILED + reason
# Exit code: 0=VERIFIED  1=UNVERIFIED  2=FAILED
# Token cost: $0
# ============================================================
set -euo pipefail

FILE="${1:?Usage: evidence_check.sh <result_file>}"
[[ -f "$FILE" ]] || { echo "UNVERIFIED: result file not found"; exit 1; }

content="$(cat "$FILE")"

# STATUS=FAILED → FAILED directly
if echo "$content" | grep -qiE '^STATUS:[[:space:]]*FAILED'; then
  echo "FAILED: bot self-reported failure (honest, correct behavior)"; exit 2
fi

# 1) Must have an EVIDENCE block
if ! echo "$content" | grep -qiE '^EVIDENCE:'; then
  echo "UNVERIFIED: missing EVIDENCE block — not allowed to count as done"; exit 1
fi

# 2) Must have cmd and exit
echo "$content" | grep -qiE '^[[:space:]]*cmd:'  || { echo "UNVERIFIED: evidence missing cmd"; exit 1; }
exit_line="$(echo "$content" | grep -iE '^[[:space:]]*exit:' | head -1 | sed 's/.*exit:[[:space:]]*//I')"
[[ -n "$exit_line" ]] || { echo "UNVERIFIED: evidence missing exit/status code"; exit 1; }

# 3) exit must indicate success (0 or 2xx)
if ! echo "$exit_line" | grep -qE '^(0|2[0-9][0-9])$'; then
  echo "UNVERIFIED: evidence shows non-success (exit=${exit_line})"; exit 1
fi

# 4) output must be non-empty (no empty-shell success claim)
out_line="$(echo "$content" | grep -iE '^[[:space:]]*output:' | head -1 | sed 's/.*output:[[:space:]]*//I' | tr -d '"')"
if [[ -z "${out_line// /}" ]]; then
  echo "UNVERIFIED: output empty — no proof of actual execution"; exit 1
fi

echo "VERIFIED: evidence complete, exit succeeded, output non-empty (claim consistency still warrants Advisor/Bagging review)"

# 5) v1.2 confidence check (if a CONFIDENCE field is present)
conf="$(echo "$content" | grep -iE '^CONFIDENCE:' | head -1 | sed 's/.*CONFIDENCE:[[:space:]]*//I')"
if [[ -n "$conf" ]]; then
  if awk "BEGIN{exit !(${conf:-1} < 0.6)}"; then
    echo "  ↳ Note: CONFIDENCE=${conf} < 0.6, recommend <ASK_CLOUD> to verify before finalizing"
  fi
fi
exit 0
