# Root Cause Analysis (RCA)

## Incident
- Title: Finance shared drive access failure after script migration
- Date of incident: 2024-03-15
- RCA prepared: 2026-08-07
- Affected users: 45 Finance users
- Affected endpoints: DESKTOP-FB* devices
- Scope: OU=Finance
- Symptoms: Finance users unable to access mapped shared drives (S:)

## Executive Summary
At 08:00, Finance users lost access to shared drives after the drive mapping process failed at logon. The mapping script `Map-FinBridgeDrives.ps1` was executed in SYSTEM context via Intune and failed with "Network name cannot be found" when attempting `\\finbridge-fs01\Finance`.

System evidence confirms the Workstation service became running shortly after script execution, and Group Policy processing was successful, ruling out GP as the primary cause. The incident was caused by a context mismatch introduced by change: mapping logic designed for USER logon context was moved to SYSTEM context without redesign for machine-context networking and credential behavior.

## Impact Assessment
- Business impact: 45 Finance users blocked from shared drive access.
- Technical impact: Mapped drive letter S: not assigned.
- Blast radius: All Finance endpoints under OU=Finance.
- Severity rationale: Multi-user productivity impact across a business-critical team.

## Timeline (Local Time, 2024-03-15)
- 2024-03-14 23:30: Change implemented. Drive mapping moved from GPO logon script (USER context) to Intune PowerShell script (SYSTEM context).
- 08:00:01: ScriptRunner starts `Map-FinBridgeDrives.ps1`.
- 08:00:02: ScriptRunner confirms execution context as SYSTEM account.
- 08:00:03: Warning: `\\finbridge-fs01\Finance` not accessible from SYSTEM context at execution time.
- 08:00:03: Script fails. Exit code 1. Error: Network name cannot be found.
- 08:00:04: ScriptRunner reports no retry configured.
- 08:00:05 (DESKTOP-FB041): Workstation service enters running state (SCM Event 7036).
- 08:00:06 (DESKTOP-FB041): Group Policy settings processed successfully (Event 1500).
- 08:00:07 (DESKTOP-FB041): NTFS warning Event 98: could not map drive letter S:, drive letter not assigned.

## Evidence and Correlation

### Extension/ScriptRunner Evidence
- Script starts before required access conditions are available.
- SYSTEM context is explicitly confirmed.
- UNC path access failure occurs at execution time.
- Failure is terminal due to no retry policy.

### System Event Evidence
- Workstation service starts after script execution/failure window.
- GP processed successfully, indicating policy framework health.
- NTFS confirms drive mapping outcome failure (S: unassigned).

### Change Correlation
- Immediate temporal correlation between previous-night migration and next-morning widespread Finance impact.
- Migration note explicitly states script was not updated for SYSTEM context behavior.

## Confirmed Root Cause
The drive mapping solution was migrated from USER logon context to Intune SYSTEM context without adapting script logic for SYSTEM-context network access and timing dependencies. As a result, at execution time the UNC target `\\finbridge-fs01\Finance` was not reachable/usable from SYSTEM context, causing mapping failure and leaving S: unassigned for all affected users.

## Contributing Factors
1. Execution context mismatch: USER-oriented mapping logic executed as SYSTEM.
2. Timing dependency: Script ran before network access conditions were fully ready for mapping attempt.
3. No retry mechanism: Single transient failure became user-visible outage.
4. Change assurance gap: No pilot validation for Finance OU under startup/logon timing conditions.

## 5 Whys Analysis
1. Why could Finance users not access shared drives?
Because mapped drive S: was not created.

2. Why was S: not created?
Because `Map-FinBridgeDrives.ps1` failed with "Network name cannot be found."

3. Why did the script fail to reach the share?
Because it ran as SYSTEM and attempted UNC mapping in a context/timing state not equivalent to user logon mapping.

4. Why was the script running as SYSTEM?
Because the mapping process was migrated from GPO USER logon script to Intune PowerShell deployment.

5. Why did this migration cause broad impact?
Because the script and rollout controls were not updated for SYSTEM context requirements (readiness checks, retries, context-appropriate mapping method, and pilot validation).

## Resolution and Recovery Actions (Recommended/Applied Pattern)
1. Restore mapping execution to USER context for Finance users, or deploy user-context remediation script.
2. Add readiness checks before mapping attempt (network stack and UNC reachability).
3. Implement retry with backoff for transient startup timing failures.
4. Re-run mapping on next user sign-in or via scheduled user-context task.
5. Validate success across sample DESKTOP-FB* devices before full OU rollout confirmation.

## Preventive and Corrective Actions (CAPA)

### Immediate (0-7 days)
1. Roll back to known-good USER-context mapping method for OU=Finance.
2. Add controlled retry policy (for example: 3 attempts, 20-30 seconds apart).
3. Add explicit logging fields: context, UNC probe result, retry count, final status.

### Near-Term (1-4 weeks)
1. Create a standard for context-sensitive scripts (USER vs SYSTEM decision matrix).
2. Require pre-prod and pilot validation on representative devices per OU.
3. Introduce release gate: block production if critical path mapping fails in pilot cohort.

### Monitoring and Alerting
1. Alert on repeated drive mapping failures by OU/user cohort.
2. Alert when mapping script exits non-zero with network-path errors.
3. Add dashboard metric: percentage of Finance endpoints with S: assigned within 5 minutes of sign-in.

## Validation Criteria for Closure
- Finance user can access `S:` and `\\finbridge-fs01\Finance` after sign-in.
- No new ScriptRunner exit-code 1 failures for mapping script over agreed monitoring window.
- Endpoint sample checks in OU=Finance show successful mapping consistency.

## Residual Risk
If any endpoint remains on SYSTEM-context mapping without readiness/retry controls, intermittent or recurring failures may reappear during startup/logon race conditions.

## Lessons Learned
- Authentication and mapping workflows are highly context-dependent; USER and SYSTEM are not interchangeable.
- Startup/logon timing issues must be treated as first-class failure modes for endpoint scripts.
- High-blast-radius changes (OU-wide mapping) require pilot gates and rollback-ready deployment plans.

## Appendix A: Provided Evidence (verbatim summary)
- ScriptRunner:
  - 08:00:01 executing `Map-FinBridgeDrives.ps1`
  - 08:00:02 context SYSTEM
  - 08:00:03 UNC path not accessible
  - 08:00:03 script failed, exit code 1, network name cannot be found
  - 08:00:04 no retry configured
- System log DESKTOP-FB041:
  - 08:00:05 SCM 7036 Workstation service running
  - 08:00:06 GroupPolicy 1500 successful
  - 08:00:07 NTFS 98 could not map S:, not assigned
- Change log:
  - 2024-03-14 23:30 migration from GPO USER logon script to Intune SYSTEM script without SYSTEM-context adaptation
