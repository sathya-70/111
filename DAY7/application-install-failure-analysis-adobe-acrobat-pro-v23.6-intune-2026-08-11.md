# Root Cause Analysis - Intune Win32 App Install Failure (Adobe Acrobat Pro v23.6)

Date: 2026-08-11  
Analyst: DWP Desktop/Endpoint Engineer  
Source: Intune Management Extension style install log (sanitised)  
App in scope: Adobe Acrobat Pro v23.6 (Win32, .intunewin)

---

## Event Summary

| Time | Component | Event | Outcome |
|------|-----------|-------|---------|
| 10:01:00 | AgentExecutor | Starting app install: Adobe Acrobat Pro v23.6 | Install flow started |
| 10:01:01 | AppInstaller | Install context: SYSTEM | Machine context confirmed |
| 10:01:03 | AppInstaller | Install command: msiexec /i AcrobatPro.msi /quiet | Command launched |
| 10:01:44 | AppInstaller | Return code: 1603 | Fatal install failure |
| 10:01:45 | DetectionRule | Registry check: HKLM\SOFTWARE\Adobe\Acrobat Reader\23.0 | Key/value not found |
| 10:01:47 | AgentExecutor | Result: Failed | Retry scheduled |
| 11:01:47 | AgentExecutor | Retry attempt 1 | Same command rerun |
| 11:02:31 | AppInstaller | Return code: 1603 | Repeat fatal failure |

---

## Root Cause Statement

The deployment failed because the installer returned Windows Installer code 1603 on both the initial attempt and retry, indicating a deterministic install-time blocker in SYSTEM context. In parallel, the detection rule is misaligned with the target product path (checking Acrobat Reader key for an Acrobat Pro deployment), which would produce false "Not detected" even if installation later succeeded. Primary failure is installer-side (1603); detection misconfiguration is a secondary configuration defect.

---

## Technical Analysis

### 1. Deterministic installer failure
- Evidence: Return code 1603 appears twice, one hour apart, with identical command and context.
- Interpretation: This is not a transient network or policy timing issue; it is a repeatable install blocker.
- Confidence: High.

### 2. Detection rule likely targets wrong product family
- Evidence: Detection checks HKLM\SOFTWARE\Adobe\Acrobat Reader\23.0 while app name is Adobe Acrobat Pro v23.6.
- Interpretation: Reader and Pro often write to different registry/product markers; this rule is likely incorrect for Pro.
- Impact:
  - Can report false negative status.
  - Can trigger unnecessary retries/reinstall attempts.
- Confidence: High.

### 3. Why retry did not recover
- Evidence: Retry after 60 minutes produced same 1603 outcome.
- Interpretation: Underlying condition persisted (for example existing conflicting install, pending reboot, source/permission issue, or transform/prerequisite issue).
- Confidence: High.

---

## Most Probable Causes (Ranked)

1. Existing Adobe product conflict or upgrade-path mismatch (most probable)
- Typical 1603 trigger when a previous Reader/Pro build or language pack conflicts with current MSI logic.

2. Pending reboot or in-use files in SYSTEM context
- Common for Adobe updates when locked files or reboot-required state exists.

3. Command/package mismatch inside .intunewin wrapper
- MSI file name/path may not resolve as expected at runtime if content layout or command path assumptions are wrong.

4. Detection rule misconfiguration (confirmed secondary defect)
- Not cause of 1603 itself, but causes false "not detected" and can mask successful remediations.

5. Missing install logging and return-code mapping hygiene
- Without verbose MSI log, 1603 root detail is hidden, slowing remediation.

---

## Required Remediation Plan

### Phase A - Immediate containment
1. Pause broad assignment for this app revision.
2. Keep deployment limited to test group until 1603 is resolved.
3. Prevent repeated retries from expanding user impact.

### Phase B - Fix app configuration in Intune
1. Update install command to include verbose MSI logging for diagnostics:
   msiexec /i "AcrobatPro.msi" /qn /L*v "%ProgramData%\Microsoft\IntuneManagementExtension\Logs\AcrobatPro_Install.log"
2. Keep uninstall command defined and validated in pilot:
   msiexec /x "{PRODUCT-CODE}" /qn
   Note: replace with actual Acrobat Pro product code from tested endpoint.
3. Correct detection rule to a Pro-specific marker. Use one validated method only:
- Preferred: MSI product code detection (most robust for MSI app lifecycle).
- Alternative: Registry key/value known to be created by Acrobat Pro v23.6.
4. Validate return code classification includes:
- 0 = Success
- 3010 = Soft reboot required (success)
- 1641 = Hard reboot initiated (success)
- 1603 = Failed

### Phase C - Endpoint-level validation on pilot device
1. Check pending reboot indicators before install.
2. Confirm no conflicting Adobe installation state.
3. Execute command locally in SYSTEM context test (for example with PsExec or equivalent controlled method).
4. Review generated MSI verbose log for the first fatal error line preceding 1603.
5. Confirm corrected detection rule returns Installed only when true Pro v23.6 marker exists.

### Phase D - Controlled re-test in Intune
1. Repackage or revise app command/detection.
2. Assign to 10-20 device pilot group.
3. Advance only if install success >= 98% within 24-48 hours and zero Sev1 business issues.

---

## Decision and Ownership

| Decision Point | Owner | SLA |
|----------------|-------|-----|
| Pause rollout / keep pilot-only | Endpoint Engineering Lead | Immediate (<= 30 min) |
| Approve detection-rule change | Intune App Packaging Owner | Same business day |
| Approve re-test after MSI log review | Endpoint Engineering + App Owner | <= 4 business hours after logs collected |
| Approve broader rollout resume | Change Manager + Endpoint Lead | Next CAB/change checkpoint |

---

## Verification Criteria for Closure

1. Three consecutive pilot installations complete without 1603.
2. Intune status aligns with endpoint truth (Installed state matches real Pro installation).
3. Detection rule validated on both fresh install and uninstall scenarios.
4. No repeated retry-loop failures in Intune for 24 hours.
5. Engineer sign-off that MSI verbose log no longer shows fatal blocker.

---

## Quick Engineer Checklist

1. Pause broad assignment.
2. Add MSI verbose logging to install command.
3. Replace Reader-based detection with Pro-accurate detection (prefer MSI product code).
4. Validate return codes.
5. Pilot test on 10-20 devices.
6. Confirm success metrics before ring expansion.

---

## Notes

- Analysis is based only on the provided sanitised log excerpt.
- No PII, secrets, or tenant-sensitive identifiers are included.
- Final implementation choices should be validated against live tenant behavior and Adobe packaging guidance.
