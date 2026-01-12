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

The `docker-compose.yml` file is already in your repository. Just pull it:

```bash
cd ~/mailwave
git pull origin main
```

**Or create it manually using this command:**
```bash
cd ~/mailwave
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  mongodb:
    image: mongo:latest
    container_name: mailwave-mongodb
    ports:
      - "27017:27017"
    volumes:
      - mongodb_data:/data/db
    networks:
      - mailwave-network
    healthcheck:
      test: echo 'db.runCommand("ping").ok' | mongosh localhost:27017/test --quiet
      interval: 10s
      timeout: 5s
      retries: 5

  backend:
    build: ./backend
    container_name: mailwave-backend
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
      - mailwave-network
    restart: unless-stopped

  frontend:
    build: ./frontend
    container_name: mailwave-frontend
    ports:
      - "3000:3000"
    environment:
      - REACT_APP_API_URL=http://YOUR_EC2_PUBLIC_IP:5000/api
    depends_on:
      - backend
    networks:
      - mailwave-network
    restart: unless-stopped

volumes:
  mongodb_data:

networks:
  mailwave-network:
    driver: bridge
EOF
```

**Important:** Replace `YOUR_EC2_PUBLIC_IP` with your actual EC2 public IP in the docker-compose.yml file.

### Step 4: Update Frontend Environment Variable
```bash
cd ~/mailwave/frontend

# Create .env file with your EC2 public IP
echo "REACT_APP_API_URL=http://YOUR_EC2_PUBLIC_IP:5000/api" > .env
```

**Replace `YOUR_EC2_PUBLIC_IP` with your actual IP address.**

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

# Should show 3 containers running:
# mailwave-mongodb    Up
# mailwave-backend    Up
# mailwave-frontend   Up

# Test backend health
curl http://localhost:5000/api/health

# Test MongoDB connection
sudo docker exec -it mailwave-mongodb mongosh

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

### Step 9: Load Sample Data (Optional)

**Add sample blog posts to your application:**
```bash
# Method 1: Use seed script (adds 12 posts)
sudo docker-compose exec backend npm run seed

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
# Stop all services (keeps data)
sudo docker-compose down

# Stop and remove volumes (deletes data)
sudo docker-compose down -v

# Start services
sudo docker-compose up -d

# Restart after code changes
sudo docker-compose down
sudo docker-compose up --build -d

# Restart specific service
sudo docker-compose restart backend

# View logs
sudo docker-compose logs -f
sudo docker-compose logs -f backend

# View resource usage
sudo docker stats

# Execute command in container
sudo docker-compose exec backend sh
sudo docker-compose exec mongodb mongosh
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

## 🏗️ Phase 4: Production Fundamentals

Transform your application from a demo to production-ready with testing, security, and proper architecture.

### What You'll Learn:
- ✅ Automated testing (Unit + Integration)
- ✅ Architecture documentation
- ✅ Secrets management with AWS
- ✅ Multi-environment configuration
- ✅ Health checks and monitoring
- ✅ Logging best practices

### Step 1: Add Testing to Backend

**Install testing dependencies:**
```bash
cd backend
npm install --save-dev jest supertest
```

**Create test file `backend/tests/api.test.js`:**
```javascript
const request = require('supertest');
const express = require('express');

// Mock app for testing
const app = express();
app.use(express.json());

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.json({ status: 'OK', message: 'Backend is running' });
});

describe('API Tests', () => {
  test('GET /api/health should return 200', async () => {
    const response = await request(app).get('/api/health');
    expect(response.status).toBe(200);
    expect(response.body.status).toBe('OK');
  });
});
```

**Update `backend/package.json` to add test script:**
```json
"scripts": {
  "start": "node server.js",
  "dev": "nodemon server.js",
  "seed": "node scripts/seed.js",
  "test": "jest --coverage"
}
```

**Run tests:**
```bash
npm test
```

### Step 2: Add Testing to Frontend

**Install testing dependencies:**
```bash
cd frontend
npm install --save-dev @testing-library/react @testing-library/jest-dom @testing-library/user-event
```

**Create test file `frontend/src/App.test.js`:**
```javascript
import { render, screen } from '@testing-library/react';
import App from './App';

test('renders MailWave heading', () => {
  render(<App />);
  const headingElement = screen.getByText(/MailWave/i);
  expect(headingElement).toBeInTheDocument();
});

test('renders subscribe section', () => {
  render(<App />);
  const subscribeElement = screen.getByText(/Subscribe to Our Newsletter/i);
  expect(subscribeElement).toBeInTheDocument();
});
```

**Run tests:**
```bash
npm test
```

### Step 3: Architecture Documentation

**Create `docs/architecture.md`:**
```markdown
# MailWave Architecture

## System Overview
Three-tier web application with React frontend, Node.js backend, and MongoDB database.

## Components

### Frontend (Port 3000)
- React SPA
- Axios for API calls
- Responsive UI

### Backend (Port 5000)
- Node.js + Express
- RESTful API
- Mongoose ODM

### Database (Port 27017)
- MongoDB
- Collections: posts, subscribers

## Network Architecture
- All services run in Docker containers
- Connected via custom bridge network
- Exposed ports for external access

## Data Flow
1. User interacts with React frontend
2. Frontend makes API calls to backend
3. Backend processes requests and queries MongoDB
4. Response flows back to frontend
5. UI updates with data
```

**Create architecture diagram** (you can use draw.io, Lucidchart, or ASCII):
```
┌─────────────────┐
│   Browser       │
└────────┬────────┘
         │ HTTP
         ▼
┌─────────────────┐
│  Frontend       │
│  (React:3000)   │
└────────┬────────┘
         │ API Calls
         ▼
┌─────────────────┐
│  Backend        │
│  (Node.js:5000) │
└────────┬────────┘
         │ Mongoose
         ▼
┌─────────────────┐
│  MongoDB        │
│  (Port 27017)   │
└─────────────────┘
```

### Step 4: Secrets Management with AWS

**Install AWS CLI on your EC2:**
```bash
# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
sudo apt install unzip
unzip awscliv2.zip
sudo ./aws/install

# Verify installation
aws --version

# Configure AWS credentials
aws configure
```

**Store secrets in AWS Systems Manager Parameter Store:**
```bash
# Store MongoDB URI
aws ssm put-parameter \
  --name "/mailwave/prod/mongodb-uri" \
  --value "mongodb://mongodb:27017/newsletter" \
  --type "SecureString" \
  --region us-east-1

# Store JWT secret (if you add authentication later)
aws ssm put-parameter \
  --name "/mailwave/prod/jwt-secret" \
  --value "your-secret-key-here" \
  --type "SecureString" \
  --region us-east-1
```

**Update backend to fetch secrets:**
```bash
cd backend
npm install aws-sdk
```

**Create `backend/config/secrets.js`:**
```javascript
const AWS = require('aws-sdk');
const ssm = new AWS.SSM({ region: 'us-east-1' });

async function getParameter(name) {
  try {
    const result = await ssm.getParameter({
      Name: name,
      WithDecryption: true
    }).promise();
    return result.Parameter.Value;
  } catch (error) {
    console.error(`Error fetching parameter ${name}:`, error);
    return null;
  }
}

module.exports = { getParameter };
```

### Step 5: Multi-Environment Configuration

**Create environment-specific docker-compose files:**

**`docker-compose.dev.yml`** (Development):
```yaml
version: '3.8'

services:
  mongodb:
    image: mongo:latest
    container_name: mailwave-mongodb-dev
    ports:
      - "27017:27017"
    volumes:
      - mongodb_data_dev:/data/db
    networks:
      - mailwave-network-dev

  backend:
    build: ./backend
    container_name: mailwave-backend-dev
    ports:
      - "5000:5000"
    environment:
      - PORT=5000
      - MONGODB_URI=mongodb://mongodb:27017/newsletter_dev
      - NODE_ENV=development
    depends_on:
      - mongodb
    networks:
      - mailwave-network-dev
    volumes:
      - ./backend:/app
      - /app/node_modules

  frontend:
    build: ./frontend
    container_name: mailwave-frontend-dev
    ports:
      - "3000:3000"
    environment:
      - REACT_APP_API_URL=http://localhost:5000/api
    depends_on:
      - backend
    networks:
      - mailwave-network-dev
    volumes:
      - ./frontend:/app
      - /app/node_modules

volumes:
  mongodb_data_dev:

networks:
  mailwave-network-dev:
    driver: bridge
```

**`docker-compose.prod.yml`** (Production):
```yaml
version: '3.8'

services:
  mongodb:
    image: mongo:latest
    container_name: mailwave-mongodb-prod
    ports:
      - "27017:27017"
    volumes:
      - mongodb_data_prod:/data/db
    networks:
      - mailwave-network-prod
    restart: always

  backend:
    build: ./backend
    container_name: mailwave-backend-prod
    ports:
      - "5000:5000"
    environment:
      - PORT=5000
      - MONGODB_URI=mongodb://mongodb:27017/newsletter_prod
      - NODE_ENV=production
    depends_on:
      - mongodb
    networks:
      - mailwave-network-prod
    restart: always

  frontend:
    build: ./frontend
    container_name: mailwave-frontend-prod
    ports:
      - "3000:3000"
    environment:
      - REACT_APP_API_URL=http://YOUR_EC2_IP:5000/api
    depends_on:
      - backend
    networks:
      - mailwave-network-prod
    restart: always

volumes:
  mongodb_data_prod:

networks:
  mailwave-network-prod:
    driver: bridge
```

**Run specific environment:**
```bash
# Development
docker-compose -f docker-compose.dev.yml up -d

# Production
docker-compose -f docker-compose.prod.yml up -d
```

### Step 6: Health Checks and Monitoring

**Update `backend/server.js` with enhanced health check:**
```javascript
// Enhanced health check endpoint
app.get('/api/health', async (req, res) => {
  const healthCheck = {
    uptime: process.uptime(),
    message: 'OK',
    timestamp: Date.now(),
    environment: process.env.NODE_ENV,
    database: 'disconnected'
  };

  try {
    // Check MongoDB connection
    if (mongoose.connection.readyState === 1) {
      healthCheck.database = 'connected';
    }
    res.status(200).json(healthCheck);
  } catch (error) {
    healthCheck.message = error.message;
    res.status(503).json(healthCheck);
  }
});

// Readiness probe
app.get('/api/ready', async (req, res) => {
  if (mongoose.connection.readyState === 1) {
    res.status(200).json({ status: 'ready' });
  } else {
    res.status(503).json({ status: 'not ready' });
  }
});

// Liveness probe
app.get('/api/live', (req, res) => {
  res.status(200).json({ status: 'alive' });
});
```

**Add logging middleware:**
```javascript
// Request logging middleware
app.use((req, res, next) => {
  const start = Date.now();
  res.on('finish', () => {
    const duration = Date.now() - start;
    console.log(`${req.method} ${req.path} ${res.statusCode} ${duration}ms`);
  });
  next();
});
```

**Update docker-compose.yml with health checks:**
```yaml
backend:
  build: ./backend
  container_name: mailwave-backend
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
    - mailwave-network
  restart: unless-stopped
  healthcheck:
    test: ["CMD", "curl", "-f", "http://localhost:5000/api/health"]
    interval: 30s
    timeout: 10s
    retries: 3
    start_period: 40s
```

### Step 7: Centralized Logging

**Create `backend/utils/logger.js`:**
```javascript
const winston = require('winston');

const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [
    new winston.transports.File({ filename: 'logs/error.log', level: 'error' }),
    new winston.transports.File({ filename: 'logs/combined.log' }),
    new winston.transports.Console({
      format: winston.format.simple()
    })
  ]
});

module.exports = logger;
```

**Install winston:**
```bash
cd backend
npm install winston
```

**Use logger in your code:**
```javascript
const logger = require('./utils/logger');

// Replace console.log with logger
logger.info('Server started on port 5000');
logger.error('Database connection failed', { error: err.message });
```

### Step 8: Testing the Production Setup

**Run all tests:**
```bash
# Backend tests
cd backend
npm test

# Frontend tests
cd frontend
npm test
```

**Test health endpoints:**
```bash
# Health check
curl http://localhost:5000/api/health

# Readiness probe
curl http://localhost:5000/api/ready

# Liveness probe
curl http://localhost:5000/api/live
```

**Test multi-environment setup:**
```bash
# Start development environment
docker-compose -f docker-compose.dev.yml up -d

# Verify
docker ps

# Stop development
docker-compose -f docker-compose.dev.yml down

# Start production environment
docker-compose -f docker-compose.prod.yml up -d
```

---

## 🚀 Next Steps: Complete DevSecOps Pipeline (10 Weeks)

You've completed the foundation! Now build an **industry-standard DevSecOps pipeline**.

### 🎯 What You'll Build

**Complete CI/CD Pipeline with Security:**
```
GitHub → Jenkins → SonarQube → OWASP → Trivy → Docker → AWS ECR → EKS
```

### 📅 10-Week Learning Path

| Week | Focus | What You'll Learn |
|------|-------|-------------------|
| **1-2** | **Jenkins CI/CD** | Pipeline automation, AWS ECR integration |
| **3** | **SonarQube** | Code quality analysis, quality gates |
| **4** | **OWASP** | Dependency vulnerability scanning |
| **5** | **Trivy** | Container security scanning |
| **6** | **Integration** | Complete DevSecOps pipeline |
| **7-8** | **Monitoring** | Prometheus + Grafana observability |
| **9-10** | **AWS EKS** | Production Kubernetes deployment |

### 🛠️ Tools You'll Master

- ✅ **Jenkins** - CI/CD orchestration
- ✅ **SonarQube** - Code quality analysis
- ✅ **OWASP Dependency-Check** - Security scanning
- ✅ **Trivy** - Container vulnerability scanning
- ✅ **AWS ECR** - Container registry
- ✅ **Prometheus + Grafana** - Monitoring
- ✅ **AWS EKS** - Kubernetes

---

## 📖 Complete DevSecOps Guide

**👉 Start Here: [docs/README.md](./docs/README.md)**

This comprehensive guide includes:
- ✅ Step-by-step instructions for each week
- ✅ Complete code examples and configurations
- ✅ Troubleshooting sections
- ✅ Checklists to track progress
- ✅ Best practices for 2026

**Quick Links:**
- [Week 1-2: Jenkins Setup](./docs/WEEK_1_2_JENKINS.md) ← **Start here!**
- [Week 3: SonarQube](./docs/WEEK_3_SONARQUBE.md)
- [Week 4: OWASP](./docs/WEEK_4_OWASP.md)
- [Week 5: Trivy](./docs/WEEK_5_TRIVY.md)
- [Week 6: Integration](./docs/WEEK_6_INTEGRATION.md)
- [Week 7-8: Monitoring](./docs/WEEK_7_8_MONITORING.md)
- [Week 9-10: EKS](./docs/WEEK_9_10_EKS.md)

---

## 🎯 Current Progress

**Completed:**
- ✅ Phase 1: Local Testing on AWS Ubuntu
- ✅ Phase 2: Dockerization
- ✅ Phase 3: Docker Compose Orchestration

**Next Up:**
- 🎯 **Week 1-2: Jenkins CI/CD Pipeline** ← Start here!

**Timeline:** 10 weeks to complete DevSecOps mastery  
**Target:** Ready for DevSecOps roles in 2026! 🚀

---

## 🎉 What You've Built So Far

You've successfully created a production-ready three-tier application:
- ✅ React frontend
- ✅ Node.js/Express backend
- ✅ MongoDB database
- ✅ Docker containerization
- ✅ Docker Compose orchestration

**Now add enterprise-grade CI/CD, security, and monitoring!**
