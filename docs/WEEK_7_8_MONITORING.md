# Week 7-8: Monitoring with Prometheus & Grafana

## 🎯 Goals
- Install Prometheus on t3.medium
- Install Grafana on t3.medium
- Monitor Jenkins pipeline metrics
- Monitor application metrics
- Create dashboards
- Set up alerts

---

## Week 7: Prometheus Setup

### Day 1-2: Install Prometheus

**Add to docker-compose.yml:**

```yaml
  prometheus:
    image: prom/prometheus:latest
    container_name: mailwave-prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
    networks:
      - mailwave-network
    restart: unless-stopped

volumes:
  prometheus_data:
```

**Create prometheus/prometheus.yml:**

```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'mailwave-backend'
    static_configs:
      - targets: ['backend:5000']

  - job_name: 'mailwave-frontend'
    static_configs:
      - targets: ['frontend:3000']

  - job_name: 'mongodb'
    static_configs:
      - targets: ['mongodb:27017']

  - job_name: 'jenkins'
    static_configs:
      - targets: ['YOUR_EC2_IP:8080']
```

**Start Prometheus:**

```bash
docker-compose up -d prometheus
```

Access: `http://YOUR_EC2_IP:9090`

### Day 3-4: Instrument Backend with Metrics

**Install prom-client in backend:**

```bash
cd backend
npm install prom-client
```

**Update backend/server.js:**

```javascript
const promClient = require('prom-client');

// Create a Registry
const register = new promClient.Registry();

// Add default metrics
promClient.collectDefaultMetrics({ register });

// Custom metrics
const httpRequestDuration = new promClient.Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'route', 'status_code'],
  registers: [register]
});

// Middleware to track metrics
app.use((req, res, next) => {
  const start = Date.now();
  res.on('finish', () => {
    const duration = (Date.now() - start) / 1000;
    httpRequestDuration.labels(req.method, req.path, res.statusCode).observe(duration);
  });
  next();
});

// Metrics endpoint
app.get('/metrics', async (req, res) => {
  res.set('Content-Type', register.contentType);
  res.end(await register.metrics());
});
```

---

## Week 8: Grafana Setup

### Day 1-2: Install Grafana

**Add to docker-compose.yml:**

```yaml
  grafana:
    image: grafana/grafana:latest
    container_name: mailwave-grafana
    ports:
      - "3001:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
      - GF_USERS_ALLOW_SIGN_UP=false
    volumes:
      - grafana_data:/var/lib/grafana
    networks:
      - mailwave-network
    restart: unless-stopped
    depends_on:
      - prometheus

volumes:
  grafana_data:
```

**Start Grafana:**

```bash
docker-compose up -d grafana
```

Access: `http://YOUR_EC2_IP:3001`
- Username: `admin`
- Password: `admin` (change on first login)

### Day 3-4: Configure Grafana

**Add Prometheus Data Source:**

1. Grafana → Configuration → Data Sources
2. Add data source → Prometheus
3. URL: `http://prometheus:9090`
4. Click **Save & Test**

**Import Dashboards:**

1. Dashboards → Import
2. Import these dashboard IDs:
   - `1860` - Node Exporter Full
   - `3662` - Prometheus 2.0 Overview
   - `7362` - MongoDB Overview

### Day 5-6: Create Custom Dashboards

**Application Dashboard:**

1. Create New Dashboard
2. Add panels:
   - HTTP Request Rate
   - Response Time
   - Error Rate
   - Active Connections

**Example Queries:**

```promql
# Request rate
rate(http_request_duration_seconds_count[5m])

# Average response time
rate(http_request_duration_seconds_sum[5m]) / rate(http_request_duration_seconds_count[5m])

# Error rate
rate(http_request_duration_seconds_count{status_code=~"5.."}[5m])
```

### Day 7: Set Up Alerts

**Create Alert Rules:**

1. Dashboard → Panel → Alert
2. Configure conditions:
   - High error rate (>5%)
   - Slow response time (>1s)
   - Service down

**Configure Notification Channels:**

1. Alerting → Notification channels
2. Add Email/Slack channel
3. Test notification

---

## Complete docker-compose.yml with Monitoring

```yaml
version: '3.8'

services:
  mongodb:
    image: mongo:latest
    container_name: mailwave-mongodb
    ports:
      - "27017:27017"
    volumes:
      - mongodb_data:/data/db
    networks:
      - mailwave-network

  backend:
    build: ./backend
    container_name: mailwave-backend
    ports:
      - "5000:5000"
    environment:
      - PORT=5000
      - MONGODB_URI=mongodb://mongodb:27017/newsletter
      - NODE_ENV=production
    depends_on:
      - mongodb
    networks:
      - mailwave-network
    restart: unless-stopped

  frontend:
    build: ./frontend
    container_name: mailwave-frontend
    ports:
      - "3000:3000"
    environment:
      - REACT_APP_API_URL=http://YOUR_EC2_IP:5000/api
    depends_on:
      - backend
    networks:
      - mailwave-network
    restart: unless-stopped

  prometheus:
    image: prom/prometheus:latest
    container_name: mailwave-prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
    networks:
      - mailwave-network
    restart: unless-stopped

  grafana:
    image: grafana/grafana:latest
    container_name: mailwave-grafana
    ports:
      - "3001:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
      - GF_USERS_ALLOW_SIGN_UP=false
    volumes:
      - grafana_data:/var/lib/grafana
    networks:
      - mailwave-network
    restart: unless-stopped
    depends_on:
      - prometheus

volumes:
  mongodb_data:
  prometheus_data:
  grafana_data:

networks:
  mailwave-network:
    driver: bridge
```

---

## 🎉 Week 7-8 Completion Checklist

- [ ] Prometheus installed and running at :9090
- [ ] Grafana installed and running at :3001
- [ ] Prometheus scraping all services
- [ ] Backend instrumented with metrics
- [ ] Grafana connected to Prometheus
- [ ] Dashboards imported
- [ ] Custom application dashboard created
- [ ] Alerts configured
- [ ] Notification channels set up
- [ ] All metrics visible and accurate

---

## 📊 Key Metrics to Monitor

**Application:**
- Request rate (requests/second)
- Response time (milliseconds)
- Error rate (%)
- Active users

**Infrastructure:**
- CPU usage (%)
- Memory usage (%)
- Disk I/O
- Network traffic

**Jenkins:**
- Build duration
- Build success rate
- Queue time

---

## 📚 Next Steps

Once Week 7-8 is complete, move to:
👉 **Week 9-10: AWS EKS Deployment**

See: `docs/WEEK_9_10_EKS.md`
