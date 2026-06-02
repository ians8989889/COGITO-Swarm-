# 🧮 MEMORY — Memory Governance (absorbs ChatGPT's Memory Governor, solves requirement ③)

> Turns "lower context/tokens" from a slogan into **tiered rules**: what stays in view, what folds, what gets archived.
> Each tier holds only what it should, avoiding stuffing entire histories into context.

---

## Four memory tiers

| Tier | Content | Stored where | Retention | Enters LLM context? |
|---|---|---|---|---|
| **Live Context** | The current turn's task + necessary flags | in prompt | this turn | ✅ all |
| **Working Memory** | State of in-progress tasks, unclosed evidence | `board/*.status`, `topics.md` | task lifetime | ⚠️ **summary lines only**, not full text |
| **Summary** | One-line conclusion of finished tasks + evidence fingerprint | `board/` summaries, `learned/` | 7 days (`PRIVACY_DATA_RETENTION_DAYS`) | ❌ not by default, query if needed |
| **Archive** | Raw long logs, full output | `events/`, files | long | ❌ never directly in context, store pointers only |

---

## Rules

1. **Load Live Context only by default.** When history is needed, **query the board** (read summary lines), don't pour conversation history into the prompt.
2. **Working Memory gives summaries only.** E.g., read the last 5 lines of `topics.md`, not the whole file.
3. **Demote on completion.** Task DONE → write details to Archive, leave only a one-line Summary + evidence fingerprint (hash/exit) on the board.
4. **Group history is not memory.** With `FACTS_SOURCE=ledger_only`: facts come only from the board ledger, not from scrolling back through TG.
5. **Archive stores pointers only.** Put `artifact:/path` or `hash:` in context; fetch the content only when you need to see it.

---

## Why this directly saves tokens

The #1 cause of token blowup in multi-agent systems is "every bot reads the entire group/history into context every turn."
Memory Governor + compute/presentation separation (`OUTPUT_CONTRACT.md`) together:
- Workers/Advisors don't read the group (compute/presentation separation).
- The Leader loads only Live + Working summaries each turn (this page).
- History is reached by **querying the board on demand**, not by stuffing context.

> In one line: **memory lives on the board (cheap disk), not in context (expensive tokens).**
