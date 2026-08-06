<#
.SYNOPSIS
    Endpoint health snapshot — reports key system metrics to the console.

.DESCRIPTION
    Collects and displays:
      - Computer name and total physical RAM
      - Free space on the C: drive
      - Top 5 processes by memory usage (Working Set)
      - Recent System event log errors (last 10 events, errors only)
      - Count of local user profiles unused for more than 90 days

    No changes are made to the system. This script is read-only.

.AUTHOR
    <YourName>

.HOW TO RUN
    Open PowerShell as Administrator and run:
        .\inherited.ps1

    Administrator rights are required to read all user profiles and event logs.

.NOTES
    Tested on: Windows 10 / Windows 11
    PowerShell version required: 5.1 or later
#>

# Query hardware and system info for this computer (hostname, RAM, domain, etc.)
$computerSystem = Get-CimInstance Win32_ComputerSystem

# Get the amount of free space on the C: drive, in bytes
$driveFreeByes = Get-PSDrive C | Select-Object -ExpandProperty Free

# Get all running processes, sorted by memory use (largest first), keep top 5
$topMemoryProcesses = Get-Process | Sort-Object WS -Descending | Select-Object -First 5

# Read the last 10 System event log entries and keep only errors (Level 2 = Error)
$systemErrors = Get-WinEvent -LogName System -MaxEvents 10 | Where-Object { $_.Level -eq 2 }

# Get all local user profiles, excluding built-in/special accounts, unused for 90+ days
$staleUserProfiles = Get-CimInstance Win32_UserProfile | Where-Object {
    -not $_.Special -and $_.LastUseTime -lt (Get-Date).AddDays(-90)
}

# Print the computer name and total physical RAM (in bytes)
Write-Host $computerSystem.Name $computerSystem.TotalPhysicalMemory

# Convert free disk space from bytes to GB (2 decimal places) and print it
Write-Host ([math]::Round($driveFreeByes / 1GB, 2)) 'GB free'

# Print the name and Working Set memory (bytes) for each of the top 5 processes
$topMemoryProcesses | ForEach-Object { Write-Host $_.Name $_.WS }

# Print the timestamp and message for each System log error found
$systemErrors | ForEach-Object { Write-Host $_.TimeCreated $_.Message }

# If any stale profiles were found, print how many
if ($staleUserProfiles.Count -gt 0) { Write-Host 'Stale profiles:' $staleUserProfiles.Count }
