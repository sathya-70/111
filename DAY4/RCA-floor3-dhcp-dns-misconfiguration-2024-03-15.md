# Root Cause Analysis (RCA)

## Incident
- Title: Floor 3 Windows 11 machines unable to authenticate — DHCP scope referencing decommissioned DNS server
- Incident date: 2024-03-15
- RCA prepared: 2026-08-07
- Service: Domain authentication, Group Policy, network drive access
- Affected machines: DESKTOP-FB055, DESKTOP-FB056, DESKTOP-FB057 (Floor 3, 10.10.3.0/24 subnet)
- Unaffected machine: DESKTOP-FB058 / DESKTOP-FB029 (same OU, manually pre-configured)
- Resolution confirmed: Pending DHCP scope correction and client renewal

## Executive Summary
On the morning of 2024-03-15, three Windows 11 machines on Floor 3 were unable to complete domain authentication, receive Group Policy, or access network resources. The failures began shortly after boot, when affected machines received DHCP leases with DNS server 10.10.3.250 (also recorded as 172.16.5.5 in DHCP server logs) — a Floor 3 local DNS server that had been decommissioned as part of an overnight migration wave at 02:00 on 2024-03-14.

With no valid DNS, the machines could not resolve the domain controller hostname (FINBRIDGE-DC01.finbridge.local), breaking Netlogon secure channel establishment and all subsequent Group Policy processing. A fourth machine on the same subnet (DESKTOP-FB058) was unaffected because it had been manually pre-configured with the correct DNS server (10.10.0.10) before the migration wave.

The root cause is a missed DHCP scope update: the Floor 3 subnet scope was not updated to reference the new central DNS server during the migration, leaving all DHCP clients on that subnet pointing to a decommissioned resolver.

## Impact Assessment
- Machines affected: 3 (DESKTOP-FB055, FB056, FB057)
- Symptom: Unable to authenticate to domain; Group Policy not applied; network drives and domain resources inaccessible
- Business impact: Users on Floor 3 blocked from domain-dependent workloads during morning login period
- Blast radius: Confined to Floor 3 subnet (10.10.3.0/24); any machine receiving a DHCP lease on this subnet after 02:00 on 2024-03-14 would be affected

## Timeline (All times local, 2024-03-15)
- 2024-03-14 02:00: DNS migration wave executed. Old DNS server (10.10.3.250 / 172.16.5.5) decommissioned. DHCP scope for Floor 3 subnet (10.10.3.0/24) not updated — still references 10.10.3.250.
- 07:40:02: Network Location Awareness service enters running state on affected machine (Service Control Manager Event 7036).
- 07:40:08: Netlogon Event 5719 (Error) — secure channel to FINBRIDGE cannot be established; DNS query for FINBRIDGE-DC01.finbridge.local returns no response.
- 07:40:09: GroupPolicy Event 1058 (Error) — GP processing failed; cannot access \\FINBRIDGE-DC01\sysvol\finbridge.local\Policies (error 0x3).
- 07:40:10: GroupPolicy Event 1030 (Warning) — cannot query list of Group Policy objects (error 0x546).
- 07:40:11: GroupPolicy Event 1058 (Error) — GP processing failed again.
- 07:40:12: GroupPolicy Event 1129 (Error) — GP failed due to no network connectivity to a domain controller.
- 07:41:05: DNS Client Events Event 1014 (Warning) — name resolution for FINBRIDGE-DC01.finbridge.local timed out; none of the configured DNS servers responded.
- 07:42:18: DHCP Client Event 50036 (Information) — IP address 10.10.3.144 leased from server 10.10.0.1; DNS server assigned: 10.10.3.250 (decommissioned).
- 07:44:01: GroupPolicy Event 1129 (Error) — GP processing failed again; no DC connectivity.

## Supporting Evidence

### Affected Machines: DESKTOP-FB055, FB056, FB057 (Floor 3)
- Netlogon Event 5719 at 07:40:08: secure channel setup failed; DC not reachable via DNS.
- GroupPolicy Event 1058 at 07:40:09 and 07:40:11: sysvol path unreachable (error 0x3 — path not found, caused by DNS failure upstream).
- GroupPolicy Event 1129 at 07:40:12 and 07:44:01: GP explicitly reports no DC network connectivity.
- DNS Client Event 1014 at 07:41:05: all configured DNS servers unresponsive.
- DHCP Event 50036 at 07:42:18: lease obtained from 10.10.0.1; DNS option assigned as 10.10.3.250 — confirms fault originates in DHCP scope configuration, not the machine itself.
- DHCP server logs: FB055–FB057 all assigned DNS 172.16.5.5 (Floor 3 local DNS — decommissioned 2024-03-14 overnight).

### Comparison Machine: DESKTOP-FB058 / DESKTOP-FB029 (same OU — unaffected)
- DHCP Event 50036 at 07:40:05: IP 10.10.3.141 leased; DNS assigned: 10.10.0.10 (correct central DNS).
- GroupPolicy Event 1500 at 07:40:11: Group Policy settings processed successfully.
- DHCP server logs: FB058 DNS assigned 10.10.0.10 — machine was manually pre-configured before migration wave.

### Correlation and Scope Signals
- Failure is subnet-scoped: all DHCP clients on Floor 3 subnet receive the decommissioned DNS server.
- Single-change difference: FB058 was manually pre-configured before the migration; all other Floor 3 machines rely on DHCP.
- No machine-level fault: hardware, OS, and domain membership are intact on affected devices; failure is entirely driven by incorrect DNS assignment.

## Confirmed Root Cause
The DHCP scope for the Floor 3 subnet (10.10.3.0/24) was not updated during the DNS migration wave on 2024-03-14. As a result, affected machines were assigned the decommissioned DNS server (10.10.3.250 / 172.16.5.5) via DHCP. With no functional DNS resolver, the machines could not resolve the domain controller hostname, breaking Netlogon secure channel establishment and all Group Policy processing downstream.

## Contributing Factors
- The DNS migration checklist did not include verification of all DHCP scopes referencing the decommissioned DNS servers before decommission.
- No automated alerting was in place to detect DHCP scopes still referencing decommissioned infrastructure.
- The manual pre-configuration of FB058 masked the scope misconfiguration during pre-migration testing, as this machine was used as a validation reference.

## 5 Whys Analysis
1. Why were Floor 3 machines unable to authenticate to the domain?
Because Netlogon could not establish a secure channel to FINBRIDGE-DC01 — the domain controller was unreachable.

2. Why was the domain controller unreachable?
Because DNS queries for FINBRIDGE-DC01.finbridge.local returned no response — DNS resolution was failing entirely.

3. Why was DNS resolution failing?
Because the machines were assigned a decommissioned DNS server (10.10.3.250) via DHCP and had no functional resolver.

4. Why were machines receiving a decommissioned DNS server via DHCP?
Because the DHCP scope for the Floor 3 subnet (10.10.3.0/24) was not updated to reference the new central DNS server (10.10.0.10) during the migration wave.

5. Why was the DHCP scope not updated?
Because the DNS migration procedure did not include a step to audit and update all DHCP scopes referencing the servers being decommissioned before cutover.

## Remediation Actions

### Immediate (same day)
- Update DHCP scope option 006 (DNS Servers) for subnet 10.10.3.0/24 to 10.10.0.10.
- On each affected machine, run `ipconfig /release` followed by `ipconfig /renew` to obtain a corrected lease.
- Verify DNS resolution: `nslookup FINBRIDGE-DC01.finbridge.local` should resolve successfully.
- Run `gpupdate /force` on each machine and confirm GroupPolicy Event 1500 (success) in Event Viewer.

### Short-Term (0-7 days)
- Audit all remaining DHCP scopes across all subnets for any remaining references to 10.10.3.250 or 172.16.5.5.
- Remediate any additional scopes found before further client renewals occur.
- Confirm no other subnets received an incomplete DHCP update during the migration wave.

### Process Improvements (1-4 weeks)
- Add a mandatory pre-decommission checklist item: enumerate all DHCP scopes referencing the target DNS server and confirm updates are complete before cutover.
- Implement post-migration validation: automated query of all DHCP scopes to confirm no references to decommissioned infrastructure exist.
- Add monitoring alert: flag any DHCP lease assignment where the DNS server IP matches a decommissioned server list.
- Update migration runbook to include a DHCP scope audit step as a formal go/no-go gate.

### Governance (ongoing)
- Maintain a decommission dependency register: before retiring any infrastructure component, identify all services that reference it (DHCP scopes, DNS forwarders, static configs, GPO preferences).
- Require post-migration smoke test on a non-pre-configured client in each affected subnet to validate end-to-end DNS and Group Policy before sign-off.

## Residual Risk
- Any Floor 3 machine that obtained a DHCP lease between 02:00 on 2024-03-14 and the scope correction will continue to use the decommissioned DNS server until its lease is renewed or manually refreshed.
- If additional DHCP scopes on other subnets reference the decommissioned DNS servers and have not been identified, other machines may experience the same failure pattern at next lease renewal.

## Lessons Learned
- A machine pre-configured before a migration is not a valid control to validate DHCP scope correctness; always test with a DHCP-dependent client after scope changes.
- DNS failure cascades silently and rapidly: the failure chain from missing DNS to broken Netlogon to failed Group Policy to inaccessible drives is fully deterministic and fast — first triage step for domain authentication failures should include confirming the assigned DNS server is reachable and correct.
- Decommissioning infrastructure requires a reverse-dependency audit, not just cutover of the new component.

## Appendix A: Event References Used in RCA
- Affected machine — Service Control Manager Event 7036 at 07:40:02.
- Affected machine — Netlogon Event 5719 at 07:40:08.
- Affected machine — GroupPolicy Event 1058 at 07:40:09 and 07:40:11.
- Affected machine — GroupPolicy Event 1030 at 07:40:10.
- Affected machine — GroupPolicy Event 1129 at 07:40:12 and 07:44:01.
- Affected machine — DNS Client Events Event 1014 at 07:41:05.
- Affected machine — DHCP Client Event 50036 at 07:42:18 (IP 10.10.3.144, DNS 10.10.3.250).
- DESKTOP-FB029 — DHCP Client Event 50036 at 07:40:05 (IP 10.10.3.141, DNS 10.10.0.10).
- DESKTOP-FB029 — GroupPolicy Event 1500 at 07:40:11.
- DHCP server log: FB055–FB057 DNS assigned 172.16.5.5; FB058 DNS assigned 10.10.0.10.
