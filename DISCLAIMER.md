# ⚠️ DISCLAIMER

**Read this in full before using COGITO-Swarm. Installing, configuring, or running this framework means you have understood and accepted the following terms.**

---

## 1. Nature: an experimental tool, not a formal product

COGITO-Swarm is an **experimental, hobbyist-grade** open-source framework, provided **AS IS.**
It is **not** a production-ready product and comes with **no** warranties, express or implied, including but not limited to merchantability, fitness for a particular purpose, non-infringement, reliability, availability, or correctness.
The authors and contributors **do not guarantee** that it will work properly, run uninterrupted, be error-free, or produce any particular result.

---

## 2. Autonomous execution risk: consequences are yours

This framework lets AI agents **autonomously execute real actions** — run commands, spawn subprocesses, call APIs, crawl data, speak externally.

- The AI may **misjudge, err, be prompt-injected, or behave unexpectedly.**
- Harm from autonomous actions (deleted files, mis-triggered APIs, wrong messages sent, costs incurred) **may be done before you notice.**
- The anti-hallucination mechanisms (evidence ledger, Action-First, ensemble voting) **reduce but do not eliminate** errors and hallucinations, and **cannot prevent deliberate forgery or all failure modes.**

> **Strongly recommended: run in an isolated/sandbox environment, set `ACTION_ALLOWLIST`, require human approval for high-risk actions, and always retain the ability to intervene and emergency-stop.**
> For any direct, indirect, incidental, or consequential damages caused by this framework's autonomous behavior, the authors and contributors **bear no liability.**

---

## 3. Third-party services and costs

- This framework calls third-party services (OpenClaw, Telegram, OpenRouter, various cloud LLM APIs, etc.). These services have **their own terms, privacy policies, availability, and billing**, outside this framework's control.
- **API and token costs are yours.** Heartbeat, ensemble, and spawn can all incur costs; misconfiguration (e.g., disabling the gate, raising the frequency) can cause **cost blowups.** Set `TOKEN_DAILY_BUDGET` and monitor it yourself.
- Cloud model versions, behavior, and availability change and may invalidate existing configurations.

---

## 4. Legal, compliance, and privacy: you are the responsible party

- You are the **deployer** of this framework; most legal obligations fall on you, not the framework or the authors.
- You are **solely responsible** for complying with all applicable laws, including but not limited to: personal data protection (Taiwan PDPA, GDPR, etc.), AI regulation (EU AI Act, etc.), cross-border data transfer restrictions, AI-identity disclosure obligations, copyright, and the terms of use of crawlers and each service.
- The framework **does not** by default do de-identification, consent management, audit reports, or content marking for you. Any data sent to the cloud (possibly containing personal data) is your decision and responsibility.
- See `COMPLIANCE.md`. Reading that document **does not constitute** legal advice; before involving others' personal data or commercial use, consult a qualified local lawyer.

---

## 5. Not for these scenarios

This framework **must not** be used for:

- **High-risk scenarios** (EU AI Act Annex III, etc.): recruitment, credit scoring, education scoring, law enforcement, medical diagnosis, critical infrastructure, etc.
- Any decision relying **solely** on legal, medical, or financial professional judgment.
- Any **illegal, infringing, or harmful** purpose.
- Any data collection, surveillance, or automation without proper authorization.

This framework's output is **for reference only** and does not constitute professional advice; important decisions must be reviewed by a qualified human.

---

## 6. Content generation and correctness

- AI-generated content **may be incorrect, outdated, biased, or misleading**, even with "evidence" attached (evidence proves execution happened, not that the conclusion is correct).
- The confidence value (CONFIDENCE) is the AI's **self-rating**, not an objective correctness guarantee.
- Users should **independently verify** any output used for important purposes.

---

## 7. Limitation of liability

To the maximum extent permitted by applicable law:
the authors, contributors, and copyright holders shall **bear no liability** for any claim, damages, or other liability arising from the use of or inability to use this framework (whether based on contract, tort, or otherwise).
This disclaimer applies together with the MIT License terms; in case of conflict, the interpretation more favorable to the authors' disclaimer of liability prevails.

---

## 8. Changes

This framework and this disclaimer may be updated at any time without notice. Continued use means acceptance of the latest version.

---

> In one line: **this is an experimental tool for technically savvy people willing to bear their own risk. Use it in an environment where you can absorb the consequences, and don't treat it as a reliable, compliant, or liability-bearing product.**

_Last updated: 2026-06 · Applies to: COGITO-Swarm v1.2_
