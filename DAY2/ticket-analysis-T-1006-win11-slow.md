# Ticket Analysis: T-1006 'Everything is Slow' — User Upgraded to Win11 Two Days Ago

## Summary
System performance degradation across all applications following Windows 11 upgrade two days ago; post-upgrade driver, indexing, or resource contention issue.

## Impact
- **Affected User/Group:** 1 user
- **Business Urgency:** **MEDIUM** – significant productivity impact; user can work but with delay and frustration; not a blocker unless system becomes unresponsive
- **Scope:** Single device post-upgrade

## Known Facts
- Trigger event: Windows 11 upgrade completed ~2 days ago
- Symptom scope: "Everything" slow (system-wide, not application-specific)
- Timing: Slowness started immediately post-upgrade or in first 1-2 days (suggests background processes/indexing running during that window)

## Missing Information to Gather
1. **Upgrade type & source** – to-verify; in-place Win10→Win11 upgrade, clean install, or OS deployment image?
2. **Device hardware specs** – to-verify; CPU, RAM, storage type (HDD/SSD); if borderline for Win11 minimum requirements, that's root cause
3. **Specific slowness symptoms** – to-verify; which operations are slow:
   - Boot/logon time?
   - App launch time?
   - File system operations (copy, save, search)?
   - Network operations?
   - All operations equally or selective?
4. **Baseline performance pre-upgrade** – to-verify; was Win10 system fast? Or was it already slow?
5. **Current resource utilization** – to-verify; check CPU, RAM, disk % usage during slowness (likely Windows Search indexing or Update Orchestrator running)
6. **Windows Update status** – to-verify; is Windows Update still running, or is post-upgrade patching in progress? (common cause of first 48-72 hrs slowness)
7. **Driver status post-upgrade** – to-verify; are all hardware drivers installed? Any unknown devices in Device Manager?
8. **Antivirus/security software** – to-verify; is third-party AV scanning during upgrade? Some AV tools re-scan entire disk post-OS upgrade
9. **Background apps & startup items** – to-verify; have users installed new apps during upgrade? Are unnecessary startup programs running?
10. **Disk space available** – to-verify; is C: drive near capacity? (Windows 11 requires free space for indexing and temp operations)
11. **Virtual Memory/paging** – to-verify; if RAM insufficient, system may be paging heavily to disk (signs: disk light always on, high disk queue)

## Likely Category
- **Primary:** Post-Upgrade System Optimization (Windows Search indexing, Windows Update patches running, or driver installation ongoing)
- **Secondary:** Hardware Limitation (device RAM/CPU/storage below optimal for Win11, or becoming bottleneck after upgrade overhead)
- **Tertiary:** Driver/Compatibility (GPU driver missing, AHCI/NVMe driver not properly loaded, or chipset driver outdated)
- **Quaternary:** Malware/Security (infection or aggressive security tool scan triggered by file system changes during upgrade)

## First Diagnostic Step
1. **Task Manager snapshot:** Have user open Task Manager → Performance tab; capture CPU, RAM, disk, and network utilization during slowness. Screenshot or note % and which processes are consuming resources.
2. **Windows Update status check:** Settings → Update & Security → Windows Update; check if updates are installing or pending restart. If yes, allow to complete and reboot.
3. **Windows Search indexing status:** Settings → Indexing Options or search "Indexing Options"; verify if search is actively indexing (common for first 24-48 hrs post-upgrade). If so, advise user slowness will improve after indexing completes.
4. **Disk space check:** File Explorer → C: Drive properties; ensure at least 10-15% free space available (Win11 requires free space for operations)
5. **Device Manager driver audit:** Check Device Manager for unknown devices or devices with warning/error icons; update drivers if available
6. **Disk check:** Run `chkdsk /F` (scheduled at next reboot) or `sfc /scannow` to check for file system or system file issues introduced during upgrade
7. **Performance Baseline:** If basic checks are clear, run built-in Windows Performance Recorder or third-party tool (to-verify: tool options; do not invent tool names) to identify slowness bottleneck
8. **Escalation:** If Updates/Search/drivers are complete and slowness persists → escalate to higher tier for deeper diagnostics (Performance Monitor logs, malware scan, or hardware diagnostics)

---

**Analysis Prepared By:** DWP Service Desk (AI-assisted)  
**Date:** 2026-08-13  
**Status:** Awaiting Task Manager/resource snapshot and Windows Update status  
**Verification Required:** Capture real-time resource utilization; verify Windows Update and indexing are not actively running; confirm disk space available; check driver status in Device Manager
