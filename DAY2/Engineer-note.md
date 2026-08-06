Root cause:
- Win11 upgrade removed legacy VPN client.
- Intune did not re-deploy new VPN client due to detection-rule gap.

Exact action taken:
- Manually removed stale VPN registry entries under HKLM\SOFTWARE<vendor>.
- Force-triggered Intune sync.
- New VPN client deployed.
- Split-tunnel config applied.

Verification:
- Connectivity confirmed to all internal subnets.

Impact/data:
- No data loss.

Preventive action needed:
- Close the Intune detection-rule gap so post-Win11-upgrade devices reliably trigger re-deployment of the new VPN client.
