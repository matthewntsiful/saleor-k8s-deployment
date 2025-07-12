#!/bin/bash

echo "🚀 Deploying Saleor to Kubernetes..."

# Deploy in correct order
echo "📁 Creating namespace..."
kubectl apply -f manifests/01-namespace.yaml

echo "🔐 Creating secrets..."
kubectl apply -f manifests/02-secret.yaml

echo "⚙️ Creating config..."
kubectl apply -f manifests/03-configmap.yaml

echo "💾 Creating persistent volume..."
kubectl apply -f manifests/04-postgres-pvc.yaml

echo "🗄️ Deploying PostgreSQL..."
kubectl apply -f manifests/05-postgres.yaml

echo "🔄 Deploying Redis..."
kubectl apply -f manifests/06-redis.yaml

echo "⏳ Waiting for databases to be ready..."
kubectl wait --for=condition=ready pod -l app=postgres -n saleor --timeout=120s
kubectl wait --for=condition=ready pod -l app=redis -n saleor --timeout=60s

echo "🛍️ Deploying Saleor..."
kubectl apply -f manifests/07-saleor-deployment.yaml

echo "🌐 Creating ingress..."
kubectl apply -f manifests/08-ingress.yaml

echo "📊 Deploying Dashboard..."
kubectl apply -f manifests/09-dashboard-deployment.yaml

echo "🌐 Creating dashboard ingress..."
kubectl apply -f manifests/10-dashboard-ingress.yaml

echo "✅ Deployment complete!"
echo ""
echo "📊 Check status:"
echo "kubectl get pods -n saleor"
echo ""
echo "🌐 Access application:"
echo "Add '127.0.0.1 saleor.local' to /etc/hosts"
echo "Then visit: http://saleor.local"