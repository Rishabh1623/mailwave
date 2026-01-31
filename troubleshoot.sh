#!/bin/bash

echo "==================================="
echo "MailWave Troubleshooting Script"
echo "==================================="
echo ""

# Check Node.js
echo "1. Checking Node.js installation..."
if command -v node &> /dev/null; then
    echo "✅ Node.js installed: $(node --version)"
else
    echo "❌ Node.js not found. Install from https://nodejs.org/"
fi

# Check npm
echo ""
echo "2. Checking npm installation..."
if command -v npm &> /dev/null; then
    echo "✅ npm installed: $(npm --version)"
else
    echo "❌ npm not found. Install Node.js to get npm"
fi

# Check Docker
echo ""
echo "3. Checking Docker installation..."
if command -v docker &> /dev/null; then
    echo "✅ Docker installed: $(docker --version)"
    if docker ps &> /dev/null; then
        echo "✅ Docker daemon is running"
    else
        echo "❌ Docker daemon is not running. Start Docker Desktop"
    fi
else
    echo "❌ Docker not found. Install from https://www.docker.com/products/docker-desktop"
fi

# Check Docker Compose
echo ""
echo "4. Checking Docker Compose..."
if command -v docker-compose &> /dev/null; then
    echo "✅ Docker Compose installed: $(docker-compose --version)"
else
    echo "❌ Docker Compose not found"
fi

# Check Git
echo ""
echo "5. Checking Git installation..."
if command -v git &> /dev/null; then
    echo "✅ Git installed: $(git --version)"
else
    echo "❌ Git not found. Install from https://git-scm.com/"
fi

# Check ports
echo ""
echo "6. Checking port availability..."
check_port() {
    if lsof -Pi :$1 -sTCP:LISTEN -t >/dev/null 2>&1 ; then
        echo "⚠️  Port $1 is in use"
        lsof -Pi :$1 -sTCP:LISTEN
    else
        echo "✅ Port $1 is available"
    fi
}

check_port 3000
check_port 5000
check_port 27017
check_port 9000

# Check running containers
echo ""
echo "7. Checking running containers..."
if docker ps &> /dev/null; then
    CONTAINERS=$(docker ps --filter "name=mailwave" --format "{{.Names}}" | wc -l)
    if [ $CONTAINERS -gt 0 ]; then
        echo "✅ Found $CONTAINERS MailWave containers running:"
        docker ps --filter "name=mailwave" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    else
        echo "⚠️  No MailWave containers running"
    fi
else
    echo "❌ Cannot check containers (Docker not running)"
fi

# Check Docker networks
echo ""
echo "8. Checking Docker networks..."
if docker network ls &> /dev/null; then
    if docker network ls | grep -q mailwave; then
        echo "✅ MailWave network exists"
    else
        echo "⚠️  MailWave network not found"
    fi
fi

# Check Docker volumes
echo ""
echo "9. Checking Docker volumes..."
if docker volume ls &> /dev/null; then
    if docker volume ls | grep -q mailwave; then
        echo "✅ MailWave volumes exist"
        docker volume ls | grep mailwave
    else
        echo "⚠️  No MailWave volumes found"
    fi
fi

# Check backend dependencies
echo ""
echo "10. Checking backend dependencies..."
if [ -d "backend/node_modules" ]; then
    echo "✅ Backend node_modules exists"
else
    echo "⚠️  Backend dependencies not installed. Run: cd backend && npm install"
fi

# Check frontend dependencies
echo ""
echo "11. Checking frontend dependencies..."
if [ -d "frontend/node_modules" ]; then
    echo "✅ Frontend node_modules exists"
else
    echo "⚠️  Frontend dependencies not installed. Run: cd frontend && npm install"
fi

# Test backend health
echo ""
echo "12. Testing backend health..."
if curl -f http://localhost:5000/api/health &> /dev/null; then
    echo "✅ Backend is responding"
    curl http://localhost:5000/api/health
else
    echo "⚠️  Backend is not responding on port 5000"
fi

# Test frontend
echo ""
echo "13. Testing frontend..."
if curl -f http://localhost:3000 &> /dev/null; then
    echo "✅ Frontend is responding"
else
    echo "⚠️  Frontend is not responding on port 3000"
fi

# Check disk space
echo ""
echo "14. Checking disk space..."
df -h | grep -E "Filesystem|/$"

# Check Docker disk usage
echo ""
echo "15. Checking Docker disk usage..."
if docker system df &> /dev/null; then
    docker system df
fi

echo ""
echo "==================================="
echo "Troubleshooting Complete"
echo "==================================="
echo ""
echo "Quick fixes:"
echo "- Install missing tools from links above"
echo "- Start Docker Desktop if not running"
echo "- Run 'docker-compose up -d' to start services"
echo "- Run 'docker-compose logs -f' to see logs"
echo "- Run 'docker-compose down' to stop services"
echo ""
