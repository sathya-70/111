param(
    [Parameter(Mandatory = $true)]
    [string]$RegistrationToken
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$agentLink = 'https://go.microsoft.com/fwlink/?linkid=2310011'
$bootLink = 'https://go.microsoft.com/fwlink/?linkid=2311028'
$agentMsi = 'C:\Windows\Temp\Microsoft.RDInfra.RDAgent.Installer-x64.msi'
$bootMsi = 'C:\Windows\Temp\Microsoft.RDInfra.RDAgentBootLoader.Installer-x64.msi'

Invoke-WebRequest -Uri $agentLink -OutFile $agentMsi -UseBasicParsing
Invoke-WebRequest -Uri $bootLink -OutFile $bootMsi -UseBasicParsing

if (-not (Test-Path $agentMsi)) { throw 'Agent MSI download failed.' }
if (-not (Test-Path $bootMsi)) { throw 'Bootloader MSI download failed.' }

$agentProc = Start-Process msiexec.exe -ArgumentList '/i', $agentMsi, ('REGISTRATIONTOKEN=' + $RegistrationToken), '/qn', '/norestart' -Wait -PassThru
$bootProc = Start-Process msiexec.exe -ArgumentList '/i', $bootMsi, '/qn', '/norestart' -Wait -PassThru

Write-Output ("AGENT_MSI_EXIT=" + $agentProc.ExitCode)
Write-Output ("BOOT_MSI_EXIT=" + $bootProc.ExitCode)

$svcAgent = Get-Service -Name RdAgent -ErrorAction SilentlyContinue
$svcBoot = Get-Service -Name RdAgentBootLoader -ErrorAction SilentlyContinue

if ($null -ne $svcAgent) {
    Write-Output ("RDAGENT_STATUS=" + $svcAgent.Status)
} else {
    Write-Output 'RDAGENT_STATUS=MISSING'
}

if ($null -ne $svcBoot) {
    Write-Output ("BOOTLOADER_STATUS=" + $svcBoot.Status)
} else {
    Write-Output 'BOOTLOADER_STATUS=MISSING'
}