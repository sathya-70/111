Symptom: During Autopilot provisioning, enrolment fails and the device does not complete setup. Assigned profiles do not apply (recorded as 0 of 4 in the analysed incident).

Cause: The verified root cause is a pre-existing legacy manual MDM enrolment record from 2023-11-04 that conflicted with Autopilot enrolment. The failure was evidenced by enrolment error 0x80180014 with text stating the device is already enrolled in MDM.

Scope: In this RCA dataset, the confirmed affected scope was a single device. The impact on that device was blocked provisioning and delayed endpoint readiness.

Workaround: Remove stale Intune managed device records and any duplicate/stale Entra device object if present, then remove the legacy Work/School MDM connection on the endpoint. If required, remove residual EnterpriseMgmt tasks and obsolete MDM certificates tied to the old enrolment, then reboot and rerun Autopilot provisioning.

Permanent fix: Implement a mandatory pre-Autopilot enrolment hygiene gate for repurposed or previously managed devices. The gate must confirm no stale Intune object, no conflicting duplicate Entra object, and no legacy Work/School MDM connection before deployment.

How to spot it: Look for enrolment state Failed with error code 0x80180014 and error text The device is already enrolled in MDM. Supporting signals in this incident were ProfilesApplied = 0 of 4 and LastError = 0x80070005 (Access denied).