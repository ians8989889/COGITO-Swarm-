# 🏷️ OUTPUT_CONTRACT — One Response, One Action + Action-First (absorbs Gemini)

> Gemini's two strengths combined on this page:
> 1. **Compute/presentation separation**: collaboration, debugging, and discussion between bots are **written only to the shared board**; TG is just a "broadcast speaker."
> 2. **Action-First / halt-and-fetch**: on hitting an information gap, **immediately stop generating natural language**, emit `<ACTION>` instead, and continue only after the system actually executes and writes the result back into the state machine.
>
> Effect: context and tokens drop sharply (no one reads group chit-chat), self-monologue disappears, hallucination is structurally cut off.

---

## 1. Each response may output only "one" tag (state-machine discipline)

The system intercepts and processes it. One response, one action — keeps output parseable, interceptable, context minimal.

| Tag | Destination | When |
|---|---|---|
| `<WRITE_BOARD>` | `board/` (collaboration channel, **not TG**) | internal notes, plans, messages to other bots, debugging |
| `<ACTION>` | system really executes (spawn / crawler / API / bash) | when external data or execution is needed (see §2) |
| `<ASK_CLOUD>` | cloud model (ask/verify) | confidence < `CONFIDENCE_ASK_CLOUD` (default 0.6) or high risk |
| `<TG_MESSAGE>` | **only this one** goes to the TG group | final conclusion, already converged (`[converge]` mode) |

```
<WRITE_BOARD>
{ "phase":"plan", "note":"need to scrape listing data, preparing to spawn Worker", "confidence":0.7, "next":"await Worker report" }
</WRITE_BOARD>

<ACTION>
{ "cmd":"sessions_spawn", "target":"WorkerBot", "task":"run script to collect latest housing listing data. Return must attach EVIDENCE+confidence." }
</ACTION>

<ASK_CLOUD>
{ "to":"bag", "question":"verify whether this rent-trend conclusion holds: [insert]", "draft_confidence":0.55 }
</ASK_CLOUD>

<TG_MESSAGE>
[converge] Boss, task complete. Conclusion: [precise answer in 3 sentences or fewer]
</TG_MESSAGE>
```

---

## 2. Action-First: halt-and-fetch (stronger anti-hallucination than "verify afterward")

The old version (v1.1) was **verify evidence only after finishing.** v1.2 adds another layer of **generation interruption**:

> **Rule: when a bot hits a "I need to look up / read / compute to know" gap mid-reasoning,
> it is not allowed to keep guessing in natural language; it must stop on the spot, emit `<ACTION>`,
> and continue only after the system writes the real result back into the state machine.**

Contrast:
- ❌ Think-aloud: "I think this API probably returns 200... so there should be 50 records..." → a hallucination breeding ground.
- ✅ Action-First: `<ACTION>` calls the API → system returns the real result → "actually got 47 records (see evidence)."

This cuts off "confabulation out of thin air" **at the moment of generation**, not when reporting.

---

## 3. Relation to compute/presentation separation (save tokens + prevent monologue)

- Collaboration channel = `board/` (only bots read/write, structured, deduplicable).
- Presentation channel = TG (only `<TG_MESSAGE>` gets in, and it must be converged).
- Benefits: Workers/Advisors never read the group → zero group context cost; the group no longer has bots exchanging pleasantries → eliminates self-monologue and the Frankenstein outcome.

> Note: we keep **multiple board files** (`board/*.md|status`) rather than a single `collab_state.json`,
> to avoid lock contention on concurrent single-file writes; but the spirit matches Gemini's — **collaborate on the board, broadcast only to TG**.
