# MailWave Setup Instructions

## Prerequisites

### 1. Install Node.js and npm
- Download from: https://nodejs.org/
- Recommended version: Node.js 20.x LTS
- Verify installation:
  ```bash
  node --version
  npm --version
  ```

### 2. Install Docker Desktop
- Download from: https://www.docker.com/products/docker-desktop
- Ensure Docker is running before proceeding

### 3. Install Git
- Download from: https://git-scm.com/downloads
- Verify: `git --version`

## Local Development Setup

### Backend Setup
```bash
cd backend
npm install
npm run dev
```

### Frontend Setup
```bash
cd frontend
npm install
npm start
```

### Full Stack with Docker
```bash
docker-compose up -d
```

## Jenkins Pipeline Requirements

### Jenkins Plugins Required
1. Docker Pipeline
2. SonarQube Scanner
3. OWASP Dependency-Check
4. Email Extension Plugin
5. AWS Credentials Plugin
6. Pipeline Utility Steps

### Jenkins Tools Configuration
1. **SonarQube Scanner**: Configure in Jenkins > Global Tool Configuration
   - Name: `SonarScanner`
   - Install automatically or provide path

2. **OWASP Dependency-Check**: Configure in Jenkins > Global Tool Configuration
   - Name: `DP-Check`
   - Install automatically

3. **Docker**: Ensure Docker is available on Jenkins agent

### Jenkins Credentials
1. **AWS Credentials** (ID: `aws-credentials`)
   - Type: AWS Credentials
   - Access Key ID and Secret Access Key

2. **SonarQube Token** (configured in SonarQube server settings)

### Environment Variables
Set these in Jenkins or your environment:
- `AWS_REGION`: us-east-1
- `AWS_ACCOUNT_ID`: 543927035352

## Common Issues and Solutions

### Issue 1: npm not found
**Solution**: Install Node.js and add to PATH

### Issue 2: Docker build fails
**Solution**: 
- Ensure Docker Desktop is running
- Check Docker daemon is accessible
- Run `docker ps` to verify

### Issue 3: Port already in use
**Solution**:
```bash
# Stop existing containers
docker-compose down
# Or kill specific ports
docker stop $(docker ps -q)
```

### Issue 4: MongoDB connection fails
**Solution**:
- Ensure MongoDB container is healthy
- Check network connectivity: `docker network ls`
- Verify MONGODB_URI in environment

### Issue 5: SonarQube analysis fails
**Solution**:
- Verify SonarQube server is running
- Check sonar-project.properties files
- Ensure SonarScanner is configured in Jenkins

### Issue 6: OWASP check timeout
**Solution**:
- Increase timeout in Jenkinsfile (currently 45 minutes)
- Use `--nvdApiDelay 8000` to avoid rate limiting
- Consider using local NVD database

### Issue 7: Trivy scan fails
**Solution**:
- Install Trivy: https://aquasecurity.github.io/trivy/
- Verify Trivy is in PATH
- Update Trivy database: `trivy image --download-db-only`

### Issue 8: ECR push fails
**Solution**:
- Verify AWS credentials
- Check ECR repository exists
- Ensure proper IAM permissions

## Testing the Application

### Health Checks
```bash
# Backend
curl http://localhost:5000/api/health

# Frontend
curl http://localhost:3000

# MongoDB
docker exec mailwave-mongodb mongosh --eval "db.runCommand('ping')"
```

### API Testing
```bash
# Subscribe to newsletter
curl -X POST http://localhost:5000/api/subscribe \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com"}'

# Get posts
curl http://localhost:5000/api/posts
```

## Deployment Checklist

- [ ] All dependencies installed
- [ ] Docker Desktop running
- [ ] Jenkins configured with required plugins
- [ ] AWS credentials configured
- [ ] SonarQube server accessible
- [ ] ECR repositories created
- [ ] Security groups configured for EC2
- [ ] Environment variables set
- [ ] Health checks passing locally

## Pipeline Stages Overview

1. **Checkout**: Pull code from GitHub
2. **OWASP Dependency Check**: Scan for vulnerable dependencies
3. **SonarQube Analysis**: Code quality and security analysis
4. **Quality Gate**: Verify code meets quality standards
5. **Build Docker Images**: Build backend and frontend containers
6. **Trivy Container Scan**: Scan images for vulnerabilities
7. **Push to ECR**: Upload images to AWS ECR
8. **Deploy to EC2**: Deploy containers to EC2 instance

## Monitoring

### Container Logs
```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f backend
docker-compose logs -f frontend
docker-compose logs -f mongodb
```

### Container Status
```bash
docker-compose ps
docker stats
```

## Cleanup

### Stop all services
```bash
docker-compose down
```

### Remove all data
```bash
docker-compose down -v
```

### Clean Docker system
```bash
docker system prune -a -f
```
