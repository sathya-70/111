# Incident C - AI vs Hand-Corrected (Side by Side)

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
$outDir = Join-Path $OutputRoot &quot;incident-C_$runId&quot;
New-Item -Path $outDir -ItemType Directory -Force | Out-Null

$userDesktop = [Environment]::GetFolderPath(&#39;Desktop&#39;)
$publicDesktop = Join-Path $env:PUBLIC &#39;Desktop&#39;

$userShortcuts = if (Test-Path $userDesktop) { Get-ChildItem -Path $userDesktop -Filter *.lnk -File -ErrorAction SilentlyContinue } else { @() }
$publicShortcuts = if (Test-Path $publicDesktop) { Get-ChildItem -Path $publicDesktop -Filter *.lnk -File -ErrorAction SilentlyContinue } else { @() }

$profileEvents = Get-WinEvent -FilterHashtable @{ LogName = &#39;Microsoft-Windows-User Profile Service/Operational&#39;; StartTime = $start } -ErrorAction SilentlyContinue |
    Select-Object -First 500 TimeCreated, Id, MachineName, Message

$msiEvents = Get-WinEvent -FilterHashtable @{ LogName = &#39;Application&#39;; ProviderName = &#39;MsiInstaller&#39;; StartTime = $start } -ErrorAction SilentlyContinue |
    Select-Object -First 500 TimeCreated, Id, MachineName, Message

$summary = [ordered]@{
    Incident = &#39;C&#39;
    DryRun = [bool]$DryRun
    StartTime = $start
    UserDesktop = $userDesktop
    PublicDesktop = $publicDesktop
    UserShortcutCount = @($userShortcuts).Count
    PublicShortcutCount = @($publicShortcuts).Count
    OutputDirectory = $outDir
}

$summary | ConvertTo-Json -Depth 5 | Set-Content -Path (Join-Path $outDir &#39;summary.json&#39;) -Encoding UTF8
$userShortcuts | Select-Object Name, FullName, LastWriteTime | Export-Csv -Path (Join-Path $outDir &#39;user-shortcuts.csv&#39;) -NoTypeInformation -Encoding UTF8
$publicShortcuts | Select-Object Name, FullName, LastWriteTime | Export-Csv -Path (Join-Path $outDir &#39;public-shortcuts.csv&#39;) -NoTypeInformation -Encoding UTF8
$profileEvents | Export-Csv -Path (Join-Path $outDir &#39;profile-events.csv&#39;) -NoTypeInformation -Encoding UTF8
$msiEvents | Export-Csv -Path (Join-Path $outDir &#39;msi-events.csv&#39;) -NoTypeInformation -Encoding UTF8

Write-Host &quot;Incident C evidence pack generated: $outDir&quot;
</pre> | <pre lang="powershell">[CmdletBinding()]
param(
    [switch]$DryRun = $true,
    [ValidateRange(1, 72)]
    [int]$HoursBack = 24,
    [string[]]$ExpectedShortcuts = @(&#39;Microsoft Edge&#39;, &#39;Outlook&#39;, &#39;Teams&#39;),
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
        [int]$MaxEvents = 1200
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
$incidentId = &#39;C&#39;
$outDir = Join-Path -Path $OutputRoot -ChildPath (&quot;incident-{0}_{1}&quot; -f $incidentId, $runId)

New-DirectorySafe -Path $OutputRoot
New-DirectorySafe -Path $outDir

$userDesktop = [Environment]::GetFolderPath(&#39;Desktop&#39;)
$publicDesktop = Join-Path -Path $env:PUBLIC -ChildPath &#39;Desktop&#39;

$userLinks = if (Test-Path -Path $userDesktop) {
    @(Get-ChildItem -Path $userDesktop -Filter &#39;*.lnk&#39; -File -Force -ErrorAction SilentlyContinue)
}
else {
    @()
}

$publicLinks = if (Test-Path -Path $publicDesktop) {
    @(Get-ChildItem -Path $publicDesktop -Filter &#39;*.lnk&#39; -File -Force -ErrorAction SilentlyContinue)
}
else {
    @()
}

$allLinkNames = @(@($userLinks) + @($publicLinks)) | ForEach-Object { $_.BaseName }
$missingExpected = foreach ($expected in $ExpectedShortcuts) {
    if ($allLinkNames -notcontains $expected) {
        [PSCustomObject]@{
            ExpectedShortcut = $expected
            Found = $false
        }
    }
}

$userProfileEvents = Get-WinEventSafe -Filter @{ LogName = &#39;Microsoft-Windows-User Profile Service/Operational&#39;; StartTime = $startTime } -MaxEvents 1200 |
    Select-Object TimeCreated, Id, MachineName, ProviderName, Message

$msiEvents = Get-WinEventSafe -Filter @{ LogName = &#39;Application&#39;; ProviderName = &#39;MsiInstaller&#39;; StartTime = $startTime } -MaxEvents 1200 |
    Select-Object TimeCreated, Id, MachineName, ProviderName, Message

$lnkTouchingPowerShellEvents = Get-WinEventSafe -Filter @{ LogName = &#39;Windows PowerShell&#39;; StartTime = $startTime } -MaxEvents 1200 |
    Where-Object { $_.Message -match &#39;\.lnk&#39; } |
    Select-Object TimeCreated, Id, MachineName, ProviderName, Message

$tempProfileIndicators = try {
    @(Get-ChildItem -Path &#39;Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList&#39; -ErrorAction Stop |
        Where-Object { $_.PSChildName -match &#39;\.bak$&#39; } |
        Select-Object PSChildName, Name)
}
catch {
    @()
}

$shortcutInventory = @(@($userLinks) + @($publicLinks)) | Sort-Object FullName | Select-Object Name, BaseName, FullName, DirectoryName, LastWriteTime

$actionChecklist = @(
    [PSCustomObject]@{ Step = 1; Owner = &#39;Endpoint Engineer&#39;; Action = &#39;Compare missing expected shortcuts with app/package deployment ring.&#39;; Status = &#39;Pending&#39; },
    [PSCustomObject]@{ Step = 2; Owner = &#39;Packaging Engineer&#39;; Action = &#39;Review installer/remediation logic for .lnk create/remove behavior.&#39;; Status = &#39;Pending&#39; },
    [PSCustomObject]@{ Step = 3; Owner = &#39;Profile SME&#39;; Action = &#39;Investigate temporary profile indicators and profile service errors.&#39;; Status = &#39;Pending&#39; },
    [PSCustomObject]@{ Step = 4; Owner = &#39;Service Desk&#39;; Action = &#39;Apply controlled shortcut baseline restore to affected cohort and record success rate.&#39;; Status = &#39;Pending&#39; }
)

$overview = [ordered]@{
    Incident = &#39;Incident C - Missing Desktop Shortcuts&#39;
    DryRun = [bool]$DryRun
    ScriptMode = &#39;ReadOnlyEvidenceCollection&#39;
    StartedFrom = $startTime.ToString(&#39;o&#39;)
    Hostname = $env:COMPUTERNAME
    Username = $env:USERNAME
    UserDesktop = $userDesktop
    PublicDesktop = $publicDesktop
    OutputDirectory = $outDir
    EvidenceFiles = @(
        &#39;overview.json&#39;,
        &#39;shortcut-inventory.csv&#39;,
        &#39;missing-expected-shortcuts.csv&#39;,
        &#39;user-profile-events.csv&#39;,
        &#39;msi-events.csv&#39;,
        &#39;powershell-lnk-events.csv&#39;,
        &#39;temp-profile-indicators.csv&#39;,
        &#39;action-checklist.csv&#39;
    )
    Counts = [ordered]@{
        UserShortcuts = @($userLinks).Count
        PublicShortcuts = @($publicLinks).Count
        MissingExpected = @($missingExpected).Count
        UserProfileEvents = @($userProfileEvents).Count
        MSIEvents = @($msiEvents).Count
        PowerShellLnkEvents = @($lnkTouchingPowerShellEvents).Count
        TempProfileIndicators = @($tempProfileIndicators).Count
    }
}

$overview | ConvertTo-Json -Depth 8 | Set-Content -Path (Join-Path $outDir &#39;overview.json&#39;) -Encoding UTF8
Export-CsvSafe -InputObject $shortcutInventory -Path (Join-Path $outDir &#39;shortcut-inventory.csv&#39;)
Export-CsvSafe -InputObject $missingExpected -Path (Join-Path $outDir &#39;missing-expected-shortcuts.csv&#39;)
Export-CsvSafe -InputObject $userProfileEvents -Path (Join-Path $outDir &#39;user-profile-events.csv&#39;)
Export-CsvSafe -InputObject $msiEvents -Path (Join-Path $outDir &#39;msi-events.csv&#39;)
Export-CsvSafe -InputObject $lnkTouchingPowerShellEvents -Path (Join-Path $outDir &#39;powershell-lnk-events.csv&#39;)
Export-CsvSafe -InputObject $tempProfileIndicators -Path (Join-Path $outDir &#39;temp-profile-indicators.csv&#39;)
Export-CsvSafe -InputObject $actionChecklist -Path (Join-Path $outDir &#39;action-checklist.csv&#39;)

[PSCustomObject]@{
    Incident = &#39;C&#39;
    DryRun = [bool]$DryRun
    OutputDirectory = $outDir
    UserShortcuts = @($userLinks).Count
    PublicShortcuts = @($publicLinks).Count
    MissingExpected = @($missingExpected).Count
    TempProfileIndicators = @($tempProfileIndicators).Count
}
</pre> |

One-line fix note: Fixed shortcut array merge bug and added missing-shortcut detection, profile indicators, and deployment-touch evidence for direct restoration action.
