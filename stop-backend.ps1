# ==============================================================================
# Teammate 1 Stop Script — stops ONLY this chunk's services (Gateway + Eureka)
# ==============================================================================
param([switch]$IncludeEureka = $false)

$ports = @(8080)
if ($IncludeEureka) { $ports += 8761 }

Write-Host "`nStopping Teammate-1 services on ports: $($ports -join ', ')..." -ForegroundColor Cyan

$conns = Get-NetTCPConnection -LocalPort $ports -State Listen -ErrorAction SilentlyContinue
if (-not $conns) {
    Write-Host "No services currently listening on these ports." -ForegroundColor Yellow
    return
}

foreach ($procId in ($conns | Select-Object -ExpandProperty OwningProcess -Unique)) {
    try {
        $p = Get-Process -Id $procId -ErrorAction Stop
        Write-Host "  Stopping process $($p.ProcessName) (PID $procId)..." -ForegroundColor Yellow
        Stop-Process -Id $procId -Force -ErrorAction SilentlyContinue
    } catch { }
}
Write-Host "Done. Teammate-1 services stopped.`n" -ForegroundColor Green
