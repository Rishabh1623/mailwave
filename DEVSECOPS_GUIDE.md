# 🚀 Complete DevSecOps Pipeline Guide (10 Weeks)

**MailWave Project - Industry Standard DevSecOps Implementation**

---

## 📋 Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Prerequisites](#prerequisites)
4. [Week 1-2: Jenkins Setup](#week-1-2-jenkins-setup)
5. [Week 3: SonarQube](#week-3-sonarqube)
6. [Week 4: OWASP Dependency Check](#week-4-owasp)
7. [Week 5: Trivy Container Security](#week-5-trivy)
8. [Week 6: Complete Pipeline Integration](#week-6-integration)
9. [Week 7-8: Monitoring](#week-7-8-monitoring)
10. [Week 9-10: AWS EKS Deployment](#week-9-10-eks)

---

## 🎯 Overview

### What You'll Build
A complete DevSecOps pipeline that automatically:
- Checks code quality (SonarQube)
- Scans dependencies for vulnerabilities (OWASP)
- Scans container images (Trivy)
- Builds and pushes Docker images (AWS ECR)
- Deploys to EC2/EKS
- Monitors everything (Prometheus + Grafana)

### Pipeline Flow
```
GitHub Push → Jenkins Webhook → 
  ↓
SonarQube (Code Quality) → 
  ↓
OWASP (Dependency Scan) → 
  ↓
Docker Build → 
  ↓
Trivy (Container Scan) → 
  ↓
AWS ECR (Push Image) → 
  ↓
Deploy (EC2/EKS) → 
  ↓
Notify (Slack/Email)
```

### Tools Stack
- **Jenkins**: CI/CD orchestration
- **SonarQube**: Code quality analysis
- **OWASP Dependency-Check**: Dependency vulnerability scanning
- **Trivy**: Container security scanning
- **Docker**: Containerization
- **AWS ECR**: Container registry
- **Prometheus + Grafana**: Monitoring
- **AWS EKS**: Kubernetes orchestration

---

## 🔧 Prerequisites

### What You Already Have
- ✅ MailWave application (Frontend + Backend + MongoDB)
- ✅ Docker & Docker Compose working
- ✅ AWS EC2 instance running
- ✅ GitHub repository

### What You Need
- AWS Account with ECR access
- EC2 instance (t2.large recommended for running all tools)
- GitHub account
- Basic understanding of Docker and Git

---
