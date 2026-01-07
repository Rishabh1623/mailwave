# MailWave - Three-Tier Newsletter Blog Application

A full-stack newsletter blog application for learning DevOps practices.

## Architecture
- **Frontend**: React application (Port 3000)
- **Backend**: Node.js/Express API (Port 5000)
- **Database**: MongoDB (Port 27017)

---

## 📋 Prerequisites

### On Your Local Machine (Windows):
- Git installed
- GitHub account

### On AWS Ubuntu Machine:
- Node.js (v18+)
- MongoDB
- Docker
- Docker Compose

---

## 🚀 Phase 1: Local Testing on AWS Ubuntu

### Step 1: Launch AWS Ubuntu Instance
1. Go to AWS EC2 Console
2. Launch Ubuntu 22.04 LTS instance (t2.medium recommended)
3. Configure Security Group:
   - SSH (22) - Your IP
   - HTTP (80) - Anywhere
   - Custom TCP (3000) - Anywhere (Frontend)
   - Custom TCP (5000) - Anywhere (Backend)
   - Custom TCP (27017) - Anywhere (MongoDB)
4. Download your .pem key file

### Step 2: Connect to Ubuntu Instance
```bash
# On Windows (PowerShell or CMD)
ssh -i "your-key.pem" ubuntu@your-ec2-public-ip
```

### Step 3: Update System
```bash
sudo apt update
sudo apt upgrade -y
```

### Step 4: Install Node.js
```bash
# Install Node.js 18.x
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# Verify installation
node --version
npm --version
```

### Step 5: Install MongoDB
```bash
# Import MongoDB public GPG key
curl -fsSL https://pgp.mongodb.com/server-7.0.asc | sudo gpg -o /usr/share/keyrings/mongodb-server-7.0.gpg --dearmor

# Create list file for MongoDB
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list

# Update package database
sudo apt update

# Install MongoDB
sudo apt install -y mongodb-org

# Start MongoDB
sudo systemctl start mongod
sudo systemctl enable mongod

# Check MongoDB status
sudo systemctl status mongod
```

### Step 6: Install Git
```bash
sudo apt install -y git
git --version
```

### Step 7: Clone Your Repository
```bash
# First, push your code to GitHub from your local machine
# Then clone it on Ubuntu:
git clone https://github.com/your-username/mailwave.git
cd mailwave
```

### Step 8: Setup Backend
```bash
# Navigate to backend directory
cd backend

# Create .env file
cat > .env << EOF
PORT=5000
MONGODB_URI=mongodb://localhost:27017/newsletter
NODE_ENV=development
EOF

# Install dependencies
npm install

# Start backend server
npm start
```

**Keep this terminal open. Backend should show:**
```
✅ MongoDB connected successfully
🚀 Server running on port 5000
```

### Step 9: Setup Frontend (New Terminal)
```bash
# Open new SSH session or use screen/tmux
# Navigate to frontend directory
cd frontend

# Install dependencies
npm install

# Start frontend
npm start
```

**Frontend will run on port 3000**

### Step 10: Test the Application
```bash
# Open browser and visit:
http://your-ec2-public-ip:3000

# Test backend API:
curl http://your-ec2-public-ip:5000/api/health
```

### Step 11: Add Sample Blog Posts (Optional)

**Option 1: Use Seed Script (Recommended)**
```bash
# Navigate to backend directory
cd backend

# Run seed script to add 12 sample posts
npm run seed
```

**Option 2: Add Single Post via API**
```bash
# Use curl to add a test post
curl -X POST http://localhost:5000/api/posts \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Welcome to Our Newsletter",
    "content": "This is our first blog post. Stay tuned for more updates!",
    "author": "Admin"
  }'
```

---

## 🐳 Phase 2: Dockerization

### Step 1: Install Docker
```bash
# Update package index
sudo apt update

# Install prerequisites
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common

# Add Docker GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Add Docker repository
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io

# Add user to docker group (to run without sudo)
sudo usermod -aG docker $USER

# Apply group changes (logout and login, or run:)
newgrp docker

# Verify Docker installation
docker --version
docker run hello-world
```

### Step 2: Create Backend Dockerfile
```bash
# Navigate to backend directory
cd ~/mailwave/backend

# Create Dockerfile using vim
vim Dockerfile
```

**Press `i` to enter insert mode, then paste:**
```dockerfile
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./

RUN npm install

COPY . .

EXPOSE 5000

CMD ["npm", "start"]
```
**Press `ESC`, type `:wq`, press `ENTER` to save and exit**

### Step 3: Create Frontend Dockerfile
```bash
# Navigate to frontend directory
cd ~/mailwave/frontend

# Create Dockerfile using vim
vim Dockerfile
```

**Press `i` to enter insert mode, then paste:**
```dockerfile
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./

RUN npm install

COPY . .

EXPOSE 3000

CMD ["npm", "start"]
```
**Press `ESC`, type `:wq`, press `ENTER` to save and exit**

### Step 4: Create .dockerignore Files
```bash
# Backend .dockerignore
cd ~/mailwave/backend
vim .dockerignore
```
**Add:**
```
node_modules
npm-debug.log
.env
.git
```

```bash
# Frontend .dockerignore
cd ~/mailwave/frontend
vim .dockerignore
```
**Add:**
```
node_modules
npm-debug.log
build
.git
```

### Step 5: Build Docker Images
```bash
# Build backend image
cd ~/mailwave/backend
docker build -t mailwave-backend .

# Build frontend image
cd ~/mailwave/frontend
docker build -t mailwave-frontend .

# Verify images
docker images
```

### Step 6: Test Individual Containers

**Note:** When running containers individually, they are isolated and cannot communicate with each other by default. This is why we'll use Docker Compose in Phase 3 to put all services on the same network.

```bash
# Create a custom network first (so containers can talk to each other)
docker network create mailwave-network

# Run MongoDB container on the network
docker run -d --name mongodb --network mailwave-network -p 27017:27017 mongo:latest

# Run backend container on the same network
docker run -d --name backend --network mailwave-network -p 5000:5000 \
  -e MONGODB_URI=mongodb://mongodb:27017/newsletter \
  mailwave-backend

# Run frontend container on the same network
docker run -d --name frontend --network mailwave-network -p 3000:3000 \
  -e REACT_APP_API_URL=http://localhost:5000/api \
  mailwave-frontend

# Check running containers
docker ps

# View logs
docker logs backend
docker logs frontend
docker logs mongodb

# Test backend connection
curl http://localhost:5000/api/health
```

### Step 7: Stop and Remove Test Containers
```bash
# Stop containers gracefully
docker stop frontend backend mongodb

# Or force kill if not stopping
docker kill frontend backend mongodb

# Remove containers
docker rm frontend backend mongodb

# Or do it all in one command (kill and remove)
docker rm -f frontend backend mongodb

# Remove the network
docker network rm mailwave-network

# Clean up everything (optional)
docker system prune -a
```

**Important:** Individual containers are isolated. For proper communication between frontend, backend, and MongoDB, we'll use Docker Compose which automatically creates a network for all services.

---

## 🎼 Phase 3: Docker Compose

**Why Docker Compose?**
- Runs all three services (frontend, backend, MongoDB) together
- Automatically creates a network so containers can communicate
- Single command to start/stop everything
- No manual network creation needed
- Services can reference each other by service name

### Step 1: Clean Up Any Existing Containers (Best Practice)

**Before starting Docker Compose, always clean up old containers to avoid conflicts:**

```bash
# Method 1: Kill and remove specific containers
docker kill mailwave-frontend mailwave-backend mailwave-mongodb 2>/dev/null || true
docker rm -f mailwave-frontend mailwave-backend mailwave-mongodb 2>/dev/null || true

# Also remove if you used these names during testing
docker kill frontend backend mongodb 2>/dev/null || true
docker rm -f frontend backend mongodb 2>/dev/null || true

# Method 2: Stop and remove all running containers (use with caution)
docker stop $(docker ps -aq) 2>/dev/null || true
docker rm $(docker ps -aq) 2>/dev/null || true

# Method 3: Clean up all stopped containers
docker container prune -f

# Verify no containers are running
docker ps -a
```

### Step 2: Install Docker Compose
```bash
# Download Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

# Make it executable
sudo chmod +x /usr/local/bin/docker-compose

# Verify installation
docker-compose --version
```

### Step 2: Install Docker Compose
```bash
# Download Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

# Make it executable
sudo chmod +x /usr/local/bin/docker-compose

# Verify installation
docker-compose --version
```

### Step 3: Create docker-compose.yml
```bash
# Navigate to project root
cd ~/your-repo-name

# Create docker-compose.yml using vim
vim docker-compose.yml
```

**Press `i` to enter insert mode, then paste:**
```yaml
version: '3.8'

services:
  mongodb:
    image: mongo:latest
    container_name: newsletter-mongodb
    ports:
      - "27017:27017"
    volumes:
      - mongodb_data:/data/db
    networks:
      - newsletter-network
    healthcheck:
      test: echo 'db.runCommand("ping").ok' | mongosh localhost:27017/test --quiet
      interval: 10s
      timeout: 5s
      retries: 5

  backend:
    build: ./backend
    container_name: newsletter-backend
    ports:
      - "5000:5000"
    environment:
      - PORT=5000
      - MONGODB_URI=mongodb://mongodb:27017/newsletter
      - NODE_ENV=production
    depends_on:
      mongodb:
        condition: service_healthy
    networks:
      - newsletter-network
    restart: unless-stopped

  frontend:
    build: ./frontend
    container_name: newsletter-frontend
    ports:
      - "3000:3000"
    environment:
      - REACT_APP_API_URL=http://localhost:5000/api
    depends_on:
      - backend
    networks:
      - newsletter-network
    restart: unless-stopped

volumes:
  mongodb_data:

networks:
  newsletter-network:
    driver: bridge
```
**Press `ESC`, type `:wq`, press `ENTER` to save and exit**

### Step 3: Create docker-compose.yml
```bash
# Navigate to project root
cd ~/your-repo-name

# Create docker-compose.yml using vim
vim docker-compose.yml
```

**Press `i` to enter insert mode, then paste:**
```yaml
version: '3.8'

services:
  mongodb:
    image: mongo:latest
    container_name: newsletter-mongodb
    ports:
      - "27017:27017"
    volumes:
      - mongodb_data:/data/db
    networks:
      - newsletter-network
    healthcheck:
      test: echo 'db.runCommand("ping").ok' | mongosh localhost:27017/test --quiet
      interval: 10s
      timeout: 5s
      retries: 5

  backend:
    build: ./backend
    container_name: newsletter-backend
    ports:
      - "5000:5000"
    environment:
      - PORT=5000
      - MONGODB_URI=mongodb://mongodb:27017/newsletter
      - NODE_ENV=production
    depends_on:
      mongodb:
        condition: service_healthy
    networks:
      - newsletter-network
    restart: unless-stopped

  frontend:
    build: ./frontend
    container_name: newsletter-frontend
    ports:
      - "3000:3000"
    environment:
      - REACT_APP_API_URL=http://localhost:5000/api
    depends_on:
      - backend
    networks:
      - newsletter-network
    restart: unless-stopped

volumes:
  mongodb_data:

networks:
  newsletter-network:
    driver: bridge
```
**Press `ESC`, type `:wq`, press `ENTER` to save and exit**

### Step 4: Update Frontend for Docker Environment
```bash
cd ~/your-repo-name/frontend

# Create .env file for frontend
vim .env
```
**Add:**
```
REACT_APP_API_URL=http://your-ec2-public-ip:5000/api
```

### Step 4: Update Frontend for Docker Environment
```bash
cd ~/your-repo-name/frontend

# Create .env file for frontend
vim .env
```
**Add:**
```
REACT_APP_API_URL=http://your-ec2-public-ip:5000/api
```

### Step 5: Final Cleanup Before Starting (Best Practice)

**Always do this before running docker-compose:**
```bash
# Navigate to project root
cd ~/mailwave

# Kill any running containers
docker kill $(docker ps -q) 2>/dev/null || true

# Remove all containers
docker rm -f $(docker ps -aq) 2>/dev/null || true

# Remove old networks (optional)
docker network prune -f

# Verify everything is clean
docker ps -a
docker network ls
```

### Step 6: Run with Docker Compose

**Now start all services with Docker Compose:**
```bash
# Build and start all services (first time)
docker-compose up --build -d

# View all running containers
docker-compose ps

# View logs from all services
docker-compose logs -f

# View specific service logs
docker-compose logs -f backend
docker-compose logs -f frontend
docker-compose logs -f mongodb

# Stop viewing logs: Press Ctrl+C
```

**What Docker Compose does automatically:**
- ✅ Creates a network called `mailwave_mailwave-network`
- ✅ Starts MongoDB first (because of `depends_on`)
- ✅ Starts backend after MongoDB is healthy
- ✅ Starts frontend after backend
- ✅ All services can communicate using service names (mongodb, backend, frontend)

### Step 7: Verify Everything is Running
```bash
# Check container status
docker-compose ps

# Test backend health
curl http://localhost:5000/api/health

# Test MongoDB connection
docker exec -it newsletter-mongodb mongosh

# Inside MongoDB shell:
show dbs
use newsletter
show collections
exit
```

### Step 7: Verify Everything is Running
```bash
# Check container status
docker-compose ps

# Should show 3 containers running:
# mailwave-mongodb    Up
# mailwave-backend    Up
# mailwave-frontend   Up

# Test backend health
curl http://localhost:5000/api/health

# Test MongoDB connection
docker exec -it mailwave-mongodb mongosh

# Inside MongoDB shell:
show dbs
use newsletter
show collections
exit
```

### Step 8: Access Application
```
Frontend: http://your-ec2-public-ip:3000
Backend API: http://your-ec2-public-ip:5000/api
```

### Step 8: Access Application
```
Frontend: http://your-ec2-public-ip:3000
Backend API: http://your-ec2-public-ip:5000/api
```

### Step 9: Load Sample Data (Optional)

**Add sample blog posts to your application:**
```bash
# Method 1: Use seed script (adds 12 posts)
docker-compose exec backend npm run seed

# Method 2: Add single post via API
curl -X POST http://localhost:5000/api/posts \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Docker Compose Success",
    "content": "Successfully deployed three-tier app with Docker Compose!",
    "author": "DevOps Engineer"
  }'

# Verify posts were added
curl http://localhost:5000/api/posts
```

### Step 10: Useful Docker Compose Commands
```bash
# Stop all services
docker-compose down

# Stop and remove volumes (deletes data)
docker-compose down -v

# Restart specific service
docker-compose restart backend

# Rebuild specific service after code changes
docker-compose up -d --build backend

# Rebuild all services after code changes
docker-compose up -d --build

# View resource usage
docker stats

# Execute command in container
docker-compose exec backend sh
docker-compose exec mongodb mongosh

# Remove all stopped containers
docker container prune

# Remove all unused images
docker image prune -a
```

---

## 🔄 Rebuilding After Code Changes

### When You Make Changes to Your Code:

**Step 1: Stop and remove old containers**
```bash
# Stop all services
docker-compose down

# Or force remove if needed
docker rm -f newsletter-frontend newsletter-backend newsletter-mongodb
```

**Step 2: Rebuild and restart**
```bash
# Rebuild specific service after code changes
docker-compose up -d --build backend

# Rebuild all services after code changes
docker-compose up -d --build

# Complete fresh start (removes volumes/data too)
docker-compose down -v
docker-compose up --build -d
```

### Quick Rebuild Commands:

**Backend changes only:**
```bash
docker-compose stop backend
docker-compose rm -f backend
docker-compose up -d --build backend
```

**Frontend changes only:**
```bash
docker-compose stop frontend
docker-compose rm -f frontend
docker-compose up -d --build frontend
```

**Both backend and frontend changes:**
```bash
docker-compose down
docker-compose up -d --build backend frontend
```

**Everything including fresh database:**
```bash
docker-compose down -v
docker-compose up --build -d
```

### View Logs After Rebuild:
```bash
# Check if rebuild was successful
docker-compose logs -f backend
docker-compose logs -f frontend

# Check all services
docker-compose ps
```

### Common Issues and Solutions:

**Error: "Container name already in use"**
```bash
# Remove conflicting containers
docker rm -f mailwave-frontend mailwave-backend mailwave-mongodb

# Then rebuild
docker-compose up -d --build
```

**Error: "Network already exists"**
```bash
# Remove old network
docker network rm mailwave-network

# Then rebuild
docker-compose up -d --build
```

**Error: "Port already in use"**
```bash
# Find what's using the port
sudo lsof -i :3000
sudo lsof -i :5000
sudo lsof -i :27017

# Kill the process
sudo kill -9 <PID>

# Or stop all Docker containers
docker stop $(docker ps -aq)
```

**Complete cleanup and fresh start:**
```bash
# Stop everything
docker-compose down -v

# Remove all containers
docker rm -f $(docker ps -aq)

# Remove all images (optional)
docker rmi -f $(docker images -q)

# Remove all networks
docker network prune -f

# Remove all volumes
docker volume prune -f

# Start fresh
docker-compose up --build -d
```

---

## 🧪 Testing the Complete Application

### Test 1: Subscribe to Newsletter
```bash
curl -X POST http://localhost:5000/api/subscribe \
  -H "Content-Type: application/json" \
  -d '{"email": "test@example.com"}'
```

### Test 2: Create Blog Post
```bash
curl -X POST http://localhost:5000/api/posts \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Docker Compose Success",
    "content": "Successfully deployed three-tier app with Docker Compose!",
    "author": "DevOps Engineer"
  }'
```

### Test 3: Get All Posts
```bash
curl http://localhost:5000/api/posts
```

### Test 4: Get All Subscribers
```bash
curl http://localhost:5000/api/subscribers
```

---

## 🔧 Troubleshooting

### Backend can't connect to MongoDB:
```bash
# Check MongoDB is running
docker-compose logs mongodb

# Restart services
docker-compose restart mongodb backend
```

### Frontend can't reach backend:
```bash
# Check backend logs
docker-compose logs backend

# Verify backend is accessible
curl http://localhost:5000/api/health
```

### Port already in use:
```bash
# Find process using port
sudo lsof -i :3000
sudo lsof -i :5000

# Kill process
sudo kill -9 <PID>
```

### Rebuild everything from scratch:
```bash
docker-compose down -v
docker system prune -a
docker-compose up --build -d
```

---

## 📚 Next Steps in DevOps Journey

1. **CI/CD Pipeline** - GitHub Actions, Jenkins
2. **Container Registry** - Docker Hub, AWS ECR
3. **Orchestration** - Kubernetes, Docker Swarm
4. **Monitoring** - Prometheus, Grafana
5. **Logging** - ELK Stack, CloudWatch
6. **Infrastructure as Code** - Terraform, CloudFormation

---

## 🎯 Summary

You've successfully:
- ✅ Created a three-tier application
- ✅ Deployed it on AWS Ubuntu
- ✅ Containerized each service with Docker
- ✅ Orchestrated services with Docker Compose

**Congratulations on completing your DevOps foundation!** 🎉
