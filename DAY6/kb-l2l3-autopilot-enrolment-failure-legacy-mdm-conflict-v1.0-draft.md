# KB: Autopilot Enrolment Failure - Legacy MDM Conflict

Version: v 1.0, 10/08/2026, status : Draft

## Background

Autopilot enrolment is the onboarding flow that registers a Windows device into managed state so policies and profiles can apply. In this incident pattern, enrolment failure blocks profile delivery and delays endpoint readiness. This matters because the device remains not fully managed and not fully compliant until enrolment succeeds.

## Symptom

Engineer observes Intune enrolment state as Failed and profile application stuck at 0 of 4. User reports device setup does not complete during provisioning. In the verified RCA pattern, the primary failure signature is error code 0x80180014 with message The device is already enrolled in MDM.

## Root cause

Verified root cause is a stale legacy manual MDM enrolment record (from 2023-11-04 in the analysed case) that conflicts with Autopilot enrolment. Evidence that confirms this: EnrollmentState = Failed, ErrorCode = 0x80180014, ErrorDescription = The device is already enrolled in MDM, MDMEnrolled = Yes with legacy enrolment source, ProfilesApplied = 0 of 4, and LastError = 0x80070005 (Access denied). AzureADJoined, IntuneP1License, AutopilotLicense, and network checks were all healthy in the same evidence set.

## Detection

1. Go to Intune admin center path: Devices > All devices > select target device > Overview. Check field Enrollment state.  
Look for: Failed.

2. Go to Intune admin center path: Devices > All devices > select target device > Device diagnostics/export view used by your tenant. Check field ErrorCode.  
Look for: 0x80180014.

3. In the same Intune diagnostics/export source, check field ErrorDescription.  
Look for exact text: The device is already enrolled in MDM.

4. In the same Intune diagnostics/export source, check field ProfilesApplied.  
Look for: 0 of 4.

5. In the same Intune diagnostics/export source, check field LastError.  
Look for: 0x80070005 (Access denied).

6. Go to Intune admin center path: Devices > All devices > select target device > Properties/identity fields used by your tenant export. Check field EnrolmentSource and MDMEnrolled.  
Look for: legacy manual MDM enrolment and MDMEnrolled = Yes.

7. Go to Entra admin center path: Identity > Devices > All devices > search target device identity. Check for duplicate/stale device objects.  
Look for: multiple objects for same endpoint identity.

8. Comparison check (affected vs known-good control device) using the same fields from steps 1-6.  
Expected comparison: affected device shows Failed, 0x80180014, ProfilesApplied 0 of 4, and legacy MDM present; known-good device shows successful enrolment and no 0x80180014 conflict signature.

9. Event IDs and log signatures to record.  
Verified in RCA: error signatures 0x80180014 and 0x80070005.  
Note: no numeric Windows Event ID was captured in the provided RCA evidence set.

## Resolution

1. Intune admin center path: Devices > All devices > select affected device > Delete stale managed device object linked to legacy enrolment. [Elevated permissions required]  
Expected result: stale Intune managed device object is removed.

2. Entra admin center path: Identity > Devices > All devices > select duplicate/stale object > Delete (only if duplicate/stale is confirmed). [Elevated permissions required]  
Expected result: only valid device identity remains.

3. On endpoint path: Settings > Accounts > Access work or school > select legacy connection > Disconnect. [Elevated permissions required]  
Expected result: legacy work/school MDM connection is removed.

4. On endpoint path: Task Scheduler > Task Scheduler Library > Microsoft > Windows > EnterpriseMgmt > remove tasks tied to old enrolment if present. [Elevated permissions required]  
Expected result: obsolete EnterpriseMgmt tasks are removed.

5. On endpoint path: Certificates console for local machine > remove obsolete MDM certificates tied to old enrolment if present. [Elevated permissions required]  
Expected result: obsolete enrolment certificates are removed.

6. On endpoint: reboot device. [Elevated permissions required]  
Expected result: clean restart with old enrolment context cleared.

7. Start Autopilot provisioning again on the endpoint.  
Expected result: enrolment proceeds without already-enrolled block.

## Verification

1. Intune admin center path: Devices > All devices > select device > Overview; confirm Enrollment state = Success.
2. In the same diagnostics/export source, confirm ProfilesApplied is no longer 0 of 4.
3. Confirm error 0x80180014 is absent after remediation.
4. Confirm blocking 0x80070005 is absent during policy/profile application.
5. Attach before/after evidence to the incident record before closure.

## Rollback

1. Stop additional Autopilot retry attempts on the affected endpoint immediately.
2. If user service continuity is required, reconnect the previously removed work/school account on endpoint path Settings > Accounts > Access work or school.
3. If a valid Entra object was deleted by mistake, go to Entra admin center path: Identity > Devices > Deleted devices and recover it, or re-register through approved join path. [Elevated permissions required]
4. If a valid Intune managed object was deleted by mistake, re-enrol device through approved manual support path to restore management visibility. [Elevated permissions required]
5. If unintended local deletions were made (tasks/certs), restore from endpoint backup or snapshot and reopen incident as remediation failed.
6. Escalate to Endpoint Engineering L3 with exact timeline and captured evidence.

## Preventive

1. Add a mandatory pre-Autopilot enrolment hygiene gate to provisioning SOP with three required checks: no stale Intune managed device object, no duplicate Entra device object, no legacy work/school MDM connection.
2. Add CAB/change template fields that require screenshot or export evidence for each hygiene check before wave admission.
3. Add a deployment preflight report that flags already-enrolled conflict signature before provisioning starts.
4. Add weekly metric review of conflict-driven Autopilot failures and trigger formal review when threshold is exceeded.

## Related

1. Related RCA: RCA-autopilot-enrolment-failure-legacy-mdm-conflict-2026-08-11.
2. Related runbook: runbook-autopilot-enrolment-remediation-legacy-mdm-conflict-2026-08-11.
3. Related closure note: closure-note-autopilot-enrollment-legacy-mdm-conflict-2026-08-11.
4. Related known error: known-error-autopilot-enrolment-failure-legacy-mdm-conflict-2026-08-11.
5. Related communications: communication-file-for-rca-autopilot-enrollment.