# FinBridge Connect v3.1 Intune Phased Rollout Plan (10,000 Win11 Endpoints)
Date: 2026-08-11  
Deadline: 3 weeks (by 2026-09-01)

## 1. RING STRUCTURE

Ring 1 (Pilot)
- Size: 300 devices (3% of fleet).
- Duration: 4 calendar days.
- Include:
  - Endpoint Engineering and Service Desk test devices.
  - 2-3 business units (excluding the main Finance population unless using Option A in section 4).
  - Mix of hardware profiles including at least 30 devices from the 4GB RAM at-risk cohort.
- Purpose:
  - Validate install behavior, detection rule reliability (registry version detection), uninstall path, and user impact before scale.
  - Confirm no unexpected interaction with baseline security and Win11 configuration profiles.
- Intune assignment group type:
  - Required assignment to a static Microsoft Entra device security group: APP-FinBridge-v3.1-Ring1-Devices.

Ring 2 (Early)
- Size: 2,200 devices (22% of fleet).
- Duration: 6 calendar days.
- Include:
  - Early adopters, non-critical departments, and representative remote/hybrid users.
  - Include at-risk hardware in controlled proportion (up to 5% of ring population).
- Purpose:
  - Validate at medium scale, confirm support load is manageable, and catch issues that appear only under broader usage patterns.
- Intune assignment group type:
  - Required assignment to a dynamic Microsoft Entra device security group using ring tag attributes: APP-FinBridge-v3.1-Ring2-Devices.

Ring 3 (Broad)
- Size: 7,500 devices (75% of fleet).
- Duration: 11 calendar days (remaining time in the 3-week window).
- Include:
  - All remaining eligible Win11 endpoints not already deployed in earlier rings.
  - Exclude any active hold/isolation groups.
- Purpose:
  - Complete enterprise rollout while preserving controls for fast halt/isolation if thresholds are exceeded.
- Intune assignment group type:
  - Required assignment to dynamic Microsoft Entra device security group: APP-FinBridge-v3.1-Ring3-Devices.
  - Exclusion groups applied for held cohorts (example: APP-FinBridge-v3.1-Hold-Devices, APP-FinBridge-4GBRAM-Isolated).


## 2. ADVANCE CRITERIA

All criteria are evaluated from Intune Win32 app install status reports for FinBridge Connect v3.1 (Device install status, User install status, and error code breakdown), plus ticket counts from the service desk queue tagged FINBRIDGE-V31.

Ring 1 -> Ring 2 (all must pass)
- Install success rate: >= 97.0% of targeted Ring 1 devices within 48 hours of assignment.
- Error rate: <= 2.0% failed installs (Failed status / targeted devices) after one automatic retry cycle.
- User-reported issues: <= 1.5 tickets per 100 deployed users over the first 72 hours, with 0 Sev1 tickets.
- Monitoring period: minimum 72 continuous hours after >= 95% of Ring 1 devices report final install state.

Ring 2 -> Ring 3 (all must pass)
- Install success rate: >= 98.0% of targeted Ring 2 devices within 72 hours of assignment.
- Error rate: <= 1.5% failed installs after retry.
- User-reported issues: <= 1.0 ticket per 100 deployed users over a 96-hour observation window, with 0 Sev1 tickets.
- Monitoring period: minimum 96 continuous hours after >= 95% of Ring 2 devices report final install state.

Hold condition (pause without full rollback)
- Trigger: If failure rate is between 3.0% and 7.9% in the active ring for any continuous 12-hour period, pause advancement to the next ring but do not revert already successful devices.
- Action during hold:
  - Stop new assignments to next ring groups.
  - Keep current ring installed devices in place.
  - Open problem record and run focused remediation (for example, free disk space script and reattempt assignment).
- Specific example:
  - Ring 2 shows 4.2% failures in 12 hours with error 0x87D30067 concentrated on low-storage devices. Rollout is paused, remediation is pushed, then criteria are re-evaluated after 24 hours.


## 3. ROLLBACK TRIGGERS

Trigger 1: Install failure rate automatic halt
- Condition: >= 8.0% failed installs in any rolling 6-hour window within the currently active ring.
- Decision owner: Endpoint Engineering Incident Commander (IC) + Intune Service Owner.
- Decision window: 30 minutes from threshold breach alert.
- Exact Intune action:
  - Remove Required assignment of FinBridge v3.1 from the active ring group.
  - Add active ring group to FinBridge v3.1 Uninstall assignment (if uninstall command is validated in Ring 1).
  - Assign FinBridge v3.0 as Required to the same ring group immediately.

Trigger 2: Application crash rollback consideration
- Condition: >= 3.0% of deployed devices in active ring show repeated app crashes (>= 2 crashes/device within 24 hours) over a rolling 24-hour period.
- Decision owner: Endpoint Engineering IC + App Owner + Major Incident Manager.
- Decision window: 2 hours from confirmed breach.
- Exact Intune action:
  - Freeze next-ring assignments.
  - For affected cohort, execute same reassignment path to v3.0 (v3.1 uninstall + v3.0 required).
  - Keep unaffected cohort on hold pending root-cause decision.

Trigger 3: Business-critical failure immediate rollback
- Condition: Any verified production issue where Finance users cannot complete payment approval/sign-off transactions in FinBridge Connect due to v3.1 (Sev1 business outage), regardless of percentage impacted.
- Decision owner: Major Incident Manager (final authority) with Finance Service Owner approval.
- Decision window: Immediate, max 15 minutes after validation.
- Exact Intune action:
  - Global halt: remove Required assignments for v3.1 from all not-yet-installed ring groups.
  - Emergency rollback assignment: set v3.0 Required for Finance and currently active ring groups.
  - If required, assign v3.1 Uninstall to impacted groups.

Trigger 4: 4GB RAM at-risk group isolation
- Condition: >= 12.0% install failures or >= 5.0% post-install instability incidents in APP-FinBridge-4GBRAM-Devices over a rolling 24-hour window.
- Decision owner: Endpoint Engineering Lead.
- Decision window: 1 hour.
- Exact Intune action:
  - Move affected devices into APP-FinBridge-4GBRAM-Isolated.
  - Exclude APP-FinBridge-4GBRAM-Isolated from all v3.1 Required assignments.
  - Keep/assign v3.0 as Required for isolated group until remediation package or compatibility fix is approved.


## 4. FINANCE DEADLINE RESOLUTION

Option A - Compress pilot to place Finance in Ring 2 by end of week 1
- Minimum safe pilot duration: 3 full days (72 hours) with continuous monitoring.
- Benefit: Finance can begin on day 4-5 of week 1 through Ring 2.
- Risk introduced: Reduced time to detect slower-burn defects (for example, memory pressure after several business cycles).
- Compensating control:
  - Increase pilot observability cadence to every 2 hours.
  - Add a mandatory checkpoint at 48h and 72h requiring explicit IC sign-off.
  - Pre-stage rollback assignment objects before pilot starts.

Option B - Create a separate priority Ring 0 for Finance before the main pilot
- Ring 0 structure:
  - Size: 500 Finance users/devices total.
  - Phase 0a: 100 Finance champions on day 1-2.
  - Phase 0b: remaining 400 Finance devices on day 3-5 if 0a criteria pass.
- Ring 0 advance conditions (0a -> 0b):
  - >= 98% install success in 48h.
  - <= 1.5% failed installs.
  - <= 1.0 ticket per 100 users in first 48h.
  - 0 Sev1 business workflow failures.
- Ring 0 rollback plan:
  - If >= 5% failures in any 6-hour window, immediately halt 0b.
  - Remove v3.1 required assignment for Finance group; assign v3.0 required.
  - For installed affected users, apply v3.1 uninstall and force v3.0 reinstall.

Recommendation (single decision)
- Recommend Option B (Priority Ring 0 for Finance).
- Justification:
  - Meets the non-negotiable Finance end-of-week-1 deadline.
  - Preserves risk control for the wider 10,000-device deployment by avoiding compression of the general pilot learning cycle.
  - Provides a business-aligned rollback boundary: Finance can be protected quickly without forcing a full-fleet decision.
  - Keeps Ring 1/2/3 governance intact for the remaining 9,500 endpoints.

Execution timeline summary
- Week 1: Ring 0 Finance (500) + Ring 1 Pilot (300) in parallel with separate gates.
- Week 2: Ring 2 Early (2,200) after passing Ring 1 criteria.
- Week 3: Ring 3 Broad (7,500) with isolation/hold controls active until completion.
