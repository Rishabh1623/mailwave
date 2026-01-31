# Pre-Deployment Checklist

Use this checklist before running your Jenkins pipeline to ensure everything is configured correctly.

## ✅ Local Environment

### Prerequisites Installed
- [ ] Node.js (v18 or v20) installed
- [ ] npm installed and working
- [ ] Docker Desktop installed and running
- [ ] Docker Compose installed
- [ ] Git installed

### Verify Installation
```bash
# Run troubleshooting script
# Windows:
.\troubleshoot.ps1

# Linux/Mac:
./troubleshoot.sh
```

Expected output: All tools should show ✅

## ✅ Project Files

### Required Files Present
- [ ] Jenkinsfile exists
- [ ] Jenkinsfile.production exists
- [ ] docker-compose.yml exists
- [ ] backend/Dockerfile exists
- [ ] frontend/Dockerfile exists
- [ ] backend/package.json exists
- [ ] frontend/package.json exists
- [ ] backend/package-lock.json exists
- [ ] .dockerignore exists

### Configuration Files
- [ ] backend/sonar-project.properties exists
- [ ] frontend/sonar-project.properties exists
- [ ] backend/.env.example exists
- [ ] frontend/nginx.conf exists

## ✅ Local Testing

### Install Dependencies
```bash
# Windows:
.\quick-start.ps1 -Install

# Linux/Mac:
./quick-start.sh install
```

- [ ] Backend dependencies installed successfully
- [ ] Frontend dependencies installed successfully
- [ ] No npm errors

### Build Docker Images
```bash
# Test backend build
docker build -t mailwave-backend:test ./backend

# Test frontend build
docker build -t mailwave-frontend:test ./frontend
```

- [ ] Backend image builds without errors
- [ ] Frontend image builds without errors

### Start Services Locally
```bash
# Windows:
.\quick-start.ps1 -Start

# Linux/Mac:
./quick-start.sh start
```

- [ ] All containers start successfully
- [ ] No port conflicts
- [ ] MongoDB is healthy
- [ ] Backend is healthy
- [ ] Frontend is healthy

### Test Endpoints
```bash
# Backend health
curl http://localhost:5000/api/health

# Frontend
curl http://localhost:3000

# Test API
curl -X POST http://localhost:5000/api/subscribe \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com"}'
```

- [ ] Backend health check returns 200 OK
- [ ] Frontend loads successfully
- [ ] API endpoints work correctly

### Check Logs
```bash
# Windows:
.\quick-start.ps1 -Logs

# Linux/Mac:
./quick-start.sh logs
```

- [ ] No error messages in logs
- [ ] MongoDB connected successfully
- [ ] Backend server running
- [ ] Frontend serving correctly

## ✅ Jenkins Setup

### Jenkins Installation
- [ ] Jenkins installed and running
- [ ] Jenkins accessible via browser
- [ ] Admin account created

### Required Plugins Installed
- [ ] Docker Pipeline
- [ ] SonarQube Scanner
- [ ] OWASP Dependency-Check
- [ ] Email Extension Plugin
- [ ] AWS Credentials Plugin
- [ ] Pipeline Utility Steps
- [ ] Blue Ocean (optional)

### Tool Configuration
- [ ] SonarQube Scanner configured (name: `SonarScanner`)
- [ ] OWASP Dependency-Check configured (name: `DP-Check`)
- [ ] Docker available on Jenkins agent

### Credentials Configured
- [ ] AWS credentials added (ID: `aws-credentials`)
- [ ] SonarQube token added
- [ ] GitHub credentials added (if private repo)
- [ ] Email credentials added

## ✅ SonarQube Setup

### SonarQube Server
- [ ] SonarQube server installed and running
- [ ] SonarQube accessible via browser
- [ ] Admin password changed from default

### SonarQube Configuration
- [ ] SonarQube server configured in Jenkins
- [ ] Authentication token generated
- [ ] Token added to Jenkins credentials
- [ ] Test connection successful

### Project Configuration
- [ ] backend/sonar-project.properties configured
- [ ] frontend/sonar-project.properties configured
- [ ] Project keys are unique

## ✅ AWS Setup

### AWS CLI
- [ ] AWS CLI installed on Jenkins agent
- [ ] AWS CLI installed on EC2 instance
- [ ] AWS credentials configured

### AWS Credentials
```bash
# Test AWS credentials
aws sts get-caller-identity
```

- [ ] AWS credentials working
- [ ] Correct AWS account ID
- [ ] Correct region (us-east-1)

### ECR Repositories
```bash
# Check ECR repositories
aws ecr describe-repositories --region us-east-1
```

- [ ] mailwave-backend repository exists
- [ ] mailwave-frontend repository exists
- [ ] Repositories in correct region

### Create ECR Repositories (if needed)
```bash
# Create backend repository
aws ecr create-repository \
    --repository-name mailwave-backend \
    --region us-east-1

# Create frontend repository
aws ecr create-repository \
    --repository-name mailwave-frontend \
    --region us-east-1
```

## ✅ EC2 Instance Setup

### EC2 Instance
- [ ] EC2 instance launched (Ubuntu 22.04 LTS)
- [ ] Instance type: t2.medium or larger
- [ ] Instance is running
- [ ] Public IP assigned

### Security Group Rules
- [ ] Port 22 (SSH) - Your IP
- [ ] Port 80 (HTTP) - Anywhere
- [ ] Port 3000 (Frontend) - Anywhere
- [ ] Port 5000 (Backend) - Anywhere
- [ ] Port 9000 (SonarQube) - Your IP
- [ ] Port 27017 (MongoDB) - Localhost only

### EC2 Software Installation
```bash
# Connect to EC2
ssh -i your-key.pem ubuntu@your-ec2-ip

# Check installations
docker --version
docker-compose --version
aws --version
```

- [ ] Docker installed on EC2
- [ ] Docker Compose installed on EC2
- [ ] AWS CLI installed on EC2
- [ ] User added to docker group

### EC2 AWS Configuration
```bash
# On EC2 instance
aws configure
```

- [ ] AWS credentials configured on EC2
- [ ] Can pull from ECR
- [ ] Can push to ECR (test)

## ✅ Security Tools

### Trivy Installation
```bash
# Check Trivy
trivy --version
```

- [ ] Trivy installed on Jenkins agent
- [ ] Trivy in PATH
- [ ] Trivy database updated

### Install Trivy (if needed)
```bash
# Linux
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin

# Update database
trivy image --download-db-only
```

### OWASP Dependency-Check
- [ ] OWASP plugin installed in Jenkins
- [ ] Tool configured in Global Tool Configuration
- [ ] NVD database accessible

## ✅ Email Notifications

### Email Configuration
- [ ] SMTP server configured in Jenkins
- [ ] Email credentials added
- [ ] Test email sent successfully
- [ ] Recipient email addresses updated in Jenkinsfile

### Update Email Addresses
Edit Jenkinsfile and Jenkinsfile.production:
```groovy
to: 'your-email@example.com'
```

- [ ] Email addresses updated in Jenkinsfile
- [ ] Email addresses updated in Jenkinsfile.production

## ✅ Pipeline Configuration

### Jenkinsfile Review
- [ ] AWS_REGION is correct (us-east-1)
- [ ] AWS_ACCOUNT_ID is correct
- [ ] ECR_REPO URL is correct
- [ ] Image names are correct
- [ ] Email addresses are correct

### Environment Variables
```groovy
environment {
    AWS_REGION = 'us-east-1'
    AWS_ACCOUNT_ID = 'YOUR_ACCOUNT_ID'  // ← Update this
    ECR_REPO = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
    BACKEND_IMAGE = 'mailwave-backend'
    FRONTEND_IMAGE = 'mailwave-frontend'
    SONAR_SCANNER = tool 'SonarScanner'
}
```

- [ ] AWS_ACCOUNT_ID updated
- [ ] AWS_REGION is correct
- [ ] Image names match ECR repositories

## ✅ GitHub Repository

### Repository Setup
- [ ] Code pushed to GitHub
- [ ] Repository is accessible
- [ ] Branch name is correct (main or master)
- [ ] .gitignore configured properly

### GitHub Credentials
- [ ] GitHub credentials added to Jenkins (if private)
- [ ] Jenkins can access repository
- [ ] Webhook configured (optional)

## ✅ Pipeline Validation

### Run Validation Script
```bash
# Linux/Mac only
./validate-pipeline.sh
```

- [ ] All validation checks pass
- [ ] No critical errors
- [ ] Warnings reviewed and addressed

### Manual Validation
- [ ] All required tools installed
- [ ] All configuration files present
- [ ] Dockerfiles build successfully
- [ ] docker-compose.yml is valid
- [ ] AWS credentials work
- [ ] ECR repositories exist

## ✅ Final Checks

### Documentation Review
- [ ] Read SETUP_INSTRUCTIONS.md
- [ ] Read JENKINS_SETUP.md
- [ ] Read PIPELINE_FIXES_SUMMARY.md
- [ ] Understand pipeline stages

### Backup
- [ ] Code committed to Git
- [ ] Configuration files backed up
- [ ] Credentials documented securely

### Team Communication
- [ ] Team notified about deployment
- [ ] Maintenance window scheduled (if needed)
- [ ] Rollback plan prepared

## ✅ Ready to Deploy!

### Create Jenkins Pipeline Job
1. Jenkins Dashboard → New Item
2. Enter name: `MailWave-Pipeline`
3. Select: Pipeline
4. Configure:
   - GitHub project URL
   - Pipeline script from SCM
   - Repository URL
   - Credentials
   - Branch: */main
   - Script Path: Jenkinsfile
5. Save

### First Build
- [ ] Click "Build Now"
- [ ] Monitor console output
- [ ] Check each stage completes
- [ ] Review security scan reports
- [ ] Verify deployment

### Post-Deployment Verification
```bash
# Check application
curl http://your-ec2-ip:5000/api/health
curl http://your-ec2-ip:3000

# Check containers on EC2
ssh ubuntu@your-ec2-ip
docker ps
docker-compose logs
```

- [ ] Backend is accessible
- [ ] Frontend is accessible
- [ ] All containers running
- [ ] No errors in logs

## 🎉 Deployment Complete!

### Access Your Application
- Frontend: http://your-ec2-ip:3000
- Backend API: http://your-ec2-ip:5000/api/health
- SonarQube: http://your-sonarqube-ip:9000
- Jenkins: http://your-jenkins-ip:8080

### Monitor
- [ ] Check Jenkins build history
- [ ] Review SonarQube reports
- [ ] Check OWASP scan results
- [ ] Review Trivy scan results
- [ ] Monitor application logs
- [ ] Check email notifications

### Next Steps
- [ ] Set up monitoring (Prometheus + Grafana)
- [ ] Configure alerts
- [ ] Schedule regular security scans
- [ ] Plan for EKS deployment
- [ ] Document lessons learned

## 📞 Support

If you encounter issues:
1. Check troubleshooting scripts
2. Review SETUP_INSTRUCTIONS.md
3. Check JENKINS_SETUP.md
4. Review pipeline logs
5. Check container logs
6. Verify all prerequisites

## 🔄 Regular Maintenance

### Weekly
- [ ] Review security scan results
- [ ] Check for dependency updates
- [ ] Monitor resource usage
- [ ] Review logs for errors

### Monthly
- [ ] Update dependencies
- [ ] Review and update documentation
- [ ] Test disaster recovery
- [ ] Review security policies

### Quarterly
- [ ] Update base images
- [ ] Review and optimize pipeline
- [ ] Security audit
- [ ] Performance review

---

**Remember:** This checklist ensures a smooth deployment. Take your time and verify each item! 🚀
