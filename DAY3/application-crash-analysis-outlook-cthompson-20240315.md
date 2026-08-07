# Root Cause Analysis — OUTLOOK.EXE Crash (cthompson)

**Date:** 2024-03-15  
**Analyst:** DWP Desktop/Endpoint Engineer  
**Source:** Windows Application Event Log  
**User in scope:** cthompson  

---

## Event Summary

| Time | Source | Event ID | Level | Description |
|------|--------|----------|-------|-------------|
| 09:14:22 | Application Error | 1000 | Error | OUTLOOK.EXE crash — Access Violation in KERNELBASE.dll |
| 09:17:45 | Application Error | 1000 | Error | OUTLOOK.EXE crash — repeat, identical fault offset |
| 09:18:01 | Windows Error Reporting | 1001 | Information | WER bucket raised; APPCRASH — no cab captured |
| 09:18:05 | .NET Runtime | 1026 | Error | Unhandled System.AccessViolationException — process terminated |

---

## Technical Detail

| Field | Value |
|-------|-------|
| Faulting application | OUTLOOK.EXE v16.0.17126.20132 |
| Faulting module | KERNELBASE.dll v10.0.22621.3155 |
| Exception code | 0xc0000005 (STATUS_ACCESS_VIOLATION) |
| Fault offset | 0x000000000003a4b2 (identical in both crashes) |
| Application start time | 09:13:44 |
| First crash | 09:14:22 (~38 seconds after launch) |
| .NET exception type | System.AccessViolationException |
| Framework | v4.0.30319 |
| Process ID | 0x1f4c |
| Report ID | a3c2f1d4-89bb-4e21-91d7-f2c3a1b09e44 |
| Faulting application path | C:\Program Files\Microsoft Office\root\Office16\OUTLOOK.EXE |
| Faulting module path | C:\Windows\System32\KERNELBASE.dll |

---

## Root Cause Statement

The Outlook crash is caused by a deterministic access violation (`0xc0000005`) during startup in a repeatable execution path (`KERNELBASE.dll` offset `0x000000000003a4b2`). Based on timing and repeatability, the most probable technical trigger is a corrupted Outlook runtime state (profile/OST and/or startup add-in path) that is loaded automatically within ~38 seconds of launch, resulting in `System.AccessViolationException` and process termination.

---

## Analysis

### 1. Exception Code: 0xc0000005 — Access Violation

The process attempted to read or write a memory address it was not permitted to access. This maps directly to `System.AccessViolationException` seen in Event 1026. This is not a standard application error — it indicates a low-level memory access failure.

### 2. Consistent Fault Offset

Both crashes share the identical offset `0x000000000003a4b2` in KERNELBASE.dll. A repeating fault at the same offset confirms:
- A deterministic, reproducible code path is being triggered.
- The crash is not random or resource-related (e.g., low memory).
- A specific trigger on startup (add-in load, profile read, MAPI init) is reliably hitting this path.

### 3. Crash Timing — 38 Seconds Post-Launch

Outlook launched at 09:13:44 and crashed at 09:14:22. This timing is consistent with:
- Profile/OST file load phase.
- COM/MAPI provider initialisation.
- Add-in loading sequence.

This rules out a crash on a user-initiated action; it is occurring during automated startup tasks.

### 4. Repeat Crash at 09:17:45

A second launch was attempted ~3 minutes later with an identical crash. No change in behaviour, confirming the root cause was not transient.

### 5. Correlation with Account Lockout Incident

The account lockout for cthompson was confirmed at 08:44:56 (Event 4740). The Outlook crash begins at 09:13:44 — approximately 29 minutes later, consistent with:
- Account being unlocked and cthompson attempting to resume work.
- Outlook launching and attempting to reconnect to Exchange/M365 using a potentially stale or corrupt cached credential/profile state.
- An OST file that may have been left in an inconsistent state when the session was interrupted during lockout.

### 6. Why This Is Root Cause and Not Symptom

- Two Event ID 1000 crashes share the same application version, module version, exception code, and fault offset.
- Event ID 1026 confirms an unhandled `System.AccessViolationException`, aligning with low-level memory access failure.
- Event ID 1001 confirms APPCRASH telemetry for the same sequence.
- The reproducible timing after launch indicates a startup component path, not random user action.

---

## Probable Root Causes (Ranked)

### 1. Corrupt Outlook Profile or OST File (Most Probable)
- The account lockout likely interrupted an active Outlook session mid-write.
- An inconsistent OST or corrupt profile can cause a MAPI access violation on reload.
- The deterministic fault offset strongly supports a consistent bad state being read on each launch.

### 2. Conflicting or Incompatible COM Add-in
- Add-ins are loaded ~30 seconds post-launch, matching the crash window.
- A managed (.NET) add-in that dereferences a null or invalid pointer would produce `System.AccessViolationException`.
- Consistent offset may indicate the same add-in failing every time.

### 3. MAPI/Exchange Provider Credential State Issue
- Following a lockout and credential reset, MAPI providers may hold stale token/credential handles.
- Attempting to use an invalidated handle can trigger an access violation in KERNELBASE.dll.

Confidence level:
- High confidence in deterministic startup crash pattern.
- Medium confidence that profile/OST corruption is the primary trigger until Safe Mode and profile rebuild tests are completed.

---

## Recommended Resolution Steps

1. **Launch Outlook in Safe Mode** to immediately isolate add-ins:
   ```
   outlook.exe /safe
   ```
   If Outlook starts successfully, an add-in is the cause — disable add-ins one at a time to identify the offender.

2. **Rebuild the Outlook Profile** if safe mode also crashes:
   - Control Panel → Mail → Show Profiles → Remove and recreate the profile for cthompson.
   - Delete or rename the existing OST file (typically `%LOCALAPPDATA%\Microsoft\Outlook\`) before creating the new profile to force a clean resync.

3. **Run the Outlook repair tool** if profile rebuild is not immediately feasible:
   ```
   scanpst.exe
   ```
   Target the cthompson OST file path.

4. **Clear MAPI credential cache** (if Exchange/M365 credential state is suspected):
   - Open Windows Credential Manager → Windows Credentials.
   - Remove any MicrosoftOffice, MicrosoftExchange, or O365 entries.
   - Restart Outlook.

5. **Review installed COM add-ins** via:
   - File → Options → Add-ins → Manage COM Add-ins → Go.
   - Disable all non-essential add-ins and re-enable incrementally.

6. **Patch check**: Confirm OUTLOOK.EXE v16.0.17126.20132 is the current patched build; if a known crash bug exists at this version, apply the latest update.

7. **Monitor**: After resolution, verify no further Event ID 1000 entries for OUTLOOK.EXE in Application log.

---

## Follow-Up Actions

| Action | Owner | Priority |
|--------|-------|----------|
| Launch Outlook /safe and test | Desktop Engineer | Immediate |
| Rebuild profile / clear OST if safe mode fails | Desktop Engineer | Same day |
| Clear Credential Manager entries | Desktop Engineer | Same day |
| Verify Outlook patch level and update if required | Desktop Engineer | Same day |
| Confirm no recurrence after fix and close incident | Desktop Engineer | Within 1 hour of fix |

---

## Closure Criteria

- Outlook opens normally in standard mode.
- No further Event ID 1000 (`Application Error`) for `OUTLOOK.EXE` for at least one business day.
- No further Event ID 1026 (`.NET Runtime`) for `OUTLOOK.EXE` on the same endpoint.
- User confirms normal send/receive, calendar open, and mailbox sync.

---

## Notes

- No PII, credentials, or internal hostnames have been included in this document.
- Analysis is based solely on sanitised event log data provided.
- All recommendations are draft; the responsible engineer must validate against the live endpoint before applying changes.
- This document relates to the same incident date as the cthompson account lockout (RCA: DAY4/RCA-cthompson-account-lockout-2024-03-15.md).
