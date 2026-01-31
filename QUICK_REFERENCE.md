# Quick Reference Card

## 🚀 Quick Start Commands

### Windows (PowerShell)
```powershell
# Troubleshoot
.\troubleshoot.ps1

# Install dependencies
.\quick-start.ps1 -Install

# Start services
.\quick-start.ps1 -Start

# Check status
.\quick-start.ps1 -Status

# View logs
.\quick-start.ps1 -Logs

# Stop services
.\quick-start.ps1 -Stop

# Clean everything
.\quick-start.ps1 -Clean
```

### Linux/Mac (Bash)
```bash
# Make scripts executable (first time only)
chmod +x *.sh

# Troubleshoot
./troubleshoot.sh

# Validate pipeline
./validate-pipeline.sh

# Install dependencies
./quick-start.sh install

# Start services
./quick-start.sh start

# Check status
./quick-start.sh status

# View logs
./quick-start.sh logs

# Stop services
./quick-start.sh stop

# Clean everything
./quick-start.sh clean
```

## 🐳 Docker Commands

### Basic Operations
```bash
# Build images
docker-compose build

# Start services
docker-compose up -d

# Stop services
docker-compose down

# Stop and remove volumes
docker-compose down -v

# View logs
docker-compose logs -f

# View specific service logs
docker-compose logs -f backend

# Check status
docker-compose ps

# Restart service
docker-compose restart backend
```

### Cleanup
```bash
# Stop all containers
docker stop $(docker ps -aq)

# Remove all containers
docker rm $(docker ps -aq)

# Remove all images
docker rmi $(docker images -q)

# Clean system
docker system prune -a -f

# Remove specific containers
docker rm -f mailwave-backend mailwave-frontend mailwave-mongodb
```

### Debugging
```bash
# Execute command in container
docker exec -it mailwave-backend sh

# View container logs
docker logs mailwave-backend

# Inspect container
docker inspect mailwave-backend

# Check resource usage
docker stats

# View networks
docker network ls

# View volumes
docker volume ls
```

## 🔍 Health Checks

### Backend
```bash
curl http://localhost:5000/api/health
```

### Frontend
```bash
curl http://localhost:3000
```

### MongoDB
```bash
docker exec mailwave-mongodb mongosh --eval "db.runCommand('ping')"
```

### All Services
```bash
docker-compose ps
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

## 📊 API Testing

### Subscribe to Newsletter
```bash
curl -X POST http://localhost:5000/api/subscribe \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com"}'
```

### Create Blog Post
```bash
curl -X POST http://localhost:5000/api/posts \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Test Post",
    "content": "This is a test post",
    "author": "Admin"
  }'
```

### Get All Posts
```bash
curl http://localhost:5000/api/posts
```

### Get All Subscribers
```bash
curl http://localhost:5000/api/subscribers
```

## 🔧 Jenkins Commands

### Pipeline Triggers
```bash
# Trigger build via CLI (if configured)
java -jar jenkins-cli.jar -s http://jenkins-url:8080/ build MailWave-Pipeline

# Or use curl
curl -X POST http://jenkins-url:8080/job/MailWave-Pipeline/build \
  --user username:token
```

### View Build Status
```bash
# Get last build status
curl http://jenkins-url:8080/job/MailWave-Pipeline/lastBuild/api/json
```

## ☁️ AWS Commands

### ECR Login
```bash
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin \
  YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com
```

### List ECR Repositories
```bash
aws ecr describe-repositories --region us-east-1
```

### List Images in Repository
```bash
aws ecr list-images \
  --repository-name mailwave-backend \
  --region us-east-1
```

### Delete Image
```bash
aws ecr batch-delete-image \
  --repository-name mailwave-backend \
  --image-ids imageTag=latest \
  --region us-east-1
```

### EC2 Connection
```bash
ssh -i your-key.pem ubuntu@your-ec2-ip
```

## 🔒 Security Scans

### Trivy Scan
```bash
# Scan image
trivy image mailwave-backend:latest

# Scan with severity filter
trivy image --severity HIGH,CRITICAL mailwave-backend:latest

# Output to file
trivy image --format json --output report.json mailwave-backend:latest
```

### OWASP Dependency Check
```bash
# Scan directory
dependency-check --scan ./backend --format HTML --out reports/
```

## 📝 Git Commands

### Basic Operations
```bash
# Check status
git status

# Add all changes
git add .

# Commit changes
git commit -m "Your message"

# Push to GitHub
git push origin main

# Pull latest changes
git pull origin main

# View commit history
git log --oneline
```

### Branch Operations
```bash
# Create new branch
git checkout -b feature-name

# Switch branch
git checkout main

# Merge branch
git merge feature-name

# Delete branch
git branch -d feature-name
```

## 🗄️ MongoDB Commands

### Connect to MongoDB
```bash
docker exec -it mailwave-mongodb mongosh
```

### Inside MongoDB Shell
```javascript
// Show databases
show dbs

// Use database
use newsletter

// Show collections
show collections

// Find all posts
db.posts.find()

// Find all subscribers
db.subscribers.find()

// Count documents
db.posts.countDocuments()

// Delete all posts
db.posts.deleteMany({})

// Exit
exit
```

## 📦 NPM Commands

### Backend
```bash
cd backend

# Install dependencies
npm install

# Start server
npm start

# Development mode
npm run dev

# Run tests
npm test

# Seed database
npm run seed
```

### Frontend
```bash
cd frontend

# Install dependencies
npm install

# Start development server
npm start

# Build for production
npm run build

# Run tests
npm test
```

## 🔍 Troubleshooting Quick Fixes

### Port Already in Use
```bash
# Find process using port
# Windows
netstat -ano | findstr :3000

# Linux/Mac
lsof -i :3000

# Kill process
# Windows
taskkill /PID <PID> /F

# Linux/Mac
kill -9 <PID>
```

### Docker Daemon Not Running
```bash
# Windows/Mac: Start Docker Desktop

# Linux
sudo systemctl start docker
sudo systemctl enable docker
```

### Permission Denied
```bash
# Add user to docker group
sudo usermod -aG docker $USER

# Apply changes
newgrp docker

# Or logout and login again
```

### Container Won't Stop
```bash
# Force kill
docker kill mailwave-backend

# Force remove
docker rm -f mailwave-backend
```

### Out of Disk Space
```bash
# Check disk usage
docker system df

# Clean up
docker system prune -a -f

# Remove unused volumes
docker volume prune -f
```

## 📚 Documentation Files

| File | Purpose |
|------|---------|
| `README.md` | Main project documentation |
| `SETUP_INSTRUCTIONS.md` | Complete setup guide |
| `JENKINS_SETUP.md` | Jenkins configuration guide |
| `PIPELINE_FIXES_SUMMARY.md` | Summary of all fixes |
| `PRE_DEPLOYMENT_CHECKLIST.md` | Deployment checklist |
| `QUICK_REFERENCE.md` | This file - quick commands |

## 🌐 Important URLs

### Local Development
- Frontend: http://localhost:3000
- Backend: http://localhost:5000
- Backend Health: http://localhost:5000/api/health
- MongoDB: mongodb://localhost:27017

### Production (Replace with your IPs)
- Frontend: http://your-ec2-ip:3000
- Backend: http://your-ec2-ip:5000
- Jenkins: http://your-jenkins-ip:8080
- SonarQube: http://your-sonarqube-ip:9000

## 🆘 Emergency Commands

### Complete Reset
```bash
# Stop everything
docker-compose down -v
docker stop $(docker ps -aq)
docker rm $(docker ps -aq)

# Clean Docker
docker system prune -a -f
docker volume prune -f
docker network prune -f

# Rebuild from scratch
docker-compose up --build -d
```

### Backup Data
```bash
# Backup MongoDB
docker exec mailwave-mongodb mongodump --out /backup

# Copy backup from container
docker cp mailwave-mongodb:/backup ./mongodb-backup
```

### Restore Data
```bash
# Copy backup to container
docker cp ./mongodb-backup mailwave-mongodb:/backup

# Restore MongoDB
docker exec mailwave-mongodb mongorestore /backup
```

## 📞 Getting Help

1. **Check logs first**
   ```bash
   docker-compose logs -f
   ```

2. **Run troubleshooting script**
   ```bash
   ./troubleshoot.sh  # or troubleshoot.ps1
   ```

3. **Check documentation**
   - SETUP_INSTRUCTIONS.md
   - JENKINS_SETUP.md
   - README.md

4. **Validate configuration**
   ```bash
   ./validate-pipeline.sh
   ```

5. **Check container health**
   ```bash
   docker ps
   docker-compose ps
   ```

## 🎯 Common Workflows

### Daily Development
```bash
# Start services
docker-compose up -d

# Make code changes
# ...

# Restart affected service
docker-compose restart backend

# View logs
docker-compose logs -f backend

# Stop when done
docker-compose down
```

### Testing Changes
```bash
# Stop services
docker-compose down

# Rebuild with changes
docker-compose up --build -d

# Test
curl http://localhost:5000/api/health

# View logs
docker-compose logs -f
```

### Deploying to Production
```bash
# Commit changes
git add .
git commit -m "Your changes"
git push origin main

# Jenkins will automatically:
# 1. Run security scans
# 2. Build images
# 3. Push to ECR
# 4. Deploy to EC2
```

---

**Pro Tip:** Bookmark this file for quick access to common commands! 🚀
