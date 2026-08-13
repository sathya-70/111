<#
.SYNOPSIS
Audits and disables Windows startup programs safely.

.DESCRIPTION
- Dry-run mode lists startup programs from registry Run keys and Startup folders.
- Disable mode takes a program name and disables matching startup entries.
- Registry changes are backed up to a JSONL audit file before modification.

.NOTES
PowerShell 5.1 compatible.
#>

[CmdletBinding()]
param(
    # Lists startup programs only. No changes are made.
    [Parameter(Mandatory = $false)]
    [switch]$DryRun,

    # Disables matching startup programs by name.
    [Parameter(Mandatory = $false)]
    [switch]$Disable,

    # Name of the startup program to disable (case-insensitive exact match).
    [Parameter(Mandatory = $false)]
    [string]$ProgramName
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
$artifactRoot = Join-Path -Path $scriptRoot -ChildPath 'startup-auditor-artifacts'
if (-not (Test-Path -Path $artifactRoot)) {
    New-Item -Path $artifactRoot -ItemType Directory -Force | Out-Null
}
$backupFile = Join-Path -Path $artifactRoot -ChildPath ("disabled-startup-backup_{0}.jsonl" -f (Get-Date -Format 'yyyyMMdd_HHmmss'))

function Get-StartupPrograms {
    [CmdletBinding()]
    param()

    $items = New-Object System.Collections.Generic.List[object]

    $registryTargets = @(
        @{ Scope = 'CurrentUser'; Hive = 'HKCU'; KeyPath = 'Software\Microsoft\Windows\CurrentVersion\Run' },
        @{ Scope = 'CurrentUser'; Hive = 'HKCU'; KeyPath = 'Software\Microsoft\Windows\CurrentVersion\RunOnce' },
        @{ Scope = 'LocalMachine'; Hive = 'HKLM'; KeyPath = 'Software\Microsoft\Windows\CurrentVersion\Run' },
        @{ Scope = 'LocalMachine'; Hive = 'HKLM'; KeyPath = 'Software\Microsoft\Windows\CurrentVersion\RunOnce' },
        @{ Scope = 'LocalMachine32'; Hive = 'HKLM'; KeyPath = 'Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Run' }
    )

    foreach ($target in $registryTargets) {
        $psPath = "Registry::{0}\{1}" -f $target.Hive, $target.KeyPath
        if (-not (Test-Path -Path $psPath)) {
            continue
        }

        try {
            $keyItem = Get-Item -Path $psPath -ErrorAction Stop
            foreach ($valueName in $keyItem.GetValueNames()) {
                $command = $keyItem.GetValue($valueName)
                $items.Add([PSCustomObject]@{
                    Name       = $valueName
                    Command    = [string]$command
                    Location   = 'Registry'
                    Scope      = $target.Scope
                    SourcePath = $psPath
                    Type       = 'RegistryValue'
                })
            }
        }
        catch {
            Write-Warning ("Failed to read startup registry key {0}: {1}" -f $psPath, $_.Exception.Message)
        }
    }

    $startupFolders = @(
        @{ Scope = 'CurrentUser'; Path = [Environment]::GetFolderPath('Startup') },
        @{ Scope = 'AllUsers'; Path = [Environment]::GetFolderPath('CommonStartup') }
    )

    foreach ($folder in $startupFolders) {
        if ([string]::IsNullOrWhiteSpace($folder.Path) -or -not (Test-Path -Path $folder.Path)) {
            continue
        }

        try {
            Get-ChildItem -Path $folder.Path -File -Force -ErrorAction Stop | ForEach-Object {
                $items.Add([PSCustomObject]@{
                    Name       = $_.BaseName
                    Command    = $_.FullName
                    Location   = 'StartupFolder'
                    Scope      = $folder.Scope
                    SourcePath = $_.FullName
                    Type       = 'File'
                })
            }
        }
        catch {
            Write-Warning ("Failed to read startup folder {0}: {1}" -f $folder.Path, $_.Exception.Message)
        }
    }

    return $items
}

function Disable-StartupProgram {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    $allPrograms = Get-StartupPrograms
    $matches = $allPrograms | Where-Object { $_.Name -ieq $Name }

    if (-not $matches) {
        Write-Error ("No startup program found with name: {0}" -f $Name)
        return
    }

    $disabledCount = 0

    foreach ($entry in $matches) {
        try {
            if ($entry.Type -eq 'RegistryValue') {
                $currentValue = (Get-Item -Path $entry.SourcePath).GetValue($entry.Name)

                $backupRecord = [PSCustomObject]@{
                    Timestamp  = (Get-Date).ToString('o')
                    Action     = 'DisableRegistryStartup'
                    Name       = $entry.Name
                    Command    = [string]$currentValue
                    Scope      = $entry.Scope
                    SourcePath = $entry.SourcePath
                }
                Add-Content -Path $backupFile -Value ($backupRecord | ConvertTo-Json -Compress)

                Remove-ItemProperty -Path $entry.SourcePath -Name $entry.Name -ErrorAction Stop
                Write-Host ("Disabled registry startup: {0} ({1})" -f $entry.Name, $entry.Scope)
                $disabledCount++
                continue
            }

            if ($entry.Type -eq 'File') {
                $disabledPath = "{0}.disabled" -f $entry.SourcePath
                if (Test-Path -Path $disabledPath) {
                    Write-Warning ("Startup file already disabled: {0}" -f $disabledPath)
                    continue
                }

                Rename-Item -Path $entry.SourcePath -NewName ([System.IO.Path]::GetFileName($disabledPath)) -ErrorAction Stop
                Write-Host ("Disabled startup file: {0}" -f $entry.SourcePath)
                $disabledCount++
                continue
            }
        }
        catch {
            Write-Warning ("Failed to disable startup entry {0}: {1}" -f $entry.Name, $_.Exception.Message)
        }
    }

    Write-Host ("Disable completed. Entries disabled: {0}" -f $disabledCount)
    Write-Host ("Backup log: {0}" -f $backupFile)
}

if ($Disable -and [string]::IsNullOrWhiteSpace($ProgramName)) {
    throw 'ProgramName is required when using -Disable.'
}

if ($Disable) {
    Disable-StartupProgram -Name $ProgramName
    return
}

# Default behavior is listing (same as explicit -DryRun for this script).
$startupPrograms = Get-StartupPrograms | Sort-Object Location, Scope, Name

if (-not $startupPrograms) {
    Write-Host 'No startup programs found.'
    return
}

$startupPrograms |
    Select-Object Name, Location, Scope, Command |
    Format-Table -AutoSize

Write-Host ("Total startup entries found: {0}" -f ($startupPrograms | Measure-Object).Count)
