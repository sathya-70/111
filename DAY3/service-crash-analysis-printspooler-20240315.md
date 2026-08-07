# Service Crash Analysis — Print Spooler (spoolsv.exe)

**Date:** 2024-03-15  
**Analyst:** DWP Desktop/Endpoint Engineer  
**Source:** Windows System Event Log  
**Service in scope:** Print Spooler (spoolsv.exe)  

---

## Event Summary

| Time | Source | Event ID | Level | Description |
|------|--------|----------|-------|-------------|
| 10:01:14 | Service Control Manager | 7034 | Error | Print Spooler terminated unexpectedly — occurrence 1 |
| 10:01:45 | Service Control Manager | 7034 | Error | Print Spooler terminated unexpectedly — occurrence 2 |
| 10:02:16 | Service Control Manager | 7034 | Error | Print Spooler terminated unexpectedly — occurrence 3 |
| 10:02:47 | Service Control Manager | 7031 | Error | Print Spooler terminated unexpectedly — occurrence 4; auto-restart scheduled in 60s |
| 10:03:49 | Service Control Manager | 7023 | Error | Print Spooler terminated with error: The specified module could not be found |
| 10:03:50 | Service Control Manager | 7038 | Error | Print Spooler unable to log on as NT AUTHORITY\SYSTEM — logon type not granted |

---

## Technical Detail

| Field | Value |
|-------|-------|
| Service name | Print Spooler |
| Binary | spoolsv.exe |
| Expected logon account | NT AUTHORITY\SYSTEM |
| Crash loop start | 10:01:14 |
| Total crash occurrences | 4 (within ~2 minutes) |
| Service recovery action triggered | Yes — restart after 60000 ms (Event 7031) |
| Terminal error (crash 5) | Error 126 — The specified module could not be found |
| Secondary error | Logon failure — requested logon type not granted |
| Crash loop duration | ~2 minutes 36 seconds (10:01:14 – 10:03:50) |

---

## Event ID Reference

| Event ID | Meaning |
|----------|---------|
| 7034 | Service terminated unexpectedly (generic — no structured error code) |
| 7031 | Service terminated unexpectedly; recovery action configured and will be triggered |
| 7023 | Service terminated with a specific Win32 error code |
| 7038 | Service failed to log on under its configured account |

---

## Analysis

### 1. Crash Loop Pattern (Events 7034 / 7031)

The service crashed four times in rapid succession:

- Occurrences 1–3 (Events 7034): The Service Control Manager recorded each uncontrolled termination without a structured error code. This indicates the process exited abnormally (non-zero exit or access violation) before the SCM could capture a specific error.
- Occurrence 4 (Event 7031): The SCM recognised the repeated failure and triggered the configured recovery action — a service restart after 60 seconds.

The tight timing (roughly every 30 seconds per crash) indicates no meaningful work is being performed between restarts. The service is crashing immediately or very shortly after launch on each attempt.

### 2. Missing Module Error — Error 126 (Event 7023)

After the recovery restart, Event 7023 fired with **"The specified module could not be found"** — Win32 Error 126. This is the most diagnostic event in the sequence and points directly at a corrupted or missing dependency.

Likely causes:
- A print driver DLL or printer processor DLL referenced in the registry (under `HKLM\SYSTEM\CurrentControlSet\Control\Print\`) has been deleted, moved, or corrupted.
- A third-party print driver `.dll` is registered but the corresponding file is absent from `%SystemRoot%\System32\spool\drivers\`.
- A Windows Update or security patch partially removed or replaced a spooler-related component without completing cleanly.
- PrintNightmare remediation activity (common around this period) may have removed or quarantined a vulnerable but still-referenced driver file.

### 3. Logon Failure for NT AUTHORITY\SYSTEM (Event 7038)

Event 7038 states the spooler **could not log on** as `NT AUTHORITY\SYSTEM` due to the requested logon type not being granted. This is an unusual secondary failure because `SYSTEM` is a built-in account and should always have local logon rights.

Likely causes:
- A Group Policy Object (GPO) has been applied that explicitly restricts the **"Log on as a service"** or **"Log on locally"** right, inadvertently removing `NT AUTHORITY\SYSTEM` or `NT SERVICE\Spooler`.
- A recent security hardening baseline (e.g., CIS benchmark rollout, NCSC hardening) modified `User Rights Assignment` and unintentionally affected system service accounts.
- Local Security Policy (`secpol.msc`) has been manually or scripted-modified on the endpoint.

This error appearing immediately after the module-not-found error suggests the spooler attempted a recovery restart and failed at the logon stage before even reaching the missing DLL — the two failures compound each other.

---

## Probable Root Causes (Ranked)

### 1. Corrupt or Missing Print Driver DLL (Most Probable)
- A registered print driver references a `.dll` that is no longer present on disk.
- Every restart attempt loads the driver list from registry and fails immediately when the file cannot be located.
- Consistent with Error 126 and the rapid crash loop with no recovery.

**Evidence:** Event 7023 — "The specified module could not be found."

### 2. GPO / Security Baseline Removed SYSTEM Logon Rights (High Probability — Compounding)
- A hardening policy change modified `User Rights Assignment`, removing or restricting the logon type required by the spooler service.
- This would prevent a clean restart even if the driver issue were resolved.

**Evidence:** Event 7038 — logon type not granted for NT AUTHORITY\SYSTEM.

### 3. Incomplete Windows Update or Patch Rollback (Contributing)
- A partially applied update or a rollback may have left the spooler subsystem in an inconsistent state — some files updated, others not, with registry pointers no longer valid.

### 4. PrintNightmare Mitigation Activity (Possible Context)
- CVE-2021-34527 mitigations involved restricting or removing printer drivers. If a remediation script ran recently and removed driver files without cleaning up registry entries, orphaned registry references would trigger Error 126 on every load.

---

## Impact Assessment

| Category | Detail |
|----------|--------|
| **Service impact** | Print Spooler unavailable; all printing functionality offline on affected endpoint(s) |
| **User impact** | Users unable to print locally or to network printers via this endpoint |
| **Security impact** | Print Spooler offline reduces PrintNightmare attack surface — no active exploit risk during outage |
| **Data impact** | None — no data loss or unauthorised access indicated |
| **Recurrence risk** | High — crash loop will resume on every restart until root cause is remediated |

---

## Recommended Remediation Steps

> **Note:** Validate all steps in a non-production environment first. Apply per DWP change management process.

### Step 1 — Identify the Offending Driver or Module

```powershell
# List all registered print drivers
Get-PrinterDriver | Select-Object Name, InfPath, PrinterEnvironment | Format-List

# Check for driver files referenced in registry that may be missing
$driverPath = "$env:SystemRoot\System32\spool\drivers"
Get-ChildItem $driverPath -Recurse -ErrorAction SilentlyContinue | Select-Object FullName
```

- Cross-reference registry entries under `HKLM\SYSTEM\CurrentControlSet\Control\Print\Environments\Windows x64\Drivers` against files present on disk.
- Any registry entry pointing to a non-existent `.dll` is the likely trigger for Error 126.

### Step 2 — Remove Orphaned or Corrupt Drivers

```powershell
# Stop dependent services before driver removal
Stop-Service -Name Spooler -Force -ErrorAction SilentlyContinue

# Remove a specific offending driver (replace <DriverName> with identified driver)
Remove-PrinterDriver -Name "<DriverName>" -ErrorAction SilentlyContinue
```

### Step 3 — Restore SYSTEM Logon Rights via GPO/Local Policy

- Open `secpol.msc` > Local Policies > User Rights Assignment.
- Verify `NT AUTHORITY\SYSTEM` and `NT SERVICE\Spooler` are present in:
  - **Log on as a service**
  - **Log on locally** (if applicable)
- If managed via GPO: review the relevant GPO in Group Policy Management Console (GPMC) and confirm the policy does not explicitly remove SYSTEM from these rights.
- Run `gpresult /h gpresult.html` on the affected endpoint to identify the winning GPO for User Rights Assignment.

### Step 4 — Restart and Validate

```powershell
Start-Service -Name Spooler
Get-Service -Name Spooler | Select-Object Status, StartType
```

- Confirm service enters `Running` state and remains stable for at least 5 minutes.
- Check System event log for absence of 7034/7031/7023/7038 events.

### Step 5 — Escalation Path (If Not Resolved)

- If Error 126 persists after driver removal: run `sfc /scannow` and `DISM /Online /Cleanup-Image /RestoreHealth` to repair system file integrity.
- If logon error persists after local policy correction: escalate to endpoint/GPO team to review security baseline deployment targeting this device or OU.

---

## Prevention Recommendations

| Recommendation | Rationale |
|----------------|-----------|
| Audit registered print drivers before and after any patch cycle | Orphaned driver registry entries from removed DLLs are a known spooler destabiliser |
| Include `NT AUTHORITY\SYSTEM` in User Rights Assignment change testing | Hardening baselines must be validated against service account logon requirements |
| Monitor Event IDs 7034 / 7031 / 7023 via SIEM or endpoint monitoring | Early alerting on crash loops prevents prolonged outage |
| Review PrintNightmare mitigation scripts for registry cleanup completeness | Partial mitigations leave orphaned references that trigger Error 126 |
| Apply Point-in-Time Recovery (restore) driver store backup pre-patching | Enables rapid rollback if a patch removes a required driver file |

---

## Classification

| Field | Value |
|-------|-------|
| **Document status** | Draft — pending engineer review |
| **Classification** | OFFICIAL |
| **Author** | DWP Desktop/Endpoint Engineer |
| **Review date** | 2024-03-22 |
| **Incident reference** | INC-[REDACTED] |

---

*AI-generated draft. Engineer must review all findings, validate against live environment data, and confirm remediation steps before action. Do not action without peer review and change approval.*
