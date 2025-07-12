# Detailed Deployment Guide

## Pre-Deployment Checklist

### 1. Cluster Requirements
- Kubernetes 1.20+
- At least 4GB RAM available
- 2+ CPU cores
- 20GB+ storage

### 2. Required Add-ons
```bash
# Enable required minikube add-ons
minikube addons enable ingress
minikube addons enable storage-provisioner
minikube addons enable default-storageclass
```

### 3. Verify Cluster
```bash
kubectl cluster-info
kubectl get nodes
kubectl get storageclass
```

## Step-by-Step Deployment

### 1. Prepare Secrets
Before deployment, update the secret values:

```bash
# Generate SECRET_KEY
python3 -c "
import secrets
import base64
key = secrets.token_urlsafe(50)
encoded = base64.b64encode(key.encode()).decode()
print(f'SECRET_KEY: {encoded}')
"

# Generate strong database password
python3 -c "
import secrets
import base64
password = secrets.token_urlsafe(32)
encoded = base64.b64encode(password.encode()).decode()
print(f'DB_PASSWORD: {encoded}')
"
```

Update `k8s-manifests/02-secret.yaml` with generated values.

### 2. Deploy Infrastructure
```bash
# Create namespace
kubectl apply -f k8s-manifests/01-namespace.yaml

# Deploy secrets and config
kubectl apply -f k8s-manifests/02-secret.yaml
kubectl apply -f k8s-manifests/03-configmap.yaml

# Deploy storage
kubectl apply -f k8s-manifests/04-postgres-pvc.yaml
```

### 3. Deploy Data Layer
```bash
# Deploy PostgreSQL
kubectl apply -f k8s-manifests/05-postgres.yaml

# Deploy Redis
kubectl apply -f k8s-manifests/06-redis.yaml

# Wait for databases to be ready
kubectl wait --for=condition=ready pod -l app=postgres -n saleor --timeout=300s
kubectl wait --for=condition=ready pod -l app=redis -n saleor --timeout=120s
```

### 4. Deploy Application Layer
```bash
# Deploy Saleor API
kubectl apply -f k8s-manifests/07-saleor-deployment.yaml

# Deploy Dashboard
kubectl apply -f k8s-manifests/09-dashboard-deployment.yaml

# Wait for applications
kubectl wait --for=condition=ready pod -l app=saleor -n saleor --timeout=300s
kubectl wait --for=condition=ready pod -l app=saleor-dashboard -n saleor --timeout=180s
```

### 5. Configure External Access
```bash
# Deploy ingress
kubectl apply -f k8s-manifests/08-ingress.yaml
kubectl apply -f k8s-manifests/10-dashboard-ingress.yaml

# Verify ingress
kubectl get ingress -n saleor
```

## Post-Deployment Verification

### 1. Check Pod Status
```bash
kubectl get pods -n saleor
kubectl get services -n saleor
kubectl get ingress -n saleor
```

### 2. Test Database Connection
```bash
kubectl exec -it -n saleor deployment/postgres -- psql -U saleor -d saleor -c "\dt"
```

### 3. Test Redis Connection
```bash
kubectl exec -it -n saleor deployment/redis -- redis-cli ping
```

### 4. Test API Health
```bash
curl -I http://saleor.local/health/
```

### 5. Test GraphQL Endpoint
```bash
curl -X POST http://saleor.local/graphql/ \
  -H "Content-Type: application/json" \
  -d '{"query": "{ shop { name } }"}'
```

## Troubleshooting Common Issues

### Init Container Failures
```bash
# Check init container logs
kubectl logs -n saleor <pod-name> -c migrate

# Manual migration if needed
kubectl exec -it -n saleor deployment/saleor -- python manage.py migrate
```

### Image Pull Issues
```bash
# Check image availability
docker pull matthewntsiful/saleor-webapp:latest

# Load image into minikube
minikube image load matthewntsiful/saleor-webapp:latest
```

### Ingress Not Working
```bash
# Check ingress controller
kubectl get pods -n ingress-nginx

# Check ingress status
kubectl describe ingress -n saleor

# Test internal service
kubectl port-forward -n saleor service/saleor-service 8080:80
```

### Database Connection Issues
```bash
# Check PostgreSQL logs
kubectl logs -n saleor deployment/postgres

# Test connection from Saleor pod
kubectl exec -it -n saleor deployment/saleor -- python manage.py dbshell
```

## Performance Tuning

### Resource Optimization
Monitor resource usage:
```bash
kubectl top pods -n saleor
kubectl top nodes
```

Adjust resources based on usage patterns in the deployment YAML files.

### Database Performance
```bash
# Check database performance
kubectl exec -it -n saleor deployment/postgres -- psql -U saleor -d saleor -c "
SELECT schemaname,tablename,attname,n_distinct,correlation 
FROM pg_stats 
WHERE schemaname = 'public' 
ORDER BY n_distinct DESC LIMIT 10;
"
```

## Backup and Recovery

### Database Backup
```bash
# Create backup
kubectl exec -n saleor deployment/postgres -- pg_dump -U saleor saleor > saleor-backup-$(date +%Y%m%d).sql

# Restore backup
kubectl exec -i -n saleor deployment/postgres -- psql -U saleor -d saleor < saleor-backup.sql
```

### Configuration Backup
```bash
# Backup all configurations
kubectl get all,configmap,secret,pvc,ingress -n saleor -o yaml > saleor-k8s-backup.yaml
```

## Monitoring Setup

### Basic Monitoring
```bash
# Watch pod status
kubectl get pods -n saleor -w

# Monitor logs
kubectl logs -f -n saleor deployment/saleor
```

### Advanced Monitoring
For production, consider deploying:
- Prometheus for metrics
- Grafana for dashboards
- ELK stack for log aggregation
- Jaeger for distributed tracing

## Security Hardening

### Network Policies
Create network policies to restrict pod-to-pod communication:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: saleor-network-policy
  namespace: saleor
spec:
  podSelector:
    matchLabels:
      app: saleor
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: nginx-ingress
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: postgres
  - to:
    - podSelector:
        matchLabels:
          app: redis
```

### Pod Security Context
Add security contexts to all deployments:

```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  fsGroup: 1000
  capabilities:
    drop:
    - ALL
```

## Scaling Strategies

### Horizontal Pod Autoscaler
```bash
# Create HPA for Saleor API
kubectl autoscale deployment saleor -n saleor --cpu-percent=70 --min=2 --max=10

# Create HPA for Dashboard
kubectl autoscale deployment saleor-dashboard -n saleor --cpu-percent=80 --min=1 --max=5
```

### Vertical Pod Autoscaler
Install VPA and create VPA resources for automatic resource adjustment.

## Disaster Recovery

### Multi-Region Setup
For production, deploy across multiple availability zones:

1. Use regional persistent disks
2. Configure cross-zone load balancing
3. Set up database replication
4. Implement backup strategies

### Backup Automation
Create CronJobs for automated backups:

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: postgres-backup
  namespace: saleor
spec:
  schedule: "0 2 * * *"  # Daily at 2 AM
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: postgres-backup
            image: postgres:15
            command:
            - /bin/bash
            - -c
            - pg_dump -h postgres -U saleor saleor > /backup/saleor-$(date +%Y%m%d).sql
            volumeMounts:
            - name: backup-storage
              mountPath: /backup
          volumes:
          - name: backup-storage
            persistentVolumeClaim:
              claimName: backup-pvc
          restartPolicy: OnFailure
```