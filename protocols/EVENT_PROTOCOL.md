# 📡 EVENT_PROTOCOL — Communication Flow (no custom protocol, use OpenClaw native)

Follows the Shrimp-OS v6 spirit: everything uses `sessions_spawn` / `message`, no invented message format.
Adds two sections: **convene** and **evidence**.

> **v1.2 compute/presentation separation (absorbs Gemini):** collaboration/discussion/debugging between bots is **written only to `board/`**;
> the TG group only receives `<TG_MESSAGE>` (the final, converged conclusion). Workers/Advisors don't read the group → zero group context.
> One-response-one-action tag discipline is in `protocols/OUTPUT_CONTRACT.md`.

---

## 1. Human → Leader (TG group @)
```
@Leader look into why backups keep timing out
@Leader make @OtherBot the head
```

## 2. Leader proactive initiation (heartbeat, solves requirement ①)
```
heartbeat.sh → gate.sh
  fail → write cogito/daily.md (don't speak)
  pass-internal → <WRITE_BOARD> note the thought/plan (not to TG)
  pass-should-go-external → <TG_MESSAGE>[converge] hey, the backup job has timed out three days running, want me to find the root cause?  ← the only path to TG
```

## 3. Leader → Worker (dispatch, solves requirement ④)
```
sessions_spawn(agentId="WorkerBot",
  task="Inspect the last three logs of backup job cb15cdb2, find the timeout root cause. Return must attach EVIDENCE.",
  mode="run")
```
The Worker executes in an isolated session → the result (**with EVIDENCE**) auto-returns.

## 4. Leader → convene (multiple bots research together, solves requirement ②)
```
# write to board
board/topics.md  ←  [CONVENE] backup timeout root cause | need:@XiaoHe @WorkerBot2 | deadline:10min | round:1/2
# @ them, ask specific questions, require basis
message("@XiaoHe can you see storage I/O on your side? @WorkerBot2 check network. Each attach your basis.")
```
Collected → Leader synthesizes → if insufficient and below `CONVENE_MAX_ROUNDS` → open round 2 → at cap, **force convergence**.

## 5. Leader → ensemble (ask/verify with cloud models, solves requirement ⑤)
See `protocols/ENSEMBLE.md`. ensemble_route.sh picks bag/boost; both asking and voting go through `sessions_spawn` to OpenRouter models.

## 6. Acceptance (anti-hallucination, solves requirement ⑥)
```
Worker returns → has EVIDENCE?
  none → flag UNVERIFIED, send back (message the Worker to redo)
  has → evidence_check.sh + Advisor verify → VERIFIED
        critical → ensemble (bag vote / boost refine, check evidence consistency) → DONE
```

## 7. Advisor → shared board (optional advice, **not to TG**)
```
# write to board/topics.md or board/decisions.md, not the group:
[ADVISOR SUGGESTION] also check /var/log
[ADVISOR RISK] subtask 2 has no evidence, should be flagged UNVERIFIED
[ADVISOR OK] evidence verified | confidence:0.9
```
The Advisor never posts to TG; the Leader reads the board and adopts or ignores.

## 8. Leader → human (report, must attach evidence)
```
message("✅ Root cause found: storage I/O collides with another job in the 02:00 backup window.
         Evidence: iostat shows await spiking to 1200ms (see evidence). Suggest staggering the schedule.")
```

## 9. Handover
```
Human: @NewBot you take the head
Old Leader: message("handover: 0 tasks in progress") → leader_sync.sh NewBot human
New Leader: takes over the heartbeat and spawn rights
```

---

## Best Practices
1. Leader=Pro, Worker/Advisor=Flash.
2. **Only the Leader in the whole swarm has a heartbeat.** Workers/Advisors set `HEARTBEAT_ENABLED=false`.
3. Workers have no TG channel (avoids group noise).
4. One spawn, one responsibility.
5. Convene has bounded rounds; ensemble (Bagging/Boosting) is used only for critical output.
6. **Any "done" must have evidence.**
