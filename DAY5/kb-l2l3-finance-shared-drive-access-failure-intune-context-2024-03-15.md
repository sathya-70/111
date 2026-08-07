# KB: Finance Shared Drive Mapping Failure After Intune Script Context Change (L2/L3)

Version: v 1.0  
Date: 07/08/2026  
Status: Draft

## Background
Finance users require mapped drive `S:` to access `\\finbridge-fs01\Finance` at sign-in. The original solution used USER logon context (GPO-style behavior), where user credentials and user network context are available during mapping. A change moved mapping to an Intune PowerShell script running as SYSTEM. This matters because SYSTEM context does not behave like USER context for credentialed share mapping, and timing at startup/logon can differ. A failure in this mapping path has high business impact because Finance workflows depend on `S:` availability.

## Symptom
Engineer-observed symptoms:
- `S:` is missing or unassigned on affected Finance endpoints (`DESKTOP-FB*`).
- Intune script execution returns non-zero (`exit code 1`) for mapping script.
- Log message indicates network path failure against `\\finbridge-fs01\Finance`.

User-reported symptoms:
- "I cannot open S drive."
- "Finance shared folder is unavailable after sign-in."

## Root Cause
Drive mapping logic designed for USER logon context was migrated to Intune SYSTEM context without redesign for context-specific network/credential behavior and startup timing readiness.

Evidence that confirms root cause:
- Script execution context explicitly shows SYSTEM.
- Script failure shows `Network name cannot be found` for `\\finbridge-fs01\Finance`.
- Service Control Manager Event ID `7036` shows Workstation service reached running state only after script failure window.
- GroupPolicy Event ID `1500` shows policy processing success, ruling out GP processing failure as primary cause.
- NTFS Event ID `98` confirms `S:` could not be mapped / drive letter not assigned.

## Detection
Confirm this diagnosis completely before remediation.

1. Collect Intune script failure evidence on one affected endpoint.
- Log location: `C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log`
- Fields to check: `TimeCreated` (or timestamp prefix), `ScriptName`, `RunAsAccount`, `ExitCode`, `ErrorMessage`.
- What to look for: entries for `Map-FinBridgeDrives.ps1`, `RunAsAccount=SYSTEM`, `ExitCode=1`, and text equivalent to `Network name cannot be found` or UNC not accessible.

2. Confirm Workstation service timing relative to script failure.
- Log location: Event Viewer -> `Windows Logs\System`
- Fields to check: `ProviderName`, `Event ID`, `TimeCreated`, `Message`.
- What to look for: `ProviderName=Service Control Manager`, `Event ID=7036`, message indicating `Workstation` entered `running` state after script failure timestamp.

3. Confirm Group Policy was not the failing component.
- Log location: Event Viewer -> `Applications and Services Logs\Microsoft\Windows\GroupPolicy\Operational`
- Fields to check: `Event ID`, `Level`, `TimeCreated`, `Message`.
- What to look for: `Event ID=1500` with successful processing message in the same incident window.

4. Confirm final mapping outcome failure.
- Log location: Event Viewer -> `Applications and Services Logs\Microsoft\Windows\NTFS\Operational`
- Fields to check: `Event ID`, `TimeCreated`, `Message`, `Computer`.
- What to look for: `Event ID=98` with message indicating drive letter `S:` could not be mapped / not assigned.

5. Run required comparison check (affected vs control cohort).
- Affected sample: one Finance endpoint in OU=Finance (`DESKTOP-FB*`) targeted by script.
- Control sample: one non-Finance endpoint not targeted by `Map-FinBridgeDrives.ps1` (or known-good user-context mapping group).
- Data points to compare: `RunAsAccount`, `ExitCode`, presence of Event ID `98`, and whether `S:` exists post sign-in.
- Confirming pattern: affected endpoint shows SYSTEM + failure + missing `S:`; control endpoint does not show this pattern.

## Resolution
Execute in order. Each step includes exact Azure portal path and expected result.

1. [ELEVATED] Open Azure portal path: `https://portal.azure.com` -> `Microsoft Intune` -> `Devices` -> `Scripts and remediations` -> `Platform scripts`.
Expected result: Platform scripts list is visible.

2. [ELEVATED] Select script `Map-FinBridgeDrives.ps1` in `Platform scripts`.
Expected result: Script overview pane shows assignments and run settings.

3. [ELEVATED] Remove Finance assignment from path: `Map-FinBridgeDrives.ps1` -> `Assignments` -> remove `FINANCE_TARGET_GROUP` -> `Review + save`.
Expected result: Finance group is no longer targeted by SYSTEM-context script.

4. [ELEVATED] Create remediation script file `Map-FinBridgeDrives-UserContext-Remediate.ps1` with readiness check + retry (3 attempts, 20 seconds delay).
Expected result: Script file is saved and syntax-valid.

5. [ELEVATED] Create new script in Azure portal path: `https://portal.azure.com` -> `Microsoft Intune` -> `Devices` -> `Scripts and remediations` -> `Platform scripts` -> `Add` -> `Windows 10 and later`.
Expected result: New script wizard opens.

6. [ELEVATED] Upload file and set properties in path: `Add PowerShell script` -> `Script settings` -> `Run this script using the logged on credentials = Yes` -> `Run script in 64-bit PowerShell host = Yes`.
Expected result: Script is configured for USER context and 64-bit host.

7. [ELEVATED] Assign script in path: `Assignments` -> `Add groups` -> select `FINANCE_TARGET_GROUP` -> `Review + add`.
Expected result: Remediation script is assigned to Finance users.

8. [ELEVATED] Trigger sync for three pilot devices in path: `https://portal.azure.com` -> `Microsoft Intune` -> `Devices` -> `Windows` -> select device -> `Sync`.
Expected result: Sync request accepted for each pilot endpoint.

9. Ask pilot user to sign out and sign in once on each pilot endpoint.
Expected result: USER-context script executes at next user session.

10. Validate mapping on each pilot endpoint by running `Get-PSDrive -Name S` in user session.
Expected result: `S:` exists with `Root=\\finbridge-fs01\Finance`.

## Verification
1. Verify Intune run status in portal path: `https://portal.azure.com` -> `Microsoft Intune` -> `Devices` -> `Scripts and remediations` -> `Platform scripts` -> `Map-FinBridgeDrives-UserContext-Remediate` -> `Device status`.
Expected result: Success trend stable; no growing failure count.

2. Verify endpoint mapping on at least 10 Finance endpoints with `Get-PSDrive -Name S` after sign-in.
Expected result: `S:` present and rooted to `\\finbridge-fs01\Finance`.

3. Verify share access by opening `\\finbridge-fs01\Finance` from sampled Finance user sessions.
Expected result: Share opens without access errors.

4. Verify incident signal reduction in Service Desk queue.
Expected result: "Missing S drive" tickets return to baseline.

## Rollback
If impact worsens, execute rollback immediately and in order.

1. [ELEVATED] Remove assignment of `Map-FinBridgeDrives-UserContext-Remediate` in portal path: `https://portal.azure.com` -> `Microsoft Intune` -> `Devices` -> `Scripts and remediations` -> `Platform scripts` -> `Map-FinBridgeDrives-UserContext-Remediate` -> `Assignments` -> remove `FINANCE_TARGET_GROUP` -> `Review + save`.
Expected result: Remediation script stops targeting Finance users.

2. [ELEVATED] Re-enable known-good pre-migration USER logon mapping method from approved baseline change record.
Expected result: Baseline mapping mechanism is active again.

3. [ELEVATED] Force policy refresh on pilot endpoints with elevated command prompt: `gpupdate /force`.
Expected result: Policy refresh completes successfully.

4. Ask pilot users to sign out/sign in once.
Expected result: Baseline mapping re-applies in new user session.

5. Validate `S:` on pilots with `Get-PSDrive -Name S`.
Expected result: `S:` mapping restored via baseline method.

6. Stop broad rollout communication and issue rollback notice to Service Desk.
Expected result: New remediation actions are paused and support follows rollback guidance.

## Preventive
Implement the following specific process/tooling changes:

1. Add a mandatory `Execution Context` control in change template with allowed values `USER` or `SYSTEM`; block CAB approval if blank.
2. Add CI lint rule for script packages: fail release if a drive-mapping script is configured as SYSTEM without explicit exception ID.
3. Standardize a preflight function in all mapping scripts that logs `Context`, `UNCProbe`, `RetryCount`, `FinalExitCode` to IME log.
4. Enforce pilot ring gating in Intune assignments:
- Ring 0: 3 devices
- Ring 1: 10% of Finance cohort
- Ring 2: 100%
Progression only when Ring failure rate is below 2% for 24 hours.
5. Publish KQL/Workbook alert for repeated script `ExitCode != 0` with keyword `Network name cannot be found` by OU/group.
6. Add a release checklist item requiring explicit affected-vs-control comparison evidence before production assignment.

## Related
- [Training/DAY4/RCA-finance-shared-drive-access-failure-2024-03-15.md](Training/DAY4/RCA-finance-shared-drive-access-failure-2024-03-15.md)
- [Training/DAY5/runbook-finance-shared-drive-access-failure-2024-03-15.md](Training/DAY5/runbook-finance-shared-drive-access-failure-2024-03-15.md)
- [Training/DAY5/kb-finance-shared-drive-access-end-user-2024-03-15.md](Training/DAY5/kb-finance-shared-drive-access-end-user-2024-03-15.md)
- [Training/DAY4/RCA-avd-black-screen-POOL-FIN-01-2024-03-15.md](Training/DAY4/RCA-avd-black-screen-POOL-FIN-01-2024-03-15.md)
- [Training/DAY4/RCA-cthompson-account-lockout-2024-03-15.md](Training/DAY4/RCA-cthompson-account-lockout-2024-03-15.md)
