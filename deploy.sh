#!/bin/bash

# Simple deployment script using Docker Hub images

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

print_info "🚀 Deploying Nadsoft using Docker Hub images..."

# Check kubectl
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl not found. Please install kubectl first."
    exit 1
fi

if ! kubectl cluster-info &> /dev/null; then
    print_error "Cannot connect to Kubernetes cluster."
    exit 1
fi

# Pull images from Docker Hub (optional, Kubernetes will pull automatically)
if [[ "$1" == "--pull" ]]; then
    print_info "Pulling images from Docker Hub..."
    docker pull ram8545/nadsoft-backend:v1.0.0
    docker pull ram8545/nadsoft-frontend:v1.0.0

    # Load to minikube if using minikube
    if command -v minikube &> /dev/null && minikube status &> /dev/null; then
        print_info "Loading images to minikube..."
        minikube image load ram8545/nadsoft-backend:v1.0.0
        minikube image load ram8545/nadsoft-frontend:v1.0.0
    fi

    print_success "Images pulled and loaded"
fi

# Deploy Kubernetes resources
print_info "Deploying to Kubernetes..."

kubectl apply -f 01-namespace.yaml
sleep 2

kubectl apply -f 02-configmap.yaml
kubectl apply -f 03-secrets.yaml
kubectl apply -f 04-persistent-volume.yaml
sleep 3

# MySQL
print_info "Deploying MySQL..."
kubectl apply -f 05-mysql-deployment.yaml
print_info "Waiting for MySQL to be ready..."
kubectl wait --for=condition=ready pod -l app=mysql -n nadsoft --timeout=300s

# Backend
print_info "Deploying Backend..."
kubectl apply -f 06-backend-deployment.yaml
print_info "Waiting for Backend to be ready..."
kubectl wait --for=condition=ready pod -l app=backend -n nadsoft --timeout=300s

# Frontend
print_info "Deploying Frontend..."
kubectl apply -f 07-frontend-deployment.yaml
print_info "Waiting for Frontend to be ready..."
kubectl wait --for=condition=ready pod -l app=frontend -n nadsoft --timeout=300s

print_success "All services deployed successfully! 🎉"

# Show status
echo ""
print_info "=== DEPLOYMENT STATUS ==="
kubectl get pods -n nadsoft -o wide

echo ""
print_info "=== SERVICES ==="
kubectl get svc -n nadsoft

# Access instructions
echo ""
print_info "=== ACCESS YOUR APPLICATION ==="
echo "Run these commands in separate terminals:"
echo ""
echo "1. Frontend: kubectl port-forward -n nadsoft service/frontend-service 3000:3000"
echo "   Then open: http://localhost:3000"
echo ""
echo "2. Backend:  kubectl port-forward -n nadsoft service/backend-service 3001:3001"
echo "   Then test: http://localhost:3001/api/students"
echo ""

# Auto port-forward if requested
if [[ "$2" == "--port-forward" ]] || [[ "$1" == "--port-forward" ]]; then
    print_info "Starting port forwarding..."
    kubectl port-forward -n nadsoft service/frontend-service 3000:3000 > /dev/null 2>&1 &
    kubectl port-forward -n nadsoft service/backend-service 3001:3001 > /dev/null 2>&1 &
    sleep 2
    print_success "Port forwarding started!"
    echo ""
    echo "🌐 Frontend: http://localhost:3000"
    echo "🔗 Backend:  http://localhost:3001/api/students"
    echo ""
    print_warning "Keep this terminal open or press Ctrl+C to stop port forwarding"

    # Keep script running
    trap 'print_info "Stopping port forwarding..."; pkill -f "kubectl port-forward"; exit 0' INT
    while true; do sleep 30; done
fi