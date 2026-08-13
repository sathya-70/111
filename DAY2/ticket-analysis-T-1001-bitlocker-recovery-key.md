# Ticket Analysis: T-1001 BitLocker Recovery Key Prompt on Every Boot

## Summary
New Windows 11 laptop repeatedly prompts for BitLocker recovery key at startup instead of proceeding to normal boot.

## Impact
- **Affected User/Group:** Individual user (1x laptop)
- **Business Urgency:** **HIGH** – device unusable until BitLocker challenge is satisfied; blocks daily logon workflow
- **Scope:** Single endpoint (new deployment)

## Known Facts
- Device: New Windows 11 laptop (deployment/model unknown - to-verify)
- Symptom: BitLocker recovery key prompt appears every boot (not on first boot only)
- Expected behavior: Device should boot normally after BitLocker provisioning phase; recovery key prompt should only appear on TPM/firmware failure or secure boot tampering detection

## Missing Information to Gather
1. **Device make/model and TPM version** – to-verify; critical for TPM/firmware compatibility
2. **BitLocker provisioning status** – Is device fully encrypted or still mid-provisioning?
3. **When did prompting start?** – On first boot after delivery, or after recent updates/changes?
4. **BIOS/firmware version** – to-verify; outdated firmware can cause TPM communication issues
5. **Secure Boot status** – to-verify; disabled or misconfigured Secure Boot can trigger recovery key prompts
6. **Recent Windows updates or configuration changes** – to-verify; MDM policy, group policy pushes, or updates?
7. **Recovery key accessibility** – Does user have the recovery key available, or is this locked out scenario?
8. **Previous BitLocker incidents on this device or fleet** – to-verify; pattern of new deployment issues?

## Likely Category
- **Primary:** Hardware/Firmware (TPM communication, BIOS/firmware version mismatch)
- **Secondary:** Configuration (BitLocker or Secure Boot policy misconfiguration, MDM provisioning conflict)

## First Diagnostic Step
1. **Ask user:** Confirm they have BitLocker recovery key available and can unlock device; gather timestamps (first occurrence, frequency).
2. **Device check:** Verify BIOS/firmware version is current for device model; confirm TPM is present and enabled in BIOS.
3. **Windows logs:** Check Event Viewer → Windows Logs → System for BitLocker-related events (Event ID 24621 or similar - to-verify actual ID; do not invent).
4. **BitLocker status command:** Direct user to run `manage-bde -status` in PowerShell to confirm encryption status and protection method.
5. **Escalation condition:** If TPM communication errors appear or device is new-in-box, escalate to hardware support; if policy-related, check Intune/MDM BitLocker enrollment settings.

---

**Analysis Prepared By:** DWP Service Desk (AI-assisted)  
**Date:** 2026-08-13  
**Status:** Awaiting first diagnostic data from user  
**Verification Required:** All items marked 'to-verify' must be confirmed before next action
