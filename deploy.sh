#!/bin/bash

# Nadsoft Kubernetes Deployment Script

set -e

echo "🚀 Starting Nadsoft Student Management System deployment..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl is not installed. Please install kubectl first."
    exit 1
fi

# Check if we can connect to Kubernetes cluster
if ! kubectl cluster-info &> /dev/null; then
    print_error "Cannot connect to Kubernetes cluster. Please check your kubeconfig."
    exit 1
fi

print_status "Connected to Kubernetes cluster"

# Build and load Docker images (for local development)
if [[ "$1" == "--build" ]]; then
    print_status "Building Docker images..."

    # Build images
    docker build -t nadsoft-frontend:latest ./frontend
    docker build -t nadsoft-backend:latest ./backend

    # If using minikube, load images
    if command -v minikube &> /dev/null && minikube status &> /dev/null; then
        print_status "Loading images to minikube..."
        minikube image load nadsoft-frontend:latest
        minikube image load nadsoft-backend:latest
    fi

    print_success "Docker images built and loaded"
fi

# Apply Kubernetes manifests
print_status "Applying Kubernetes manifests..."

# Apply in order
kubectl apply -f 01-namespace.yaml
sleep 2

kubectl apply -f 02-configmap.yaml
kubectl apply -f 03-secret.yaml
kubectl apply -f 04-persistent-volume.yaml
sleep 5

kubectl apply -f 05-mysql-deployment.yaml
print_status "Waiting for MySQL to be ready..."
kubectl wait --for=condition=ready pod -l app=mysql -n nadsoft --timeout=300s

kubectl apply -f 06-backend-deployment.yaml
print_status "Waiting for Backend to be ready..."
kubectl wait --for=condition=ready pod -l app=backend -n nadsoft --timeout=300s

kubectl apply -f 07-frontend-deployment.yaml
print_status "Waiting for Frontend to be ready..."
kubectl wait --for=condition=ready pod -l app=frontend -n nadsoft --timeout=300s

# Apply optional components
if [[ "$2" == "--with-ingress" ]]; then
    kubectl apply -f 08-ingress.yaml
    print_success "Ingress configured"
fi

if [[ "$3" == "--with-hpa" ]]; then
    kubectl apply -f 09-hpa.yaml
    print_success "HPA configured"
fi

print_success "All components deployed successfully!"

# Show status
echo ""
print_status "Deployment Status:"
kubectl get pods -n nadsoft -o wide

echo ""
print_status "Services:"
kubectl get svc -n nadsoft

# Port forwarding instructions
echo ""
print_status "To access the application locally, run:"
echo "kubectl port-forward -n nadsoft service/frontend-service 3000:3000"
echo "kubectl port-forward -n nadsoft service/backend-service 3001:3001"

echo ""
print_status "Or access via LoadBalancer (if configured):"
kubectl get svc -n nadsoft | grep LoadBalancer

echo ""
print_success "🎉 Nadsoft Student Management System is now running on Kubernetes!"

# Optional: Open port-forward automatically
if [[ "$4" == "--port-forward" ]]; then
    print_status "Starting port forwarding..."
    kubectl port-forward -n nadsoft service/frontend-service 3000:3000 &
    kubectl port-forward -n nadsoft service/backend-service 3001:3001 &
    print_success "Port forwarding started. Access the app at http://localhost:3000"
fi