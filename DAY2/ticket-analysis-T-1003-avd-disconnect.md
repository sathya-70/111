# Ticket Analysis: T-1003 AVD Session Disconnects After ~10 Minutes, Then Reconnects

## Summary
Azure Virtual Desktop session automatically disconnects after approximately 10 minutes of use, then reconnects (possible auto-reconnect policy or idle timeout misconfiguration).

## Impact
- **Affected User/Group:** 1 user (unless part of wider session management issue affecting multiple users - to-verify)
- **Business Urgency:** **MEDIUM-HIGH** – productivity disruption; session loss interrupts work, though auto-reconnect mitigates data loss; pattern suggests configuration issue
- **Scope:** Single user session + potential fleet policy issue

## Known Facts
- Symptom: Disconnection is predictable (consistent ~10 min interval; not random)
- Auto-reconnect behavior observed (suggests policy-managed reconnection, not hard failure)
- Issue pattern suggests timeout or idle policy rather than network/resource exhaustion

## Missing Information to Gather
1. **User activity during disconnection** – to-verify; is disconnection linked to idle time or user activity, or purely time-based?
2. **AVD host pool & session type** – to-verify; pooled or personal, Win10/Win11/Server, Remote App or full desktop?
3. **Disconnection trigger** – to-verify; observe Event Viewer logs on AVD host (exact event IDs to-verify; check for session timeout, idle policy, policy reapply events)
4. **RDP timeouts configured** – to-verify; check Group Policy: Computer Configuration → Administrative Templates → Windows Components → Remote Desktop Services → Session Time Limits (exact policy names and values to-verify)
5. **User's local time zone vs. tenant/host time** – to-verify; clock skew can trigger auth/session policy misalignment
6. **Latency/connection quality** – to-verify; is there intermittent network loss that looks like disconnection?
7. **OneDrive/file sync during disconnect** – to-verify; is user syncing large files? (known to cause apparent session hangs)
8. **Other users on same host pool** – to-verify; is this isolated or fleet-wide?
9. **Recent policy changes or host pool updates** – to-verify; new GPO, WVD agent update, or session limits policy change?

## Likely Category
- **Primary:** Configuration/Policy (session timeout, idle time limit, or policy reapply interval set to ~10 min)
- **Secondary:** Network (intermittent disconnect due to WiFi, VPN, or latency; client thinks session lost and reconnects)
- **Tertiary:** Host/Resource (AVD host memory pressure, resource contention, or session policy conflict)

## First Diagnostic Step
1. **User observation:** Capture exact activity timeline; is disconnection predictable at 10 min regardless of user action, or tied to idle?
2. **Event Viewer check:** On AVD host, check System & Security logs for session timeout or disconnection events near disconnect time
3. **Group Policy audit:** Review applied GPO on user/host for Remote Desktop Session Host timeouts and idle limits (look for policies with "Session Time Limit" or "Idle Time Limit" - to-verify actual policy names)
4. **RDP client logs:** Check user's RDP client for disconnect reason codes (to-verify: %temp%\rdp logs or similar; exact location OS-dependent)
5. **Reconnect behavior audit:** Confirm auto-reconnect is policy-driven (check client-side or host-side auto-reconnect settings - to-verify specific setting locations)
6. **Escalation:** If 10-min pattern is exact and policy-driven → remove or raise timeout limits; if intermittent/network-based → test connection quality and review WiFi/VPN settings

---

**Analysis Prepared By:** DWP Service Desk (AI-assisted)  
**Date:** 2026-08-13  
**Status:** Awaiting activity logs and event viewer output  
**Verification Required:** Determine if time-based or idle-based; verify applied policies; check event logs for root cause
