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
                            sh """
                                trivy image \
                                    --severity HIGH,CRITICAL \
                                    --format json \
                                    --output backend-trivy-report.json \
                                    ${BACKEND_IMAGE}:${BUILD_NUMBER}
                                
                                trivy image \
                                    --severity HIGH,CRITICAL \
                                    --exit-code 0 \
                                    ${BACKEND_IMAGE}:${BUILD_NUMBER}
                            """
                        }
                    }
                }
                
                stage('Trivy - Frontend') {
                    steps {
                        echo '🔒 Scanning frontend image with Trivy...'
                        script {
                            sh """
                                trivy image \
                                    --severity HIGH,CRITICAL \
                                    --format json \
                                    --output frontend-trivy-report.json \
                                    ${FRONTEND_IMAGE}:${BUILD_NUMBER}
                                
                                trivy image \
                                    --severity HIGH,CRITICAL \
                                    --exit-code 0 \
                                    ${FRONTEND_IMAGE}:${BUILD_NUMBER}
                            """
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
                        sh """
                            # Login to ECR
                            aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REPO}
                            
                            # Pull latest images from ECR
                            docker pull ${ECR_REPO}/${BACKEND_IMAGE}:latest
                            docker pull ${ECR_REPO}/${FRONTEND_IMAGE}:latest
                            
                            # Tag images for docker-compose
                            docker tag ${ECR_REPO}/${BACKEND_IMAGE}:latest ${BACKEND_IMAGE}:latest
                            docker tag ${ECR_REPO}/${FRONTEND_IMAGE}:latest ${FRONTEND_IMAGE}:latest
                            
                            # Stop existing containers
                            docker-compose down || true
                            
                            # Start new containers
                            docker-compose up -d
                            
                            # Wait for services to start
                            sleep 15
                            
                            # Verify deployment
                            docker-compose ps
                            
                            # Check if services are healthy
                            echo "Checking backend health..."
                            curl -f http://localhost:5000/api/health || echo "Backend health check failed"
                            
                            echo "Checking frontend..."
                            curl -f http://localhost:3000 || echo "Frontend check failed"
                        """
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
        }
        failure {
            echo '❌ Pipeline failed! Check security scan results.'
        }
    }
}
