# Disk Health Reporter - Documentation

## Overview
The **Disk Health Reporter** is a read-only PowerShell script designed to provide comprehensive disk health and optimization status analysis without performing any modifications to disk data.

## Key Features

### 1. **Disk Health Reporting**
- Total disk capacity in GB
- Used and free space calculations
- Percentage of disk full
- Health status classification (HEALTHY/WARNING/CRITICAL)
- File system type and drive label
- Drive health status from Windows Volume API

### 2. **Optimization Status**
- Scheduled defragmentation status
- Last optimization run time
- Next scheduled optimization
- Disk usage recommendations
- Actionable guidance based on disk fullness

### 3. **Fragmentation Analysis**
- Non-destructive fragmentation scanning using `-AnalyzeOnly` flag
- Prevents any actual defragmentation
- Read-only analysis of disk layout

### 4. **SMART Disk Status**
- Attempts to retrieve S.M.A.R.T. status if available
- Warns of predicted disk failures
- Requires appropriate WMI permissions

### 5. **Multi-Drive Support**
- Single drive analysis (default: C:)
- All-drives report option with `-IncludeAllDrives` switch

## Usage

### Basic Usage (Single Drive - C:)
```powershell
.\disk-health-reporter.ps1
```

### Analyze Specific Drive
```powershell
.\disk-health-reporter.ps1 -DriveLetter "D:"
```

### Generate Report for All Drives
```powershell
.\disk-health-reporter.ps1 -IncludeAllDrives
```

### With Verbose Output
```powershell
.\disk-health-reporter.ps1 -Verbose
```

### Combined Examples
```powershell
# All drives with verbose output
.\disk-health-reporter.ps1 -IncludeAllDrives -Verbose

# Specific drive
.\disk-health-reporter.ps1 -DriveLetter "E:" -Verbose
```

## Output Sections

### 1. Disk Capacity Analysis
```
Total Capacity: 119.53 GB
Used Space: 45.23 GB
Free Space: 74.30 GB
Percentage Full: 37.85 %
Status: HEALTHY ✓
```

### 2. Drive Information
- File system (NTFS, FAT32, etc.)
- Drive label
- Drive health status

### 3. Fragmentation Status
- Non-destructive analysis results
- Current fragmentation percentage
- Status confirmation (no defragmentation performed)

### 4. Optimization Status
- Scheduled task status
- Last run and next run times
- File system optimization recommendations

### 5. SMART Status (if available)
- Disk health predictions
- Failure warnings if applicable

## Health Status Indicators

| Status | Disk Full % | Action |
|--------|------------|--------|
| HEALTHY ✓ | < 80% | Monitor regularly |
| WARNING ⚠ | 80-90% | Review and clean unnecessary files |
| CRITICAL ✗ | > 90% | Delete files immediately, consider archiving |

## Important Restrictions & Guarantees

### ✓ Read-Only Operations Only
- Script only **reads** disk information
- **No file modifications** performed
- **No defragmentation** executed
- **No changes** to disk structure

### ✓ Safety Features
- Uses `-AnalyzeOnly` flag for fragmentation analysis
- Employs `ErrorAction Continue` for resilience
- No destructive WMI calls
- No scheduled task modifications

### ✗ What This Script Will NOT Do
- ❌ Defragment drives
- ❌ Delete files
- ❌ Modify partition structures
- ❌ Change optimization schedules
- ❌ Alter file system settings
- ❌ Enable/disable features

## Permissions

### Minimum Permissions
- Standard user permissions sufficient for basic disk space reporting
- No admin elevation required for basic functionality

### Elevated Permissions (Recommended)
- Run as Administrator for:
  - Complete fragmentation analysis data
  - Full SMART status information
  - Detailed optimization history
  - All WMI queries

## Requirements

- PowerShell 3.0 or higher
- Windows 7 or later (tested on Windows 10/11)
- Local disk access permissions

## Error Handling

The script includes robust error handling:
- Gracefully handles unavailable WMI data
- Continues analysis even if one section fails
- Provides informative error messages
- Suggests remediation steps

## Example Output Structure

```
╔════════════════════════════════════════════════════════════╗
║         DISK HEALTH & OPTIMIZATION REPORTER v1.0          ║
║                 READ-ONLY ANALYSIS SCRIPT                  ║
╚════════════════════════════════════════════════════════════╝

========== DISK HEALTH REPORT ==========
Drive: C:
Report Generated: 2026-08-13 14:32:15
Scan Mode: READ-ONLY (No modifications)

DISK CAPACITY ANALYSIS:
  Total Capacity: 119.53 GB
  Used Space: 45.23 GB
  Free Space: 74.30 GB
  Percentage Full: 37.85 %
  Status: HEALTHY ✓
  
[Additional sections follow...]

IMPORTANT NOTES:
  • This script is READ-ONLY and performs no modifications
  • Defragmentation is NEVER performed
  • Fragmentation analysis requires -AnalyzeOnly flag
  • For full SMART/fragmentation data, run as Administrator
```

## Troubleshooting

### "Fragmentation check: Limited data available"
- **Cause:** Running without administrator privileges
- **Solution:** Right-click PowerShell, select "Run as administrator"

### "SMART Data: Not available"
- **Cause:** WMI not accessible or hardware doesn't support SMART
- **Solution:** This is normal; non-critical information only

### "Error retrieving optimization status"
- **Cause:** Windows Scheduled Tasks service issue
- **Solution:** Ensure Task Scheduler service is running

## Data Output

The script displays results in color-coded output:
- **Cyan:** Main headers and informational messages
- **Green:** Healthy status and safe operations
- **Yellow:** Warnings and optimization suggestions
- **Red:** Critical issues requiring immediate attention
- **Magenta:** Section headers

## Schedule Regular Analysis

To schedule regular health reports, create a Windows scheduled task:
```powershell
$taskPath = "\Disk Health Reports\"
$taskName = "Daily Disk Health Check"
$script = "C:\Path\To\disk-health-reporter.ps1"

# Example: Run daily at 8:00 AM
# See Windows Task Scheduler documentation for full setup
```

## Support & Limitations

- **Scope:** Local system disk analysis only
- **Network Drives:** May have limited functionality
- **Cloud Storage:** Not directly analyzed
- **USB/External:** Supported if properly mounted

## Version History

| Version | Date | Notes |
|---------|------|-------|
| 1.0 | 2026-08-13 | Initial release - Read-only disk health reporting |

## License & Warranty

This script is provided as-is for educational and diagnostic purposes. The script performs read-only operations and has been validated to prevent accidental data modifications.

**Always maintain backups of critical data.**
