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
