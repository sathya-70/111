# Runbook: Floor 6 Incident Cluster Remediation (Short Form)
Date: 2026-08-14
Incident IDs: A (Confidentiality), B (Login), C (Shortcuts)
Location: Floor 6, Finbridge
Version: 1.1 (Condensed)
Reference: RCA-FLOOR-6-INCIDENT-CLUSTER-2026-08-14.md

## Priority Order
1. Incident A first (confidentiality containment).
2. Incident B second (access restoration).
3. Incident C third (productivity cleanup).

Do not delay Incident A for B or C.

## 0) First 10 Minutes
- Declare major incident and notify leadership, security, legal, compliance.
- Freeze Floor 6 ACL, group, and connector changes.
- Assign owners: Security (A), Endpoint (B), Intune/App (C).
- Start evidence collection immediately.

---

## Incident A: Unauthorized Client Matter Exposure
Goal: Stop retrieval immediately, confirm ACL vs connector decision, repair entitlement state.

### A1. Contain
Owner: Platform/Connector Engineer
- M365 admin center -> Copilot -> Data sources.
- Find affected connector.
- Set to Disabled or admin-only scope (do not delete).
- If disable unavailable, exclude Floor 6 scope.

Expected:
- Floor 6 Copilot retrieval from affected repository returns no results.

### A2. Preserve Evidence
Owner: Security/Forensics
Run:
- cd c:\Users\labuser\Documents\Training\Project
- .\incident-A-dryrun-ai-and-corrected.ps1 -Version Corrected -DryRun $false -HoursBack 72 -OutputRoot c:\temp\incident-a-evidence

Expected outputs:
- corrected-overview.json
- corrected-security-signin-events.csv
- corrected-group-change-events.csv
- corrected-aad-operational-events.csv
- corrected-action-checklist.csv

### A3. Confirm Mismatch (ACL vs Connector)
Owner: Platform/Identity
- Get exact matter ID + user UPN from report.
- Check source ACL decision (allow/deny).
- Check connector decision for same UPN, matter ID, timestamp.

Decision:
- Connector allow + ACL deny = mismatch confirmed.
- Connector deny + ACL deny = no mismatch (likely user/session issue).
- Connector allow + ACL allow = valid access (false alarm).

### A4. Token Refresh + Retest
Owner: Identity Engineer
Run:
- Connect-MgGraph -Scopes Directory.Read.All, AuditLog.Read.All
- Revoke-MgUserSignSession -UserId <test-user-upn>

Retest same query with fresh session.

Expected:
- If still reproducible, persistent entitlement issue.

### A5. Rebuild Connector Index (only if mismatch confirmed)
Owner: Platform Engineer
Run:
- Connect-MgGraph -Scopes AdminConsentRequired
- Start-MgBetaConnectorIndexRebuild -ConnectorId <connector-id> -Scope Floor6 -Force
- Get-MgBetaConnectorIndexStatus -ConnectorId <connector-id>

Expected:
- Entitlement metadata refreshed and aligned to current ACL.

### A Verification
- Floor 6 test query returns no access/no results.
- ACL and connector comparison documented and signed off.
- Evidence pack complete and moved to secure storage.

### A Rollback
- Re-enable connector and restore original scope filter if business impact is unacceptable.
- Notify stakeholders immediately if rollback executed.

---

## Incident B: Login Failures and Slowness
Goal: Remove rollout pressure, restore baseline logon, then re-enable safely.

### B1. Identify Affected Cohort
Owner: Endpoint Engineer
Run:
- Connect-MgGraph -Scopes DeviceManagementManagedDevices.Read.All
- Get-MgDeviceManagementManagedDevice -Filter "displayName startswith 'F6-'"

Capture:
- device name, OS, enrollmentDateTime, lastSyncDateTime

Expected:
- Confirm affected Floor 6 cohort and scope.

### B2. Pause Non-Critical Friday Assignments
Owner: Intune Admin
- Intune admin center -> Apps -> Windows apps -> target app -> Assignments.
- Remove Floor 6 included group for non-critical Friday app/policies only.
- Do not remove critical security controls.

Expected:
- New sign-ins skip heavy install/remediation tasks.

### B3. Sync + Reboot in Waves
Owner: Endpoint Engineer
Run per device:
- Invoke-MgDeviceManagementManagedDeviceAction -ManagedDeviceId <device-id> -ActionName syncDevice
- Invoke-MgDeviceManagementManagedDeviceAction -ManagedDeviceId <device-id> -ActionName rebootNow

Expected:
- Faster policy evaluation and improved sign-in readiness.

### B4. Measure Post-Change Login
Owner: Endpoint Engineer
- Test 2-3 users per wave.
- Target time: 2-5 minutes to desktop.
- Check compliance and recent sync.

Expected:
- Login duration improves, failure rate drops.

### B5. Deep Diagnostics if Still Slow
Owner: Senior Endpoint Engineer
Run:
- .\incident-B-dryrun-ai-and-corrected.ps1 -Version Corrected -DryRun $false -HoursBack 24 -OutputRoot c:\temp\incident-b-diagnostics

Analyze:
- corrected-logon-summary.csv: Event ID 4624 vs 4625 ratio
- corrected-overview.json: FreeSpaceGB, PercentUsed, MinutesSinceBoot

Interpretation:
- High 4625 ratio = auth bottleneck
- Profile warnings = profile bottleneck
- Low disk free space = storage bottleneck
- Otherwise review policy conflict

### B6. Re-enable Gradually (after stable period)
Owner: Intune Admin
- Wait minimum 4 hours after stabilization.
- Re-enable in reverse order: policy first, then app pilot, then wider rollout.
- Observe 30 minutes between stages.

Expected:
- No regression while restoring assignments.

### B Verification
- 5 users log in within 2-5 minutes.
- Entra sign-ins show conditionalAccessStatus success trend.
- Intune compliance and check-in healthy.
- Login ticket volume returns to baseline.

### B Rollback
- Re-add Floor 6 group to paused assignments.
- Force sync on affected devices.
- Notify users of temporary redeployment.

---

## Incident C: Missing Desktop Shortcuts
Goal: Confirm cause, restore shortcuts safely, ensure persistence.

### C1. Confirm Blast Radius
Owner: Endpoint Engineer
Run:
- .\incident-C-dryrun-ai-and-corrected.ps1 -Version Corrected -DryRun $true -HoursBack 24 -ExpectedShortcuts @(Microsoft Edge, Outlook, Teams) -OutputRoot c:\temp\incident-c-diagnostics

Expected:
- Determine single-device vs cohort-wide impact.

### C2. Compare with Baseline Device
Owner: Endpoint Engineer
- Collect .lnk inventory from unaffected Floor 6 device.
- Compare names/paths/targets with affected device.

Expected:
- Clear list of missing shortcuts.

### C3. Check Cause Signals
Owner: Platform/Endpoint Engineer
- Application log (MsiInstaller) for .lnk/shortcut activity.
- Windows PowerShell log for .lnk/shortcut activity.
- Registry ProfileList for .bak profile keys and profile state.

Expected:
- Identify installer/script removal vs temporary profile path.

### C4. Deploy Remediation Script
Owner: Intune Admin
- Intune admin center -> Devices -> Windows -> Scripts and remediations.
- Deploy shortcut-remediation.ps1 to Floor 6 group.
- Run immediately.

Expected:
- Missing shortcuts recreated on public/user desktop.

### C5. Validate Function + Persistence
Owner: Endpoint Engineer
- Open remediated shortcuts on test device.
- Sign out/in and recheck shortcuts.

Expected:
- Shortcuts launch target apps and remain after relogin.

### C Verification
- Missing shortcut count = 0 on sampled affected devices.
- Three user functional checks pass.
- No re-loss after relogin.

### C Rollback
- Disable/delete remediation assignment if wrong links deployed.
- Remove incorrect .lnk from Public Desktop.
- Notify users while corrected package is prepared.

---

## Cross-Incident Checks
- If B unresolved, do not mass-remediate C.
- If A mismatch persists after rebuild, escalate to security architect and compliance immediately.
- If Pool 1 starts showing Pool 2 symptoms, escalate as broader platform incident.

---

## Escalation Matrix
- Incident A: Security architect, compliance officer, legal.
- Incident B: Identity SME, endpoint engineering lead.
- Incident C: App deployment SME, platform engineering lead.

---

## Stakeholder Update Template
30-minute update:
- A: Contained/restricted, evidence in progress.
- B: Mitigation running, reboot waves active, stabilization ETA 60 min.
- C: Assessment complete, remediation pending B stabilization.

60-minute update:
- A: ACL vs connector finding status.
- B: Login baseline restored or still degraded.
- C: Remediation deployed/validated status.

---

## Command Quick Reference
- List Floor 6 devices:
  Get-MgDeviceManagementManagedDevice -Filter "displayName startswith 'F6-'" | Select-Object displayName, osVersion, enrollmentDateTime

- Check compliance:
  Get-MgDeviceManagementManagedDevice -ManagedDeviceId <id> | Select-Object displayName, compliant, complianceExpirationDateTime

- Force sync:
  Invoke-MgDeviceManagementManagedDeviceAction -ManagedDeviceId <id> -ActionName syncDevice
