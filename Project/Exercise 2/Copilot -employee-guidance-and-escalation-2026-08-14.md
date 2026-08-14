# Incident A Employee Guidance and Escalation

Date: 2026-08-14  
Audience: All Floor 6 employees, people managers, service desk, incident coordinators  
Related incident: Possible unauthorized client matter exposure via Copilot/search

## What Exactly Happened

Based on current triage evidence, one employee reported that Copilot/search returned a client matter they believe they were never authorized to access.

This likely happened because one of the following control points failed after recent changes (new document management rollout, Win11 migration, Intune enrollment):

1. Permissions mismatch:
   - The document repository permissions and the Copilot connector entitlement checks may not have aligned.
2. Inheritance/group mapping issue:
   - A folder/library or group mapping may have widened access unexpectedly.
3. Token or index staleness:
   - Cached identity or indexing data may have used an outdated authorization state.

Important clarification:
- This is being treated as a confidentiality-risk incident until full audit confirms whether unauthorized access truly occurred.
- At this stage, no broad data-loss event is confirmed.

## Why This Matters

- Client confidentiality could be impacted if unauthorized visibility is confirmed.
- Legal, regulatory, and reputational risk increases if users continue to open, copy, or share content they should not see.
- Immediate behavior by employees is critical to reduce risk.

## What Employees Must Never Do

If content appears in Copilot/search that seems unrelated to your work or you suspect you should not see it, never do the following:

1. Never open additional related files out of curiosity.
2. Never download, copy, screenshot, photograph, print, or forward the content.
3. Never paste excerpts into chat, email, tickets, or external tools.
4. Never share document names, client identifiers, or links in public channels.
5. Never attempt to test access across other client matters.
6. Never delete evidence (do not clear history, logs, or browser/app data).
7. Never continue repeated prompts to retrieve similar restricted content.

## What Employees Should Do Immediately

1. Stop interacting with the returned content immediately.
2. Record minimal evidence only:
   - time observed
   - device name
   - app used
   - document title or ID if visible
3. Close the content view without further interaction.
4. Report immediately using the escalation path below.
5. Follow Service Desk instructions for sign-out/token refresh if requested.

## Mandatory Escalation If Someone Already Performed A Risky Action

If an employee has already opened, copied, shared, or downloaded potentially unauthorized content, escalate as a Priority 1 confidentiality event immediately.

### Escalation path (in order)

1. Service Desk P1 ticket:
   - Category: Security and Data Access
   - Severity: Critical
   - Tag: Possible unauthorized client matter visibility
2. Notify Incident Manager and DWP Engineering lead immediately.
3. Notify Information Security and Legal/Compliance duty contact.
4. Notify business owner/partner representative for affected practice area.

### Information required in escalation

Include only operational facts (do not circulate sensitive content broadly):

1. Reporter name and contact.
2. Timestamp and timezone.
3. Device name and user account.
4. Application and query context (high-level only).
5. Whether content was viewed only, or copied/shared/downloaded.
6. Who received shared material (if any).
7. Whether screenshots/prints were taken.

### Immediate containment steps after escalation

1. Revoke active sessions and force re-auth for affected account(s).
2. Temporarily restrict Copilot connector/retrieval scope for affected repository or cohort.
3. Preserve logs and audit trails (no cleanup actions).
4. Start chain-of-custody documentation for investigation records.

## Manager Script For Team Communication

Use this exact message if needed:

A potential access-control issue is under investigation. If you see content in Copilot/search that appears outside your normal client scope, stop immediately and do not open, copy, share, or capture it. Report it to the Service Desk as Priority 1 and inform your manager. This is a confidentiality-protection measure while investigation is in progress.

## DWP Engineer Actions To Run In Parallel

1. Validate source ACL vs connector entitlement decision for reported document.
2. Pull 72-hour retrieval and permission-change audit set.
3. Confirm whether exposure is isolated or systemic across Floor 6.
4. Provide first verified update to leadership within 60 to 90 minutes.
5. Issue follow-up communication with confirmed do and do-not guidance.

## Closure Conditions For This Employee Advisory

This advisory remains active until all are complete:

1. Entitlement mismatch root cause confirmed and fixed.
2. No new unauthorized retrieval events observed in monitoring window.
3. Legal/Compliance confirms incident handling obligations are met.
4. Leadership approves return to normal retrieval scope.
