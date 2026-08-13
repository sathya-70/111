$ErrorActionPreference = 'Stop'

$services = 'RdAgent','RdAgentBootLoader'
foreach ($svc in $services) {
    $obj = Get-Service -Name $svc -ErrorAction SilentlyContinue
    if ($null -eq $obj) {
        Write-Output ("SERVICE_" + $svc + "=MISSING")
    } else {
        Write-Output ("SERVICE_" + $svc + "=" + $obj.Status)
    }
}

$ds = dsregcmd /status
$aadLine = $ds | Where-Object { $_ -match 'AzureAdJoined\s*:\s*(YES|NO)' } | Select-Object -First 1
$domLine = $ds | Where-Object { $_ -match 'DomainJoined\s*:\s*(YES|NO)' } | Select-Object -First 1

if ($aadLine) { Write-Output ($aadLine.Trim()) }
if ($domLine) { Write-Output ($domLine.Trim()) }