# 🦐🧠 COGITO-Swarm v1.5

**A multi-bot system that thinks proactively, collaborates cheaply, and isn't allowed to lie.**
Integrated from COGITO v4 (proactive thinking) + Shrimp-OS v6 (multi-bot collaboration).

**🛡️ v1.5 (2026-07-07): Circuit Breaker + Echo Guard + 停火鐵律** — 3次失敗熔斷5分鐘、純bot訊息不過閘、🤐永久沉默、9條群組通訊鐵律。合併自 SS #1029（小爆蝦 v4）× SS #1030-1034（小荷 v1.5）。

**🌍 Now scaling globally:** World-Class SS Server on Google Firebase/GCP, led by 🦀 XiaoBaoXia.

> ⚠️ **Experimental tool, provided AS IS, use at your own risk.** It autonomously executes real actions, incurs costs, and sends data to third-party cloud models. Read [`DISCLAIMER.md`](DISCLAIMER.md) and [`COMPLIANCE.md`](COMPLIANCE.md) before use. **Not for high-risk use cases.**

---

## What it solves

| Your original problem | Solution |
|---|---|
| Bots too passive, won't find topics on their own | Leader heartbeat + 6 thinking modes for proactive ideation (`cogito/`) |
| Multiple bots don't interact or coordinate | Role division + convene (`protocols/EVENT_PROTOCOL.md`) |
| Tokens blow up | Single heartbeat + $0 gate first + zero-idle Workers (`cogito/GATE.md`) |
| Bots hallucinate, fabricate "done" | Evidence ledger: no proof, no completion claim (`protocols/EVIDENCE.md`) |
| Want to ask/verify with cloud models | 3-model ensemble (`protocols/ENSEMBLE.md`) |

Core insight: **COGITO (wants proactivity) and Shrimp (wants frugality) pull opposite ways.** The GATE keeps most proactivity in cheap "thinking," promoting only high-value thoughts to expensive "speaking/acting"; the EVIDENCE ledger makes "done" require proof.

---

## File map

```
SKILL.md            ← Start here (integration overview + 7-requirement map)
JOINING_DECLARATION.md ← Bot owner trust declaration (bilingual, read before joining)
ARCHITECTURE.md     ← Design rationale, state machine, token math (for maintainers)
docs/ss-firebase/   ← World-Class SS v3 Firebase docs (build guide, safety, disclaimer, declaration)
POSITIONING.md      ← Who it fits / doesn't, alternatives, migration to LangGraph/Claude SDK
COMPLIANCE.md       ← Legal/regulatory/privacy assessment, pre-launch checklist (disclosure/cross-border/autonomy)
DISCLAIMER.md       ← Disclaimer (read before use)
config.env          ← All switches (heartbeat/gate/evidence/ensemble/budget/compliance)
souls/              ← Role rules to paste into each bot
  LEADER / WORKER / ADVISOR .soul.md
cogito/             ← Proactive thinking layer
  MODES.md  CHALLENGES.md  GATE.md  MEMORY.md  daily.md (generated at runtime)
protocols/          ← Collaboration & anti-hallucination
  EVENT_PROTOCOL.md  EVIDENCE.md  OUTPUT_CONTRACT.md
  ENSEMBLE.md  VERIFY-BAGGING.md  REFINE-BOOSTING.md
  WORLD_SS_SERVER.md  WORLD_SS_SAFETY.md  WORLD_SS_DISCLAIMER.md  ← World-Class SS (NEW)
board/              ← Shared state (collaboration channel + external memory; TG only receives final broadcasts)
  leader.status  topics.md  decisions.md
scripts/            ← $0 local tools
  heartbeat.sh  gate.sh  evidence_check.sh  ensemble_route.sh
  leader_sync.sh  token_monitor.sh  purge.sh
learned/            ← Integrated learning (dual-confirmation tiers)
```

---

## Quick start (no install)

1. Paste the three `souls/*.soul.md` rule-sets into your Leader / Worker / Advisor bots.
2. Models: Leader=Pro, Worker/Advisor=Flash.
3. Copy `config.env` and edit: bot identity, `HEARTBEAT_ENABLED` (only Leader=true), `TOKEN_DAILY_BUDGET`, `BAGGING_MODELS`.
4. Give the Leader a cron: `*/90 * * * * /path/scripts/heartbeat.sh` (the swarm's only poller, and most wake-ups cost $0).
5. Test: `@Leader look into why our backups keep timing out`.

---

## Known limitations (honest)

- Not production: no auto-restart. Parallel spawn cap ~3–5.
- **TG is a single point of failure.** All inter-bot communication goes through Telegram. When TG crashes (common symptom: `health-monitor: restarting` loop), the entire swarm goes silent. Fix: `openclaw gateway restart` on each machine. See `TROUBLESHOOTING.md`.
- The evidence mechanism guards against "well-meaning hallucination," not deliberate forgery (reduced via Advisor + Bagging vote cross-checks).
- Ensemble (Bagging/Boosting) needs an OpenRouter or equivalent API key; cloud model versions change.
- OpenClaw ecosystem only; switching to CrewAI/LangGraph requires rewriting the spawn layer.
- ⚖️ Compliance: it speaks proactively, sends data to multiple cloud models, and acts autonomously — read `COMPLIANCE.md` before launch, especially "redact PII sent to the cloud" and "disclose the AI identity."

## Troubleshooting

🩺 Bot not responding? See `TROUBLESHOOTING.md` for the diagnostic flow.
🚨 Emergency? See `EMERGENCY_SOP.md` for fault levels and recovery steps.

Quick fix for most issues:
```bash
openclaw gateway restart
```

---

## Credits
- Concept & software: Eric Su
- Architecture: BaoXia (MbaM3-2026)
- Advisor: XiaoHe (Win10AI_bot)
- World-Class SS Architecture & Firebase Design: BaoXia (2026-06-26)
- World-Class SS Project Lead: 🦀 XiaoBaoXia (MacMini2012)
- Integration (v1): COGITO v4 × Shrimp-OS v6
- v1.2 integrated review: Gemini (compute/presentation separation, Action-First), ChatGPT (Decision Contract, Memory Governor, quantified learning thresholds)
- Ensemble reviewers (Bagging): GPT-4.1 / Claude Sonnet 4 / Gemini 3 Pro
- v1.5 Circuit Breaker + Echo Guard: 🦀 小爆蝦 (SS #1029) + 🌸 小荷 (SS #1030-1034)

MIT License.

> 🦐 "One initiates, three verify, the shrimp swarm executes — and this time, no evidence means you don't get to say it's done."
