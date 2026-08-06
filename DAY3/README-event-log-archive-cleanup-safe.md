# Safe Event Log Archive and Cleanup Script (PowerShell 5.1)

This folder now includes:
- `event-log-archive-cleanup-safe.ps1`

The script is designed for safe endpoint use with:
- Dry-run mode that prints the total record count that would be deleted
- Configurable age filtering (`-OlderThanDays`, default `3`)
- Per-operation try/catch handling
- Timestamped action logging
- End-of-run summary
- Rollback mode using cleanup manifest and archived EVTX files
- Idempotent archive behavior (skip if today's archive already exists)

## How It Decides What To Clean

The script does **not** delete individual records.
It targets logs where the **newest event in the log** is older than the cutoff date.

Example with default `-OlderThanDays 3`:
- If a log's newest event is older than 3 days, that whole log is eligible.
- The log is archived first, then cleared.

## Parameters

- `-OlderThanDays <int>`
Only logs fully older than this many days are targeted.
Default: `3`

- `-DryRun`
No changes are made.
The script prints:
- target logs
- records per target log
- **total record count that would be deleted**

- `-Rollback`
Runs rollback mode.
If `-ManifestPath` is not provided, newest manifest is used.

- `-ManifestPath <string>`
Optional path to a specific manifest JSONL file for rollback.

- `-LogNamePattern <string>`
Optional wildcard pattern for logs.
Default: `*`
Examples: `Application`, `System`, `Microsoft-Windows-*`

- `-RunId <string>`
Optional run identifier for artifact naming.
Default: current timestamp (`yyyyMMdd_HHmmss`).

## Usage Examples

Dry run (recommended first):
```powershell
.\event-log-archive-cleanup-safe.ps1 -DryRun
```

Dry run, only Application and System:
```powershell
.\event-log-archive-cleanup-safe.ps1 -DryRun -LogNamePattern Application
.\event-log-archive-cleanup-safe.ps1 -DryRun -LogNamePattern System
```

Cleanup logs fully older than 7 days:
```powershell
.\event-log-archive-cleanup-safe.ps1 -OlderThanDays 7
```

Rollback from newest manifest:
```powershell
.\event-log-archive-cleanup-safe.ps1 -Rollback
```

Rollback from specific manifest:
```powershell
.\event-log-archive-cleanup-safe.ps1 -Rollback -ManifestPath ".\event-log-artifacts\manifests\manifest_20260805_120000.jsonl"
```

## Artifacts

Created under:
- `DAY3\event-log-artifacts\`

Subfolders:
- `logs\` -> timestamped script logs
- `archives\` -> archived EVTX files
- `manifests\` -> JSONL entries for each archived/cleared log
- `rollback-output\` -> rollback handling outputs

## Idempotency

Per log, archive file naming uses date (`yyyyMMdd`).
If today's archive file already exists for that log, cleanup for that log is skipped.
This prevents repeat archive/clear activity on the same log in the same day.

## Rollback Notes

Windows Event Log APIs do not provide a direct and universally safe "import back into live log" operation for all logs.
Rollback mode therefore does:
- guaranteed preservation/copy of archived EVTX files into rollback output
- best-effort creation of live restore candidate files when possible
- manifest status updates so repeated rollback runs stay idempotent

For high assurance recovery workflows, retain archived EVTX files and validate restoration procedures in a controlled lab before production use.
