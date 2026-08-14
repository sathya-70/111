[CmdletBinding()]
param(
    [ValidateSet('AI','Corrected','All')]
    [string]$Version = 'All',
    [switch]$DryRun = $true,
    [ValidateRange(1, 72)]
    [int]$HoursBack = 24,
    [string[]]$ExpectedShortcuts = @('Microsoft Edge', 'Outlook', 'Teams'),
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

function Invoke-IncidentC_AI {
    param(
        [datetime]$StartTime,
        [Parameter(Mandatory = $true)][string]$OutDir
    )

    $outDir = $OutDir

    $userDesktop = [Environment]::GetFolderPath('Desktop')
    $publicDesktop = Join-Path $env:PUBLIC 'Desktop'

    $userShortcuts = if (Test-Path $userDesktop) { Get-ChildItem -Path $userDesktop -Filter *.lnk -File -ErrorAction SilentlyContinue } else { @() }
    $publicShortcuts = if (Test-Path $publicDesktop) { Get-ChildItem -Path $publicDesktop -Filter *.lnk -File -ErrorAction SilentlyContinue } else { @() }

    $profileEvents = Get-WinEvent -FilterHashtable @{ LogName = 'Microsoft-Windows-User Profile Service/Operational'; StartTime = $StartTime } -ErrorAction SilentlyContinue |
        Select-Object -First 500 TimeCreated, Id, MachineName, Message

    $msiEvents = Get-WinEvent -FilterHashtable @{ LogName = 'Application'; StartTime = $StartTime } -ErrorAction SilentlyContinue |
        Where-Object { $_.ProviderName -eq 'MsiInstaller' } |
        Select-Object -First 500 TimeCreated, Id, MachineName, Message

    $summary = [ordered]@{
        Incident = 'C'
        Version = 'AI'
        DryRun = [bool]$DryRun
        StartTime = $StartTime
        UserDesktop = $userDesktop
        PublicDesktop = $publicDesktop
        UserShortcutCount = @($userShortcuts).Count
        PublicShortcutCount = @($publicShortcuts).Count
        OutputDirectory = $outDir
    }

    $summary | ConvertTo-Json -Depth 5 | Set-Content -Path (Join-Path $outDir 'ai-summary.json') -Encoding UTF8
    Export-CsvSafe -InputObject ($userShortcuts | Select-Object Name, FullName, LastWriteTime) -Path (Join-Path $outDir 'ai-user-shortcuts.csv')
    Export-CsvSafe -InputObject ($publicShortcuts | Select-Object Name, FullName, LastWriteTime) -Path (Join-Path $outDir 'ai-public-shortcuts.csv')
    Export-CsvSafe -InputObject $profileEvents -Path (Join-Path $outDir 'ai-profile-events.csv')
    Export-CsvSafe -InputObject $msiEvents -Path (Join-Path $outDir 'ai-msi-events.csv')

    [PSCustomObject]@{
        Incident = 'C'
        Version = 'AI'
        DryRun = [bool]$DryRun
        OutputDirectory = $outDir
        UserShortcuts = @($userShortcuts).Count
        PublicShortcuts = @($publicShortcuts).Count
        UserProfileEvents = @($profileEvents).Count
        MSIEvents = @($msiEvents).Count
    }
}

function Invoke-IncidentC_Corrected {
    param(
        [datetime]$StartTime,
        [Parameter(Mandatory = $true)][string]$OutDir
    )

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

    $outDir = $OutDir

    $userDesktop = [Environment]::GetFolderPath('Desktop')
    $publicDesktop = Join-Path -Path $env:PUBLIC -ChildPath 'Desktop'

    $userLinks = if (Test-Path -Path $userDesktop) {
        @(Get-ChildItem -Path $userDesktop -Filter '*.lnk' -File -Force -ErrorAction SilentlyContinue)
    }
    else {
        @()
    }

    $publicLinks = if (Test-Path -Path $publicDesktop) {
        @(Get-ChildItem -Path $publicDesktop -Filter '*.lnk' -File -Force -ErrorAction SilentlyContinue)
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

    $userProfileEvents = Get-WinEventSafe -Filter @{ LogName = 'Microsoft-Windows-User Profile Service/Operational'; StartTime = $StartTime } -MaxEvents 1200 |
        Select-Object TimeCreated, Id, MachineName, ProviderName, Message

    $msiEvents = Get-WinEventSafe -Filter @{ LogName = 'Application'; ProviderName = 'MsiInstaller'; StartTime = $StartTime } -MaxEvents 1200 |
        Select-Object TimeCreated, Id, MachineName, ProviderName, Message

    $lnkTouchingPowerShellEvents = Get-WinEventSafe -Filter @{ LogName = 'Windows PowerShell'; StartTime = $StartTime } -MaxEvents 1200 |
        Where-Object { $_.Message -match '\.lnk' } |
        Select-Object TimeCreated, Id, MachineName, ProviderName, Message

    $tempProfileIndicators = try {
        @(Get-ChildItem -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList' -ErrorAction Stop |
            Where-Object { $_.PSChildName -match '\.bak$' } |
            Select-Object PSChildName, Name)
    }
    catch {
        @()
    }

    $shortcutInventory = @(@($userLinks) + @($publicLinks)) | Sort-Object FullName | Select-Object Name, BaseName, FullName, DirectoryName, LastWriteTime

    $overview = [ordered]@{
        Incident = 'Incident C - Missing Desktop Shortcuts'
        Version = 'Corrected'
        DryRun = [bool]$DryRun
        StartedFrom = $StartTime.ToString('o')
        Hostname = $env:COMPUTERNAME
        Username = $env:USERNAME
        UserDesktop = $userDesktop
        PublicDesktop = $publicDesktop
        OutputDirectory = $outDir
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

    $overview | ConvertTo-Json -Depth 8 | Set-Content -Path (Join-Path $outDir 'corrected-overview.json') -Encoding UTF8
    Export-CsvSafe -InputObject $shortcutInventory -Path (Join-Path $outDir 'corrected-shortcut-inventory.csv')
    Export-CsvSafe -InputObject $missingExpected -Path (Join-Path $outDir 'corrected-missing-expected-shortcuts.csv')
    Export-CsvSafe -InputObject $userProfileEvents -Path (Join-Path $outDir 'corrected-user-profile-events.csv')
    Export-CsvSafe -InputObject $msiEvents -Path (Join-Path $outDir 'corrected-msi-events.csv')
    Export-CsvSafe -InputObject $lnkTouchingPowerShellEvents -Path (Join-Path $outDir 'corrected-powershell-lnk-events.csv')
    Export-CsvSafe -InputObject $tempProfileIndicators -Path (Join-Path $outDir 'corrected-temp-profile-indicators.csv')

    [PSCustomObject]@{
        Incident = 'C'
        Version = 'Corrected'
        DryRun = [bool]$DryRun
        OutputDirectory = $outDir
        UserShortcuts = @($userLinks).Count
        PublicShortcuts = @($publicLinks).Count
        MissingExpected = @($missingExpected).Count
        TempProfileIndicators = @($tempProfileIndicators).Count
    }
}

$startTime = (Get-Date).AddHours(-1 * $HoursBack)
New-Item -Path $OutputRoot -ItemType Directory -Force | Out-Null
$runId = Get-Date -Format 'yyyyMMdd_HHmmss'
$runOutputDirectory = Join-Path $OutputRoot ("incident-C_run_{0}" -f $runId)
New-Item -Path $runOutputDirectory -ItemType Directory -Force | Out-Null

$results = @()
if ($Version -in @('AI','All')) { $results += Invoke-IncidentC_AI -StartTime $startTime -OutDir $runOutputDirectory }
if ($Version -in @('Corrected','All')) { $results += Invoke-IncidentC_Corrected -StartTime $startTime -OutDir $runOutputDirectory }
$results | Format-Table -AutoSize
