#!/bin/bash

# MailWave Quick Start Script for Linux/Mac

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

function show_help {
    cat << EOF
MailWave Quick Start Script
============================

Usage: ./quick-start.sh [COMMAND]

Commands:
  install     Install dependencies (npm packages)
  start       Start all services with Docker Compose
  stop        Stop all services
  clean       Clean up containers, volumes, and images
  logs        Show container logs
  status      Show status of all services
  help        Show this help message

Examples:
  ./quick-start.sh install
  ./quick-start.sh start
  ./quick-start.sh status
  ./quick-start.sh logs
  ./quick-start.sh stop
  ./quick-start.sh clean

EOF
}

function install_dependencies {
    echo -e "${CYAN}Installing dependencies...${NC}"
    
    echo -e "\n${YELLOW}Installing backend dependencies...${NC}"
    cd backend
    npm install
    cd ..
    
    echo -e "\n${YELLOW}Installing frontend dependencies...${NC}"
    cd frontend
    npm install
    cd ..
    
    echo -e "\n${GREEN}✅ Dependencies installed successfully!${NC}"
}

function start_services {
    echo -e "${CYAN}Starting MailWave services...${NC}"
    
    # Check if Docker is running
    if ! docker ps &> /dev/null; then
        echo -e "${RED}❌ Docker is not running. Please start Docker Desktop.${NC}"
        exit 1
    fi
    
    # Stop existing containers
    echo -e "\n${YELLOW}Stopping existing containers...${NC}"
    docker-compose down 2>/dev/null || true
    
    # Start services
    echo -e "\n${YELLOW}Starting services...${NC}"
    docker-compose up -d
    
    # Wait for services
    echo -e "\n${YELLOW}Waiting for services to start...${NC}"
    sleep 15
    
    # Check health
    echo -e "\n${YELLOW}Checking service health...${NC}"
    
    BACKEND_HEALTHY=false
    FRONTEND_HEALTHY=false
    
    for i in {1..10}; do
        if curl -f http://localhost:5000/api/health &> /dev/null; then
            echo -e "${GREEN}✅ Backend is healthy${NC}"
            BACKEND_HEALTHY=true
            break
        fi
        echo -e "${YELLOW}⏳ Waiting for backend... attempt $i/10${NC}"
        sleep 3
    done
    
    for i in {1..10}; do
        if curl -f http://localhost:3000 &> /dev/null; then
            echo -e "${GREEN}✅ Frontend is healthy${NC}"
            FRONTEND_HEALTHY=true
            break
        fi
        echo -e "${YELLOW}⏳ Waiting for frontend... attempt $i/10${NC}"
        sleep 3
    done
    
    echo -e "\n${CYAN}=====================================${NC}"
    echo -e "${CYAN}MailWave Services Started!${NC}"
    echo -e "${CYAN}=====================================${NC}"
    echo -e "\n${YELLOW}Access the application:${NC}"
    echo -e "  Frontend:  http://localhost:3000"
    echo -e "  Backend:   http://localhost:5000/api/health"
    echo -e "  MongoDB:   mongodb://localhost:27017"
    echo -e "\n${YELLOW}View logs: ./quick-start.sh logs${NC}"
    echo -e "${YELLOW}Stop services: ./quick-start.sh stop${NC}"
    echo ""
}

function stop_services {
    echo -e "${CYAN}Stopping MailWave services...${NC}"
    docker-compose down
    echo -e "${GREEN}✅ Services stopped${NC}"
}

function clean_all {
    echo -e "${CYAN}Cleaning up MailWave...${NC}"
    
    echo -e "\n${YELLOW}Stopping containers...${NC}"
    docker-compose down -v
    
    echo -e "\n${YELLOW}Removing images...${NC}"
    docker rmi mailwave-backend:latest -f 2>/dev/null || true
    docker rmi mailwave-frontend:latest -f 2>/dev/null || true
    
    echo -e "\n${YELLOW}Pruning Docker system...${NC}"
    docker system prune -f
    
    echo -e "\n${GREEN}✅ Cleanup complete!${NC}"
}

function show_logs {
    echo -e "${CYAN}Showing container logs (Ctrl+C to exit)...${NC}"
    docker-compose logs -f
}

function show_status {
    echo -e "${CYAN}MailWave Service Status${NC}"
    echo -e "${CYAN}=======================${NC}"
    echo ""
    
    docker-compose ps
    
    echo -e "\n${YELLOW}Container Health:${NC}"
    docker ps --filter "name=mailwave" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    
    echo -e "\n${YELLOW}Docker Resources:${NC}"
    docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}"
}

# Main script logic
case "$1" in
    install)
        install_dependencies
        ;;
    start)
        start_services
        ;;
    stop)
        stop_services
        ;;
    clean)
        clean_all
        ;;
    logs)
        show_logs
        ;;
    status)
        show_status
        ;;
    help|--help|-h|"")
        show_help
        ;;
    *)
        echo -e "${RED}Unknown command: $1${NC}"
        echo ""
        show_help
        exit 1
        ;;
esac
