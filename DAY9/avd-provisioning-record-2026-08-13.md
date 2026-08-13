# Azure Virtual Desktop Provisioning Record

Date: 2026-08-13

## Scope

This document records the Azure Virtual Desktop provisioning that was completed in Azure CLI for the Windows 11 workplace migration lab.

Environment:

- Subscription ID: `56746145-f37c-4127-b1ad-8a2908b80432`
- Resource group: `dwp-lab-rg`
- Region: `Central US`
- Microsoft 365 tenant: `zippyops.in`
- User requiring access: `p19@zippyops.in`

## Pre-checks Performed

Before provisioning, the signed-in Azure CLI identity and RBAC scope were verified.

- Signed-in user: `traininguser21@zippyops.in`
- Effective role on subscription: `Owner`

This confirmed permission to create resources and assign Azure roles. If this check had failed, provisioning would have stopped before the role-assignment stage.

## Target Build

The requested end state was:

- Pooled host pool named `POOL-FIN-01`
- Breadth-first load balancing
- Maximum 5 sessions per host
- Desktop application group
- Workspace named `FinBridge-Workspace`
- One Windows 11 multi-session session host VM
- VM size `Standard_B2ms`
- Trusted Launch enabled with Secure Boot and vTPM
- Microsoft Entra ID joined only
- Direct VM sign-in and published desktop access assigned to `p19@zippyops.in`

## Provisioning Steps Followed

### 1. Confirm Azure context and permissions

The following checks were performed:

- `az account show`
- `az ad signed-in-user show`
- `az role assignment list --assignee-object-id <objectId> --include-inherited --scope /subscriptions/56746145-f37c-4127-b1ad-8a2908b80432`

Result:

- Target subscription was already selected.
- The signed-in identity had `Owner` on the subscription.

### 2. Install and configure the required CLI extension

The Azure Virtual Desktop CLI extension was installed and non-interactive extension handling was enabled to avoid blocking prompts.

Commands used:

- `az config set extension.use_dynamic_install=yes_without_prompt`
- `az config set extension.dynamic_install_allow_preview=true`
- `az extension add --name desktopvirtualization --upgrade --yes`

Result:

- `desktopvirtualization` extension was available and usable.

### 3. Create and validate the AVD control plane

The following objects were created or validated:

- Host pool: `POOL-FIN-01`
- Desktop application group: `DAG-POOL-FIN-01`
- Workspace: `FinBridge-Workspace`

Key CLI actions:

- `az desktopvirtualization hostpool create`
- `az desktopvirtualization applicationgroup create`
- `az desktopvirtualization workspace create`

Validated settings:

- Host pool type: `Pooled`
- Load balancer type: `BreadthFirst`
- Max session limit: `5`
- Application group type: `Desktop`
- Workspace linked to `DAG-POOL-FIN-01`

### 4. Create network and session host VM

The following Azure resources were created for the session host:

- Virtual network: `avd-fin-vnet`
- Network security group: `avd-fin-nsg`
- Session host VM: `avd-fin-sh-01`

VM configuration:

- Image: Windows 11 multi-session AVD image (`win11-24h2-avd`)
- Size: `Standard_B2ms`
- Security type: `TrustedLaunch`
- Secure Boot: `True`
- vTPM: `True`
- License type: `Windows_Client`
- Managed identity: enabled

Key CLI actions:

- `az network vnet create`
- `az network nsg create`
- `az network nsg rule create`
- `az vm create`
- `az vm wait --created`

### 5. Enable Microsoft Entra sign-in on the VM

The Microsoft Entra sign-in extension for Windows was installed.

Command used:

- `az vm extension set --name AADLoginForWindows --publisher Microsoft.Azure.ActiveDirectory`

Validation:

- Extension provisioning state: `Succeeded`

### 6. Generate host pool registration token

The host pool registration token was refreshed before session-host registration.

Commands used:

- `az desktopvirtualization hostpool update --registration-info expiration-time=<utc> registration-token-operation=Update`
- `az desktopvirtualization hostpool retrieve-registration-token --query token -o tsv`

### 7. Register the VM to the host pool

Initial attempts used inline remote PowerShell through `az vm run-command invoke`. Those attempts exposed quoting and download-path issues, so the final reliable method used a file-based script.

Final working script:

- `DAY9/register-avd-sessionhost.ps1`

What the script does:

- Downloads the current Azure Virtual Desktop Agent from Microsoft fwlink
- Downloads the current Azure Virtual Desktop Boot Loader from Microsoft fwlink
- Installs the agent with the current registration token
- Installs the boot loader
- Prints MSI exit codes
- Prints `RdAgent` and `RdAgentBootLoader` service state

Validated result from the script:

- `AGENT_MSI_EXIT=0`
- `BOOT_MSI_EXIT=0`
- `RDAGENT_STATUS=Running`
- `BOOTLOADER_STATUS=Running`

### 8. Diagnose host status using VM-side checks

After registration, the host briefly appeared as `Unavailable`. Instead of rerunning the same registration blindly, VM-side checks were used.

Diagnostic script used:

- `DAY9/check-avd-hoststate.ps1`

What the script checks:

- `RdAgent` service state
- `RdAgentBootLoader` service state
- `AzureAdJoined` value from `dsregcmd /status`
- `DomainJoined` value from `dsregcmd /status`

Validated VM-side state:

- `SERVICE_RdAgent=Running`
- `SERVICE_RdAgentBootLoader=Running`
- `AzureAdJoined : YES`
- `DomainJoined : NO`

After agent startup completed and heartbeat updated, the session host state changed to `Available`.

### 9. Assign access roles for the M365 account

The following role assignments were created for `p19@zippyops.in`:

- `Virtual Machine User Login` on VM `avd-fin-sh-01`
- `Desktop Virtualization User` on application group `DAG-POOL-FIN-01`

Commands used:

- `az role assignment create --role "Virtual Machine User Login" --scope <vm-scope>`
- `az role assignment create --role "Desktop Virtualization User" --scope <app-group-scope>`

These assignments provide:

- Direct RDP sign-in to the VM using Microsoft Entra ID
- Access to the published desktop through the Azure Virtual Desktop client

## Final Validated State

### Host pool

- Name: `POOL-FIN-01`
- Type: `Pooled`
- Load balancing: `BreadthFirst`
- Max session limit: `5`

### Application group and workspace

- Desktop application group: `DAG-POOL-FIN-01`
- Workspace: `FinBridge-Workspace`
- Workspace registration: confirmed

### Session host VM

- Name: `avd-fin-sh-01`
- Size: `Standard_B2ms`
- Provisioning state: `Succeeded`
- Security type: `TrustedLaunch`
- Secure Boot: `True`
- vTPM: `True`
- Entra join state: `AzureAdJoined : YES`
- Domain join state: `DomainJoined : NO`

### Actual session host status

Validated through ARM query of session hosts:

- Session host object: `POOL-FIN-01/avd-fin-sh-01`
- Status: `Available`
- Allow new session: `True`
- Agent version: `1.0.15008.300`

## Notes and Observations

- The CLI extension prompt initially blocked execution until non-interactive extension handling was configured.
- Inline `az vm run-command invoke` scripts were prone to quoting issues when long PowerShell payloads were passed directly on the command line.
- The stable approach was to use script files and pass them with `--scripts @<path>`.
- Older direct binary URLs used earlier in the session were not reliable for the boot loader. The working implementation used Microsoft fwlinks instead.

## Files Created During Provisioning

- `DAY9/register-avd-sessionhost.ps1`
- `DAY9/check-avd-hoststate.ps1`

## Recommended Reuse Pattern

For future AVD host registration work in this lab:

1. Refresh the host pool registration token.
2. Use `register-avd-sessionhost.ps1` with the new token.
3. Use `check-avd-hoststate.ps1` to validate agent services and Entra join state.
4. Query session host status before concluding the build is complete.