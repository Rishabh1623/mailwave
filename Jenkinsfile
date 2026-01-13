pipeline {
    agent any
    
    environment {
        AWS_REGION = 'us-east-1'
        AWS_ACCOUNT_ID = '543927035352'
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
                    // Use AWS credentials stored in Jenkins
                    withAWS(credentials: 'aws-credentials', region: "${AWS_REGION}") {
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
