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
        
        
        stage('OWASP Dependency Check - Backend') {
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
        
        stage('OWASP Dependency Check - Frontend') {
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
                    waitForQualityGate abortPipeline: false
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
                    waitForQualityGate abortPipeline: false
                }
            }
        }
        
        stage('Build Backend Image') {
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
        
        stage('Build Frontend Image') {
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
        
        stage('Trivy Scan - Backend') {
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
                            --exit-code 1 \
                            ${BACKEND_IMAGE}:${BUILD_NUMBER}
                    """
                }
            }
        }
        
        stage('Trivy Scan - Frontend') {
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
                            --exit-code 1 \
                            ${FRONTEND_IMAGE}:${BUILD_NUMBER}
                    """
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
