# Incident B - AI vs Hand-Corrected (Side by Side)

| AI-generated version | Hand-corrected version |
|---|---|
| <pre lang="powershell">[CmdletBinding()]
param(
    [switch]$DryRun = $true,
    [int]$HoursBack = 24,
    [string]$OutputRoot = (Join-Path -Path (Split-Path -Parent $MyInvocation.MyCommand.Path) -ChildPath &#39;evidence-artifacts&#39;)
)

$ErrorActionPreference = &#39;Stop&#39;
$start = (Get-Date).AddHours(-1 * $HoursBack)
$runId = Get-Date -Format &#39;yyyyMMdd_HHmmss&#39;
$outDir = Join-Path $OutputRoot &quot;incident-B_$runId&quot;
New-Item -Path $outDir -ItemType Directory -Force | Out-Null

$securityEvents = Get-WinEvent -FilterHashtable @{ LogName = &#39;Security&#39;; Id = 4624,4625; StartTime = $start } -ErrorAction SilentlyContinue |
    Select-Object -First 800 TimeCreated, Id, MachineName, Message

$profileEvents = Get-WinEvent -FilterHashtable @{ LogName = &#39;Microsoft-Windows-User Profile Service/Operational&#39;; StartTime = $start } -ErrorAction SilentlyContinue |
    Select-Object -First 800 TimeCreated, Id, MachineName, Message

$dmEvents = Get-WinEvent -FilterHashtable @{ LogName = &#39;Microsoft-Windows-DeviceManagement-Enterprise-Diagnostics-Provider/Admin&#39;; StartTime = $start } -ErrorAction SilentlyContinue |
    Select-Object -First 800 TimeCreated, Id, MachineName, Message

$startup = Get-CimInstance Win32_StartupCommand -ErrorAction SilentlyContinue |
    Select-Object Name, Command, User, Location

$os = Get-CimInstance Win32_OperatingSystem
$disk = Get-CimInstance Win32_LogicalDisk -Filter &quot;DeviceID=&#39;C:&#39;&quot;

$summary = [ordered]@{
    Incident = &#39;B&#39;
    DryRun = [bool]$DryRun
    StartTime = $start
    LastBoot = $os.LastBootUpTime
    FreeSpaceGB = [math]::Round(($disk.FreeSpace / 1GB), 2)
    TotalSpaceGB = [math]::Round(($disk.Size / 1GB), 2)
    OutputDirectory = $outDir
}

$summary | ConvertTo-Json -Depth 5 | Set-Content -Path (Join-Path $outDir &#39;summary.json&#39;) -Encoding UTF8
$securityEvents | Export-Csv -Path (Join-Path $outDir &#39;security-signin-events.csv&#39;) -NoTypeInformation -Encoding UTF8
$profileEvents | Export-Csv -Path (Join-Path $outDir &#39;profile-events.csv&#39;) -NoTypeInformation -Encoding UTF8
$dmEvents | Export-Csv -Path (Join-Path $outDir &#39;dm-events.csv&#39;) -NoTypeInformation -Encoding UTF8
$startup | Export-Csv -Path (Join-Path $outDir &#39;startup-items.csv&#39;) -NoTypeInformation -Encoding UTF8

Write-Host &quot;Incident B evidence pack generated: $outDir&quot;
</pre> | <pre lang="powershell">[CmdletBinding()]
param(
    [switch]$DryRun = $true,
    [ValidateRange(1, 48)]
    [int]$HoursBack = 24,
    [ValidateNotNullOrEmpty()]
    [string]$OutputRoot = (Join-Path -Path (Split-Path -Parent $MyInvocation.MyCommand.Path) -ChildPath &#39;evidence-artifacts&#39;)
)

Set-StrictMode -Version Latest
$ErrorActionPreference = &#39;Stop&#39;

function New-DirectorySafe {
    param([Parameter(Mandatory = $true)][string]$Path)
    if (-not (Test-Path -Path $Path)) {
        New-Item -Path $Path -ItemType Directory -Force | Out-Null
    }
}

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

$startTime = (Get-Date).AddHours(-1 * $HoursBack)
$runId = Get-Date -Format &#39;yyyyMMdd_HHmmss&#39;
$incidentId = &#39;B&#39;
$outDir = Join-Path -Path $OutputRoot -ChildPath (&quot;incident-{0}_{1}&quot; -f $incidentId, $runId)

New-DirectorySafe -Path $OutputRoot
New-DirectorySafe -Path $outDir

$signinEvents = Get-WinEventSafe -Filter @{ LogName = &#39;Security&#39;; Id = 4624, 4625; StartTime = $startTime } -MaxEvents 2000 |
    Select-Object TimeCreated, Id, MachineName, ProviderName, Message

$userProfileEvents = Get-WinEventSafe -Filter @{ LogName = &#39;Microsoft-Windows-User Profile Service/Operational&#39;; StartTime = $startTime } -MaxEvents 1500 |
    Select-Object TimeCreated, Id, MachineName, ProviderName, Message

$dmEvents = Get-WinEventSafe -Filter @{ LogName = &#39;Microsoft-Windows-DeviceManagement-Enterprise-Diagnostics-Provider/Admin&#39;; StartTime = $startTime } -MaxEvents 1500 |
    Select-Object TimeCreated, Id, MachineName, ProviderName, Message

$groupPolicyEvents = Get-WinEventSafe -Filter @{ LogName = &#39;Microsoft-Windows-GroupPolicy/Operational&#39;; StartTime = $startTime } -MaxEvents 1500 |
    Select-Object TimeCreated, Id, MachineName, ProviderName, Message

$startupItems = try {
    @(Get-CimInstance -ClassName Win32_StartupCommand -ErrorAction Stop | Select-Object Name, Command, User, Location)
}
catch {
    @()
}

$os = Get-CimInstance -ClassName Win32_OperatingSystem
$disk = Get-CimInstance -ClassName Win32_LogicalDisk -Filter &quot;DeviceID=&#39;C:&#39;&quot;
$bootWindowMinutes = [math]::Round(((Get-Date) - $os.LastBootUpTime).TotalMinutes, 2)

$signinSummary = $signinEvents | Group-Object -Property Id | Sort-Object Name | ForEach-Object {
    [PSCustomObject]@{
        EventId = [int]$_.Name
        Count = $_.Count
    }
}

$actionChecklist = @(
    [PSCustomObject]@{ Step = 1; Owner = &#39;Endpoint Lead&#39;; Action = &#39;Compare impacted devices against this host baseline and identify shared policy/app timing markers.&#39;; Status = &#39;Pending&#39; },
    [PSCustomObject]@{ Step = 2; Owner = &#39;Identity Engineer&#39;; Action = &#39;Map 4625 failures by time to conditional access decisions and MFA outcomes.&#39;; Status = &#39;Pending&#39; },
    [PSCustomObject]@{ Step = 3; Owner = &#39;Intune Engineer&#39;; Action = &#39;Correlate DM and GroupPolicy events with sign-in windows for delays/conflicts.&#39;; Status = &#39;Pending&#39; },
    [PSCustomObject]@{ Step = 4; Owner = &#39;Service Desk Coordinator&#39;; Action = &#39;Use startup-items and profile event indicators to prioritize manual remediation order.&#39;; Status = &#39;Pending&#39; }
)

$overview = [ordered]@{
    Incident = &#39;Incident B - Login Failures and Severe Slowness&#39;
    DryRun = [bool]$DryRun
    ScriptMode = &#39;ReadOnlyEvidenceCollection&#39;
    StartedFrom = $startTime.ToString(&#39;o&#39;)
    Hostname = $env:COMPUTERNAME
    Username = $env:USERNAME
    LastBootUpTime = $os.LastBootUpTime.ToString(&#39;o&#39;)
    MinutesSinceBoot = $bootWindowMinutes
    Disk = [ordered]@{
        Drive = &#39;C:&#39;
        FreeSpaceGB = [math]::Round(($disk.FreeSpace / 1GB), 2)
        TotalSpaceGB = [math]::Round(($disk.Size / 1GB), 2)
        PercentUsed = if ($disk.Size -gt 0) { [math]::Round((($disk.Size - $disk.FreeSpace) / $disk.Size) * 100, 2) } else { 0 }
    }
    OutputDirectory = $outDir
    EvidenceFiles = @(
        &#39;overview.json&#39;,
        &#39;signin-events.csv&#39;,
        &#39;signin-summary.csv&#39;,
        &#39;user-profile-events.csv&#39;,
        &#39;dm-events.csv&#39;,
        &#39;group-policy-events.csv&#39;,
        &#39;startup-items.csv&#39;,
        &#39;action-checklist.csv&#39;
    )
    Counts = [ordered]@{
        SignInEvents = @($signinEvents).Count
        UserProfileEvents = @($userProfileEvents).Count
        DeviceManagementEvents = @($dmEvents).Count
        GroupPolicyEvents = @($groupPolicyEvents).Count
        StartupItems = @($startupItems).Count
    }
}

$overview | ConvertTo-Json -Depth 8 | Set-Content -Path (Join-Path $outDir &#39;overview.json&#39;) -Encoding UTF8
Export-CsvSafe -InputObject $signinEvents -Path (Join-Path $outDir &#39;signin-events.csv&#39;)
Export-CsvSafe -InputObject $signinSummary -Path (Join-Path $outDir &#39;signin-summary.csv&#39;)
Export-CsvSafe -InputObject $userProfileEvents -Path (Join-Path $outDir &#39;user-profile-events.csv&#39;)
Export-CsvSafe -InputObject $dmEvents -Path (Join-Path $outDir &#39;dm-events.csv&#39;)
Export-CsvSafe -InputObject $groupPolicyEvents -Path (Join-Path $outDir &#39;group-policy-events.csv&#39;)
Export-CsvSafe -InputObject $startupItems -Path (Join-Path $outDir &#39;startup-items.csv&#39;)
Export-CsvSafe -InputObject $actionChecklist -Path (Join-Path $outDir &#39;action-checklist.csv&#39;)

[PSCustomObject]@{
    Incident = &#39;B&#39;
    DryRun = [bool]$DryRun
    OutputDirectory = $outDir
    SignInEvents = @($signinEvents).Count
    UserProfileEvents = @($userProfileEvents).Count
    DMEvents = @($dmEvents).Count
    GroupPolicyEvents = @($groupPolicyEvents).Count
    StartupItems = @($startupItems).Count
}
</pre> |

One-line fix note: Added normalized schema, expanded correlation sources, null-safe exports, and remediation-priority checklist for reliable login incident triage.
