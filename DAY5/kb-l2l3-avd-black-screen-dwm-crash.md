---

| Field   | Detail                                                                   |
|---------|--------------------------------------------------------------------------|
| Version | 1.0                                                                      |
| Date    | 07/08/2026                                                               |
| Status  | Draft                                                                    |

---

# KB (L2/L3): AVD Black Screen — DWM Crash Caused by Graphics Driver Regression in Image Update

---

## 1. Background

Azure Virtual Desktop (AVD) delivers Windows desktop sessions from shared session host virtual machines running in Azure. Users connect via the AVD client or browser; the session is rendered on the host and streamed to the user's device.

The **Desktop Window Manager (dwm.exe)** is the Windows process responsible for compositing and rendering the graphical desktop. If dwm.exe crashes, the user's session loses its display — the screen goes black and the Remote Desktop client disconnects or shows a reconnect prompt. dwm.exe typically restarts automatically, but if the underlying cause persists (e.g. a faulty graphics driver component), it will crash again immediately on reconnection, producing a repeating black screen loop.

Session hosts in POOL-FIN-01 are used exclusively by Finance team staff. This pool is business-critical during core hours (08:00–17:00). A full-pool outage directly prevents Finance users from accessing their desktops and any applications delivered through them.

---

## 2. Symptoms

### What the engineer observes

- Multiple session hosts in **POOL-FIN-01** showing **Unavailable** or generating rapid disconnect/reconnect cycles in the AVD host health blade.
- Event ID **1000** (Application Error) entries in `Windows Logs > Application` on affected hosts, with:
  - `Faulting application name: dwm.exe`
  - `Faulting module name: igdumd64.dll`
- Event ID **9009** (DWM exited) in `Windows Logs > System` on affected hosts, with no subsequent Event ID **9011** (DWM restarted successfully) within the same session.
- The incident time-stamps cluster in a narrow window (e.g. 07:00–07:30) coinciding with an overnight image update deployment.
- POOL-FIN-02 (Finance overflow pool, not updated overnight) is **unaffected** — no equivalent errors on its hosts.

### What users report

- Work screen goes black immediately or within seconds of signing in.
- Screen does not recover — repeated sign-in attempts produce the same result.
- No error message in most cases; some users see a generic "Remote Desktop disconnected" prompt.
- Issue started suddenly at the beginning of the working day with no user-side change.

---

## 3. Root Cause

An overnight automated image update deployed a new Intel graphics driver version to POOL-FIN-01 session hosts. The updated driver introduced a regression in `igdumd64.dll` — the Intel user-mode graphics driver component. On each session logon, dwm.exe loads `igdumd64.dll` during desktop composition initialisation. The faulty DLL causes dwm.exe to crash immediately, producing a black screen before the desktop fully renders. dwm.exe attempts an automatic restart but crashes again on the same DLL load, creating a crash loop.

**Evidence that confirms this specific cause:**

| Evidence | Location | What to look for |
|---|---|---|
| Event ID 1000 on affected hosts | `Windows Logs > Application` | `Faulting application name: dwm.exe`, `Faulting module name: igdumd64.dll` |
| Event ID 9009 without 9011 on affected hosts | `Windows Logs > System` | DWM exiting with no clean restart following it |
| Absence of same events on POOL-FIN-02 | `Windows Logs > Application` on SHFIN-02-A | Zero matching Event ID 1000 entries in the same time window |
| Image version mismatch between pools | Azure portal > AVD > Host pools > Properties > Image field | POOL-FIN-01 on newer (faulty) version; POOL-FIN-02 on previous (known-good) version |

---

## 4. Detection

Work through these checks in order. **Target: complete D1–D5 in under 3 minutes using the PowerShell commands provided.** Do not skip to Resolution until all checks are complete. If any check does not match the expected result, **stop and escalate** — this runbook does not apply.

> **Quick path:** Run the PowerShell commands in D2–D5 from your local workstation. They query the remote host's event logs directly — no GUI clicking required. Replace `SHFIN-01-A` with the actual affected host name.

---

### D1 — Check session host health in the Azure portal

**Path:** `portal.azure.com > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts`

**What to look for:**
- `Status` column shows **Unavailable** on one or more hosts.
- Hosts may alternate rapidly between **Available** and **Unavailable** if dwm.exe is in a crash-restart loop.

**Pass:** At least one host in POOL-FIN-01 shows **Unavailable** and user reports align with the start of the working day or an overnight maintenance window.  
**Fail / different pattern:** If hosts are **Available** but users are reporting black screens only intermittently, the cause may differ — do not proceed with this runbook.

---

### D2 — Confirm the crash signature on an affected host (Event ID 1000, Application log)

**Log:** `Application` log on the affected host — Source: `Application Error` — Event ID: `1000`  
**Field to check in the event description:** `Faulting module name: igdumd64.dll`

**PowerShell (fastest — run from your local workstation):**

```powershell
Get-WinEvent -ComputerName SHFIN-01-A -FilterHashtable @{
    LogName      = 'Application'
    Id           = 1000
    ProviderName = 'Application Error'
} -MaxEvents 20 |
Where-Object { $_.Message -match 'dwm\.exe' -and $_.Message -match 'igdumd64\.dll' } |
Select-Object TimeCreated, Message |
Format-List
```

**Manual (Event Viewer fallback):**
1. Run `eventvwr.msc`. Right-click **Event Viewer (Local)** > **Connect to Another Computer** > enter `SHFIN-01-A`.
2. Expand **Windows Logs > Application**.
3. Right-click **Application** > **Filter Current Log** > Event ID: `1000`, Source: `Application Error`.
4. In results, open entries and confirm the `General` tab contains both `Faulting application name: dwm.exe` and `Faulting module name: igdumd64.dll`.

**Pass:** At least one event returned with `Faulting application name: dwm.exe` and `Faulting module name: igdumd64.dll`. Timestamps cluster around the reported incident start.  
**Fail:** No results, or the faulting module is not `igdumd64.dll` — the crash has a different cause. Stop and investigate before proceeding.

---

### D3 — Confirm DWM is not restarting cleanly (Event IDs 9009 and 9011, System log)

**Log:** `System` log on the affected host — Source: `Desktop Window Manager` — Event IDs: `9009` (DWM exit) and `9011` (DWM started successfully)

**PowerShell:**

```powershell
# Check for DWM crash events (9009) — should be present on affected host
Get-WinEvent -ComputerName SHFIN-01-A -FilterHashtable @{
    LogName      = 'System'
    Id           = 9009
    ProviderName = 'Desktop Window Manager'
} -MaxEvents 10 | Select-Object TimeCreated, Id, Message | Format-List

# Check for DWM healthy-start events (9011) — should be ABSENT or have no entry after each 9009
Get-WinEvent -ComputerName SHFIN-01-A -FilterHashtable @{
    LogName      = 'System'
    Id           = 9011
    ProviderName = 'Desktop Window Manager'
} -MaxEvents 10 | Select-Object TimeCreated, Id, Message | Format-List
```

Compare timestamps: a 9009 with **no 9011 following it** in the same logon session confirms the crash loop.

**Pass:** 9009 entries present; no subsequent 9011 within the incident window. DWM is crashing and not recovering.  
**Fail:** Every 9009 is followed by a 9011 — DWM is restarting successfully. The black screen has a different cause; do not proceed with this runbook.

---

### D4 — Comparative check: confirm POOL-FIN-02 is clean (healthy baseline)

**Purpose:** Prove the fault is image-specific to POOL-FIN-01, not a platform-wide issue.  
**Log (affected check):** `Application` log on `SHFIN-02-A` — Event ID `1000` — must return **zero** results for `igdumd64.dll`.  
**Log (healthy baseline check):** `System` log on `SHFIN-02-A` — Event ID `9011` — must return **at least one** result confirming DWM started successfully on the unaffected pool.

**PowerShell:**

```powershell
# Should return NO results — confirms igdumd64.dll crash is absent on POOL-FIN-02
Get-WinEvent -ComputerName SHFIN-02-A -FilterHashtable @{
    LogName      = 'Application'
    Id           = 1000
    ProviderName = 'Application Error'
} -MaxEvents 20 -ErrorAction SilentlyContinue |
Where-Object { $_.Message -match 'dwm\.exe' -and $_.Message -match 'igdumd64\.dll' } |
Select-Object TimeCreated, Message

# Should return results — confirms DWM is starting cleanly on the healthy pool (Event 9011)
Get-WinEvent -ComputerName SHFIN-02-A -FilterHashtable @{
    LogName      = 'System'
    Id           = 9011
    ProviderName = 'Desktop Window Manager'
} -MaxEvents 5 | Select-Object TimeCreated, Id, Message | Format-List
```

**Pass:** First command returns zero rows. Second command returns at least one Event ID 9011 on SHFIN-02-A. This confirms the fault is isolated to POOL-FIN-01's updated image.  
**Fail:** First command returns matching rows on SHFIN-02-A, OR second command returns zero 9011 events — the problem is platform-wide. This runbook does not apply; escalate to the AVD platform team immediately.

---

### D5 — Confirm image version mismatch between pools

**Path:** `portal.azure.com > Azure Virtual Desktop > Host pools`

1. Click **POOL-FIN-01** > left menu > **Properties** > scroll to **Virtual machine image**. Record the full version string (e.g. `MicrosoftWindowsDesktop / windows-11 / win11-23h2-avd / 22631.3374.240405`).
2. Click **POOL-FIN-02** > **Properties** > **Virtual machine image**. Record its version string.
3. Compare the version number segment (last segment). POOL-FIN-01 should be on a **newer** version than POOL-FIN-02.

**Pass:** POOL-FIN-01 version is newer than POOL-FIN-02 and the version change aligns with the overnight maintenance window.  
**Fail:** Both pools are on the same image version — the fault cannot be attributed to an image update. Stop and investigate host-level configuration differences.

---

> **All five detection checks must pass before proceeding to Resolution.**

---

### D5 — Confirm image version mismatch between pools

**Path:** `portal.azure.com > Azure Virtual Desktop > Host pools`

**Steps:**
1. Click **POOL-FIN-01** > left menu > **Properties** > scroll to **Virtual machine image** section. Record the full image version string (publisher / offer / SKU / version, e.g. `MicrosoftWindowsDesktop / windows-11 / win11-23h2-avd / 22631.3374.240405`).
2. Click **POOL-FIN-02** > **Properties** > **Virtual machine image**. Record its version string.
3. Compare the two version strings — specifically the version number segment (last segment).

**Pass:** POOL-FIN-01 is on a **newer** version than POOL-FIN-02. The version change aligns with the overnight maintenance window.  
**Fail:** Both pools are on the same image version — the fault cannot be attributed to an image update. Stop and investigate host-level configuration differences.

---

> **All five detection checks must pass before proceeding to Resolution.**

---

## 5. Resolution

> **Required permissions:** AVD Host Pool Contributor (or higher) for R1–R8. Shared Image Gallery Reader for R4–R5. Confirm access before starting.

**Set these variables once before running any commands in this section:**

```powershell
# Az PowerShell — set once, reuse throughout Resolution, Verification, and Rollback
$RG       = "rg-avd-fin-prod"       # your resource group name
$Pool     = "POOL-FIN-01"
$GoodPool = "POOL-FIN-02"           # unaffected pool — used to identify known-good image
```

```bash
# Az CLI equivalent — set once
RG="rg-avd-fin-prod"
POOL="POOL-FIN-01"
GOOD_POOL="POOL-FIN-02"
```

---

### R1 — Enable drain mode to stop new sessions landing on broken hosts

**Portal path:**
`portal.azure.com > Azure Virtual Desktop > Host pools > POOL-FIN-01 > [left menu] Properties > [scroll to] Drain mode toggle > set ON > Save`

**Az PowerShell (faster):**

```powershell
# Disable new sessions on every host in POOL-FIN-01 simultaneously
Get-AzWvdSessionHost -ResourceGroupName $RG -HostPoolName $Pool | ForEach-Object {
    $hostShortName = ($_.Name -split '/')[1]
    Update-AzWvdSessionHost -ResourceGroupName $RG -HostPoolName $Pool `
        -Name $hostShortName -AllowNewSession:$false
}
# Confirm — every host should show AllowNewSession = False
Get-AzWvdSessionHost -ResourceGroupName $RG -HostPoolName $Pool |
    Select-Object Name, Status, AllowNewSession
```

**Az CLI equivalent:**

```bash
# List all session host names then disable new sessions on each
az desktopvirtualization sessionhost list \
  --host-pool-name $POOL --resource-group $RG \
  --query "[].name" -o tsv | sed 's|.*/||' | while read HOST; do
    az desktopvirtualization sessionhost update \
      --host-pool-name $POOL --resource-group $RG \
      --name "$HOST" --allow-new-session false
done
```

**Expected result:** Every host in `POOL-FIN-01 > Session hosts` shows **Available (Drain)**. No new user sessions can start. Existing sessions are unaffected.

---

### R2 — Notify the service desk and redirect users to POOL-FIN-02

Send a message to the service desk (Teams channel or ITSM ticket) stating: POOL-FIN-01 is in drain mode; all new connections and reconnections must be directed to POOL-FIN-02 until further notice. Include your name and the incident ticket number.

**Expected result:** Service desk confirms in writing (Teams reply or ticket note) that users are being directed to POOL-FIN-02. Do not proceed to R3 until this confirmation is received.

---

### R3 — Log off remaining active sessions on all affected hosts

**Portal path:**
`portal.azure.com > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts > [click host name e.g. SHFIN-01-A] > [left menu] Sessions > [tick session checkbox] > Send message > Log off`

Repeat for every host in POOL-FIN-01.

**Az PowerShell (faster — logs off all sessions across all hosts in one pass):**

```powershell
Get-AzWvdSessionHost -ResourceGroupName $RG -HostPoolName $Pool | ForEach-Object {
    $hostShortName = ($_.Name -split '/')[1]
    Get-AzWvdUserSession -ResourceGroupName $RG -HostPoolName $Pool `
        -SessionHostName $hostShortName | ForEach-Object {
        $sessionId = ($_.Name -split '/')[2]
        Remove-AzWvdUserSession -ResourceGroupName $RG -HostPoolName $Pool `
            -SessionHostName $hostShortName -Id $sessionId -Force
    }
}
```

**Az CLI equivalent:**

```bash
az desktopvirtualization usersession list \
  --host-pool-name $POOL --resource-group $RG \
  --host-name SHFIN-01-A --query "[].name" -o tsv | sed 's|.*/||' | while read SID; do
    az desktopvirtualization usersession delete \
      --host-pool-name $POOL --resource-group $RG \
      --host-name SHFIN-01-A --user-session-id "$SID" --yes
done
# Repeat for each host name
```

**Expected result:** The Sessions list for every host in POOL-FIN-01 shows zero active sessions.

---

### R4 — Record the current (faulty) image version before making any changes

**Portal path:**
`portal.azure.com > Azure Virtual Desktop > Host pools > POOL-FIN-01 > [left menu] Properties > [scroll to] Virtual machine image > Image field (full version string)`

Copy the full value (e.g. `MicrosoftWindowsDesktop / windows-11 / win11-23h2-avd / 22631.3374.240405`) and paste it into the incident ticket under the heading: **"Faulty image version — recorded before rollback."**

**Az PowerShell (read current image reference from host pool):**

```powershell
# Retrieves the vmTemplate JSON blob — parse imageVersion from it
$template = Get-AzWvdHostPool -ResourceGroupName $RG -Name $Pool |
    Select-Object -ExpandProperty VmTemplate | ConvertFrom-Json
$template | Select-Object imageType, galleryImageOffer, galleryImageSku, galleryImageVersion
```

**Az CLI equivalent:**

```bash
az desktopvirtualization hostpool show \
  --name $POOL --resource-group $RG \
  --query "vmTemplate" -o json
# The output is a JSON string — look for galleryImageVersion or customImageId
```

**Expected result:** The version string is saved in the incident ticket. This is your exact recovery point for Rollback step RB2.

---

### R5 — Set the host pool image reference to the known-good version

> **This step is safest done via the Azure portal.** Updating `vmTemplate` via CLI requires constructing the full JSON blob — a mistake here will apply the wrong image to all hosts on reimage. Use the portal to select the image visually and confirm the version string before saving.

**Portal path:**
`portal.azure.com > Azure Virtual Desktop > Host pools > POOL-FIN-01 > [left menu] Properties > [scroll to] Virtual machine image > [click] Edit (pencil icon) > See all images > My images tab > [navigate] Shared Image Gallery > [select known-good version matching POOL-FIN-02] > Select > Save`

Before clicking Save, verify the **Image** field shows the same version string as POOL-FIN-02 (from Detection step D5).

**Az PowerShell (to read POOL-FIN-02's image as your target — confirm before applying):**

```powershell
# Read the known-good image version from the unaffected pool for reference
$goodTemplate = Get-AzWvdHostPool -ResourceGroupName $RG -Name $GoodPool |
    Select-Object -ExpandProperty VmTemplate | ConvertFrom-Json
$goodTemplate | Select-Object imageType, galleryImageOffer, galleryImageSku, galleryImageVersion
```

**Expected result:** Portal notification: *"Host pool updated successfully."* The **Image** field under `POOL-FIN-01 > Properties > Virtual machine image` now shows the known-good version string. No hosts have been reimaged yet — this only sets the target for the next reimage.

---

### R6 — Reimage the first host and validate before reimaging the rest

**Portal path:**
`portal.azure.com > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts > [click host name SHFIN-01-A] > [top of blade] Reimage button > [confirm dialog — verify image version shown matches R5] > Reimage`

Wait until SHFIN-01-A shows **Available (Drain)**. Expected: 10–20 minutes. Then log on with the test account and watch for 90 seconds (see Verification V3).

**Az PowerShell (reimage a single host):**

```powershell
# Reimages the underlying VM — AVD agent re-registers automatically after restart
Invoke-AzVMReimage -ResourceGroupName $RG -VMName "SHFIN-01-A"

# Poll status every 60 s until Available
do {
    Start-Sleep -Seconds 60
    $status = Get-AzWvdSessionHost -ResourceGroupName $RG -HostPoolName $Pool -Name "SHFIN-01-A"
    Write-Host "$(Get-Date -Format HH:mm:ss) — Status: $($status.Status)"
} until ($status.Status -eq 'Available')
```

**Az CLI equivalent:**

```bash
az vm reimage --resource-group $RG --name SHFIN-01-A --no-wait

# Poll status
watch -n 60 "az desktopvirtualization sessionhost show \
  --host-pool-name $POOL --resource-group $RG \
  --name SHFIN-01-A --query 'status' -o tsv"
```

**Expected result:** SHFIN-01-A returns to **Available (Drain)**. Test logon (Verification V3) shows a stable desktop for 90 seconds with no black screen. If black screen recurs on this host, go to Rollback step RB1 immediately.

---

### R7 — Reimage remaining hosts in batches of two or three

**Portal path:**
`portal.azure.com > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts > [tick checkboxes for 2–3 hosts] > [top action bar] Reimage > [confirm dialog — verify image version] > Reimage`

Wait for each batch to show **Available (Drain)** before selecting the next batch.

**Az PowerShell (reimage all remaining hosts sequentially in batches):**

```powershell
# Skip SHFIN-01-A — already reimaged in R6
$remainingHosts = Get-AzWvdSessionHost -ResourceGroupName $RG -HostPoolName $Pool |
    Where-Object { $_.Name -notmatch 'SHFIN-01-A' } |
    ForEach-Object { ($_.Name -split '/')[1] }

# Reimage in batches of 2
$batch = 2
for ($i = 0; $i -lt $remainingHosts.Count; $i += $batch) {
    $currentBatch = $remainingHosts[$i..([Math]::Min($i + $batch - 1, $remainingHosts.Count - 1))]
    $currentBatch | ForEach-Object { Invoke-AzVMReimage -ResourceGroupName $RG -VMName $_ -AsJob }
    Write-Host "Reimaging batch: $($currentBatch -join ', ') — waiting for completion..."
    Get-Job | Wait-Job | Remove-Job
    # Brief pause to allow AVD agent re-registration
    Start-Sleep -Seconds 120
}
```

**Expected result:** Every host in `POOL-FIN-01 > Session hosts` shows **Available (Drain)** with today's reimaged timestamp. No host remains in **Upgrading** or **Unavailable** for more than 25 minutes. If one does, see Rollback step RB3.

---

### R8 — Disable drain mode to restore user access

**Portal path:**
`portal.azure.com > Azure Virtual Desktop > Host pools > POOL-FIN-01 > [left menu] Properties > [scroll to] Drain mode toggle > set OFF > Save`

**Az PowerShell:**

```powershell
# Re-enable new sessions on all hosts in POOL-FIN-01
Get-AzWvdSessionHost -ResourceGroupName $RG -HostPoolName $Pool | ForEach-Object {
    $hostShortName = ($_.Name -split '/')[1]
    Update-AzWvdSessionHost -ResourceGroupName $RG -HostPoolName $Pool `
        -Name $hostShortName -AllowNewSession:$true
}
# Confirm
Get-AzWvdSessionHost -ResourceGroupName $RG -HostPoolName $Pool |
    Select-Object Name, Status, AllowNewSession
```

**Az CLI equivalent:**

```bash
az desktopvirtualization sessionhost list \
  --host-pool-name $POOL --resource-group $RG \
  --query "[].name" -o tsv | sed 's|.*/||' | while read HOST; do
    az desktopvirtualization sessionhost update \
      --host-pool-name $POOL --resource-group $RG \
      --name "$HOST" --allow-new-session true
done
```

**Expected result:** Portal notification: *"Host pool updated successfully."* Every host in `POOL-FIN-01 > Session hosts > Status column` now shows **Available** (no Drain label). Users can sign in to POOL-FIN-01 normally.

---

## 6. Verification

Perform all five checks before marking the incident resolved. A single fail result means the incident is not closed — action the fail instruction before proceeding.

---

### V1 — No crash events on reimaged hosts (Application log, Event ID 1000)

**Portal path:** n/a — use PowerShell below

**Az PowerShell (run against each reimaged host):**

```powershell
# Returns results only if the crash is still occurring — expected: no output
Get-WinEvent -ComputerName SHFIN-01-A -FilterHashtable @{
    LogName      = 'Application'
    Id           = 1000
    ProviderName = 'Application Error'
} -MaxEvents 20 -ErrorAction SilentlyContinue |
Where-Object { $_.Message -match 'dwm\.exe' -and $_.Message -match 'igdumd64\.dll' } |
Select-Object TimeCreated, Message
```

**Pass:** No output returned.  
**Fail:** Any result returned — go to RB1 immediately.

---

### V2 — DWM starting cleanly post-reimage (System log, Event ID 9011)

**Portal path:** n/a — use PowerShell below

**Az PowerShell:**

```powershell
# Should return at least one event after the reimage timestamp
Get-WinEvent -ComputerName SHFIN-01-A -FilterHashtable @{
    LogName      = 'System'
    Id           = 9011
    ProviderName = 'Desktop Window Manager'
} -MaxEvents 5 | Select-Object TimeCreated, Id, Message | Format-List
```

**Pass:** At least one Event ID 9011 (*"Desktop Window Manager has started successfully"*) with a timestamp after the reimage completed. No Event ID 9009 follows it without a subsequent 9011.  
**Fail:** Zero results, or a 9009 appears after the most recent 9011 — go to RB1.

---

### V3 — Test logon stable for 90 seconds

**Path:** Remote Desktop client > connect to AVD workspace > select **POOL-FIN-01** > sign in with test account (not a personal or live account)

Watch the session continuously for 90 seconds from the moment it connects.

**Pass:** Full Windows desktop (taskbar, desktop icons, Start button) visible within 90 seconds. No black screen. Remote Desktop client shows no *"Reconnecting…"* or *"Session ended"* prompt.  
**Fail:** Black screen at any point, or client disconnects — go to RB1.

---

### V4 — All hosts showing Available in the portal

**Portal path:**
`portal.azure.com > Azure Virtual Desktop > Host pools > POOL-FIN-01 > [left menu] Session hosts > Status column (all rows)`

**Az PowerShell:**

```powershell
Get-AzWvdSessionHost -ResourceGroupName $RG -HostPoolName $Pool |
    Select-Object Name, Status, AllowNewSession | Format-Table -AutoSize
```

**Pass:** Every row shows `Status = Available` and `AllowNewSession = True`. No host shows `Unavailable`, `Upgrading`, or `AllowNewSession = False`.  
**Fail:** Any host still shows `Unavailable` or `AllowNewSession = False` — resolve that individual host before closing the incident.

---

### V5 — No new black-screen reports in the 30-minute window after drain mode was disabled

**Path:** Service desk ticket queue and Teams incident channel

Count new tickets for POOL-FIN-01 black screen raised in the 30 minutes after R8 completed.

**Pass:** Zero new reports.  
**Fail:** One or more new reports — re-enable drain mode using R1 commands, identify which hosts users are landing on, and check whether those hosts completed reimaging. Go to RB1.

---

## 7. Rollback

> **Target: RB1 complete within 90 seconds of deciding to roll back. Use the PowerShell commands — faster than portal navigation under pressure.**

Use the same variable block defined at the top of Section 5 (`$RG`, `$Pool`).

---

### RB1 — Immediately stop users hitting broken hosts (drain mode on)

**Trigger:** Black screen persists after reimaging, or you are aborting at any point in the procedure.

**Portal path:**
`portal.azure.com > Azure Virtual Desktop > Host pools > POOL-FIN-01 > [left menu] Properties > [scroll to] Drain mode toggle > set ON > Save`

**Az PowerShell (use this — faster than portal):**

```powershell
Get-AzWvdSessionHost -ResourceGroupName $RG -HostPoolName $Pool | ForEach-Object {
    $hostShortName = ($_.Name -split '/')[1]
    Update-AzWvdSessionHost -ResourceGroupName $RG -HostPoolName $Pool `
        -Name $hostShortName -AllowNewSession:$false
}
Get-AzWvdSessionHost -ResourceGroupName $RG -HostPoolName $Pool |
    Select-Object Name, Status, AllowNewSession
```

**You know it worked when:** Every host shows `AllowNewSession = False`. Portal `POOL-FIN-01 > Session hosts > Status` column shows **Available (Drain)** on all rows.

---

### RB2 — Revert host pool image to the pre-change version and reimage all hosts

**Trigger:** RB1 is complete AND V1/V2 show crashes continuing after reimaging to the known-good version.

**Prerequisite:** Retrieve the faulty image version string saved in the incident ticket during R4.

**Portal path (set image back to R4 version):**
`portal.azure.com > Azure Virtual Desktop > Host pools > POOL-FIN-01 > [left menu] Properties > [scroll to] Virtual machine image > [click] Edit (pencil icon) > See all images > My images tab > Shared Image Gallery > [select the version string from R4] > Select > Save`

Confirm the **Image** field under `POOL-FIN-01 > Properties > Virtual machine image` shows the R4 version string before proceeding.

**Portal path (reimage all hosts to restored image):**
`portal.azure.com > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts > [tick all checkboxes] > [top action bar] Reimage > [confirm dialog — verify image version matches R4] > Reimage`

**Az PowerShell (reimage all hosts to restored image — run after portal image update above):**

```powershell
# After updating the image reference in the portal, reimage all hosts
Get-AzWvdSessionHost -ResourceGroupName $RG -HostPoolName $Pool |
    ForEach-Object { ($_.Name -split '/')[1] } |
    ForEach-Object { Invoke-AzVMReimage -ResourceGroupName $RG -VMName $_ -AsJob }

# Wait for all reimage jobs
Get-Job | Wait-Job | Select-Object Name, State
```

**You know it worked when:** All hosts return to **Available (Drain)** with a new reimaged timestamp. Escalate to the AVD platform team immediately — if both the faulty and known-good images crash, the root cause is not the image and this runbook does not apply.

---

### RB3 — Remove a host stuck in Upgrading or Unavailable

**Trigger:** A single host has remained in **Upgrading** or **Unavailable** for more than 25 minutes while all other hosts completed normally.

**Portal path:**
`portal.azure.com > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts > [click stuck host name] > [top of blade] Remove button > confirm removal`

**Az PowerShell:**

```powershell
# Replace SHFIN-01-B with the actual stuck host short name
Remove-AzWvdSessionHost -ResourceGroupName $RG -HostPoolName $Pool -Name "SHFIN-01-B" -Force
# Confirm removal
Get-AzWvdSessionHost -ResourceGroupName $RG -HostPoolName $Pool | Select-Object Name, Status
```

**Az CLI equivalent:**

```bash
az desktopvirtualization sessionhost delete \
  --host-pool-name $POOL --resource-group $RG \
  --name SHFIN-01-B --yes
```

After removing, raise an Azure Support ticket with: host name, resource group, host pool name, reimage start timestamp, and last portal Status before removal.

**You know it worked when:** The host no longer appears in `POOL-FIN-01 > Session hosts` list. Remaining hosts are unaffected.

---

## 8. Prevention

Each control below names the owner role, when in the release process it fires, the concrete pass/fail signal, and the automation status. Controls marked **[REQUIRES]** depend on a tool or process that may not yet exist.

---

**P1 — Pre-deployment smoke test gate in the image deployment pipeline**
- **Owner:** Release engineer | **When:** During deployment — immediately after the first host comes online with the new image, before any host is made available to users
- **What:** Pipeline automatically performs a test logon using a dedicated service account on the first reimaged host. It queries the host's `Application` log for Event ID 1000 (Source: `Application Error`, description containing `dwm.exe`) and the `System` log for Event ID 9011 (Source: `Desktop Window Manager`).
- **Pass:** Zero Event ID 1000 entries AND at least one Event ID 9011 within 5 minutes of the test logon completing.
- **Fail:** Any Event ID 1000 present, OR zero Event ID 9011 after 5 minutes → pipeline halts, host is automatically reimaged to the previous version, on-call engineer paged within 2 minutes. No further hosts are updated.
- **Automation:** Automated pipeline gate. **[REQUIRES: deployment pipeline with PowerShell WinEvent query capability and auto-reimage on failure]**

---

**P2 — Pin Intel graphics driver version in the image build manifest**
- **Owner:** Image owner | **When:** Pre-deployment — at image build time, verified before the build artifact is published to the Shared Image Gallery
- **What:** `igdumd64.dll` driver package version is pinned to a specific approved version string in the build manifest (Packer / Azure Image Builder). Automatic driver updates are disabled for this component. Any change to the pinned version requires a separate change request with test evidence attached.
- **Pass:** Build validation step confirms the driver package in the manifest matches the approved version string held in source control. Build artifact is published only if this check passes.
- **Fail:** Build fails with a version-mismatch error; artifact is not published to the Shared Image Gallery; image owner is notified.
- **Automation:** Manual pinning, automated verification check in the build pipeline. *Could be fully automated: add a build step that compares the manifest driver version against a `approved-driver-versions.json` file in the repo and blocks the build on mismatch.* **[REQUIRES: version-control file for approved driver versions]**

---

**P3 — Mandatory canary host pool promotion gate before any production deployment**
- **Owner:** Change manager | **When:** Pre-deployment to production — canary pool must be stable for a minimum of 24 hours; change manager must explicitly approve promotion before production hosts are updated
- **What:** Every image update is deployed to an isolated canary pool first. The canary pool is monitored for Event ID 1000 (Source: `Application Error`, `Application` log) and Event ID 9009 (Source: `Desktop Window Manager`, `System` log) across a minimum of five test logons over the 24-hour window.
- **Pass:** Zero Event ID 1000 or 9009 entries across the full 24-hour canary window AND at least one Event ID 9011 per test logon. Change manager signs off in the change ticket.
- **Fail:** Any single Event ID 1000 or 9009 in the canary window → production deployment blocked; change put on hold; image owner notified to investigate.
- **Automation:** Manual check and sign-off. *Can be automated: Azure Monitor alert on the canary pool workspace (same KQL as P4) wired to block the production pipeline stage.* **[REQUIRES: dedicated canary host pool; Log Analytics workspace for canary pool]**

---

**P4 — Standing Azure Monitor alert rule for dwm.exe crash events on all AVD production hosts**
- **Owner:** DWP engineer (monitoring/operations) | **When:** Standing control, always active — fires during and after any deployment and during normal operations
- **What:** Alert rule in Azure Monitor targets the Log Analytics workspace linked to POOL-FIN-01 hosts. KQL: `Event | where EventID == 1000 and Source == "Application Error" and RenderedDescription contains "dwm.exe" | where TimeGenerated > ago(5m)`. Threshold: 1 occurrence. Severity: 1 (Critical). Action group: page on-call engineer with link to this KB article.
- **Pass:** Alert fires within 5 minutes of the first matching event. Validate monthly by checking Azure Monitor > Alerts > Alert rules > Last fired timestamp.
- **Fail:** Alert does not fire despite matching events — rule health degraded or Log Analytics ingestion delayed. Escalate to monitoring team. *Test alert health by running the KQL manually in Log Analytics and confirming results appear within the ingestion SLA (typically < 2 minutes).*
- **Automation:** Automated. **[REQUIRES: Log Analytics workspace with Windows Event log collection enabled for `Application` and `System` logs on all POOL-FIN-01 session hosts]**

---

**P5 — CMDB configuration item records approved image version per host pool**
- **Owner:** Service desk lead (ITSM process owner) | **When:** At deployment time — CMDB record must be updated as a mandatory step in the change ticket closure checklist, before the change is marked complete
- **What:** The CMDB configuration item for each host pool records the current approved image version string. The change ticket closure checklist includes a required field: *"CMDB image version updated? Yes / No."* Reviewer cannot close the change ticket until this field is set to Yes.
- **Pass:** CMDB CI for POOL-FIN-01 shows image version matching `portal.azure.com > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Properties > Virtual machine image` field value.
- **Fail:** Version mismatch between CMDB and portal → change ticket remains open; service desk lead notified.
- **Automation:** Manual. *Can be automated: add a deployment pipeline post-step that calls the ITSM CMDB API to update the CI record on successful deployment.* **[REQUIRES: CMDB API access from the deployment pipeline]**

---

**P6 — In-flight monitoring during the rollout window** *(new — in-flight monitoring layer)*
- **Owner:** Release engineer | **When:** During deployment — active from first host reimage start to drain mode disabled (R8); engineer monitors actively throughout
- **What:** Every 5 minutes during the rollout window, run the following query in Azure Monitor Logs against the POOL-FIN-01 workspace: `Event | where EventID == 1000 and Source == "Application Error" and RenderedDescription contains "dwm.exe" | where TimeGenerated > ago(10m)`. Log the result (zero rows expected) against each batch in the change ticket.
- **Pass:** Zero rows returned at every 5-minute check throughout the entire rollout window.
- **Fail:** Any row returned → halt rollout immediately, execute RB1 (drain mode on), raise P1 incident.
- **Automation:** Manual during rollout. *Can be automated: enable a tighter scoped Azure Monitor alert (threshold 1, evaluation frequency 5 min, window 10 min) for the duration of the maintenance window only, wired to an Azure Automation runbook that enables drain mode automatically.* **[REQUIRES: Log Analytics workspace; Azure Automation account with Az.DesktopVirtualization module]**

---

**P7 — Post-deployment change validation sign-off before change ticket closure** *(new — post-deployment validation layer)*
- **Owner:** Change manager | **When:** After deployment — before the change ticket is closed
- **What:** Engineer must attach evidence of all five verification checks (V1–V5 from Section 6 of this KB) to the change ticket. Minimum acceptable evidence: PowerShell output showing zero Event ID 1000 results (V1), at least one Event ID 9011 per host (V2), and `Get-AzWvdSessionHost` output showing all hosts `Status = Available` (V4).
- **Pass:** All five checks documented and attached; change manager reviews and approves closure.
- **Fail:** Missing evidence → change ticket remains open; engineer must re-run the relevant checks and resubmit.
- **Automation:** Manual sign-off. *Can be automated: post-deployment pipeline job runs V1 and V4 PowerShell checks and posts results as a comment to the ITSM ticket via API.* **[REQUIRES: ITSM API access from the deployment pipeline]**

---

**P8 — Rollback trigger threshold during deployment** *(new — rollback trigger layer)*
- **Owner:** Release engineer | **When:** During deployment (in-flight)
- **What:** If Event ID 1000 (Source: `Application Error`, description: `dwm.exe` + `igdumd64.dll`) appears on **2 or more reimaged hosts within any 10-minute window** during the rollout, the release engineer must immediately execute Rollback RB1 without waiting for further confirmation or approval.
- **Pass:** Rollout completes with zero triggers of this threshold.
- **Fail:** Threshold crossed → RB1 executed within 90 seconds; incident escalated to P1 severity; incident manager paged.
- **Automation:** Manual decision trigger. *Can be automated: Azure Monitor alert set to threshold 2 in a 10-minute window wired to an Azure Automation runbook that calls `Update-AzWvdSessionHost -AllowNewSession:$false` across all hosts automatically.* **[REQUIRES: Azure Automation account; Az.DesktopVirtualization module; tested runbook for drain mode]**

---

**P9 — Post-incident knowledge and runbook update** *(new — knowledge update layer)*
- **Owner:** DWP engineer (incident owner) | **When:** After incident closure — within 3 working days of the incident being marked resolved
- **What:** Incident owner reviews this KB article and `DAY5/runbook-avd-black-screen-dwm-crash-2024-03-15.md` for any step that was unclear, missing, or had to be improvised during the incident. Both documents are updated to reflect actual steps taken, version number incremented, and changes submitted for peer review before being committed to the knowledge base.
- **Pass:** Both documents updated and peer-reviewed; version numbers incremented; changes recorded in the post-incident review tracker.
- **Fail:** Outstanding update flagged in the post-incident review tracker and escalated to the team lead after 5 working days.
- **Automation:** Manual.

---

## 9. Related Articles and Records

| Type | Title / Reference | Location |
|---|---|---|
| Root Cause Analysis | RCA — AVD Black Screen, POOL-FIN-01, 2024-03-15 | `DAY4/RCA-avd-black-screen-POOL-FIN-01-2024-03-15.md` |
| Known Error Record | Known Error — AVD Black Screen (DWM / igdumd64.dll) | `DAY4/known-error-record-avd-black-screen-2024-03-15.md` |
| Closure Note | Closure Note — AVD Black Screen POOL-FIN-01 | `DAY4/closure-note-avd-black-screen-2024-03-15.md` |
| Incident Hypothesis | AVD Incident Hypothesis Analysis, 2024-03-15 | `DAY4/avd-incident-analysis-hypothesis-2024-03-15.md` |
| Runbook (L2/L3 procedural) | Runbook — AVD Black Screen DWM Crash (igdumd64.dll) | `DAY5/runbook-avd-black-screen-dwm-crash-2024-03-15.md` |
| L1 End-User KB | My work screen went black — what do I do? | `DAY5/kb-avd-black-screen-end-user.md` |
