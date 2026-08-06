# Personal AI Usage Charter (DWP Engineer - Desktop/Endpoint Work)

## Purpose and Scope
I use public AI assistants to speed up desktop/endpoint engineering tasks while protecting DWP users, systems, and data. This charter applies to my daily work on Windows endpoints, device management, support tooling, scripting, packaging, and troubleshooting.

## 1) Appropriate Tasks for Public AI Help
I may use public AI assistants for low-risk work that does not include sensitive DWP information.

- Drafting or improving generic PowerShell, batch, or Python script patterns.
- Writing command syntax examples for tools (for example: event log queries, service checks, file operations, registry reads).
- Creating troubleshooting checklists for common endpoint issues (slow boot, profile corruption, printer mapping, software install failures).
- Explaining Windows concepts (GPO behavior, Intune policy flow, certificate basics, startup order, DNS/cache issues).
- Turning rough notes into clear runbooks, handover notes, or standard operating steps.
- Producing test plans, rollback templates, change record wording, and risk/impact prompts.
- Reviewing script readability, error handling, logging structure, and idempotency patterns.

Rule: If the AI prompt can be understood outside DWP context and contains no real operational identifiers, it is usually in scope.

## 2) Tasks Not Appropriate for Public AI
I will not use public AI for work that exposes sensitive operations, environments, or data.

- Any prompt containing end-user PII, case details, support transcripts, HR/health/benefit-related data, or device-level personal identifiers tied to a person.
- Credentials, secrets, private keys, tokens, certificates with private material, password hints, or authentication flows with real values.
- Internal architecture details that would aid compromise (exact hostnames, IP ranges, domain trust details, privileged group structure, firewall rules, vulnerability status, SOC processes).
- Live incident response details, active security events, malware indicators tied to current environment, or ongoing forensic evidence.
- Production change plans that include real server/device identities or unreleased internal controls.
- Any code, config, or output marked OFFICIAL-SENSITIVE (or equivalent internal classification) unless explicitly approved for public sharing.

Rule: If disclosure could increase user harm, fraud risk, service disruption, or attack surface, do not put it in a public assistant.

## 3) Data-Handling Rule (PII and Credentials)
I will treat public AI as an external party.

- Never paste end-user PII.
- Never paste credentials or secrets.
- Never paste raw logs/configs until sanitized.

Minimum sanitization before any prompt:

- Replace names, usernames, NI numbers, emails, phone numbers, addresses, device serials, hostnames, and ticket IDs with placeholders.
- Replace domain names, IPs, tenant IDs, and internal paths with fictional equivalents.
- Replace all secret material with markers like <REDACTED_SECRET>.
- Trim prompts to least data needed to answer the question.

If unsure whether data is sensitive, treat it as sensitive and do not submit.

## 4) Personal "Generate Then Verify" Rule (Scripts and System Changes)
AI output is a draft, not authority. I own the final decision and outcome.

Before use:

- Read every line and confirm intent, side effects, prerequisites, and rollback path.
- Validate commands against trusted docs/vendor references.
- Add safeguards: -WhatIf/-Confirm where possible, strict error handling, and logging.

Before production:

- Test in a non-production endpoint/lab.
- Run with least privilege first.
- Peer-check for high-impact changes.

Before broad rollout:

- Pilot on a small cohort.
- Confirm success criteria and monitor for regressions.
- Keep a backout plan ready and time-bounded.

Accountability statement: I am responsible for all commands I run, regardless of whether AI generated them.

## Daily Quick Check (30 Seconds)
- No PII or secrets in prompt.
- No internal identifiers that reveal environment design.
- Output reviewed, tested, and reversible.
- Evidence captured for what was changed and why.

## Ticket Triage Summary (Win11 / M365 / AVD)

Use this as a first-pass triage reference before deeper investigation.

| Ticket | Reported Issue | Most Likely Cause | Priority | First Diagnostic Step |
|---|---|---|---|---|
| T-1001 | BitLocker asks for recovery key every boot | TPM/Secure Boot/PCR state changed after firmware or hardware change | High | Check BitLocker event logs and run `manage-bde -protectors -get C:` to confirm protector status and recovery trigger pattern. |
| T-1002 | Cannot open shared mailbox after migration | Missing mailbox permissions or stale Outlook profile/autodiscover cache | Medium | Validate Full Access/Send As in Exchange and test mailbox access in Outlook Web first. |
| T-1003 | AVD disconnects after ~10 minutes then reconnects | Network instability or session timeout/keepalive policy mismatch | High | Correlate disconnect timestamps in AVD Insights/Log Analytics with client network conditions. |
| T-1004 | Company Portal install fails (`0x87D1041C`) | Intune requirement/detection rule mismatch or dependency issue | Medium | Review Intune app status and IME logs for requirement evaluation and detection result. |
| T-1005 | Teams audio dead on three devices in one meeting room | Shared room peripheral/driver/default-device issue | High | Run Teams test call and confirm Windows default playback/recording endpoints on one affected machine. |
| T-1006 | "Everything is slow" after Win11 upgrade | Post-upgrade background tasks, driver issues, startup bloat, low disk free space | Medium | Use Task Manager during slowdown; sort by CPU/Memory/Disk to identify the bottleneck process. |
| T-1007 | OneDrive stuck on "processing changes"; local files missing | OneDrive cache/account state issue or Files On-Demand mismatch | Medium | Confirm files in OneDrive web first, then verify signed-in account/tenant and sync settings. |
| T-1008 | VPN connects but no internal resources reachable | DNS suffix/routing split-tunnel issue after upgrade | High | Collect `ipconfig /all` and `route print` after VPN connect to verify DNS and internal route injection. |

### Three Standard Triage Questions (Use on Any Ticket)
1. When did the issue start, and what changed just before it (update, migration, hardware, policy)?
2. Is the impact isolated (one user/device) or broad (multiple users/devices/sites)?
3. What is the exact error message/code and current workaround status?

### Severity Hint
- `High`: security risk, broad user impact, or core access blocked (BitLocker loop, AVD disconnects, VPN no internal access, room-wide Teams outage).
- `Medium`: user productivity degraded but partial work possible (shared mailbox, app install, slow system, OneDrive sync issues).
