# MailWave Services Health Check Script
# Checks the status of all services

Write-Host "🔍 Checking MailWave Services..." -ForegroundColor Cyan
Write-Host ""

# Function to check URL
function Test-ServiceUrl {
    param($Name, $Url)
    try {
        $response = Invoke-WebRequest -Uri $Url -TimeoutSec 5 -UseBasicParsing -ErrorAction Stop
        Write-Host "✅ $Name is UP ($Url)" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "❌ $Name is DOWN ($Url)" -ForegroundColor Red
        return $false
    }
}

# Check Docker containers
Write-Host "📦 Docker Containers:" -ForegroundColor Yellow
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" --filter "name=jenkins" --filter "name=sonarqube" --filter "name=mailwave"
Write-Host ""

# Check service endpoints
Write-Host "🌐 Service Health Checks:" -ForegroundColor Yellow
Write-Host ""

$jenkinsUp = Test-ServiceUrl "Jenkins" "http://localhost:8080"
$sonarUp = Test-ServiceUrl "SonarQube" "http://localhost:9000"

Write-Host ""
Write-Host "📊 Summary:" -ForegroundColor Cyan
if ($jenkinsUp -and $sonarUp) {
    Write-Host "✅ All core services are running!" -ForegroundColor Green
} else {
    Write-Host "⚠️ Some services are not responding" -ForegroundColor Yellow
    Write-Host "   Run: .\start-services.ps1 to start services" -ForegroundColor White
}
Write-Host ""
