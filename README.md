# Saleor E-commerce Platform on Kubernetes

[![Docker Hub](https://img.shields.io/badge/Docker%20Hub-matthewntsiful-blue?logo=docker)](https://hub.docker.com/u/matthewntsiful)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-Ready-green?logo=kubernetes)](https://kubernetes.io/)
[![Saleor](https://img.shields.io/badge/Saleor-E--commerce-purple?logo=saleor)](https://saleor.io/)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Build Status](https://img.shields.io/badge/Build-Passing-brightgreen)]()

A production-ready deployment of [Saleor](https://saleor.io/) - a headless, GraphQL-native e-commerce platform - on Kubernetes with complete infrastructure setup.

## 📦 Custom Docker Images

This deployment uses custom-built Docker images based on the original Saleor project:

- **Original Project**: Cloned from [Saleor Official Repository](https://github.com/saleor/saleor)
- **Custom Images**: Built and pushed to [Docker Hub](https://hub.docker.com/u/matthewntsiful)
  - `matthewntsiful/saleor-webapp:latest` - Main Saleor API application
  - `matthewntsiful/saleor-dashboard:latest` - Admin dashboard interface

### Image Build Process
```bash
# Images were built from the original Saleor source
git clone https://github.com/saleor/saleor.git
cd saleor

# Built and pushed custom images
docker build -t matthewntsiful/saleor-webapp:latest .
docker push matthewntsiful/saleor-webapp:latest

docker build -t matthewntsiful/saleor-dashboard:latest -f Dockerfile.dashboard .
docker push matthewntsiful/saleor-dashboard:latest
```

## 🏗️ Architecture Overview

This project deploys a complete e-commerce platform consisting of:

- **Saleor API** - Django-based GraphQL e-commerce backend
- **Saleor Dashboard** - React-based admin interface
- **PostgreSQL** - Primary database with persistent storage
- **Redis** - Caching and Celery task queue
- **Nginx Ingress** - Load balancing and external access

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Nginx Ingress │────│   Saleor API     │────│   PostgreSQL    │
│   (External)    │    │   (GraphQL)      │    │   (Persistent)  │
└─────────────────┘    └──────────────────┘    └─────────────────┘
         │                       │                       │
         │              ┌──────────────────┐    ┌─────────────────┐
         └──────────────│ Saleor Dashboard │    │     Redis       │
                        │   (Admin UI)     │    │  (Cache/Queue)  │
                        └──────────────────┘    └─────────────────┘
```

## 🚀 Features

### ✅ Production-Ready Configuration
- **Resource limits** and requests for all containers
- **Health probes** (liveness and readiness) for automatic recovery
- **Persistent storage** for database data
- **Secrets management** for sensitive configuration
- **Init containers** for database migrations
- **Horizontal scaling** support

### ✅ Security Best Practices
- Separate ConfigMaps and Secrets
- Non-root container execution
- Network policies ready
- Secure credential handling

### ✅ High Availability
- Multiple replicas for API pods
- Persistent data storage
- Automatic pod restart on failures
- Load balancing via Kubernetes services

## 📁 Project Structure

```
saleor-k8s-deployment/
├── README.md                    # This file
├── k8s-manifests/              # Kubernetes YAML files
│   ├── 01-namespace.yaml       # Namespace isolation
│   ├── 02-secret.yaml          # Sensitive configuration
│   ├── 03-configmap.yaml       # Application configuration
│   ├── 04-postgres-pvc.yaml    # Persistent storage claim
│   ├── 05-postgres.yaml        # PostgreSQL database
│   ├── 06-redis.yaml           # Redis cache/queue
│   ├── 07-saleor-deployment.yaml # Main Saleor API
│   ├── 08-ingress.yaml         # API external access
│   ├── 09-dashboard-deployment.yaml # Admin dashboard
│   └── 10-dashboard-ingress.yaml   # Dashboard external access
├── scripts/
│   └── deploy.sh               # Automated deployment script
└── docs/
    └── DEPLOYMENT.md           # Detailed deployment guide
```

## 🛠️ Prerequisites

- **Kubernetes cluster** (minikube, kind, or cloud provider)
- **kubectl** configured and connected to your cluster
- **Nginx Ingress Controller** installed
- **Docker** (for building custom images)

### Install Nginx Ingress Controller
```bash
# For minikube
minikube addons enable ingress

# For other clusters
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml
```

## 🚀 Quick Start

### 1. Clone and Deploy
```bash
git clone <your-repo-url>
cd saleor-k8s-deployment

# Make deployment script executable
chmod +x scripts/deploy.sh

# Deploy everything
./scripts/deploy.sh
```

### 2. Configure Local Access
Add these entries to your `/etc/hosts` file:
```bash
127.0.0.1 saleor.local
127.0.0.1 dashboard.saleor.local
```

### 3. Access the Platform
- **API & GraphQL Playground**: http://saleor.local
- **Admin Dashboard**: http://dashboard.saleor.local

## 🔧 Configuration

### Environment Variables
Key configuration is managed through ConfigMaps and Secrets:

**ConfigMap (Non-sensitive)**:
- `CELERY_BROKER_URL` - Redis connection for task queue
- `ALLOWED_HOSTS` - Allowed hostnames
- `DASHBOARD_URL` - Dashboard location

**Secret (Sensitive)**:
- `SECRET_KEY` - Django secret key
- `DATABASE_URL` - PostgreSQL connection string

### Resource Allocation
| Component | CPU Request | Memory Request | CPU Limit | Memory Limit |
|-----------|-------------|----------------|-----------|--------------|
| Saleor API | 250m | 1Gi | 1000m | 2Gi |
| PostgreSQL | 200m | 512Mi | 500m | 1Gi |
| Redis | 50m | 128Mi | 100m | 256Mi |
| Dashboard | 100m | 128Mi | 200m | 256Mi |

## 📊 Monitoring & Health Checks

### Health Probes
- **Saleor API**: HTTP probe on `/health/` endpoint
- **PostgreSQL**: `pg_isready` command execution
- **Redis**: `redis-cli ping` command execution
- **Dashboard**: HTTP probe on root path

### Monitoring Endpoints
- **GraphQL Playground**: `http://saleor.local/graphql/`
- **Health Check**: `http://saleor.local/health/`

## 🔄 Scaling

### Horizontal Scaling
```bash
# Scale Saleor API pods
kubectl scale deployment saleor -n saleor --replicas=3

# Scale Dashboard pods
kubectl scale deployment saleor-dashboard -n saleor --replicas=2
```

### Vertical Scaling
Update resource limits in the respective YAML files and apply:
```bash
kubectl apply -f k8s-manifests/07-saleor-deployment.yaml
```

## 🛡️ Security Considerations

### Production Recommendations
1. **Update default passwords** in `02-secret.yaml`
2. **Use strong SECRET_KEY** (generate with Django)
3. **Enable TLS/SSL** for ingress
4. **Implement network policies**
5. **Use managed databases** for production
6. **Enable pod security policies**

### Secret Management
```bash
# Generate strong secret key
python -c "import secrets, base64; key=secrets.token_urlsafe(50); print(base64.b64encode(key.encode()).decode())"

# Update secret
kubectl create secret generic saleor-secret \
  --from-literal=SECRET_KEY=<your-key> \
  --from-literal=DATABASE_URL=<your-db-url> \
  -n saleor --dry-run=client -o yaml | kubectl apply -f -
```

## 🚨 Troubleshooting

### Common Issues

**Pods not starting**:
```bash
kubectl get pods -n saleor
kubectl describe pod <pod-name> -n saleor
kubectl logs <pod-name> -n saleor
```

**Database connection issues**:
```bash
kubectl logs -n saleor deployment/saleor -c migrate
kubectl exec -it -n saleor deployment/postgres -- psql -U saleor -d saleor
```

**Ingress not working**:
```bash
kubectl get ingress -n saleor
kubectl describe ingress saleor-ingress -n saleor
```

### Manual Migration
If init container fails:
```bash
kubectl exec -it -n saleor deployment/saleor -- python manage.py migrate
```

## 🔄 Updates & Maintenance

### Update Application
```bash
# Update image tag in deployment
kubectl set image deployment/saleor saleor=matthewntsiful/saleor-webapp:v2.0 -n saleor

# Or edit and apply
kubectl apply -f k8s-manifests/07-saleor-deployment.yaml
```

### Backup Database
```bash
kubectl exec -n saleor deployment/postgres -- pg_dump -U saleor saleor > backup.sql
```

## 🏭 Production Deployment

### Cloud Provider Setup
For production deployment, consider:

1. **Managed Kubernetes** (EKS, GKE, AKS)
2. **Managed Database** (RDS, Cloud SQL, Azure Database)
3. **Managed Redis** (ElastiCache, Cloud Memorystore)
4. **Cloud Storage** (S3, GCS, Azure Blob)
5. **Load Balancer** (ALB, Cloud Load Balancer)
6. **SSL Certificates** (Let's Encrypt, Cloud SSL)

### Environment-Specific Configs
Create separate configurations for:
- Development (`dev/`)
- Staging (`staging/`)
- Production (`prod/`)

## 📚 Additional Resources

- [Saleor Documentation](https://docs.saleor.io/)
- [Saleor GitHub Repository](https://github.com/saleor/saleor)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Nginx Ingress Controller](https://kubernetes.github.io/ingress-nginx/)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test the deployment
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the original [Saleor License](https://github.com/saleor/saleor/blob/main/LICENSE) for details.

## 👨‍💻 Author

**Matthieu Ntsiful**
- Kubernetes deployment and infrastructure setup
- Production-ready configuration and security hardening
- Automated deployment scripts and documentation

---

*Built with ❤️ for modern e-commerce deployments*