# Ticket Analysis: Company Portal Install Error 0x87D1041C

## Summary (one line)
Company app installation from Company Portal fails with error 0x87D1041C, likely due to app assignment, applicability, or compliance gating in Intune.

## Impact (who/how many/business urgency)
- Who: Reported by one end user; wider impact possible if assignment/applicability is misconfigured for a group (to-verify).
- How many: 1 confirmed user; total affected population unknown (to-verify).
- Business urgency: Medium to High (to-verify) depending on whether the app is required for business-critical tasks.

## Known Facts
- Install is initiated via Company Portal.
- Failure error code is 0x87D1041C.
- Symptom is install failure, not a successful install with runtime failure.
- Environment is Intune-managed endpoint context (to-verify).

## Missing Information to Gather
- Exact app name, app ID, and app type (Win32, Store, M365, LOB) (to-verify).
- Assignment details: user/device group membership and Available vs Required targeting (to-verify).
- Device details: OS version/build, architecture, enrollment state, and last check-in time (to-verify).
- Device compliance status and any active Conditional Access/compliance blocks (to-verify).
- Whether other users can install the same app and whether this user can install other apps (to-verify).
- Intune Management Extension and Company Portal logs/time-correlated failure entries (to-verify).

## Likely Category
Intune / Endpoint Management - Application Deployment Failure (Company Portal).

## First Diagnostic Step
In Intune admin center, validate the failing app's assignment and applicability for the affected user/device (targeting group, install intent, OS/architecture requirements), then force a device sync and retry from Company Portal.
