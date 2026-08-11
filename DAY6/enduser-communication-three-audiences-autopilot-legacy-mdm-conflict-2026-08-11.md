# End-User Communication Set: Autopilot Enrolment Failure (Legacy MDM Conflict)

Date: 2026-08-11
Source of facts: RCA-autopilot-enrolment-failure-legacy-mdm-conflict-2026-08-11

## Audience 1 - Non-technical executive

Your access and data are safe. One device setup issue occurred because an older management record from 2023-11-04 blocked the new setup, so setup failed and none of its four assigned settings were applied. Identity link, licensing, and network were all working. We are removing the old management links, rerunning setup, and verifying completion. We are also adding a mandatory pre-setup cleanup check. You do not need to do anything unless contacted.

## Audience 2 - Affected end-user team (10 people, non-technical)

Your access and data are safe. One device setup failed because it was still connected to an older management setup from 2023-11-04, which blocked the new setup, so none of the four assigned settings applied. We confirmed sign-in link, licensing, and network were working. We are clearing the old setup links, rerunning setup, and verifying it completes. If you see the same setup failure, stop and report it immediately so we can run the same fix path. Contact the DWP Service Desk / Endpoint Engineering queue.

## Audience 3 - Engineer-to-engineer internal note

Incident scope and facts:
1. Confirmed scope: single device in provided dataset.
2. Primary enrolment failure: 0x80180014 with description that device is already enrolled in MDM.
3. Secondary profile-stage failure: 0x80070005 (Access denied).
4. ProfilesApplied remained 0 of 4.
5. AzureADJoined = Yes, IntuneP1License = Yes, AutopilotLicense = Yes, network endpoints reachable with no proxy blocker.
6. Legacy manual MDM enrolment present from 2023-11-04.

Root cause:
1. Stale legacy manual MDM enrolment conflicted with Autopilot enrolment transaction.
2. Process-level cause: no enforced pre-Autopilot legacy enrolment hygiene gate.

Exact action taken / required execution path:
1. Remove stale Intune managed device object tied to legacy enrolment.
2. Remove stale/duplicate Entra device object if duplicate identity exists.
3. Remove legacy Work/School MDM connection on endpoint.
4. If required, remove residual EnterpriseMgmt scheduled tasks and obsolete MDM certificates linked to old enrolment.
5. Reboot device and rerun Autopilot provisioning.

Config and verification detail:
1. Verify enrolment state returns to Success in Intune.
2. Verify assigned profiles apply (no longer 0 of 4).
3. Verify no recurrence of 0x80180014.
4. Verify no blocking 0x80070005 during policy application.

Preventive action required:
1. Implement mandatory pre-Autopilot enrolment hygiene gate for repurposed/previously managed devices.
2. Gate checks must confirm: no stale Intune object, no conflicting duplicate Entra object, no legacy Work/School MDM connection.
3. Attach readiness evidence to ticket/change record and enforce reviewer sign-off before deployment wave admission.