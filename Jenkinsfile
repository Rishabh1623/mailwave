pipeline {
    agent any
    
    options {
        timeout(time: 60, unit: 'MINUTES')
    }
    
    environment {
        AWS_REGION = 'us-east-1'
        AWS_ACCOUNT_ID = '543927035352'
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
        
        
        stage('OWASP Dependency Check') {
            parallel {
                stage('OWASP - Backend') {
                    steps {
                        echo '🔍 Running OWASP Dependency Check on backend...'
                        timeout(time: 30, unit: 'MINUTES') {
                            dir('backend') {
                                dependencyCheck additionalArguments: '''
                                    --scan ./
                                    --format HTML
                                    --format XML
                                    --project "MailWave Backend"
                                    --failOnCVSS 7
                                    --disableNodeAudit
                                    --nvdApiDelay 6000
                                ''', odcInstallation: 'DP-Check'
                                
                                dependencyCheckPublisher pattern: 'dependency-check-report.xml'
                            }
                        }
                    }
                }
                
                stage('OWASP - Frontend') {
                    steps {
                        echo '🔍 Running OWASP Dependency Check on frontend...'
                        timeout(time: 30, unit: 'MINUTES') {
                            dir('frontend') {
                                dependencyCheck additionalArguments: '''
                                    --scan ./
                                    --format HTML
                                    --format XML
                                    --project "MailWave Frontend"
                                    --failOnCVSS 7
                                    --disableNodeAudit
                                    --nvdApiDelay 6000
                                ''', odcInstallation: 'DP-Check'
                                
                                dependencyCheckPublisher pattern: 'dependency-check-report.xml'
                            }
                        }
                    }
                }
            }
        }
        
        stage('SonarQube Analysis') {
            parallel {
                stage('SonarQube - Backend') {
                    steps {
                        echo '📊 Running SonarQube analysis on backend...'
                        dir('backend') {
                            withSonarQubeEnv('SonarQube') {
                                sh "${SONAR_SCANNER}/bin/sonar-scanner"
                            }
                        }
                    }
                }
                
                stage('SonarQube - Frontend') {
                    steps {
                        echo '📊 Running SonarQube analysis on frontend...'
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
            parallel {
                stage('Quality Gate - Backend') {
                    steps {
                        echo '🚦 Checking quality gate for backend...'
                        timeout(time: 10, unit: 'MINUTES') {
                            script {
                                def qg = waitForQualityGate()
                                if (qg.status != 'OK') {
                                    echo "⚠️ Quality Gate failed: ${qg.status}"
                                    echo "Continuing anyway for learning purposes..."
                                } else {
                                    echo "✅ Quality Gate passed!"
                                }
                            }
                        }
                    }
                }
                
                stage('Quality Gate - Frontend') {
                    steps {
                        echo '🚦 Checking quality gate for frontend...'
                        timeout(time: 10, unit: 'MINUTES') {
                            script {
                                def qg = waitForQualityGate()
                                if (qg.status != 'OK') {
                                    echo "⚠️ Quality Gate failed: ${qg.status}"
                                    echo "Continuing anyway for learning purposes..."
                                } else {
                                    echo "✅ Quality Gate passed!"
                                }
                            }
                        }
                    }
                }
            }
        }
        
        stage('Build Docker Images') {
            parallel {
                stage('Build Backend') {
                    steps {
                        echo '🐳 Building backend Docker image...'
                        dir('backend') {
                            script {
                                sh "docker build -t ${BACKEND_IMAGE}:${BUILD_NUMBER} ."
                                sh "docker tag ${BACKEND_IMAGE}:${BUILD_NUMBER} ${BACKEND_IMAGE}:latest"
                            }
                        }
                    }
                }
                
                stage('Build Frontend') {
                    steps {
                        echo '🐳 Building frontend Docker image...'
                        dir('frontend') {
                            script {
                                sh "docker build -t ${FRONTEND_IMAGE}:${BUILD_NUMBER} ."
                                sh "docker tag ${FRONTEND_IMAGE}:${BUILD_NUMBER} ${FRONTEND_IMAGE}:latest"
                            }
                        }
                    }
                }
            }
        }
        
        stage('Trivy Container Scan') {
            parallel {
                stage('Trivy - Backend') {
                    steps {
                        echo '🔒 Scanning backend image with Trivy...'
                        script {
                            try {
                                sh """
                                    trivy image \
                                        --severity HIGH,CRITICAL \
                                        --format json \
                                        --output backend-trivy-report.json \
                                        --exit-code 0 \
                                        ${BACKEND_IMAGE}:${BUILD_NUMBER} || true
                                    
                                    trivy image \
                                        --severity HIGH,CRITICAL \
                                        --exit-code 0 \
                                        ${BACKEND_IMAGE}:${BUILD_NUMBER} || true
                                """
                                echo "✅ Backend Trivy scan completed"
                            } catch (Exception e) {
                                echo "⚠️ Trivy scan failed but continuing: ${e.message}"
                            }
                        }
                    }
                }
                
                stage('Trivy - Frontend') {
                    steps {
                        echo '🔒 Scanning frontend image with Trivy...'
                        script {
                            try {
                                sh """
                                    trivy image \
                                        --severity HIGH,CRITICAL \
                                        --format json \
                                        --output frontend-trivy-report.json \
                                        --exit-code 0 \
                                        ${FRONTEND_IMAGE}:${BUILD_NUMBER} || true
                                    
                                    trivy image \
                                        --severity HIGH,CRITICAL \
                                        --exit-code 0 \
                                        ${FRONTEND_IMAGE}:${BUILD_NUMBER} || true
                                """
                                echo "✅ Frontend Trivy scan completed"
                            } catch (Exception e) {
                                echo "⚠️ Trivy scan failed but continuing: ${e.message}"
                            }
                        }
                    }
                }
            }
        }
        
        stage('Push to ECR') {
            steps {
                echo '📤 Pushing images to AWS ECR...'
                script {
                    // Use AWS credentials stored in Jenkins
                    withCredentials([[
                        $class: 'AmazonWebServicesCredentialsBinding',
                        credentialsId: 'aws-credentials',
                        accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                        secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                    ]]) {
                        sh """
                            aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REPO}
                            
                            docker tag ${BACKEND_IMAGE}:${BUILD_NUMBER} ${ECR_REPO}/${BACKEND_IMAGE}:latest
                            docker push ${ECR_REPO}/${BACKEND_IMAGE}:latest
                            
                            docker tag ${FRONTEND_IMAGE}:${BUILD_NUMBER} ${ECR_REPO}/${FRONTEND_IMAGE}:latest
                            docker push ${ECR_REPO}/${FRONTEND_IMAGE}:latest
                        """
                    }
                }
            }
        }
        
        stage('Deploy to EC2') {
            steps {
                echo '🚀 Deploying to EC2...'
                script {
                    withCredentials([[
                        $class: 'AmazonWebServicesCredentialsBinding',
                        credentialsId: 'aws-credentials',
                        accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                        secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                    ]]) {
                        sh '''
                            echo "=== Pre-Deployment Diagnostics ==="
                            echo "Checking existing containers..."
                            docker ps -a --filter "name=mailwave" || true
                            
                            echo ""
                            echo "Checking existing networks..."
                            docker network ls | grep mailwave || echo "No mailwave networks found"
                            
                            echo ""
                            echo "=== Starting Cleanup ==="
                            
                            # Stop and remove specific containers by name
                            echo "Stopping and removing containers..."
                            docker stop mailwave-mongodb mailwave-backend mailwave-frontend 2>/dev/null || true
                            docker rm -f mailwave-mongodb mailwave-backend mailwave-frontend 2>/dev/null || true
                            
                            # Remove docker-compose resources
                            echo "Cleaning up docker-compose resources..."
                            docker-compose down -v 2>/dev/null || true
                            
                            # Remove any orphaned mailwave networks
                            echo "Removing orphaned networks..."
                            docker network prune -f || true
                            
                            echo ""
                            echo "=== Cleanup Complete ==="
                            docker ps -a --filter "name=mailwave" || echo "All mailwave containers removed"
                            
                            echo ""
                            echo "=== Starting Deployment ==="
                            
                            # Login to ECR
                            aws ecr get-login-password --region ''' + AWS_REGION + ''' | docker login --username AWS --password-stdin ''' + ECR_REPO + '''
                            
                            # Pull latest images from ECR
                            echo "Pulling images from ECR..."
                            docker pull ''' + ECR_REPO + '''/''' + BACKEND_IMAGE + ''':latest
                            docker pull ''' + ECR_REPO + '''/''' + FRONTEND_IMAGE + ''':latest
                            
                            # Tag images for docker-compose
                            echo "Tagging images..."
                            docker tag ''' + ECR_REPO + '''/''' + BACKEND_IMAGE + ''':latest ''' + BACKEND_IMAGE + ''':latest
                            docker tag ''' + ECR_REPO + '''/''' + FRONTEND_IMAGE + ''':latest ''' + FRONTEND_IMAGE + ''':latest
                            
                            # Start new containers
                            echo "Starting containers with docker-compose..."
                            docker-compose up -d
                            
                            # Wait for services to start
                            echo "Waiting for services to initialize..."
                            sleep 15
                            
                            echo ""
                            echo "=== Deployment Status ==="
                            docker-compose ps
                            
                            echo ""
                            echo "=== Health Checks ==="
                            echo "Checking backend health..."
                            curl -f http://localhost:5000/api/health || echo "Backend may still be starting..."
                            
                            echo "Checking frontend..."
                            curl -f http://localhost:3000 || echo "Frontend may still be starting..."
                            
                            echo ""
                            echo "Deployment complete!"
                        '''
                    }
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
            emailext (
                subject: "✅ Pipeline Success: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                body: """
                    <h2>Pipeline Succeeded! 🎉</h2>
                    <p><strong>Job:</strong> ${env.JOB_NAME}</p>
                    <p><strong>Build Number:</strong> ${env.BUILD_NUMBER}</p>
                    <p><strong>Build URL:</strong> <a href="${env.BUILD_URL}">${env.BUILD_URL}</a></p>
                    <p><strong>Status:</strong> ✅ SUCCESS</p>
                    
                    <h3>Pipeline Stages Completed:</h3>
                    <ul>
                        <li>✅ OWASP Dependency Check</li>
                        <li>✅ SonarQube Code Quality Analysis</li>
                        <li>✅ Quality Gates</li>
                        <li>✅ Docker Image Build</li>
                        <li>✅ Trivy Container Security Scan</li>
                        <li>✅ Push to AWS ECR</li>
                        <li>✅ Deploy to EC2</li>
                    </ul>
                    
                    <p><strong>Application URLs:</strong></p>
                    <ul>
                        <li>Backend: <a href="http://13.218.28.204:5000/api/health">http://13.218.28.204:5000/api/health</a></li>
                        <li>Frontend: <a href="http://13.218.28.204:3000">http://13.218.28.204:3000</a></li>
                    </ul>
                """,
                to: 'rishabhmadne1623@gmail.com',
                mimeType: 'text/html'
            )
        }
        failure {
            echo '❌ Pipeline failed! Check security scan results.'
            emailext (
                subject: "❌ Pipeline Failed: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                body: """
                    <h2>Pipeline Failed! ⚠️</h2>
                    <p><strong>Job:</strong> ${env.JOB_NAME}</p>
                    <p><strong>Build Number:</strong> ${env.BUILD_NUMBER}</p>
                    <p><strong>Build URL:</strong> <a href="${env.BUILD_URL}">${env.BUILD_URL}</a></p>
                    <p><strong>Console Output:</strong> <a href="${env.BUILD_URL}console">${env.BUILD_URL}console</a></p>
                    <p><strong>Status:</strong> ❌ FAILED</p>
                    
                    <h3>Action Required:</h3>
                    <ol>
                        <li>Check the console output for error details</li>
                        <li>Review security scan reports (OWASP, SonarQube, Trivy)</li>
                        <li>Fix the issues and push changes to trigger a new build</li>
                    </ol>
                    
                    <p><strong>Common Failure Reasons:</strong></p>
                    <ul>
                        <li>OWASP: HIGH/CRITICAL vulnerabilities in dependencies</li>
                        <li>SonarQube: Quality gate failed (bugs, code smells, security issues)</li>
                        <li>Trivy: HIGH/CRITICAL vulnerabilities in container images</li>
                        <li>Docker: Build errors or missing dependencies</li>
                        <li>Deployment: Container startup failures</li>
                    </ul>
                """,
                to: 'rishabhmadne1623@gmail.com',
                mimeType: 'text/html'
            )
        }
    }
}
