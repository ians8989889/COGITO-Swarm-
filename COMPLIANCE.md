# ⚖️ COMPLIANCE — Legal / Regulatory / Privacy Assessment

> Not legal advice. I am not a lawyer; this is an engineering-angle risk inventory + the corresponding framework settings.
> Before going live (especially commercially or handling others' personal data), confirm with a local lawyer.

This framework has three inherent regulatory-sensitive points: **it speaks proactively, it sends data to multiple cloud models, and it executes actions autonomously.**
Each is assessed below, with the existing setting that lowers the risk.

---

## 1. Disclosure obligation: the bot must let people know they're "talking to an AI"

**Regulation:** EU AI Act Article 50 (enforceable from 2026-08-02) requires AI systems interacting with real persons to clearly inform them at first interaction that they're talking to a machine; generated content must be identifiable. Taiwan's PDPA also requires informing the data subject of the collection purpose and identity.

**Risk in this framework:** the Leader speaks proactively on Telegram. If there are unaware real people in the group, you could trip the "undisclosed AI identity" rule.

**Mitigation (in the framework / recommended):**
- AI marking in the bot name, group pin, or every `<TG_MESSAGE>`.
- Recommend enabling `AI_DISCLOSURE_REQUIRED=true` in `config.env`, auto-appending "I am an AI bot" on first speech.
- Externally published conclusions can carry generated-content marking (watermark/metadata), echoing Article 50 and the C2PA trend.

---

## 2. Cross-border transfer + third parties: the ensemble sends data to multiple cloud models

**Regulation:** Taiwan PDPA Article 21 — cross-border transfer of personal data is allowed in principle, but the competent authority may restrict it where "the receiving country lacks adequate protection" or "to circumvent the PDPA"; and **transfers to Mainland China have special restrictions.** Violating international transfer limits can carry up to 5 years' imprisonment and fines up to NTD 1,000,000. Third-party transfers have special notice/consent requirements.

**This framework's highest risk is here:**
- `BAGGING_MODELS` / `<ASK_CLOUD>` will send task content (possibly containing personal data) to GPT / Claude / Gemini behind OpenRouter — **this is cross-border + multiple third parties.**
- If task content contains others' personal data without consent, or is sent to an inadequately-protected/restricted jurisdiction, it may violate the PDPA.

**Mitigation (strongly recommended):**
- **De-identify before sending to the cloud:** mask names, phone numbers, addresses, IDs before `<ASK_CLOUD>` (recommend `CLOUD_PII_REDACT=true`).
- **Whitelist jurisdictions:** `BAGGING_MODELS` should only pick models in regions with adequate data protection; avoid restricted destinations.
- **Consent and notice:** if handling others' personal data, confirm the collection purpose and third-party transfer have been disclosed/consented.
- **Data minimization:** `<ASK_CLOUD>` sends only "the minimal snippet needed for verification," not the whole conversation.
- **Logging:** beyond `token_usage.log`, log "which data was sent to which model" for audit.

> ⚠️ This is the compliance point this framework most requires you to handle actively. The framework does **not** de-identify by default — it's just a tool, and what gets sent out is your decision.

---

## 3. Autonomous execution: Action-First really runs commands / spawns / calls APIs

**Regulation/risk:** the 2026 AI Safety Report calls this out — when an autonomous agent executes an unauthorized action (deleting files, financial transactions), the harm is done before a human notices and is hard to intervene in. The EU AI Act requires anomaly detection, documented escalation paths, and human oversight for high-risk systems.

**Risk in this framework:** `<ACTION>` really triggers bash / crawler / API. If a Worker gets a dangerous command or is injected, real harm could result.

**Mitigation (in the framework):**
- **Evidence ledger + Execution Gate:** already require verifiable evidence, indirectly limiting "running wild."
- **Human-in-the-loop escalation:** timeout/low-confidence/high-risk → escalate to human (corresponds to the AI Act's escalation path).
- **Recommended additions:** `ACTION_ALLOWLIST` (only allowlisted commands/domains), `ACTION_REQUIRE_HUMAN_ABOVE_RISK` (high-risk actions need human approval), sandboxed execution.
- **Crawler compliance:** respect robots.txt, target-site ToS, API rate limits; don't crawl copyright-protected or login-walled content.

---

## 4. Data retention & data-subject rights

**Regulation:** the PDPA requires deleting personal data once the purpose is achieved or the retention period expires; data subjects have rights to access/correct/delete. The 2025 amendments add an independent supervisory authority (PDPC), DPO, and other GDPR-ward directions.

**This framework's correspondence:**
- `PRIVACY_DATA_RETENTION_DAYS=7` (present) + the Memory Governor's "demote/archive on completion" echo the retention limit.
- `board/`, `learned/`, `events/`, `daily.md` all retain data — if it contains personal data, include it in delete/access mechanisms.
- A `scripts/purge.sh` is provided: clears expired boards and logs by retention period.

---

## 5. Risk tiering: which tier are you probably in?

The EU AI Act tiers by risk. For most hobbyist uses:
- **Most cases are "limited risk"** (chatbot-like); the main obligation is **disclosing the AI identity** (point 1). It was originally estimated that ~85% of AI systems fall under minimal regulation.
- **If used in high-risk scenarios** (recruitment, credit, education scoring, law enforcement, medical, etc. — Annex III), obligations increase sharply: risk management, data governance, human oversight, logging, conformity assessment. **This framework is an experimental tool and is not recommended for direct use in high-risk scenarios.**
- **Copyright:** for crawled content and content sent to the cloud for verification, mind source licensing; don't reproduce protected content in outputs.

---

## 6. One-page checklist (run through before launch)

```
[ ] The bot clearly discloses its AI identity (all group members know they're talking to an AI)
[ ] Content sent to the cloud (ASK_CLOUD/BAGGING) is de-identified or contains no personal data
[ ] BAGGING_MODELS contains no models in restricted/inadequately-protected jurisdictions
[ ] If handling others' personal data: notice/consent and third-party transfer legality confirmed
[ ] <ACTION> has allowlist / sandbox; high-risk actions need human approval
[ ] Crawler respects robots.txt, ToS, rate limits; avoids copyright/login-walled content
[ ] Data retention period set with a purge mechanism
[ ] Not used in Annex III high-risk scenarios (or a compliant alternative has been sought)
[ ] Audit records kept (who, when, what data sent where)
```

---

## 7. The framework's own compliance position (honest)

- This is a **tool/skill**, not a "service provider." Most AI Act/PDPA obligations fall on the **deployer (you)**, not the framework.
- The framework does **not** do de-identification, consent management, or audit reports for you by default — you wire those up.
- Good news: the framework's three core parts **happen to align with regulatory expectations** — the evidence ledger = an auditable evidence chain, HITL escalation = an escalation path, the GATE = throttling before anomalies. Used well, the compliance burden is far smaller than a bare autonomous agent.

> In one line: **technically you're on the right side (auditable, human-in-the-loop); legally the biggest holes are "personal data sent to the cloud" and "disclosing the AI identity" — handle these two first.**
