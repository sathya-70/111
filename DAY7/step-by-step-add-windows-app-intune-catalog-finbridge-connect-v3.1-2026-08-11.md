# Step-by-Step: Add a Windows App to the Intune App Catalog (Before Rollout)
Date: 2026-08-11
Audience: DWP engineers with no prior Intune app deployment experience
Worked example app: FinBridge Connect v3.1 (.intunewin)

Important note on UI labels
- Intune portal labels can vary by tenant version, feature rollout wave, and portal updates.
- In every navigation step below, if labels are slightly different in your tenant, verify the live label/path in your portal and proceed with the equivalent option.
- Do not rely only on this document label text if your tenant shows a different but equivalent path.

## 1. Confirm prerequisites before opening Intune
1. Ensure you have Intune permissions to create and assign apps (for example: Intune Administrator, Application Administrator, or a custom role with app create/assign rights).
2. Confirm the package is ready and validated:
   - File type: `.intunewin`
   - Example file: `FinBridgeConnect_v3.1.intunewin`
3. Confirm deployment commands from the packaging team:
   - Install command: `FinBridgeConnect_Setup.exe /silent`
   - Uninstall command: `FinBridgeConnect_Setup.exe /uninstall /silent`
4. Confirm detection target and value:
   - Registry path: `HKLM\SOFTWARE\FinBridge\Connect`
   - Value name: `Version`
   - Expected value: `3.1`

## 2. Navigate to the app catalog location in Intune
1. Open the Intune admin center in browser.
2. Go to: `Apps` -> `All apps` -> `Add`.
3. UI label variation warning:
   - In some tenants, you may see `Applications` instead of `Apps`, or a slightly different left-nav grouping.
   - Verify the live equivalent path that leads to the app creation wizard.

## 3. Choose the correct app type
1. In `Select app type`, choose based on source:
   - For Windows LOB package (`.intunewin`): choose `Windows app (Win32)`.
   - For Microsoft Store-delivered app: choose `Microsoft Store app (new)`.
   - For a URL shortcut/portal link: choose `Web link`.
2. For this worked example (FinBridge Connect v3.1), select `Windows app (Win32)`.
3. UI label variation warning:
   - Some tenants may show equivalent labels like `Win32 app` or place Store options in a separate category.
   - Verify by checking that the selected type supports `.intunewin` upload.

## 4. Upload the `.intunewin` package
1. In the app creation wizard, locate the package upload step (often called `App package file`).
2. Browse and upload `FinBridgeConnect_v3.1.intunewin`.
3. Wait for package metadata processing to finish before continuing.
4. UI label variation warning:
   - Step name may be `App information` first, with package upload embedded or in a previous tab.
   - Verify you can see the uploaded file name before moving on.

## 5. Complete required App information fields
1. Enter the required app metadata:
   - Name: `FinBridge Connect v3.1`
   - Description: `FinBridge Connect desktop client version 3.1 for managed Win11 endpoints.`
   - Publisher: `FinBridge`
   - Version: `3.1`
2. Optional but recommended fields:
   - Category (for catalog organization)
   - App logo/icon
   - Owner/help URL
3. Why this matters:
   - Clear naming/versioning avoids confusion during phased rollout and rollback decisions.

## 6. Configure Program settings
1. In the `Program` section, set:
   - Install command: `FinBridgeConnect_Setup.exe /silent`
   - Uninstall command: `FinBridgeConnect_Setup.exe /uninstall /silent`
2. Set install behavior/context:
   - Recommended for managed enterprise app rollout: `System` context.
   - Use `User` context only if the app must install per-user and does not require machine-level write access.
3. Keep restart behavior explicit (for example, determine whether app install can force restart).
4. UI label variation warning:
   - Some tenants expose restart handling under `Program` while others surface it under an advanced setting.

## 7. Configure Requirements
1. In `Requirements`, set at least:
   - Operating system architecture: `64-bit` (and `32-bit` only if truly supported).
   - Minimum operating system: `Windows 11` baseline used by your org standard.
2. For this fleet:
   - Target is Win11 endpoints, so set minimum OS accordingly.
3. Why this matters:
   - Prevents deployment to unsupported devices and reduces false `Failed` states.

## 8. Configure Detection rules (registry method)
1. In `Detection rules`, choose `Manually configure detection rules` if prompted.
2. Add a `Registry` detection rule with:
   - Key path: `HKEY_LOCAL_MACHINE\SOFTWARE\FinBridge\Connect`
   - Value name: `Version`
   - Detection method: `String comparison` (or equivalent)
   - Operator: `Equals`
   - Value: `3.1`
3. Confirm architecture scope for registry lookup (64-bit vs 32-bit hive) matches how the app writes the key.
4. Alternative detection methods (for other apps):
   - MSI product code (best when MSI is used and stable)
   - File path/file version (when app writes reliable binaries to fixed location)
5. UI label variation warning:
   - Detection wizard labels vary frequently; verify you are checking exact key/value, not key existence only.

## 9. Configure Return codes
1. Open `Return codes` and verify defaults.
2. Ensure at minimum these mappings exist:
   - `0` -> Success
   - `3010` -> Soft reboot (success with restart required)
   - `1641` -> Hard reboot (success with restart initiated)
3. Mark non-success installer failures as `Failed` (for example, `1603` unless your app owner documents a different interpretation).
4. Why this matters:
   - Incorrect return code mapping causes false failure/success reporting.
5. UI label variation warning:
   - Some tenants present return code editing in-line, others in a separate modal.

## 10. Review and create the app object
1. Use the final review page to verify:
   - App type is `Windows app (Win32)`
   - Commands are correct
   - Detection key/value exactly matches `Version = 3.1`
   - Requirements target Win11 architecture correctly
2. Select `Create`.
3. Wait for app object creation and initial processing to complete.

## 11. Understand assignment types before targeting devices
1. `Required`:
   - Intune installs automatically on targeted users/devices.
   - Use for controlled deployment rings.
2. `Available for enrolled devices`:
   - App appears in Company Portal for user self-install.
   - Good for optional apps or early voluntary adoption.
3. `Uninstall`:
   - Intune removes app from targeted users/devices.
   - Use for rollback/remediation scenarios.

## 12. Assign to pilot first (not the full 10,000 fleet)
1. Create/select a small pilot group (for example 50-300 representative devices/users).
2. Assign FinBridge Connect v3.1 as `Required` to the pilot group only.
3. Do not assign directly to all 10,000 endpoints on day 1.
4. Reason:
   - Pilot validates packaging, detection, return codes, and user impact at low risk.
   - Limits blast radius if command, requirement, or detection settings are wrong.

## 13. Verify app appears correctly in catalog
1. Go to `Apps` -> `All apps`.
2. Search for `FinBridge Connect v3.1`.
3. Confirm app card/details include:
   - Correct name/version/publisher
   - Type `Windows app (Win32)`
   - Assignment present for pilot group
4. Open app properties and re-check Program, Requirements, Detection, and Return codes for accuracy.

## 14. Verify installation on an assigned test device
1. In Intune, open the app and check:
   - `Device install status`
   - `User install status`
2. Select a known pilot test device and inspect status/details.
3. On the endpoint, validate:
   - Application is installed and launches.
   - Registry key exists: `HKLM\SOFTWARE\FinBridge\Connect\Version = 3.1`.
4. If needed, trigger sync from Intune or Company Portal and re-check status after policy refresh.

## 15. Interpret key status values
1. `Installed`:
   - Intune detected app successfully using the configured detection rule.
2. `Failed`:
   - Install command failed, timeout occurred, requirement mismatch at execution time, or detection did not confirm success.
   - Check error code and return code mapping first.
3. `Not applicable`:
   - Target does not meet requirements (for example wrong OS architecture/version) or assignment context is not valid for that target.
   - Review Requirements and assignment target type.

## 16. Operational checkpoint before phased rollout begins
1. Confirm pilot completion criteria are met:
   - Stable install success rate
   - Acceptable support ticket rate
   - No Sev1 business-impact defects
2. Confirm rollback readiness:
   - Previous version assignment plan is prepared
   - Uninstall assignment tested on pilot subset
3. Only then proceed to phased ring expansion.

---

Quick checklist (copy into change record)
1. `.intunewin` uploaded and processed.
2. App info completed (name, description, publisher, version).
3. Program commands validated.
4. Install behavior set (`System` unless justified otherwise).
5. Requirements set for Win11 target.
6. Detection rule set to registry `Version = 3.1`.
7. Return codes reviewed.
8. Assigned to pilot group only.
9. Catalog and device install status verified.
10. Ready for phased rollout governance.
