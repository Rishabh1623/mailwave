# Week 7-8: Monitoring Setup Guide

## 🎯 What We're Adding
- **Prometheus** (port 9090) - Metrics collection and storage
- **Grafana** (port 3001) - Visualization and dashboards
- **Backend Metrics** - Application performance monitoring

---

## ✅ Step 1: Update AWS Security Group

Add these inbound rules to your EC2 security group:

| Port | Protocol | Source | Description |
|------|----------|--------|-------------|
| 9090 | TCP | 0.0.0.0/0 | Prometheus |
| 3001 | TCP | 0.0.0.0/0 | Grafana |

**How to add:**
1. Go to AWS Console → EC2 → Security Groups
2. Select your instance's security group
3. Edit inbound rules → Add rule
4. Add both ports above
5. Save rules

---

## ✅ Step 2: Commit and Push Changes

```bash
git add .
git commit -m "Add Prometheus and Grafana monitoring - Week 7-8"
git push
```

---

## ✅ Step 3: Trigger Jenkins Build

The pipeline will:
1. Build backend with prom-client dependency
2. Deploy all services including Prometheus and Grafana
3. Start monitoring automatically

---

## ✅ Step 4: Access Monitoring Tools

After deployment completes:

### Prometheus
- URL: `http://13.218.28.204:9090`
- Check targets: Status → Targets
- Should see: prometheus, mailwave-backend, jenkins

### Grafana
- URL: `http://13.218.28.204:3001`
- Username: `admin`
- Password: `admin` (change on first login)

---

## ✅ Step 5: Configure Grafana

### Add Prometheus Data Source:
1. Login to Grafana
2. Configuration (⚙️) → Data Sources
3. Add data source → Prometheus
4. URL: `http://mailwave-prometheus:9090`
5. Click "Save & Test" (should show green checkmark)

### Import Pre-built Dashboards:
1. Dashboards (📊) → Import
2. Import these dashboard IDs:
   - **1860** - Node Exporter Full (system metrics)
   - **3662** - Prometheus 2.0 Overview
   - **7362** - MongoDB Overview (if available)

3. For each dashboard:
   - Enter the ID
   - Click "Load"
   - Select "Prometheus" as data source
   - Click "Import"

---

## ✅ Step 6: Create Custom Application Dashboard

1. Dashboards → New Dashboard → Add visualization
2. Select "Prometheus" data source
3. Add these panels:

### Panel 1: HTTP Request Rate
```promql
rate(http_requests_total[5m])
```

### Panel 2: Average Response Time
```promql
rate(http_request_duration_seconds_sum[5m]) / rate(http_request_duration_seconds_count[5m])
```

### Panel 3: Error Rate
```promql
rate(http_requests_total{status_code=~"5.."}[5m])
```

### Panel 4: Request Count by Route
```promql
sum by (route) (http_requests_total)
```

4. Save dashboard as "MailWave Application Metrics"

---

## ✅ Step 7: Verify Metrics

### Check Backend Metrics:
```bash
curl http://13.218.28.204:5000/metrics
```

Should see output like:
```
# HELP http_requests_total Total number of HTTP requests
# TYPE http_requests_total counter
http_requests_total{method="GET",route="/api/health",status_code="200"} 45

# HELP http_request_duration_seconds Duration of HTTP requests in seconds
# TYPE http_request_duration_seconds histogram
...
```

### Check Prometheus Targets:
1. Go to `http://13.218.28.204:9090/targets`
2. All targets should show "UP" status

---

## ✅ Step 8: Set Up Alerts (Optional)

### Create Alert Rule in Grafana:
1. Open your dashboard panel
2. Edit → Alert tab
3. Create alert rule:
   - **Name**: High Error Rate
   - **Condition**: `WHEN avg() OF query(A, 5m, now) IS ABOVE 0.05`
   - **Evaluate every**: 1m
   - **For**: 5m

4. Add notification channel:
   - Alerting → Notification channels
   - Add channel (Email/Slack)
   - Test notification

---

## 📊 What You'll Monitor

### Application Metrics:
- ✅ Request rate (requests/second)
- ✅ Response time (milliseconds)
- ✅ Error rate (%)
- ✅ Requests by endpoint

### System Metrics (if Node Exporter added):
- CPU usage
- Memory usage
- Disk I/O
- Network traffic

### Jenkins Metrics (if Jenkins plugin configured):
- Build duration
- Build success rate
- Queue time

---

## 🔍 Troubleshooting

### Prometheus not scraping backend:
```bash
# Check if metrics endpoint is accessible
docker exec mailwave-backend curl http://localhost:5000/metrics

# Check Prometheus logs
docker logs mailwave-prometheus
```

### Grafana can't connect to Prometheus:
- Make sure URL is `http://mailwave-prometheus:9090` (not localhost)
- Both containers must be on same network (mailwave-network)

### No data in dashboards:
- Wait 1-2 minutes for data to accumulate
- Check Prometheus targets are UP
- Verify queries in Explore tab

---

## 🎉 Success Criteria

- [ ] Prometheus accessible at :9090
- [ ] Grafana accessible at :3001
- [ ] Backend metrics endpoint working (/metrics)
- [ ] Prometheus showing all targets as UP
- [ ] Grafana connected to Prometheus
- [ ] At least one dashboard showing data
- [ ] Can see request metrics in real-time

---

## 📚 Next Steps

Once monitoring is working:
- Create custom dashboards for your needs
- Set up alerts for critical metrics
- Monitor during load testing
- Move to **Week 9-10: AWS EKS Deployment**

---

## 🔗 Useful Links

- Prometheus: http://13.218.28.204:9090
- Grafana: http://13.218.28.204:3001
- Backend Metrics: http://13.218.28.204:5000/metrics
- Grafana Dashboards: https://grafana.com/grafana/dashboards/
