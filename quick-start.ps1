# MailWave Quick Start Script for Windows
param(
    [switch]$Install,
    [switch]$Start,
    [switch]$Stop,
    [switch]$Clean,
    [switch]$Logs,
    [switch]$Status
)

$ErrorActionPreference = "Continue"

function Show-Help {
    Write-Host @"
MailWave Quick Start Script
============================

Usage: .\quick-start.ps1 [OPTIONS]

Options:
  -Install    Install dependencies (npm packages)
  -Start      Start all services with Docker Compose
  -Stop       Stop all services
  -Clean      Clean up containers, volumes, and images
  -Logs       Show container logs
  -Status     Show status of all services
  -Help       Show this help message

Examples:
  .\quick-start.ps1 -Install
  .\quick-start.ps1 -Start
  .\quick-start.ps1 -Status
  .\quick-start.ps1 -Logs
  .\quick-start.ps1 -Stop
  .\quick-start.ps1 -Clean

"@
}

function Install-Dependencies {
    Write-Host "Installing dependencies..." -ForegroundColor Cyan
    
    Write-Host "`nInstalling backend dependencies..." -ForegroundColor Yellow
    Push-Location backend
    npm install
    Pop-Location
    
    Write-Host "`nInstalling frontend dependencies..." -ForegroundColor Yellow
    Push-Location frontend
    npm install
    Pop-Location
    
    Write-Host "`n✅ Dependencies installed successfully!" -ForegroundColor Green
}

function Start-Services {
    Write-Host "Starting MailWave services..." -ForegroundColor Cyan
    
    # Check if Docker is running
    try {
        docker ps | Out-Null
    } catch {
        Write-Host "❌ Docker is not running. Please start Docker Desktop." -ForegroundColor Red
        exit 1
    }
    
    # Stop existing containers
    Write-Host "`nStopping existing containers..." -ForegroundColor Yellow
    docker-compose down 2>$null
    
    # Start services
    Write-Host "`nStarting services..." -ForegroundColor Yellow
    docker-compose up -d
    
    # Wait for services
    Write-Host "`nWaiting for services to start..." -ForegroundColor Yellow
    Start-Sleep -Seconds 15
    
    # Check health
    Write-Host "`nChecking service health..." -ForegroundColor Yellow
    
    $backendHealthy = $false
    $frontendHealthy = $false
    
    for ($i = 1; $i -le 10; $i++) {
        try {
            $response = Invoke-WebRequest -Uri "http://localhost:5000/api/health" -UseBasicParsing -TimeoutSec 2
            if ($response.StatusCode -eq 200) {
                Write-Host "✅ Backend is healthy" -ForegroundColor Green
                $backendHealthy = $true
                break
            }
        } catch {
            Write-Host "⏳ Waiting for backend... attempt $i/10" -ForegroundColor Yellow
            Start-Sleep -Seconds 3
        }
    }
    
    for ($i = 1; $i -le 10; $i++) {
        try {
            $response = Invoke-WebRequest -Uri "http://localhost:3000" -UseBasicParsing -TimeoutSec 2
            if ($response.StatusCode -eq 200) {
                Write-Host "✅ Frontend is healthy" -ForegroundColor Green
                $frontendHealthy = $true
                break
            }
        } catch {
            Write-Host "⏳ Waiting for frontend... attempt $i/10" -ForegroundColor Yellow
            Start-Sleep -Seconds 3
        }
    }
    
    Write-Host "`n=====================================" -ForegroundColor Cyan
    Write-Host "MailWave Services Started!" -ForegroundColor Cyan
    Write-Host "=====================================" -ForegroundColor Cyan
    Write-Host "`nAccess the application:" -ForegroundColor Yellow
    Write-Host "  Frontend:  http://localhost:3000" -ForegroundColor White
    Write-Host "  Backend:   http://localhost:5000/api/health" -ForegroundColor White
    Write-Host "  MongoDB:   mongodb://localhost:27017" -ForegroundColor White
    Write-Host "`nView logs: .\quick-start.ps1 -Logs" -ForegroundColor Yellow
    Write-Host "Stop services: .\quick-start.ps1 -Stop" -ForegroundColor Yellow
    Write-Host ""
}

function Stop-Services {
    Write-Host "Stopping MailWave services..." -ForegroundColor Cyan
    docker-compose down
    Write-Host "✅ Services stopped" -ForegroundColor Green
}

function Clean-All {
    Write-Host "Cleaning up MailWave..." -ForegroundColor Cyan
    
    Write-Host "`nStopping containers..." -ForegroundColor Yellow
    docker-compose down -v
    
    Write-Host "`nRemoving images..." -ForegroundColor Yellow
    docker rmi mailwave-backend:latest -f 2>$null
    docker rmi mailwave-frontend:latest -f 2>$null
    
    Write-Host "`nPruning Docker system..." -ForegroundColor Yellow
    docker system prune -f
    
    Write-Host "`n✅ Cleanup complete!" -ForegroundColor Green
}

function Show-Logs {
    Write-Host "Showing container logs (Ctrl+C to exit)..." -ForegroundColor Cyan
    docker-compose logs -f
}

function Show-Status {
    Write-Host "MailWave Service Status" -ForegroundColor Cyan
    Write-Host "=======================" -ForegroundColor Cyan
    Write-Host ""
    
    docker-compose ps
    
    Write-Host "`nContainer Health:" -ForegroundColor Yellow
    docker ps --filter "name=mailwave" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    
    Write-Host "`nDocker Resources:" -ForegroundColor Yellow
    docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}"
}

# Main script logic
if ($Install) {
    Install-Dependencies
} elseif ($Start) {
    Start-Services
} elseif ($Stop) {
    Stop-Services
} elseif ($Clean) {
    Clean-All
} elseif ($Logs) {
    Show-Logs
} elseif ($Status) {
    Show-Status
} else {
    Show-Help
}
