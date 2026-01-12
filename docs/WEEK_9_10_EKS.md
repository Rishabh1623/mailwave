# Week 9-10: AWS EKS Deployment

## 🎯 Goals
- Install kubectl and eksctl
- Create AWS EKS cluster
- Learn Kubernetes concepts while deploying
- Deploy MailWave to EKS
- Update Jenkins to deploy to EKS
- Add monitoring to EKS

---

## Week 9: EKS Cluster Setup

### Day 1: Install Required Tools

```bash
# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
kubectl version --client

# Install eksctl
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin
eksctl version

# Install AWS CLI (if not already installed)
aws --version
```

### Day 2-3: Create EKS Cluster

```bash
# Create cluster (takes 15-20 minutes)
eksctl create cluster \
  --name mailwave-cluster \
  --region us-east-1 \
  --nodegroup-name mailwave-nodes \
  --node-type t3.medium \
  --nodes 2 \
  --nodes-min 1 \
  --nodes-max 4 \
  --managed

# Configure kubectl
aws eks update-kubeconfig --region us-east-1 --name mailwave-cluster

# Verify cluster
kubectl get nodes
kubectl get pods --all-namespaces
```

### Day 4-5: Create Kubernetes Manifests

**Create k8s/ directory with manifests:**

**k8s/mongodb-deployment.yaml:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mongodb
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mongodb
  template:
    metadata:
      labels:
        app: mongodb
    spec:
      containers:
      - name: mongodb
        image: mongo:latest
        ports:
        - containerPort: 27017
        volumeMounts:
        - name: mongodb-storage
          mountPath: /data/db
      volumes:
      - name: mongodb-storage
        persistentVolumeClaim:
          claimName: mongodb-pvc
---
apiVersion: v1
kind: Service
metadata:
  name: mongodb-service
spec:
  selector:
    app: mongodb
  ports:
  - protocol: TCP
    port: 27017
    targetPort: 27017
  type: ClusterIP
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mongodb-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
```

**k8s/backend-deployment.yaml:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mailwave-backend
spec:
  replicas: 2
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
        image: YOUR_ACCOUNT.dkr.ecr.us-east-1.amazonaws.com/mailwave-backend:latest
        ports:
        - containerPort: 5000
        env:
        - name: PORT
          value: "5000"
        - name: MONGODB_URI
          value: "mongodb://mongodb-service:27017/newsletter"
        - name: NODE_ENV
          value: "production"
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

**k8s/frontend-deployment.yaml:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mailwave-frontend
spec:
  replicas: 2
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
      - name: frontend
        image: YOUR_ACCOUNT.dkr.ecr.us-east-1.amazonaws.com/mailwave-frontend:latest
        ports:
        - containerPort: 3000
        env:
        - name: REACT_APP_API_URL
          valueFrom:
            configMapKeyRef:
              name: app-config
              key: backend_url
---
apiVersion: v1
kind: Service
metadata:
  name: frontend-service
spec:
  selector:
    app: frontend
  ports:
  - protocol: TCP
    port: 80
    targetPort: 3000
  type: LoadBalancer
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  backend_url: "http://BACKEND_LB_URL:5000/api"
```

### Day 6-7: Deploy to EKS

```bash
# Apply manifests
kubectl apply -f k8s/mongodb-deployment.yaml
kubectl apply -f k8s/backend-deployment.yaml
kubectl apply -f k8s/frontend-deployment.yaml

# Check deployments
kubectl get deployments
kubectl get pods
kubectl get services

# Get LoadBalancer URLs
kubectl get svc backend-service
kubectl get svc frontend-service

# Update frontend ConfigMap with backend URL
kubectl edit configmap app-config
# Update backend_url with actual backend LoadBalancer URL

# Restart frontend to pick up new config
kubectl rollout restart deployment/mailwave-frontend
```

---

## Week 10: Jenkins Integration & Production Hardening

### Day 1-2: Update Jenkins for EKS Deployment

**Install kubectl on Jenkins server:**
```bash
# Same as Day 1 above
```

**Configure AWS credentials for kubectl:**
```bash
aws eks update-kubeconfig --region us-east-1 --name mailwave-cluster
```

**Add EKS Deploy Stage to Jenkinsfile:**

```groovy
stage('Deploy to EKS') {
    steps {
        echo '☸️ Deploying to EKS...'
        script {
            sh '''
                # Update image tags in manifests
                sed -i "s|image:.*backend.*|image: ${ECR_REPO}/${BACKEND_IMAGE}:${BUILD_NUMBER}|g" k8s/backend-deployment.yaml
                sed -i "s|image:.*frontend.*|image: ${ECR_REPO}/${FRONTEND_IMAGE}:${BUILD_NUMBER}|g" k8s/frontend-deployment.yaml
                
                # Apply manifests
                kubectl apply -f k8s/
                
                # Wait for rollout
                kubectl rollout status deployment/mailwave-backend
                kubectl rollout status deployment/mailwave-frontend
                
                # Verify deployment
                kubectl get pods
            '''
        }
    }
}
```

### Day 3-4: Add Monitoring to EKS

**Install Prometheus Operator:**
```bash
# Add Prometheus Helm repo
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Install Prometheus
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace

# Access Grafana
kubectl port-forward -n monitoring svc/prometheus-grafana 3001:80
```

### Day 5-6: Production Hardening

**1. Add Resource Limits:**
```yaml
resources:
  requests:
    memory: "256Mi"
    cpu: "250m"
  limits:
    memory: "512Mi"
    cpu: "500m"
```

**2. Add Health Checks:**
```yaml
livenessProbe:
  httpGet:
    path: /api/health
    port: 5000
  initialDelaySeconds: 30
  periodSeconds: 10

readinessProbe:
  httpGet:
    path: /api/health
    port: 5000
  initialDelaySeconds: 5
  periodSeconds: 5
```

**3. Add Horizontal Pod Autoscaler:**
```bash
kubectl autoscale deployment mailwave-backend \
  --cpu-percent=70 \
  --min=2 \
  --max=10
```

**4. Add Ingress (Optional):**
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: mailwave-ingress
spec:
  rules:
  - host: mailwave.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend-service
            port:
              number: 80
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: backend-service
            port:
              number: 5000
```

### Day 7: Final Testing & Documentation

**Test Complete Flow:**
1. Push code to GitHub
2. Jenkins builds and scans
3. Pushes to ECR
4. Deploys to EKS
5. Verify application works
6. Check monitoring dashboards

**Create DEPLOYMENT_GUIDE.md:**
```markdown
# EKS Deployment Guide

## Architecture
- EKS Cluster: mailwave-cluster
- Nodes: 2x t3.medium
- Deployments: Frontend (2 replicas), Backend (2 replicas), MongoDB (1 replica)

## Access URLs
- Frontend: http://FRONTEND_LB_URL
- Backend API: http://BACKEND_LB_URL:5000/api
- Grafana: kubectl port-forward -n monitoring svc/prometheus-grafana 3001:80

## Useful Commands
- View pods: kubectl get pods
- View logs: kubectl logs -f pod-name
- Scale: kubectl scale deployment mailwave-backend --replicas=3
- Update: kubectl set image deployment/mailwave-backend backend=NEW_IMAGE
```

---

## 🎉 Week 9-10 Completion Checklist

- [ ] kubectl and eksctl installed
- [ ] EKS cluster created
- [ ] Kubernetes manifests created
- [ ] Application deployed to EKS
- [ ] LoadBalancers accessible
- [ ] Jenkins deploys to EKS automatically
- [ ] Monitoring added to EKS
- [ ] Resource limits configured
- [ ] Health checks added
- [ ] Autoscaling configured
- [ ] Complete end-to-end test successful
- [ ] Documentation complete

---

## 🐛 Troubleshooting

### Pods not starting
```bash
kubectl describe pod POD_NAME
kubectl logs POD_NAME
```

### Can't access LoadBalancer
```bash
# Check security groups
# Verify LoadBalancer is provisioned
kubectl get svc
```

### Image pull errors
```bash
# Verify ECR permissions
# Check image exists in ECR
aws ecr describe-images --repository-name mailwave-backend
```

---

## 🎓 Kubernetes Concepts Learned

- **Pods**: Smallest deployable units
- **Deployments**: Manage replica sets
- **Services**: Expose pods (ClusterIP, LoadBalancer)
- **ConfigMaps**: Configuration data
- **PersistentVolumeClaims**: Storage
- **Ingress**: HTTP routing
- **HPA**: Horizontal Pod Autoscaler

---

## 🎉 CONGRATULATIONS!

You've completed the entire 10-week DevSecOps journey!

**You now have:**
✅ Complete CI/CD pipeline with Jenkins  
✅ Security scanning (OWASP, SonarQube, Trivy)  
✅ Container registry (AWS ECR)  
✅ Monitoring (Prometheus + Grafana)  
✅ Production Kubernetes deployment (AWS EKS)  
✅ Automated deployments  
✅ Portfolio-worthy project  
✅ Skills for 2026 DevSecOps roles  

**You're ready for DevSecOps positions! 🚀**

---

## 📚 Next Steps

1. **Add to Resume/Portfolio**
2. **Create Blog Posts** about your journey
3. **Practice** - Deploy other projects
4. **Learn More:**
   - Service Mesh (Istio)
   - GitOps (ArgoCD)
   - Advanced Kubernetes
   - Multi-cloud deployments

**Keep learning and building! 💪**
