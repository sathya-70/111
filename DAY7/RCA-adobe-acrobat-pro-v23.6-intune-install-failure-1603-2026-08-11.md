# Root Cause Analysis (RCA) - Adobe Acrobat Pro v23.6 Intune Install Failure (1603)

Date: 2026-08-11  
Author: DWP Desktop/Endpoint Engineering  
Incident Type: Application deployment failure (Intune Win32 app)  
Environment: Windows 11 managed endpoints (SYSTEM install context)

---

## 1. Executive Summary

A Win32 app deployment for Adobe Acrobat Pro v23.6 failed in Intune with return code 1603 on both initial execution and retry. The deployment did not meet detection criteria and remained in Failed state.

Primary root cause:
- Installer execution failed deterministically in SYSTEM context (1603), indicating a persistent package/endpoint precondition conflict.

Secondary configuration defect:
- Detection rule checked an Adobe Acrobat Reader registry path rather than a validated Acrobat Pro marker, causing guaranteed non-detection for this app configuration.

Business outcome:
- App not installed on targeted devices.
- Repeat retries consumed deployment cycles without remediation.
- Increased service desk risk and delayed rollout schedule.

---

## 2. Incident Scope and Impact

Scope (from supplied evidence):
- At least one targeted device attempted install twice.
- Same failure pattern on initial run and scheduled retry.

Impact:
- Adobe Acrobat Pro v23.6 unavailable to affected users.
- Potential repeated failure loops for all devices in same assignment if configuration unchanged.
- Risk of wider rollout disruption if promoted without fix.

Severity assessment:
- Technical severity: Medium-High (repeatable deployment failure).
- Business severity: Medium (depends on user dependency for PDF workflows).

---

## 3. Supporting Evidence

Source evidence provided:

1. `[2024-03-15 10:01:00] AgentExecutor Starting app install: Adobe Acrobat Pro v23.6`
- Confirms deployment object and start time.

2. `[2024-03-15 10:01:01] AppInstaller Install context: SYSTEM`
- Confirms machine-context execution, so permissions/UAC behavior differs from user-context tests.

3. `[2024-03-15 10:01:03] AppInstaller Install command: msiexec /i AcrobatPro.msi /quiet`
- Confirms command line used by Intune.

4. `[2024-03-15 10:01:44] AppInstaller Return code: 1603`
- Fatal MSI failure; install did not complete successfully.

5. `[2024-03-15 10:01:45] DetectionRule Key: HKLM\SOFTWARE\Adobe\Acrobat Reader\23.0`
- Detection target references Reader path while deployment is Acrobat Pro.

6. `[2024-03-15 10:01:45] DetectionRule Value: not found`
- App not detected under configured key.

7. `[2024-03-15 10:01:47] AgentExecutor Retry scheduled: 60 minutes`
- Confirms retry policy engaged.

8. `[2024-03-15 11:02:31] AppInstaller Return code: 1603`
- Same fatal code on retry; issue is persistent, not transient.

Evidence confidence:
- High for failure determination and retry behavior.
- Medium for exact installer blocker detail because verbose MSI logs were not captured in supplied evidence.

---

## 4. Timeline (UTC/local as per source log)

| Time | Event | Interpretation |
|------|-------|----------------|
| 10:01:00 | Install initiated | Deployment starts |
| 10:01:01 | Context SYSTEM | Machine-level install path |
| 10:01:03 | `msiexec /i AcrobatPro.msi /quiet` | Silent MSI execution |
| 10:01:44 | Return code 1603 | Fatal installer failure (first attempt) |
| 10:01:45 | Detection rule executed | Post-failure detection check |
| 10:01:45 | Registry value not found | Not detected with current rule |
| 10:01:47 | Result Failed, retry scheduled | Automatic retry in 60 mins |
| 11:01:47 | Retry attempt 1 starts | Re-execution without config change |
| 11:02:31 | Return code 1603 again | Deterministic repeat failure |
| 11:02:32 | Retry 1 failed | Ongoing failure loop risk |

Elapsed analysis:
- First attempt duration to failure: ~41 seconds.
- Retry attempt duration to failure: ~43 seconds.
- Similar runtime supports deterministic blocker hypothesis.

---

## 5. Technical Findings

1. Installer failure is primary
- 1603 is generated before detection and repeated identically.
- Detection misconfiguration alone cannot generate MSI 1603.

2. Detection configuration is incorrect for app identity
- Rule checks `Adobe\Acrobat Reader\23.0`, not a proven Acrobat Pro v23.6 marker.
- Even a successful Pro install could be misreported as Not detected.

3. Retry strategy cannot resolve static misconfiguration
- Retrying same command with unchanged prerequisites and detection logic reproduced failure.

4. Missing deep diagnostics in baseline package config
- No verbose MSI log path in command means first-failure evidence insufficient for immediate pinpointing (file lock, product conflict, pending reboot, custom action failure, etc.).

---

## 6. 5 Whys Analysis

Problem statement:
- Adobe Acrobat Pro v23.6 installation failed repeatedly in Intune and did not detect as installed.

Why 1:
- Why did deployment fail?
- Because installer returned `1603` during execution in SYSTEM context.

Why 2:
- Why was `1603` unresolved after retry?
- Because retry used the same package command and endpoint state with no remediation between attempts.

Why 3:
- Why was there no remediation path before retry?
- Because deployment lacked mandatory pre-flight checks and detailed MSI logging to identify and clear blockers quickly.

Why 4:
- Why were pre-flight checks and robust diagnostics missing?
- Because the packaging quality gate did not enforce a standard validation checklist (conflict checks, pending reboot checks, verbose logging, and context testing).

Why 5:
- Why did quality gate fail to catch broader configuration issues?
- Because release governance focused on upload success and basic command syntax, but did not require detection-rule alignment and pilot evidence sign-off before assignment.

Root process cause identified by 5 Whys:
- Insufficient deployment governance controls for Win32 app packaging and validation (technical + process).

---

## 7. Root Cause and Contributing Factors

Primary root cause:
- Deterministic MSI install failure (1603) caused by unresolved install-time blocker in SYSTEM context.

Secondary root cause:
- Misaligned detection rule (Reader registry path used for Pro app), causing non-detection and unreliable install state reporting.

Contributing factors:
- No verbose MSI log capture in install command.
- No enforced pre-flight checks before assignment.
- Retry policy executed without conditional remediation.
- Incomplete packaging checklist and approval criteria.

---

## 8. Corrective Actions (Immediate and Short-Term)

Immediate (0-4 hours)
1. Pause new/broad assignments of this app revision.
2. Keep scope to controlled pilot only.
3. Update install command to include verbose logging, for example:
   `msiexec /i "AcrobatPro.msi" /qn /L*v "%ProgramData%\Microsoft\IntuneManagementExtension\Logs\AcrobatPro_v23.6_install.log"`
4. Correct detection rule to Pro-specific marker (prefer MSI product code or validated Pro registry key/value).

Short-term (same business day)
1. Re-test on 10-20 pilot devices across hardware profiles.
2. Validate return code mapping (`0`, `3010`, `1641` as success classes; `1603` as failure).
3. Confirm endpoint truth matches Intune status (Installed only when actual Pro v23.6 present).

---

## 9. Preventive Actions (Long-Term)

1. Standardized Win32 Packaging Quality Gate (mandatory)
- Include:
  - SYSTEM context install/uninstall test.
  - Verbose MSI logging enabled in pre-prod test runs.
  - Detection rule verification for install and uninstall states.
  - Return code table validation.
- Owner: Intune App Packaging Lead
- Target date: within 10 business days

2. Deployment Readiness Checklist in change process
- No production assignment until checklist is signed off by Packaging + Endpoint Engineering.
- Owner: Change Manager + Endpoint Engineering Lead
- Target date: within 2 weeks

3. Detection Rule Design Standard
- Prefer MSI product code where possible; registry/file detection must include evidence screenshot/log from test device.
- Owner: Packaging Standards Owner
- Target date: within 2 weeks

4. Pilot Gate Policy
- Minimum pilot sample size and success threshold required before scale-out.
- Suggested default: >= 98% success over 24-48 hours, zero Sev1 incidents.
- Owner: Endpoint Engineering Governance
- Target date: within 2 weeks

5. Knowledge Base entry for MSI 1603 pattern
- Add troubleshooting matrix: conflict, reboot pending, permission, custom action, detection mismatch.
- Owner: L2/L3 Knowledge Manager
- Target date: within 5 business days

---

## 10. Validation Plan for Preventive Controls

Validation criteria:
1. Next 3 Win32 app releases show completed quality gate artifacts.
2. No critical detection mismatches found in peer review.
3. Reduction in first-attempt deployment failures for new Win32 apps.
4. Evidence that rollback/hold decisions can be made from available logs within 30 minutes.

Reporting cadence:
- Weekly deployment quality review for 4 weeks post-implementation.

---

## 11. Closure Criteria

The incident can be closed when all are true:
1. Pilot devices install Acrobat Pro v23.6 successfully without 1603 recurrence.
2. Intune detection accurately reports Installed for validated endpoints.
3. No repeated retry-loop failures for 24 hours after corrective deployment.
4. Preventive action owners and due dates are approved and tracked in change records.

---

## 12. Assumptions and Limitations

Assumptions:
- Provided logs are accurate and complete for observed attempts.
- Endpoint policy/environment remained stable between attempt and retry.

Limitations:
- No MSI verbose log excerpt was provided, so sub-cause of 1603 cannot be forensically pinned to a single installer action in this RCA.

---

## 13. Recommended Next Operational Step

- Execute one controlled pilot redeployment after command/detection correction and collect MSI verbose logs from at least 3 success and 3 failure cases (if failures remain) to finalize sub-cause classification.
