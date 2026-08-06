# Safe Temp Cleanup Script (PowerShell 5.1)

This folder contains a safe temp cleanup script for Windows endpoints:
- `temp-cleanup-safe.ps1`

The script is designed for DWP endpoint engineering workflows with:
- Dry-run support
- Configurable file age filter
- Per-file try/catch error handling
- Locked file skip + logging
- Timestamped action log
- End-of-run summary
- Rollback support via manifest + quarantine
- Idempotent behavior

## Script Behavior

In cleanup mode, files are removed from target temp locations by moving them into a quarantine store, and each move is recorded in a manifest file.

This provides rollback capability while keeping operations safe and traceable.

## Parameters

- `-TargetPaths <string[]>`
Scans these folders recursively for files to clean.
Default:
- `$env:TEMP`
- `$env:WINDIR\Temp`

- `-OlderThanDays <int>`
Only targets files with `LastWriteTime` older than this value in days.
Default: `0`

- `-DryRun`
Lists files that would be cleaned without changing anything.

- `-Rollback`
Runs rollback mode and restores files from a manifest.

- `-EnableRollback`
Alias of `-Rollback` for the same restore operation.

- `-ManifestPath <string>`
Optional path to a specific manifest file for rollback.
If omitted with `-Rollback`, the newest manifest is used.

- `-RunId <string>`
Optional run identifier for cleanup artifact naming.
Default: current timestamp (`yyyyMMdd_HHmmss`).

## Examples

Dry run with defaults:
```powershell
.\temp-cleanup-safe.ps1 -DryRun
```

Cleanup files older than 7 days:
```powershell
.\temp-cleanup-safe.ps1 -OlderThanDays 7
```

Cleanup custom paths in dry-run:
```powershell
.\temp-cleanup-safe.ps1 -TargetPaths "C:\Temp","C:\Windows\Temp" -OlderThanDays 3 -DryRun
```

Rollback from latest manifest:
```powershell
.\temp-cleanup-safe.ps1 -Rollback
```

Rollback from latest manifest using the compatibility alias:
```powershell
.\temp-cleanup-safe.ps1 -EnableRollback
```

Rollback from a specific manifest:
```powershell
.\temp-cleanup-safe.ps1 -Rollback -ManifestPath ".\temp-cleanup-artifacts\manifests\manifest_20260805_103000.jsonl"
```

## Logs and Artifacts

Artifacts are created under:
- `DAY3\temp-cleanup-artifacts\`

Subfolders:
- `logs\` -> timestamped run logs
- `manifests\` -> JSONL manifest entries for moved files
- `quarantine\` -> staged files available for rollback

## Idempotency Notes

Cleanup idempotency:
- Already-moved or already-removed files are skipped safely.
- Re-running cleanup does not fail when files are no longer present.

Rollback idempotency:
- If staged files are already restored/missing, entries are skipped.
- If destination already exists, restore is skipped to avoid overwrite.

## Operational Guidance

- Run first with `-DryRun` to verify scope.
- Start with higher `-OlderThanDays` values in production-style endpoints.
- Review the summary and log file after each run.
- Keep manifests/logs for audit and support history.
