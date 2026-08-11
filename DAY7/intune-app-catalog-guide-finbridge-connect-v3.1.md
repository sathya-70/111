# Intune App Catalog Guide (Pre-Rollout): FinBridge Connect v3.1

Purpose: Add a Windows application to Intune correctly before any phased rollout begins.
Audience: DWP engineers with no prior Intune app deployment experience.
Worked example: FinBridge Connect v3.1 (Windows LOB app, .intunewin).

Important: Intune UI labels and menu names can vary by tenant, licensing, and portal version. At each navigation step below, verify labels in your live tenant rather than trusting this guide word-for-word.

## 1. Prerequisites

1. Confirm you have:
   - Intune admin access with app management permissions.
   - The packaged installer file: `FinBridgeConnect_v3.1.intunewin`.
   - Install command: `FinBridgeConnect_Setup.exe /silent`.
   - Uninstall command: `FinBridgeConnect_Setup.exe /uninstall /silent`.
   - Detection target: Registry value `HKLM\SOFTWARE\FinBridge\Connect\Version = 3.1`.
2. Confirm a pilot Azure AD/Entra group exists for controlled testing (for example, 10-50 test devices/users).
3. Do not target the full fleet initially (for example, not all 10,000 devices).

## 2. Navigate to the App Creation Area in Intune

1. Open the Intune admin center in your browser.
2. Go to:
   - `Apps` -> `All apps` -> `Add`
3. UI variance warning:
   - In some tenants this may appear as `Apps` -> `Windows` -> `Add`, or labels may include platform-specific wording.
   - Verify the final destination is the screen where you choose an app type.

## 3. Choose the Correct App Type

1. When prompted for app type, choose based on packaging:
   - Windows LOB app packaged as `.intunewin`:
     - Select `Windows app (Win32)` (commonly used for .intunewin packages).
   - Microsoft Store app:
     - Select `Microsoft Store app (new)` (or equivalent label in your tenant).
   - Web link application:
     - Select `Web link`.
2. For this guide, select `Windows app (Win32)`.
3. UI variance warning:
   - Some portals use slightly different naming, but the correct option is the Win32 workflow that accepts `.intunewin`.

## 4. Upload Package and Enter Required App Information

1. Upload the package file:
   - `FinBridgeConnect_v3.1.intunewin`
2. Complete app information fields (required baseline):
   - Name: `FinBridge Connect`
   - Description: `FinBridge Connect desktop client v3.1`
   - Publisher: `FinBridge`
   - Version: `3.1`
3. Optional fields may appear (category, logo, owner, notes). Fill according to local standards.
4. UI variance warning:
   - Field order and labels like `Display version` vs `Version` can differ.

## 5. Configure Program Settings (Install/Uninstall Behavior)

1. Set Install command:
   - `FinBridgeConnect_Setup.exe /silent`
2. Set Uninstall command:
   - `FinBridgeConnect_Setup.exe /uninstall /silent`
3. Set Install behavior / context:
   - Choose `System` when the app must install machine-wide or write to protected locations under HKLM/Program Files.
   - Choose `User` only when installation is strictly per-user and does not need elevated machine context.
4. For FinBridge Connect v3.1 in this example, choose `System`.
5. UI variance warning:
   - The label may appear as `Install behavior`, `Install context`, or be inside an `Execution` section.

## 6. Configure Requirements

1. Set OS architecture (as provided by app owner or packaging standard):
   - `64-bit` (common default for enterprise Windows apps).
2. Set minimum OS version:
   - Example baseline: `Windows 10 22H2` or your organization minimum supported Windows version.
3. Ensure requirement values align with your managed endpoint baseline policy.
4. UI variance warning:
   - Architecture names and OS version dropdown labels differ slightly by portal build.

## 7. Configure Detection Rules (Critical for Install Success)

1. In Detection rules, choose `Manually configure detection rules` if prompted.
2. Add a registry-based detection rule:
   - Rule type: `Registry`
   - Key path: `HKEY_LOCAL_MACHINE\SOFTWARE\FinBridge\Connect`
   - Value name: `Version`
   - Detection method/operator: equals
   - Expected value: `3.1`
3. Why this matters:
   - Intune marks the app as installed only when detection succeeds.
   - Incorrect detection is a common cause of repeated installs or false failures.
4. Alternative detection options (if registry is not suitable):
   - MSI product code detection.
   - File/folder existence or file version detection.
5. UI variance warning:
   - Labels may be `Detection rules`, `Detection`, or `Rules`.

## 8. Configure Return Codes

1. Review and keep or adjust default return codes.
2. Ensure at least these meanings are set:
   - `0` = Success
   - `3010` = Soft reboot required (often treated as success with restart)
   - `1641` = Hard reboot initiated (commonly success/reboot)
   - Non-listed non-zero codes = Failure (unless explicitly mapped)
3. Add vendor-specific success codes if FinBridge packaging documentation requires them.
4. UI variance warning:
   - Return code editor may be in `Program`, `Detection`, or a separate step.

## 9. Review and Create the App

1. Use `Review + create` (or equivalent review action).
2. Confirm all key values:
   - App type is Win32/.intunewin path.
   - Commands exactly match tested syntax.
   - Requirements match target devices.
   - Detection rule matches registry key/value.
3. Select `Create`.

## 10. Assignment Basics: Required vs Available vs Uninstall

1. Open the newly created app and go to `Assignments`.
2. Understand assignment types:
   - Required:
     - Intune automatically installs on targeted devices/users.
   - Available:
     - App appears in Company Portal for optional self-service install.
   - Uninstall:
     - Intune removes the app from targeted devices/users.
3. For a new app, assign first to a small pilot group, not full fleet.
4. Why pilot first:
   - Limits blast radius if install/detection/uninstall logic is wrong.
   - Exposes device-specific issues (permissions, prerequisites, conflicts) early.
   - Reduces risk of mass failures across 10,000 devices.
5. Add assignment for pilot:
   - Start with `Required` for a dedicated test device group, or `Available` for controlled user-led validation.
6. UI variance warning:
   - Group selection labels and assignment UX differ by tenant version.

## 11. Verification After Assignment

1. Confirm app appears correctly in catalog:
   - In Intune `Apps` -> `All apps`, verify `FinBridge Connect` is listed.
   - Open the app and validate metadata (name, version, publisher, commands, detection).
2. Check install status for pilot targets:
   - In app monitor/status views, review device and user install states.
   - On a pilot test device, run a sync from Company Portal or Intune policy sync if needed.
3. Interpret common statuses:
   - `Installed`: Detection succeeded; Intune confirms app present.
   - `Failed`: Installer returned an error code or detection did not pass after install attempt.
   - `Not applicable`: Device/user does not meet requirements, assignment scope, platform, or filters.
4. If failures occur, triage in this order:
   - Command syntax and silent switch validity.
   - Detection rule correctness (path, value name, data type, expected value).
   - Requirement mismatch (OS/version/architecture).
   - Return code mappings.

## 12. Exit Criteria Before Wider Rollout

1. Do not proceed beyond pilot until:
   - Pilot install success rate meets team threshold.
   - No critical user impact reported.
   - Detection and uninstall behavior validated.
2. Expand scope in phases (for example, pilot -> early adopters -> department waves -> broad deployment).
3. Keep rollback path ready (for example, Uninstall assignment to pilot group if needed).

## Quick Reference: Worked Example Values

- App package: `FinBridgeConnect_v3.1.intunewin`
- Type: `Windows app (Win32)`
- Name: `FinBridge Connect`
- Description: `FinBridge Connect desktop client v3.1`
- Publisher: `FinBridge`
- Version: `3.1`
- Install command: `FinBridgeConnect_Setup.exe /silent`
- Uninstall command: `FinBridgeConnect_Setup.exe /uninstall /silent`
- Install behavior: `System`
- Detection: `HKLM\SOFTWARE\FinBridge\Connect\Version = 3.1`
- Recommended first assignment: pilot group only
