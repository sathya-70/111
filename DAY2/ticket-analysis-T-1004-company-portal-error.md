# Ticket Analysis: T-1004 Company App Fails to Install from Company Portal, Error 0x87D1041C

## Summary
Application installation from Company Portal fails with error code 0x87D1041C; Intune deployment or app availability issue.

## Impact
- **Affected User/Group:** 1 user (unless app is required/assigned to group - to-verify scope)
- **Business Urgency:** **MEDIUM** – blocks access to company app; may be required for job function or optional (to-verify)
- **Scope:** Single user + single app assignment

## Known Facts
- Error: 0x87D1041C (Intune app deployment error; indicates issue with app availability, assignment, or platform compatibility)
- Deployment method: Company Portal (user-initiated install, not auto-deployed)
- Symptom: Install fails at deployment stage (not download, not execution)

## Missing Information to Gather
1. **App name & app ID** – to-verify; which specific app is failing?
2. **App type** – to-verify; Microsoft Store app, LOB (Line-of-Business), Microsoft 365, Win32/MSI, or web app?
3. **Device platform & OS version** – to-verify; Win10/Win11, version number; error 0x87D1041C can indicate platform mismatch
4. **User role/group assignments** – to-verify; is user in target assignment group for this app?
5. **Device compliance status** – to-verify; non-compliant devices may have app installation blocked
6. **App prerequisites** – to-verify; does app require specific framework, registry keys, or dependencies installed first?
7. **Company Portal version & sync status** – to-verify; is Company Portal up-to-date? When was last device sync with Intune?
8. **Storage space available** – to-verify; low disk space can cause install failures
9. **Previous install attempts** – to-verify; is this first attempt or recurring failure? Any past successful installs?
10. **Network/proxy issues** – to-verify; can user reach Microsoft app store or Intune endpoints?

## Likely Category
- **Primary:** Intune Deployment (app not available for device platform, user not in assignment group, or app assignment conflict)
- **Secondary:** Device Compliance (device marked non-compliant, preventing install)
- **Tertiary:** Device Configuration (missing prerequisite, insufficient storage, or network connectivity to app source)

## First Diagnostic Step
1. **Company Portal sync:** Have user manually refresh Company Portal (check for "Refresh" or "Sync" button) and check if app availability status changes
2. **Admin check:** Verify app assignment includes user/device in Intune → Apps → [App Name] → Assignment; confirm assignment type (Required/Available)
3. **Device compliance audit:** Check device compliance status in Intune; if non-compliant, identify & remediate non-compliance before re-attempting install
4. **Device platform check:** Verify app supports the device OS and architecture (x64/x86/ARM); re-publish or adjust assignment if platform mismatch
5. **Intune logs on device:** Check Company Portal or Win32 app install logs (to-verify: location is typically %ProgramFiles%\Intune Management Extension\Logs\ or similar; exact path OS-dependent)
6. **Clear cache & retry:** Have user uninstall app (if installed), clear Company Portal cache (to-verify: cache location), sync, and retry
7. **Escalation:** If error persists after above steps, escalate to Intune admin for app package validation and re-publish attempt

---

**Analysis Prepared By:** DWP Service Desk (AI-assisted)  
**Date:** 2026-08-13  
**Status:** Awaiting Company Portal sync and app assignment verification  
**Verification Required:** Confirm app assignment, device compliance, and platform compatibility; review Intune logs for error details
