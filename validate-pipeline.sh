#!/bin/bash

# Pipeline Validation Script
# This script validates that all required tools and configurations are in place

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

ERRORS=0
WARNINGS=0

echo -e "${CYAN}=====================================${NC}"
echo -e "${CYAN}Pipeline Validation Script${NC}"
echo -e "${CYAN}=====================================${NC}"
echo ""

function check_command {
    if command -v $1 &> /dev/null; then
        echo -e "${GREEN}✅ $1 is installed${NC}"
        if [ ! -z "$2" ]; then
            VERSION=$($1 $2 2>&1 | head -n 1)
            echo -e "   Version: $VERSION"
        fi
        return 0
    else
        echo -e "${RED}❌ $1 is NOT installed${NC}"
        ERRORS=$((ERRORS + 1))
        return 1
    fi
}

function check_file {
    if [ -f "$1" ]; then
        echo -e "${GREEN}✅ $1 exists${NC}"
        return 0
    else
        echo -e "${RED}❌ $1 is missing${NC}"
        ERRORS=$((ERRORS + 1))
        return 1
    fi
}

function check_docker_image {
    if docker images | grep -q "$1"; then
        echo -e "${GREEN}✅ Docker image $1 exists${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠️  Docker image $1 not found (will be built)${NC}"
        WARNINGS=$((WARNINGS + 1))
        return 1
    fi
}

# Check required commands
echo -e "${CYAN}1. Checking Required Tools${NC}"
check_command "docker" "--version"
check_command "docker-compose" "--version"
check_command "node" "--version"
check_command "npm" "--version"
check_command "git" "--version"

echo ""
echo -e "${CYAN}2. Checking Optional Tools (for Jenkins)${NC}"
check_command "trivy" "--version" || echo -e "   ${YELLOW}Install: https://aquasecurity.github.io/trivy/${NC}"
check_command "aws" "--version" || echo -e "   ${YELLOW}Install: https://aws.amazon.com/cli/${NC}"

# Check Docker daemon
echo ""
echo -e "${CYAN}3. Checking Docker Status${NC}"
if docker ps &> /dev/null; then
    echo -e "${GREEN}✅ Docker daemon is running${NC}"
else
    echo -e "${RED}❌ Docker daemon is not running${NC}"
    ERRORS=$((ERRORS + 1))
fi

# Check required files
echo ""
echo -e "${CYAN}4. Checking Project Files${NC}"
check_file "Jenkinsfile"
check_file "Jenkinsfile.production"
check_file "docker-compose.yml"
check_file "backend/Dockerfile"
check_file "frontend/Dockerfile"
check_file "backend/package.json"
check_file "frontend/package.json"
check_file "backend/server.js"
check_file "frontend/src/App.js"

# Check configuration files
echo ""
echo -e "${CYAN}5. Checking Configuration Files${NC}"
check_file "backend/sonar-project.properties"
check_file "frontend/sonar-project.properties"
check_file "backend/.env.example"
check_file "frontend/nginx.conf"

# Check dependencies
echo ""
echo -e "${CYAN}6. Checking Dependencies${NC}"
if [ -d "backend/node_modules" ]; then
    echo -e "${GREEN}✅ Backend dependencies installed${NC}"
else
    echo -e "${YELLOW}⚠️  Backend dependencies not installed${NC}"
    echo -e "   Run: cd backend && npm install"
    WARNINGS=$((WARNINGS + 1))
fi

if [ -d "frontend/node_modules" ]; then
    echo -e "${GREEN}✅ Frontend dependencies installed${NC}"
else
    echo -e "${YELLOW}⚠️  Frontend dependencies not installed${NC}"
    echo -e "   Run: cd frontend && npm install"
    WARNINGS=$((WARNINGS + 1))
fi

# Check Docker images
echo ""
echo -e "${CYAN}7. Checking Docker Images${NC}"
check_docker_image "mailwave-backend"
check_docker_image "mailwave-frontend"
check_docker_image "mongo"

# Check ports
echo ""
echo -e "${CYAN}8. Checking Port Availability${NC}"
function check_port {
    if lsof -Pi :$1 -sTCP:LISTEN -t >/dev/null 2>&1 ; then
        echo -e "${YELLOW}⚠️  Port $1 is in use${NC}"
        WARNINGS=$((WARNINGS + 1))
    else
        echo -e "${GREEN}✅ Port $1 is available${NC}"
    fi
}

check_port 3000
check_port 5000
check_port 27017

# Check AWS configuration (if AWS CLI is installed)
echo ""
echo -e "${CYAN}9. Checking AWS Configuration${NC}"
if command -v aws &> /dev/null; then
    if aws sts get-caller-identity &> /dev/null; then
        echo -e "${GREEN}✅ AWS credentials are configured${NC}"
        IDENTITY=$(aws sts get-caller-identity --query 'Account' --output text)
        echo -e "   Account: $IDENTITY"
    else
        echo -e "${YELLOW}⚠️  AWS credentials not configured${NC}"
        echo -e "   Run: aws configure"
        WARNINGS=$((WARNINGS + 1))
    fi
else
    echo -e "${YELLOW}⚠️  AWS CLI not installed (required for ECR push)${NC}"
    WARNINGS=$((WARNINGS + 1))
fi

# Check ECR repositories (if AWS is configured)
if command -v aws &> /dev/null && aws sts get-caller-identity &> /dev/null; then
    echo ""
    echo -e "${CYAN}10. Checking ECR Repositories${NC}"
    
    if aws ecr describe-repositories --repository-names mailwave-backend --region us-east-1 &> /dev/null; then
        echo -e "${GREEN}✅ ECR repository mailwave-backend exists${NC}"
    else
        echo -e "${YELLOW}⚠️  ECR repository mailwave-backend not found${NC}"
        echo -e "   Create: aws ecr create-repository --repository-name mailwave-backend --region us-east-1"
        WARNINGS=$((WARNINGS + 1))
    fi
    
    if aws ecr describe-repositories --repository-names mailwave-frontend --region us-east-1 &> /dev/null; then
        echo -e "${GREEN}✅ ECR repository mailwave-frontend exists${NC}"
    else
        echo -e "${YELLOW}⚠️  ECR repository mailwave-frontend not found${NC}"
        echo -e "   Create: aws ecr create-repository --repository-name mailwave-frontend --region us-east-1"
        WARNINGS=$((WARNINGS + 1))
    fi
fi

# Validate Dockerfiles
echo ""
echo -e "${CYAN}11. Validating Dockerfiles${NC}"
if docker build -f backend/Dockerfile -t mailwave-backend-test backend --no-cache &> /dev/null; then
    echo -e "${GREEN}✅ Backend Dockerfile is valid${NC}"
    docker rmi mailwave-backend-test &> /dev/null || true
else
    echo -e "${RED}❌ Backend Dockerfile has errors${NC}"
    ERRORS=$((ERRORS + 1))
fi

if docker build -f frontend/Dockerfile -t mailwave-frontend-test frontend --no-cache &> /dev/null; then
    echo -e "${GREEN}✅ Frontend Dockerfile is valid${NC}"
    docker rmi mailwave-frontend-test &> /dev/null || true
else
    echo -e "${RED}❌ Frontend Dockerfile has errors${NC}"
    ERRORS=$((ERRORS + 1))
fi

# Validate docker-compose
echo ""
echo -e "${CYAN}12. Validating docker-compose.yml${NC}"
if docker-compose config &> /dev/null; then
    echo -e "${GREEN}✅ docker-compose.yml is valid${NC}"
else
    echo -e "${RED}❌ docker-compose.yml has errors${NC}"
    ERRORS=$((ERRORS + 1))
fi

# Summary
echo ""
echo -e "${CYAN}=====================================${NC}"
echo -e "${CYAN}Validation Summary${NC}"
echo -e "${CYAN}=====================================${NC}"

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✅ All checks passed! Pipeline is ready.${NC}"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠️  $WARNINGS warning(s) found. Pipeline may work but review warnings.${NC}"
    exit 0
else
    echo -e "${RED}❌ $ERRORS error(s) and $WARNINGS warning(s) found.${NC}"
    echo -e "${RED}Please fix the errors before running the pipeline.${NC}"
    exit 1
fi
