# Legal Document Manager Crash Wave Analysis

Date prepared: 2026-08-13  
Incident date: 2024-03-25  
Analyst context: DWP endpoint operations  
Incident type: Post-deployment application crash wave

## 1) Scope Facts Established From Both Sources

### Source 1 - Nexthink DEX export

- Device group in scope: `Legal-Win11`
- Population size: `45 devices`
- Baseline period before the event:
  - `08:00`: DEX score `91`, app crash rate `0.1%`, disk I/O `Normal`
  - `09:00`: DEX score `90`, app crash rate `0.2%`, disk I/O `Normal`
- Degraded period after the event:
  - `10:00`: DEX score `58`, app crash rate `6.2%`, disk I/O `High`
  - `11:00`: DEX score `55`, app crash rate `6.8%`, disk I/O `High`
- Top crashing process during the degraded window (`10:00-11:00`): `DocManager.exe`
- `DocManager.exe` accounts for `74%` of all crashes in that window

### Source 2 - SCCM deployment log

- Deployment target collection: `Legal-Win11`
- Deployment start: `09:38:20`
- Deployment completed: `09:44:07`
- Installation success rate: `45 of 45 devices`
- Installation failures recorded: `0`
- Previous version: `Document Manager v2.0`
- New version: `Legal Document Manager v2.1`
- Vendor release note for `v2.1`:
  - new auto-save feature introduced
  - known limitation on devices with under `8GB` RAM
  - limitation can cause `high disk I/O` and `intermittent crashes`
  - effect is expected `during the first few hours after installation while the initial index builds`
- Fleet hardware profile:
  - `27 of 45` devices have `8GB` RAM
  - `18 of 45` devices have `4GB` RAM

## 2) Cross-Source Correlation

The two sources align on both scope and timing and should be read as a single event chain rather than as separate observations.

### Scope correlation

- The DEX export and SCCM deployment both reference the exact same population: `Legal-Win11` with `45 devices`.
- The deployment log confirms `45 of 45` installs succeeded, which means the new application version was introduced across the full population later seen in the DEX degradation window.
- The dominant crashing process in DEX is `DocManager.exe`, which directly matches the application being deployed (`Document Manager v2.1`).

### Timing correlation

- At `08:00` and `09:00`, the device group is stable: DEX remains high (`91` then `90`), app crash rate is near baseline (`0.1%` then `0.2%`), and disk I/O is `Normal`.
- The SCCM deployment starts at `09:38:20` and completes successfully by `09:44:07`.
- The first hourly DEX snapshot after deployment completion is `10:00`, where the device group shows a sharp deterioration:
  - DEX score falls from `90` at `09:00` to `58` at `10:00`
  - app crash rate jumps from `0.2%` to `6.2%`
  - disk I/O shifts from `Normal` to `High`
- The degradation continues at `11:00`, with DEX falling further to `55` and crash rate increasing to `6.8%`, which is consistent with an issue that persists for more than a single short spike.

### Content correlation

- The vendor release note for `v2.1` predicts the same symptom pattern seen in DEX:
  - `high disk I/O`
  - `intermittent crashes`
  - occurring in `the first few hours after installation`
- The DEX data shows that exact pattern beginning immediately after installation:
  - disk I/O changes from `Normal` to `High`
  - crash rate increases materially
  - `DocManager.exe` becomes the clear leading crashing process
- This is not a generic device-health degradation pattern. The crash concentration in `DocManager.exe` and the matching disk-I/O signature point specifically to the newly deployed application version rather than to an unrelated OS-wide issue.

## 3) Most Supported Analysis Outcome

The most supported conclusion from the combined evidence is that the app crash wave on Floor 4 was triggered by the `Legal Document Manager v2.1` deployment to the `Legal-Win11` estate, with the new auto-save indexing behavior driving elevated disk I/O and a corresponding rise in `DocManager.exe` crashes during the first hours after install.

This conclusion is supported by all of the following facts lining up:

- same affected group in both data sources: `Legal-Win11`, `45 devices`
- no sign of instability before the deployment window
- deployment completed successfully immediately before the DEX decline begins
- `DocManager.exe` is the dominant crashing process after deployment
- disk I/O becomes `High` in the same window as the crash spike
- vendor release notes describe the same failure mode and same expected timing window

## 4) Likely Blast Radius Within The 45 Devices

The full `Legal-Win11` group is in scope for the deployment and observed degradation, but the strongest device-level risk is concentrated in the `18` devices with `4GB` RAM because those are the systems explicitly below the vendor's `8GB` threshold.

That said, the available data is still incomplete in two ways:

- the DEX source is aggregated at device-group level, so it does not yet break crashes out by individual device or RAM class
- the SCCM log confirms install success, but it does not prove whether all failures are limited only to `4GB` devices

Operationally, the current evidence supports this position:

- Confirmed affected estate: all `45` devices received the change and contributed to the group-level DEX degradation
- Highest-probability directly impacted subset: the `18` devices with `4GB` RAM
- Possible secondary impact on the remaining devices: some `8GB` devices may still experience temporary load or reduced responsiveness while indexing runs, but the evidence provided is not sufficient to quantify that subset

## 5) Confidence Statement

Confidence is `high` that the deployment is the trigger for the crash wave.

Confidence is not yet `absolute` on exact per-device distribution because the evidence set is incomplete and does not include:

- device-level crash counts
- RAM-to-crash correlation by hostname
- uninstall or rollback test results
- user session timing from affected machines

Even with those gaps, the current data is strong enough to treat `Document Manager v2.1` as the primary incident driver until disproved.

## 6) Recommended Next Technical Checks

1. Split the `45` devices by RAM and confirm whether the `4GB` cohort carries the highest `DocManager.exe` crash count.
2. Validate whether disk queue length and storage latency rose at the same time on the lowest-memory endpoints.
3. Confirm whether a rollback to `v2.0` or disabling the new auto-save indexing feature removes the crash pattern.
4. Pause any broader deployment of `v2.1` until the vendor limitation is mitigated or an exclusion rule is applied to sub-`8GB` devices.

## 7) Short Incident Statement

On `2024-03-25`, Floor 4's `Legal-Win11` fleet experienced a sharp application crash wave immediately after SCCM deployed `Legal Document Manager v2.1` to all `45` devices. Nexthink DEX shows the environment was stable before deployment, then deteriorated within the next hourly window, with DEX dropping from `90` to `58`, app crash rate increasing from `0.2%` to `6.2%`, disk I/O moving to `High`, and `DocManager.exe` accounting for `74%` of crashes. The deployment timing, the crashing process name, and the vendor's published `v2.1` limitation together make the new version the most probable cause, with the `4GB` devices representing the highest-risk subset.