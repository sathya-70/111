# Incident A - AI vs Hand-Corrected (Side by Side)

| AI-generated version | Hand-corrected version |
|---|---|
| <pre lang="powershell">[CmdletBinding()]
param(
    [switch]$DryRun = $true,
    [int]$HoursBack = 72,
    [string]$OutputRoot = (Join-Path -Path (Split-Path -Parent $MyInvocation.MyCommand.Path) -ChildPath &#39;evidence-artifacts&#39;)
)

$ErrorActionPreference = &#39;Stop&#39;
$start = (Get-Date).AddHours(-1 * $HoursBack)
$runId = Get-Date -Format &#39;yyyyMMdd_HHmmss&#39;
$outDir = Join-Path $OutputRoot &quot;incident-A_$runId&quot;
New-Item -Path $outDir -ItemType Directory -Force | Out-Null

$summary = [ordered]@{
    Incident = &#39;A&#39;
    DryRun = [bool]$DryRun
    StartTime = $start
    OutputDirectory = $outDir
}

$securityEvents = Get-WinEvent -FilterHashtable @{ LogName = &#39;Security&#39;; Id = 4624,4625; StartTime = $start } -ErrorAction SilentlyContinue |
    Select-Object -First 500 TimeCreated, Id, MachineName, Message

$aadEvents = Get-WinEvent -FilterHashtable @{ LogName = &#39;Microsoft-Windows-AAD/Operational&#39;; StartTime = $start } -ErrorAction SilentlyContinue |
    Select-Object -First 500 TimeCreated, Id, MachineName, Message

$groupEvents = Get-WinEvent -FilterHashtable @{ LogName = &#39;Security&#39;; Id = 4732,4733,4728,4729; StartTime = $start } -ErrorAction SilentlyContinue |
    Select-Object -First 500 TimeCreated, Id, MachineName, Message

$summaryPath = Join-Path $outDir &#39;summary.json&#39;
$securityPath = Join-Path $outDir &#39;security-signin-events.csv&#39;
$aadPath = Join-Path $outDir &#39;aad-operational-events.csv&#39;
$groupPath = Join-Path $outDir &#39;group-change-events.csv&#39;

$summary | ConvertTo-Json -Depth 5 | Set-Content -Path $summaryPath -Encoding UTF8
$securityEvents | Export-Csv -Path $securityPath -NoTypeInformation -Encoding UTF8
$aadEvents | Export-Csv -Path $aadPath -NoTypeInformation -Encoding UTF8
$groupEvents | Export-Csv -Path $groupPath -NoTypeInformation -Encoding UTF8

Write-Host &quot;Incident A evidence pack generated: $outDir&quot;
</pre> | <pre lang="powershell">[CmdletBinding()]
param(
    [switch]$DryRun = $true,
    [ValidateRange(1, 168)]
    [int]$HoursBack = 72,
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
        [int]$MaxEvents = 1000
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
$incidentId = &#39;A&#39;
$outDir = Join-Path -Path $OutputRoot -ChildPath (&quot;incident-{0}_{1}&quot; -f $incidentId, $runId)

New-DirectorySafe -Path $OutputRoot
New-DirectorySafe -Path $outDir

$securityEvents = Get-WinEventSafe -Filter @{ LogName = &#39;Security&#39;; Id = 4624, 4625; StartTime = $startTime } -MaxEvents 1500 |
    Select-Object TimeCreated, Id, MachineName, ProviderName, LevelDisplayName, Message

$groupAuditEvents = Get-WinEventSafe -Filter @{ LogName = &#39;Security&#39;; Id = 4728, 4729, 4732, 4733, 4756, 4757; StartTime = $startTime } -MaxEvents 1000 |
    Select-Object TimeCreated, Id, MachineName, ProviderName, Message

$aadEvents = Get-WinEventSafe -Filter @{ LogName = &#39;Microsoft-Windows-AAD/Operational&#39;; StartTime = $startTime } -MaxEvents 1000 |
    Select-Object TimeCreated, Id, MachineName, ProviderName, LevelDisplayName, Message

$logonSummary = $securityEvents | Group-Object -Property Id | Sort-Object Name | ForEach-Object {
    [PSCustomObject]@{
        EventId = [int]$_.Name
        Count = $_.Count
    }
}

$principalContext = try { whoami /all } catch { @(&#39;Unable to query whoami /all in current context.&#39;) }

$actionChecklist = @(
    [PSCustomObject]@{ Step = 1; Owner = &#39;Security Lead&#39;; Action = &#39;Correlate request IDs with repository ACL outcomes for reported matter.&#39;; Status = &#39;Pending&#39; },
    [PSCustomObject]@{ Step = 2; Owner = &#39;Identity Engineer&#39;; Action = &#39;Review group membership changes tied to affected user scope in last 72 hours.&#39;; Status = &#39;Pending&#39; },
    [PSCustomObject]@{ Step = 3; Owner = &#39;Platform Engineer&#39;; Action = &#39;Compare connector entitlement decision and source ACL decision for mismatches.&#39;; Status = &#39;Pending&#39; },
    [PSCustomObject]@{ Step = 4; Owner = &#39;Incident Manager&#39;; Action = &#39;Preserve this evidence pack and append cloud-side audit traces using matching timestamps.&#39;; Status = &#39;Pending&#39; }
)

$overview = [ordered]@{
    Incident = &#39;Incident A - Possible Unauthorized Client Matter Exposure&#39;
    DryRun = [bool]$DryRun
    ScriptMode = &#39;ReadOnlyEvidenceCollection&#39;
    StartedFrom = $startTime.ToString(&#39;o&#39;)
    Hostname = $env:COMPUTERNAME
    Username = $env:USERNAME
    OutputDirectory = $outDir
    EvidenceFiles = @(
        &#39;overview.json&#39;,
        &#39;security-signin-events.csv&#39;,
        &#39;group-change-events.csv&#39;,
        &#39;aad-operational-events.csv&#39;,
        &#39;logon-summary.csv&#39;,
        &#39;principal-context.txt&#39;,
        &#39;action-checklist.csv&#39;
    )
    Counts = [ordered]@{
        SecuritySignInEvents = @($securityEvents).Count
        GroupAuditEvents = @($groupAuditEvents).Count
        AADOperationalEvents = @($aadEvents).Count
    }
}

$overview | ConvertTo-Json -Depth 6 | Set-Content -Path (Join-Path $outDir &#39;overview.json&#39;) -Encoding UTF8
Export-CsvSafe -InputObject $securityEvents -Path (Join-Path $outDir &#39;security-signin-events.csv&#39;)
Export-CsvSafe -InputObject $groupAuditEvents -Path (Join-Path $outDir &#39;group-change-events.csv&#39;)
Export-CsvSafe -InputObject $aadEvents -Path (Join-Path $outDir &#39;aad-operational-events.csv&#39;)
Export-CsvSafe -InputObject $logonSummary -Path (Join-Path $outDir &#39;logon-summary.csv&#39;)
$principalContext | Set-Content -Path (Join-Path $outDir &#39;principal-context.txt&#39;) -Encoding UTF8
Export-CsvSafe -InputObject $actionChecklist -Path (Join-Path $outDir &#39;action-checklist.csv&#39;)

[PSCustomObject]@{
    Incident = &#39;A&#39;
    DryRun = [bool]$DryRun
    OutputDirectory = $outDir
    SecuritySignInEvents = @($securityEvents).Count
    GroupAuditEvents = @($groupAuditEvents).Count
    AADOperationalEvents = @($aadEvents).Count
}
</pre> |

One-line fix note: Added strict-mode safety, resilient empty-log handling, and actionable checklist output to ensure usable evidence even with limited event access.
