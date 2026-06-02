# 🦐🧠 COGITO-Swarm v1.2 — A Multi-Bot System That Thinks Proactively and Collaborates Cheaply

> ⚠️ **Experimental tool, provided AS IS, use at your own risk. Read `DISCLAIMER.md` and `COMPLIANCE.md` before use. Not for high-risk use cases.**
>
> Integrates **COGITO v4 (proactive thinking)** with **Shrimp-OS v6 (multi-bot collaboration)**.
> In one line: **COGITO is the prefrontal cortex (initiates thoughts), Shrimp-OS is the nervous system (divides and executes); two bridge parts — the GATE and the EVIDENCE LEDGER — resolve the contradiction between them.**
>
> **Core principle: Think Distributed · Act Centralized · Learn Verified**
> **Work loop: Observe → Think → Discuss → Decide → Execute → Verify → Learn**
>
> **v1.1:** "Boosting" renamed and split into Bagging (voting) + Boosting (refinement), with `ENSEMBLE_MODE` auto-routing.
> **v1.2:** Absorbed Gemini's **compute/presentation separation** (collaborate on the board, TG broadcasts only) and **Action-First** (halt-and-fetch), plus ChatGPT's **Decision Contract / Memory Governor / Confidence / quantified learning thresholds**.

This is not a manual, it's a **remote control**. When you need to switch a behavior, read just that page — don't stuff the whole package into context.

---

## 0. Why integrate (understand the contradiction first)

| | COGITO v4 | Shrimp-OS v6 |
|---|---|---|
| Goal | Make 1 bot **proactive, talkative, free-associating** | Make many bots **quiet, cheap** |
| Means | Heartbeat cron + 6 thinking modes | Workers stay silent unless spawned; Leader acts only when @-mentioned |
| Problem solved | A-1 passivity | A-2 no collaboration + token blowup |
| Side effect | Talks to an empty room (see old daily.md) | All bots become passive, no initiative |

**They pull in opposite directions.** A naive merge = every bot heartbeating + free-associating + chattering = back to the poller hell Shrimp-OS set out to kill.
COGITO-Swarm's solution: **only the Leader has a heartbeat; the heartbeat first passes a $0 local gate, and the genuinely token-burning LLM thinking is allowed through only 2–4 times a day.**

---

## 1. SKILL index (atomic skills → corresponding files)

| # | SKILL | Purpose | Location in this framework |
|---|---|---|---|
| 01 | Curiosity Engine | Proactive ideation (idle/unfinished/contradiction triggers) | `scripts/heartbeat.sh` + `cogito/MODES.md` |
| 02 | Ensemble Router | Decide Bagging/Boosting/Hybrid | `scripts/ensemble_route.sh` + `protocols/ENSEMBLE.md` |
| 03 | Speech License | Avoid talking to oneself (assigned+new+non-dup) | `cogito/GATE.md` |
| 04 | Group Deliberation | Form consensus (Idea→Research→Critic→Planner→Leader) | `protocols/EVENT_PROTOCOL.md` (convene) |
| 05 | Reality Protocol | Eliminate hallucination (Intent/Action/Evidence/Claim/Confidence) | `protocols/EVIDENCE.md` + `OUTPUT_CONTRACT.md` |
| 06 | Decision Contract | proposal/owner/deadline/confidence | `board/decisions.md` |
| 07 | Memory Governor | Live/Working/Summary/Archive | `cogito/MEMORY.md` |
| 08 | Shared Learning Guard | source≥2 / verify≥1 / conf>0.85 | `learned/` + `config.env` |
| 09 | Execution Gate | No execution evidence → no completion claim | `scripts/evidence_check.sh` |
| 10 | Leader Governance | Think with many, output from one | `souls/*.soul.md` + `OUTPUT_CONTRACT.md` |

> Recommended pipeline: **Curiosity → Bagging → Debate → Boosting → Execute → Verify → Learn**

---

## 2. Seven requirements → mechanisms (one-page map)

| Your requirement | How COGITO-Swarm solves it | Read which page |
|---|---|---|
| ① Proactive thinking, finding topics | Leader heartbeat + 6 thinking modes generate "candidate thoughts" | `cogito/MODES.md`, `scripts/heartbeat.sh` |
| ② Interact with other bots, integrated learning | Role division + `convene` + `learned/` dual-confirmation | `protocols/EVENT_PROTOCOL.md` |
| ③ Minimal context / tokens | Single heartbeat + $0 gate first + zero-idle Workers + **compute/presentation separation** (collaborate on board) + **Memory Governor** tiers | `cogito/GATE.md`, `cogito/MEMORY.md`, `protocols/OUTPUT_CONTRACT.md` |
| ④ Group research/discuss/execute/finish | Leader decomposes → Workers parallel → Advisor reviews → report | `souls/*.soul.md` |
| ⑤ Ask/verify with cloud LLMs via API | Ensemble verification: Bagging vote + Boosting refine (auto-routed) | `protocols/ENSEMBLE.md` |
| ⑥ Real execution results, no hallucination/fake replies | Evidence ledger + **Action-First** (halt-and-fetch) + Confidence self-rating | `protocols/EVIDENCE.md`, `protocols/OUTPUT_CONTRACT.md` |
| ⑦ Integrate the two frameworks | This folder is it | All |

---

## 3. Two bridge parts (the real contribution of the integration)

### 🚪 GATE (resolves "proactive ↔ cheap")
After the heartbeat wakes, **run a $0 local check first**; only spend tokens if it passes:
1. **Budget** — Is today's token budget still available? No → journal only, don't speak.
2. **Novelty** — Compare against the last N entries in `board/topics.md`; duplicate topic → drop.
3. **Value** — Is it one of: risk alert / stuck task / human online + genuinely new idea? None of these → journal, don't broadcast.
4. **Presence** — Nobody online and not a risk/task → write to the journal (`cogito/daily.md`), do **not** post to the group.
5. **Speech rights** — Only the Leader may proactively broadcast; Workers never; Advisor only advises.
→ See `cogito/GATE.md`

### 🧾 EVIDENCE (resolves "hallucination / fake replies")
**Any bot that wants to mark a status as "done" must attach verifiable evidence** (command, exit code, output snippet, file hash, URL).
- No evidence → automatically flagged `UNVERIFIED`; **must not** report success to humans.
- Group chat and memory are **clues, not the source of truth**. Facts live only in the ledger and must have evidence.
- Hard rule: "Better to say 'I haven't done it yet' than to say 'done' without proof."
→ See `protocols/EVIDENCE.md`

---

## 4. Roles (Shrimp-OS triangle + COGITO brain)

| Role | Model | Heartbeat? | Responsibilities |
|---|---|---|---|
| 👑 Leader | Pro | ✅ the only one | Proactive ideation (past the gate), decompose tasks, spawn, convene, synthesize, report. Every report needs evidence. |
| 🔧 Worker | Flash | ❌ zero idle | Acts only when spawned; execute → **must attach evidence** → auto-return. Doesn't speak, doesn't initiate. |
| 🔍 Advisor | Flash | ❌ | Review + **verify evidence** (check claim vs. evidence consistency). Advises only, never decides. |

→ The three SOUL rule-sets live in `souls/`. Paste each into the corresponding bot's SOUL.md.

---

## 5. Full flow of one task (proactive version)

```
Leader heartbeat wakes
  → gate.sh ($0 local check)  ──fail──→ write cogito/daily.md, end (cost ≈ $0)
        │ pass
        ▼
  Generate candidate: "this is a topic worth convening on"
  → write board/topics.md + @relevant bots (convene, bounded rounds)
  → sessions_spawn Workers to run subtasks (parallel 3–5)
        │
   Worker returns [with EVIDENCE] ──no evidence──→ flag UNVERIFIED, send back to redo
        │ has evidence
        ▼
  Advisor verifies evidence + critical output → Bagging 3-model parallel vote (≥2/3 and evidence-consistent)
        │ pass
        ▼
  Leader message() reports to human (with evidence summary) → write learned/ (promote after dual confirmation)
```

→ Full protocol in `protocols/EVENT_PROTOCOL.md`

---

## 6. Getting started (Shrimp's "no-install" spirit)

1. Paste the three SOUL rule-sets into your Leader / Worker / Advisor bots.
2. Model routing: Leader=Pro, Worker/Advisor=Flash.
3. Edit `config.env`: bot identity, heartbeat interval, token budget, `BAGGING_MODELS`, `ENSEMBLE_MODE`.
4. Give the Leader a cron running `scripts/heartbeat.sh` (the only poller, and most wake-ups cost only $0).
5. Test: say to the Leader "@Leader look into why our backups keep timing out."

> 📍 Want to know who this framework fits, what the alternatives are, and how to migrate to LangGraph / Claude Agent SDK if you ever go to production? Read `POSITIONING.md`.

> 🦐 "One initiates, three verify, the shrimp swarm executes — and this time, no evidence means you don't get to say it's done." — COGITO-Swarm v1.2
