# End-User Communication Pack (Same Facts, Three Audiences)

Date of incident: 2024-03-15
Affected area: AVD Finance pool POOL-FIN-01 only
Unaffected area: POOL-FIN-02
Resolution confirmed: 10:00 AM local

## Audience 1 - Non-Technical Executive
Your access and data are safe. On 15 March, between about 07:00 and 10:00, around 40% of Finance users in one virtual desktop pool (POOL-FIN-01) saw a black screen after sign-in. A second pool (POOL-FIN-02) was unaffected. The issue followed an overnight update, and service was restored by moving back to a known-good version. Action for you: no action needed.

## Audience 2 - Affected End-User Team (10 people, non-technical)
Your access and data are safe. On 15 March from about 07:00 to 10:00, some people in one Finance virtual desktop group (POOL-FIN-01) saw a black screen after sign-in because an overnight software update in that group caused the desktop to fail to load correctly; another group (POOL-FIN-02) was not affected. The fix was to move that group back to a known-good version, and service was confirmed at 10:00. If you see this again, sign out, reconnect once, then contact the Service Desk.

## Audience 3 - Engineer-to-Engineer Internal Note
Incident: 2024-03-15 AVD black screen post-login, Finance.

Scope/impact:
- Impact window: ~07:00 to 10:00 local.
- Blast radius: POOL-FIN-01 only; ~40% users affected.
- Control group: POOL-FIN-02 unaffected.

Root cause (confirmed):
- Graphics/display stack regression introduced by the 02:00 POOL-FIN-01 image update.
- Failure mode: DWM crash during post-login desktop init.
- Crash signature: Application Error Event 1000, dwm.exe faulting in igdumd64.dll, exception 0xc0000005.

Config/detail signals:
- Update applied overnight at 02:00 to POOL-FIN-01; POOL-FIN-02 not updated.
- Affected host evidence (SHFIN-01-A):
  - Event 21 logon success at 07:02:10.
  - Event 1000 at 07:02:16 and 07:02:46 (dwm.exe/igdumd64.dll).
  - Event 40 disconnect at 07:02:17 and 07:02:47.
  - Event 9009 DWM exit at 07:02:18 and 07:03:01.
  - Repeated pattern for multiple users (e.g., 07:08:24 Event 1000).
- Comparison host (SHFIN-02-A): Event 21 then Event 9011 (DWM started successfully), no Event 1000 in window.

Exact action taken:
- Paused further rollout of updated image branch.
- Drained/isolated affected POOL-FIN-01 capacity.
- Repointed/restored POOL-FIN-01 to known-good baseline/remediated image path.
- Rebooted/returned hosts in controlled batches.

Verification/closure:
- Resolution confirmed 10:00 local.
- Successful user logins to POOL-FIN-01 after remediation.
- No continued black-screen/disconnect pattern reported.

Preventive action required:
- Add canary gate with repeated AVD login/logoff cycles and DWM crash monitoring.
- Block image promotion on any dwm.exe Event 1000 in canary.
- Enforce phased rollout with auto-halt/rollback thresholds for disconnect or black-screen spikes.
- Keep/display-driver + AVD agent + OS patch compatibility checks in release checklist.
