<#
.SYNOPSIS
Read-only endpoint health report for DWP engineers (PowerShell 5.1).

.DESCRIPTION
Collects and displays:
- System uptime
- Free disk space
- Pending reboot status (registry checks)
- Top 5 processes by memory (Working Set)
- Top 5 processes by CPU
- Last 5 System log errors

This script is strictly read-only and does not change any system state.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Host "=================================================="
Write-Host "DWP Endpoint Health Report"
Write-Host "Host: $env:COMPUTERNAME"
Write-Host "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host "=================================================="

# -----------------------------------------------------------------------------
# Section: System uptime
# What this does:
# - Reads the operating system last boot time.
# - Calculates and displays total uptime in days/hours/minutes.
# Read-only: Yes (query only).
# ----------------------------------------------------------------------------
try {
    $os = Get-CimInstance -ClassName Win32_OperatingSystem
    $lastBoot = $os.LastBootUpTime
    $uptime = (Get-Date) - $lastBoot

    Write-Host "`n[System Uptime]"
    [PSCustomObject]@{
        LastBootTime = $lastBoot
        Uptime       = ('{0} days {1} hours {2} minutes' -f $uptime.Days, $uptime.Hours, $uptime.Minutes)
    } | Format-List
}
catch {
    Write-Warning "Failed to retrieve system uptime: $($_.Exception.Message)"
}

# -----------------------------------------------------------------------------
# Section: Free disk space
# What this does:
# - Reads logical disks with DriveType=3 (local fixed disks).
# - Displays total size, free space, and free percentage.
# Read-only: Yes (query only).
# ----------------------------------------------------------------------------
try {
    $disks = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3" |
        Select-Object DeviceID,
                      VolumeName,
                      @{Name='SizeGB';Expression={[math]::Round($_.Size / 1GB, 2)}},
                      @{Name='FreeGB';Expression={[math]::Round($_.FreeSpace / 1GB, 2)}},
                      @{Name='FreePercent';Expression={ if ($_.Size -gt 0) { [math]::Round(($_.FreeSpace / $_.Size) * 100, 2) } else { $null } }}

    Write-Host "`n[Free Disk Space]"
    if ($disks) {
        $disks | Sort-Object DeviceID | Format-Table -AutoSize
    }
    else {
        Write-Host "No local fixed disks found."
    }
}
catch {
    Write-Warning "Failed to retrieve disk information: $($_.Exception.Message)"
}

# -----------------------------------------------------------------------------
# Section: Pending reboot status (registry checks)
# What this does:
# - Checks common Windows registry indicators that suggest a pending reboot.
# - Reports whether any known indicator is present.
# Read-only: Yes (registry reads only).
# ----------------------------------------------------------------------------
try {
    # VERIFY BEFORE RUNNING: Confirm these registry paths match your DWP baseline and OS policy.
    $pendingRebootPaths = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending',
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired',
        'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager'
    )

    $pendingFlags = [System.Collections.Generic.List[string]]::new()

    if (Test-Path -Path $pendingRebootPaths[0]) {
        $pendingFlags.Add('Component Based Servicing: RebootPending exists')
    }

    if (Test-Path -Path $pendingRebootPaths[1]) {
        $pendingFlags.Add('WindowsUpdate: RebootRequired exists')
    }

    # VERIFY BEFORE RUNNING: PendingFileRenameOperations may not exist on all systems; this check is read-only.
    $sessionManagerValue = Get-ItemProperty -Path $pendingRebootPaths[2] -Name 'PendingFileRenameOperations' -ErrorAction SilentlyContinue
    if ($null -ne $sessionManagerValue) {
        $pendingFlags.Add('Session Manager: PendingFileRenameOperations is set')
    }

    Write-Host "`n[Pending Reboot Check]"
    if ($pendingFlags.Count -gt 0) {
        [PSCustomObject]@{
            PendingReboot = $true
            Indicators    = ($pendingFlags -join '; ')
        } | Format-List
    }
    else {
        [PSCustomObject]@{
            PendingReboot = $false
            Indicators    = 'No known pending reboot indicators found'
        } | Format-List
    }
}
catch {
    Write-Warning "Failed to check pending reboot status: $($_.Exception.Message)"
}

# Build a process-id to executable-path lookup once for later process tables.
# Read-only: Yes (query only).
$processPathMap = @{}
try {
    Get-CimInstance -ClassName Win32_Process -Property ProcessId, ExecutablePath |
        ForEach-Object {
            if ($_.ExecutablePath) {
                $processPathMap[[int]$_.ProcessId] = $_.ExecutablePath
            }
        }
}
catch {
    Write-Warning "Failed to build executable path lookup: $($_.Exception.Message)"
}

# -----------------------------------------------------------------------------
# Section: Top 5 processes by memory (Working Set)
# What this does:
# - Reads running processes.
# - Sorts by Working Set (current physical memory use) descending.
# - Displays top 5 consumers.
# Read-only: Yes (query only).
# ----------------------------------------------------------------------------
try {
    $topMemory = Get-Process |
        Sort-Object -Property WorkingSet64 -Descending |
        Select-Object -First 5 -Property Id,
                                       ProcessName,
                                       @{Name='ExecutableName';Expression={
                                           if ($_.Path) { Split-Path -Path $_.Path -Leaf }
                                           elseif ($processPathMap.ContainsKey([int]$_.Id)) { Split-Path -Path $processPathMap[[int]$_.Id] -Leaf }
                                           else { '<unknown>' }
                                       }},
                                       @{Name='ExecutablePath';Expression={
                                           if ($_.Path) { $_.Path }
                                           elseif ($processPathMap.ContainsKey([int]$_.Id)) { $processPathMap[[int]$_.Id] }
                                           else { '<access denied or unavailable>' }
                                       }},
                                       @{Name='WorkingSetMB';Expression={[math]::Round($_.WorkingSet64 / 1MB, 2)}},
                                       CPU

    Write-Host "`n[Top 5 Processes by Memory (Working Set)]"
    $topMemory | Format-Table -AutoSize
}
catch {
    Write-Warning "Failed to retrieve processes by memory: $($_.Exception.Message)"
}

# -----------------------------------------------------------------------------
# Section: Top 5 processes by CPU
# What this does:
# - Reads running processes.
# - Sorts by CPU property descending.
# - CPU is cumulative processor time in seconds since process start.
# - Displays top 5 consumers.
# Read-only: Yes (query only).
# ----------------------------------------------------------------------------
try {
    $topCpu = Get-Process |
        Sort-Object -Property CPU -Descending |
        Select-Object -First 5 -Property Id,
                                       ProcessName,
                                       @{Name='ExecutableName';Expression={
                                           if ($_.Path) { Split-Path -Path $_.Path -Leaf }
                                           elseif ($processPathMap.ContainsKey([int]$_.Id)) { Split-Path -Path $processPathMap[[int]$_.Id] -Leaf }
                                           else { '<unknown>' }
                                       }},
                                       @{Name='ExecutablePath';Expression={
                                           if ($_.Path) { $_.Path }
                                           elseif ($processPathMap.ContainsKey([int]$_.Id)) { $processPathMap[[int]$_.Id] }
                                           else { '<access denied or unavailable>' }
                                       }},
                                       @{Name='CPUSeconds';Expression={ if ($_.CPU) { [math]::Round($_.CPU, 2) } else { 0 } }},
                                       @{Name='WorkingSetMB';Expression={[math]::Round($_.WorkingSet64 / 1MB, 2)}}

    Write-Host "`n[Top 5 Processes by CPU]"
    $topCpu | Format-Table -AutoSize
}
catch {
    Write-Warning "Failed to retrieve processes by CPU: $($_.Exception.Message)"
}

# -----------------------------------------------------------------------------
# Section: Last 5 System log errors
# What this does:
# - Reads the Windows System event log.
# - Retrieves the most recent 5 error-level events.
# Read-only: Yes (event log reads only).
# ----------------------------------------------------------------------------
try {
    # VERIFY BEFORE RUNNING: Access to System event log may require elevated rights depending on endpoint policy.
    $systemErrors = Get-WinEvent -FilterHashtable @{ LogName = 'System'; Level = 2 } -MaxEvents 5 |
        Select-Object TimeCreated,
                      Id,
                      ProviderName,
                      LevelDisplayName,
                      Message

    Write-Host "`n[Last 5 System Log Errors]"
    if ($systemErrors) {
        $systemErrors | Format-Table -Wrap -AutoSize
    }
    else {
        Write-Host "No recent system errors found."
    }
}
catch {
    Write-Warning "Failed to retrieve System log errors: $($_.Exception.Message)"
}

Write-Host "`nReport complete. (Read-only checks only)"
