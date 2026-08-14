# KB: Floor 6 Incident Cluster (A/B/C) - L2/L3 Diagnostic Guide
v 1.0, 14/08/2026, status : Draft

## Background
- This incident cluster combines three linked failures on Floor 6: A (confidentiality exposure), B (login failures/slowness), C (missing shortcuts).
- System components involved: Copilot connector entitlements, Entra sign-in/session state, Intune app/policy assignments, endpoint profile/shortcut state.
- Why it matters: A is data confidentiality risk, B blocks user access, C impacts productivity. Priority is always A -> B -> C.

## Symptom
- User reports:
  - A: User can retrieve client matter content they should not see.
  - B: Sign-in fails repeatedly or desktop loads very slowly.
  - C: Desktop shortcuts (Edge/Outlook/Teams) disappear.
- Engineer observes:
  - A: Unexpected Copilot retrieval from restricted repository.
  - B: Spike in failed sign-ins and longer time-to-desktop.
  - C: Missing .lnk files on Public Desktop or user desktop.

## Root Cause
- A (Confidentiality): Connector entitlement decision is stale/misaligned with source ACL for the same user and matter.
  - Confirming evidence: ConnectorDecision=Allow while ACLDecision=Deny at same user/matter/timestamp; issue still reproduces after session revoke.
- B (Login): Non-critical Friday app/policy load created sign-in pressure for Floor 6 cohort.
  - Confirming evidence: High Event ID 4625 relative to 4624, then improvement after assignment pause + sync/reboot waves.
- C (Shortcuts): Shortcut deletion/not recreation caused by installer/remediation activity or temporary profile state.
  - Confirming evidence: MsiInstaller or PowerShell activity references .lnk/shortcut; ProfileList .bak/profile-state anomalies on affected device.

## Detection
### A - Unauthorized Client Matter Exposure
1. Confirm connector control state.
   - Log location: M365 admin center > Copilot > Data sources > affected connector.
   - Fields: Connector status, Scope filter, Last index/crawl time.
   - Look for: Enabled scope includes Floor 6 during reported exposure window.
2. Confirm ACL vs connector mismatch from evidence pack.
   - Log location: c:\temp\incident-a-evidence\corrected-action-checklist.csv and corrected-group-change-events.csv.
   - Fields: UserPrincipalName, MatterId, ACLDecision, ConnectorDecision, Timestamp.
   - Look for: Same UserPrincipalName + MatterId + near-identical Timestamp where ACLDecision=Deny and ConnectorDecision=Allow.
3. Correlate sign-in/session.
   - Log location: Azure portal > Microsoft Entra ID > Monitoring & health > Sign-in logs.
   - Fields: User principal name, Status, Correlation ID, Conditional Access, Resource display name, Created date.
   - Look for: Successful session aligned to mismatch timestamp.

### B - Login Failures and Slowness
1. Validate affected cohort.
   - Log location: Intune admin center > Devices > All devices (filter displayName startswith F6-).
   - Fields: Device name, OS, Enrollment date, Last check-in.
   - Look for: Floor 6 devices concentrated in failure window.
2. Validate authentication signal.
   - Log location: Event Viewer > Windows Logs > Security.
   - Event IDs: 4624, 4625.
   - Fields: TargetUserName, LogonType, Status, SubStatus, WorkstationName, TimeCreated.
   - Look for: Elevated 4625/4624 ratio on affected endpoints.
3. Validate endpoint pressure signal.
   - Log location: c:\temp\incident-b-diagnostics\corrected-overview.json and corrected-logon-summary.csv.
   - Fields: FreeSpaceGB, PercentUsed, MinutesSinceBoot, Event4624Count, Event4625Count.
   - Look for: High 4625 ratio and/or low FreeSpaceGB.
4. Pool comparison check (mandatory).
   - Log location: Azure portal > Azure Virtual Desktop > Host pools > Pool 1 and Pool 2 > Insights > Connections.
   - Fields: Connection success rate, Failed connections, Sign-in duration.
   - Look for: Pool 2 degraded while Pool 1 stable. If Pool 1 starts matching Pool 2 degradation, treat as broader platform incident.

### C - Missing Desktop Shortcuts
1. Confirm blast radius.
   - Log location: Output from incident-C-dryrun-ai-and-corrected.ps1 under c:\temp\incident-c-diagnostics.
   - Fields: DeviceName, ExpectedShortcut, Present, ShortcutPath, Timestamp.
   - Look for: Single-device loss vs cohort-wide loss.
2. Check installer-driven shortcut changes.
   - Log location: Event Viewer > Windows Logs > Application (Source=MsiInstaller).
   - Fields: ProviderName, EventID, Message, User, TimeCreated.
   - Look for: Message contains .lnk or shortcut operations near failure time.
3. Check script-driven shortcut changes.
   - Log location: Event Viewer > Applications and Services Logs > Microsoft > Windows > PowerShell > Operational.
   - Fields: EventID, ScriptBlockText, Message, UserId, TimeCreated.
   - Look for: Script block references .lnk, Desktop path, Remove-Item/New-Item around failure time.
4. Check profile fallback condition.
   - Log location: Registry path HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList.
   - Fields: Subkey suffix .bak, State, RefCount, ProfileImagePath.
   - Look for: .bak profile with abnormal State/RefCount indicating temporary profile behavior.

## Resolution
### A - Unauthorized Client Matter Exposure (do first)
1. Contain connector immediately.
   - Azure portal path: https://admin.microsoft.com > Copilot > Data sources > affected connector.
   - Action: Set Disabled or admin-only scope; if not available, exclude Floor 6 scope.
   - Expected: Floor 6 queries return no results from affected repository.
2. Revoke test-user sessions and retest.
   - Azure portal path: https://portal.azure.com > Microsoft Entra ID > Users > <test-user> > Revoke sessions.
   - Action: Revoke sessions, sign in again, rerun same query.
   - Expected: If issue persists, entitlement problem is persistent.
3. Rebuild connector index only when mismatch is confirmed.
   - Azure portal path: https://portal.azure.com > Cloud Shell > PowerShell.
   - Action:
     - Connect-MgGraph -Scopes AdminConsentRequired
     - Start-MgBetaConnectorIndexRebuild -ConnectorId <connector-id> -Scope Floor6 -Force
     - Get-MgBetaConnectorIndexStatus -ConnectorId <connector-id>
   - Expected: Index status completes and entitlement metadata aligns with ACL.

### B - Login Failures and Slowness (second)
1. Pause non-critical Friday assignments for Floor 6 only.
   - Azure portal path: https://intune.microsoft.com > Apps > Windows apps > <app/policy> > Assignments.
   - Action: Remove Floor 6 include group from non-critical assignments only.
   - Expected: New sign-ins skip heavy install/remediation workload.
2. Force sync and reboot in waves.
   - Azure portal path: https://intune.microsoft.com > Devices > All devices > <device> > ... > Sync and Restart.
   - Action: Run sync then reboot for each wave.
   - Expected: Faster policy evaluation; improved sign-in readiness.
3. Re-enable gradually after stabilization.
   - Azure portal path: https://intune.microsoft.com > Apps > Windows apps > <app/policy> > Assignments.
   - Action: After 4 hours stable, re-enable policy first, then pilot app, then wider scope with 30-minute observation gaps.
   - Expected: No sign-in regression during reintroduction.

### C - Missing Desktop Shortcuts (third)
1. Deploy remediation script.
   - Azure portal path: https://intune.microsoft.com > Devices > Windows > Scripts and remediations.
   - Action: Assign shortcut-remediation.ps1 to Floor 6 group and run now.
   - Expected: Missing .lnk recreated on Public Desktop/user desktop.
2. Validate persistence after sign-out/in.
   - Azure portal path: https://intune.microsoft.com > Devices > All devices > <device> > Device actions and status.
   - Action: Functional open test for Edge/Outlook/Teams, then sign out/in and recheck.
   - Expected: Shortcuts remain and launch correctly.

## Verification
- A success:
  - Floor 6 test query returns no unauthorized data.
  - ACLDecision and ConnectorDecision now aligned for tested user/matter pairs.
- B success:
  - At least 5 users reach desktop in 2-5 minutes.
  - Event ID 4625 count drops and 4624/4625 ratio normalizes.
  - Entra conditional access success trend improves.
- C success:
  - Missing shortcut count is zero on sampled impacted devices.
  - Shortcuts survive sign-out/sign-in.
- Pool comparison check:
  - Pool 2 returns to expected metrics and no matching degradation appears in Pool 1.

## Rollback
- A rollback:
  - Azure portal path: https://admin.microsoft.com > Copilot > Data sources > affected connector.
  - Re-enable prior connector scope only with security + compliance approval.
  - If exposure returns, disable immediately and escalate Security Architect + Legal.
- B rollback:
  - Azure portal path: https://intune.microsoft.com > Apps > Windows apps > <app/policy> > Assignments.
  - Re-add Floor 6 group to previously paused assignments.
  - Force sync on impacted devices and notify users of temporary redeployment impact.
- C rollback:
  - Azure portal path: https://intune.microsoft.com > Devices > Windows > Scripts and remediations.
  - Disable/delete faulty remediation assignment.
  - Remove incorrect .lnk from Public Desktop and redeploy corrected package.

## Preventive
- Implement connector-ACL parity control:
  - Scheduled job every 30 minutes compares connector entitlement vs source ACL for high-sensitivity matters.
  - Auto-action: set connector to admin-only if mismatch count > 0; open Sev-2 ticket automatically.
- Implement Intune Friday deployment guardrail:
  - Assignment policy requires CAB tag for Floor 6 on Fridays; non-critical assignments blocked by automation without approved tag.
  - Add ring cap: max 10% Floor 6 devices per 30-minute rollout window.
- Implement login health SLO alerting:
  - Alert when 4625/4624 ratio crosses threshold for 15 minutes on Floor 6 cohort.
  - Alert when Pool 2 sign-in duration deviates from Pool 1 by defined threshold.
- Implement shortcut drift detection:
  - Daily remediation detection script verifies required .lnk set (Edge/Outlook/Teams) on Public Desktop and user desktop.
  - Auto-remediate and open ticket when missing count > 0 on more than 3 devices.

## Related
- RCA-FLOOR-6-INCIDENT-CLUSTER-2026-08-14.md
- RUNBOOK-FLOOR-6-INCIDENT-CLUSTER-2026-08-14.md
- DAY4/known-error-record-avd-black-screen-2024-03-15.md
- DAY5/kb-avd-black-screen-end-user.md