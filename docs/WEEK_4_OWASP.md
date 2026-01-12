# Week 4: OWASP Dependency Check

## 🎯 Goals
- Install OWASP Dependency-Check plugin
- Scan npm packages for vulnerabilities
- Check for known CVEs
- Set security gates
- Fail builds on critical vulnerabilities

---

## Day 1-2: Install OWASP Dependency-Check

### Step 1: Install Plugin in Jenkins

1. Jenkins → **Manage Jenkins** → **Manage Plugins**
2. **Available** tab → Search: `OWASP Dependency-Check`
3. Install **OWASP Dependency-Check Plugin**
4. Restart Jenkins

### Step 2: Configure OWASP Dependency-Check

1. **Manage Jenkins** → **Global Tool Configuration**
2. Scroll to **Dependency-Check**
3. Click **Add Dependency-Check**
4. Configure:
   - Name: `DP-Check`
   - ✅ Install automatically
   - Install from: github.com
   - Version: Latest
5. Click **Save**

---

## Day 3-4: Update Jenkinsfile with OWASP Scan

### Add OWASP Stages to Jenkinsfile

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
        
        stage('OWASP Dependency Check - Backend') {
            steps {
                echo 'Running OWASP Dependency Check on backend...'
                dir('backend') {
                    dependencyCheck additionalArguments: '''
                        --scan ./
                        --format HTML
                        --format JSON
                        --format XML
                        --project "MailWave Backend"
                        --failOnCVSS 7
                    ''', odcInstallation: 'DP-Check'
                    
                    dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
                }
            }
        }
        
        stage('OWASP Dependency Check - Frontend') {
            steps {
                echo 'Running OWASP Dependency Check on frontend...'
                dir('frontend') {
                    dependencyCheck additionalArguments: '''
                        --scan ./
                        --format HTML
                        --format JSON
                        --format XML
                        --project "MailWave Frontend"
                        --failOnCVSS 7
                    ''', odcInstallation: 'DP-Check'
                    
                    dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
                }
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
            echo '❌ Pipeline failed - Check security vulnerabilities!'
        }
    }
}
```

---

## Day 5-6: Test and Review Results

### Step 1: Push Changes

```bash
git add Jenkinsfile
git commit -m "Add OWASP Dependency Check to pipeline"
git push origin main
```

### Step 2: View OWASP Reports in Jenkins

1. Go to Jenkins build
2. Click on **Dependency-Check** in left menu
3. Review:
   - Total dependencies scanned
   - Vulnerabilities found (High, Medium, Low)
   - CVE details
   - Affected packages

### Step 3: Fix Vulnerabilities

**Check npm packages:**
```bash
# In backend directory
cd backend
npm audit

# Fix automatically (if possible)
npm audit fix

# Force fix (may break things)
npm audit fix --force

# Update specific package
npm update package-name
```

**Check frontend packages:**
```bash
cd frontend
npm audit
npm audit fix
```

---

## Day 7: Configure Security Thresholds

### Adjust CVSS Threshold

In Jenkinsfile, adjust `--failOnCVSS` value:

```groovy
--failOnCVSS 7   // Fail on HIGH (7.0-8.9) and CRITICAL (9.0-10.0)
--failOnCVSS 4   // Fail on MEDIUM (4.0-6.9) and above
--failOnCVSS 0   // Fail on any vulnerability
```

**Recommended for production:** `--failOnCVSS 7`

### Suppress False Positives

Create `suppression.xml` if needed:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<suppressions xmlns="https://jeremylong.github.io/DependencyCheck/dependency-suppression.1.3.xsd">
    <suppress>
        <notes>False positive - not applicable to our use case</notes>
        <cve>CVE-2021-XXXXX</cve>
    </suppress>
</suppressions>
```

Add to Jenkinsfile:
```groovy
--suppression suppression.xml
```

---

## 🎉 Week 4 Completion Checklist

- [ ] OWASP Dependency-Check plugin installed
- [ ] Dependency-Check tool configured in Jenkins
- [ ] OWASP scan added to Jenkinsfile for backend
- [ ] OWASP scan added to Jenkinsfile for frontend
- [ ] Pipeline runs successfully with dependency scan
- [ ] OWASP reports visible in Jenkins
- [ ] Vulnerabilities reviewed and documented
- [ ] Critical vulnerabilities fixed
- [ ] Security threshold configured (--failOnCVSS)
- [ ] Pipeline fails on critical vulnerabilities

---

## 🐛 Troubleshooting

### OWASP scan takes too long
```groovy
// Add timeout
timeout(time: 30, unit: 'MINUTES') {
    dependencyCheck ...
}
```

### Out of memory during scan
```bash
# Increase Jenkins memory
sudo systemctl edit jenkins

# Add:
[Service]
Environment="JAVA_OPTS=-Xmx2048m"

# Restart
sudo systemctl restart jenkins
```

### False positives
- Create suppression.xml file
- Document why it's a false positive
- Add to version control

---

## 📊 Understanding CVSS Scores

- **0.0**: None
- **0.1-3.9**: Low
- **4.0-6.9**: Medium
- **7.0-8.9**: High
- **9.0-10.0**: Critical

**Recommendation:** Fix all HIGH and CRITICAL before deploying to production.

---

## 📚 Next Steps

Once Week 4 is complete, move to:
👉 **Week 5: Trivy Container Security**

See: `docs/WEEK_5_TRIVY.md`
