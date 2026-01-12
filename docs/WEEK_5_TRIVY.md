# Week 5: Trivy Container Security

## 🎯 Goals
- Install Trivy scanner
- Scan Docker images for vulnerabilities
- Check OS and application vulnerabilities
- Block vulnerable images from being pushed
- Generate security reports

---

## Day 1-2: Install Trivy

### Step 1: Install Trivy on Jenkins Server

```bash
# Add Trivy repository
sudo apt-get install wget apt-transport-https gnupg lsb-release
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
echo "deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee -a /etc/apt/sources.list.d/trivy.list

# Install Trivy
sudo apt-get update
sudo apt-get install trivy

# Verify installation
trivy --version
```

### Step 2: Test Trivy Manually

```bash
# Scan an image
trivy image mailwave-backend:latest

# Scan with severity filter
trivy image --severity HIGH,CRITICAL mailwave-backend:latest

# Generate report
trivy image --format json --output report.json mailwave-backend:latest
```

---

## Day 3-4: Add Trivy to Jenkins Pipeline

### Update Jenkinsfile

Add Trivy scan stages after Docker build:

```groovy
stage('Trivy Scan - Backend') {
    steps {
        echo 'Scanning backend image with Trivy...'
        script {
            sh """
                trivy image \
                  --severity HIGH,CRITICAL \
                  --format json \
                  --output backend-trivy-report.json \
                  ${BACKEND_IMAGE}:${BUILD_NUMBER}
                
                trivy image \
                  --severity HIGH,CRITICAL \
                  --exit-code 1 \
                  ${BACKEND_IMAGE}:${BUILD_NUMBER}
            """
        }
    }
}

stage('Trivy Scan - Frontend') {
    steps {
        echo 'Scanning frontend image with Trivy...'
        script {
            sh """
                trivy image \
                  --severity HIGH,CRITICAL \
                  --format json \
                  --output frontend-trivy-report.json \
                  ${FRONTEND_IMAGE}:${BUILD_NUMBER}
                
                trivy image \
                  --severity HIGH,CRITICAL \
                  --exit-code 1 \
                  ${FRONTEND_IMAGE}:${BUILD_NUMBER}
            """
        }
    }
}
```

**Note:** `--exit-code 1` makes the pipeline fail if vulnerabilities are found.

---

## Day 5-6: Complete Jenkinsfile with All Security Scans

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
                echo '📥 Checking out code...'
                checkout scm
            }
        }
        
        stage('OWASP Dependency Check - Backend') {
            steps {
                echo '🔍 Running OWASP scan on backend dependencies...'
                dir('backend') {
                    dependencyCheck additionalArguments: '--scan ./ --format HTML --format JSON --project "MailWave Backend" --failOnCVSS 7', 
                                   odcInstallation: 'DP-Check'
                    dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
                }
            }
        }
        
        stage('OWASP Dependency Check - Frontend') {
            steps {
                echo '🔍 Running OWASP scan on frontend dependencies...'
                dir('frontend') {
                    dependencyCheck additionalArguments: '--scan ./ --format HTML --format JSON --project "MailWave Frontend" --failOnCVSS 7', 
                                   odcInstallation: 'DP-Check'
                    dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
                }
            }
        }
        
        stage('SonarQube Analysis - Backend') {
            steps {
                echo '📊 Running SonarQube analysis on backend...'
                dir('backend') {
                    withSonarQubeEnv('SonarQube') {
                        sh "${SONAR_SCANNER}/bin/sonar-scanner"
                    }
                }
            }
        }
        
        stage('Quality Gate - Backend') {
            steps {
                echo '🚦 Checking quality gate for backend...'
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }
        
        stage('SonarQube Analysis - Frontend') {
            steps {
                echo '📊 Running SonarQube analysis on frontend...'
                dir('frontend') {
                    withSonarQubeEnv('SonarQube') {
                        sh "${SONAR_SCANNER}/bin/sonar-scanner"
                    }
                }
            }
        }
        
        stage('Quality Gate - Frontend') {
            steps {
                echo '🚦 Checking quality gate for frontend...'
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }
        
        stage('Build Backend Image') {
            steps {
                echo '🐳 Building backend Docker image...'
                dir('backend') {
                    sh "docker build -t ${BACKEND_IMAGE}:${BUILD_NUMBER} ."
                    sh "docker tag ${BACKEND_IMAGE}:${BUILD_NUMBER} ${BACKEND_IMAGE}:latest"
                }
            }
        }
        
        stage('Build Frontend Image') {
            steps {
                echo '🐳 Building frontend Docker image...'
                dir('frontend') {
                    sh "docker build -t ${FRONTEND_IMAGE}:${BUILD_NUMBER} ."
                    sh "docker tag ${FRONTEND_IMAGE}:${BUILD_NUMBER} ${FRONTEND_IMAGE}:latest"
                }
            }
        }
        
        stage('Trivy Scan - Backend') {
            steps {
                echo '🔒 Scanning backend image with Trivy...'
                sh """
                    trivy image --severity HIGH,CRITICAL --format json --output backend-trivy-report.json ${BACKEND_IMAGE}:${BUILD_NUMBER}
                    trivy image --severity HIGH,CRITICAL --exit-code 1 ${BACKEND_IMAGE}:${BUILD_NUMBER}
                """
            }
        }
        
        stage('Trivy Scan - Frontend') {
            steps {
                echo '🔒 Scanning frontend image with Trivy...'
                sh """
                    trivy image --severity HIGH,CRITICAL --format json --output frontend-trivy-report.json ${FRONTEND_IMAGE}:${BUILD_NUMBER}
                    trivy image --severity HIGH,CRITICAL --exit-code 1 ${FRONTEND_IMAGE}:${BUILD_NUMBER}
                """
            }
        }
        
        stage('Push to ECR') {
            steps {
                echo '📤 Pushing images to AWS ECR...'
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
            echo '🧹 Cleaning up...'
            sh 'docker system prune -f'
            archiveArtifacts artifacts: '*-trivy-report.json', allowEmptyArchive: true
        }
        success {
            echo '✅ Pipeline succeeded! All security checks passed.'
        }
        failure {
            echo '❌ Pipeline failed! Check security scan results.'
        }
    }
}
```

---

## Day 7: Test and Review

### Push and Test

```bash
git add Jenkinsfile
git commit -m "Add Trivy container security scanning"
git push origin main
```

### View Trivy Reports

1. Jenkins build → **Artifacts**
2. Download `backend-trivy-report.json` and `frontend-trivy-report.json`
3. Review vulnerabilities

### Fix Container Vulnerabilities

**Update base images in Dockerfiles:**

```dockerfile
# Use specific versions with fewer vulnerabilities
FROM node:18-alpine3.18

# Or use distroless images
FROM gcr.io/distroless/nodejs18-debian11
```

---

## 🎉 Week 5 Completion Checklist

- [ ] Trivy installed on Jenkins server
- [ ] Trivy scan tested manually
- [ ] Trivy scan added to Jenkinsfile for backend
- [ ] Trivy scan added to Jenkinsfile for frontend
- [ ] Pipeline runs with container security scanning
- [ ] Trivy reports generated and archived
- [ ] HIGH and CRITICAL vulnerabilities reviewed
- [ ] Pipeline fails on vulnerable images
- [ ] Base images updated to reduce vulnerabilities

---

## 🐛 Troubleshooting

### Trivy database update fails
```bash
# Clear cache
trivy image --clear-cache

# Update database manually
trivy image --download-db-only
```

### Too many vulnerabilities
- Use Alpine-based images (smaller attack surface)
- Use specific version tags (not `latest`)
- Regularly update base images

---

## 📚 Next Steps

Once Week 5 is complete, move to:
👉 **Week 6: Complete Pipeline Integration**

See: `docs/WEEK_6_INTEGRATION.md`
