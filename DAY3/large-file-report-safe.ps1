<#
.SYNOPSIS
Read-only large file reporting script for Windows endpoints.

.DESCRIPTION
Scans a target path recursively and reports files larger than a threshold.
This script is read-only: it does not modify, move, or delete any files.
Designed for PowerShell 5.1 compatibility.

.PARAMETER TargetPath
Root path to scan. Defaults to the current directory.

.PARAMETER ThresholdMB
File size threshold in MB. Files strictly larger than this value are reported.
Default is 100 MB.

.PARAMETER IncludeHidden
Includes hidden/system files when specified.

.EXAMPLE
.\large-file-report-safe.ps1

.EXAMPLE
.\large-file-report-safe.ps1 -TargetPath "C:\Users" -ThresholdMB 100

.EXAMPLE
.\large-file-report-safe.ps1 -TargetPath "C:\" -ThresholdMB 250 -IncludeHidden
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$TargetPath = (Get-Location).Path,

    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 1048576)]
    [int]$ThresholdMB = 100,

    [Parameter(Mandatory = $false)]
    [switch]$IncludeHidden
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

try {
    if (-not (Test-Path -Path $TargetPath)) {
        throw "TargetPath not found: $TargetPath"
    }

    $thresholdBytes = [int64]$ThresholdMB * 1MB

    $scanParams = @{
        Path        = $TargetPath
        File        = $true
        Recurse     = $true
        ErrorAction = 'SilentlyContinue'
    }

    if ($IncludeHidden) {
        $scanParams.Force = $true
    }

    $results = Get-ChildItem @scanParams |
        Where-Object { $_.Length -gt $thresholdBytes } |
        Select-Object @{ Name = 'Path'; Expression = { $_.FullName } }, @{ Name = 'SizeMB'; Expression = { [math]::Round(($_.Length / 1MB), 2) } }, @{ Name = 'SizeGB'; Expression = { [math]::Round(($_.Length / 1GB), 3) } }, LastWriteTime |
        Sort-Object -Property SizeMB -Descending

    Write-Host "Large file report (read-only)"
    Write-Host ("TargetPath : {0}" -f $TargetPath)
    Write-Host ("Threshold  : {0} MB" -f $ThresholdMB)
    Write-Host ("Found      : {0}" -f ($results | Measure-Object | Select-Object -ExpandProperty Count))
    Write-Host ""

    if (-not $results) {
        Write-Host "No files found above the threshold."
        return
    }

    $results | Format-Table -AutoSize
}
catch {
    Write-Error ("Failed to generate large file report. {0}" -f $_.Exception.Message)
    exit 1
}