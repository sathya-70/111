[CmdletBinding()]
param(
    [ValidateSet('AI','Corrected','All')]
    [string]$Version = 'All',
    [switch]$DryRun = $true,
    [ValidateRange(1, 72)]
    [int]$HoursBack = 24,
    [string]$OutputRoot = (Join-Path -Path (Split-Path -Parent $MyInvocation.MyCommand.Path) -ChildPath 'evidence-artifacts')
)

$ErrorActionPreference = 'Stop'

function Export-CsvSafe {
    param(
        $InputObject,
        [Parameter(Mandatory = $true)][string]$Path
    )

    if ($null -eq $InputObject) {
        @() | Export-Csv -Path $Path -NoTypeInformation -Encoding UTF8
        return
    }

    @($InputObject) | Export-Csv -Path $Path -NoTypeInformation -Encoding UTF8
}

function Invoke-IncidentB_AI {
    param(
        [datetime]$StartTime,
        [Parameter(Mandatory = $true)][string]$OutDir
    )

    $outDir = $OutDir

    $securityEvents = Get-WinEvent -FilterHashtable @{ LogName = 'Security'; Id = 4624,4625; StartTime = $StartTime } -ErrorAction SilentlyContinue |
        Select-Object -First 800 TimeCreated, Id, MachineName, Message

    $profileEvents = Get-WinEvent -FilterHashtable @{ LogName = 'Microsoft-Windows-User Profile Service/Operational'; StartTime = $StartTime } -ErrorAction SilentlyContinue |
        Select-Object -First 800 TimeCreated, Id, MachineName, Message

    $dmEvents = Get-WinEvent -FilterHashtable @{ LogName = 'Microsoft-Windows-DeviceManagement-Enterprise-Diagnostics-Provider/Admin'; StartTime = $StartTime } -ErrorAction SilentlyContinue |
        Select-Object -First 800 TimeCreated, Id, MachineName, Message

    $startup = Get-CimInstance Win32_StartupCommand -ErrorAction SilentlyContinue |
        Select-Object Name, Command, User, Location

    $os = Get-CimInstance Win32_OperatingSystem
    $disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"

    $summary = [ordered]@{
        Incident = 'B'
        Version = 'AI'
        DryRun = [bool]$DryRun
        StartTime = $StartTime
        LastBoot = $os.LastBootUpTime
        FreeSpaceGB = [math]::Round(($disk.FreeSpace / 1GB), 2)
        TotalSpaceGB = [math]::Round(($disk.Size / 1GB), 2)
        OutputDirectory = $outDir
    }

    $summary | ConvertTo-Json -Depth 5 | Set-Content -Path (Join-Path $outDir 'ai-summary.json') -Encoding UTF8
    Export-CsvSafe -InputObject $securityEvents -Path (Join-Path $outDir 'ai-security-signin-events.csv')
    Export-CsvSafe -InputObject $profileEvents -Path (Join-Path $outDir 'ai-profile-events.csv')
    Export-CsvSafe -InputObject $dmEvents -Path (Join-Path $outDir 'ai-dm-events.csv')
    Export-CsvSafe -InputObject $startup -Path (Join-Path $outDir 'ai-startup-items.csv')

    [PSCustomObject]@{
        Incident = 'B'
        Version = 'AI'
        DryRun = [bool]$DryRun
        OutputDirectory = $outDir
        SignInEvents = @($securityEvents).Count
        UserProfileEvents = @($profileEvents).Count
        DMEvents = @($dmEvents).Count
        StartupItems = @($startup).Count
    }
}

function Invoke-IncidentB_Corrected {
    param(
        [datetime]$StartTime,
        [Parameter(Mandatory = $true)][string]$OutDir
    )

    function Get-WinEventSafe {
        param(
            [Parameter(Mandatory = $true)][hashtable]$Filter,
            [int]$MaxEvents = 1500
        )

        try {
            return @(Get-WinEvent -FilterHashtable $Filter -ErrorAction Stop -MaxEvents $MaxEvents)
        }
        catch {
            return @()
        }
    }

    $outDir = $OutDir

    $signinEvents = Get-WinEventSafe -Filter @{ LogName = 'Security'; Id = 4624, 4625; StartTime = $StartTime } -MaxEvents 2000 |
        Select-Object TimeCreated, Id, MachineName, ProviderName, Message

    $userProfileEvents = Get-WinEventSafe -Filter @{ LogName = 'Microsoft-Windows-User Profile Service/Operational'; StartTime = $StartTime } -MaxEvents 1500 |
        Select-Object TimeCreated, Id, MachineName, ProviderName, Message

    $dmEvents = Get-WinEventSafe -Filter @{ LogName = 'Microsoft-Windows-DeviceManagement-Enterprise-Diagnostics-Provider/Admin'; StartTime = $StartTime } -MaxEvents 1500 |
        Select-Object TimeCreated, Id, MachineName, ProviderName, Message

    $groupPolicyEvents = Get-WinEventSafe -Filter @{ LogName = 'Microsoft-Windows-GroupPolicy/Operational'; StartTime = $StartTime } -MaxEvents 1500 |
        Select-Object TimeCreated, Id, MachineName, ProviderName, Message

    $startupItems = try {
        @(Get-CimInstance -ClassName Win32_StartupCommand -ErrorAction Stop | Select-Object Name, Command, User, Location)
    }
    catch {
        @()
    }

    $os = Get-CimInstance -ClassName Win32_OperatingSystem
    $disk = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DeviceID='C:'"
    $bootWindowMinutes = [math]::Round(((Get-Date) - $os.LastBootUpTime).TotalMinutes, 2)

    $signinSummary = $signinEvents | Group-Object -Property Id | Sort-Object Name | ForEach-Object {
        [PSCustomObject]@{
            EventId = [int]$_.Name
            Count = $_.Count
        }
    }

    $overview = [ordered]@{
        Incident = 'Incident B - Login Failures and Severe Slowness'
        Version = 'Corrected'
        DryRun = [bool]$DryRun
        StartedFrom = $StartTime.ToString('o')
        Hostname = $env:COMPUTERNAME
        Username = $env:USERNAME
        LastBootUpTime = $os.LastBootUpTime.ToString('o')
        MinutesSinceBoot = $bootWindowMinutes
        Disk = [ordered]@{
            Drive = 'C:'
            FreeSpaceGB = [math]::Round(($disk.FreeSpace / 1GB), 2)
            TotalSpaceGB = [math]::Round(($disk.Size / 1GB), 2)
            PercentUsed = if ($disk.Size -gt 0) { [math]::Round((($disk.Size - $disk.FreeSpace) / $disk.Size) * 100, 2) } else { 0 }
        }
        OutputDirectory = $outDir
        Counts = [ordered]@{
            SignInEvents = @($signinEvents).Count
            UserProfileEvents = @($userProfileEvents).Count
            DeviceManagementEvents = @($dmEvents).Count
            GroupPolicyEvents = @($groupPolicyEvents).Count
            StartupItems = @($startupItems).Count
        }
    }

    $overview | ConvertTo-Json -Depth 8 | Set-Content -Path (Join-Path $outDir 'corrected-overview.json') -Encoding UTF8
    Export-CsvSafe -InputObject $signinEvents -Path (Join-Path $outDir 'corrected-signin-events.csv')
    Export-CsvSafe -InputObject $signinSummary -Path (Join-Path $outDir 'corrected-signin-summary.csv')
    Export-CsvSafe -InputObject $userProfileEvents -Path (Join-Path $outDir 'corrected-user-profile-events.csv')
    Export-CsvSafe -InputObject $dmEvents -Path (Join-Path $outDir 'corrected-dm-events.csv')
    Export-CsvSafe -InputObject $groupPolicyEvents -Path (Join-Path $outDir 'corrected-group-policy-events.csv')
    Export-CsvSafe -InputObject $startupItems -Path (Join-Path $outDir 'corrected-startup-items.csv')

    [PSCustomObject]@{
        Incident = 'B'
        Version = 'Corrected'
        DryRun = [bool]$DryRun
        OutputDirectory = $outDir
        SignInEvents = @($signinEvents).Count
        UserProfileEvents = @($userProfileEvents).Count
        DMEvents = @($dmEvents).Count
        GroupPolicyEvents = @($groupPolicyEvents).Count
        StartupItems = @($startupItems).Count
    }
}

$startTime = (Get-Date).AddHours(-1 * $HoursBack)
New-Item -Path $OutputRoot -ItemType Directory -Force | Out-Null
$runId = Get-Date -Format 'yyyyMMdd_HHmmss'
$runOutputDirectory = Join-Path $OutputRoot ("incident-B_run_{0}" -f $runId)
New-Item -Path $runOutputDirectory -ItemType Directory -Force | Out-Null

$results = @()
if ($Version -in @('AI','All')) { $results += Invoke-IncidentB_AI -StartTime $startTime -OutDir $runOutputDirectory }
if ($Version -in @('Corrected','All')) { $results += Invoke-IncidentB_Corrected -StartTime $startTime -OutDir $runOutputDirectory }
$results | Format-Table -AutoSize
