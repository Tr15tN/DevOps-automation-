# Infrastructure Insight 🧐

## 🚀 Project Overview

**Infrastructure Insight** is a comprehensive DevOps infrastructure project demonstrating modern containerization, load balancing, and infrastructure monitoring. This project implements a diagnostic application deployed across a multi-server architecture with HAProxy load balancing, NGINX web servers, and a Node.js backend API.

### Key Features

- 🐳 **Containerized Infrastructure**: Docker-based deployment with Docker Compose orchestration
- ⚖️ **Load Balancing**: HAProxy with multiple algorithms (round-robin, weighted, least-connection)
- 🌐 **Web Servers**: Two NGINX instances serving frontend and proxying API requests
- 📊 **Real-time Metrics**: Backend API providing system diagnostics (CPU, memory, OS info)
- 🎨 **Modern UI**: Responsive, animated frontend with dark theme
- 🔒 **Security**: Firewall configuration scripts for production deployment
- 💾 **Backup System**: Automated backup and restore scripts for critical data
- 📈 **Monitoring**: Netdata integration for real-time system monitoring

---

## 🏗️ Architecture

```
┌─────────────────┐
│   Load Balancer │  HAProxy (port 8080)
│    (HAProxy)    │  Stats: port 8404
└────────┬────────┘
         │ Round-robin / Weighted / Least-conn
    ┌────┴────┐
    ▼         ▼
┌────────┐ ┌────────┐
│ NGINX  │ │ NGINX  │  Web Servers (ports 8081, 8082)
│ Web #1 │ │ Web #2 │  Serve frontend + proxy /api/*
└───┬────┘ └───┬────┘
    └──────┬───┘
           ▼
    ┌──────────┐
    │ Node.js  │          App Server (port 3000)
    │ Backend  │          /api/metrics endpoint
    └──────────┘
```

### Container Services

| Service | Image | Ports | Purpose |
|---------|-------|-------|---------|
| **load-balancer** | haproxy:2.8-alpine | 8080:80, 8404:8404 | Traffic distribution |
| **web-server-1** | nginx:1.25-alpine | 8081:80 | Frontend + API proxy |
| **web-server-2** | nginx:1.25-alpine | 8082:80 | Frontend + API proxy |
| **app-server** | Custom Node.js | 3000:3000 | Metrics API backend |
| **netdata** | netdata/netdata | 19999:19999 | System monitoring |

---

## 📋 Prerequisites

- **Docker Desktop** (Windows/Mac) or **Docker Engine** (Linux) v20.10+
- **Docker Compose** v2.0+
- **Git** for cloning the repository
- **8GB+ RAM** recommended
- **10GB+ free disk space**

For production VM deployment:
- Ubuntu 20.04+ or Debian 11+
- `curl`, `wget`, `rsync` (for backup scripts)
- Root or sudo access

---

## 🚀 Quick Start

### 1. Clone the Repository

```bash
git clone <your-repository-url>
cd server-sorcery-101
```

### 2. Start the Infrastructure

```bash
docker-compose up -d
```

### 3. Verify All Services

```bash
docker-compose ps
```

Expected output: All services showing `Up (healthy)`

### 4. Access the Application

- **Main Application (Load Balanced)**: http://localhost:8080
- **Web Server 1 (Direct)**: http://localhost:8081
- **Web Server 2 (Direct)**: http://localhost:8082
- **App Server API**: http://localhost:3000/api/metrics
- **HAProxy Stats**: http://localhost:8404/stats
- **Netdata Monitoring**: http://localhost:19999

---

## 📊 Application Features

### Frontend (`/`)

The responsive frontend displays real-time infrastructure metrics:

- **Host Information**: Hostname, OS type, architecture
- **CPU Metrics**: Core count, model, usage percentage, load averages
- **Memory Usage**: Total, used, free memory with percentage
- **Server Identification**: Shows which NGINX web server responded
- **Responsive Design**: Works on desktop, tablet, and mobile
- **Smooth Animations**: Subtle fade-in effects for better UX

### Backend API (`/api/metrics`)

The Node.js backend provides a comprehensive metrics endpoint:

```json
{
  "server": "app-server",
  "hostname": "abc123def456",
  "os": {
    "platform": "linux",
    "arch": "x64",
    "release": "5.15.0"
  },
  "cpu": {
    "cores": 8,
    "model": "Intel(R) Core(TM) i7-9700K",
    "speedMHz": 3600,
    "usagePercent": 23.45,
    "loadAverage": { "1m": 1.2, "5m": 0.9, "15m": 0.7 }
  },
  "memory": {
    "totalBytes": 16777216000,
    "freeBytes": 8388608000,
    "usedBytes": 8388608000,
    "usedPercent": 50.00
  },
  "network": {
    "interfaces": { /* Network interface details */ }
  },
  "timestamp": "2025-10-30T12:34:56.789Z"
}
```

---

## ⚖️ Load Balancing Algorithms

HAProxy supports multiple load balancing strategies. Edit `configs/haproxy/haproxy.cfg` to switch:

### 1. Round Robin (Default)

Distributes requests evenly across all servers.

```haproxy
backend be_web
    balance roundrobin
    server web1 web-server-1:80 check
    server web2 web-server-2:80 check
```

### 2. Weighted Round Robin

Gives more traffic to servers with higher weights (useful for unequal hardware).

```haproxy
backend be_web
    balance roundrobin
    server web1 web-server-1:80 check weight 3
    server web2 web-server-2:80 check weight 1
```

*Server 1 receives 75% of traffic, Server 2 receives 25%*

### 3. Least Connection

Routes to the server with the fewest active connections.

```haproxy
backend be_web
    balance leastconn
    server web1 web-server-1:80 check
    server web2 web-server-2:80 check
```

**To apply changes:**

```bash
docker-compose restart load-balancer
```

---

## 🛠️ Server Setup for Production

### Installing Docker

Run the installation script on each server:

```bash
chmod +x scripts/install_docker.sh
./scripts/install_docker.sh
```

This script:
- Installs Docker Engine and Docker Compose plugin
- Adds current user to `docker` group
- Configures Docker to start on boot

**Note**: Log out and back in for group membership to take effect.

### Configuring Firewall

Secure your servers with UFW firewall:

```bash
chmod +x scripts/configure_firewall.sh
sudo ./scripts/configure_firewall.sh
```

This opens necessary ports:
- **22**: SSH
- **8080**: Load balancer
- **8404**: HAProxy stats
- **8081, 8082**: Web servers (optional, for debugging)
- **3000**: App server API (optional, for debugging)
- **19999**: Netdata monitoring

### Deploying Containers

1. Transfer project files to each server:

```bash
rsync -avz --exclude 'node_modules' --exclude '.git' \
  ./ user@server-ip:/opt/infrastructure-insight/
```

2. SSH into the server and start services:

```bash
ssh user@server-ip
cd /opt/infrastructure-insight
docker-compose up -d
```

---

## 💾 Backup and Restore

### Setting Up Backup VM

1. **Transfer scripts to backup server:**

```bash
scp scripts/backup/*.sh backup-user@backup-server:/opt/backups/
```

2. **Test backup manually:**

```bash
ssh backup-user@backup-server
cd /opt/backups
chmod +x backup.sh restore.sh

# Backup from app server
./backup.sh devops@app-server-ip:/ /backups/app-server
```

### Automated Weekly Backups

Add to crontab on the backup server:

```bash
crontab -e
```

Insert:

```cron
# Weekly full backup every Sunday at 3 AM
0 3 * * 0 /opt/backups/backup.sh devops@10.0.0.10:/ /backups/server-01 >> /var/log/backup.log 2>&1
0 3 * * 0 /opt/backups/backup.sh devops@10.0.0.11:/ /backups/server-02 >> /var/log/backup.log 2>&1
```

### Restoring from Backup

```bash
# List available backups
ls -lh /backups/server-01/

# Restore specific backup
./restore.sh /backups/server-01/full-2025-10-30 10.0.0.10 devops
```

**⚠️ Warning**: Restore operations overwrite existing files. Test in staging first.

---

## 🧪 Testing and Validation

### Test Load Balancing

```bash
# Make multiple requests and observe server rotation
for i in {1..10}; do
  curl -s http://localhost:8080/health
  echo ""
done
```

You should see responses alternating between `OK web-server-1` and `OK web-server-2`.

### Test Metrics Endpoint

```bash
curl http://localhost:8080/api/metrics | jq
```

### Monitor HAProxy Stats

Visit http://localhost:8080/stats to see:
- Active connections per server
- Request rate
- Server health status
- Session information

### Health Checks

```bash
# Check all container health
docker-compose ps

# Individual service health
curl http://localhost:8080/health
curl http://localhost:3000/health
```

---

## 🔧 Configuration Files

### Key Configuration Locations

| File | Purpose |
|------|---------|
| `docker-compose.yml` | Container orchestration |
| `configs/haproxy/haproxy.cfg` | Load balancer settings |
| `configs/nginx/nginx1.conf` | Web server 1 configuration |
| `configs/nginx/nginx2.conf` | Web server 2 configuration |
| `docker/app-server/Dockerfile` | App server image build |
| `docker/app-server/server.js` | Backend API logic |
| `web-content/index.html` | Frontend application |

### Customizing the Backend

Edit `docker/app-server/server.js` to add new metrics or endpoints:

```javascript
app.get('/api/custom', async (req, res) => {
  // Your custom logic
  res.json({ custom: 'data' });
});
```

Rebuild and restart:

```bash
docker-compose up -d --build app-server
```

### Customizing the Frontend

Edit `web-content/index.html` to modify UI, add charts, or change styling.

Changes are reflected immediately (no rebuild needed):

```bash
docker-compose restart web-server-1 web-server-2
```

---

## 📈 Monitoring with Netdata

Access the Netdata dashboard at http://localhost:19999 to monitor:

- **CPU Usage**: Per-core utilization, temperature, frequency
- **Memory**: RAM usage, swap, cache
- **Disk I/O**: Read/write operations, IOPS
- **Network**: Bandwidth, packet rates, errors
- **Containers**: Per-container resource usage
- **Applications**: Process-level metrics

### Key Netdata Features

- Real-time charts (1-second granularity)
- Historical data retention
- Alerts and notifications
- Performance insights

---

## 🐛 Troubleshooting

### Containers Won't Start

```bash
# Check logs
docker-compose logs app-server
docker-compose logs web-server-1

# Check Docker daemon
docker info

# Rebuild from scratch
docker-compose down -v
docker-compose up -d --build
```

### Port Already in Use

```bash
# Find process using port 8080
sudo lsof -i :8080
# or
sudo netstat -tulpn | grep 8080

# Kill the process or change port in docker-compose.yml
```

### Health Checks Failing

```bash
# Enter container to debug
docker-compose exec app-server sh

# Test endpoint from inside container
curl http://localhost:3000/health

# Check logs for errors
docker-compose logs -f app-server
```

### Load Balancer Not Distributing Traffic

1. Check HAProxy stats: http://localhost:8404/stats
2. Verify both web servers show as "UP"
3. Check NGINX health: `curl http://localhost:8081/health`
4. Review HAProxy logs: `docker-compose logs load-balancer`

### Metrics Endpoint Returns Null CPU Usage

This is expected behavior if CPU sampling times out (1.5s). The endpoint returns other metrics successfully. This prevents the request from hanging indefinitely.

---

## 📁 Project Structure

```
server-sorcery-101/
├── docker-compose.yml              # Main orchestration file
├── README.md                       # This file
├── docker/
│   └── app-server/
│       ├── Dockerfile              # Backend container definition
│       ├── package.json            # Node.js dependencies
│       └── server.js               # Express API server
├── configs/
│   ├── haproxy/
│   │   └── haproxy.cfg             # Load balancer config
│   └── nginx/
│       ├── nginx1.conf             # Web server 1 config
│       └── nginx2.conf             # Web server 2 config
├── web-content/
│   └── index.html                  # Frontend application
├── scripts/
│   ├── install_docker.sh           # Docker installation script
│   ├── configure_firewall.sh       # UFW firewall setup
│   └── backup/
│       ├── backup.sh               # Weekly backup script
│       └── restore.sh              # Restore from backup
└── docs/                           # Additional documentation
```

---

## 🎯 Learning Outcomes

By working with this project, you'll learn:

1. **Containerization**: Docker image building, multi-container orchestration
2. **Load Balancing**: HAProxy configuration, algorithm comparison
3. **Web Servers**: NGINX reverse proxy, static content serving
4. **Backend Development**: Node.js/Express API, async patterns
5. **Frontend Development**: Responsive UI, REST API consumption
6. **DevOps Practices**: Automation, monitoring, backup strategies
7. **Networking**: Container networking, service discovery, health checks
8. **Security**: Firewall configuration, production hardening

---

## 🚀 Deployment Workflow

### Development

```bash
# Start services
docker-compose up

# View logs
docker-compose logs -f

# Stop services
docker-compose down
```

### Production

```bash
# Build and start in detached mode
docker-compose up -d --build

# Verify health
docker-compose ps
curl http://localhost:8080/health

# Monitor logs
docker-compose logs -f --tail=100

# Update application
git pull
docker-compose up -d --build app-server

# Rolling restart
docker-compose restart web-server-1
sleep 5
docker-compose restart web-server-2
```

---

## 🔐 Security Considerations

### Current Implementation

- ✅ Non-root container execution
- ✅ Health checks for reliability
- ✅ Resource limits (in docker-compose)
- ✅ Firewall configuration scripts
- ✅ Read-only config mounts

### Production Enhancements

For production deployment, consider adding:

- **HTTPS/TLS**: SSL certificates with Let's Encrypt
- **Authentication**: API key or OAuth for /api/* endpoints
- **Rate Limiting**: Prevent abuse with HAProxy stick tables
- **Secret Management**: Docker secrets or HashiCorp Vault
- **Network Segmentation**: Separate frontend/backend networks
- **Logging**: Centralized logging with ELK or Loki
- **Vulnerability Scanning**: Trivy, Clair, or Snyk integration

---

## 📚 Additional Resources

### Docker & Containerization

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Reference](https://docs.docker.com/compose/)
- [Container Best Practices](https://docs.docker.com/develop/dev-best-practices/)

### Load Balancing

- [HAProxy Documentation](http://www.haproxy.org/#docs)
- [NGINX Reverse Proxy Guide](https://docs.nginx.com/nginx/admin-guide/web-server/reverse-proxy/)

### Monitoring & Observability

- [Netdata Documentation](https://learn.netdata.cloud/)
- [Prometheus & Grafana](https://prometheus.io/docs/visualization/grafana/)

---

## 🤝 Contributing

This is an educational project. Feel free to:

- Experiment with different configurations
- Add new features (database integration, caching, etc.)
- Implement additional load balancing algorithms
- Enhance security measures
- Improve monitoring and alerting

---

## 📄 License

MIT License - Free to use for learning and development purposes.

---

## 🏆 Success Criteria

- ✅ All containers start and report healthy status
- ✅ Load balancer distributes traffic between web servers
- ✅ Frontend displays metrics from backend API
- ✅ HAProxy stats page shows server health
- ✅ Netdata provides real-time monitoring
- ✅ Backup and restore scripts function correctly
- ✅ Firewall rules secure production servers

---

**Ready to explore modern DevOps infrastructure? Start the containers and access http://localhost:8080 to see your infrastructure in action! 🚀**
