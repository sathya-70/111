# Floor 6 Finbridge Incident Analysis

Date: 2026-08-14  
Prepared for: IT Ops Lead / Partner Update

## 1. Incident Separation (Untangled)

Based on the statement provided, this is not one incident. It is three distinct incidents:

1. Incident A (Critical): Possible unauthorized client matter exposure in Copilot/search.
2. Incident B (High): Floor-wide login failures and severe login slowness.
3. Incident C (Medium): Missing desktop shortcuts/workspace items.

## 2. Incidents In Order Of Urgency

1. Incident A - Critical (confidentiality and regulatory risk).
2. Incident B - High (broad business productivity impact).
3. Incident C - Medium (localized productivity/usability impact).

## 3. State Of Incidents

- Incident A: Active, high-risk, containment required immediately.
- Incident B: Active, broad operational impact, mitigation required now.
- Incident C: Active, user-impacting, lower immediate risk than A and B.

## 4. Incident Details

## Incident A: Possible Unauthorized Client Matter Exposure

### Root cause (current best hypothesis)

- Most likely permissions-boundary issue introduced during Friday document management rollout, or post-migration indexing/sync mismatch between repository permissions and Copilot/search retrieval scope.
- Alternative possibility: stale identity token/cache causing retrieval against outdated access graph.

### Devices affected

- Potentially all Floor 6 users on the new document management app and Copilot-enabled search, not just the reporting paralegal, until disproven.

### Summary of what might have happened

- A user asked Copilot/search and saw a client matter they believe they never had access to.
- This indicates either true over-permissioning or an authorization/indexing defect.
- Treat as a confidentiality incident until validated otherwise.

### First-base troubleshooting to perform

1. Contain immediately: temporarily disable Copilot retrieval for affected repository scope, or restrict Floor 6 data connectors.
2. Validate document permissions: ACL, inheritance, direct grants, group membership changes since Friday.
3. Compare app connector permissions vs source repository ACLs for the exposed matter.
4. Force re-auth/token refresh for affected users and retest with controlled accounts.
5. Run access audit for all retrieval/view events on the exposed matter since rollout.

### Log report to generate

Security and entitlement report (last 72 hours):

1. User identity, device, timestamp, query category, returned document ID, authorization decision.
2. Permission-change audit: who changed ACLs, when, before/after values.
3. Copilot retrieval traces: request IDs, connector, entitlement-check result.
4. Exception events where retrieval succeeded but source ACL check failed or was bypassed.

---

## Incident B: Login Failures and Severe Slowness (12/45+ users)

### Root cause (current best hypothesis)

- Change collision between Win11 migration, Intune enrollment/policy application, and Friday app deployment.
- Likely drivers: heavy first-logon provisioning, conditional access/compliance delays, identity token issues, or profile/container load latency.

### Devices affected

- At least 12 of 45 Floor 6 endpoints, likely concentrated in recent migration/enrollment cohorts.

### Summary of what might have happened

- During Monday peak login, endpoints were completing first-run Win11 + Intune + app tasks simultaneously.
- This likely increased authentication and profile initialization time, creating login delays and some failures.

### First-base troubleshooting to perform

1. Find common denominator: affected users by device model, migration batch, enrollment date, and app assignment ring.
2. Pause non-critical policy/app assignments to Floor 6 temporarily.
3. Reboot affected endpoints in waves and force policy sync.
4. Validate sign-in path: identity logs, conditional access outcomes, compliance checks.
5. Check endpoint health factors: disk space, startup programs, profile load time, network path to identity endpoints.

### Log report to generate

Login and provisioning correlation report (today 06:00-now):

1. Sign-in attempt result, failure reason code, time-to-desktop.
2. Intune policy/app install timeline per device in logon window.
3. Conditional access outcomes by user/device (success/challenge/block).
4. Profile load and shell initialization events.
5. Per-device timeline joining auth, policy, app install, and desktop readiness.

---

## Incident C: Missing Desktop Shortcuts

### Root cause (current best hypothesis)

- Shortcut deployment/removal script conflict during Win11 migration or Intune packaging.
- Secondary possibility: profile re-creation/temporary profile after failed or delayed login.

### Devices affected

- Confirmed on at least one endpoint; potentially more in same deployment ring.

### Summary of what might have happened

- Shortcut paths changed (Public Desktop vs user Desktop), installer replaced icons, or profile initialization reset visible desktop items.

### First-base troubleshooting to perform

1. Confirm if missing for user profile only or all users/Public Desktop.
2. Review app installer and remediation scripts for shortcut create/remove actions.
3. Check profile path consistency and temporary-profile indicators.
4. Re-publish standard shortcut baseline through Intune remediation for affected devices.

### Log report to generate

Desktop/profile integrity report:

1. Shortcut inventory by path and timestamp (before/after login).
2. Profile load events and temporary-profile indicators.
3. App install/uninstall actions touching .lnk files.
4. Remediation results and restore success percentage.

## 5. Immediate Actions (Now to 2 Hours)

1. Declare major incident with two parallel workstreams: Security containment (Incident A) and service restoration (Incidents B/C).
2. Contain Incident A first: restrict Copilot/retrieval scope for affected repository/floor until entitlement checks pass.
3. Freeze additional Floor 6 rollout changes during stabilization.
4. Run focused triage cohort (3-5 affected devices) and compare to unaffected controls.
5. Issue user advisory with expected update times.
6. Provide leadership updates every 30 minutes until stable.

## 6. Partner/Leadership Lunch Update (Non-Technical)

We have identified three separate issues on Floor 6 this morning.

First, one report indicates a potential document access-boundary issue in AI-assisted search. We are treating this as a priority confidentiality event and have moved to containment while we verify permissions and access logs.

Second, a broader login slowdown/failure issue is affecting a subset of users and appears linked to overlapping system changes from the recent Windows 11 and Intune migration plus Friday's app rollout.

Third, some users have missing desktop shortcuts due to profile/deployment side effects.

At this point, there is no evidence of data loss. We are prioritizing confidentiality protection first, then full user access restoration, with timed status updates to leadership.
