# Windows 11 Intune Compliance Policy Translation (DWP)

Date: 2026-08-10  
Scope: Translate baseline requirements into Microsoft Intune compliance policy settings for Windows 11 devices.

## Baseline-to-Intune Mapping

| Requirement | Settings name (exact Intune label) | Value | Grace Period | Effect (plain English) | False-positive risk | Recommendation to reduce false positives (without weakening security) |
|---|---|---|---|---|---|---|
| 1. BitLocker must be enabled on OS drive | Require BitLocker | Require | 7 days | Device is noncompliant if BitLocker protection is not enabled for trusted boot attestation. | Health attestation status is boot-time dependent. Device may stay noncompliant until reboot after encryption completes. Older/unsupported TPM scenarios can misreport. | Keep setting at Require. Add user/admin runbook step to reboot after enabling BitLocker. Validate TPM readiness during enrollment and pre-provisioning. |
| 2. Secure Boot must be enabled | Require Secure Boot to be enabled on the device | Require | 7 days | Device must boot only trusted signed components (UEFI Secure Boot). | Unsupported firmware/TPM combinations (especially older hardware) can report noncompliant even when posture is expected for that model. | Keep setting at Require. Maintain an approved hardware list and block enrollment of unsupported models where possible. Use exception group only for verified legacy hardware retirement period. |
| 3. Minimum OS build N-1 (22621.2861) | Minimum OS version | 10.0.22621.2861 | 7 days | Blocks devices below the approved Windows 11 patch baseline. | Reporting lag after update, check-in delays, or typo in version format can mark compliant devices noncompliant. | Use full 4-part version format exactly. Pair with update rings/expedite updates so devices reach target quickly. Consider Valid operating system builds for controlled ranges if you support multiple release trains. |
| 4. Microsoft Defender real-time protection must be on | Real-time protection | Require | 7 days | Real-time malware scanning must be active. | Third-party AV coexistence, service startup race after boot, or tamper/protection-state sync delays can temporarily show noncompliant. | Keep at Require. Standardize AV strategy (single primary AV where possible). Also set Microsoft Defender Antimalware and security intelligence requirements in same policy for consistency. |
| 5. Firewall must be enabled for all profiles | Firewall | Require | 7 days | Windows Firewall must stay enabled and users cannot disable it. | Conflicting GPO or local policy can override and cause noncompliance. Immediate post-boot sync can produce temporary Error state. | Keep at Require. Remove conflicting legacy GPO firewall settings and manage firewall centrally from Intune. Re-sync/recheck before incident escalation if status is transient right after reboot. |
| 6. A PIN or password must be configured | Require a password to unlock mobile devices | Require | 7 days | User must have a local unlock secret (PIN/password) before using the device. | Shared/autologon kiosk patterns, policy scope mismatch, or misunderstanding of desktop behavior can create apparent false positives. | Keep at Require for standard user endpoints. If stronger assurance is needed, also configure Password type and Minimum password length in same compliance policy. Use separate compliance policy for kiosk/shared-device scenarios. |
| 7. Device must not be jailbroken or rooted | No direct Windows compliance setting (Not applicable on Windows) | N/A | N/A | Intune does not expose a rooted/jailbroken compliance control for Windows platform. | Requirement may be interpreted as unmet if stakeholders expect a literal toggle in Windows compliance policy. | Compensating control: set Require code integrity = Require, keep Secure Boot and BitLocker required, and integrate Microsoft Defender for Endpoint risk-based compliance (Require device to be at or under the machine risk score, typically Low or Clear). |

## Grace Period Configuration (All Settings)

Requirement: 7-day grace period for all settings.

How to configure in policy:
- Go to Actions for noncompliance in the compliance policy wizard.
- Action: Mark device noncompliant.
- Schedule (days after noncompliance): 7.

Operational note:
- This grace period is policy-level action timing, not a per-setting value field.
- Devices can show In grace period before moving to Not compliant.

## Steps to Create the Compliance Policy in Intune

### Step 1 — Sign in and navigate

1. Open [Microsoft Intune admin center](https://intune.microsoft.com).
2. Go to **Devices** > **Compliance**.
3. Select the **Policies** tab.
4. Click **+ Create policy**.

### Step 2 — Platform and basics

5. Platform: select **Windows 10 and later**.
6. Click **Create**.
7. **Name**: e.g. `DWP-WIN11-Compliance-Baseline`
8. **Description**: e.g. `DWP security baseline compliance policy for Windows 11 endpoints.`
9. Click **Next**.

### Step 3 — Configure compliance settings (map to baseline requirements)

Work through each settings category and apply the values from the table above:

**Device health** (Requirements 1 and 2)
- Require BitLocker → **Require**
- Require Secure Boot to be enabled on the device → **Require**
- Require code integrity → **Require** *(compensating control for Req 7)*

**Device properties** (Requirement 3)
- Minimum OS version → **10.0.22621.2861**

**System security > Defender** (Requirement 4)
- Real-time protection → **Require**
- Microsoft Defender Antimalware → **Require**
- Microsoft Defender Antimalware security intelligence up-to-date → **Require**

**System security > Device security** (Requirement 5)
- Firewall → **Require**

**System security > Password** (Requirement 6)
- Require a password to unlock mobile devices → **Require**

**Microsoft Defender for Endpoint** (Compensating control for Requirement 7)
- Require the device to be at or under the machine risk score → **Low**

Click **Next**.

### Step 4 — Actions for noncompliance (Grace Period — all settings)

10. The default action **Mark device noncompliant** is pre-populated with Schedule = **0 days** (immediate).
11. Change the **Schedule (days after noncompliance)** field to **7**.
12. Optionally add a second action — **Send email to end user** — to notify users before enforcement kicks in.
13. Click **Next**.

### Step 5 — Assignments

14. Under **Included groups**, click **+ Add groups**.
15. Select the target device or user group (e.g. `GRP-DWP-ManagedEndpoints`).
16. Exclude any pilot exclusion or break-glass groups if applicable.
17. Click **Next**.

### Step 6 — Review and create

18. Review the summary. Confirm all 7 requirements are reflected.
19. Click **Create**.

### Step 7 — Validate after deployment

20. Go to **Devices** > **Compliance** > select the policy > **Monitor** tab.
21. Allow up to 24 hours for devices to check in and report status.
22. Review **Per-setting status** to identify any settings producing high noncompliant counts before enforcing Conditional Access.

See the full post-assignment validation procedure in the section **Post-Assignment Validation** below.

---

## Latest Likely UI Path (and Path Volatility Flags)

Intune UI labels can shift between portal experiences. The settings names above are stable, but navigation may vary.

Primary path (current commonly documented):
- Microsoft Intune admin center -> Devices -> Compliance -> Policies -> Create policy
- Platform: Windows 10 and later

Alternate documented path seen in newer docs for tenant-wide compliance settings:
- Microsoft Intune admin center -> Endpoint security -> Device compliance -> Compliance policy settings

Per-setting location after choosing Windows policy:
- Device health: Require BitLocker, Require Secure Boot to be enabled on the device, Require code integrity
- Device properties: Minimum OS version (or Valid operating system builds)
- System security -> Defender: Real-time protection
- System security -> Device security: Firewall
- System security -> Password: Require a password to unlock mobile devices
- Microsoft Defender for Endpoint: Require the device to be at or under the machine risk score (compensating control for rooted/jailbroken N/A)

Flagged as potentially changed since older training data:
- Top-level navigation location between Devices and Endpoint security blades
- Placement and labeling of report/monitor nodes
- Preview features such as client-driven compliance evaluation UI placement

## Recommended Companion Controls (Optional but Strongly Advised)

To improve reliability and reduce policy noise while preserving security intent:
- Set Microsoft Defender Antimalware = Require.
- Set Microsoft Defender Antimalware security intelligence up-to-date = Require.
- Set Antivirus = Require and Antispyware = Require (if aligned to your AV strategy).
- Configure Compliance policy setting Mark devices with no compliance policy assigned as = Not compliant.
- Keep Compliance status validity period aligned to your operations model (commonly 30 days unless a stricter posture is needed).

---

## Post-Assignment Validation

### Where to find a specific device's compliance status for this policy

**Path 1 — Via the policy (best for bulk view):**
1. Intune admin center > **Devices** > **Compliance**.
2. Select the **Policies** tab > click `DWP-WIN11-Compliance-Baseline`.
3. The **Monitor** tab opens by default showing the device status bar chart.
4. Click **View report** to see per-device rows with: Device name, Logged-in user, Policy compliance status, Last contacted.
5. Search for the test device name using the Search box.

**Path 2 — Via the device directly (best for single-device triage):**
1. Intune admin center > **Devices** > **All devices**.
2. Search for and select the test device.
3. Go to **Monitor** > **Compliance** (left-hand menu within the device blade).
4. All compliance policies assigned to this device are listed with their individual status.
5. Click the policy name to expand and see which specific settings are compliant or noncompliant.

**Per-setting drill-down:**
- From the policy Monitor tab, select the **Per-setting status** tile.
- Each setting in the policy is listed with a count for Compliant / Noncompliant / Error / Not applicable.
- Select the noncompliant count number to see exactly which devices failed that specific setting.

---

### What each compliance state means for Conditional Access

| Status | What it means | Conditional Access impact |
|---|---|---|
| **Compliant** | Device has met every setting in this policy at last check-in. | Access to CA-protected resources (M365, Exchange, SharePoint, Teams) is **permitted** (subject to other CA conditions). |
| **Not compliant** | One or more settings failed. Grace period has expired or was never set. | CA **blocks** access to protected resources. User sees an access-denied page with a prompt to fix the device. |
| **In grace period** | One or more settings failed, but the configured grace period (7 days) has not yet expired. | CA **permits** access during the grace window. Device is flagged for remediation but the user is not blocked yet. |

Key operational points:
- **In grace period** is not the same as compliant — the clock is running. If the device does not remediate within 7 days it automatically moves to Not compliant and CA blocks access with no further warning unless a noncompliance email action was configured.
- A device can be **Compliant to this policy** but **Not compliant overall** if another assigned policy is failing. CA evaluates the combined device compliance state, not individual policy results.
- Compliance state visible in Intune reflects the **last check-in**. A device that fixed itself but has not yet checked in will still show the old state until the next sync (up to 8 hours on Windows; trigger manually via Company Portal > Sync or `dsregcmd /refreshprt`).

---

### BitLocker shows Non-compliant despite BitLocker being enabled — three most common causes

#### Cause 1 — HAS attestation has not refreshed since last boot

**Why it happens:** `Require BitLocker` uses the Windows Health Attestation Service, which records TPM boot measurements. If BitLocker was enabled, re-keyed, or the device upgraded since the last clean boot, HAS may still hold the previous state.

**Fastest check:**
```powershell
# Run on the device — confirms current BitLocker status and TPM readiness
Get-BitLockerVolume -MountPoint C: | Select-Object MountPoint, VolumeStatus, ProtectionStatus, EncryptionMethod
```
If `ProtectionStatus` = `On` and `VolumeStatus` = `FullyEncrypted` but Intune still shows noncompliant, **reboot the device**, wait 15 minutes, then trigger a manual sync. HAS re-attests on the next clean boot.

---

#### Cause 2 — BitLocker protection is suspended (not disabled)

**Why it happens:** Windows automatically suspends BitLocker during major updates, driver changes, or BIOS/firmware updates. `ProtectionStatus` reports `Off` (suspended) even though encryption data is still on disk. Intune/HAS sees suspension as non-protected.

**Fastest check:**
```powershell
# ProtectionStatus = Off with VolumeStatus = FullyEncrypted = suspended, not disabled
Get-BitLockerVolume -MountPoint C: | Select-Object VolumeStatus, ProtectionStatus

# Re-enable protection immediately (no data loss, no re-encryption needed)
Resume-BitLocker -MountPoint C:
```
After `Resume-BitLocker`, reboot and sync. HAS will attest correctly on the next boot.

---

#### Cause 3 — TPM is not owned, not ready, or reported in an error state

**Why it happens:** HAS requires a functional TPM to seal the BitLocker keys. If the TPM is in a reduced-functionality state (common after motherboard replacement, firmware update, or factory reset without TPM clear), HAS cannot attest to BitLocker even if encryption is on.

**Fastest check:**
```powershell
# Check TPM status on the device
Get-Tpm | Select-Object TpmPresent, TpmReady, TpmEnabled, TpmActivated, TpmOwned, ManufacturerVersion
```
If `TpmReady = False` or `TpmEnabled = False`: escalate to hardware/firmware review. If `TpmOwned = False`: Windows should auto-provision TPM ownership on next boot — reboot and recheck. If TPM version is 1.2, Secure Boot HAS attestation may be unsupported for this device model.
