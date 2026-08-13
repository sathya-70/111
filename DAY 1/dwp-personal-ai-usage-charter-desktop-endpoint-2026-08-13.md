# DWP Personal AI Usage Charter (Desktop/Endpoint Engineer)

## Purpose
Use public AI assistants to speed up safe engineering work while protecting DWP data, users, and services. Treat all public AI tools as external systems.

## 1) Appropriate Tasks for Public AI Help
Use public AI for low-risk, sanitized, technical drafting and problem-solving such as:

- Drafting and refactoring PowerShell, batch, and Python scripts using placeholder values only.
- Building troubleshooting checklists for endpoint issues (logon delays, profile issues, printer mapping, software install failures, VPN client errors).
- Creating runbook templates, rollback plans, pre/post-check lists, and change communication drafts.
- Explaining Windows desktop concepts (services, event logs, Intune policy behavior, GPO interactions, Autopilot flow, Defender basics).
- Producing test plans for desktop changes (pilot scope, success criteria, fallback checks).
- Reviewing script quality for idempotency, error handling, logging, and safe execution flags (for example: WhatIf/Confirm where relevant).

## 2) Not Appropriate Tasks for Public AI
Do not use public AI for any data or task that could expose users, credentials, or internal security posture, including:

- End-user PII, HR/health/benefit details, case notes, support transcripts, or ticket exports.
- Credentials, secrets, tokens, private keys, certificates with private material, or password reset artifacts.
- Internal architecture details that increase attack surface (exact hostnames, trust boundaries, security exceptions, detection gaps).
- Live incident response details, active threat telemetry, or forensic artifacts.
- Raw production logs/config dumps that contain identities, device names, IPs, tenant IDs, or internal paths.
- Any OFFICIAL-SENSITIVE content unless explicitly approved for external sharing.

## 3) Data-Handling Rule (PII and Credentials)
Before using public AI, sanitize first and minimize always:

- Replace names, usernames, emails, phone numbers, IDs, device names, hostnames, domains, IPs, tenant IDs, ticket references, and file paths with placeholders.
- Replace every secret with <REDACTED_SECRET>.
- Share only the minimum technical context required for help.
- Never paste authentication material, recovery codes, or privileged command output.
- If uncertain whether data is safe, do not submit it.

## 4) Personal "Generate Then Verify" Rule (Scripts and System Changes)
AI output is a draft, never a direct production action.

- Verify intent line-by-line before execution.
- Confirm prerequisites, dependencies, and side effects.
- Add robust error handling, logging, and safe/preview modes where possible.
- Test in lab or non-production first, then pilot with a small endpoint group.
- Validate against trusted Microsoft and DWP guidance before rollout.
- Keep a rollback plan and success/failure criteria before any wider deployment.
- Engineer accountability remains with me, not the AI tool.

## Personal Commitment Statement
I will use public AI to improve speed and clarity, not to bypass security, privacy, or change control. I remain responsible for safeguarding user data and for validating all technical outputs before use.
