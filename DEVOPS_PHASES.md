# 🚀 DevOps Journey - Advanced Phases

This document contains detailed step-by-step instructions for Phases 5-10 of your DevOps learning journey.

---

## 📦 Phase 5: Container Registry (Docker Hub & AWS ECR)

### Why Container Registry?
- Share images across teams and environments
- Version control for Docker images
- Faster deployments (no rebuild needed)
- Industry standard practice

### Part A: Docker Hub

#### Step 1: Create Docker Hub Account
1. Go to https://hub.docker.com
2. Sign up for a free account
3. Verify your email

#### Step 2: Login to Docker Hub from Terminal
```bash
# On your Ubuntu server
docker login

# Enter your Docker Hub username and password
```

#### Step 3: Tag Your Images
```bash
# Tag backend image
docker tag mailwave-backend YOUR_DOCKERHUB_USERNAME/mailwave-backend:v1.0
docker tag mailwave-backend YOUR_DOCKERHUB_USERNAME/mailwave-backend:latest

# Tag frontend image
docker tag mailwave-frontend YOUR_DOCKERHUB_USERNAME/mailwave-frontend:v1.0
docker tag mailwave-frontend YOUR_DOCKERHUB_USERNAME/mailwave-frontend:latest

# View tagged images
docker images
```

#### Step 4: Push Images to Docker Hub
```bash
# Push backend
docker push YOUR_DOCKERHUB_USERNAME/mailwave-backend:v1.0
docker push YOUR_DOCKERHUB_USERNAME/mailwave-backend:latest

# Push frontend
docker push YOUR_DOCKERHUB_USERNAME/mailwave-frontend:v1.0
docker push YOUR_DOCKERHUB_USERNAME/mailwave-frontend:latest
```

#### Step 5: Update docker-compose.yml to Use Remote Images

Create `docker-compose.hub.yml`:
```yaml
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

  backend:
    image: YOUR_DOCKERHUB_USERNAME/mailwave-backend:latest
    container_name: mailwave-backend
    ports:
      - "5000:5000"
    environment:
      - PORT=5000
      - MONGODB_URI=mongodb://mongodb:27017/newsletter
      - NODE_ENV=production
    depends_on:
      - mongodb
    networks:
      - mailwave-network
    restart: unless-stopped

  frontend:
    image: YOUR_DOCKERHUB_USERNAME/mailwave-frontend:latest
    container_name: mailwave-frontend
    ports:
      - "3000:3000"
    environment:
      - REACT_APP_API_URL=http://YOUR_EC2_IP:5000/api
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
```

#### Step 6: Test Pulling from Docker Hub
```bash
# Stop current containers
sudo docker-compose down

# Remove local images (to test pull)
docker rmi mailwave-backend mailwave-frontend

# Start using Docker Hub images
sudo docker-compose -f docker-compose.hub.yml up -d

# Verify it's pulling from Docker Hub
sudo docker-compose logs -f
```

### Part B: AWS ECR (Elastic Container Registry)

#### Step 1: Install AWS CLI
```bash
# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
sudo apt install unzip
unzip awscliv2.zip
sudo ./aws/install

# Verify installation
aws --version
```

#### Step 2: Configure AWS CLI
```bash
# Configure AWS credentials
aws configure

# Enter:
# AWS Access Key ID: [Your Access Key]
# AWS Secret Access Key: [Your Secret Key]
# Default region: us-east-1 (or your preferred region)
# Default output format: json
```

#### Step 3: Create ECR Repositories
```bash
# Create backend repository
aws ecr create-repository --repository-name mailwave-backend --region us-east-1

# Create frontend repository
aws ecr create-repository --repository-name mailwave-frontend --region us-east-1

# List repositories
aws ecr describe-repositories --region us-east-1
```
