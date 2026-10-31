# ==============================================================================
# Teammate 1 (Platform & Infra) Start Script — starts ONLY this chunk's services
# Eureka Server (:8761) + API Gateway (:8080)
# Usage:  .\start-backend.ps1 -Mode maven   (or jar mode after mvn install)
# ==============================================================================
param([ValidateSet("jar", "maven")][string]$Mode = "jar")

$ErrorActionPreference = "Continue"
$backendDir = Join-Path $PSScriptRoot "backend"
$logsDir = Join-Path $backendDir "logs"
New-Item -ItemType Directory -Path $logsDir -Force | Out-Null

# Common secret for JWT signing (min 32 chars) — keep in sync with other teammates
$env:JWT_SECRET = "change-me-dev-secret-min-32-chars-long"

Write-Host "`n=== Starting Teammate-1 services (eureka-server, api-gateway) ===`n" -ForegroundColor Cyan

# This chunk has no data service, so MongoDB is NOT required.
# (Other teammates' services need Mongo on :27017 — see their MY-PART.md)

$services = @(
    @{ Name = "eureka-server"; Port = 8761; Jar = "eureka-server\target\eureka-server.jar" },
    @{ Name = "api-gateway";   Port = 8080; Jar = "api-gateway\target\api-gateway.jar" }
)

foreach ($svc in $services) {
    $port = $svc.Port; $name = $svc.Name
    $logFile = Join-Path $logsDir "$name.log"

    if ((Test-NetConnection -ComputerName 127.0.0.1 -Port $port -WarningAction SilentlyContinue).TcpTestSucceeded) {
        Write-Host ("  [ALREADY RUNNING] {0,-16} on port {1}" -f $name, $port) -ForegroundColor Green
        continue
    }

    $jarFull = Join-Path $backendDir $svc.Jar
    if ($Mode -eq "jar" -and (Test-Path $jarFull)) {
        Write-Host ("  [STARTING JAR]    {0,-16} (port {1})..." -f $name, $port)
        $cmdArgs = "/c start /b `"`" cmd /c `"set JWT_SECRET=$env:JWT_SECRET&& java -Xmx256m -jar `"$jarFull`" > `"$logFile`" 2>&1`"`""
        Start-Process -FilePath "cmd.exe" -ArgumentList $cmdArgs -WorkingDirectory (Split-Path $jarFull) -WindowStyle Hidden
    } else {
        Write-Host ("  [STARTING MAVEN]  {0,-16} (port {1})..." -f $name, $port)
        $cmdArgs = "/c start /b `"`" cmd /c `"set JWT_SECRET=$env:JWT_SECRET&& mvn -q -pl $name -am spring-boot:run > `"$logFile`" 2>&1`"`""
        Start-Process -FilePath "cmd.exe" -ArgumentList $cmdArgs -WorkingDirectory $backendDir -WindowStyle Hidden
    }
    if ($name -eq "eureka-server") { Start-Sleep -Seconds 5 } else { Start-Sleep -Seconds 1 }
}

# Wait for readiness (max 90s)
Write-Host "`nWaiting for services to initialize..." -ForegroundColor Cyan
$sw = [System.Diagnostics.Stopwatch]::StartNew()
while ($sw.Elapsed.TotalSeconds -lt 90) {
    $allUp = $true
    foreach ($svc in $services) {
        if (-not (Test-NetConnection -ComputerName 127.0.0.1 -Port $svc.Port -WarningAction SilentlyContinue).TcpTestSucceeded) { $allUp = $false }
    }
    if ($allUp) { break }
    Start-Sleep -Seconds 3
}

Write-Host "`n=== Status ===" -ForegroundColor Cyan
foreach ($svc in $services) {
    $t = Test-NetConnection -ComputerName 127.0.0.1 -Port $svc.Port -WarningAction SilentlyContinue
    $status = if ($t.TcpTestSucceeded) { "ONLINE" } else { "STARTING (check logs/$($svc.Name).log)" }
    Write-Host ("  {0,-16} : Port {1,-5} : {2}" -f $svc.Name, $svc.Port, $status)
}
Write-Host "`nEureka dashboard: http://localhost:8761" -ForegroundColor Green
Write-Host "API Gateway:      http://localhost:8080" -ForegroundColor Green
Write-Host "Stop with:        .\stop-backend.ps1`n" -ForegroundColor Yellow
