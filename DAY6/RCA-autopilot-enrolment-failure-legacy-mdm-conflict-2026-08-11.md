# Root Cause Analysis (RCA)

Title: Autopilot Enrolment Failure - Legacy MDM Enrolment Conflict  
Date: 2026-08-11  
Prepared by: DWP Analyst

## 1. Executive Summary

A Windows device failed Autopilot enrolment because it already had an existing legacy manual MDM enrolment record from 2023-11-04. The failure is evidenced by enrolment state `Failed`, error code `0x80180014`, and error text stating the device is already enrolled in MDM. Secondary profile-stage failure `0x80070005 (Access denied)` is consistent with the blocked/invalid management context during the failed enrolment flow.

## 2. Incident Statement

Autopilot enrolment could not complete for the target device during provisioning. This prevented policy/profile delivery (`0 of 4` applied) and delayed endpoint readiness.

## 3. Scope and Impact

- Affected scope: Confirmed single device in this analysis dataset.
- Business impact: Device provisioning blocked; endpoint not fully managed by intended Autopilot/Intune flow.
- Security/compliance impact: Compliance and configuration baseline not fully applied at the time of failure.
- Customer/user impact: Delayed readiness for productive use.

## 4. Supporting Evidence (From Collected Export)

| Evidence item | Value | Interpretation |
|---|---|---|
| EnrollmentState | Failed | Enrolment did not complete |
| ErrorCode | 0x80180014 | Primary enrolment failure code |
| ErrorDescription | The device is already enrolled in MDM. | Direct indicator of conflicting existing enrolment |
| MDMEnrolled | Yes (previous enrolment from 2023-11-04) | Confirms prior registration exists |
| EnrolmentSource | Legacy manual MDM enrolment | Conflicting management origin predates Autopilot attempt |
| ProfilesApplied | 0 of 4 | No assigned profiles were successfully applied |
| LastError | 0x80070005 (Access denied) | Policy/profile stage encountered access failure |
| AzureADJoined | Yes | Identity join present; failure not due to missing Azure AD join |
| IntuneP1License | Yes | Required licence present |
| AutopilotLicense | Yes | Required Autopilot licence present |
| Network | All endpoints reachable, no proxy | No network/proxy blocker identified |

## 5. Timeline of Events

Note: Only facts evidenced by provided data are time-stamped/anchored below. Unknown exact event timestamps are marked explicitly.

1. 2023-11-04 - Device recorded as already MDM-enrolled via legacy manual enrolment source.
2. Unknown (current incident window) - Autopilot enrolment initiated for device.
3. Unknown (same incident window) - Enrolment failed with `0x80180014` and description indicating pre-existing MDM enrolment conflict.
4. Unknown (post enrolment failure during profile stage) - `ProfilesApplied` remained `0 of 4`; `LastError` captured as `0x80070005 (Access denied)`.
5. 2026-08-11 - Evidence review completed and root cause confirmed as legacy MDM conflict.

## 6. Technical Analysis

### 6.1 What failed

- The Autopilot-managed enrolment transaction failed before successful policy establishment.
- Configuration/compliance profile delivery did not progress beyond initial state.

### 6.2 What did not fail

- Azure AD join state was present (`AzureADJoined: Yes`).
- Licensing prerequisites were present (`IntuneP1License: Yes`, `AutopilotLicense: Yes`).
- Network path prerequisites were healthy (all endpoints reachable, no proxy).

### 6.3 Root Cause

Confirmed root cause: A stale/existing legacy manual MDM enrolment record conflicted with Autopilot enrolment, causing enrolment failure (`0x80180014`) and preventing profile application.

## 7. 5-Why Analysis

1. Why did Autopilot enrolment fail?  
Because the enrolment process encountered a blocking condition and returned `0x80180014` with text indicating the device was already enrolled in MDM.

2. Why was the device considered already enrolled?  
Because an existing MDM enrolment record from 2023-11-04 was still present from a legacy manual enrolment path.

3. Why did the existing legacy enrolment remain active/conflicting?  
Because prior management state was not fully cleaned up before re-provisioning via Autopilot.

4. Why was cleanup not completed before Autopilot handoff?  
Because there was no enforced pre-provisioning gate/checklist step to detect and remediate legacy MDM registrations.

5. Why was there no enforced gate/checklist?  
Because the Autopilot intake process lacked a standard control requiring legacy enrolment hygiene validation across Intune/Entra/device state before deployment.

Process root cause: Missing pre-Autopilot legacy enrolment hygiene control.

## 8. Corrective Actions Completed / Required

### 8.1 Immediate corrective actions (required for affected device)

- Remove stale managed device object in Intune for the conflicting legacy enrolment.
- Remove stale/duplicate Entra device object if duplicate identity is present.
- Remove legacy work/school MDM connection on endpoint.
- If required, remove residual EnterpriseMgmt tasks and obsolete MDM certificates tied to old enrolment.
- Reboot and re-run Autopilot provisioning.

### 8.2 Verification actions after remediation

- Confirm enrolment state is successful in Intune.
- Confirm assigned profiles apply (no longer `0 of 4`).
- Confirm no recurrence of `0x80180014`.
- Confirm no blocking `0x80070005` during policy application.

## 9. Preventive Actions

### 9.1 Preventive control (mandatory)

Implement a pre-Autopilot enrolment hygiene gate for any repurposed or previously managed device.

Control must require all of the following before Autopilot deployment:
- Intune check: No stale managed device object for target identity.
- Entra check: No conflicting duplicate device object.
- Device check: No legacy work/school MDM connection.
- Readiness evidence attached to ticket/change record.

### 9.2 Process updates

- Update provisioning SOP to include legacy enrolment cleanup as a hard prerequisite.
- Add CAB/change template fields for hygiene evidence and reviewer sign-off.
- Add deployment-wave preflight report for known conflict indicators (already-enrolled signatures).

### 9.3 Monitoring and governance

- Weekly review of enrolment failures for conflict indicators.
- Trend metric: percentage of Autopilot failures caused by existing enrolment conflicts.
- Triggered review if conflict-driven failures exceed agreed threshold.

## 10. Residual Risk and Assumptions

- Residual risk: If cleanup is partial (admin objects cleaned but device artifacts retained, or vice versa), conflict can recur.
- Assumption: Dataset provided is complete for the analysed incident; no contradictory telemetry was supplied.

## 11. Final Conclusion

The incident was caused by a legacy manual MDM enrolment that remained associated with the device and conflicted with Autopilot enrolment. Identity join, licensing, and network prerequisites were healthy, narrowing failure causality to enrolment-state conflict. A mandatory pre-Autopilot legacy-enrolment hygiene gate is required to prevent recurrence.
