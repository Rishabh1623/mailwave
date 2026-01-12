# Week 1-2: Jenkins Setup & Basic Pipeline

## 🎯 Goals
- Install Jenkins on EC2
- Connect Jenkins to GitHub
- Create your first pipeline
- Build Docker images in Jenkins
- Push images to AWS ECR

---

## Day 1-2: Jenkins Installation

### Step 1: Prepare Your Existing EC2 Instance (t3.medium)

**You'll run everything on your existing t3.medium instance - it's perfect!**

```bash
# Verify your instance type
curl http://169.254.169.254/latest/meta-data/instance-type
# Should show: t3.medium ✅

# Check available memory
free -h
# Should show ~4GB total ✅
```

**Update Security Group:**
1. Go to AWS EC2 Console
2. Select your instance
3. Click on Security Group
4. Add Inbound Rules:
   - Port 8080 (Jenkins) - Source: 0.0.0.0/0
   - Port 9000 (SonarQube) - Source: 0.0.0.0/0 (add in Week 3)
   - Port 9090 (Prometheus) - Source: 0.0.0.0/0 (add in Week 7)
   - Port 3001 (Grafana) - Source: 0.0.0.0/0 (add in Week 7)

### Step 2: Install Java (Jenkins Requirement)

```bash
# Update system
sudo apt update
sudo apt upgrade -y

# Install Java 11
sudo apt install -y openjdk-11-jdk

# Verify installation
java -version
# Should show: openjdk version "11.x.x"
```

### Step 3: Install Jenkins

```bash
# Add Jenkins repository key
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee \
  /usr/share/keyrings/jenkins-keyring.asc > /dev/null

# Add Jenkins repository
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null

# Update package list
sudo apt update

# Install Jenkins
sudo apt install -y jenkins

# Start Jenkins
sudo systemctl start jenkins
sudo systemctl enable jenkins

# Check status
sudo systemctl status jenkins
# Should show: active (running)
```

### Step 4: Initial Jenkins Setup

```bash
# Get initial admin password
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
# Copy this password
```

**Access Jenkins:**
1. Open browser: `http://YOUR_EC2_PUBLIC_IP:8080`
2. Paste the initial admin password
3. Click "Install suggested plugins" (wait 5-10 minutes)
4. Create admin user:
   - Username: admin
   - Password: (choose a strong password)
   - Full name: Your Name
   - Email: your@email.com
5. Jenkins URL: `http://YOUR_EC2_PUBLIC_IP:8080/`
6. Click "Start using Jenkins"

---

## Day 3: Install Required Jenkins Plugins

### Step 1: Install Plugins

1. Go to: **Manage Jenkins** → **Manage Plugins** → **Available**
2. Search and install these plugins:
   - Docker Pipeline
   - Docker
   - Amazon ECR
   - Git
   - GitHub Integration
   - Pipeline
   - SonarQube Scanner
   - OWASP Dependency-Check
   - Slack Notification (optional)

3. Click "Install without restart"
4. Check "Restart Jenkins when installation is complete"

### Step 2: Install Docker on Jenkins Server

```bash
# Install Docker
sudo apt update
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common

# Add Docker GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Add Docker repository
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io

# Add Jenkins user to docker group
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins

# Verify
sudo -u jenkins docker ps
# Should work without errors
```

---

## Day 4-5: Configure AWS ECR

### Step 1: Create ECR Repositories

```bash
# Install AWS CLI (if not installed)
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
sudo apt install unzip
unzip awscliv2.zip
sudo ./aws/install

# Configure AWS CLI
aws configure
# Enter your AWS Access Key ID
# Enter your AWS Secret Access Key
# Region: us-east-1 (or your preferred region)
# Output format: json

# Create ECR repositories
aws ecr create-repository --repository-name mailwave-backend --region us-east-1
aws ecr create-repository --repository-name mailwave-frontend --region us-east-1

# List repositories
aws ecr describe-repositories --region us-east-1
```

### Step 2: Configure AWS Credentials in Jenkins

1. Go to: **Manage Jenkins** → **Manage Credentials**
2. Click **(global)** → **Add Credentials**
3. Kind: **AWS Credentials**
4. ID: `aws-credentials`
5. Description: `AWS ECR Access`
6. Access Key ID: (your AWS access key)
7. Secret Access Key: (your AWS secret key)
8. Click **OK**

---

## Day 6-7: Create Your First Pipeline

### Step 1: Connect Jenkins to GitHub

1. Go to your GitHub repository
2. Settings → Webhooks → Add webhook
3. Payload URL: `http://YOUR_JENKINS_IP:8080/github-webhook/`
4. Content type: `application/json`
5. Events: "Just the push event"
6. Click "Add webhook"

### Step 2: Create Jenkinsfile in Your Repository

Create file: `Jenkinsfile` in your project root:

```groovy
pipeline {
    agent any
    
    environment {
        AWS_REGION = 'us-east-1'
        AWS_ACCOUNT_ID = 'YOUR_AWS_ACCOUNT_ID'
        ECR_REPO = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
        BACKEND_IMAGE = 'mailwave-backend'
        FRONTEND_IMAGE = 'mailwave-frontend'
    }
    
    stages {
        stage('Checkout') {
            steps {
                echo 'Checking out code from GitHub...'
                checkout scm
            }
        }
        
        stage('Build Backend Image') {
            steps {
                echo 'Building backend Docker image...'
                dir('backend') {
                    script {
                        sh "docker build -t ${BACKEND_IMAGE}:${BUILD_NUMBER} ."
                        sh "docker tag ${BACKEND_IMAGE}:${BUILD_NUMBER} ${BACKEND_IMAGE}:latest"
                    }
                }
            }
        }
        
        stage('Build Frontend Image') {
            steps {
                echo 'Building frontend Docker image...'
                dir('frontend') {
                    script {
                        sh "docker build -t ${FRONTEND_IMAGE}:${BUILD_NUMBER} ."
                        sh "docker tag ${FRONTEND_IMAGE}:${BUILD_NUMBER} ${FRONTEND_IMAGE}:latest"
                    }
                }
            }
        }
        
        stage('Push to ECR') {
            steps {
                echo 'Pushing images to AWS ECR...'
                script {
                    sh """
                        aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REPO}
                        
                        docker tag ${BACKEND_IMAGE}:${BUILD_NUMBER} ${ECR_REPO}/${BACKEND_IMAGE}:${BUILD_NUMBER}
                        docker tag ${BACKEND_IMAGE}:latest ${ECR_REPO}/${BACKEND_IMAGE}:latest
                        docker push ${ECR_REPO}/${BACKEND_IMAGE}:${BUILD_NUMBER}
                        docker push ${ECR_REPO}/${BACKEND_IMAGE}:latest
                        
                        docker tag ${FRONTEND_IMAGE}:${BUILD_NUMBER} ${ECR_REPO}/${FRONTEND_IMAGE}:${BUILD_NUMBER}
                        docker tag ${FRONTEND_IMAGE}:latest ${ECR_REPO}/${FRONTEND_IMAGE}:latest
                        docker push ${ECR_REPO}/${FRONTEND_IMAGE}:${BUILD_NUMBER}
                        docker push ${ECR_REPO}/${FRONTEND_IMAGE}:latest
                    """
                }
            }
        }
    }
    
    post {
        always {
            echo 'Cleaning up...'
            sh 'docker system prune -f'
        }
        success {
            echo '✅ Pipeline succeeded!'
        }
        failure {
            echo '❌ Pipeline failed!'
        }
    }
}
```

**Important:** Replace `YOUR_AWS_ACCOUNT_ID` with your actual AWS account ID:
```bash
# Get your AWS account ID
aws sts get-caller-identity --query Account --output text
```

### Step 3: Create Jenkins Pipeline Job

1. Jenkins Dashboard → **New Item**
2. Name: `mailwave-pipeline`
3. Type: **Pipeline**
4. Click **OK**

**Configure the pipeline:**
1. **General** section:
   - ✅ GitHub project
   - Project url: `https://github.com/YOUR_USERNAME/mailwave`

2. **Build Triggers**:
   - ✅ GitHub hook trigger for GITScm polling

3. **Pipeline** section:
   - Definition: **Pipeline script from SCM**
   - SCM: **Git**
   - Repository URL: `https://github.com/YOUR_USERNAME/mailwave.git`
   - Branch: `*/main`
   - Script Path: `Jenkinsfile`

4. Click **Save**

### Step 4: Test Your Pipeline

```bash
# Commit and push Jenkinsfile
git add Jenkinsfile
git commit -m "Add Jenkins pipeline"
git push origin main
```

**Watch the pipeline:**
1. Go to Jenkins Dashboard
2. Click on `mailwave-pipeline`
3. You should see a build starting automatically
4. Click on the build number (e.g., #1)
5. Click "Console Output" to watch logs

**Expected result:**
- ✅ Checkout stage passes
- ✅ Backend image builds
- ✅ Frontend image builds
- ✅ Images pushed to ECR

---

## 🎉 Week 1-2 Completion Checklist

- [ ] Jenkins installed and running
- [ ] Jenkins accessible at http://YOUR_IP:8080
- [ ] Docker installed on Jenkins server
- [ ] AWS ECR repositories created
- [ ] AWS credentials configured in Jenkins
- [ ] GitHub webhook configured
- [ ] Jenkinsfile created and pushed
- [ ] Pipeline job created in Jenkins
- [ ] First successful pipeline run
- [ ] Images visible in AWS ECR

---

## 🐛 Troubleshooting

### Jenkins won't start
```bash
sudo systemctl status jenkins
sudo journalctl -u jenkins -n 50
```

### Docker permission denied
```bash
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins
```

### AWS ECR login fails
```bash
# Test AWS credentials
aws sts get-caller-identity

# Test ECR login manually
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin YOUR_ACCOUNT.dkr.ecr.us-east-1.amazonaws.com
```

### Pipeline fails at checkout
- Check GitHub webhook is configured
- Verify repository URL in Jenkins job
- Check Jenkins has internet access

---

## 📚 Next Steps

Once Week 1-2 is complete, move to:
👉 **Week 3: SonarQube Code Quality Analysis**

See: `docs/WEEK_3_SONARQUBE.md`
