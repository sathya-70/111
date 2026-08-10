# Windows 11 Intune Compliance Policy Translation (DWP)

Date: 2026-08-10  
Scope: Translate baseline requirements into Microsoft Intune compliance policy settings for Windows 11 devices.

## Baseline-to-Intune Mapping

| Requirement | Settings name (exact Intune label) | Value | Effect (plain English) | False-positive risk | Recommendation to reduce false positives (without weakening security) |
|---|---|---|---|---|---|
| 1. BitLocker must be enabled on OS drive | Require BitLocker | Require | Device is noncompliant if BitLocker protection is not enabled for trusted boot attestation. | Health attestation status is boot-time dependent. Device may stay noncompliant until reboot after encryption completes. Older/unsupported TPM scenarios can misreport. | Keep setting at Require. Add user/admin runbook step to reboot after enabling BitLocker. Validate TPM readiness during enrollment and pre-provisioning. |
| 2. Secure Boot must be enabled | Require Secure Boot to be enabled on the device | Require | Device must boot only trusted signed components (UEFI Secure Boot). | Unsupported firmware/TPM combinations (especially older hardware) can report noncompliant even when posture is expected for that model. | Keep setting at Require. Maintain an approved hardware list and block enrollment of unsupported models where possible. Use exception group only for verified legacy hardware retirement period. |
| 3. Minimum OS build N-1 (22621.2861) | Minimum OS version | 10.0.22621.2861 | Blocks devices below the approved Windows 11 patch baseline. | Reporting lag after update, check-in delays, or typo in version format can mark compliant devices noncompliant. | Use full 4-part version format exactly. Pair with update rings/expedite updates so devices reach target quickly. Consider Valid operating system builds for controlled ranges if you support multiple release trains. |
| 4. Microsoft Defender real-time protection must be on | Real-time protection | Require | Real-time malware scanning must be active. | Third-party AV coexistence, service startup race after boot, or tamper/protection-state sync delays can temporarily show noncompliant. | Keep at Require. Standardize AV strategy (single primary AV where possible). Also set Microsoft Defender Antimalware and security intelligence requirements in same policy for consistency. |
| 5. Firewall must be enabled for all profiles | Firewall | Require | Windows Firewall must stay enabled and users cannot disable it. | Conflicting GPO or local policy can override and cause noncompliance. Immediate post-boot sync can produce temporary Error state. | Keep at Require. Remove conflicting legacy GPO firewall settings and manage firewall centrally from Intune. Re-sync/recheck before incident escalation if status is transient right after reboot. |
| 6. A PIN or password must be configured | Require a password to unlock mobile devices | Require | User must have a local unlock secret (PIN/password) before using the device. | Shared/autologon kiosk patterns, policy scope mismatch, or misunderstanding of desktop behavior can create apparent false positives. | Keep at Require for standard user endpoints. If stronger assurance is needed, also configure Password type and Minimum password length in same compliance policy. Use separate compliance policy for kiosk/shared-device scenarios. |
| 7. Device must not be jailbroken or rooted | No direct Windows compliance setting (Not applicable on Windows) | N/A | Intune does not expose a rooted/jailbroken compliance control for Windows platform. | Requirement may be interpreted as unmet if stakeholders expect a literal toggle in Windows compliance policy. | Compensating control: set Require code integrity = Require, keep Secure Boot and BitLocker required, and integrate Microsoft Defender for Endpoint risk-based compliance (Require device to be at or under the machine risk score, typically Low or Clear). |

## Grace Period Configuration (All Settings)

Requirement: 7-day grace period for all settings.

How to configure in policy:
- Go to Actions for noncompliance in the compliance policy wizard.
- Action: Mark device noncompliant.
- Schedule (days after noncompliance): 7.

Operational note:
- This grace period is policy-level action timing, not a per-setting value field.
- Devices can show In grace period before moving to Not compliant.

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
