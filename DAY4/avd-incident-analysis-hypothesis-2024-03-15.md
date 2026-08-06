# AVD Incident Analysis and Hypothesis

Date of analysis: 2026-08-06
Incident date: 2024-03-15
Context: FinBridge Service Desk black screen incident

## Scope Facts Used
- Symptom: black screen post-login; clears after about 30 seconds for some users, persists for others.
- Who: about 40% of users on POOL-FIN-01. POOL-FIN-02 is completely unaffected.
- Since: about 07:00 this morning.
- Change: overnight image update to POOL-FIN-01 at 02:00. POOL-FIN-02 was not updated.

## Ranked Hypotheses (Most Probable First)

### 1) New image regression in logon shell path (startup apps, Run keys, shell init order)
Why this fits scope facts:
- Strongest timing match: issue starts the same morning after the 02:00 update.
- Strongest scope match: only POOL-FIN-01 (updated) is affected; POOL-FIN-02 (not updated) is clean.
- Symptom fit: black screen after auth with eventual recovery in some sessions is consistent with delayed shell start.
Single fastest check:
- Log on to one affected host and one unaffected host with the same test account, then compare shell start latency and event sequence (Winlogon/User Profile Service/Explorer start) to confirm delay only on updated hosts.

### 2) FSLogix/profile container attach delay or failure introduced by updated image components
Why this fits scope facts:
- Partial impact (about 40%) aligns with user/profile-specific behavior.
- Mixed symptom (clears for some, persists for others) matches slow attach versus failed attach paths.
- Could be triggered by new image agent/driver/service ordering even if storage backend did not change.
Single fastest check:
- On an affected host, check FSLogix operational logs for an impacted user at logon time and measure container attach duration/failure codes; compare with a successful session.

### 3) Graphics/display stack issue from image update (GPU driver, RDP graphics policy, hardware acceleration)
Why this fits scope facts:
- Black screen post-login is a known manifestation of display pipeline issues in AVD.
- Pool-specific impact is consistent with a pool-specific image driver or policy change.
- Not all users being affected can occur when hosts have mixed runtime states or session conditions.
Single fastest check:
- On one affected host, force a basic render path (disable advanced graphics acceleration path for test) and verify whether new logons stop black-screening.

### 4) AVD agent/bootloader/version mismatch after image update (subset of hosts unhealthy)
Why this fits scope facts:
- Update wave can leave some hosts with inconsistent agent states, producing host-level partial impact.
- Explains why some users repeatedly hit the issue (landing on the same bad hosts) while others do not.
- Unaffected comparison pool supports a change-scoped host software issue.
Single fastest check:
- List host health and agent versions across POOL-FIN-01, then correlate incidents to specific hosts/versions; clustering indicates this cause.

### 5) New security/EDR/logon policy in updated image causing post-auth contention
Why this fits scope facts:
- Time-of-change alignment is plausible if policy/module arrived in the image update.
- Black screen that later clears can result from synchronous startup checks or blocked shell handoff.
- Partial user impact can occur if policy targets certain groups or process conditions.
Single fastest check:
- Temporarily exclude one affected test host or test user from the new startup security/script component and retest first logon; if symptom disappears, this path is strongly implicated.

## Weighting Rationale (Timing Clue Applied)
- Highest weight is assigned to causes directly introduced by the 02:00 image update and isolated to POOL-FIN-01.
- Ranking therefore prioritizes image-regression classes first (shell path, profile attach dependency, graphics stack), then host consistency and policy side effects.
- No single root cause is declared yet; quick checks above should be run before committing to one cause.

## Event Evidence Review (Incident Window 07:00-07:30)

### Source Hosts Reviewed
- Affected: SHFIN-01-A (POOL-FIN-01)
- Unaffected comparison: SHFIN-02-A (POOL-FIN-02)

### Key Event Details from Affected Host (SHFIN-01-A)
- 07:02:10 TerminalServices-LocalSessionManager Event 21: session logon succeeded for FINBRIDGE\mlopez.
- 07:02:14 Kernel-General Event 1: host boot time recorded as 02:03:11 (post-update restart).
- 07:02:16 Application Error Event 1000: dwm.exe crashed in igdumd64.dll (exception 0xc0000005).
- 07:02:17 TerminalServices-LocalSessionManager Event 40: session disconnected.
- 07:02:18 Desktop Window Manager Event 9009: DWM exited with code 0x40010004.
- 07:02:44 Event 21: reconnect logon succeeded.
- 07:02:46 Event 1000: repeated dwm.exe crash in igdumd64.dll.
- 07:02:47 Event 40: session disconnected again.
- 07:03:01 Event 9009: repeated DWM exit.
- 07:03:10 Event 21: second reconnect succeeded.
- 07:08:24 Event 1000: same dwm.exe/igdumd64.dll crash for FINBRIDGE\akapoor.

### Key Event Details from Unaffected Host (SHFIN-02-A)
- 07:01:44 TerminalServices-LocalSessionManager Event 21: session logon succeeded.
- 07:01:46 Desktop Window Manager Event 9011: DWM started successfully.
- No Application Error Event 1000 entries in the comparison window.

## Hypothesis Elimination Outcome

### Surviving Hypothesis
Graphics/display stack regression introduced by the POOL-FIN-01 image update, with DWM crashing in Intel graphics module igdumd64.dll during post-login desktop initialization.

### Why This Survived
- Direct crash signature: Application Error Event 1000 repeatedly identifies dwm.exe faulting in igdumd64.dll.
- Symptom alignment: DWM exits (Event 9009) immediately after successful logon (Event 21), matching black screen/disconnect behavior.
- Scope alignment: pattern appears on updated POOL-FIN-01 host and not on unaffected POOL-FIN-02 comparison host.

## Detailed Resolution Steps

### 1) Immediate Containment
1. Pause any further rollout of the updated image to other pools.
2. Drain affected POOL-FIN-01 session hosts to prevent new user impact.
3. Prioritize business-critical users to known-good host capacity.

### 2) Rapid Service Restoration
1. Repoint POOL-FIN-01 to the previous known-good image (aligned with POOL-FIN-02 baseline where applicable).
2. Reimage/replace affected hosts from the known-good image.
3. Reboot restored hosts and return them to service in controlled batches.

### 3) Targeted Technical Remediation (Image Branch)
1. In a test branch of the updated image, remove or replace the Intel graphics driver version implicated by igdumd64.dll crashes.
2. Validate compatibility across graphics driver, AVD agent, and OS patch level.
3. If an immediate driver fix is not available, apply a temporary policy forcing software/basic render path for AVD sessions.

### 4) Verification Criteria Before Closure
1. Confirm no new Application Error Event 1000 entries for dwm.exe/igdumd64.dll on remediated hosts.
2. Confirm DWM successful startup events after logon and no repeated DWM exits.
3. Track incident/ticket volume and validate black-screen rate returns to baseline.

### 5) Recurrence Prevention
1. Add pre-production AVD canary tests for repeated logon cycles and DWM crash detection.
2. Add rollout gates that halt promotion on any dwm.exe Application Error Event 1000 in canary.
3. Enforce phased deployment with automatic rollback triggers based on session failure thresholds.
