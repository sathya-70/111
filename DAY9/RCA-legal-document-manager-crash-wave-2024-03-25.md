# Root Cause Analysis (RCA)

## Incident
- Title: Legal Document Manager crash wave on Legal-Win11
- Incident date: 2024-03-25
- RCA prepared: 2026-08-13
- Service: Endpoint application stability (Document Manager)
- Affected device group: `Legal-Win11`
- Devices in scope: `45`

## Executive Summary
On 2024-03-25, the `Legal-Win11` estate experienced a sharp application crash wave shortly after a successful SCCM rollout of `Legal Document Manager v2.1` to all `45` target devices. Before deployment, DEX telemetry was stable (DEX `91` then `90`, crash rate `0.1%` then `0.2%`, disk I/O `Normal`). Immediately after deployment completion (`09:44:07`), the next DEX windows showed material degradation (DEX `58` then `55`, crash rate `6.2%` then `6.8%`, disk I/O `High`).

The top crashing process was `DocManager.exe`, accounting for `74%` of all crashes in the degraded window. Vendor notes for `v2.1` state a known limitation: devices below `8GB` RAM may show high disk I/O and intermittent crashes during initial index build in the first few hours after install. The population includes `18` devices with `4GB` RAM and `27` with `8GB` RAM.

Based on timing, scope match, process-specific crash concentration, and vendor-known behavior, the finalized cause is a post-deployment application defect/limitation in `v2.1` auto-save indexing behavior, amplified on lower-memory endpoints.

## Impact Assessment
- User impact: elevated app instability for users in `Legal-Win11`
- Symptom: repeated `DocManager.exe` crashes and reduced endpoint experience
- Technical impact:
  - DEX score drop from `90` to `58` within first post-deploy window
  - App crash rate increase from `0.2%` to `6.2%` and then `6.8%`
  - Disk I/O state changed from `Normal` to `High`
- Business impact: reduced productivity for legal users depending on the document application
- Blast radius: entire `Legal-Win11` deployment group (`45` devices), with highest risk on sub-`8GB` endpoints

## Scope Facts Used
- Population: `Legal-Win11`, `45` devices
- Baseline (pre-event):
  - `08:00`: DEX `91`, crash rate `0.1%`, disk I/O `Normal`
  - `09:00`: DEX `90`, crash rate `0.2%`, disk I/O `Normal`
- SCCM deployment:
  - Start: `09:38:20`
  - Complete: `09:44:07`
  - Result: `45/45` success, `0` failures
  - Version change: `v2.0` -> `v2.1`
- Post-event degraded windows:
  - `10:00`: DEX `58`, crash rate `6.2%`, disk I/O `High`
  - `11:00`: DEX `55`, crash rate `6.8%`, disk I/O `High`
- Crash concentration: `DocManager.exe` = `74%` of crashes during degraded period
- Vendor note for `v2.1`: auto-save indexing may cause high disk I/O and intermittent crashes on devices with `<8GB` RAM during first hours after install
- RAM profile:
  - `27` devices at `8GB`
  - `18` devices at `4GB`

## Timeline (Based on Provided Evidence)
- `08:00`: Baseline healthy state recorded (DEX `91`, crash `0.1%`, I/O `Normal`).
- `09:00`: Baseline still healthy (DEX `90`, crash `0.2%`, I/O `Normal`).
- `09:38:20`: SCCM starts deployment of `Legal Document Manager v2.1` to `Legal-Win11`.
- `09:44:07`: Deployment completes successfully on all `45` devices.
- `10:00`: First post-deployment telemetry window shows major degradation (DEX `58`, crash `6.2%`, I/O `High`).
- `11:00`: Degradation persists (DEX `55`, crash `6.8%`, I/O `High`).

## Supporting Evidence

### Scope and Timing Alignment
- Same target group in both sources (`Legal-Win11`, `45` devices).
- No instability indicated before deployment window.
- Degradation appears in the first telemetry interval after deployment completion.

### Process Specificity
- `DocManager.exe` is the dominant crashing process (`74%` of crashes), directly tied to deployed app.

### Signature Match to Vendor Limitation
- Vendor-described pattern (high disk I/O + intermittent crashes in early post-install period) matches observed DEX behavior.
- Lowest-memory subgroup (`4GB`) is below documented threshold and is the highest-probability impacted cohort.

## Ranked Cause Assessment

### 1. Application behavior change in `v2.1` auto-save indexing on low-memory devices
Most likely and finalized cause.

Why it fits:
- Exact timing match with deployment completion.
- Crash concentration tied to deployed binary/process (`DocManager.exe`).
- High I/O symptom and crash timing match vendor-known limitation.

### 2. Resource contention during first-hours index build
Strong contributing factor.

Why it fits:
- Disk I/O moved from `Normal` to `High` immediately after install.
- Lower-memory endpoints (`4GB`) are more vulnerable to sustained indexing pressure.

### 3. Deployment ring design did not gate lower-memory devices
Process contributor.

Why it fits:
- `45/45` broad deployment without exclusion likely exposed all low-memory devices at once.
- A phased ring or RAM-based targeting could have limited blast radius.

## Finalized Cause
The crash wave was caused by deployment of `Legal Document Manager v2.1`, where the new auto-save indexing behavior introduced sustained post-install disk I/O pressure and intermittent `DocManager.exe` crashes, particularly on devices below `8GB` RAM. The issue manifested immediately after successful deployment to all `45` devices in `Legal-Win11`.

## 5 Whys Analysis
1. Why did legal users experience a crash wave?  
Because `DocManager.exe` crash frequency increased sharply across the `Legal-Win11` fleet.

2. Why did `DocManager.exe` crash frequency increase?  
Because `v2.1` introduced behavior that generated high disk I/O during initial indexing.

3. Why did high disk I/O lead to instability?  
Because lower-memory endpoints had less headroom, increasing contention during index build and app runtime.

4. Why were vulnerable endpoints broadly impacted at once?  
Because the deployment succeeded to all `45` devices in one wave, including `18` devices with `4GB` RAM.

5. Why was this not prevented before broad rollout?  
Because hardware-aware gating/phasing and early ring validation for the known vendor limitation were insufficient.

## Remediation Steps Executed / Required

### Immediate containment
1. Pause further `v2.1` rollout beyond current scope.
2. Prioritize stabilization for impacted users on `4GB` devices.
3. Apply vendor-recommended mitigation for indexing/auto-save where available.
4. If mitigation is unavailable or ineffective, rollback impacted cohort to `v2.0`.

### Recovery verification
1. Re-check DEX crash rate trend hourly after mitigation/rollback.
2. Confirm disk I/O returns toward baseline.
3. Confirm `DocManager.exe` no longer dominates crash telemetry.

## Verification After Remediation
- DEX trend improves toward pre-incident baseline.
- Crash rate materially decreases from `6%+` range.
- Disk I/O state on impacted devices returns from `High` to expected levels.
- `DocManager.exe` crash share falls significantly from `74%`.
- User validation confirms normal application usage without repeated crash prompts.

## Preventive and Corrective Actions (CAPA)

### Immediate hardening
- Introduce hardware-aware deployment filters for this app family (RAM threshold check).
- Require canary ring before full collection rollout.
- Add temporary DEX alerting for sudden app-specific crash spikes after software change.

### Near-term process improvements
- Add pre-deployment risk review whenever vendor notes include hardware limitations.
- Enforce phased deployment rings (`pilot` -> `limited` -> `broad`) with hold points.
- Define automatic pause criteria (for example: crash-rate delta and DEX drop thresholds).

### Long-term prevention
- Keep a maintained compatibility matrix (app version vs endpoint hardware tiers).
- Bake rollback plans and validation checkpoints into standard change templates.

## Residual Risk
- Risk remains if low-memory devices continue to receive versions with known indexing-related load without ring controls.
- Aggregated telemetry alone can mask per-device outliers; device-level monitoring should be part of closure criteria.

## Lessons Learned
- Group-level DEX stability before change and immediate degradation after change is high-value causality evidence.
- Process-level crash concentration (`DocManager.exe`) quickly narrows fault domain.
- Vendor release notes with explicit hardware caveats must translate into deployment filters, not just documentation.

## Closure Criteria
- Mitigation or rollback complete for impacted cohort.
- DEX and crash metrics remain stable for at least one business day.
- Deployment safeguards (ringing + hardware gating + pause thresholds) documented and approved.