# Root Cause Analysis (RCA)

## Incident
- Title: AVD black screen post-login on Finance pool
- Incident date: 2024-03-15
- RCA prepared: 2026-08-06
- Service: Azure Virtual Desktop (AVD)
- Affected pool: POOL-FIN-01
- Unaffected pool: POOL-FIN-02
- Resolution confirmed: 10:00 AM (same day)

## Executive Summary
Between about 07:00 and 10:00 on 2024-03-15, Finance users in POOL-FIN-01 experienced black screens after login, with some sessions recovering after about 30 seconds and others disconnecting/requiring reconnect. Impact was limited to about 40% of users in POOL-FIN-01. POOL-FIN-02 remained unaffected.

Evidence from affected session host SHFIN-01-A shows repeated Desktop Window Manager (dwm.exe) crashes in Intel graphics module igdumd64.dll (Application Error Event 1000), immediately followed by DWM exit events and session disconnects. Timeline and scope align with an overnight image update applied only to POOL-FIN-01.

The issue was resolved by applying the agreed remediation path (containment and rollback/remediation actions for the updated image branch), with service recovery verified at 10:00 AM and no further user reports.

## Impact Assessment
- User impact: approximately 40% of POOL-FIN-01 users.
- Symptom: black screen post-login; delayed desktop for some users; persistent black screen/disconnect for others.
- Business impact: delayed or blocked access to Finance workloads during peak morning login period.
- Blast radius: confined to POOL-FIN-01.

## Timeline (All times local, 2024-03-15)
- 02:00: Overnight image update deployed to POOL-FIN-01.
- 02:03:11: SHFIN-01-A booted post-update (Kernel-General Event 1 captured later at 07:02:14).
- ~07:00: First user reports begin.
- 07:02:10: SHFIN-01-A Event 21, successful logon for FINBRIDGE\\mlopez (Session 3).
- 07:02:16: SHFIN-01-A Event 1000, dwm.exe crash in igdumd64.dll (0xc0000005).
- 07:02:17: SHFIN-01-A Event 40, session disconnected.
- 07:02:18: SHFIN-01-A Event 9009, DWM exited (0x40010004).
- 07:02:44: SHFIN-01-A Event 21, reconnect logon succeeded.
- 07:02:46: SHFIN-01-A Event 1000, repeated dwm.exe/igdumd64.dll crash.
- 07:02:47: SHFIN-01-A Event 40, disconnected again.
- 07:03:01: SHFIN-01-A Event 9009, repeated DWM exit.
- 07:03:10: SHFIN-01-A Event 21, second reconnect succeeded.
- 07:08:22: SHFIN-01-A Event 21, logon for FINBRIDGE\\akapoor.
- 07:08:24: SHFIN-01-A Event 1000, same dwm.exe/igdumd64.dll crash pattern.
- 07:01:44 to 07:01:46 (comparison): SHFIN-02-A Event 21 then Event 9011 (DWM started successfully), no Event 1000 entries.
- 10:00: Resolution verified. Users logging in to POOL-FIN-01 successfully; no new issues reported.

## Supporting Evidence

### Affected Host: SHFIN-01-A (POOL-FIN-01)
- Event 21 at 07:02:10: successful logon indicates auth/session creation succeeds.
- Event 1000 at 07:02:16 and 07:02:46: dwm.exe faulting module igdumd64.dll, exception 0xc0000005.
- Event 9009 at 07:02:18 and 07:03:01: Desktop Window Manager exited.
- Event 40 at 07:02:17 and 07:02:47: user session disconnected immediately after DWM failure.
- Event 1 at 07:02:14 reports boot time 02:03:11, consistent with post-update restart.

### Comparison Host: SHFIN-02-A (POOL-FIN-02)
- Event 21 at 07:01:44: successful logon.
- Event 9011 at 07:01:46: DWM started successfully.
- No Application Error Event 1000 entries during incident window.

### Correlation and Scope Signals
- Pool-specific change: only POOL-FIN-01 received the overnight image update.
- Pool-specific impact: only POOL-FIN-01 reported black-screen symptoms.
- Failure signature consistency: repeated identical DWM crash module on affected host and users.

## Confirmed Root Cause
A graphics/display stack regression introduced in the updated POOL-FIN-01 image caused Desktop Window Manager (dwm.exe) to crash in Intel graphics module igdumd64.dll during post-login desktop initialization, leading to black screen, session instability, and disconnect behavior.

## Contributing Factors
- Update wave targeted only one pool, creating version skew between user pools.
- No pre-production gate detected DWM crash conditions under repeated AVD logon cycles before rollout.
- Morning login concurrency increased visibility/impact quickly.

## 5 Whys Analysis
1. Why did users see black screens after login?
Because the desktop compositor process (dwm.exe) failed during session initialization, preventing stable desktop rendering.

2. Why did dwm.exe fail?
Because dwm.exe repeatedly crashed in graphics module igdumd64.dll (Application Error Event 1000, exception 0xc0000005).

3. Why was that graphics module crashing in this pool?
Because POOL-FIN-01 was running the newly updated image branch that introduced a graphics/display stack regression.

4. Why was a regressive image promoted to production?
Because rollout checks did not include a canary gate specifically validating DWM stability and black-screen behavior across repeated AVD login cycles.

5. Why were those checks missing?
Because the image release process focused on baseline host health and functional startup but lacked explicit display-pipeline crash criteria and automated rollback thresholds for session UX failures.

## Resolution Actions Executed
- Paused further rollout of the updated image branch.
- Drained or isolated affected POOL-FIN-01 capacity to reduce user exposure.
- Restored POOL-FIN-01 to a known-good baseline/remediated image path.
- Validated post-change login behavior and stability before full return.
- Confirmed recovery at 10:00 AM with successful user logins and no new incident reports.

## Validation and Closure Evidence
- No new user-reported black-screen incidents after remediation window.
- Verified logins to POOL-FIN-01 hosts successful.
- No ongoing disconnect pattern reported by Service Desk after 10:00 AM.

## Preventive and Corrective Actions (CAPA)

### Immediate Hardening (0-7 days)
- Add mandatory canary test: 20+ repeated AVD logon/logoff cycles with DWM crash monitoring.
- Block image promotion if any Application Error Event 1000 for dwm.exe is detected in canary.
- Add release checklist item for display-driver/AVD-agent/OS patch compatibility matrix.

### Near-Term Process Improvements (1-4 weeks)
- Implement phased rollout policy: pilot subset, then staged expansion with health gates.
- Add auto-halt thresholds based on session disconnect spike and black-screen ticket rate.
- Publish runbook for rapid rollback to previous known-good image per pool.

### Monitoring and Alerting (1-4 weeks)
- Add alerts for:
  - Application Error Event 1000 where faulting app = dwm.exe.
  - Desktop Window Manager Event 9009 surge on session hosts.
  - Correlated Event 21 -> Event 1000 -> Event 40 sequence within 2 minutes.
- Add pool-level dashboard for login success rate, median time-to-desktop, disconnect rate.

### Governance and Change Control (ongoing)
- Require explicit sign-off on user experience criteria (time-to-desktop, no black-screen) before production wave approval.
- Record version-to-pool mapping for immediate blast-radius analysis during incidents.

## Residual Risk
- If similar driver regressions are introduced in future image waves, symptoms can recur without strict pre-production display-path testing and rollout guardrails.

## Lessons Learned
- In AVD incidents, successful logon (Event 21) does not imply desktop readiness; DWM and graphics pipeline events must be part of first-line triage.
- A clean comparison pool on previous image version is high-value evidence for rapid cause narrowing.

## Appendix A: Event References Used in RCA
- SHFIN-01-A Event 21 at 07:02:10, 07:02:44, 07:03:10, 07:08:22.
- SHFIN-01-A Event 1 at 07:02:14 (boot time 02:03:11).
- SHFIN-01-A Event 1000 at 07:02:16, 07:02:46, 07:08:24.
- SHFIN-01-A Event 40 at 07:02:17, 07:02:47.
- SHFIN-01-A Event 9009 at 07:02:18, 07:03:01.
- SHFIN-02-A Event 21 at 07:01:44.
- SHFIN-02-A Event 9011 at 07:01:46.
