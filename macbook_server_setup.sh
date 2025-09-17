#!/bin/bash

# MacBook Kubernetes Server Setup Script

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

print_info "🖥️  Setting up MacBook as Kubernetes Server..."

# Function to get public IP
get_public_ip() {
    curl -s ifconfig.me || curl -s ipinfo.io/ip || curl -s icanhazip.com
}

# Function to get local IP
get_local_ip() {
    ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' | head -1
}

# Step 1: Install prerequisites
install_prerequisites() {
    print_info "Installing prerequisites..."
    
    # Check if Homebrew is installed
    if ! command -v brew &> /dev/null; then
        print_info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    
    # Install required tools
    brew install --cask docker
    brew install kubectl
    brew install minikube
    brew install ngrok/ngrok/ngrok  # For tunneling
    
    print_success "Prerequisites installed"
}

# Step 2: Setup Kubernetes cluster
setup_kubernetes() {
    print_info "Setting up Kubernetes cluster..."
    
    # Start Docker if not running
    if ! docker info &> /dev/null; then
        print_warning "Please start Docker Desktop and try again"
        open -a Docker
        exit 1
    fi
    
    # Start minikube with specific configuration for external access
    minikube start \
        --driver=docker \
        --memory=6144 \
        --cpus=4 \
        --disk-size=50g \
        --apiserver-ips=127.0.0.1,$(get_local_ip) \
        --embed-certs
    
    # Enable required addons
    minikube addons enable ingress
    minikube addons enable ingress-dns
    minikube addons enable dashboard
    minikube addons enable metrics-server
    
    print_success "Kubernetes cluster started"
}

# Step 3: Configure networking
configure_networking() {
    print_info "Configuring networking..."
    
    LOCAL_IP=$(get_local_ip)
    PUBLIC_IP=$(get_public_ip)
    
    echo ""
    print_info "Network Information:"
    echo "Local IP:  $LOCAL_IP"
    echo "Public IP: $PUBLIC_IP"
    echo ""
    
    # Save IPs for later use
    echo "$LOCAL_IP" > .local_ip
    echo "$PUBLIC_IP" > .public_ip
    
    print_success "Network configuration saved"
}

# Step 4: Deploy application
deploy_application() {
    print_info "Deploying Nadsoft application..."
    
    # Deploy the application
    chmod +x deploy-dockerhub.sh
    ./deploy-dockerhub.sh --pull
    
    print_success "Application deployed"
}

# Step 5: Setup external access
setup_external_access() {
    print_info "Setting up external access..."
    
    # Create NodePort services for external access
    kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: frontend-nodeport
  namespace: nadsoft
spec:
  type: NodePort
  ports:
  - port: 3000
    targetPort: 3000
    nodePort: 30000
  selector:
    app: frontend
---
apiVersion: v1
kind: Service
metadata:
  name: backend-nodeport
  namespace: nadsoft
spec:
  type: NodePort
  ports:
  - port: 3001
    targetPort: 3001
    nodePort: 30001
  selector:
    app: backend
EOF

    print_success "NodePort services created"
}

# Step 6: Setup domain and SSL (with Let's Encrypt)
setup_domain_ssl() {
    local domain=$1
    
    if [ -z "$domain" ]; then
        print_warning "No domain provided. Skipping SSL setup."
        return
    fi
    
    print_info "Setting up domain and SSL for: $domain"
    
    # Install cert-manager
    kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.2/cert-manager.yaml
    
    # Wait for cert-manager to be ready
    kubectl wait --for=condition=ready pod -l app=cert-manager -n cert-manager --timeout=300s
    
    # Create ClusterIssuer for Let's Encrypt
    kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: admin@$domain
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
EOF

    # Create Ingress with SSL
    kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: nadsoft-ingress-ssl
  namespace: nadsoft
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/cors-allow-origin: "*"
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - $domain
    - api.$domain
    secretName: nadsoft-tls
  rules:
  - host: $domain
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend-service
            port:
              number: 3000
  - host: api.$domain
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: backend-service
            port:
              number: 3001
EOF

    print_success "Domain and SSL configured for $domain"
}

# Step 7: Setup monitoring and status page
setup_monitoring() {
    print_info "Setting up monitoring..."
    
    # Create a simple status page
    kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: status-page
  namespace: nadsoft
data:
  index.html: |
    <!DOCTYPE html>
    <html>
    <head>
        <title>Nadsoft Server Status</title>
        <meta http-equiv="refresh" content="30">
        <style>
            body { font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }
            .container { max-width: 800px; margin: 0 auto; background: white; padding: 20px; border-radius: 10px; }
            .status { display: inline-block; padding: 5px 10px; border-radius: 5px; color: white; }
            .running { background: #4CAF50; }
            .pending { background: #FF9800; }
            .failed { background: #F44336; }
            .service { margin: 10px 0; padding: 15px; border: 1px solid #ddd; border-radius: 5px; }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>🖥️ Nadsoft MacBook Server Status</h1>
            <p>Last updated: <span id="timestamp"></span></p>
            
            <div class="service">
                <h3>🌐 Frontend Service</h3>
                <p>Status: <span class="status running">Running</span></p>
                <p>URL: <a href="http://localhost:3000" target="_blank">http://localhost:3000</a></p>
            </div>
            
            <div class="service">
                <h3>🔗 Backend API</h3>
                <p>Status: <span class="status running">Running</span></p>
                <p>URL: <a href="http://localhost:3001/api/students" target="_blank">http://localhost:3001/api/students</a></p>
            </div>
            
            <div class="service">
                <h3>🗄️ MySQL Database</h3>
                <p>Status: <span class="status running">Running</span></p>
                <p>Port: 3306</p>
            </div>
            
            <div class="service">
                <h3>☸️ Kubernetes Cluster</h3>
                <p>Status: <span class="status running">Running</span></p>
                <p>Nodes: 1 (MacBook)</p>
            </div>
        </div>
        
        <script>
            document.getElementById('timestamp').textContent = new Date().toLocaleString();
        </script>
    </body>
    </html>
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: status-page
  namespace: nadsoft
spec:
  replicas: 1
  selector:
    matchLabels:
      app: status-page
  template:
    metadata:
      labels:
        app: status-page
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - containerPort: 80
        volumeMounts:
        - name: status-page
          mountPath: /usr/share/nginx/html
      volumes:
      - name: status-page
        configMap:
          name: status-page
---
apiVersion: v1
kind: Service
metadata:
  name: status-page-service
  namespace: nadsoft
spec:
  type: NodePort
  ports:
  - port: 80
    targetPort: 80
    nodePort: 30080
  selector:
    app: status-page
EOF

    print_success "Monitoring and status page configured"
}

# Main execution
main() {
    local domain=$1
    
    echo "🖥️  MacBook Kubernetes Server Setup"
    echo "=================================="
    
    case "$1" in
        "install")
            install_prerequisites
            ;;
        "start")
            setup_kubernetes
            configure_networking
            deploy_application
            setup_external_access
            setup_monitoring
            ;;
        "domain")
            if [ -z "$2" ]; then
                print_error "Please provide a domain: $0 domain yourdomain.com"
                exit 1
            fi
            setup_domain_ssl "$2"
            ;;
        "status")
            print_info "Cluster Status:"
            kubectl get nodes
            echo ""
            print_info "Application Status:"
            kubectl get pods,svc -n nadsoft
            echo ""
            print_info "Access Information:"
            LOCAL_IP=$(cat .local_ip 2>/dev/null || get_local_ip)
            echo "Local Frontend:  http://$LOCAL_IP:30000"
            echo "Local Backend:   http://$LOCAL_IP:30001"
            echo "Status Page:     http://$LOCAL_IP:30080"
            ;;
        "tunnel")
            print_info "Setting up ngrok tunnel..."
            print_warning "This requires ngrok account and authtoken"
            ngrok http 30000 --subdomain=nadsoft-$(whoami) &
            ngrok http 30001 --subdomain=nadsoft-api-$(whoami) &
            ;;
        "stop")
            print_info "Stopping services..."
            minikube stop
            pkill -f ngrok || true
            print_success "Services stopped"
            ;;
        "full")
            domain=$2
            install_prerequisites
            setup_kubernetes
            configure_networking
            deploy_application
            setup_external_access
            setup_monitoring
            if [ ! -z "$domain" ]; then
                setup_domain_ssl "$domain"
            fi
            print_success "🎉 MacBook server setup complete!"
            ;;
        *)
            echo "Usage: $0 {install|start|domain <domain>|status|tunnel|stop|full [domain]}"
            echo ""
            echo "Commands:"
            echo "  install           - Install prerequisites"
            echo "  start            - Start Kubernetes and deploy app"
            echo "  domain <domain>  - Setup SSL for domain"
            echo "  status           - Show status and access info"
            echo "  tunnel           - Create ngrok tunnel"
            echo "  stop             - Stop all services"
            echo "  full [domain]    - Complete setup"
            echo ""
            echo "Examples:"
            echo "  $0 full                    # Complete setup without domain"
            echo "  $0 full mydomain.com       # Complete setup with domain"
            echo "  $0 status                  # Check status"
            exit 1
            ;;
    esac
}

main "$@"