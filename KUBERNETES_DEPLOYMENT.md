# Kubernetes Deployment Guide

This guide will help you deploy the Nadsoft Student Management System on Kubernetes.

## 📋 Prerequisites

- Kubernetes cluster (local or cloud)
- `kubectl` configured to connect to your cluster
- Docker images built (`nadsoft-frontend` and `nadsoft-backend`)

### For Local Development:
- **minikube** or **Docker Desktop** with Kubernetes enabled
- **kubectl** installed

### For Cloud Deployment:
- **EKS** (AWS), **GKE** (Google Cloud), or **AKS** (Azure)
- **Ingress Controller** (nginx, traefik, etc.)

## 🗂️ File Structure

```
kubernetes/
├── 01-namespace.yaml          # Namespace definition
├── 02-configmap.yaml          # Configuration data
├── 03-secrets.yaml            # Sensitive data (passwords)
├── 04-persistent-volume.yaml  # Storage for MySQL
├── 05-mysql-deployment.yaml   # MySQL database
├── 06-backend-deployment.yaml # Node.js API
├── 07-frontend-deployment.yaml# React frontend
├── 08-ingress.yaml            # External access (optional)
├── 09-hpa.yaml                # Auto-scaling (optional)
└── deploy.sh                  # Deployment script
```

## 🚀 Quick Deployment

### Option 1: Using the Deployment Script (Recommended)

```bash
# Make the script executable
chmod +x deploy.sh

# Deploy with building images (for local development)
./deploy.sh --build

# Deploy with ingress and HPA
./deploy.sh --build --with-ingress --with-hpa

# Deploy with automatic port forwarding
./deploy.sh --build --port-forward
```

### Option 2: Manual Deployment

```bash
# 1. Create namespace and configs
kubectl apply -f 01-namespace.yaml
kubectl apply -f 02-configmap.yaml
kubectl apply -f 03-secrets.yaml
kubectl apply -f 04-persistent-volume.yaml

# 2. Deploy MySQL (wait for it to be ready)
kubectl apply -f 05-mysql-deployment.yaml
kubectl wait --for=condition=ready pod -l app=mysql -n nadsoft --timeout=300s

# 3. Deploy Backend (wait for it to be ready)
kubectl apply -f 06-backend-deployment.yaml
kubectl wait --for=condition=ready pod -l app=backend -n nadsoft --timeout=300s

# 4. Deploy Frontend
kubectl apply -f 07-frontend-deployment.yaml

# 5. (Optional) Deploy Ingress and HPA
kubectl apply -f 08-ingress.yaml
kubectl apply -f 09-hpa.yaml
```

## 🔧 Configuration

### Secrets (03-secrets.yaml)

Update the base64 encoded passwords:

```bash
# Encode your passwords
echo -n "your_password" | base64

# Or use stringData for automatic encoding (see commented section)
```

### ConfigMap (02-configmap.yaml)

Update database and application configuration as needed.

### Ingress (08-ingress.yaml)

Update the host domain:
```yaml
rules:
- host: your-domain.com  # Change this
```

## 🌐 Accessing the Application

### Local Development (Port Forwarding)

```bash
# Frontend
kubectl port-forward -n nadsoft service/frontend-service 3000:3000

# Backend API
kubectl port-forward -n nadsoft service/backend-service 3001:3001

# MySQL (for debugging)
kubectl port-forward -n nadsoft service/mysql-service 3306:3306
```

Access: http://localhost:3000

### With Ingress

1. Configure your `/etc/hosts` file:
   ```
   127.0.0.1 nadsoft.local
   ```

2. Access: http://nadsoft.local

### With LoadBalancer (Cloud)

```bash
# Get external IP
kubectl get svc -n nadsoft

# Access using the external IP
```

## 📊 Monitoring and Management

### Check Deployment Status

```bash
# All resources in namespace
kubectl get all -n nadsoft

# Pods with details
kubectl get pods -n nadsoft -o wide

# Services
kubectl get svc -n nadsoft

# Persistent volumes
kubectl get pv,pvc -n nadsoft
```

### View Logs

```bash
# Frontend logs
kubectl logs -f deployment/frontend-deployment -n nadsoft

# Backend logs
kubectl logs -f deployment/backend-deployment -n nadsoft

# MySQL logs
kubectl logs -f deployment/mysql-deployment -n nadsoft
```

### Scaling Applications

```bash
# Manual scaling
kubectl scale deployment backend-deployment --replicas=5 -n nadsoft
kubectl scale deployment frontend-deployment --replicas=3 -n nadsoft

# Check HPA status (if enabled)
kubectl get hpa -n nadsoft
```

## 🐛 Troubleshooting

### Common Issues

1. **Pods not starting**
   ```bash
   kubectl describe pod <pod-name> -n nadsoft
   kubectl logs <pod-name> -n nadsoft
   ```

2. **Image pull errors**
   ```bash
   # For local images, ensure they're loaded
   minikube image ls | grep nadsoft

   # Load images if missing
   minikube image load nadsoft-frontend:latest
   minikube image load nadsoft-backend:latest
   ```

3. **Database connection issues**
   ```bash
   # Check MySQL pod
   kubectl exec -it deployment/mysql-deployment -n nadsoft -- mysql -u nadsoft_user -p

   # Check connectivity from backend
   kubectl exec -it deployment/backend-deployment -n nadsoft -- nslookup mysql-service
   ```

4. **Service discovery issues**
   ```bash
   # Check service endpoints
   kubectl get endpoints -n nadsoft

   # Test service connectivity
   kubectl run test-pod --image=busybox -n nadsoft --rm -it -- nslookup mysql-service
   ```

### Debug Commands

```bash
# Get events
kubectl get events -n nadsoft --sort-by='.lastTimestamp'

# Describe resources
kubectl describe deployment backend-deployment -n nadsoft
kubectl describe service backend-service -n nadsoft

# Access pod shell
kubectl exec -it deployment/backend-deployment -n nadsoft -- sh

# Check resource usage
kubectl top pods -n nadsoft
kubectl top nodes
```

## 🔄 Updates and Rollbacks

### Update Application

```bash
# Update image
kubectl set image deployment/backend-deployment backend=nadsoft-backend:v2 -n nadsoft

# Check rollout status
kubectl rollout status deployment/backend-deployment -n nadsoft

# Rollback if needed
kubectl rollout undo deployment/backend-deployment -n nadsoft
```

### Configuration Updates

```bash
# Update ConfigMap or Secret
kubectl apply -f 02-configmap.yaml
kubectl apply -f 03-secrets.yaml

# Restart deployments to pick up changes
kubectl rollout restart deployment/backend-deployment -n nadsoft
kubectl rollout restart deployment/frontend-deployment -n nadsoft
```

## 🧹 Cleanup

### Remove Everything

```bash
# Delete namespace (removes all resources)
kubectl delete namespace nadsoft

# Or delete individual resources
kubectl delete -f .
```

### Remove Persistent Data

```bash
# Delete PVC (this will delete MySQL data)
kubectl delete pvc mysql-pvc -n nadsoft
```

## 🏗️ Production Considerations

### Security
- Use proper RBAC
- Network policies
- Pod security policies
- Encrypt secrets at rest

### High Availability
- Multi-zone deployment
- MySQL clustering (or managed database)
- Load balancer configuration

### Monitoring
- Add Prometheus/Grafana
- Configure alerts
- Log aggregation (ELK stack)

### Backup
- Regular database backups
- PV snapshots
- Configuration backups

### Performance
- Resource limits and requests
- HPA configuration
- Node affinity rules

## 🔗 Useful Commands Cheatsheet

```bash
# Quick status check
kubectl get pods,svc,pvc -n nadsoft

# Watch pod status
kubectl get pods -n nadsoft -w

# Port forward all services (run in separate terminals)
kubectl port-forward -n nadsoft svc/frontend-service 3000:3000 &
kubectl port-forward -n nadsoft svc/backend-service 3001:3001 &
kubectl port-forward -n nadsoft svc/mysql-service 3306:3306 &

# Scale down everything (for cost savings)
kubectl scale deployment --all --replicas=0 -n nadsoft

# Scale back up
kubectl scale deployment backend-deployment --replicas=2 -n nadsoft
kubectl scale deployment frontend-deployment --replicas=2 -n nadsoft
kubectl scale deployment mysql-deployment --replicas=1 -n nadsoft
```

## 🤝 Support

For issues and questions:
- Check the troubleshooting section
- Review Kubernetes events: `kubectl get events -n nadsoft`
- Check application logs
- Verify resource limits and requests

---

**Happy Deploying! 🎉**