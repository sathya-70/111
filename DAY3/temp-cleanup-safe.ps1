<#
.SYNOPSIS
Safely cleans temp files on Windows endpoints with dry-run, logging, and rollback support.

.DESCRIPTION
Designed for PowerShell 5.1 and endpoint-safe operation.
- Targets files in temp paths older than a configurable age.
- Supports dry-run mode that prints files that would be removed.
- Handles errors per file and continues processing.
- Skips locked/in-use files and logs the skip.
- Logs all actions to a timestamped log file.
- Produces a summary report at the end.
- Implements rollback by moving files to a quarantine store with a manifest.
- Idempotent behavior for both cleanup and rollback operations.

.NOTES
Default mode is cleanup. Use -Rollback to restore files from a manifest.
#>

[CmdletBinding()]
param(
    # Paths to scan for temp files. Defaults to common endpoint temp locations.
    [Parameter(Mandatory = $false)]
    [string[]]$TargetPaths = @(
        $env:TEMP,
        (Join-Path -Path $env:WINDIR -ChildPath 'Temp')
    ),

    # Only process files with LastWriteTime older than this many days.
    [Parameter(Mandatory = $false)]
    [ValidateRange(0, 3650)]
    [int]$OlderThanDays = 0,

    # Dry-run mode: list files that would be cleaned, without moving/deleting anything.
    [Parameter(Mandatory = $false)]
    [switch]$DryRun,

    # Rollback mode: restore files from a manifest instead of performing cleanup.
        [Parameter(Mandatory = $false)]
        [Alias('EnableRollback')]
    [switch]$Rollback,

    # Optional manifest to use for rollback. If omitted in rollback mode, latest manifest is used.
    [Parameter(Mandatory = $false)]
    [string]$ManifestPath,

    # Optional run identifier used for folder/log naming in cleanup mode.
    [Parameter(Mandatory = $false)]
    [string]$RunId = (Get-Date -Format 'yyyyMMdd_HHmmss')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# -----------------------------------------------------------------------------
# Section: Script working directories
# What this does:
# - Creates local folders for logs, manifests, and quarantine storage.
# - Keeps script artifacts next to the script for easier support/operations.
# -----------------------------------------------------------------------------
$scriptRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
$artifactRoot = Join-Path -Path $scriptRoot -ChildPath 'temp-cleanup-artifacts'
$logDir = Join-Path -Path $artifactRoot -ChildPath 'logs'
$manifestDir = Join-Path -Path $artifactRoot -ChildPath 'manifests'
$quarantineRoot = Join-Path -Path $artifactRoot -ChildPath 'quarantine'

foreach ($dir in @($artifactRoot, $logDir, $manifestDir, $quarantineRoot)) {
    if (-not (Test-Path -Path $dir)) {
        New-Item -Path $dir -ItemType Directory -Force | Out-Null
    }
}

# -----------------------------------------------------------------------------
# Section: Logging helpers
# What this does:
# - Writes timestamped entries to both console and a log file.
# - Ensures every action is traceable for auditing and troubleshooting.
# -----------------------------------------------------------------------------
$logFile = Join-Path -Path $logDir -ChildPath ("temp-cleanup_{0}.log" -f (Get-Date -Format 'yyyyMMdd_HHmmss'))

function Write-Log {
    param(
        [Parameter(Mandatory = $true)][string]$Level,
        [Parameter(Mandatory = $true)][string]$Message
    )

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $entry = "[{0}] [{1}] {2}" -f $timestamp, $Level.ToUpperInvariant(), $Message
    Add-Content -Path $logFile -Value $entry
    Write-Host $entry
}

# -----------------------------------------------------------------------------
# Section: File lock detection helper
# What this does:
# - Attempts exclusive file access.
# - Returns $true when file appears locked/in use by another process.
# -----------------------------------------------------------------------------
function Test-FileLocked {
    param(
        [Parameter(Mandatory = $true)][string]$Path
    )

    try {
        $stream = [System.IO.File]::Open($Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)
        if ($stream) {
            $stream.Close()
            $stream.Dispose()
        }
        return $false
    }
    catch [System.IO.IOException] {
        return $true
    }
    catch {
        # If access cannot be confirmed for another reason, treat as locked/safe-to-skip.
        return $true
    }
}

# -----------------------------------------------------------------------------
# Section: Cleanup operation
# What this does:
# - Scans target folders for files older than cutoff.
# - In dry-run, reports files that would be cleaned.
# - In live mode, moves each eligible file to quarantine and writes manifest entries.
# - Uses per-file try/catch and continues on errors.
# -----------------------------------------------------------------------------
function Invoke-Cleanup {
    param(
        [Parameter(Mandatory = $true)][string[]]$Paths,
        [Parameter(Mandatory = $true)][int]$Days,
        [Parameter(Mandatory = $true)][switch]$IsDryRun,
        [Parameter(Mandatory = $true)][string]$CleanupRunId
    )

    $cutoff = (Get-Date).AddDays(-1 * $Days)
    $runQuarantine = Join-Path -Path $quarantineRoot -ChildPath $CleanupRunId
    $runManifest = Join-Path -Path $manifestDir -ChildPath ("manifest_{0}.jsonl" -f $CleanupRunId)

    if (-not $IsDryRun) {
        if (-not (Test-Path -Path $runQuarantine)) {
            New-Item -Path $runQuarantine -ItemType Directory -Force | Out-Null
        }
        if (-not (Test-Path -Path $runManifest)) {
            New-Item -Path $runManifest -ItemType File -Force | Out-Null
        }
    }

    $summary = [ordered]@{
        ScannedPaths                 = 0
        EligibleFiles                = 0
        DryRunListed                 = 0
        MovedToQuarantine            = 0
        SkippedLockedOrInUse         = 0
        SkippedNotFound              = 0
        PerFileErrors                = 0
        PathEnumerationErrors        = 0
    }

    Write-Log -Level 'INFO' -Message ("Cleanup mode started. DryRun={0}; OlderThanDays={1}; Cutoff={2}" -f [bool]$IsDryRun, $Days, $cutoff)

    foreach ($path in $Paths) {
        $summary.ScannedPaths++

        if ([string]::IsNullOrWhiteSpace($path)) {
            Write-Log -Level 'WARN' -Message 'Encountered an empty target path entry. Skipping.'
            continue
        }

        if (-not (Test-Path -Path $path)) {
            Write-Log -Level 'WARN' -Message ("Target path not found. Skipping: {0}" -f $path)
            continue
        }

        Write-Log -Level 'INFO' -Message ("Scanning path: {0}" -f $path)

        try {
            $files = Get-ChildItem -Path $path -File -Recurse -Force -ErrorAction Stop |
                Where-Object { $_.LastWriteTime -lt $cutoff }
        }
        catch {
            $summary.PathEnumerationErrors++
            Write-Log -Level 'ERROR' -Message ("Failed to enumerate path: {0}. Error: {1}" -f $path, $_.Exception.Message)
            continue
        }

        foreach ($file in $files) {
            $summary.EligibleFiles++

            if ($IsDryRun) {
                $summary.DryRunListed++
                Write-Log -Level 'INFO' -Message ("DRYRUN would clean: {0}" -f $file.FullName)
                continue
            }

            try {
                if (-not (Test-Path -Path $file.FullName)) {
                    $summary.SkippedNotFound++
                    Write-Log -Level 'WARN' -Message ("File not found at action time (already processed/removed). Skipping: {0}" -f $file.FullName)
                    continue
                }

                if (Test-FileLocked -Path $file.FullName) {
                    $summary.SkippedLockedOrInUse++
                    Write-Log -Level 'WARN' -Message ("Skipping locked/in-use file: {0}" -f $file.FullName)
                    continue
                }

                $itemId = [guid]::NewGuid().ToString()
                $stagedName = "{0}_{1}" -f $itemId, $file.Name
                $stagedPath = Join-Path -Path $runQuarantine -ChildPath $stagedName

                Move-Item -Path $file.FullName -Destination $stagedPath -Force -ErrorAction Stop

                $manifestEntry = [PSCustomObject]@{
                    RunId          = $CleanupRunId
                    OriginalPath   = $file.FullName
                    StagedPath     = $stagedPath
                    FileName       = $file.Name
                    LengthBytes    = $file.Length
                    LastWriteTime  = $file.LastWriteTime.ToString('o')
                    MovedAt        = (Get-Date).ToString('o')
                }

                Add-Content -Path $runManifest -Value ($manifestEntry | ConvertTo-Json -Compress)
                $summary.MovedToQuarantine++
                Write-Log -Level 'INFO' -Message ("Moved to quarantine: {0} => {1}" -f $file.FullName, $stagedPath)
            }
            catch [System.IO.IOException] {
                $summary.SkippedLockedOrInUse++
                Write-Log -Level 'WARN' -Message ("I/O issue (likely locked/in-use) for file: {0}. Error: {1}" -f $file.FullName, $_.Exception.Message)
            }
            catch {
                $summary.PerFileErrors++
                Write-Log -Level 'ERROR' -Message ("Per-file error for {0}: {1}" -f $file.FullName, $_.Exception.Message)
            }
        }
    }

    Write-Log -Level 'INFO' -Message 'Cleanup mode completed.'

    [PSCustomObject]@{
        Mode                        = if ($IsDryRun) { 'DryRun' } else { 'Cleanup' }
        RunId                       = $CleanupRunId
        CutoffDate                  = $cutoff
        ManifestPath                = if ($IsDryRun) { '<none>' } else { $runManifest }
        QuarantinePath              = if ($IsDryRun) { '<none>' } else { $runQuarantine }
        LogFile                     = $logFile
        ScannedPaths                = $summary.ScannedPaths
        EligibleFiles               = $summary.EligibleFiles
        DryRunListed                = $summary.DryRunListed
        MovedToQuarantine           = $summary.MovedToQuarantine
        SkippedLockedOrInUse        = $summary.SkippedLockedOrInUse
        SkippedNotFound             = $summary.SkippedNotFound
        PerFileErrors               = $summary.PerFileErrors
        PathEnumerationErrors       = $summary.PathEnumerationErrors
    }
}

# -----------------------------------------------------------------------------
# Section: Rollback operation
# What this does:
# - Restores files from a manifest generated by cleanup mode.
# - Uses per-file try/catch and continues on errors.
# - Idempotent: skips already-restored items safely.
# -----------------------------------------------------------------------------
function Invoke-Rollback {
    param(
        [Parameter(Mandatory = $false)][string]$InputManifestPath
    )

    $selectedManifest = $null

    if ($InputManifestPath) {
        $selectedManifest = $InputManifestPath
    }
    else {
        $selectedManifest = Get-ChildItem -Path $manifestDir -File -Filter 'manifest_*.jsonl' |
            Sort-Object -Property LastWriteTime -Descending |
            Select-Object -First 1 -ExpandProperty FullName
    }

    if (-not $selectedManifest) {
        throw 'No manifest found for rollback. Provide -ManifestPath or run cleanup mode first.'
    }

    if (-not (Test-Path -Path $selectedManifest)) {
        throw ("Manifest path does not exist: {0}" -f $selectedManifest)
    }

    Write-Log -Level 'INFO' -Message ("Rollback mode started using manifest: {0}" -f $selectedManifest)

    $summary = [ordered]@{
        ManifestEntriesRead         = 0
        Restored                    = 0
        SkippedAlreadyRestored      = 0
        SkippedDestinationExists    = 0
        RollbackErrors              = 0
    }

    $lines = Get-Content -Path $selectedManifest -ErrorAction Stop

    foreach ($line in $lines) {
        if ([string]::IsNullOrWhiteSpace($line)) {
            continue
        }

        $summary.ManifestEntriesRead++

        try {
            $entry = $line | ConvertFrom-Json -ErrorAction Stop

            if (-not (Test-Path -Path $entry.StagedPath)) {
                $summary.SkippedAlreadyRestored++
                Write-Log -Level 'WARN' -Message ("Staged file not found (already restored or removed). Skipping: {0}" -f $entry.StagedPath)
                continue
            }

            if (Test-Path -Path $entry.OriginalPath) {
                $summary.SkippedDestinationExists++
                Write-Log -Level 'WARN' -Message ("Destination already exists. Skipping restore to avoid overwrite: {0}" -f $entry.OriginalPath)
                continue
            }

            $originalDir = Split-Path -Path $entry.OriginalPath -Parent
            if (-not (Test-Path -Path $originalDir)) {
                New-Item -Path $originalDir -ItemType Directory -Force | Out-Null
            }

            Move-Item -Path $entry.StagedPath -Destination $entry.OriginalPath -Force -ErrorAction Stop
            $summary.Restored++
            Write-Log -Level 'INFO' -Message ("Restored file: {0}" -f $entry.OriginalPath)
        }
        catch {
            $summary.RollbackErrors++
            Write-Log -Level 'ERROR' -Message ("Rollback error for manifest entry #{0}: {1}" -f $summary.ManifestEntriesRead, $_.Exception.Message)
        }
    }

    Write-Log -Level 'INFO' -Message 'Rollback mode completed.'

    [PSCustomObject]@{
        Mode                        = 'Rollback'
        ManifestPath                = $selectedManifest
        LogFile                     = $logFile
        ManifestEntriesRead         = $summary.ManifestEntriesRead
        Restored                    = $summary.Restored
        SkippedAlreadyRestored      = $summary.SkippedAlreadyRestored
        SkippedDestinationExists    = $summary.SkippedDestinationExists
        RollbackErrors              = $summary.RollbackErrors
    }
}

# -----------------------------------------------------------------------------
# Section: Main execution flow
# What this does:
# - Routes to cleanup or rollback mode.
# - Prints final summary in all cases.
# -----------------------------------------------------------------------------
try {
    Write-Log -Level 'INFO' -Message ("Script started on host {0} by user {1}" -f $env:COMPUTERNAME, $env:USERNAME)

    if ($Rollback) {
        $result = Invoke-Rollback -InputManifestPath $ManifestPath
    }
    else {
        $result = Invoke-Cleanup -Paths $TargetPaths -Days $OlderThanDays -IsDryRun:$DryRun -CleanupRunId $RunId
    }

    Write-Host "`n================ SUMMARY ================"
    $result | Format-List | Out-String | Write-Host
    Write-Host "Log file: $logFile"
    Write-Host "=========================================`n"

    Write-Log -Level 'INFO' -Message 'Script finished successfully.'
}
catch {
    Write-Log -Level 'ERROR' -Message ("Fatal error: {0}" -f $_.Exception.Message)
    Write-Host "`nScript failed. Check log: $logFile"
    exit 1
}
