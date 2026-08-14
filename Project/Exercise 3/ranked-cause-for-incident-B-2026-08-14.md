# Ranked Cause Analysis - Incident B (Login Failures and Slowness)

Date: 2026-08-14  
Incident: Floor 6 login failures and severe login slowness  
Requested focus: Friday afternoon new app deployment versus other concurrent changes

## Current State

Incident B is active and in mitigation. Current confidence is that this is a change-collision event, with Friday app deployment as a major candidate cause that must be proven or disproven quickly.

## 1) Ranked Causes With Reasoning

1. New app deployment created login-time contention or shell delay (Most likely)
Reason:
- Strong temporal correlation: app deployed Friday, floor-wide symptoms appear Monday morning peak.
- Typical pattern: first business-day login after deployment triggers install, repair, indexing, or post-install tasks.
- Scope fit: issue concentrated on the same floor/assignment cohort receiving the app.

2. Intune policy/app assignment overlap after Win11 migration (High likelihood)
Reason:
- Win11 migrated devices often receive multiple policies and baseline changes at first or early logins.
- Concurrent app assignment plus compliance evaluation can create long sign-in and shell startup delay.
- Could explain both slow and failed logins if timeout thresholds are exceeded.

3. Conditional Access and compliance latency or mismatched state (Moderate likelihood)
Reason:
- If compliance posture is still converging, sign-in flow may loop/challenge/block inconsistently.
- Produces mixed behavior across users in same area, especially after enrollment changes.

4. User profile/container initialization delays or corruption (Moderate likelihood)
Reason:
- Slow profile load can produce very long time-to-desktop and apparent login failures.
- Can occur after OS migration and policy churn.

5. Endpoint resource bottleneck unrelated to app package (Lower likelihood)
Reason:
- Disk pressure, startup bloat, or heavy AV scan can slow login.
- Possible contributor, but weaker explanation for synchronized onset across a single floor after a known change.

## 2) Ranked Fastest Checks To Perform

1. Cohort split check by deployment status (10 to 20 minutes)
- Compare impacted versus non-impacted users by exact app assignment and install state.
- If impact clusters with assigned or installing devices, deployment causality strengthens immediately.

2. Timeline correlation check (15 to 30 minutes)
- Build per-device timeline: sign-in start, app install start, install completion, desktop ready time.
- If delay window overlaps app install or app post-install actions, this is strong evidence.

3. Temporary assignment pause test (30 to 60 minutes)
- Pause non-critical app and policy assignments for a pilot subset.
- If new logins normalize in the paused subset while control group stays degraded, causality is likely deployment-driven.

4. Known-good control device retest (15 to 30 minutes)
- Use a similar Floor 6 device with app not yet installed or app removed in controlled test.
- Faster login on control path supports deployment impact.

5. Auth and CA result sanity check (10 to 20 minutes)
- Confirm whether failures are auth-block codes or post-auth provisioning delays.
- If auth succeeds but desktop readiness is delayed, deployment/provisioning is more likely than identity policy block.

## 3) Evidence Matrix: Confirm or Rule Out Friday Deployment

## Evidence that confirms deployment as the cause

1. Statistical correlation
- Significantly higher login duration or failure rate only in devices with the new app assigned or installing.

2. Temporal correlation
- Login degradation begins after deployment and spikes at first business login cycle.

3. Process evidence
- App installer, self-heal, indexing, or post-install script runs during login delay window.

4. A/B behavior
- Paused-assignment pilot improves; unchanged control cohort does not.

5. Reproducibility
- Installing the app on a test endpoint reproduces slowdown; removing or deferring install restores normal login.

## Evidence that rules out deployment as the cause

1. No cohort separation
- Impact is equal in devices with and without the app assignment.

2. No timeline overlap
- Login delay occurs before any app install or app process execution.

3. Identity-rooted failures
- Failures map to clear CA/MFA/compliance-deny codes independent of app state.

4. No change effect from pause
- Assignment freeze produces no improvement in new logins.

5. Alternative dominant fault
- Clear profile corruption, DNS/time sync, or identity endpoint outage explains all affected and unaffected patterns better than deployment.

## 4) Practical Triage Pack To Collect Immediately

1. Device-by-device correlation sheet
- Device name, user, app assigned Y/N, app installed Y/N, install timestamp, login duration, failure code.

2. Sign-in evidence
- Entra sign-in result, CA decision, compliance decision, MFA path.

3. Intune evidence
- Management extension health, app install queue, install retry count, script execution duration.

4. Endpoint performance evidence
- Profile load events, shell start time, CPU and disk utilization during login window.

5. Change evidence
- Exact deployment ring membership, assignment time, and revision hash of app package.

## 5) Causality State (What We Can Say Now)

- Current causality state: Suspected-primary, not yet proven.
- Confidence level: Medium-high pending cohort and pause-test results.
- Decision rule:
  - If 3 or more confirmatory evidence categories are met, classify Friday deployment as probable root cause.
  - If 3 or more rule-out categories are met, classify deployment as non-primary and pivot to identity/profile root cause.

## 6) Recommended Immediate Decision Sequence

1. Run cohort split and timeline correlation first.
2. Start temporary assignment pause pilot.
3. Produce 60-minute update with preliminary causality classification.
4. If probable deployment root cause, keep freeze and move to staged rollback or install deferral.
5. If ruled out, shift response priority to CA/compliance and profile recovery pathways.
