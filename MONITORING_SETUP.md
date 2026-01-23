# 📊 Week 7-8: Monitoring Setup Guide

## ✅ What's Already Configured

### 1. Prometheus
- **Container**: `mailwave-prometheus`
- **Port**: 9090
- **Config**: `prometheus/prometheus.yml`
- **Scraping**: Backend metrics, Jenkins, MongoDB

### 2. Grafana
- **Container**: `mailwave-grafana`
- **Port**: 3001
- **Default Login**: admin/admin
- **Connected to**: Prometheus

### 3. Backend Metrics
- **Endpoint**: http://13.218.28.204:5000/metrics
- **Metrics**:
  - `http_request_duration_seconds` - Request latency
  - `http_requests_total` - Total requests
  - `process_cpu_seconds_total` - CPU usage
  - `process_resident_memory_bytes` - Memory usage
  - `nodejs_*` - Node.js specific metrics

---

## 🚀 Quick Start

### Step 1: Deploy Monitoring Stack
Run a new Jenkins build to deploy Prometheus and Grafana:

```bash
# On EC2, after Jenkins build completes:
docker ps | grep -E "prometheus|grafana"
```

### Step 2: Access Services
- **Prometheus**: http://13.218.28.204:9090
- **Grafana**: http://13.218.28.204:3001
- **Backend Metrics**: http://13.218.28.204:5000/metrics

### Step 3: Configure Grafana

#### Add Prometheus Data Source
1. Login to Grafana: http://13.218.28.204:3001
   - Username: `admin`
   - Password: `admin` (change on first login)

2. Go to: **Configuration** → **Data Sources** → **Add data source**

3. Select **Prometheus**

4. Configure:
   - **Name**: Prometheus
   - **URL**: `http://mailwave-prometheus:9090`
   - Click **Save & Test**

#### Import Pre-built Dashboards
1. Go to: **Dashboards** → **Import**

2. Import these dashboard IDs:
   - **1860** - Node Exporter Full (system metrics)
   - **3662** - Prometheus 2.0 Overview
   - **11074** - Node.js Application Dashboard

3. Select **Prometheus** as data source

---

## 📈 Custom Dashboard Queries

### Request Rate (requests per second)
```promql
rate(http_requests_total[5m])
```

### Average Response Time
```promql
rate(http_request_duration_seconds_sum[5m]) / rate(http_request_duration_seconds_count[5m])
```

### Error Rate (5xx errors)
```promql
rate(http_requests_total{status_code=~"5.."}[5m])
```

### Memory Usage
```promql
process_resident_memory_bytes / 1024 / 1024
```

### CPU Usage
```promql
rate(process_cpu_seconds_total[5m]) * 100
```

---

## 🎯 Create Custom Application Dashboard

### Step 1: Create New Dashboard
1. **Dashboards** → **New Dashboard** → **Add new panel**

### Step 2: Add Panels

#### Panel 1: Request Rate
- **Query**: `rate(http_requests_total[5m])`
- **Title**: HTTP Requests per Second
- **Visualization**: Graph

#### Panel 2: Response Time
- **Query**: `rate(http_request_duration_seconds_sum[5m]) / rate(http_request_duration_seconds_count[5m])`
- **Title**: Average Response Time (seconds)
- **Visualization**: Graph

#### Panel 3: Error Rate
- **Query**: `rate(http_requests_total{status_code=~"5.."}[5m])`
- **Title**: Error Rate (5xx)
- **Visualization**: Graph
- **Alert**: Set threshold > 0.1

#### Panel 4: Memory Usage
- **Query**: `process_resident_memory_bytes / 1024 / 1024`
- **Title**: Memory Usage (MB)
- **Visualization**: Gauge

#### Panel 5: CPU Usage
- **Query**: `rate(process_cpu_seconds_total[5m]) * 100`
- **Title**: CPU Usage (%)
- **Visualization**: Gauge

### Step 3: Save Dashboard
- Click **Save dashboard**
- Name: `MailWave Application Metrics`

---

## 🔔 Set Up Alerts

### Step 1: Configure Notification Channel
1. **Alerting** → **Notification channels** → **Add channel**

2. Choose type:
   - **Email**: rishabhmadne1623@gmail.com
   - **Slack**: #new-channel

3. Test notification

### Step 2: Create Alert Rules

#### High Error Rate Alert
1. Edit **Error Rate** panel
2. Click **Alert** tab
3. Configure:
   - **Name**: High Error Rate
   - **Condition**: WHEN avg() OF query(A, 5m) IS ABOVE 0.1
   - **Notification**: Send to your channel

#### High Response Time Alert
1. Edit **Response Time** panel
2. Configure:
   - **Name**: Slow Response Time
   - **Condition**: WHEN avg() OF query(A, 5m) IS ABOVE 1
   - **Notification**: Send to your channel

---

## 🧪 Test Metrics

### Generate Traffic
```bash
# On EC2 or local machine
for i in {1..100}; do
  curl http://13.218.28.204:5000/api/health
  curl http://13.218.28.204:5000/api/posts
  sleep 0.1
done
```

### View Metrics
```bash
# Check backend metrics endpoint
curl http://13.218.28.204:5000/metrics

# Check Prometheus targets
# Go to: http://13.218.28.204:9090/targets
```

---

## 📊 Key Metrics to Monitor

### Application Health
- ✅ Request rate (normal: 10-100 req/s)
- ✅ Response time (target: < 200ms)
- ✅ Error rate (target: < 1%)
- ✅ Uptime (target: 99.9%)

### System Health
- ✅ CPU usage (target: < 70%)
- ✅ Memory usage (target: < 80%)
- ✅ Disk usage (target: < 80%)
- ✅ Network I/O

### Jenkins Metrics
- ✅ Build duration
- ✅ Build success rate
- ✅ Queue time

---

## 🎉 Week 7-8 Completion Checklist

- [ ] Prometheus running at :9090
- [ ] Grafana running at :3001
- [ ] Prometheus scraping backend metrics
- [ ] Grafana connected to Prometheus
- [ ] Pre-built dashboards imported
- [ ] Custom application dashboard created
- [ ] Alerts configured
- [ ] Notification channels set up
- [ ] Test traffic generated
- [ ] All metrics visible and accurate

---

## 🔧 Troubleshooting

### Prometheus not scraping backend
```bash
# Check if backend metrics endpoint is accessible
curl http://mailwave-backend:5000/metrics

# Check Prometheus targets
# Go to: http://13.218.28.204:9090/targets
```

### Grafana can't connect to Prometheus
- Use internal Docker network URL: `http://mailwave-prometheus:9090`
- NOT: `http://localhost:9090` or `http://13.218.28.204:9090`

### No data in dashboards
- Wait 1-2 minutes for Prometheus to scrape metrics
- Generate some traffic to the application
- Check Prometheus targets are UP

---

## 📚 Next Steps

Once Week 7-8 is complete:
👉 **Week 9-10: AWS EKS Deployment**

See: `docs/WEEK_9_10_EKS.md`
