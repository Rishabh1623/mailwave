# MailWave Troubleshooting Script for Windows
Write-Host "===================================" -ForegroundColor Cyan
Write-Host "MailWave Troubleshooting Script" -ForegroundColor Cyan
Write-Host "===================================" -ForegroundColor Cyan
Write-Host ""

# Check Node.js
Write-Host "1. Checking Node.js installation..." -ForegroundColor Yellow
try {
    $nodeVersion = node --version
    Write-Host "✅ Node.js installed: $nodeVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Node.js not found. Install from https://nodejs.org/" -ForegroundColor Red
}

# Check npm
Write-Host ""
Write-Host "2. Checking npm installation..." -ForegroundColor Yellow
try {
    $npmVersion = npm --version
    Write-Host "✅ npm installed: $npmVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ npm not found. Install Node.js to get npm" -ForegroundColor Red
}

# Check Docker
Write-Host ""
Write-Host "3. Checking Docker installation..." -ForegroundColor Yellow
try {
    $dockerVersion = docker --version
    Write-Host "✅ Docker installed: $dockerVersion" -ForegroundColor Green
    
    try {
        docker ps | Out-Null
        Write-Host "✅ Docker daemon is running" -ForegroundColor Green
    } catch {
        Write-Host "❌ Docker daemon is not running. Start Docker Desktop" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Docker not found. Install from https://www.docker.com/products/docker-desktop" -ForegroundColor Red
}

# Check Docker Compose
Write-Host ""
Write-Host "4. Checking Docker Compose..." -ForegroundColor Yellow
try {
    $composeVersion = docker-compose --version
    Write-Host "✅ Docker Compose installed: $composeVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Docker Compose not found" -ForegroundColor Red
}

# Check Git
Write-Host ""
Write-Host "5. Checking Git installation..." -ForegroundColor Yellow
try {
    $gitVersion = git --version
    Write-Host "✅ Git installed: $gitVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Git not found. Install from https://git-scm.com/" -ForegroundColor Red
}

# Check ports
Write-Host ""
Write-Host "6. Checking port availability..." -ForegroundColor Yellow

function Test-Port {
    param($Port)
    $connection = Get-NetTCPConnection -LocalPort $Port -ErrorAction SilentlyContinue
    if ($connection) {
        Write-Host "⚠️  Port $Port is in use" -ForegroundColor Yellow
        $connection | Select-Object LocalPort, State, OwningProcess | Format-Table
    } else {
        Write-Host "✅ Port $Port is available" -ForegroundColor Green
    }
}

Test-Port 3000
Test-Port 5000
Test-Port 27017
Test-Port 9000

# Check running containers
Write-Host ""
Write-Host "7. Checking running containers..." -ForegroundColor Yellow
try {
    $containers = docker ps --filter "name=mailwave" --format "{{.Names}}" 2>$null
    if ($containers) {
        Write-Host "✅ Found MailWave containers running:" -ForegroundColor Green
        docker ps --filter "name=mailwave" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    } else {
        Write-Host "⚠️  No MailWave containers running" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Cannot check containers (Docker not running)" -ForegroundColor Red
}

# Check Docker networks
Write-Host ""
Write-Host "8. Checking Docker networks..." -ForegroundColor Yellow
try {
    $networks = docker network ls | Select-String "mailwave"
    if ($networks) {
        Write-Host "✅ MailWave network exists" -ForegroundColor Green
    } else {
        Write-Host "⚠️  MailWave network not found" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Cannot check networks" -ForegroundColor Red
}

# Check Docker volumes
Write-Host ""
Write-Host "9. Checking Docker volumes..." -ForegroundColor Yellow
try {
    $volumes = docker volume ls | Select-String "mailwave"
    if ($volumes) {
        Write-Host "✅ MailWave volumes exist" -ForegroundColor Green
        docker volume ls | Select-String "mailwave"
    } else {
        Write-Host "⚠️  No MailWave volumes found" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Cannot check volumes" -ForegroundColor Red
}

# Check backend dependencies
Write-Host ""
Write-Host "10. Checking backend dependencies..." -ForegroundColor Yellow
if (Test-Path "backend/node_modules") {
    Write-Host "✅ Backend node_modules exists" -ForegroundColor Green
} else {
    Write-Host "⚠️  Backend dependencies not installed. Run: cd backend; npm install" -ForegroundColor Yellow
}

# Check frontend dependencies
Write-Host ""
Write-Host "11. Checking frontend dependencies..." -ForegroundColor Yellow
if (Test-Path "frontend/node_modules") {
    Write-Host "✅ Frontend node_modules exists" -ForegroundColor Green
} else {
    Write-Host "⚠️  Frontend dependencies not installed. Run: cd frontend; npm install" -ForegroundColor Yellow
}

# Test backend health
Write-Host ""
Write-Host "12. Testing backend health..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:5000/api/health" -UseBasicParsing -TimeoutSec 5
    Write-Host "✅ Backend is responding" -ForegroundColor Green
    Write-Host $response.Content
} catch {
    Write-Host "⚠️  Backend is not responding on port 5000" -ForegroundColor Yellow
}

# Test frontend
Write-Host ""
Write-Host "13. Testing frontend..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:3000" -UseBasicParsing -TimeoutSec 5
    Write-Host "✅ Frontend is responding" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Frontend is not responding on port 3000" -ForegroundColor Yellow
}

# Check disk space
Write-Host ""
Write-Host "14. Checking disk space..." -ForegroundColor Yellow
Get-PSDrive -PSProvider FileSystem | Select-Object Name, @{Name="Used(GB)";Expression={[math]::Round($_.Used/1GB,2)}}, @{Name="Free(GB)";Expression={[math]::Round($_.Free/1GB,2)}} | Format-Table

# Check Docker disk usage
Write-Host ""
Write-Host "15. Checking Docker disk usage..." -ForegroundColor Yellow
try {
    docker system df
} catch {
    Write-Host "❌ Cannot check Docker disk usage" -ForegroundColor Red
}

Write-Host ""
Write-Host "===================================" -ForegroundColor Cyan
Write-Host "Troubleshooting Complete" -ForegroundColor Cyan
Write-Host "===================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Quick fixes:" -ForegroundColor Yellow
Write-Host "- Install missing tools from links above"
Write-Host "- Start Docker Desktop if not running"
Write-Host "- Run 'docker-compose up -d' to start services"
Write-Host "- Run 'docker-compose logs -f' to see logs"
Write-Host "- Run 'docker-compose down' to stop services"
Write-Host ""
