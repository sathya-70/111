<#
.SYNOPSIS
Safely archives and cleans Windows Event Logs on endpoint devices (PowerShell 5.1).

.DESCRIPTION
This script is designed for DWP endpoint-safe operations.
- Supports dry-run mode and prints the record count that would be deleted.
- Targets only logs whose newest event is older than a configurable cutoff.
- Archives each target log before clearing it.
- Uses timestamped logging for every action.
- Writes a JSONL manifest for audit and rollback.
- Includes rollback mode (best effort) using archived EVTX files.
- Idempotent archive behavior: if today's archive exists for a log, it skips that log.
#>

[CmdletBinding()]
param(
    # Number of days used to calculate the cutoff date. Only logs fully older than this are targeted.
    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 3650)]
    [int]$OlderThanDays = 3,

    # Dry-run mode: no archive/clear changes are made.
    [Parameter(Mandatory = $false)]
    [switch]$DryRun,

    # Rollback mode: uses a manifest and archived files to attempt rollback handling.
    [Parameter(Mandatory = $false)]
    [switch]$Rollback,

    # Optional manifest path used by rollback mode. If omitted, latest manifest is selected.
    [Parameter(Mandatory = $false)]
    [string]$ManifestPath,

    # Optional log name wildcard (for example: Application, System, Microsoft-Windows-*).
    [Parameter(Mandatory = $false)]
    [string]$LogNamePattern = '*',

    # Optional run identifier used in manifest and folder naming.
    [Parameter(Mandatory = $false)]
    [string]$RunId = (Get-Date -Format 'yyyyMMdd_HHmmss')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# -----------------------------------------------------------------------------
# Section: Path and artifact initialization
# What this does:
# - Creates local script artifact folders for logs, archives, manifests, and rollback output.
# - Keeps all operational outputs together for auditability.
# -----------------------------------------------------------------------------
$scriptRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
$artifactRoot = Join-Path -Path $scriptRoot -ChildPath 'event-log-artifacts'
$logDir = Join-Path -Path $artifactRoot -ChildPath 'logs'
$archiveDir = Join-Path -Path $artifactRoot -ChildPath 'archives'
$manifestDir = Join-Path -Path $artifactRoot -ChildPath 'manifests'
$rollbackDir = Join-Path -Path $artifactRoot -ChildPath 'rollback-output'

$logFile = Join-Path -Path $logDir -ChildPath ("event-log-cleanup_{0}.log" -f (Get-Date -Format 'yyyyMMdd_HHmmss'))

# -----------------------------------------------------------------------------
# Section: Logging helper
# What this does:
# - Writes timestamped actions to console and log file.
# - Ensures operation traceability for support and auditing.
# -----------------------------------------------------------------------------
function Write-Log {
    param(
        [Parameter(Mandatory = $true)][string]$Level,
        [Parameter(Mandatory = $true)][string]$Message
    )

    try {
        $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        $entry = "[{0}] [{1}] {2}" -f $timestamp, $Level.ToUpperInvariant(), $Message
        Add-Content -Path $logFile -Value $entry
        Write-Host $entry
    }
    catch {
        Write-Host "[LOGGING-FAILURE] $Message"
    }
}

# -----------------------------------------------------------------------------
# Section: Safe directory creation helper
# What this does:
# - Creates a directory if missing.
# - Wraps each directory operation in try/catch.
# -----------------------------------------------------------------------------
function Ensure-Directory {
    param(
        [Parameter(Mandatory = $true)][string]$Path
    )

    try {
        if (-not (Test-Path -Path $Path)) {
            New-Item -Path $Path -ItemType Directory -Force | Out-Null
            Write-Log -Level 'INFO' -Message ("Created directory: {0}" -f $Path)
        }
        else {
            Write-Log -Level 'INFO' -Message ("Directory already exists: {0}" -f $Path)
        }
    }
    catch {
        throw ("Failed to ensure directory: {0}. Error: {1}" -f $Path, $_.Exception.Message)
    }
}

# -----------------------------------------------------------------------------
# Section: Utility helpers
# What this does:
# - Normalizes log names for file naming.
# - Runs wevtutil commands and checks exit code.
# -----------------------------------------------------------------------------
function Convert-LogNameToFileSafeName {
    param(
        [Parameter(Mandatory = $true)][string]$LogName
    )

    try {
        $safe = $LogName -replace '[\\/:*?"<>|]', '_'
        return $safe
    }
    catch {
        throw ("Failed to sanitize log name '{0}': {1}" -f $LogName, $_.Exception.Message)
    }
}

function Invoke-WevtUtil {
    param(
        [Parameter(Mandatory = $true)][string[]]$Arguments,
        [Parameter(Mandatory = $true)][string]$ActionDescription
    )

    try {
        & wevtutil @Arguments | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw ("wevtutil exited with code {0} while: {1}" -f $LASTEXITCODE, $ActionDescription)
        }
        Write-Log -Level 'INFO' -Message ("wevtutil success: {0}" -f $ActionDescription)
    }
    catch {
        throw ("wevtutil failure: {0}. Error: {1}" -f $ActionDescription, $_.Exception.Message)
    }
}

# -----------------------------------------------------------------------------
# Section: Discover target logs helper
# What this does:
# - Enumerates candidate logs.
# - Evaluates each log's newest event timestamp.
# - Selects only logs where newest event is older than cutoff date.
# -----------------------------------------------------------------------------
function Get-TargetLogsForCleanup {
    param(
        [Parameter(Mandatory = $true)][int]$Days,
        [Parameter(Mandatory = $true)][string]$Pattern
    )

    $targets = @()
    $cutoffDate = (Get-Date).AddDays(-1 * $Days)

    try {
        $logs = @(Get-WinEvent -ListLog $Pattern -ErrorAction Stop |
            Where-Object { $_.IsEnabled -and $_.RecordCount -gt 0 }
        )
        Write-Log -Level 'INFO' -Message ("Discovered {0} enabled logs with records using pattern '{1}'." -f $logs.Count, $Pattern)
    }
    catch {
        throw ("Failed to enumerate event logs. Error: {0}" -f $_.Exception.Message)
    }

    foreach ($log in $logs) {
        try {
            $latest = Get-WinEvent -FilterHashtable @{ LogName = $log.LogName } -MaxEvents 1 -ErrorAction Stop
            if ($null -eq $latest) {
                Write-Log -Level 'WARN' -Message ("No readable events found in log despite record count > 0. Skipping: {0}" -f $log.LogName)
                continue
            }

            if ($latest.TimeCreated -lt $cutoffDate) {
                $targets += [PSCustomObject]@{
                    LogName         = $log.LogName
                    RecordCount     = [int64]$log.RecordCount
                    NewestEventTime = [datetime]$latest.TimeCreated
                    LogFilePath     = $log.LogFilePath
                }
                Write-Log -Level 'INFO' -Message ("Target selected: {0}; Records={1}; NewestEvent={2}" -f $log.LogName, $log.RecordCount, $latest.TimeCreated)
            }
            else {
                Write-Log -Level 'INFO' -Message ("Log excluded by age rule: {0}; NewestEvent={1}" -f $log.LogName, $latest.TimeCreated)
            }
        }
        catch {
            Write-Log -Level 'ERROR' -Message ("Failed evaluating log: {0}. Error: {1}" -f $log.LogName, $_.Exception.Message)
        }
    }

    return [PSCustomObject]@{
        CutoffDate     = $cutoffDate
        CandidateCount = $logs.Count
        Targets        = $targets
    }
}

# -----------------------------------------------------------------------------
# Section: Cleanup mode
# What this does:
# - Archives each target log to EVTX.
# - Clears archived logs.
# - Writes a manifest entry for each successful clear.
# - Honors idempotency by skipping logs already archived today.
# -----------------------------------------------------------------------------
function Invoke-EventLogCleanup {
    param(
        [Parameter(Mandatory = $true)][int]$Days,
        [Parameter(Mandatory = $true)][switch]$IsDryRun,
        [Parameter(Mandatory = $true)][string]$Pattern,
        [Parameter(Mandatory = $true)][string]$CleanupRunId
    )

    $summary = [ordered]@{
        Mode                         = if ($IsDryRun) { 'DryRun' } else { 'Cleanup' }
        OlderThanDays                = $Days
        CandidateLogs                = 0
        TargetLogs                   = 0
        RecordsToDelete              = 0
        ArchivedLogs                 = 0
        ClearedLogs                  = 0
        SkippedArchiveExistsToday    = 0
        PerLogErrors                 = 0
        ManifestPath                 = '<none>'
        LogFile                      = $logFile
    }

    $manifestPath = Join-Path -Path $manifestDir -ChildPath ("manifest_{0}.jsonl" -f $CleanupRunId)

    try {
        $discovery = Get-TargetLogsForCleanup -Days $Days -Pattern $Pattern
        $targets = @($discovery.Targets)
        $summary.CandidateLogs = $discovery.CandidateCount
        $summary.TargetLogs = $targets.Count
        if ($targets.Count -gt 0) {
            $summary.RecordsToDelete = ($targets | Measure-Object -Property RecordCount -Sum).Sum
            if ($null -eq $summary.RecordsToDelete) { $summary.RecordsToDelete = 0 }
        }
        else {
            $summary.RecordsToDelete = 0
        }

        Write-Log -Level 'INFO' -Message ("Cleanup mode start. DryRun={0}; CutoffDate={1}; TargetLogs={2}; RecordsToDelete={3}" -f [bool]$IsDryRun, $discovery.CutoffDate, $summary.TargetLogs, $summary.RecordsToDelete)
    }
    catch {
        throw ("Failed during target discovery. Error: {0}" -f $_.Exception.Message)
    }

    if ($IsDryRun) {
        foreach ($target in $targets) {
            try {
                Write-Log -Level 'INFO' -Message ("DRYRUN target => Log={0}; RecordCount={1}; NewestEvent={2}" -f $target.LogName, $target.RecordCount, $target.NewestEventTime)
            }
            catch {
                $summary.PerLogErrors++
                Write-Log -Level 'ERROR' -Message ("Dry-run log output failure for {0}. Error: {1}" -f $target.LogName, $_.Exception.Message)
            }
        }

        Write-Host "Dry-run records that would be deleted: $($summary.RecordsToDelete)"
        return [PSCustomObject]$summary
    }

    try {
        if (-not (Test-Path -Path $manifestPath)) {
            New-Item -Path $manifestPath -ItemType File -Force | Out-Null
        }
        $summary.ManifestPath = $manifestPath
    }
    catch {
        throw ("Failed to initialize manifest file {0}. Error: {1}" -f $manifestPath, $_.Exception.Message)
    }

    $todayTag = Get-Date -Format 'yyyyMMdd'

    foreach ($target in $targets) {
        try {
            $safeLogName = Convert-LogNameToFileSafeName -LogName $target.LogName
            $archiveFile = Join-Path -Path $archiveDir -ChildPath ("{0}_{1}.evtx" -f $safeLogName, $todayTag)

            # Idempotency guard: if today's archive file exists for this log, skip archive and clear.
            if (Test-Path -Path $archiveFile) {
                $summary.SkippedArchiveExistsToday++
                Write-Log -Level 'INFO' -Message ("Skipping log due to existing archive for today: {0} => {1}" -f $target.LogName, $archiveFile)
                continue
            }

            # Archive first, then clear.
            Invoke-WevtUtil -Arguments @('epl', $target.LogName, $archiveFile, '/ow:true') -ActionDescription ("Archive log '{0}' to '{1}'" -f $target.LogName, $archiveFile)
            $summary.ArchivedLogs++

            Invoke-WevtUtil -Arguments @('cl', $target.LogName) -ActionDescription ("Clear log '{0}'" -f $target.LogName)
            $summary.ClearedLogs++

            $manifestEntry = [PSCustomObject]@{
                RunId            = $CleanupRunId
                LogName          = $target.LogName
                ArchivePath      = $archiveFile
                RecordCountAtRun = $target.RecordCount
                NewestEventAtRun = $target.NewestEventTime.ToString('o')
                ClearedAt        = (Get-Date).ToString('o')
                OlderThanDays    = $Days
                CutoffDate       = ((Get-Date).AddDays(-1 * $Days)).ToString('o')
                RollbackStatus   = 'NotRequested'
            }

            Add-Content -Path $manifestPath -Value ($manifestEntry | ConvertTo-Json -Compress)
            Write-Log -Level 'INFO' -Message ("Manifest entry added for log: {0}" -f $target.LogName)
        }
        catch {
            $summary.PerLogErrors++
            Write-Log -Level 'ERROR' -Message ("Per-log operation failed for {0}. Error: {1}" -f $target.LogName, $_.Exception.Message)
        }
    }

    Write-Log -Level 'INFO' -Message 'Cleanup mode completed.'
    return [PSCustomObject]$summary
}

# -----------------------------------------------------------------------------
# Section: Rollback mode
# What this does:
# - Reads manifest entries from a prior cleanup run.
# - Performs best-effort rollback by preserving archive files in a dated rollback folder.
# - Attempts direct live-log file restore when safe; if not possible, records a fallback action.
# - Keeps rollback idempotent by skipping entries already handled.
# -----------------------------------------------------------------------------
function Invoke-EventLogRollback {
    param(
        [Parameter(Mandatory = $false)][string]$InputManifestPath
    )

    $summary = [ordered]@{
        Mode                        = 'Rollback'
        ManifestPath                = '<none>'
        EntriesRead                 = 0
        RollbackHandled             = 0
        LiveRestoreSucceeded        = 0
        FallbackCopyOnly            = 0
        SkippedAlreadyHandled       = 0
        RollbackErrors              = 0
        LogFile                     = $logFile
    }

    $selectedManifest = $null

    try {
        if ($InputManifestPath) {
            $selectedManifest = $InputManifestPath
        }
        else {
            $selectedManifest = Get-ChildItem -Path $manifestDir -File -Filter 'manifest_*.jsonl' |
                Sort-Object -Property LastWriteTime -Descending |
                Select-Object -First 1 -ExpandProperty FullName
        }
    }
    catch {
        throw ("Failed selecting manifest for rollback. Error: {0}" -f $_.Exception.Message)
    }

    if (-not $selectedManifest) {
        throw 'No manifest found for rollback. Provide -ManifestPath or run cleanup first.'
    }

    try {
        if (-not (Test-Path -Path $selectedManifest)) {
            throw ("Manifest not found: {0}" -f $selectedManifest)
        }
        $summary.ManifestPath = $selectedManifest
    }
    catch {
        throw ("Rollback manifest validation failed. Error: {0}" -f $_.Exception.Message)
    }

    $rollbackRunFolder = Join-Path -Path $rollbackDir -ChildPath (Get-Date -Format 'yyyyMMdd_HHmmss')
    try {
        Ensure-Directory -Path $rollbackRunFolder
    }
    catch {
        throw ("Failed creating rollback folder. Error: {0}" -f $_.Exception.Message)
    }

    Write-Log -Level 'INFO' -Message ("Rollback mode started with manifest: {0}" -f $selectedManifest)

    try {
        $lines = Get-Content -Path $selectedManifest -ErrorAction Stop
    }
    catch {
        throw ("Failed reading manifest. Error: {0}" -f $_.Exception.Message)
    }

    $updatedManifestLines = @()

    foreach ($line in $lines) {
        if ([string]::IsNullOrWhiteSpace($line)) {
            continue
        }

        $summary.EntriesRead++

        try {
            $entry = $line | ConvertFrom-Json -ErrorAction Stop

            if ($entry.RollbackStatus -like 'Handled*') {
                $summary.SkippedAlreadyHandled++
                Write-Log -Level 'INFO' -Message ("Skipping already handled rollback entry for log: {0}" -f $entry.LogName)
                $updatedManifestLines += ($entry | ConvertTo-Json -Compress)
                continue
            }

            if (-not (Test-Path -Path $entry.ArchivePath)) {
                throw ("Archive not found for rollback entry: {0}" -f $entry.ArchivePath)
            }

            $safeLogName = Convert-LogNameToFileSafeName -LogName $entry.LogName
            $fallbackFile = Join-Path -Path $rollbackRunFolder -ChildPath ("{0}_rollbackcopy.evtx" -f $safeLogName)

            # Fallback action: keep a rollback copy in rollback-output even if live restore is not possible.
            Copy-Item -Path $entry.ArchivePath -Destination $fallbackFile -Force -ErrorAction Stop
            $summary.FallbackCopyOnly++
            Write-Log -Level 'INFO' -Message ("Rollback fallback copy created: {0}" -f $fallbackFile)

            # Best-effort live restore attempt for logs where log file path can be resolved.
            $liveRestoreSuccess = $false
            try {
                $logConfig = Get-WinEvent -ListLog $entry.LogName -ErrorAction Stop
                $logFilePath = $logConfig.LogFilePath

                if ($logFilePath -and (Test-Path -Path (Split-Path -Path $logFilePath -Parent))) {
                    $candidateRestore = "{0}.restore-candidate" -f $logFilePath
                    Copy-Item -Path $entry.ArchivePath -Destination $candidateRestore -Force -ErrorAction Stop
                    $liveRestoreSuccess = $true
                    $summary.LiveRestoreSucceeded++
                    Write-Log -Level 'INFO' -Message ("Best-effort live restore candidate placed at: {0}" -f $candidateRestore)
                }
                else {
                    Write-Log -Level 'WARN' -Message ("Live restore path unavailable for log: {0}" -f $entry.LogName)
                }
            }
            catch {
                Write-Log -Level 'WARN' -Message ("Live restore attempt failed for {0}: {1}" -f $entry.LogName, $_.Exception.Message)
            }

            $summary.RollbackHandled++

            # Update manifest entry status in-memory and write back at end.
            $entry.RollbackStatus = if ($liveRestoreSuccess) { 'Handled-LiveCandidateCreated' } else { 'Handled-FallbackCopyOnly' }
            $entry.RollbackHandledAt = (Get-Date).ToString('o')
            $updatedManifestLines += ($entry | ConvertTo-Json -Compress)
        }
        catch {
            $summary.RollbackErrors++
            Write-Log -Level 'ERROR' -Message ("Rollback entry #{0} failed: {1}" -f $summary.EntriesRead, $_.Exception.Message)

            # Preserve the original manifest line if processing failed.
            $updatedManifestLines += $line
        }
    }

    # Re-write manifest with updated rollback statuses for idempotent repeat rollback runs.
    try {
        Set-Content -Path $selectedManifest -Value $updatedManifestLines -Force
        Write-Log -Level 'INFO' -Message 'Manifest statuses updated after rollback handling.'
    }
    catch {
        $summary.RollbackErrors++
        Write-Log -Level 'ERROR' -Message ("Failed to update manifest rollback statuses: {0}" -f $_.Exception.Message)
    }

    Write-Log -Level 'INFO' -Message 'Rollback mode completed.'
    return [PSCustomObject]$summary
}

# -----------------------------------------------------------------------------
# Section: Main execution and final summary
# What this does:
# - Initializes folders.
# - Routes to cleanup or rollback.
# - Prints a final summary and log file location.
# -----------------------------------------------------------------------------
try {
    # Ensure artifact directories exist before any operation.
    foreach ($dir in @($artifactRoot, $logDir, $archiveDir, $manifestDir, $rollbackDir)) {
        try {
            Ensure-Directory -Path $dir
        }
        catch {
            throw ("Startup folder initialization failed for {0}. Error: {1}" -f $dir, $_.Exception.Message)
        }
    }

    Write-Log -Level 'INFO' -Message ("Script started on host '{0}' by user '{1}'." -f $env:COMPUTERNAME, $env:USERNAME)
    Write-Log -Level 'INFO' -Message ("Parameters: OlderThanDays={0}; DryRun={1}; Rollback={2}; Pattern={3}; RunId={4}" -f $OlderThanDays, [bool]$DryRun, [bool]$Rollback, $LogNamePattern, $RunId)

    if ($Rollback) {
        try {
            $result = Invoke-EventLogRollback -InputManifestPath $ManifestPath
        }
        catch {
            throw ("Rollback execution failed. Error: {0}" -f $_.Exception.Message)
        }
    }
    else {
        try {
            $result = Invoke-EventLogCleanup -Days $OlderThanDays -IsDryRun:$DryRun -Pattern $LogNamePattern -CleanupRunId $RunId
        }
        catch {
            throw ("Cleanup execution failed. Error: {0}" -f $_.Exception.Message)
        }
    }

    Write-Host "`n================ EVENT LOG CLEANUP SUMMARY ================"
    $result | Format-List | Out-String | Write-Host
    Write-Host "Log file: $logFile"
    Write-Host "===========================================================`n"

    Write-Log -Level 'INFO' -Message 'Script finished successfully.'
}
catch {
    Write-Log -Level 'ERROR' -Message ("Fatal error: {0}" -f $_.Exception.Message)
    Write-Host "`nScript failed. Check log: $logFile"
    exit 1
}
