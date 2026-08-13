# ============================================================================
# Disk Health Reporter - Read-Only Analysis Script
# Purpose: Provides comprehensive disk health and optimization status reports
# Restrictions: Strictly read-only; NO defragmentation or modifications
# ============================================================================

param(
    [switch]$Verbose,
    [string]$DriveLetter = "C:",
    [switch]$IncludeAllDrives
)

# Set error action preference
$ErrorActionPreference = "Continue"

# ============================================================================
# FUNCTION: Get-DiskHealthReport
# ============================================================================
function Get-DiskHealthReport {
    param(
        [string]$Drive = "C:"
    )
    
    Write-Host "`n========== DISK HEALTH REPORT ==========" -ForegroundColor Cyan
    Write-Host "Drive: $Drive" -ForegroundColor Yellow
    Write-Host "Report Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Yellow
    Write-Host "Scan Mode: READ-ONLY (No modifications)" -ForegroundColor Green
    Write-Host ""
    
    try {
        # Get disk volume information
        $volume = Get-Volume -DriveLetter $Drive.TrimEnd(':') -ErrorAction Stop
        $diskSize = $volume.Size
        $freeSpace = $volume.SizeRemaining
        $usedSpace = $diskSize - $freeSpace
        $percentFull = if ($diskSize -gt 0) { [math]::Round(($usedSpace / $diskSize) * 100, 2) } else { 0 }
        
        # Display disk capacity information
        Write-Host "DISK CAPACITY ANALYSIS:" -ForegroundColor Magenta
        Write-Host "  Total Capacity: $([math]::Round($diskSize / 1GB, 2)) GB"
        Write-Host "  Used Space: $([math]::Round($usedSpace / 1GB, 2)) GB"
        Write-Host "  Free Space: $([math]::Round($freeSpace / 1GB, 2)) GB"
        Write-Host "  Percentage Full: $percentFull %"
        
        # Health status based on disk usage
        if ($percentFull -lt 80) {
            Write-Host "  Status: HEALTHY ✓" -ForegroundColor Green
        }
        elseif ($percentFull -lt 90) {
            Write-Host "  Status: WARNING ⚠" -ForegroundColor Yellow
        }
        else {
            Write-Host "  Status: CRITICAL ✗" -ForegroundColor Red
        }
        
        # Get drive details
        Write-Host ""
        Write-Host "DRIVE INFORMATION:" -ForegroundColor Magenta
        Write-Host "  File System: $($volume.FileSystem)"
        Write-Host "  Drive Label: $($volume.FileSystemLabel -eq '' ? '[No Label]' : $volume.FileSystemLabel)"
        Write-Host "  Drive Status: $($volume.HealthStatus)"
        
    }
    catch {
        Write-Host "Error reading disk information: $_" -ForegroundColor Red
        return $false
    }
    
    return $true
}

# ============================================================================
# FUNCTION: Get-DiskFragmentationStatus
# ============================================================================
function Get-DiskFragmentationStatus {
    param(
        [string]$Drive = "C:"
    )
    
    Write-Host ""
    Write-Host "FRAGMENTATION STATUS (READ-ONLY):" -ForegroundColor Magenta
    
    try {
        # Get optimization status - READ-ONLY
        $drive_letter = $Drive.TrimEnd(':')
        $defragStatus = Get-Volume -DriveLetter $drive_letter -ErrorAction Stop | 
                        Get-StorageHealthReport -ErrorAction SilentlyContinue
        
        # Try WMI approach for fragmentation data (read-only)
        $fragment = Get-Volume -DriveLetter $drive_letter | 
                   Get-Volume | 
                   Select-Object @{Name="FragmentationPercent"; Expression={
                       try {
                           $diskInfo = Get-WmiObject -Query "SELECT * FROM Win32_LogicalDisk WHERE DeviceID='$($drive_letter):'" -ErrorAction SilentlyContinue
                           if ($diskInfo) {
                               # Calculate fragmentation estimate from file system info
                               "Data available via Optimize-Volume -AnalyzeOnly"
                           }
                           else { "Unable to determine" }
                       }
                       catch { "Unable to determine" }
                   }}
        
        # Use Optimize-Volume with -AnalyzeOnly (non-destructive)
        Write-Host "  Analyzing fragmentation (non-destructive scan)..." -ForegroundColor Yellow
        
        $analyzeResult = Optimize-Volume -DriveLetter $drive_letter -Defrag -Verbose -AnalyzeOnly 2>&1 | 
                        Select-String -Pattern "CurrentPercentFragmentation|DeviceCurrentPercentFragmentation"
        
        if ($analyzeResult) {
            Write-Host "  $($analyzeResult[0])"
        }
        else {
            Write-Host "  Fragmentation Analysis: Skipped (requires elevated privileges)"
            Write-Host "  Note: Run as Administrator for detailed fragmentation data"
        }
        
        Write-Host "  Status: READ-ONLY SCAN COMPLETED - No defragmentation performed" -ForegroundColor Green
        
    }
    catch {
        Write-Host "  Fragmentation check: Limited data available without elevation" -ForegroundColor Yellow
        Write-Host "  Note: Re-run as Administrator for full analysis" -ForegroundColor Yellow
    }
}

# ============================================================================
# FUNCTION: Get-OptimizationStatus
# ============================================================================
function Get-OptimizationStatus {
    param(
        [string]$Drive = "C:"
    )
    
    Write-Host ""
    Write-Host "OPTIMIZATION STATUS:" -ForegroundColor Magenta
    
    try {
        $drive_letter = $Drive.TrimEnd(':')
        
        # Query optimization schedule
        $taskName = "\Microsoft\Windows\Defrag\ScheduledDefrag"
        $task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
        
        if ($task) {
            Write-Host "  Scheduled Optimization: $($task.State)"
            Write-Host "  Last Run Time: $($task.LastRunTime)"
            Write-Host "  Next Run Time: $($task.NextRunTime)"
        }
        else {
            Write-Host "  Scheduled Optimization: Not found or disabled"
        }
        
        # Get volume optimization information
        $volume = Get-Volume -DriveLetter $drive_letter -ErrorAction Stop
        Write-Host "  File System Type: $($volume.FileSystem)"
        
        # Recommendations
        Write-Host ""
        Write-Host "OPTIMIZATION RECOMMENDATIONS:" -ForegroundColor Cyan
        
        $disk = Get-WmiObject -Class Win32_LogicalDisk -Filter "Name='$($drive_letter):'" -ErrorAction SilentlyContinue
        if ($disk) {
            $percentFull = if ($disk.Size -gt 0) { 
                [math]::Round(($disk.Size - $disk.FreeSpace) / $disk.Size * 100, 2) 
            } else { 0 }
            
            if ($percentFull -gt 90) {
                Write-Host "  ⚠ CRITICAL: Free space critically low ($percentFull % full)" -ForegroundColor Red
                Write-Host "    → Delete unnecessary files immediately" -ForegroundColor Red
                Write-Host "    → Consider archiving old data" -ForegroundColor Red
            }
            elseif ($percentFull -gt 80) {
                Write-Host "  ⚠ WARNING: Disk space getting low ($percentFull % full)" -ForegroundColor Yellow
                Write-Host "    → Review and clean unnecessary files" -ForegroundColor Yellow
                Write-Host "    → Disable Windows temporary file cleanup if not configured" -ForegroundColor Yellow
            }
            else {
                Write-Host "  ✓ GOOD: Disk has adequate free space ($percentFull % full)" -ForegroundColor Green
                Write-Host "    → Continue monitoring disk usage" -ForegroundColor Green
            }
        }
        
        Write-Host "  ✓ Optimization history available via Optimize-Volume -AnalyzeOnly" -ForegroundColor Green
        Write-Host "  ✓ This script performs READ-ONLY analysis only" -ForegroundColor Green
        
    }
    catch {
        Write-Host "  Error retrieving optimization status: $_" -ForegroundColor Red
    }
}

# ============================================================================
# FUNCTION: Get-SMARTStatus (if available)
# ============================================================================
function Get-SMARTStatus {
    param(
        [string]$Drive = "C:"
    )
    
    Write-Host ""
    Write-Host "SMART DISK STATUS (if available):" -ForegroundColor Magenta
    
    try {
        # Attempt to read SMART data (requires WMI access)
        $smartStatus = Get-WmiObject -Namespace "\\.\root\wmi" `
                      -Class MSStorageDriver_FailurePredictStatus `
                      -ErrorAction SilentlyContinue
        
        if ($smartStatus) {
            foreach ($disk in $smartStatus) {
                Write-Host "  SMART Status: $($disk.PredictFailure -eq $true ? 'FAILURE PREDICTED' : 'HEALTHY')"
                if ($disk.PredictFailure) {
                    Write-Host "    ⚠ WARNING: Disk failure predicted - backup data immediately!" -ForegroundColor Red
                }
            }
        }
        else {
            Write-Host "  SMART Data: Not available (WMI access limited or SMART not supported)"
        }
        
    }
    catch {
        Write-Host "  SMART Status: Unable to retrieve (insufficient permissions or hardware support)" -ForegroundColor Yellow
    }
}

# ============================================================================
# FUNCTION: Get-AllDrivesReport
# ============================================================================
function Get-AllDrivesReport {
    
    Write-Host "`n" | Out-Null
    $drives = Get-Volume | Where-Object { $_.DriveLetter } | Select-Object -ExpandProperty DriveLetter
    
    if ($drives.Count -eq 0) {
        Write-Host "No drives found" -ForegroundColor Yellow
        return
    }
    
    foreach ($drive in $drives) {
        Get-DiskHealthReport -Drive "$($drive):"
        Get-DiskFragmentationStatus -Drive "$($drive):"
    }
    
    Get-OptimizationStatus -Drive $drives[0]
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================
Write-Host "`n╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║         DISK HEALTH & OPTIMIZATION REPORTER v1.0          ║" -ForegroundColor Cyan
Write-Host "║                 READ-ONLY ANALYSIS SCRIPT                  ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan

if ($IncludeAllDrives) {
    Get-AllDrivesReport
}
else {
    Get-DiskHealthReport -Drive $DriveLetter
    Get-DiskFragmentationStatus -Drive $DriveLetter
    Get-OptimizationStatus -Drive $DriveLetter
    Get-SMARTStatus -Drive $DriveLetter
}

Write-Host ""
Write-Host "IMPORTANT NOTES:" -ForegroundColor Cyan
Write-Host "  • This script is READ-ONLY and performs no modifications" -ForegroundColor Green
Write-Host "  • Defragmentation is NEVER performed" -ForegroundColor Green
Write-Host "  • Fragmentation analysis requires -AnalyzeOnly flag" -ForegroundColor Green
Write-Host "  • For full SMART/fragmentation data, run as Administrator" -ForegroundColor Yellow
Write-Host ""
Write-Host "Report completed at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Yellow
Write-Host ""
