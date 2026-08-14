[CmdletBinding()]
param(
    [ValidateSet('AI','Corrected','All')]
    [string]$Version = 'All',
    [switch]$DryRun = $true,
    [ValidateRange(1, 168)]
    [int]$HoursBack = 72,
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

function Invoke-IncidentA_AI {
    param(
        [datetime]$StartTime,
        [Parameter(Mandatory = $true)][string]$OutDir
    )

    $outDir = $OutDir

    $summary = [ordered]@{
        Incident = 'A'
        Version = 'AI'
        DryRun = [bool]$DryRun
        StartTime = $StartTime
        OutputDirectory = $outDir
    }

    $securityEvents = Get-WinEvent -FilterHashtable @{ LogName = 'Security'; Id = 4624,4625; StartTime = $StartTime } -ErrorAction SilentlyContinue |
        Select-Object -First 500 TimeCreated, Id, MachineName, Message

    $aadEvents = Get-WinEvent -FilterHashtable @{ LogName = 'Microsoft-Windows-AAD/Operational'; StartTime = $StartTime } -ErrorAction SilentlyContinue |
        Select-Object -First 500 TimeCreated, Id, MachineName, Message

    $groupEvents = Get-WinEvent -FilterHashtable @{ LogName = 'Security'; Id = 4732,4733,4728,4729; StartTime = $StartTime } -ErrorAction SilentlyContinue |
        Select-Object -First 500 TimeCreated, Id, MachineName, Message

    $summary | ConvertTo-Json -Depth 5 | Set-Content -Path (Join-Path $outDir 'ai-summary.json') -Encoding UTF8
    Export-CsvSafe -InputObject $securityEvents -Path (Join-Path $outDir 'ai-security-signin-events.csv')
    Export-CsvSafe -InputObject $aadEvents -Path (Join-Path $outDir 'ai-aad-operational-events.csv')
    Export-CsvSafe -InputObject $groupEvents -Path (Join-Path $outDir 'ai-group-change-events.csv')

    [PSCustomObject]@{
        Incident = 'A'
        Version = 'AI'
        DryRun = [bool]$DryRun
        OutputDirectory = $outDir
        SecuritySignInEvents = @($securityEvents).Count
        GroupAuditEvents = @($groupEvents).Count
        AADOperationalEvents = @($aadEvents).Count
    }
}

function Invoke-IncidentA_Corrected {
    param(
        [datetime]$StartTime,
        [Parameter(Mandatory = $true)][string]$OutDir
    )

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

    $outDir = $OutDir

    $securityEvents = Get-WinEventSafe -Filter @{ LogName = 'Security'; Id = 4624, 4625; StartTime = $StartTime } -MaxEvents 1500 |
        Select-Object TimeCreated, Id, MachineName, ProviderName, LevelDisplayName, Message

    $groupAuditEvents = Get-WinEventSafe -Filter @{ LogName = 'Security'; Id = 4728, 4729, 4732, 4733, 4756, 4757; StartTime = $StartTime } -MaxEvents 1000 |
        Select-Object TimeCreated, Id, MachineName, ProviderName, Message

    $aadEvents = Get-WinEventSafe -Filter @{ LogName = 'Microsoft-Windows-AAD/Operational'; StartTime = $StartTime } -MaxEvents 1000 |
        Select-Object TimeCreated, Id, MachineName, ProviderName, LevelDisplayName, Message

    $logonSummary = $securityEvents | Group-Object -Property Id | Sort-Object Name | ForEach-Object {
        [PSCustomObject]@{
            EventId = [int]$_.Name
            Count = $_.Count
        }
    }

    $actionChecklist = @(
        [PSCustomObject]@{ Step = 1; Owner = 'Security Lead'; Action = 'Correlate request IDs with repository ACL outcomes for reported matter.'; Status = 'Pending' },
        [PSCustomObject]@{ Step = 2; Owner = 'Identity Engineer'; Action = 'Review group membership changes tied to affected user scope in last 72 hours.'; Status = 'Pending' },
        [PSCustomObject]@{ Step = 3; Owner = 'Platform Engineer'; Action = 'Compare connector entitlement decision and source ACL decision for mismatches.'; Status = 'Pending' },
        [PSCustomObject]@{ Step = 4; Owner = 'Incident Manager'; Action = 'Preserve this evidence pack and append cloud-side audit traces using matching timestamps.'; Status = 'Pending' }
    )

    $overview = [ordered]@{
        Incident = 'Incident A - Possible Unauthorized Client Matter Exposure'
        Version = 'Corrected'
        DryRun = [bool]$DryRun
        ScriptMode = 'ReadOnlyEvidenceCollection'
        StartedFrom = $StartTime.ToString('o')
        Hostname = $env:COMPUTERNAME
        Username = $env:USERNAME
        OutputDirectory = $outDir
        Counts = [ordered]@{
            SecuritySignInEvents = @($securityEvents).Count
            GroupAuditEvents = @($groupAuditEvents).Count
            AADOperationalEvents = @($aadEvents).Count
        }
    }

    $overview | ConvertTo-Json -Depth 6 | Set-Content -Path (Join-Path $outDir 'corrected-overview.json') -Encoding UTF8
    Export-CsvSafe -InputObject $securityEvents -Path (Join-Path $outDir 'corrected-security-signin-events.csv')
    Export-CsvSafe -InputObject $groupAuditEvents -Path (Join-Path $outDir 'corrected-group-change-events.csv')
    Export-CsvSafe -InputObject $aadEvents -Path (Join-Path $outDir 'corrected-aad-operational-events.csv')
    Export-CsvSafe -InputObject $logonSummary -Path (Join-Path $outDir 'corrected-logon-summary.csv')
    Export-CsvSafe -InputObject $actionChecklist -Path (Join-Path $outDir 'corrected-action-checklist.csv')

    [PSCustomObject]@{
        Incident = 'A'
        Version = 'Corrected'
        DryRun = [bool]$DryRun
        OutputDirectory = $outDir
        SecuritySignInEvents = @($securityEvents).Count
        GroupAuditEvents = @($groupAuditEvents).Count
        AADOperationalEvents = @($aadEvents).Count
    }
}

$startTime = (Get-Date).AddHours(-1 * $HoursBack)
New-Item -Path $OutputRoot -ItemType Directory -Force | Out-Null
$runId = Get-Date -Format 'yyyyMMdd_HHmmss'
$runOutputDirectory = Join-Path $OutputRoot ("incident-A_run_{0}" -f $runId)
New-Item -Path $runOutputDirectory -ItemType Directory -Force | Out-Null

$results = @()
if ($Version -in @('AI','All')) { $results += Invoke-IncidentA_AI -StartTime $startTime -OutDir $runOutputDirectory }
if ($Version -in @('Corrected','All')) { $results += Invoke-IncidentA_Corrected -StartTime $startTime -OutDir $runOutputDirectory }
$results | Format-Table -AutoSize
