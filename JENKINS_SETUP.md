# Jenkins Setup Guide for MailWave Pipeline

## Prerequisites

1. Jenkins installed and running
2. Docker installed on Jenkins agent
3. AWS CLI installed on Jenkins agent
4. Trivy installed on Jenkins agent
5. SonarQube server running

## Step 1: Install Required Jenkins Plugins

Go to **Manage Jenkins > Manage Plugins > Available** and install:

1. **Docker Pipeline** - For Docker commands in pipeline
2. **SonarQube Scanner** - For code quality analysis
3. **OWASP Dependency-Check** - For vulnerability scanning
4. **Email Extension Plugin** - For email notifications
5. **AWS Credentials Plugin** - For AWS authentication
6. **Pipeline Utility Steps** - For pipeline utilities
7. **Blue Ocean** (optional) - For better UI

## Step 2: Configure Global Tools

### 2.1 SonarQube Scanner
1. Go to **Manage Jenkins > Global Tool Configuration**
2. Scroll to **SonarQube Scanner**
3. Click **Add SonarQube Scanner**
4. Name: `SonarScanner`
5. Check "Install automatically" or provide installation path
6. Save

### 2.2 OWASP Dependency-Check
1. In **Global Tool Configuration**
2. Scroll to **Dependency-Check**
3. Click **Add Dependency-Check**
4. Name: `DP-Check`
5. Check "Install automatically"
6. Save

### 2.3 Docker
Ensure Docker is available on the Jenkins agent:
```bash
docker --version
```

## Step 3: Configure SonarQube Server

1. Go to **Manage Jenkins > Configure System**
2. Scroll to **SonarQube servers**
3. Click **Add SonarQube**
4. Configuration:
   - Name: `SonarQube`
   - Server URL: `http://your-sonarqube-server:9000`
   - Server authentication token: Add from credentials
5. Save

### Create SonarQube Token
1. Login to SonarQube
2. Go to **My Account > Security > Generate Tokens**
3. Generate token and copy it
4. In Jenkins: **Manage Jenkins > Manage Credentials**
5. Add **Secret text** credential with the token
6. ID: `sonarqube-token`

## Step 4: Configure AWS Credentials

1. Go to **Manage Jenkins > Manage Credentials**
2. Click on **(global)** domain
3. Click **Add Credentials**
4. Kind: **AWS Credentials**
5. Configuration:
   - ID: `aws-credentials`
   - Access Key ID: Your AWS access key
   - Secret Access Key: Your AWS secret key
   - Description: AWS ECR Access
6. Save

## Step 5: Configure Email Notifications

1. Go to **Manage Jenkins > Configure System**
2. Scroll to **Extended E-mail Notification**
3. Configuration:
   - SMTP server: `smtp.gmail.com` (or your SMTP server)
   - SMTP Port: `587`
   - Use SSL/TLS
   - Credentials: Add email credentials
   - Default Recipients: Your email
4. Test configuration
5. Save

### Gmail Setup (if using Gmail)
1. Enable 2-factor authentication
2. Generate App Password
3. Use App Password in Jenkins credentials

## Step 6: Install Trivy on Jenkins Agent

### On Linux/Mac:
```bash
# Install Trivy
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin

# Verify installation
trivy --version

# Update database
trivy image --download-db-only
```

### On Windows:
```powershell
# Using Chocolatey
choco install trivy

# Or download from GitHub releases
# https://github.com/aquasecurity/trivy/releases
```

## Step 7: Create ECR Repositories

```bash
# Login to AWS
aws configure

# Create backend repository
aws ecr create-repository \
    --repository-name mailwave-backend \
    --region us-east-1

# Create frontend repository
aws ecr create-repository \
    --repository-name mailwave-frontend \
    --region us-east-1

# Verify
aws ecr describe-repositories --region us-east-1
```

## Step 8: Create Jenkins Pipeline Job

1. Click **New Item**
2. Enter name: `MailWave-Pipeline`
3. Select **Pipeline**
4. Click **OK**
5. Configuration:
   - Description: MailWave DevSecOps Pipeline
   - Check **GitHub project** (optional)
   - Pipeline Definition: **Pipeline script from SCM**
   - SCM: **Git**
   - Repository URL: Your GitHub repo URL
   - Credentials: Add GitHub credentials if private
   - Branch: `*/main` or `*/master`
   - Script Path: `Jenkinsfile`
6. Save

## Step 9: Configure EC2 Instance

### Security Group Rules
Allow inbound traffic:
- Port 22 (SSH)
- Port 80 (HTTP)
- Port 3000 (Frontend)
- Port 5000 (Backend API)
- Port 9000 (SonarQube)
- Port 27017 (MongoDB - only from backend)

### Install Docker on EC2
```bash
# Update system
sudo yum update -y

# Install Docker
sudo yum install docker -y

# Start Docker
sudo systemctl start docker
sudo systemctl enable docker

# Add user to docker group
sudo usermod -aG docker ec2-user

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verify
docker --version
docker-compose --version
```

### Install AWS CLI on EC2
```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
aws --version
```

### Configure AWS Credentials on EC2
```bash
aws configure
# Enter your AWS Access Key ID
# Enter your AWS Secret Access Key
# Default region: us-east-1
# Default output format: json
```

## Step 10: Test Pipeline

1. Click **Build Now** on your pipeline job
2. Monitor the build in **Blue Ocean** or **Console Output**
3. Check each stage:
   - ✅ Checkout
   - ✅ OWASP Dependency Check
   - ✅ SonarQube Analysis
   - ✅ Quality Gate
   - ✅ Build Docker Images
   - ✅ Trivy Container Scan
   - ✅ Push to ECR
   - ✅ Deploy to EC2

## Troubleshooting

### Issue: SonarQube connection failed
**Solution:**
- Verify SonarQube server is running
- Check firewall rules
- Verify token is correct
- Test connection: `curl http://sonarqube-server:9000/api/system/status`

### Issue: Docker build fails
**Solution:**
- Check Dockerfile syntax
- Verify base images are accessible
- Check network connectivity
- Review build logs

### Issue: AWS ECR authentication fails
**Solution:**
- Verify AWS credentials
- Check IAM permissions
- Ensure ECR repositories exist
- Test: `aws ecr describe-repositories`

### Issue: OWASP check timeout
**Solution:**
- Increase timeout in Jenkinsfile
- Use local NVD database
- Add `--nvdApiDelay 8000`

### Issue: Trivy not found
**Solution:**
- Install Trivy on Jenkins agent
- Add Trivy to PATH
- Verify: `trivy --version`

### Issue: Deployment fails
**Solution:**
- Check EC2 instance is running
- Verify Docker is running on EC2
- Check security group rules
- Review container logs: `docker-compose logs`

## Best Practices

1. **Use separate pipelines for dev and production**
   - `Jenkinsfile` for development
   - `Jenkinsfile.production` for production

2. **Implement proper secret management**
   - Use Jenkins credentials
   - Never commit secrets to Git
   - Use AWS Secrets Manager for production

3. **Set up monitoring**
   - CloudWatch for AWS resources
   - Prometheus + Grafana for containers
   - ELK stack for logs

4. **Implement rollback strategy**
   - Tag images with build numbers
   - Keep previous versions in ECR
   - Test rollback procedure

5. **Regular maintenance**
   - Update Jenkins plugins
   - Update Docker images
   - Update security scanning tools
   - Review and fix security findings

## Pipeline Optimization

1. **Use Docker layer caching**
2. **Parallel stages** for faster builds
3. **Conditional stages** to skip unnecessary steps
4. **Artifact archiving** for reports
5. **Build triggers** for automatic builds

## Security Checklist

- [ ] All credentials stored in Jenkins Credentials
- [ ] AWS IAM roles with least privilege
- [ ] Security groups properly configured
- [ ] SSL/TLS enabled for production
- [ ] Regular security scans scheduled
- [ ] Vulnerability reports reviewed
- [ ] Dependencies updated regularly
- [ ] Container images scanned before deployment
- [ ] Secrets not in code or logs
- [ ] Audit logs enabled

## Monitoring URLs

After successful deployment:
- Frontend: http://your-ec2-ip:3000
- Backend API: http://your-ec2-ip:5000/api/health
- SonarQube: http://your-sonarqube-ip:9000
- Jenkins: http://your-jenkins-ip:8080

## Support

For issues or questions:
1. Check Jenkins console output
2. Review container logs
3. Check security scan reports
4. Consult documentation
5. Contact DevOps team
