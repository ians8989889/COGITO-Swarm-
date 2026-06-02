# 🚪 GATE — Proactivity Gate (the core bridge part)

> Contradiction it resolves: COGITO wants bots proactive (burns tokens), Shrimp wants bots quiet (saves tokens).
> Solution: **after the heartbeat wakes, pass a $0 local gate first; only spend money if it passes.** "Thinking" is cheap, "speaking/acting" is expensive.

Run by `scripts/gate.sh` at the very front of every heartbeat. All local checks, no LLM call.

---

## Five checks (failing any one means "journal only, don't broadcast")

### 1. Budget gate 💰
Today's used tokens ≥ `TOKEN_DAILY_BUDGET`?
→ **Yes: block everything.** Record only, no thinking, no speaking. Sleep.

### 2. Novelty gate 🔁
Compare the candidate topic against the last `GATE_NOVELTY_LOOKBACK` entries in `board/topics.md` (keyword/hash).
→ **Duplicate: discard.** Don't say the same thought twice.

### 3. Value gate ⚖️
Is the candidate one of the following?
- Risk alert (money/time/safety/privacy, with risk ≥ `GATE_RISK_MIN_THRESHOLD`)
- Stuck task (a task has timed out and needs rescue)
- Human online **and** a genuinely new idea/topic
→ **None of these: don't broadcast.** Just write to `cogito/daily.md` as daily practice.

### 4. Presence gate 🌙
`GATE_QUIET_IF_NO_HUMAN=true` and nobody currently online and not a risk/task?
→ **Yes: journal only, don't post to the group.** (Lesson from the old daily.md: don't monologue at an empty chat room for two and a half days.)

### 5. Quota gate 📊
Today's proactive "broadcast" count ≥ `GATE_MAX_PROACTIVE_PER_DAY`?
→ **Yes: you've said enough today.** Journal instead.

---

## After passing

All passed → only then does the heartbeat call the LLM, produce output using a mode from `cogito/MODES.md`, then:
- Idea/topic → `message()` one line to the group
- Risk → `message()` name the risk + advice
- Task → go to Leader SOUL section B (spawn)
- Should convene → go to section C (convene), write `board/topics.md`

---

## Why this satisfies both "proactive" and "cheap"

```
16 heartbeats/day
 ├─ ~12: gate blocks → journal ($0)        ← the bot keeps "thinking," spends nothing
 └─ ~2-4: pass gate → LLM output + action   ← spends only when there's real value
```

Proactivity doesn't disappear; it is **demoted to cheap "thinking,"** and only high-value thoughts are promoted to expensive "speaking/acting."
This is the key to letting COGITO (proactive) and Shrimp (cheap) coexist.
