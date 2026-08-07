## Version Header
Title: Finance Shared Drive Access Failure After Script Migration
Version: 1.0
Date: 07/08/2026
Author: Sathya
reviewed: self
status: draft
change: initial version from RCA

# Runbook: Finance Shared Drive Access Failure After Script Migration

## Purpose
Restore access to Finance shared drive `S:` for users affected by SYSTEM-context drive-mapping failure.

## Prerequisites
Complete all prerequisites before starting the procedure.

1. Confirm you have an approved change ticket for emergency remediation.
2. Confirm you have [ELEVATED] Intune Administrator or Endpoint Security Manager rights in Microsoft Intune.
3. Confirm you have [ELEVATED] rights to edit the Finance user-targeting Entra ID group used for script assignment.
4. Confirm you have [ELEVATED] local admin rights on at least one pilot Finance endpoint.
5. Confirm the Finance target share path is `\\finbridge-fs01\Finance`.
6. Confirm the affected drive letter is `S:`.
7. Confirm the failing script object name in Intune is `Map-FinBridgeDrives.ps1`.
8. Identify and record the exact Finance targeting group name in Entra ID as `FINANCE_TARGET_GROUP`.
9. Identify and record three pilot Finance devices as `PILOT_DEVICE_1`, `PILOT_DEVICE_2`, and `PILOT_DEVICE_3`.
10. Prepare a test Finance user account with valid access to `\\finbridge-fs01\Finance`.
11. Prepare a text editor to create a remediation script file.
12. Prepare PowerShell 5.1 or later on pilot devices.

## Procedure
Follow steps in order. Each step has one action and one expected result.

1. [ELEVATED] Open Microsoft Intune admin center.
Expected result: Intune admin portal loads successfully.

2. [ELEVATED] Open the script object `Map-FinBridgeDrives.ps1` in Intune.
Expected result: Script details page shows current assignment and run context.

3. [ELEVATED] Remove assignment of `Map-FinBridgeDrives.ps1` from `FINANCE_TARGET_GROUP`.
Expected result: Finance group is no longer targeted by the SYSTEM-context script.

4. [ELEVATED] Create a new file named `Map-FinBridgeDrives-UserContext-Remediate.ps1` with the script below.
Expected result: Script file is saved locally with no syntax errors.

```powershell
$ErrorActionPreference = 'Stop'

$driveLetter = 'S'
$uncPath = '\\finbridge-fs01\Finance'
$attempts = 3
$delaySeconds = 20

for ($i = 1; $i -le $attempts; $i++) {
    try {
        if (Get-PSDrive -Name $driveLetter -ErrorAction SilentlyContinue) {
            Remove-PSDrive -Name $driveLetter -Force -ErrorAction SilentlyContinue
        }

        if (Test-Path -Path $uncPath) {
            New-PSDrive -Name $driveLetter -PSProvider FileSystem -Root $uncPath -Persist -Scope Global | Out-Null
            if (Test-Path -Path ($driveLetter + ':\\')) {
                Write-Output "Mapped $driveLetter`: to $uncPath on attempt $i"
                exit 0
            }
        }

        Write-Warning "Attempt $i failed to map $driveLetter`: to $uncPath"
    }
    catch {
        Write-Warning "Attempt $i error: $($_.Exception.Message)"
    }

    Start-Sleep -Seconds $delaySeconds
}

Write-Error "Failed to map $driveLetter`: to $uncPath after $attempts attempts"
exit 1
```

5. [ELEVATED] Create a new Intune Platform Script named `Map-FinBridgeDrives-UserContext-Remediate` and upload the file from step 4.
Expected result: New script object exists in Intune with uploaded content.

6. [ELEVATED] Set script option `Run this script using the logged on credentials` to `Yes`.
Expected result: Script is configured to run in USER context.

7. [ELEVATED] Set script option `Run script in 64-bit PowerShell host` to `Yes`.
Expected result: Script is configured for 64-bit execution.

8. [ELEVATED] Assign `Map-FinBridgeDrives-UserContext-Remediate` to `FINANCE_TARGET_GROUP`.
Expected result: Finance users are targeted by USER-context remediation script.

9. Ask the test Finance user to sign out and sign back in on `PILOT_DEVICE_1`.
Expected result: A fresh user logon session starts on the pilot device.

10. Run `Get-PSDrive -Name S` in the test user session on `PILOT_DEVICE_1`.
Expected result: Command returns `S` with root `\\finbridge-fs01\Finance`.

11. Open `S:\` in File Explorer on `PILOT_DEVICE_1`.
Expected result: Finance share content opens without access error.

12. Repeat step 9 on `PILOT_DEVICE_2`.
Expected result: A fresh user logon session starts on the second pilot device.

13. Repeat step 10 on `PILOT_DEVICE_2`.
Expected result: `S:` is present and rooted to `\\finbridge-fs01\Finance`.

14. Repeat step 11 on `PILOT_DEVICE_2`.
Expected result: Finance share content opens without access error.

15. Repeat step 9 on `PILOT_DEVICE_3`.
Expected result: A fresh user logon session starts on the third pilot device.

16. Repeat step 10 on `PILOT_DEVICE_3`.
Expected result: `S:` is present and rooted to `\\finbridge-fs01\Finance`.

17. Repeat step 11 on `PILOT_DEVICE_3`.
Expected result: Finance share content opens without access error.

18. Notify Service Desk to request sign-out/sign-in for all Finance users.
Expected result: All targeted users receive a standard re-logon instruction.

## Verification
Complete all checks before closure.

1. Run `Get-PSDrive -Name S` on at least 10 Finance endpoints after user sign-in.
Expected result: All sampled endpoints return `S` mapped to `\\finbridge-fs01\Finance`.

2. Open `\\finbridge-fs01\Finance` directly in File Explorer from at least 10 Finance user sessions.
Expected result: All sampled users can open the share path directly.

3. [ELEVATED] Review Intune script run status for `Map-FinBridgeDrives-UserContext-Remediate`.
Expected result: Success rate is stable and failures are not increasing.

4. [ELEVATED] Confirm no new non-zero execution trend for the new script in the last monitoring window.
Expected result: No active spike in failed script executions.

5. Confirm Service Desk reports for "missing S drive" return to normal baseline.
Expected result: Incident volume drops to expected baseline.

6. Record closure evidence in the incident ticket.
Expected result: Ticket contains command output samples, user confirmation, and Intune status evidence.

## Rollback
Execute rollback immediately if user impact increases or mapping becomes inconsistent.

1. [ELEVATED] Remove assignment of `Map-FinBridgeDrives-UserContext-Remediate` from `FINANCE_TARGET_GROUP`.
Expected result: New remediation stops targeting Finance users.

2. [ELEVATED] Re-enable the last known-good USER logon mapping method for Finance (the pre-migration baseline from change record).
Expected result: Finance mapping returns to previously stable deployment method.

3. [ELEVATED] Force policy refresh on `PILOT_DEVICE_1` by running `gpupdate /force` in an elevated command prompt.
Expected result: User logon mapping policy refresh completes successfully.

4. Ask the test Finance user to sign out and sign back in on `PILOT_DEVICE_1`.
Expected result: Baseline mapping method executes in a new user session.

5. Run `Get-PSDrive -Name S` in the test user session on `PILOT_DEVICE_1`.
Expected result: `S:` is mapped through the baseline method.

6. Repeat steps 3 to 5 on `PILOT_DEVICE_2`.
Expected result: Baseline mapping is restored on second pilot device.

7. Repeat steps 3 to 5 on `PILOT_DEVICE_3`.
Expected result: Baseline mapping is restored on third pilot device.

8. Notify Service Desk that rollback is active and pause broader rollout.
Expected result: Frontline teams stop forward-remediation instructions and follow rollback comms.

9. Open a Problem record for root-cause follow-up before retrying migration.
Expected result: Further changes are blocked until corrective actions are approved.

## Notes
- This incident was caused by moving USER-context mapping logic to SYSTEM context without redesign.
- SYSTEM context and USER context are not interchangeable for drive mapping and share access.
- Startup timing matters: network services can become available after script execution starts.
- Keep retry logic for transient startup conditions (minimum 3 attempts with delay).
- If `S:` is already used for another business mapping on any endpoint, stop and resolve drive-letter conflict before deployment.
- Related incident records:
  - `RCA-finance-shared-drive-access-failure-2024-03-15.md`
  - `RCA-cthompson-account-lockout-2024-03-15.md`
  - `RCA-avd-black-screen-POOL-FIN-01-2024-03-15.md`
