# Week 3: SonarQube Code Quality Analysis

## 🎯 Goals
- Install SonarQube on your t3.medium
- Integrate SonarQube with Jenkins
- Scan backend and frontend code
- Set up quality gates
- Fail builds on poor code quality

---

## Day 1: Install SonarQube

### Step 1: Run SonarQube in Docker

```bash
# Create SonarQube directory
mkdir -p ~/sonarqube/data ~/sonarqube/logs ~/sonarqube/extensions

# Run SonarQube container
docker run -d \
  --name sonarqube \
  -p 9000:9000 \
  -v ~/sonarqube/data:/opt/sonarqube/data \
  -v ~/sonarqube/logs:/opt/sonarqube/logs \
  -v ~/sonarqube/extensions:/opt/sonarqube/extensions \
  sonarqube:lts-community

# Check if running
docker ps | grep sonarqube

# View logs (wait 2-3 minutes for startup)
docker logs -f sonarqube
# Wait for: "SonarQube is operational"
```

### Step 2: Access SonarQube

1. Open browser: `http://YOUR_EC2_IP:9000`
2. Default credentials:
   - Username: `admin`
   - Password: `admin`
3. Change password when prompted (use a strong password)

### Step 3: Create Project Token

1. Click on **Administration** → **Security** → **Users**
2. Click on **Tokens** for admin user
3. Generate Token:
   - Name: `jenkins-token`
   - Type: **Global Analysis Token**
   - Click **Generate**
4. **Copy the token** (you'll need it for Jenkins)

---

## Day 2: Configure SonarQube in Jenkins

### Step 1: Install SonarQube Scanner Plugin

1. Jenkins → **Manage Jenkins** → **Manage Plugins**
2. **Available** tab → Search: `SonarQube Scanner`
3. Install and restart Jenkins

### Step 2: Configure SonarQube Server in Jenkins

1. **Manage Jenkins** → **Configure System**
2. Scroll to **SonarQube servers**
3. Click **Add SonarQube**
4. Configure:
   - Name: `SonarQube`
   - Server URL: `http://localhost:9000`
   - Server authentication token: Click **Add** → **Jenkins**
     - Kind: **Secret text**
     - Secret: (paste your SonarQube token)
     - ID: `sonarqube-token`
     - Description: `SonarQube Token`
   - Click **Add**, then select `sonarqube-token`
5. Click **Save**

### Step 2.5: Configure SonarQube Webhook (CRITICAL for Quality Gates!)

**Without this, quality gates will timeout!**

1. Go to SonarQube: `http://YOUR_EC2_IP:9000`
2. Login as admin
3. **Administration** → **Configuration** → **Webhooks**
4. Click **Create**
5. Configure:
   - Name: `Jenkins`
   - URL: `http://localhost:8080/sonarqube-webhook/`
   - Secret: (leave empty for local setup)
6. Click **Create**

**What this does:** After SonarQube finishes analyzing code, it sends results back to Jenkins so the quality gate check completes immediately instead of timing out.

### Step 3: Configure SonarQube Scanner

1. **Manage Jenkins** → **Global Tool Configuration**
2. Scroll to **SonarQube Scanner**
3. Click **Add SonarQube Scanner**
4. Configure:
   - Name: `SonarScanner`
   - ✅ Install automatically
   - Version: Latest
5. Click **Save**

---

## Day 3-4: Create SonarQube Projects

### Step 1: Create Backend Project

1. SonarQube → **Projects** → **Create Project**
2. **Manually**
3. Configure:
   - Project key: `mailwave-backend`
   - Display name: `MailWave Backend`
4. Click **Set Up**
5. Choose **Locally**
6. Generate token or use existing
7. Choose **Other** for build tool
8. Copy the project key

### Step 2: Create Frontend Project

1. Repeat above steps:
   - Project key: `mailwave-frontend`
   - Display name: `MailWave Frontend`

### Step 3: Create sonar-project.properties Files

**Backend:** Create `backend/sonar-project.properties`
```properties
sonar.projectKey=mailwave-backend
sonar.projectName=MailWave Backend
sonar.projectVersion=1.0
sonar.sources=.
sonar.exclusions=node_modules/**,coverage/**
sonar.javascript.lcov.reportPaths=coverage/lcov.info
```

**Frontend:** Create `frontend/sonar-project.properties`
```properties
sonar.projectKey=mailwave-frontend
sonar.projectName=MailWave Frontend
sonar.projectVersion=1.0
sonar.sources=src
sonar.exclusions=node_modules/**,build/**,coverage/**
sonar.javascript.lcov.reportPaths=coverage/lcov.info
```

---

## Day 5-6: Update Jenkinsfile

### Update Your Jenkinsfile

Add SonarQube stages after checkout:

```groovy
pipeline {
    agent any
    
    environment {
        AWS_REGION = 'us-east-1'
        AWS_ACCOUNT_ID = 'YOUR_AWS_ACCOUNT_ID'
        ECR_REPO = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
        BACKEND_IMAGE = 'mailwave-backend'
        FRONTEND_IMAGE = 'mailwave-frontend'
        SONAR_SCANNER = tool 'SonarScanner'
    }
    
    stages {
        stage('Checkout') {
            steps {
                echo 'Checking out code...'
                checkout scm
            }
        }
        
        stage('SonarQube Analysis - Backend') {
            steps {
                echo 'Running SonarQube analysis on backend...'
                dir('backend') {
                    withSonarQubeEnv('SonarQube') {
                        sh "${SONAR_SCANNER}/bin/sonar-scanner"
                    }
                }
            }
        }
        
        stage('Quality Gate - Backend') {
            steps {
                echo 'Checking quality gate for backend...'
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }
        
        stage('SonarQube Analysis - Frontend') {
            steps {
                echo 'Running SonarQube analysis on frontend...'
                dir('frontend') {
                    withSonarQubeEnv('SonarQube') {
                        sh "${SONAR_SCANNER}/bin/sonar-scanner"
                    }
                }
            }
        }
        
        stage('Quality Gate - Frontend') {
            steps {
                echo 'Checking quality gate for frontend...'
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }
        
        stage('Build Backend Image') {
            steps {
                echo 'Building backend Docker image...'
                dir('backend') {
                    sh "docker build -t ${BACKEND_IMAGE}:${BUILD_NUMBER} ."
                    sh "docker tag ${BACKEND_IMAGE}:${BUILD_NUMBER} ${BACKEND_IMAGE}:latest"
                }
            }
        }
        
        stage('Build Frontend Image') {
            steps {
                echo 'Building frontend Docker image...'
                dir('frontend') {
                    sh "docker build -t ${FRONTEND_IMAGE}:${BUILD_NUMBER} ."
                    sh "docker tag ${FRONTEND_IMAGE}:${BUILD_NUMBER} ${FRONTEND_IMAGE}:latest"
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

---

## Day 7: Test and Configure Quality Gates

### Step 1: Push Changes and Test

```bash
# Add sonar-project.properties files
git add backend/sonar-project.properties frontend/sonar-project.properties
git add Jenkinsfile
git commit -m "Add SonarQube analysis to pipeline"
git push origin main
```

### Step 2: View Results in SonarQube

1. Go to SonarQube: `http://YOUR_EC2_IP:9000`
2. Click on **Projects**
3. View **mailwave-backend** and **mailwave-frontend**
4. Check:
   - Bugs
   - Vulnerabilities
   - Code Smells
   - Coverage
   - Duplications

### Step 3: Configure Quality Gates

1. SonarQube → **Quality Gates**
2. Click **Create**
3. Name: `MailWave Quality Gate`
4. Add conditions:
   - Bugs: is greater than 0
   - Vulnerabilities: is greater than 0
   - Code Smells: is greater than 10
   - Coverage: is less than 50%
5. Click **Save**

### Step 4: Assign Quality Gate to Projects

1. Go to **Projects** → **mailwave-backend**
2. **Project Settings** → **Quality Gate**
3. Select `MailWave Quality Gate`
4. Repeat for **mailwave-frontend**

---

## 🎉 Week 3 Completion Checklist

- [ ] SonarQube installed and running at http://YOUR_IP:9000
- [ ] SonarQube accessible with admin credentials
- [ ] Jenkins token created in SonarQube
- [ ] SonarQube Scanner plugin installed in Jenkins
- [ ] SonarQube server configured in Jenkins
- [ ] Backend project created in SonarQube
- [ ] Frontend project created in SonarQube
- [ ] sonar-project.properties files created
- [ ] Jenkinsfile updated with SonarQube stages
- [ ] Pipeline runs successfully with code analysis
- [ ] Quality gates configured
- [ ] Pipeline fails on poor code quality

---

## 🐛 Troubleshooting

### SonarQube won't start
```bash
# Check logs
docker logs sonarqube

# Check memory
free -h

# Restart container
docker restart sonarqube
```

### Quality gate timeout
```bash
# Increase timeout in Jenkinsfile
timeout(time: 10, unit: 'MINUTES')
```

### Scanner not found
- Verify SonarScanner is configured in Global Tool Configuration
- Check tool name matches in Jenkinsfile

---

## 📚 Next Steps

Once Week 3 is complete, move to:
👉 **Week 4: OWASP Dependency Check**

See: `docs/WEEK_4_OWASP.md`
