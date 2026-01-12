# Week 6: Complete DevSecOps Pipeline Integration

## 🎯 Goals
- Integrate all security tools in one pipeline
- Add notifications (Slack/Email)
- Create comprehensive security reports
- Add deployment stage
- Test end-to-end pipeline
- Document the complete flow

---

## Complete Pipeline Architecture

```
GitHub Push
    ↓
Jenkins Webhook Trigger
    ↓
Checkout Code
    ↓
OWASP Dependency Scan (Backend + Frontend)
    ↓
SonarQube Code Quality (Backend + Frontend)
    ↓
Quality Gates Check
    ↓
Docker Build (Backend + Frontend)
    ↓
Trivy Container Scan (Backend + Frontend)
    ↓
Push to AWS ECR
    ↓
Deploy to EC2
    ↓
Send Notification (Slack/Email)
```

---

## Day 1-2: Add Deployment Stage

### Create Deployment Script

Create `deploy.sh` in project root:

```bash
#!/bin/bash

echo "🚀 Deploying MailWave Application..."

# Pull latest images from ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin YOUR_ACCOUNT.dkr.ecr.us-east-1.amazonaws.com

# Stop existing containers
docker-compose down

# Pull new images
docker pull YOUR_ACCOUNT.dkr.ecr.us-east-1.amazonaws.com/mailwave-backend:latest
docker pull YOUR_ACCOUNT.dkr.ecr.us-east-1.amazonaws.com/mailwave-frontend:latest

# Update docker-compose to use ECR images
# Start containers
docker-compose up -d

echo "✅ Deployment complete!"
```

### Add Deploy Stage to Jenkinsfile

```groovy
stage('Deploy to EC2') {
    steps {
        echo '🚀 Deploying to EC2...'
        script {
            sh '''
                # Update docker-compose.yml to use ECR images
                sed -i "s|image:.*backend.*|image: ${ECR_REPO}/${BACKEND_IMAGE}:${BUILD_NUMBER}|g" docker-compose.yml
                sed -i "s|image:.*frontend.*|image: ${ECR_REPO}/${FRONTEND_IMAGE}:${BUILD_NUMBER}|g" docker-compose.yml
                
                # Deploy
                docker-compose down
                docker-compose up -d
                
                # Verify deployment
                sleep 10
                docker-compose ps
            '''
        }
    }
}
```

---

## Day 3-4: Add Notifications

### Option 1: Email Notifications

Configure in Jenkins:
1. **Manage Jenkins** → **Configure System**
2. **Extended E-mail Notification**
3. SMTP server: `smtp.gmail.com`
4. Port: `465`
5. Add credentials

Add to Jenkinsfile:
```groovy
post {
    success {
        emailext (
            subject: "✅ Pipeline Success: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
            body: """
                Pipeline succeeded!
                
                Job: ${env.JOB_NAME}
                Build: ${env.BUILD_NUMBER}
                URL: ${env.BUILD_URL}
            """,
            to: 'your-email@example.com'
        )
    }
    failure {
        emailext (
            subject: "❌ Pipeline Failed: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
            body: """
                Pipeline failed!
                
                Job: ${env.JOB_NAME}
                Build: ${env.BUILD_NUMBER}
                URL: ${env.BUILD_URL}
                
                Check console output for details.
            """,
            to: 'your-email@example.com'
        )
    }
}
```

### Option 2: Slack Notifications

1. Install Slack Notification plugin
2. Create Slack webhook
3. Configure in Jenkins

Add to Jenkinsfile:
```groovy
post {
    success {
        slackSend (
            color: 'good',
            message: "✅ Pipeline Success: ${env.JOB_NAME} #${env.BUILD_NUMBER}"
        )
    }
    failure {
        slackSend (
            color: 'danger',
            message: "❌ Pipeline Failed: ${env.JOB_NAME} #${env.BUILD_NUMBER}"
        )
    }
}
```

---

## Day 5-6: Final Complete Jenkinsfile

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
                echo '📥 Checking out code from GitHub...'
                checkout scm
            }
        }
        
        stage('Security Scan - Dependencies') {
            parallel {
                stage('OWASP - Backend') {
                    steps {
                        echo '🔍 OWASP scan: Backend dependencies...'
                        dir('backend') {
                            dependencyCheck additionalArguments: '--scan ./ --format HTML --format JSON --project "MailWave Backend" --failOnCVSS 7', 
                                           odcInstallation: 'DP-Check'
                            dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
                        }
                    }
                }
                stage('OWASP - Frontend') {
                    steps {
                        echo '🔍 OWASP scan: Frontend dependencies...'
                        dir('frontend') {
                            dependencyCheck additionalArguments: '--scan ./ --format HTML --format JSON --project "MailWave Frontend" --failOnCVSS 7', 
                                           odcInstallation: 'DP-Check'
                            dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
                        }
                    }
                }
            }
        }
        
        stage('Code Quality Analysis') {
            parallel {
                stage('SonarQube - Backend') {
                    steps {
                        echo '📊 SonarQube: Backend code quality...'
                        dir('backend') {
                            withSonarQubeEnv('SonarQube') {
                                sh "${SONAR_SCANNER}/bin/sonar-scanner"
                            }
                        }
                    }
                }
                stage('SonarQube - Frontend') {
                    steps {
                        echo '📊 SonarQube: Frontend code quality...'
                        dir('frontend') {
                            withSonarQubeEnv('SonarQube') {
                                sh "${SONAR_SCANNER}/bin/sonar-scanner"
                            }
                        }
                    }
                }
            }
        }
        
        stage('Quality Gates') {
            steps {
                echo '🚦 Checking quality gates...'
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }
        
        stage('Build Docker Images') {
            parallel {
                stage('Build Backend') {
                    steps {
                        echo '🐳 Building backend image...'
                        dir('backend') {
                            sh "docker build -t ${BACKEND_IMAGE}:${BUILD_NUMBER} ."
                            sh "docker tag ${BACKEND_IMAGE}:${BUILD_NUMBER} ${BACKEND_IMAGE}:latest"
                        }
                    }
                }
                stage('Build Frontend') {
                    steps {
                        echo '🐳 Building frontend image...'
                        dir('frontend') {
                            sh "docker build -t ${FRONTEND_IMAGE}:${BUILD_NUMBER} ."
                            sh "docker tag ${FRONTEND_IMAGE}:${BUILD_NUMBER} ${FRONTEND_IMAGE}:latest"
                        }
                    }
                }
            }
        }
        
        stage('Container Security Scan') {
            parallel {
                stage('Trivy - Backend') {
                    steps {
                        echo '🔒 Trivy scan: Backend container...'
                        sh """
                            trivy image --severity HIGH,CRITICAL --format json --output backend-trivy-report.json ${BACKEND_IMAGE}:${BUILD_NUMBER}
                            trivy image --severity HIGH,CRITICAL --exit-code 1 ${BACKEND_IMAGE}:${BUILD_NUMBER}
                        """
                    }
                }
                stage('Trivy - Frontend') {
                    steps {
                        echo '🔒 Trivy scan: Frontend container...'
                        sh """
                            trivy image --severity HIGH,CRITICAL --format json --output frontend-trivy-report.json ${FRONTEND_IMAGE}:${BUILD_NUMBER}
                            trivy image --severity HIGH,CRITICAL --exit-code 1 ${FRONTEND_IMAGE}:${BUILD_NUMBER}
                        """
                    }
                }
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
        
        stage('Deploy to EC2') {
            steps {
                echo '🚀 Deploying to EC2...'
                script {
                    sh '''
                        docker-compose down
                        docker-compose pull
                        docker-compose up -d
                        sleep 10
                        docker-compose ps
                    '''
                }
            }
        }
        
        stage('Health Check') {
            steps {
                echo '🏥 Running health checks...'
                script {
                    sh '''
                        curl -f http://localhost:5000/api/health || exit 1
                        curl -f http://localhost:3000 || exit 1
                    '''
                }
            }
        }
    }
    
    post {
        always {
            echo '🧹 Cleaning up...'
            sh 'docker system prune -f'
            archiveArtifacts artifacts: '*-trivy-report.json,**/dependency-check-report.*', allowEmptyArchive: true
        }
        success {
            echo '✅ Pipeline succeeded! All checks passed.'
            // Add email/Slack notification here
        }
        failure {
            echo '❌ Pipeline failed! Check logs for details.'
            // Add email/Slack notification here
        }
    }
}
```

---

## Day 7: Documentation and Testing

### Create SECURITY_REPORT.md

Document your security setup:

```markdown
# Security Report

## Pipeline Security Checks

### 1. Dependency Scanning (OWASP)
- Scans: npm packages
- Threshold: CVSS >= 7.0
- Action: Fails build on HIGH/CRITICAL

### 2. Code Quality (SonarQube)
- Checks: Bugs, vulnerabilities, code smells
- Quality Gate: Custom rules
- Action: Fails build on gate failure

### 3. Container Scanning (Trivy)
- Scans: Docker images
- Severity: HIGH, CRITICAL
- Action: Blocks vulnerable images

## Security Metrics
- Last scan: [Date]
- Vulnerabilities found: [Number]
- Vulnerabilities fixed: [Number]
- Current status: ✅ PASS
```

---

## 🎉 Week 6 Completion Checklist

- [ ] All security tools integrated in pipeline
- [ ] Parallel stages for faster execution
- [ ] Deployment stage added
- [ ] Health checks implemented
- [ ] Notifications configured (Email/Slack)
- [ ] Security reports archived
- [ ] Complete end-to-end test successful
- [ ] Pipeline runs on every push
- [ ] All gates working correctly
- [ ] Documentation complete

---

## 📊 Pipeline Metrics

Track these metrics:
- Build time: ~15-20 minutes
- Success rate: Target >90%
- Security issues found per build
- Time to fix vulnerabilities

---

## 📚 Next Steps

Once Week 6 is complete, move to:
👉 **Week 7-8: Monitoring with Prometheus & Grafana**

See: `docs/WEEK_7_8_MONITORING.md`
