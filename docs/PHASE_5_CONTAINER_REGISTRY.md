# 📦 Phase 5: Container Registry (Docker Hub & AWS ECR)

## Why Container Registry?
- Share images across teams and environments
- Version control for Docker images
- Faster deployments (no rebuild needed)
- Industry standard practice

---

## Part A: Docker Hub

### Step 1: Create Docker Hub Account
1. Go to https://hub.docker.com
2. Sign up for a free account
3. Verify your email

### Step 2: Login to Docker Hub
```bash
# On your Ubuntu server
docker login
# Enter your Docker Hub username and password
```

### Step 3: Tag Your Images
```bash
# Replace YOUR_DOCKERHUB_USERNAME with your actual username

# Tag backend image
docker tag mailwave-backend YOUR_DOCKERHUB_USERNAME/mailwave-backend:v1.0
docker tag mailwave-backend YOUR_DOCKERHUB_USERNAME/mailwave-backend:latest

# Tag frontend image
docker tag mailwave-frontend YOUR_DOCKERHUB_USERNAME/mailwave-frontend:v1.0
docker tag mailwave-frontend YOUR_DOCKERHUB_USERNAME/mailwave-frontend:latest

# View tagged images
docker images
```

### Step 4: Push Images to Docker Hub
```bash
# Push backend
docker push YOUR_DOCKERHUB_USERNAME/mailwave-backend:v1.0
docker push YOUR_DOCKERHUB_USERNAME/mailwave-backend:latest

# Push frontend
docker push YOUR_DOCKERHUB_USERNAME/mailwave-frontend:v1.0
docker push YOUR_DOCKERHUB_USERNAME/mailwave-frontend:latest

# Check on Docker Hub website - your images should be visible
```

### Step 5: Create docker-compose.hub.yml
