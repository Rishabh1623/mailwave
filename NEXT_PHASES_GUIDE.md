# 🚀 MailWave DevOps Journey - Phases 5-10 Guide

Complete step-by-step guide for advanced DevOps concepts (2026 Edition)

---

## 📦 PHASE 5: Container Registry

### Objectives
- Push images to Docker Hub
- Set up AWS ECR
- Implement image versioning
- Automate image builds

### Quick Start Commands
```bash
# Docker Hub
docker login
docker tag mailwave-backend YOUR_USERNAME/mailwave-backend:v1.0
docker push YOUR_USERNAME/mailwave-backend:v1.0

# AWS ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin YOUR_ACCOUNT.dkr.ecr.us-east-1.amazonaws.com
docker tag mailwave-backend:latest YOUR_ACCOUNT.dkr.ecr.us-east-1.amazonaws.com/mailwave-backend:v1.0
docker push YOUR_ACCOUNT.dkr.ecr.us-east-1.amazonaws.com/mailwave-backend:v1.0
```

### Detailed Steps
See: `docs/PHASE_5_CONTAINER_REGISTRY.md`

**Time Estimate:** 2-3 hours  
**Difficulty:** Beginner

---

## 🔄 PHASE 6: Jenkins CI/CD with DevSecOps

### Objectives
- Install Jenkins on EC2
- Create CI/CD pipelines
- Integrate security scanning
- Automate deployments

### Architecture
```
GitHub Push → Jenkins Webhook → Build → Test → Security Scan → Push to Registry → Deploy
```

### Jenkins Installation
```bash
# Install Java
sudo apt update
sudo apt install -y openjdk-11-jdk

# Add Jenkins repository
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee \
  /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null

# Install Jenkins
sudo apt update
sudo apt install -y jenkins

# Start Jenkins
sudo systemctl start jenkins
sudo systemctl enable jenkins

# Get initial admin password
sudo cat /var/lib/jenkins/secrets/initialAdminPassword

# Access Jenkins at: http://YOUR_EC2_IP:8080
```

### Pipeline Example (Jenkinsfile)
```groovy
pipeline {
    agent any
    
    stages {
        stage('Checkout') {
            steps {
                git 'https://github.com/YOUR_USERNAME/mailwave.git'
            }
        }
        
        stage('Build Backend') {
            steps {
                dir('backend') {
                    sh 'docker build -t mailwave-backend .'
                }
            }
        }
        
        stage('Test') {
            steps {
                sh 'npm test'
            }
        }
        
        stage('Security Scan') {
            steps {
                sh 'trivy image mailwave-backend'
            }
        }
        
        stage('Push to Registry') {
            steps {
                sh 'docker push YOUR_USERNAME/mailwave-backend:latest'
            }
        }
        
        stage('Deploy') {
            steps {
                sh 'docker-compose up -d'
            }
        }
    }
}
```

**Time Estimate:** 4-6 hours  
**Difficulty:** Intermediate

---

## ☁️ PHASE 7: AWS Deep Dive

### Objectives
- Create custom VPC
- Set up Application Load Balancer
- Migrate to RDS
- Implement Auto Scaling

### 7.1: VPC Setup
```bash
# Create VPC
aws ec2 create-vpc --cidr-block 10.0.0.0/16 --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=mailwave-vpc}]'

# Create Subnets
aws ec2 create-subnet --vpc-id vpc-xxxxx --cidr-block 10.0.1.0/24 --availability-zone us-east-1a
aws ec2 create-subnet --vpc-id vpc-xxxxx --cidr-block 10.0.2.0/24 --availability-zone us-east-1b

# Create Internet Gateway
aws ec2 create-internet-gateway
aws ec2 attach-internet-gateway --vpc-id vpc-xxxxx --internet-gateway-id igw-xxxxx
```

### 7.2: Application Load Balancer
```bash
# Create ALB
aws elbv2 create-load-balancer \
  --name mailwave-alb \
  --subnets subnet-xxxxx subnet-yyyyy \
  --security-groups sg-xxxxx

# Create Target Group
aws elbv2 create-target-group \
  --name mailwave-targets \
  --protocol HTTP \
  --port 3000 \
  --vpc-id vpc-xxxxx

# Register targets
aws elbv2 register-targets \
  --target-group-arn arn:aws:elasticloadbalancing:... \
  --targets Id=i-xxxxx
```

### 7.3: RDS Setup
```bash
# Create RDS instance (MongoDB alternative: DocumentDB)
aws rds create-db-instance \
  --db-instance-identifier mailwave-db \
  --db-instance-class db.t3.micro \
  --engine postgres \
  --master-username admin \
  --master-user-password YourPassword123 \
  --allocated-storage 20
```

### 7.4: Auto Scaling
```bash
# Create Launch Template
aws ec2 create-launch-template \
  --launch-template-name mailwave-template \
  --version-description v1 \
  --launch-template-data file://launch-template.json

# Create Auto Scaling Group
aws autoscaling create-auto-scaling-group \
  --auto-scaling-group-name mailwave-asg \
  --launch-template LaunchTemplateName=mailwave-template \
  --min-size 2 \
  --max-size 5 \
  --desired-capacity 2 \
  --vpc-zone-identifier "subnet-xxxxx,subnet-yyyyy"
```

**Time Estimate:** 6-8 hours  
**Difficulty:** Intermediate-Advanced

---

## ☸️ PHASE 8: Kubernetes + EKS Deployment

### Objectives
- Learn Kubernetes fundamentals
- Deploy to local Minikube
- Set up AWS EKS cluster
- Deploy MailWave to EKS

### 8.1: Install Kubernetes Tools
```bash
# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Install Minikube (for local testing)
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Start Minikube
minikube start
```

### 8.2: Create Kubernetes Manifests

**backend-deployment.yaml**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mailwave-backend
spec:
  replicas: 3
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
      - name: backend
        image: YOUR_USERNAME/mailwave-backend:latest
        ports:
        - containerPort: 5000
        env:
        - name: MONGODB_URI
          value: "mongodb://mongodb-service:27017/newsletter"
---
apiVersion: v1
kind: Service
metadata:
  name: backend-service
spec:
  selector:
    app: backend
  ports:
  - protocol: TCP
    port: 5000
    targetPort: 5000
  type: LoadBalancer
```

### 8.3: Deploy to Minikube
```bash
# Apply manifests
kubectl apply -f mongodb-deployment.yaml
kubectl apply -f backend-deployment.yaml
kubectl apply -f frontend-deployment.yaml

# Check deployments
kubectl get deployments
kubectl get pods
kubectl get services

# Access application
minikube service frontend-service
```

### 8.4: AWS EKS Setup
```bash
# Install eksctl
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin

# Create EKS cluster
eksctl create cluster \
  --name mailwave-cluster \
  --region us-east-1 \
  --nodegroup-name mailwave-nodes \
  --node-type t3.medium \
  --nodes 2 \
  --nodes-min 1 \
  --nodes-max 4

# Configure kubectl
aws eks update-kubeconfig --region us-east-1 --name mailwave-cluster

# Deploy to EKS
kubectl apply -f k8s/
```

**Time Estimate:** 8-12 hours  
**Difficulty:** Advanced

---

## 📊 PHASE 9: Observability (Prometheus, Grafana, ELK)

### Objectives
- Monitor application metrics
- Visualize data with Grafana
- Centralize logs with ELK
- Set up alerts

### 9.1: Prometheus Setup
```bash
# Create prometheus.yml
cat > prometheus.yml << EOF
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'mailwave-backend'
    static_configs:
      - targets: ['backend:5000']
  
  - job_name: 'mailwave-frontend'
    static_configs:
      - targets: ['frontend:3000']
EOF

# Add to docker-compose.yml
```

### 9.2: Grafana Setup
```yaml
# Add to docker-compose.yml
  grafana:
    image: grafana/grafana:latest
    container_name: mailwave-grafana
    ports:
      - "3001:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
    volumes:
      - grafana_data:/var/lib/grafana
    networks:
      - mailwave-network
```

### 9.3: ELK Stack (Elasticsearch, Logstash, Kibana)
```yaml
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:8.11.0
    environment:
      - discovery.type=single-node
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
    ports:
      - "9200:9200"
    networks:
      - mailwave-network

  kibana:
    image: docker.elastic.co/kibana/kibana:8.11.0
    ports:
      - "5601:5601"
    environment:
      - ELASTICSEARCH_HOSTS=http://elasticsearch:9200
    networks:
      - mailwave-network
```

**Time Estimate:** 6-8 hours  
**Difficulty:** Intermediate-Advanced

---

## 🏗️ PHASE 10: Infrastructure as Code (Terraform)

### Objectives
- Automate AWS infrastructure
- Version control infrastructure
- Create reusable modules
- Implement best practices

### 10.1: Install Terraform
```bash
# Install Terraform
wget https://releases.hashicorp.com/terraform/1.6.6/terraform_1.6.6_linux_amd64.zip
unzip terraform_1.6.6_linux_amd64.zip
sudo mv terraform /usr/local/bin/

# Verify installation
terraform --version
```

### 10.2: Create Terraform Configuration

**main.tf**
```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# VPC
resource "aws_vpc" "mailwave_vpc" {
  cidr_block = "10.0.0.0/16"
  
  tags = {
    Name = "mailwave-vpc"
  }
}

# Subnets
resource "aws_subnet" "public_subnet_1" {
  vpc_id            = aws_vpc.mailwave_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  
  tags = {
    Name = "mailwave-public-1"
  }
}

# EC2 Instance
resource "aws_instance" "mailwave_server" {
  ami           = "ami-0c55b159cbfafe1f0"  # Ubuntu 22.04
  instance_type = "t2.medium"
  subnet_id     = aws_subnet.public_subnet_1.id
  
  user_data = file("user-data.sh")
  
  tags = {
    Name = "mailwave-server"
  }
}

# Security Group
resource "aws_security_group" "mailwave_sg" {
  name        = "mailwave-sg"
  description = "Security group for MailWave"
  vpc_id      = aws_vpc.mailwave_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# RDS Instance
resource "aws_db_instance" "mailwave_db" {
  identifier           = "mailwave-db"
  engine              = "postgres"
  engine_version      = "14.7"
  instance_class      = "db.t3.micro"
  allocated_storage   = 20
  username            = "admin"
  password            = var.db_password
  skip_final_snapshot = true
  
  tags = {
    Name = "mailwave-database"
  }
}
```

### 10.3: Terraform Commands
```bash
# Initialize Terraform
terraform init

# Plan infrastructure changes
terraform plan

# Apply changes
terraform apply

# Destroy infrastructure
terraform destroy

# Format code
terraform fmt

# Validate configuration
terraform validate
```

**Time Estimate:** 8-10 hours  
**Difficulty:** Advanced

---

## 📅 Recommended Learning Timeline

### Week 1-2: Phase 5 (Container Registry)
- Docker Hub basics
- AWS ECR setup
- Image versioning

### Week 3-4: Phase 6 (Jenkins CI/CD)
- Jenkins installation
- Pipeline creation
- Security scanning

### Week 5-6: Phase 7 (AWS Deep Dive)
- VPC networking
- Load balancing
- Database migration

### Week 7-9: Phase 8 (Kubernetes)
- K8s fundamentals
- Local deployment
- EKS production

### Week 10-11: Phase 9 (Observability)
- Prometheus metrics
- Grafana dashboards
- Log aggregation

### Week 12-13: Phase 10 (Terraform)
- IaC basics
- AWS automation
- Best practices

---

## 🎯 Success Criteria

By the end of this journey, you will have:

✅ Production-ready containerized application  
✅ Automated CI/CD pipeline  
✅ Scalable AWS infrastructure  
✅ Kubernetes orchestration  
✅ Complete observability stack  
✅ Infrastructure as Code  

**You'll be ready for DevOps roles in 2026!** 🚀

---

## 📚 Additional Resources

- **Docker**: https://docs.docker.com
- **Kubernetes**: https://kubernetes.io/docs
- **AWS**: https://aws.amazon.com/documentation
- **Terraform**: https://www.terraform.io/docs
- **Jenkins**: https://www.jenkins.io/doc
- **Prometheus**: https://prometheus.io/docs
- **Grafana**: https://grafana.com/docs

---

## 🤝 Need Help?

- Create GitHub issues for questions
- Join DevOps communities
- Practice on AWS Free Tier
- Build your portfolio

**Good luck on your DevOps journey!** 💪
