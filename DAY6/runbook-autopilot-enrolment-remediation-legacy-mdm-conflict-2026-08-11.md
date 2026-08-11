# Runbook: Autopilot Enrolment Failure Remediation (Legacy MDM Conflict)

Date: 2026-08-11  
Source RCA: RCA-autopilot-enrolment-failure-legacy-mdm-conflict-2026-08-11

## prerequisites

1. Obtain Intune admin center access with rights to view and delete managed device objects. [Elevated permissions required]
2. Obtain Entra admin center access with rights to view and delete device objects. [Elevated permissions required]
3. Obtain local administrator access on the affected Windows endpoint. [Elevated permissions required]
4. Confirm the target device identity details (device name and user) from the incident ticket.
5. Confirm this incident matches the RCA signature: enrolment error 0x80180014 and message stating the device is already enrolled in MDM.
6. Confirm the endpoint is network-connected to Microsoft cloud endpoints.
7. Open the incident/change record to capture evidence before and after each action.

## Procedure

1. Open Intune admin center and search for the affected device.  
Expected result: One or more managed device records for the target identity are visible.

2. Record the current Intune enrolment state and error values in the ticket.  
Expected result: Pre-change evidence is captured, including Failed state and error context.

3. Delete the stale Intune managed device object linked to the legacy enrolment. [Elevated permissions required]  
Expected result: The stale managed device object is removed from Intune.

4. Open Entra admin center and search for device objects matching the same endpoint identity.  
Expected result: Any duplicate or stale Entra object becomes visible for review.

5. Delete the duplicate or stale Entra device object if one exists. [Elevated permissions required]  
Expected result: Only the valid device identity remains in Entra.

6. Sign in to the affected endpoint with local administrator rights. [Elevated permissions required]  
Expected result: You have an elevated local session on the device.

7. Open Access work or school settings on the endpoint.  
Expected result: Existing work or school connections are listed.

8. Disconnect the legacy work or school MDM connection. [Elevated permissions required]  
Expected result: The legacy management connection is removed from the device.

9. Remove residual EnterpriseMgmt scheduled tasks tied to the old enrolment if they are present. [Elevated permissions required]  
Expected result: Obsolete EnterpriseMgmt tasks related to the old enrolment are no longer present.

10. Remove obsolete MDM certificates tied to the old enrolment if they are present. [Elevated permissions required]  
Expected result: Old enrolment certificates are removed from the local certificate store.

11. Reboot the endpoint. [Elevated permissions required]  
Expected result: Device restarts cleanly and returns to sign-in screen.

12. Start Autopilot provisioning on the endpoint.  
Expected result: Enrolment flow starts without immediate already-enrolled blocking message.

13. Wait for provisioning to complete and sync status to Intune.  
Expected result: Device reports updated enrolment and profile progress.

14. Update the incident ticket with all actions taken and timestamps.  
Expected result: Full change trail is documented for audit and handoff.

## Verification

1. Check Intune enrolment state for the device and confirm it is Success.
2. Check profile application state and confirm assigned profiles are applied (not 0 of 4).
3. Confirm error 0x80180014 is not present after remediation.
4. Confirm blocking 0x80070005 is not present during policy application.
5. Record screenshots or export evidence in the incident ticket before closure.

## Rollback

1. Stop further Autopilot attempts on the affected endpoint immediately.
2. Restore endpoint service by reconnecting the previously removed work or school account only if required for temporary user access continuity.
3. If a valid Entra device object was deleted in error, recover it from Entra deleted devices or recreate identity registration through standard join process. [Elevated permissions required]
4. If a valid Intune managed device object was deleted in error, re-enrol the endpoint through the approved manual support path to restore management visibility. [Elevated permissions required]
5. Revert any unintended certificate or scheduled-task deletions by restoring from endpoint backup/snapshot if available and reopen the incident as remediation failed.
6. Escalate to Endpoint Engineering L3 with the full action timeline and captured evidence if enrolment still fails after rollback.

## Notes

1. This runbook is for the confirmed RCA pattern only: existing legacy manual MDM enrolment conflict causing 0x80180014.
2. In the analysed incident, Azure AD join, licensing, and network prerequisites were healthy; do not treat them as root cause without new evidence.
3. Partial cleanup can cause recurrence, so admin-side object cleanup and endpoint-side artifact cleanup must both be completed.
4. Related known signal: profile stage may remain at 0 of 4 with secondary 0x80070005 until conflict is removed.
5. Link this runbook execution to the preventive control: mandatory pre-Autopilot legacy-enrolment hygiene gate before deployment waves.