# Ticket Analysis: T-1008 VPN Connects but No Internal Resources Reachable After Win11 Upgrade

## Summary
VPN connection establishes successfully but internal network resources (file shares, servers, applications) remain unreachable following Windows 11 upgrade; network routing or split-tunnel misconfiguration.

## Impact
- **Affected User/Group:** 1 remote user (could scale to fleet if upgrade is wide deployment - to-verify scope)
- **Business Urgency:** **HIGH** – user cannot access internal applications/data; effectively unable to work remotely
- **Scope:** Single device post-upgrade; potentially affects others upgraded simultaneously

## Known Facts
- VPN connection state: Confirmed connected (suggests VPN client tunnel established, authentication successful)
- Symptom: Internal resources unreachable despite VPN active (not a connection failure, but routing/gateway issue)
- Trigger event: Windows 11 upgrade (suggests upgrade broke network configuration, route table, or driver compatibility)
- Network isolation: Cannot reach internal IPs/resources, but likely internet-bound traffic is routing (to-verify; user may not have tested)

## Missing Information to Gather
1. **VPN client type & version** – to-verify; Cisco AnyConnect, Fortinet FortiClient, F5 SSL VPN, OpenVPN, built-in RRAS/IKEv2, or other?
2. **VPN provider compatibility with Win11** – to-verify; has vendor released Win11 support for this client version?
3. **Network interface details** – to-verify; how many NICs post-upgrade? Has upgrade changed NIC enumeration or added virtual adapters?
4. **Resource access target type** – to-verify; are users trying to reach:
   - File shares (SMB/UNC paths)?
   - Intranet web servers (http/https)?
   - Database servers (specific ports)?
   - Other resources?
5. **DNS resolution status** – to-verify; can user resolve internal hostnames (nslookup/ping from cmd)? Or failing to resolve?
6. **VPN routing configuration** – to-verify; is split tunneling enabled (internet bypasses VPN while internal traffic uses VPN)? Or full tunnel (all traffic via VPN)?
7. **Network adapter driver status post-upgrade** – to-verify; are all NIC drivers properly installed? Any devices in Device Manager with warnings?
8. **Firewall status** – to-verify; is Windows Defender Firewall blocking internal traffic? Or third-party firewall (Zone Alarm, etc.)?
9. **Proxy configuration** – to-verify; did Win11 upgrade reset proxy settings? Is user behind corporate proxy requiring reconfiguration?
10. **VPN client connection details** – to-verify; does VPN settings show internal DNS servers assigned? IP address leased in internal range or external?
11. **Upgrade path taken** – to-verify; in-place upgrade, clean install, or provisioned image? (in-place may leave old VPN config orphaned)
12. **Successful VPN history** – to-verify; has VPN worked on this device pre-upgrade? Or new deployment?

## Likely Category
- **Primary:** Network Routing/Tunneling (VPN tunnel established but traffic not routed to internal network, or split tunneling misconfigured)
- **Secondary:** VPN Client Driver/Compatibility (Win11 upgrade broke or deprioritized VPN client; driver not updated for new OS)
- **Tertiary:** Network Interface/Driver (Win11 upgrade changed NIC enumeration, or driver update caused VPN stack incompatibility)
- **Quaternary:** Firewall/Security Policy (Windows Defender Firewall or third-party firewall blocking VPN tunnel or internal traffic post-upgrade)

## First Diagnostic Step
1. **VPN connection verification:**
   - Confirm VPN client shows "Connected" status and displays assigned IP (should be in internal range, e.g., 10.x.x.x or 172.x.x.x)
   - Note the assigned VPN IP address
   - Check if local DNS servers are listed in VPN connection settings (should show internal corp DNS, not public resolver)
2. **DNS resolution test:**
   - Open Command Prompt and run: `nslookup [intranet-hostname]` (e.g., nslookup intranet.company.com)
   - If resolves → DNS working; if fails → DNS not reaching internal DNS servers
3. **Route table inspection:**
   - Run: `route print` or `Get-NetRoute` (PowerShell)
   - Verify routes for internal subnets (e.g., 10.0.0.0/8, 172.16.0.0/12) point to VPN adapter (not local adapter)
   - If routes missing or pointing to wrong adapter → escalate to network/VPN team for route table reset
4. **Ping test to internal resource:**
   - Run: `ping [internal-ip-address]` (e.g., ping 10.1.1.1) or `ping [internal-hostname]`
   - If ping succeeds → IP connectivity working; if fails → blocked by firewall or routing
5. **VPN adapter status & driver check:**
   - Device Manager → Network adapters; find VPN adapter name (e.g., "Cisco AnyConnect Secure Mobility Client")
   - Verify no warning/error icons; if warning present → driver may be incompatible with Win11
   - Check VPN vendor website for Win11-compatible driver update
6. **Windows Firewall rule audit:**
   - Windows Defender Firewall → Advanced Settings → Inbound Rules; look for VPN client rules or internal subnet rules
   - If VPN is blocked, enable or create new rule allowing VPN traffic
7. **VPN client re-authentication/reconnect:**
   - Disconnect VPN
   - Restart VPN client service (or reboot device)
   - Reconnect VPN; observe if routing tables and DNS update correctly
8. **Escalation path:**
   - If DNS resolves and ping works → network connectivity is OK; issue is client app configuration or DNS-based resource discovery (escalate to app support)
   - If DNS fails but route table is correct → internal DNS unreachable; escalate to VPN/network team
   - If VPN adapter has driver warning → escalate to hardware/driver support for Win11-compatible driver
   - If Windows Firewall is blocking VPN → reset firewall rules or create explicit VPN allow rule (to-verify exact rule syntax for environment)

---

**Analysis Prepared By:** DWP Service Desk (AI-assisted)  
**Date:** 2026-08-13  
**Status:** Awaiting VPN connection details and diagnostic command output  
**Verification Required:** Confirm VPN IP is internal range; test DNS resolution; verify route table includes internal subnets; check VPN adapter driver status; verify Windows Firewall not blocking VPN traffic
