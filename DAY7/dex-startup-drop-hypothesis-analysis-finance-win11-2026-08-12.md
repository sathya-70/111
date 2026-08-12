# DEX Startup Performance Drop — Hypothesis Analysis
## Finance-Win11 | 2026-08-04 Config Change

**Date:** 2026-08-12
**Device group:** Finance-Win11 (215 devices)
**Analyst:** DWP Endpoint Team

---

## Ranked Hypotheses

---

### Hypothesis 1 — Startup script running synchronously, blocking login completion
**Probability: Highest**

**Why it fits:**
The compliance logging startup script was deployed at 02:00 on 2026-08-04, and the degradation appears in full on the very first boot measurement that day — a 23.8-second increase with no gradual drift. Startup scripts assigned via policy run synchronously by default, meaning the desktop does not become usable until the script finishes. A script contacting a logging endpoint, waiting for a network response, or performing file writes before completing would add directly and consistently to the login-to-usable-desktop time. IT-Win11 received no script and shows no change, which is exactly what you would expect if the script is the cause.

**Fastest check:**
On an affected Finance-Win11 device, open Event Viewer → Applications and Services Logs → Microsoft → Windows → GroupPolicy → Operational. Filter for Event ID 4016 (startup script processing start) and 4017 (end). The elapsed time between them will show whether the script is the source of the delay and how long it is running.

---

### Hypothesis 2 — Additional Defender scan policy triggering a scan at login
**Probability: Medium**

**Why it fits:**
The config change explicitly added a new Defender scan policy to Finance-Win11. If this policy schedules or triggers a scan at device startup or user login, it will drive high CPU and disk I/O during the period the user is waiting for the desktop to become usable — consistent with a sustained ~42-second median across all three post-change days. The flat, stable IT-Win11 scores confirm this is not a platform-wide Defender update; it is something applied only to Finance-Win11.

**Fastest check:**
On an affected device, open Windows Security → Virus & threat protection → Protection history and check whether a scan ran within minutes of the affected login times. Alternatively, run `Get-MpComputerStatus` in PowerShell and check `LastFullScanTime` and `LastQuickScanTime` against login timestamps for the same device.

---

### Hypothesis 3 — Security baseline profile extending synchronous policy processing
**Probability: Lower**

**Why it fits:**
Security baseline profiles can introduce a large number of new CSP or Group Policy settings applied synchronously before the shell loads. If the baseline added settings that require foreground policy processing (such as software restriction, AppLocker rules, or credential guard configuration), Windows may enforce synchronous application, extending the policy processing phase. The timing matches the deployment, and again IT-Win11 was not in scope and shows no impact. This hypothesis is ranked lower because policy processing delays of ~24 seconds would be unusually large for settings alone; scripts and scans are more commonly the direct cause of delays of this magnitude.

**Fastest check:**
On an affected device, run `gpresult /h gp-report.html` and open the report. Check the Startup (Computer) section for any policies flagged as running in foreground/synchronous mode and their reported processing duration. Compare against a device in IT-Win11 where the baseline was not applied.

---

## Summary

| Rank | Hypothesis | Key evidence alignment | Fastest check |
|---|---|---|---|
| 1 | Startup script blocking login | Exact timing match; direct 1:1 mechanism for delay | Event Viewer — GroupPolicy Operational, Event ID 4016/4017 |
| 2 | Defender scan at login | Sustained high delay across all post-change days; scan policy explicitly cited in change log | Windows Security — Protection history; `Get-MpComputerStatus` |
| 3 | Baseline profile extending policy processing | Timing matches; lower probability given magnitude of delay | `gpresult /h` — foreground policy processing durations |

> **Note:** Hypotheses 1 and 2 are not mutually exclusive. Both changes were deployed simultaneously and both could be contributing to the total delay. The checks above will quantify each component separately.
