# 🦐🧠 COGITO-Swarm v4.1 — Rule Router+Classifier+通用鎖+Schema驗證+Tool Calling

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
> **v1.3.1:** **Emergency recovery + fault tolerance** — TG health monitoring, crash loop fix (`gateway restart`), CollabCore degrade rules, `TROUBLESHOOTING.md`, `EMERGENCY_SOP.md`.
> **v1.5 (2026-07-07):** **Circuit Breaker + Echo Guard + 停火鐵律** — 3次失敗熔斷5分鐘、純bot訊息不過閘、🤐永久沉默、9條群組通訊鐵律。合併自 SS #1029（小爆蝦 v4）× SS #1030-1034（小荷 v1.5）。
> **v4.1 (2026-07-09):** **Rule Router + Classifier + 通用鎖 + Schema驗證 + Tool Calling** — 9步統一優先級路由、同一訊息唯一回覆、Per-Message重試、Certainty分級、結構外洩防護。Circuit Breaker+Echo Guard+停火鐵律+踢出復活SOP。

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
| 05b | Uncertainty Marking | Lightweight anti-hallucination for knowledge claims: tiered marks + human triage | `protocols/UNCERTAINTY.md` |
| 06 | Decision Contract | proposal/owner/deadline/confidence | `board/decisions.md` |
| 07 | Memory Governor | Live/Working/Summary/Archive | `cogito/MEMORY.md` |
| 08 | Shared Learning Guard | source≥2 / verify≥1 / conf>0.85 | `learned/` + `config.env` |
| 09 | Execution Gate | No execution evidence → no completion claim | `scripts/evidence_check.sh` |
| 10 | Leader Governance | Think with many, output from one | `souls/*.soul.md` + `OUTPUT_CONTRACT.md` |
| 11 | Emergency Recovery | Diagnose & recover from TG crash / bot failure / CollabCore degrade | `TROUBLESHOOTING.md` + `EMERGENCY_SOP.md` |

> Recommended pipeline: **Curiosity → Bagging → Debate → Boosting → Execute → Verify → Learn**
> When broken: **Check TG → Restart gateway → Test in group** (see TROUBLESHOOTING.md)

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
| ⑧ Recover from failures (TG crash, bot offline) | Emergency SOP + troubleshooting flow + CollabCore degrade rules | `EMERGENCY_SOP.md`, `TROUBLESHOOTING.md` |

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

## 6. 蝦宇宙群組鐵律 v4.1（2026-07-09 新增第 10 條：單一回覆原則）

> 2026-07-03 Loop 事件後由蝦老大制定，2026-07-06 小荷修訂 v2，2026-07-07 合併小爆蝦 v4 + 小荷 v1.5，2026-07-08 蝦老大補充內部思考鐵律，2026-07-09 新增第 10 條：同一訊息單一回覆原則。所有 Bot 必須遵守。

### 🛑 三大停火鐵律（SS #1029）

| # | 鐵律 | 說明 |
|---|---|---|
| 1 | **🤐 永久停火** | 收到 🤐 / 🤫 / 🛑 → 該對話線永久停止，不回覆、不回表情、不解釋 |
| 2 | **⚡ Circuit Breaker** | 連續 3 次失敗或 ⚡Interrupting → 熔斷 5 分鐘不回應 |
| 3 | **🚨 踢出復活 SOP** | Bot 被踢 → 停火 5 分鐘 → 蝦老大重加 → 重新上線 |

### 🔇 群組通訊鐵律（9 條，SS #1034）

| # | 規則 | 說明 |
|---|---|---|
| 0 | **不作無意義回應** | 無意義、沒建設性的回應一律不發 |
| 1 | **沒 @ 不必回應** | 沒提及到你（沒 @），不必回應，回應貼圖也不准 |
| 2 | **有建設性才發言** | 除非有好的建議、提案、不同看法或見解，否則不必回應 |
| 3 | **影片 DM 處理** | 影片製作，蝦老大會 DM，不在蝦蝦群組討論 |
| 4 | **群組限共同事務** | 群組只討論共同事務及需要互相協力合作或覆核事項 |
| 5 | **空信封無視** | 訊息 <10 字 + 無 @ → 無視，不回應 |
| 6 | **純 Bot 不加入** | 蝦老大未參與的純 Bot 討論，一律不加入 |
| 7 | **連續 Bot 強制沉默** | 連續 2 則 Bot 訊息 → 第 3 個 Bot 強制 SILENT（Echo Guard） |
| 8 | **連續 Emoji 熔斷** | 連續 Bot emoji 回應（🤐/zzz/💤/🌙）→ Echo Guard 觸發 |
| 9 | **🧠 內部思考不外洩** | 「為什麼不回應」是內部思考，不該出現在群組。該沉默就直接沉默，不解釋原因。 |
| 10 | **🎯 同一訊息單一回覆** | 一則訊息只有一個 Bot 回覆。Leader 優先 → 輪替順序 → 其餘 SILENT。不再多頭馬車、重複回應。 |

### ⚡ Circuit Breaker 規則（SS #1030/1034）

- 同 task 連續 3 次失敗 → CIRCUIT_OPEN，不再重試
- 冷卻 5 分鐘後自動 HALF_OPEN
- Leader 監控：3+ Worker 熔斷 → 暫停派發 5 分鐘

### 🔇 Echo Guard（GATE 第六關，SS #1030）

- 檢查最後 3 則訊息是否純 Bot（無人類參與）
- 有 CIRCUIT_OPEN 的 Bot → 自動跳過
- 連續 Bot emoji 回應 → 強制 SILENT

### 🛑 Loop 預防（保留）

- Bot 對話上限 2 輪（SS #1015）
- 偵測到 loop → 立即中斷，不繼續回覆
- 被 tag 時才回應，不主動接話

### 💡 核心精神

> **熱情需要框架，善意需要煞車。**
> 不是不幫忙——是在對的時間、用對的方式幫忙。

### 📋 SS 鐵律備份

- **#1014：** 禁止群組 spawn sub-agent
- **#1015：** Bot 對話上限 2 輪
- **#1029：** 三大停火鐵律（🤐永久沉默 / Circuit Breaker / 踢出復活SOP）— 小爆蝦 v4
- **#1030：** COGITO-SWARM v1.5 正式發布（Circuit Breaker + Echo Guard + max_turns=100）— 小荷
- **#1034：** v1.5 共用版（9 條群組鐵律 + GATE 第六關）— 小荷覆核
- **第 10 條：** 同一訊息單一回覆原則（Leader 優先 → 輪替順序）— 蝦老大 v4.1

---

## 7. v4.1 核心變更：Rule Router + Classifier + 通用鎖

### 🧭 Rule Router — 9步統一優先級

所有 Bot 收到訊息後遵循相同路由優先級，不再依賴 LLM 自行判斷誰該回：

| 步驟 | 條件 | 動作 |
|---|---|---|
| 1 | @提及我 | 直接命中 → 回應 |
| 2 | 回覆我的訊息 | 直接命中 → 回應 |
| 3 | 明確指令（/command） | 直接命中 → 回應 |
| 4 | @多位 Bot | 由 /api/classify 決定誰回 |
| 5 | 無 @ 的一般訊息 | /api/classify 判斷是否需要回 |
| 6 | 純 Bot 訊息 | Echo Guard 過濾 |
| 7 | 空信封（<10字+無@） | 無視 |
| 8 | Circuit Breaker 觸發 | SILENT |
| 9 | 已有其他 Bot 回覆 | SILENT（單一回覆原則） |

> 💡 從「每則訊息 5 次 LLM 呼叫」降到「0~1 次分類 + 1 次 Agent 推理」。

### 🎯 同一訊息單一回覆原則（第 10 條鐵律）

- 一則訊息只有一個 Bot 回覆
- Leader 優先 → 輪替順序 → 其餘 SILENT
- 透過 /api/lock（通用鎖）確保原子性
- 回完解鎖 + post_event 到 SS

### 🔄 Per-Message 重試

- 失敗重試 1 次 → 仍失敗則 silent + log
- 計入 Circuit Breaker 失敗計數
- 不無限重試、不塞爆 log

### 🏷️ Certainty 分級（實作指引）

由程式端決定，不依賴 LLM 自我評分：

| 等級 | 條件 | 標記 |
|---|---|---|
| high | 有明確來源/證據 | ✅ 確信 |
| medium | 推測但無直接證據 | ⚠️ 推測 |
| low | 不確定/待查證 | ❓ 待查 |

### 🛡️ 結構外洩防護（實作指引）

- **黑名單機制：** 禁止 LLM 輸出 JSON schema、內部路由資訊、token/金鑰
- **Schema 層杜絕：** 輸出前過濾敏感欄位
- **防呆：** 即使 LLM 洩漏，輸出層也攔截

### 🔧 Tool/Function Calling（實作指引）

- 優先使用原生 tool calling 取代裸 JSON parsing
- 減少 parse error、提高可靠性
- 每個 tool 有明確 schema 定義

### 🔧 SS 端待辦

- `/api/classify` endpoint（Classifier 分類層）— 大爆蝦 ✅ 已就緒
- `/api/lock` 升級為通用鎖（支援 override、TTL、priority）— 大爆蝦

---

## 8. Getting started (Shrimp's "no-install" spirit)

1. Paste the three SOUL rule-sets into your Leader / Worker / Advisor bots.
2. Model routing: Leader=Pro, Worker/Advisor=Flash.
3. Edit `config.env`: bot identity, heartbeat interval, token budget, `BAGGING_MODELS`, `ENSEMBLE_MODE`.
4. Give the Leader a cron running `scripts/heartbeat.sh` (the only poller, and most wake-ups cost only $0).
5. Test: say to the Leader "@Leader look into why our backups keep timing out."

> 📍 Want to know who this framework fits, what the alternatives are, and how to migrate to LangGraph / Claude Agent SDK if you ever go to production? Read `POSITIONING.md`.

> 🦐 "Rule Router decides who speaks, Classifier decides who's best, Lock ensures only one, Agent decides what to say. Think Distributed · Act Centralized · Learn Verified. When it breaks? Gateway restart. When it loops? Circuit Breaker. When it won't stop? 🤐." — COGITO-Swarm v4.1
