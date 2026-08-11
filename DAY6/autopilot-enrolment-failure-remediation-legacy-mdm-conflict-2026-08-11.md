# Autopilot Enrolment Failure Analysis and Remediation (Legacy MDM Conflict)

Date: 2026-08-11  
Analyst context: DWP endpoint operations  
Incident type: Windows Autopilot enrolment failure

## 1) Scope Facts Confirmed

- Enrolment state: Failed
- Primary enrolment error: 0x80180014
- Error text in export: The device is already enrolled in MDM
- Existing enrolment present: Yes (legacy manual MDM enrolment dated 2023-11-04)
- Azure AD joined: Yes
- Policy application: Failed/incomplete (0 of 4 profiles applied)
- Secondary error observed: 0x80070005 (Access denied)
- Licensing: Intune P1 = Yes, Autopilot license = Yes
- Network: Healthy (all endpoints reachable, no proxy)

## 2) Confirmed Root Cause

A stale, pre-existing legacy MDM enrolment is blocking Autopilot-managed MDM enrolment.  
Autopilot cannot complete while a conflicting device MDM registration already exists.

## 3) Remediation Runbook (Exact Order of Operations)

Follow this sequence exactly to avoid re-creating duplicate device identities or re-triggering enrolment conflicts.

### Step 1 - Capture identifiers before cleanup

- Action: Record device serial number, Azure AD Device ID, Intune managed device name, and current primary user.
- Intune path: Devices > All devices > select device > Overview.
- Access type: Admin Center only.
- Outcome: You have authoritative identifiers for safe object cleanup and post-fix verification.

### Step 2 - Remove stale Intune managed device object

- Action: Delete the existing/stale managed device entry tied to the legacy enrolment.
- Intune path: Devices > All devices > select stale device > Delete.
- Access type: Admin Center only.
- Outcome: Removes the old management channel that conflicts with new Autopilot enrolment.

### Step 3 - Remove stale Entra ID device object only if duplicate/conflicting

- Action: Check for duplicate Entra device objects with same serial/device identity. Remove only stale duplicate object(s); keep intended active object when clear.
- Intune path to pivot: Devices > All devices > select device > click Azure AD device link.
- Entra path: Microsoft Entra admin center > Devices > All devices.
- Access type: Admin Center only.
- Outcome: Prevents identity collisions and ownership mismatches during re-enrolment.

### Step 4 - Confirm Autopilot device record is present and correctly assigned

- Action: Validate the Autopilot device identity exists, is assigned to the intended deployment profile, and profile assignment status is correct.
- Intune path: Devices > Windows > Windows enrollment > Devices (Windows Autopilot devices).
- Access type: Admin Center only.
- Outcome: Ensures the device is ready to receive the correct Autopilot configuration at OOBE.

### Step 5 - Remove local legacy workplace/MDM connection on device

- Action: Disconnect the existing work/school account connection that represents the legacy MDM registration.
- Device path: Settings > Accounts > Access work or school > select legacy connection > Disconnect.
- Access type: Device access required (physical console or remote interactive session).
- Outcome: Clears local enrolment relationship that triggers the already-enrolled conflict.

### Step 6 - Remove residual MDM enrolment artifacts (if disconnect alone is insufficient)

- Action: If conflict persists, remove residual enrolment tasks/certificates related to old MDM enrolment.
- Device checks:
  - Task Scheduler > Microsoft > Windows > EnterpriseMgmt > remove orphaned enrolment GUID task folders.
  - Certificates (Local Computer and Current User where applicable) > Personal > Certificates > remove obsolete MDM enrollment certificates only when clearly tied to old enrolment.
- Access type: Device access required (physical or remote, typically with local admin rights).
- Outcome: Eliminates hidden leftovers that can reassert stale MDM state.
- Safety note: Remove only artifacts proven to belong to the old enrolment. If uncertain, stop and validate certificate issuer, expiry, and enrolment GUID mappings before deletion.

### Step 7 - Reboot device

- Action: Restart Windows device after local cleanup.
- Access type: Device access required.
- Outcome: Flushes cached enrolment state and ensures a clean start before Autopilot retry.

### Step 8 - Restart Autopilot enrolment flow from OOBE/ESP stage

- Action: Re-initiate Autopilot provisioning sequence for the device.
- Typical method: Fresh start/reset as per operational process, then run through OOBE with assigned user credentials.
- Access type: Device access required.
- Outcome: Device attempts new MDM enrolment without legacy conflict.

### Step 9 - Monitor enrolment and policy delivery live

- Action: Watch enrolment status and profile delivery while device completes setup.
- Intune paths:
  - Devices > All devices > target device > Device action status / timeline.
  - Devices > Monitor > Enrollment failures (if available in tenant view).
  - Devices > Configuration profiles > assigned profiles > Device status.
- Access type: Admin Center only.
- Outcome: Confirms whether enrolment and subsequent policy application progress normally.

## 4) Post-Remediation Verification (Success Criteria)

Use all checks below to declare incident resolved.

### Verification A - Enrolment status in Intune

- Expected: Device appears as managed with current check-in time.
- Expected: No active enrolment failure for 0x80180014 on the retried attempt.
- Access type: Admin Center only.

### Verification B - MDM channel and profile delivery

- Expected: ProfilesApplied increases from 0 of 4 to full intended assignment state.
- Expected: No recurring 0x80070005 during baseline profile application.
- Access type: Admin Center only.

### Verification C - Device-side connection state

- Expected: Access work or school shows a valid active organizational connection corresponding to the new enrolment.
- Expected: dsregcmd /status shows AzureAdJoined = YES and workplace/MDM state consistent with active management.
- Access type: Device access required.

### Verification D - Compliance and policy health

- Expected: Device receives compliance/configuration policy without immediate access-denied failures.
- Access type: Admin Center only.

Resolution sign-off rule:
- Mark resolved only when enrolment succeeds and assigned Autopilot/Intune profiles are applied without legacy enrolment conflict reappearing.

## 5) Fast Triage Checklist (Operational)

- Confirm there is no duplicate stale managed device object in Intune.
- Confirm no conflicting duplicate stale device object in Entra.
- Confirm legacy work/school connection removed on endpoint.
- Confirm reboot completed before reattempt.
- Confirm Autopilot profile assignment is valid before retry.

## 6) Preventive Action to Stop Recurrence

Implement a pre-Autopilot legacy-enrolment hygiene control in endpoint intake/provisioning.

### Preventive Control Design

- Control objective: Block Autopilot handoff until legacy MDM traces are removed.
- Scope: Devices with prior manual/legacy MDM history.
- Components:
  - Admin Center pre-check: Confirm no stale Intune managed object and no stale duplicate Entra object before assigning device to deployment batch.
  - Device preflight check: Validate Access work or school has no legacy organizational connection before reset/OOBE.
  - Standard cleanup runbook: Use documented cleanup steps for EnterpriseMgmt tasks and obsolete MDM certificates when needed.
  - Gate in change process: Add a mandatory checklist item in Autopilot readiness review and CAB/change ticket template.

### Minimum Preventive SOP Update

- Add a pre-provisioning checklist field: Legacy MDM enrolment confirmed removed (Yes/No).
- Require screenshot or export evidence for:
  - Intune object cleanup completed.
  - Entra duplicate check completed.
  - Device connection state clean before Autopilot retry.
- Run weekly report for devices with enrolment failures containing already-enrolled indicators and remediate before next deployment wave.

## 7) Notes on Error Codes in this Case

- 0x80180014: Treated as confirmed by export context stating device is already enrolled in MDM.
- 0x80070005: Access denied appears during profile stage and is consistent with blocked/invalid management context while conflict exists.

## 8) Closure Statement

Root cause is confirmed as legacy MDM enrolment conflict.  
After stale enrolment object cleanup in admin systems and local device deregistration, rerunning Autopilot should complete successfully when verification criteria above are met.
