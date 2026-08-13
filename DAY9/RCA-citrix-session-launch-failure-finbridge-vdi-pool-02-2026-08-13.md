# Root Cause Analysis (RCA)

## Incident
- Title: Citrix VDI session launch failure on FinBridge Pool-02
- Incident date: 2026-08-13
- RCA prepared: 2026-08-13
- Service: Citrix Virtual Desktop Infrastructure
- Affected pool: `FinBridge-VDI-Pool-02`
- Unaffected pool: `FinBridge-VDI-Pool-01`
- Affected users: `22 of 30`

## Executive Summary
On 2026-08-13, users in `FinBridge-VDI-Pool-02` experienced desktop launch failures. The broker log shows session launch attempts timing out while waiting for machine registration, followed by `Session launch FAILED: error 1030` and `No machines available in the desktop group`.

The strongest evidence links the incident to Delivery Controller `dc-vdi-02`, where `Citrix Broker Service` was found stopped. Pool-02 machine registration state at the same time showed `25` provisioned machines but only `3` registered and `22` unregistered. Sample affected VDAs reported `Unable to contact Delivery Controller dc-vdi-02.finbridge.local:80 - connection refused`, which is consistent with a controller endpoint not accepting registration traffic.

The comparison controller, `dc-vdi-01`, remained healthy with `Citrix Broker Service` running and `14` days uptime, while the comparison pool, `FinBridge-VDI-Pool-01`, remained largely healthy with `19` of `20` machines registered. Based on the supplied evidence, the finalized cause is controller-side broker service loss on `dc-vdi-02`, with a pending update/reboot state as the most likely trigger for that service outage.

## Impact Assessment
- User impact: `22 of 30` users affected in `FinBridge-VDI-Pool-02`
- Symptom: session launch failure
- Broker-facing symptom: timeout waiting for machine registration and no machines available
- Business impact: users could not start VDI sessions in the affected pool
- Blast radius: confined to `FinBridge-VDI-Pool-02`

## Scope Facts Used
- Broker timeout text: `Timeout waiting for machine registration response (30000ms exceeded)`
- Launch failure text: `Session launch FAILED: error 1030`
- Broker message: `No machines available in the desktop group`
- Pool-02 registration state: `25` provisioned, `3` registered, `22` unregistered, `0` in maintenance mode
- Pool-01 registration state: `20` provisioned, `19` registered, `1` unregistered
- Sample VDA errors from Pool-02: `Unable to contact Delivery Controller dc-vdi-02.finbridge.local:80 - connection refused`
- `dc-vdi-02`: `Citrix Broker Service` stopped; last known running `yesterday 23:40`; Windows Update installed `today 00:15`; reboot required flag set; host not rebooted
- `dc-vdi-01`: `Citrix Broker Service` running; uptime `14 days`

## Timeline (Based on Provided Evidence)
- `Yesterday 23:40`: `dc-vdi-02` `Citrix Broker Service` last known running.
- `Today 00:15`: Windows Update installed on `dc-vdi-02`; reboot required flag set; host not rebooted.
- `06:15:22`: `VDI-P02-014` last registration attempt failed with `Unable to contact Delivery Controller dc-vdi-02.finbridge.local:80 - connection refused`.
- `06:16:01`: `VDI-P02-017` last registration attempt failed with the same `connection refused` error to `dc-vdi-02:80`.
- `08:58:03`: Session launch requested for user `jsmith`, `Pool-02`.
- `08:58:04`: Broker queried available machines in `Pool-02`.
- `08:58:34`: Broker timed out waiting for machine registration response after `30000ms`.
- `08:58:34`: Session launch failed with `error 1030` and `No machines available in the desktop group`.
- During the same incident window: Pool-02 catalog observed with `3` registered and `22` unregistered; Pool-01 remained healthy with `19` registered of `20`.

## Supporting Evidence

### Affected Pool: `FinBridge-VDI-Pool-02`
- Large registration deficit: only `3` of `25` machines registered.
- `22` machines unregistered while maintenance mode remained `0`, indicating capacity existed but was not available to broker as registered resources.
- User impact scale aligns with registration loss: `22 of 30` users affected.

### Unregistered Machine Samples
- `VDI-P02-014`: last registration attempt `06:15:22`, failed.
- `VDI-P02-017`: last registration attempt `06:16:01`, failed.
- Common error on both: `Unable to contact Delivery Controller dc-vdi-02.finbridge.local:80 - connection refused`.

### Delivery Controller Comparison

`dc-vdi-02`:
- `Citrix Broker Service` = `STOPPED`
- Last known running: `yesterday 23:40`
- Windows Update installed: `today 00:15`
- Reboot required flag set
- Host not rebooted

`dc-vdi-01`:
- `Citrix Broker Service` = `RUNNING`
- Uptime = `14 days`

### Unaffected Pool Comparison: `FinBridge-VDI-Pool-01`
- `20` provisioned
- `19` registered
- `1` unregistered
- Same site but different pool, supporting a localized fault rather than full-site loss.

## Ranked Cause Assessment

### 1. Controller-side broker service outage on `dc-vdi-02`  
Most likely and finalized cause.

Why it fits:
- Directly explains `connection refused` to `dc-vdi-02:80`.
- Matches the stopped `Citrix Broker Service` state.
- Explains widespread Pool-02 unregistration and broker no-capacity failure.

### 2. Pending post-update state on `dc-vdi-02` left broker services down  
Strong contributing trigger.

Why it fits:
- Timing aligns with update window and required reboot state.
- Provides a plausible reason for the broker service outage on that controller.

### 3. Inadequate Pool-02 controller failover/discovery behavior  
Possible contributing factor.

Why it fits:
- Affected VDAs are calling out `dc-vdi-02` specifically.
- Pool-01 stays healthy via `dc-vdi-01`, suggesting failover was insufficient for Pool-02 capacity recovery.

## Finalized Cause
`FinBridge-VDI-Pool-02` session launches failed because most Pool-02 VDAs could not register while Delivery Controller `dc-vdi-02` was not accepting registration traffic, evidenced by `connection refused` to `dc-vdi-02:80` and a stopped `Citrix Broker Service`. The pending Windows Update / reboot-required state on `dc-vdi-02` is the most likely trigger for that controller-side service outage.

## 5 Whys Analysis
1. Why did users in `FinBridge-VDI-Pool-02` fail to launch sessions?  
Because the broker could not find enough available registered machines and returned `No machines available in the desktop group`.

2. Why were machines not available to the broker?  
Because only `3` of `25` Pool-02 machines were registered and `22` were unregistered.

3. Why were `22` Pool-02 machines unregistered?  
Because affected VDAs were failing registration attempts with `Unable to contact Delivery Controller dc-vdi-02.finbridge.local:80 - connection refused`.

4. Why were VDAs unable to contact `dc-vdi-02` for registration?  
Because `Citrix Broker Service` on `dc-vdi-02` was stopped, so the controller was not accepting broker registration traffic.

5. Why was `Citrix Broker Service` stopped on `dc-vdi-02`?  
Most likely because the controller entered a pending post-Windows-Update state with reboot required and was not fully recovered after the maintenance activity.

## Remediation Steps Executed / Required

### Exact remediation sequence
1. Confirm `dc-vdi-01` remains healthy and Pool-01 stable.
2. Confirm `Citrix Broker Service` on `dc-vdi-02` is stopped and port `80` is not accepting connections.
3. Attempt to start `Citrix Broker Service` on `dc-vdi-02`.
4. If the service fails to start or does not remain healthy, reboot `dc-vdi-02` to complete the pending update state.
5. After recovery, verify `Citrix Broker Service` is running and listening.
6. Monitor Pool-02 machine registration recovery.
7. Test session launch in `FinBridge-VDI-Pool-02`.

### Specific recovery action if confirmed
- Restore the broker service path on `dc-vdi-02` first.
- Use controller reboot as the next step when the pending update state prevents stable service recovery.

## Verification After Remediation
- `dc-vdi-02` shows `Citrix Broker Service = RUNNING`.
- Port `80` on `dc-vdi-02` is reachable from affected Pool-02 VDAs.
- Pool-02 registered count rises materially above `3` and unregistered count falls from `22`.
- Previously affected VDI names re-register successfully.
- Test session launch in `FinBridge-VDI-Pool-02` completes without registration timeout.
- No repeat `No machines available in the desktop group` error during validation.

## Preventive and Corrective Actions (CAPA)

### Immediate hardening
- Add monitoring and alerting for `Citrix Broker Service` state changes on all Delivery Controllers.
- Alert on sudden pool-level growth in unregistered VDAs.
- Require post-patch controller validation before closing a maintenance action.

### Near-term process improvements
- Add a controller health check to every patch/change window:
  - service status check
  - listener/port check
  - sample VDA registration check
  - sample user launch check
- Review VDA controller discovery/failover configuration so a healthy alternate controller can absorb registration demand.

### Preventive action to stop recurrence
- Introduce a mandatory post-update reboot-and-validation control for Citrix Delivery Controllers whenever patching leaves a reboot-required state.
- Do not close controller maintenance until broker service health and at least one pool registration/launch test are both passed.

## Residual Risk
- If controller patching or service stoppage can occur without immediate alerting and post-change verification, similar pool-specific registration failures can recur.

## Lessons Learned
- Session launch failures with broker timeout should be correlated immediately with VDA registration state and controller service health.
- A healthy comparison pool and controller provide fast scoping evidence and help isolate localized broker/control-plane failures.
- `Connection refused` is high-value evidence that the endpoint is reachable but the required service is not accepting traffic.

## Note on Error Code `1030`
The evidence confirms `error 1030` was the broker-reported launch failure code in this incident, shown together with `No machines available in the desktop group`. This RCA does not rely on any unsupported external expansion of that code beyond the text included in the supplied logs.