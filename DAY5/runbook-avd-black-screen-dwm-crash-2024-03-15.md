---

| Field    | Detail                          |
|----------|---------------------------------|
| Title    | Runbook: AVD Black Screen — DWM Crash (igdumd64.dll) Post Image Update |
| Version  | 1.0                             |
| Date     | 07/08/2026                      |
| Author   | Sathya                          |
| Reviewed | Self                            |
| Status   | Draft                           |
| Change   | Initial version from RCA        |

---

# Runbook: AVD Black Screen — DWM Crash (igdumd64.dll) Post Image Update

**Incident reference:** POOL-FIN-01 black screen incident, 2024-03-15  
**Root cause:** Intel graphics driver (igdumd64.dll) regression in overnight image update causing repeated dwm.exe crashes on POOL-FIN-01 session hosts  
**Author:** DWP Engineering  
**Date:** 2026-08-07  

---

## Prerequisites

Before starting, confirm you have all of the following. Do not proceed without them.

| Requirement | Detail |
|---|---|
| **Access — AVD Host Pool admin** | Rights to drain, reimage, and return session hosts in the POOL-FIN-01 host pool. *(Elevated)* |
| **Access — Azure portal / AVD blade** | Reader or Contributor on the AVD resource group to check host health and agent versions. |
| **Access — Image gallery / versioning** | Rights to view and deploy previous image versions from the Shared Image Gallery or equivalent store. *(Elevated)* |
| **Access — Event Viewer (remote)** | Ability to connect to affected session hosts via remote Event Viewer or log analytics workspace. |
| **Tool — Azure portal or Az CLI** | Logged in and targeted at the correct subscription and resource group. |
| **Tool — Remote desktop client** | To validate a test logon post-fix. |
| **Information — Previous known-good image version** | Confirm the image version used by POOL-FIN-02 (unaffected pool) — this is your rollback target. Record the version ID before starting. |
| **Information — Affected host list** | List all session hosts in POOL-FIN-01. Obtain this before starting. |
| **Communication** | Notify the service desk and affected users that maintenance is in progress before draining hosts. |

---

## Procedure

### Phase 1 — Contain the incident

**Step 1.** Open the Azure portal ([portal.azure.com](https://portal.azure.com)). In the top search bar type **Azure Virtual Desktop** and select it. In the left menu select **Host pools**, then click **POOL-FIN-01**, then select **Session hosts** from the left menu of that host pool blade.  
*Expected result:* A table loads listing every session host in POOL-FIN-01, each row showing a host name (e.g. SHFIN-01-A), a Status column, and an Agent version column. If the table is empty or the blade does not load, stop and verify you are in the correct subscription.

**Step 2.** *(Elevated — AVD Host Pool Contributor or higher required)*  
From the **POOL-FIN-01** host pool overview blade, select **Properties** in the left menu. Scroll down to the **Validation environment** section and locate the **Start VM on connect** toggle. Then scroll further to find **Assignment type** — immediately above the Save button locate the **Drain mode** toggle and set it to **On**. Click **Save**.  
*Expected result:* A notification banner appears: *"Host pool updated successfully."* Return to **Session hosts** — the Status column for each host now shows **Available (Drain)** rather than **Available**. Users already connected keep their sessions; no new sessions can start on this pool.

**Step 3.** Send a message to the service desk channel (Teams / ticketing system) with the following information: POOL-FIN-01 is in drain mode, all new and reconnecting users must be directed to POOL-FIN-02 until further notice. Include your name and the incident ticket reference.  
*Expected result:* Service desk acknowledges in writing (Teams reply or ticket note) that they are routing users to POOL-FIN-02. Do not proceed to Step 4 without this acknowledgement.

**Step 4.** *(Elevated — AVD Host Pool Contributor or higher required)*  
Still on the **Session hosts** tab of POOL-FIN-01, click the name of the first affected host (e.g. **SHFIN-01-A**). In the host detail blade select **Sessions** from the left menu. For each session listed, tick the checkbox next to the session and click **Send message** first (message text: *"Your session is being disconnected for maintenance. Please reconnect in a few minutes."*) then click **Log off** for sessions that do not self-disconnect within 2 minutes.  
Repeat for each affected host.  
*Expected result:* The Sessions list for each host shows zero active sessions. Users will receive the message, disconnect, and be able to reconnect via POOL-FIN-02.

---

### Phase 2 — Confirm root cause on a single host before reimaging all hosts

**Step 5.** On your local workstation, open **Event Viewer** (`eventvwr.msc`). In the left pane right-click **Event Viewer (Local)** and select **Connect to Another Computer...**. Enter `SHFIN-01-A` and click **OK**. Expand **Windows Logs > Application**. Right-click **Application** and select **Filter Current Log...**. In the **Event IDs** field enter `1000`. In the **Event sources** field enter `Application Error`. Click **OK**.  
In the filtered results, look for entries where the Description contains both `dwm.exe` and `igdumd64.dll`. If the log is large, right-click and use **Find** (Ctrl+F), search for `igdumd64`.  
*Expected result:* You find at least one event matching all of: Event ID = 1000, Source = Application Error, description text contains `Faulting application name: dwm.exe` and `Faulting module name: igdumd64.dll`. The timestamps fall between 07:00 and 07:30. If you see this, the root cause is confirmed — continue to Step 6. If you do not see this, stop and escalate; do not proceed with the rollback.

**Step 6.** Without closing the Event Viewer connection to SHFIN-01-A, right-click **Event Viewer (Local)** again, select **Connect to Another Computer...**, enter `SHFIN-02-A`, and click **OK**. Navigate to **Windows Logs > Application** on SHFIN-02-A and apply the same filter (Event ID 1000, Source = Application Error). Also navigate to **Windows Logs > System**, filter for Event ID `9011`.  
*Expected result:* On SHFIN-02-A — zero Event ID 1000 entries for `dwm.exe` / `igdumd64.dll` in the 07:00–07:30 window; at least one Event ID 9011 present (DWM started successfully). This confirms the crash is isolated to the updated POOL-FIN-01 image and not a platform-wide fault.

> **Stop here if Step 5 does not show the expected crash signature.** The root cause may differ from this runbook. Escalate and do not proceed with the image rollback until the actual cause is confirmed.

---

### Phase 3 — Restore service by rolling back to known-good image

**Step 7.** In the Azure portal go to **Azure Virtual Desktop > Host pools > POOL-FIN-01**. In the left menu select **Properties**. Scroll to the **Virtual machine image** section. Write down the exact value shown in the **Image** field (publisher, offer, SKU, and version string, e.g. `MicrosoftWindowsDesktop / windows-11 / win11-23h2-avd / 22631.3374.240405`). Store this in the incident ticket before touching anything else.  
*Expected result:* You have a written record of the current faulty image version. If you skip this step you will not be able to roll back cleanly.

**Step 8.** *(Elevated — AVD Host Pool Contributor and Shared Image Gallery Reader required)*  
Still on **Properties**, click **Edit** (or the pencil icon) next to the **Image** field. In the image picker, select **See all images**, then choose **My images** tab and navigate to the Shared Image Gallery. Select the known-good image version recorded in Prerequisites (the version matching POOL-FIN-02). Click **Select**, then click **Save** on the Properties blade.  
*Expected result:* The **Image** field on the Properties blade now shows the known-good version string you selected. The portal shows a *"Host pool updated successfully"* notification. Note: no hosts have been reimaged yet — this change only sets what image will be used the next time a host is reimaged.

**Step 9.** *(Elevated — AVD Host Pool Contributor required)*  
Go to **POOL-FIN-01 > Session hosts**. Click the name of the first host in the list (e.g. **SHFIN-01-A**). In the host detail blade click **Reimage** at the top of the blade. A confirmation dialog appears — verify the image version shown in the dialog matches the known-good version from Step 8, then click **Reimage** to confirm.  
*Expected result:* The host Status changes to **Unavailable** and then **Upgrading**. This is normal. The reimage typically takes 10–20 minutes. Do not reimage any other host until this host returns to **Available (Drain)** status — keep refreshing the Session hosts list every 2 minutes.

**Step 10.** Once SHFIN-01-A shows **Available (Drain)**, open your Remote Desktop client, connect to the AVD workspace, and log on using the **test account** (do not use a personal or live user account). Wait 90 seconds from the moment the session connects.  
While waiting, watch for: screen going black and session disconnecting (failure), or the Windows desktop loading and remaining stable (success).  
*Expected result:* The Windows taskbar, desktop icons, and Start menu are all visible within 90 seconds. The session stays connected. No black screen occurs and the Remote Desktop client does not show a disconnect or reconnect prompt. If this passes, the rollback is working — continue to Step 11. If black screen or disconnect occurs, stop immediately and go to Rollback section.

**Step 11.** *(Elevated — AVD Host Pool Contributor required)*  
Return to **POOL-FIN-01 > Session hosts**. Select the checkboxes for the next two hosts (e.g. SHFIN-01-B and SHFIN-01-C). Click **Reimage** in the top action bar. Confirm the image version in the dialog matches the known-good version, then click **Reimage**.  
Wait for both hosts to return to **Available (Drain)** before selecting the next batch. Repeat in batches of two or three until all hosts are reimaged.  
*Expected result:* Every host in the Session hosts table shows **Available (Drain)** with the reimaged timestamp updated to today. No host remains in **Upgrading** or **Unavailable** for more than 25 minutes — if one does, see Rollback step R1.

**Step 12.** *(Elevated — AVD Host Pool Contributor required)*  
Go to **POOL-FIN-01 > Properties**. Locate the **Drain mode** toggle and set it to **Off**. Click **Save**.  
*Expected result:* Portal shows *"Host pool updated successfully."* Return to **Session hosts** — each host now shows **Available** (without the Drain label). Open the AVD workspace URL and confirm the POOL-FIN-01 pool appears as an available resource for users.

---

### Phase 4 — Parallel: Prepare a fixed image (do not block service restoration on this)

> This phase runs in parallel with Phase 3, assigned to a second engineer where possible. It must not delay service restoration.

**Step 13.** On the image build workstation, open the image pipeline tool (e.g. Packer, Azure Image Builder, or your organisation's image build portal). Clone or branch from the known-good image version recorded in Prerequisites — do not branch from the faulty overnight build. Label the new branch clearly, e.g. `POOL-FIN-01-driver-fix-YYYYMMDD`.  
Within the image, navigate to the Intel graphics driver installation step. Replace the Intel graphics driver package with a version that does not contain the faulty `igdumd64.dll` build — use the driver version present in the known-good image as the minimum safe baseline. Record the old and new driver version strings in the incident ticket.  
*Expected result:* The image build pipeline shows the new driver package reference in the build manifest. The old (faulty) driver package is no longer referenced. Build has not been triggered yet.

**Step 14.** Trigger a build of the test image branch and deploy it to a single **isolated non-production test host** — not any host in POOL-FIN-01 or POOL-FIN-02. Once the host is available, log on five times consecutively with the same test account, fully logging off between each attempt. After all five logons, open Event Viewer on the test host (**Windows Logs > Application**, filter Event ID = 1000, Source = Application Error) and check for `dwm.exe` / `igdumd64.dll` entries.  
*Expected result:* Zero Event ID 1000 entries for `dwm.exe` across all five logon cycles. Event ID 9011 (DWM started successfully) is present in the System log after each logon. Desktop loaded cleanly each time with no black screen. If any crash is found, do not proceed to Step 15 — return to the image branch and investigate the driver further.

**Step 15.** Raise a change request in the ITSM tool (e.g. ServiceNow) referencing this incident ticket. Attach: the image build manifest showing the old and new driver versions, the test results from Step 14 (screenshots of clean Event Viewer output), and the peer-review sign-off. Submit through the standard CAB or expedited approval route as appropriate.  
*Expected result:* The change request is approved and the fixed image version is published to the Shared Image Gallery with a clear version label (e.g. `...DriverFix-YYYYMMDD`). It is ready to be applied to POOL-FIN-01 at the next scheduled maintenance window.

---

## Verification

Perform all checks below before marking the incident as resolved and closing the ticket.

**V1.** For each reimaged POOL-FIN-01 host, open Event Viewer remotely (right-click **Event Viewer (Local) > Connect to Another Computer**, enter the host name). Go to **Windows Logs > Application**. Right-click and select **Filter Current Log** — set Event ID to `1000` and Event source to `Application Error`. Look at all entries from the last 60 minutes.  
*Pass:* The filtered list is empty, or contains no entries where the description includes `dwm.exe` and `igdumd64.dll`.  
*Fail:* Any entry shows `Faulting application name: dwm.exe` and `Faulting module name: igdumd64.dll` — do not close the incident; go to Rollback step R2.

**V2.** On each reimaged POOL-FIN-01 host, still in Event Viewer, go to **Windows Logs > System**. Filter for Event ID `9011`, source `Desktop Window Manager`. Check entries generated after the reimage completed (timestamp after the reimage finish time noted in Step 9/11).  
*Pass:* At least one Event ID 9011 with description *"The Desktop Window Manager has started successfully"* is present after the reimage timestamp, and no Event ID 9009 (DWM exit) follows it within the same session.  
*Fail:* Event 9009 appears after logon with no subsequent 9011, meaning DWM is still crashing — do not close; go to Rollback step R2.

**V3.** Open your Remote Desktop client. Connect to the AVD workspace and select POOL-FIN-01. Log on with the test account. Start a stopwatch. Watch the session continuously for 90 seconds without clicking anything.  
*Pass:* The full Windows desktop (taskbar visible at the bottom, desktop icons visible, Start button responsive) loads within 90 seconds and the session remains connected for the full 90 seconds without any black screen or disconnect.  
*Fail:* The screen goes black at any point, or the Remote Desktop client shows a *"Reconnecting..."* or *"Session ended"* message within 90 seconds — go to Rollback step R2.

**V4.** Check the service desk ticket queue and the Teams incident channel. Count the number of new black-screen reports raised in the 30 minutes since drain mode was removed in Step 12.  
*Pass:* Zero new black-screen reports for POOL-FIN-01 users in the 30-minute window.  
*Fail:* One or more new reports in that window — do not close; re-enable drain mode (Rollback step R2), identify which hosts users are landing on, and check whether those hosts completed reimaging successfully.

**V5.** In the Azure portal go to **Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts**. Review the **Status** column for every row.  
*Pass:* Every host shows **Available** (green). The **Drain mode** column (if visible) shows **Off** for all hosts. No host shows **Unavailable**, **Upgrading**, or **Available (Drain)**.  
*Fail:* Any host still shows **Unavailable** or **Available (Drain)** — do not close; resolve the individual host status before marking the incident resolved.

---

## Rollback

> **TARGET: complete R1–R3 within 3 minutes of deciding to roll back.**  
> Read the trigger for each step first, then act only on the one that applies. You do not need to run all steps.

---

### R1 — Stop users hitting the broken pool immediately

**Trigger:** Black screen is still occurring after reimaging, OR you have decided to abort the procedure at any point.

*(Elevated — AVD Host Pool Contributor required)*

1. Go to [portal.azure.com](https://portal.azure.com). In the top search bar type `Azure Virtual Desktop` and press Enter.
2. In the left menu click **Host pools**, then click **POOL-FIN-01**.
3. In the left menu of the host pool blade click **Properties**.
4. Scroll down to the **Drain mode** toggle. Set it to **On**.
5. Click **Save**.

*You know it worked when:* The portal shows *"Host pool updated successfully"* and the Session hosts list shows **Available (Drain)** next to every host. No new user sessions can now start on POOL-FIN-01.

*Elapsed time target: under 90 seconds.*

---

### R2 — Revert the host pool to the previous image version

**Trigger:** R1 is done AND the reimaged hosts are still crashing (verified in V1/V2), meaning the known-good image version applied in Step 8 has not resolved the fault.  
**Prerequisite:** You recorded the faulty image version string in Step 7. Retrieve it now from the incident ticket before continuing.

*(Elevated — AVD Host Pool Contributor and Shared Image Gallery Reader required)*

1. Still on **POOL-FIN-01 > Properties**, scroll to the **Virtual machine image** section.
2. Click **Edit** (pencil icon) next to the **Image** field.
3. In the image picker select **See all images > My images**, navigate to the Shared Image Gallery, and select the image version string you recorded in Step 7.
4. Click **Select**, then click **Save**.
5. The portal shows *"Host pool updated successfully"*. The Image field now shows the Step 7 version string.
6. Go to **POOL-FIN-01 > Session hosts**. Select the checkbox for every host. Click **Reimage** in the top action bar. Confirm the image version in the dialog matches the Step 7 version string. Click **Reimage**.

*You know it worked when:* All hosts move to **Upgrading** status. Reimaging takes 10–20 minutes per batch. Do not wait here — hand off to the on-call engineer and escalate to the AVD platform team immediately, as the rollback target itself may be unstable.

*Elapsed time target for steps 1–6: under 90 seconds.*

---

### R3 — Remove a host that is stuck and will not recover

**Trigger:** A single host has remained in **Unavailable** or **Upgrading** status for more than 25 minutes after a reimage attempt, while other hosts completed normally.

*(Elevated — AVD Host Pool Contributor required)*

1. Go to **Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts**.
2. Click the name of the stuck host.
3. At the top of the host detail blade click **Remove**. Confirm the removal in the dialog.
4. Open a support ticket with Microsoft Azure Support. Include: host name, resource group, host pool name, timestamp of the reimage action, and the current Status shown in the portal before removal.

*You know it worked when:* The host no longer appears in the Session hosts list. Remaining hosts are unaffected.

*Elapsed time target: under 60 seconds.*

---

### R4 — Discard a broken test image branch (Phase 4 only)

**Trigger:** A test logon in Step 14 reveals dwm.exe crashes persist in the new image branch.

1. In your image build tool (Packer / Azure Image Builder / internal build portal), delete or archive the current test branch labelled `POOL-FIN-01-driver-fix-YYYYMMDD`.
2. Do not merge it and do not publish it to the Shared Image Gallery.
3. Create a new branch from the known-good image baseline (the same version used for POOL-FIN-02) and restart the driver investigation from Step 13.

*You know it worked when:* The faulty branch no longer appears in the active build list and the Shared Image Gallery contains no new version derived from it.

---

## Notes

**Edge cases**

- **Mixed host states:** If only some hosts in POOL-FIN-01 were updated overnight (partial rollout), you may find hosts on different image versions. Check the image version on each host individually before reimaging — do not assume all hosts are on the faulty version.
- **Persistent users:** Some users may have pinned sessions or personal host assignments within POOL-FIN-01. Identify these before draining — they cannot simply be redirected to POOL-FIN-02 without profile migration.
- **FSLogix profile containers:** If a user's FSLogix container was in mid-attach during a DWM crash, the container may be left in a locked state. If a user reports they still cannot log in cleanly after the fix, check the FSLogix operational log on their assigned host for container lock errors and run the FSLogix profile reset process for that user.

**Warnings**

- Do not apply the faulty updated image to any other pool while this incident is open.
- Do not reimage more than three hosts simultaneously — reimaging all hosts at once leaves zero capacity in POOL-FIN-01 and extends the impact window.
- The igdumd64.dll module is an Intel GPU driver component. If the AVD hosts use a different GPU vendor, this runbook's root cause confirmation steps (Step 5–6) will not match and the runbook does not apply — escalate to the platform team.

**Permissions flags summary**

Steps requiring elevated permissions (AVD Host Pool Contributor or higher): **2, 8, 9, 11, 12, R1, R2, R3**.  
Steps requiring image gallery write access: **8, 13, 15**.

**Related incidents and records**

- RCA: `DAY4/RCA-avd-black-screen-POOL-FIN-01-2024-03-15.md`
- Known error record: `DAY4/known-error-record-avd-black-screen-2024-03-15.md`
- Closure note: `DAY4/closure-note-avd-black-screen-2024-03-15.md`
- Hypothesis analysis: `DAY4/avd-incident-analysis-hypothesis-2024-03-15.md`
