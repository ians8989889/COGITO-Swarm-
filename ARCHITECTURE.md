# 🏗️ COGITO-Swarm v1.3.1 — Architecture & Design Rationale

This page is for the "builder": why it's designed this way, how tokens are counted, how state flows.
You don't need to read this for day-to-day operation.

---

## 1. Design principles

1. **Single-heartbeat principle**: only the Leader in the whole swarm has a heartbeat. N bots each heartbeating = N× poller cost, exactly what Shrimp-OS v6 set out to kill. Proactivity is concentrated in one brain; collaboration spreads via spawn/convene.
2. **$0 first, money later**: the first thing the heartbeat does on waking is run the local shell gate (read files, compare, compute budget), all $0. The LLM is called only if the gate lets it through.
3. **Facts only in the ledger**: a bot's memory and group history are "clues," not "facts." Any "done" status must correspond to a ledger entry with evidence. This is a structural anti-hallucination guarantee, not relying on prompt-words to ask the bot not to lie.
4. **Use native mechanisms**: communication uses OpenClaw's `sessions_spawn` / `message`, no invented custom protocol (inherited from Shrimp v6).
5. **Honesty**: this is an experimental hobbyist framework, not production. Limitations listed as-is.

---

## 2. Task state machine (anti-hallucination core)

```
PROPOSED ──spawn──▶ IN_PROGRESS ──attach evidence──▶ CLAIMED
                         │                              │
                  no evidence/failure          Advisor/evidence_check verifies
                         ▼                              │
                      FAILED            ┌───pass (evidence consistent)──▶ VERIFIED ──Bagging vote ≥2/3──▶ DONE
                                        └───fail────────────────────────▶ UNVERIFIED ──send back──▶ IN_PROGRESS
```

- **Only `DONE` may report "done" to humans.** `CLAIMED` / `UNVERIFIED` may never claim success.
- Non-critical tasks may close at `VERIFIED` (skip the ensemble vote, save money); critical/external/safety-related must reach `DONE`.

---

## 3. Gate logic (the mathematical solution to proactive vs. cheap)

The decision tree on every heartbeat wake (all local $0 until the last step):

```
Wake
 ├─ Today's used tokens ≥ budget?             → Yes: record only, sleep
 ├─ Candidate topic duplicates last 5 topics? → Yes: discard, sleep
 ├─ Is it risk/stuck-task/human-online?       → No: write daily.md (journal), sleep   ← this step saves the vast majority of tokens
 ├─ Today's proactive broadcasts ≥ max?       → Yes: write daily.md, sleep
 └─ All passed → call LLM, produce via a thinking mode → broadcast/open task           ← the only token-burning path
```

Key: **"thinking" is cheap (write a journal), "speaking" and "acting" are expensive (LLM+spawn).** The gate keeps most heartbeats at the "thinking" level.

---

## 4. Token cost estimate (continuing Shrimp v6's honesty table)

Assume: Leader heartbeats every 90 minutes = 16/day.

| Path | Share (est) | Cost each | Note |
|---|---|---|---|
| Gate blocks (pure local) | ~12/16 | ≈ $0 | shell reads files & compares, no LLM call |
| Pass gate → LLM think/broadcast | ~2–4/16 | small | capped by `max_proactive_per_day` |
| Worker execution | depends on task | Flash price | zero idle, only on spawn |
| Ensemble verification (Bag/Boost) | critical output only | 3×~500 tok ≈ $0.002 | most tasks skip |

Comparison (same 150 tasks/month scenario):

| Approach | Monthly cost (est) | Proactive? | Anti-hallucination? |
|---|---|---|---|
| ❌ 30s poller × 3 bots | ~$40 | fake proactive (really just spinning) | none |
| 🟡 pure Shrimp v6 (@mention-only) | ~$0.14 | ❌ fully passive | partial (via voting) |
| 🧠 pure COGITO (per-bot heartbeat) | high (N×poller) | ✅ | none |
| ✅ **COGITO-Swarm v1.2** | **~$0.30–0.60** | ✅ controlled proactive | ✅ evidence-enforced |

> The extra few cents buy: real proactivity + structural anti-hallucination. Still ~98% cheaper than a pure poller.
> (Figures are design estimates, not measured; rely on your environment's `token_monitor`.)

---

## 5. Integrated learning data flow

```
Task VERIFIED/DONE → extract reusable conclusion → learned/pending_confirmation/
   → a second bot or a second task verifies again → learned/medium/ or verified/
   → insufficient confidence → learned/low_confidence/ (not adopted, kept for reference only)
```
Dual confirmation (`LEARN_REQUIRE_DUAL_CONFIRM`) prevents a one-off hallucination being absorbed as knowledge.

---

## 6. TG Communication Layer (Single Point of Failure) 🚨

**All inter-bot collaboration in COGITO-Swarm depends on Telegram.**

The TG group chat is the communication backbone for:
- `sessions_spawn` — spawning Workers/Advisors as subagents
- `message()` — reporting results, convening, broadcasting
- CollabCore — round-table discussions

**When TG goes down, the entire swarm goes silent.**

### TG Crash Loop (Most Common Failure)

**Symptom:** All bots stop responding. Log shows every ~10 minutes:
```
[telegram:default] health-monitor: restarting (reason: stopped)
```

**Root cause:** TG subsystem instability → health monitor restarts → crashes again → loop.

**Fix:**
```bash
openclaw gateway restart
```
On every bot machine.

**Prevention:** Install a TG health-check cron (see `TROUBLESHOOTING.md`).

### CollabCore Degrade Rules

| Situation | Behavior |
|-----------|----------|
| Chairman (Leader) offline | Round table suspended; bots only respond to @ |
| 1 seat vacant | Round table proceeds; decisions note the absence |
| 2+ seats vacant | Downgrade to 2-person discussion mode; no formal decisions |
| Bot returns after outage | Chairman sends it the missed meeting summary |

> 🦐 **Design insight:** TG was chosen for simplicity (no custom protocol), but it means the swarm inherits TG's failure modes. Future versions may add a fallback channel (e.g., shared file + polling on Google Drive).

---

## 7. Known limitations (honest)

- Not production: no auto-restart; if the heartbeat itself dies there's no watchdog-of-the-watchdog.
- Parallel spawn cap ~3–5 (OpenClaw limit).
- The evidence mechanism can't stop the malicious case of "a bot forging evidence" — it stops "well-meaning hallucination out of thin air," and reduces forgery room via Advisor + Bagging vote cross-checks.
- Ensemble (Bagging/Boosting) needs an OpenRouter or equivalent API key, and cloud model versions change.
- The TG API has rate limits under high load.
- OpenClaw ecosystem only; CrewAI/LangGraph require rewriting the spawn layer.

---

## 8. Correspondence with the original frameworks (for maintainers)

| Original part | Where it went |
|---|---|
| COGITO `cogito.yaml` | merged into `config.env` (heartbeat/budget/eval sections) |
| COGITO `SKILL.md` thinking modes | → `cogito/MODES.md` |
| COGITO `challenges.md` | → `cogito/CHALLENGES.md` |
| COGITO `daily.md` | → `cogito/daily.md` (generated at runtime) |
| Shrimp SOUL templates ×3 | → `souls/*.soul.md` (added evidence rules) |
| Shrimp `EVENT_PROTOCOL.md` | → `protocols/EVENT_PROTOCOL.md` (added convene + evidence) |
| Shrimp Boosting (misnamed) | → renamed and split into `protocols/ENSEMBLE.md` + `VERIFY-BAGGING.md` + `REFINE-BOOSTING.md` |
| Shrimp `leader_sync.sh` / `token_monitor.sh` | kept in `scripts/` |
| **New (v1)** | `cogito/GATE.md`, `protocols/EVIDENCE.md`, `scripts/heartbeat.sh`, `scripts/gate.sh`, `scripts/evidence_check.sh`, `board/topics.md` |
| **New (v1.1)** | `protocols/ENSEMBLE.md` (router), `protocols/VERIFY-BAGGING.md`, `protocols/REFINE-BOOSTING.md`, `scripts/ensemble_route.sh`, config `ENSEMBLE_MODE`/`BAGGING_*`/`BOOSTING_*` |
| **New (v1.2, absorbs Gemini)** | `protocols/OUTPUT_CONTRACT.md` (compute/presentation separation + Action-First + single tag), config `COMMS_MODE`/`ACTION_FIRST`/`TG_OUTPUT_ONLY` |
| **New (v1.2, absorbs ChatGPT)** | `cogito/MEMORY.md` (Memory Governor), `board/decisions.md` (Decision Contract), EVIDENCE `CONFIDENCE` field, config quantified learning thresholds `LEARN_MIN_SOURCES`/`LEARN_MIN_VERIFY`/`LEARN_MIN_CONFIDENCE` |
| **New (v1.3)** | `protocols/UNCERTAINTY.md` — lightweight anti-hallucination: tiered confidence marks + human triage. Complements EVIDENCE for knowledge/memory claims (not execution). `[確信]`/`[推測]`/`[待查]` + RLHF alignment loop. |
