# 🧾 EVIDENCE — Evidence Ledger (anti-hallucination core, solves requirement ⑥)

> Core belief: **facts exist only in the ledger, and must have evidence. Group chat and memory are clues, not facts.**
> Bots are not allowed to infer "it's probably done" from common sense, conversation, or their own memory.

---

## 1. Task states (only DONE/VERIFIED may be called "done")

```
PROPOSED → IN_PROGRESS → CLAIMED → (verify) → VERIFIED → (Bagging vote) → DONE
                            │                     │
                       no evidence→UNVERIFIED   send back IN_PROGRESS
                            │
                          failure→FAILED
```

- `CLAIMED`: the bot says it's done, **but not yet verified.** May not claim success to humans.
- `UNVERIFIED`: no evidence attached, or evidence inconsistent with the claim. **Never** claim success.
- `VERIFIED`: evidence exists and is consistent (verified by Advisor or `evidence_check.sh`). Routine tasks may close here.
- `DONE`: additionally passed a Bagging vote ≥2/3. Critical/external/safety tasks must reach here.

---

## 2. EVIDENCE block format (Worker/Leader reports must attach)

```
RESULT: <one-line conclusion>
STATUS: CLAIMED | FAILED
CONFIDENCE: 0.0–1.0          # v1.2: self-rated confidence. < CONFIDENCE_ASK_CLOUD (0.6) should ask/verify first
EVIDENCE:
  tool: bash | http | file | api
  cmd:  "the actual command or request run"
  exit: 0                       # or HTTP status code
  output: "key snippet of real output (truncation OK, but no fabrication)"
  artifact: "/path/to/file"     # if a file was produced
  hash: "sha256:..."            # recommended for file-type output
  ts: 2026-06-01T09:14:03+08
```

> **v1.2 Action-First (see `protocols/OUTPUT_CONTRACT.md`):** evidence isn't only "attached afterward,"
> it's also "**halt now**" — when an information gap appears mid-reasoning, stop on the spot and emit `<ACTION>`, continue only after the real result returns.
> Cutting off confabulation at the moment of generation is stronger than verifying only after the fact.

### Rules
1. **When `EVIDENCE_REQUIRED=true`, any "done" without this block is downgraded to `UNVERIFIED`.**
2. `output` must be **real execution output**, not filled in by guessing from the task description.
3. If it can't be done, `STATUS: FAILED` + error evidence — **never** fake success.
4. Multi-step tasks: attach evidence for each step, or attach an operation log.

---

## 3. Verification (who checks)

| Task importance | Verification method |
|---|---|
| Routine | `scripts/evidence_check.sh` (local $0) + Advisor spot-check |
| Critical/external/safety | Advisor must verify + Bagging 3 models (told to "check evidence vs. claim consistency; reject if evidence missing") |

`evidence_check.sh` checks: presence of an EVIDENCE block, whether exit succeeded, whether output is non-empty, whether the claim is supported by the output (keyword match).

---

## 4. Hard rule for reporting to humans (written into every SOUL)

> "Better to say 'I haven't done it yet' or 'subtask 2 has no evidence, re-dispatching,'
>  than to ever say 'completed' without producing evidence."

- Reports must attach an **evidence summary** (what was done + what the evidence is).
- Forbidden to infer status from group history/memory (`FACTS_SOURCE=ledger_only`).
- If the status is still CLAIMED/UNVERIFIED, state so honestly; don't round it up to success.

---

## 5. What it blocks and what it doesn't (honest)

- ✅ Blocks: a bot "well-meaningly" inferring completion from conversation, saying an un-run command was run, treating memory as fact.
- ⚠️ Doesn't block: a bot deliberately forging fake evidence. Countermeasures: Advisor + Bagging vote cross-checks, requiring reproducible commands — these reduce the feasibility of forgery but cannot 100% prevent malice.
