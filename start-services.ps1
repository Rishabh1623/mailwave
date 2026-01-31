# MailWave Services Startup Script
# This script starts Jenkins, SonarQube, and the application

Write-Host "🚀 Starting MailWave Services..." -ForegroundColor Cyan
Write-Host ""

# Check if Docker is running
Write-Host "Checking Docker..." -ForegroundColor Yellow
docker ps > $null 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Docker is not running. Please start Docker Desktop first." -ForegroundColor Red
    exit 1
}
Write-Host "✅ Docker is running" -ForegroundColor Green
Write-Host ""

# Start Jenkins
Write-Host "🔧 Starting Jenkins..." -ForegroundColor Yellow
docker start jenkins 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Jenkins started" -ForegroundColor Green
} else {
    Write-Host "⚠️ Jenkins container not found or already running" -ForegroundColor Yellow
}
Write-Host ""

# Start SonarQube
Write-Host "📊 Starting SonarQube..." -ForegroundColor Yellow
docker start sonarqube 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ SonarQube started" -ForegroundColor Green
} else {
    Write-Host "⚠️ SonarQube container not found or already running" -ForegroundColor Yellow
}
Write-Host ""

# Wait a moment for services to initialize
Write-Host "⏳ Waiting for services to initialize..." -ForegroundColor Yellow
Start-Sleep -Seconds 5
Write-Host ""

# Check service status
Write-Host "📋 Service Status:" -ForegroundColor Cyan
Write-Host ""
docker ps --filter "name=jenkins" --filter "name=sonarqube" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
Write-Host ""

# Display access URLs
Write-Host "🌐 Access URLs:" -ForegroundColor Cyan
Write-Host "   Jenkins:   http://localhost:8080" -ForegroundColor White
Write-Host "   SonarQube: http://localhost:9000" -ForegroundColor White
Write-Host ""

Write-Host "✅ Services startup complete!" -ForegroundColor Green
Write-Host ""
Write-Host "💡 Next steps:" -ForegroundColor Yellow
Write-Host "   1. Wait 30-60 seconds for services to fully start"
Write-Host "   2. Access Jenkins at http://localhost:8080"
Write-Host "   3. Access SonarQube at http://localhost:9000"
Write-Host "   4. Run a Jenkins build to deploy the application"
Write-Host ""
