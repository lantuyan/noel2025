#!/bin/bash

# ============================================
# Christmas Tree 3D - Auto Deploy Script
# Domain: noel.sixpilot.technology
# ============================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

DOMAIN="noel.sixpilot.technology"
APP_DIR=$(dirname "$(readlink -f "$0")")
PORT=${PORT:-3000}  # Use PORT env var if set, otherwise default to 3000

print_status() {
    echo -e "${BLUE}[*]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

# Check if running as root for nginx/certbot operations
check_sudo() {
    if [ "$EUID" -ne 0 ]; then
        print_warning "Some operations require sudo. You may be prompted for password."
    fi
}

# Install Node.js if not present
install_nodejs() {
    if command -v node &> /dev/null; then
        NODE_VERSION=$(node -v)
        print_success "Node.js already installed: $NODE_VERSION"
    else
        print_status "Installing Node.js 20.x..."
        curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
        sudo apt-get install -y nodejs
        print_success "Node.js installed: $(node -v)"
    fi
}

# Install pnpm if not present
install_pnpm() {
    if command -v pnpm &> /dev/null; then
        print_success "pnpm already installed"
    else
        print_status "Installing pnpm..."
        npm install -g pnpm
        print_success "pnpm installed"
    fi
}

# Install nginx if not present
install_nginx() {
    if command -v nginx &> /dev/null; then
        print_success "Nginx already installed"
    else
        print_status "Installing Nginx..."
        sudo apt-get update
        sudo apt-get install -y nginx
        print_success "Nginx installed"
    fi
}

# Install certbot for SSL
install_certbot() {
    if command -v certbot &> /dev/null; then
        print_success "Certbot already installed"
    else
        print_status "Installing Certbot..."
        # Try snap first (recommended method)
        if command -v snap &> /dev/null; then
            sudo snap install --classic certbot 2>/dev/null || true
            sudo ln -sf /snap/bin/certbot /usr/bin/certbot 2>/dev/null || true
        fi
        # Fallback to apt
        if ! command -v certbot &> /dev/null; then
            sudo apt-get install -y certbot python3-certbot-nginx
        fi
        print_success "Certbot installed"
    fi
    
    # Ensure nginx plugin is installed
    print_status "Ensuring Certbot nginx plugin is installed..."
    if command -v snap &> /dev/null && snap list certbot &> /dev/null; then
        # For snap-based certbot, the nginx plugin is included
        print_success "Using snap certbot (nginx plugin included)"
    else
        # For apt-based certbot, install the plugin separately
        sudo apt-get install -y python3-certbot-nginx
        print_success "Certbot nginx plugin installed"
    fi
}

# Install project dependencies
install_dependencies() {
    print_status "Installing project dependencies..."
    cd "$APP_DIR"
    pnpm install
    print_success "Dependencies installed"
}

# Build the project
build_project() {
    print_status "Building project..."
    cd "$APP_DIR"
    pnpm run build
    print_success "Project built successfully"
}

# Configure Nginx
configure_nginx() {
    print_status "Configuring Nginx for $DOMAIN..."
    
    NGINX_CONFIG="/etc/nginx/sites-available/$DOMAIN"
    
    # Use eval to expand PORT variable in heredoc
    sudo tee "$NGINX_CONFIG" > /dev/null << EOF
server {
    listen 80;
    listen [::]:80;
    server_name $DOMAIN;

    root $APP_DIR/dist;
    index index.html;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied expired no-cache no-store private auth;
    gzip_types text/plain text/css text/xml text/javascript application/x-javascript application/xml application/javascript;
    gzip_disable "MSIE [1-6]\.";

    # Cache static assets
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Proxy API upload requests to Vite preview server
    location /api/ {
        proxy_pass http://localhost:${PORT};
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        client_max_body_size 10M;
    }

    # Handle SPA routing
    location / {
        try_files \$uri \$uri/ /index.html;
    }

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
}
EOF

    # Enable the site
    sudo ln -sf "$NGINX_CONFIG" /etc/nginx/sites-enabled/
    
    # Remove default if exists
    sudo rm -f /etc/nginx/sites-enabled/default
    
    # Test nginx config
    sudo nginx -t
    
    # Reload nginx
    sudo systemctl reload nginx
    
    print_success "Nginx configured for $DOMAIN"
}

# Setup SSL with Let's Encrypt
setup_ssl() {
    print_status "Setting up SSL certificate for $DOMAIN..."
    
    read -p "Do you want to set up SSL with Let's Encrypt? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        sudo certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos --email admin@sixpilot.technology --redirect
        print_success "SSL certificate installed"
    else
        print_warning "Skipping SSL setup. Site will be available on HTTP only."
    fi
}

# Install PM2 for process management (optional, for preview mode)
install_pm2() {
    if command -v pm2 &> /dev/null; then
        print_success "PM2 already installed"
    else
        print_status "Installing PM2..."
        npm install -g pm2
        print_success "PM2 installed"
    fi
}

# Start the application using PM2 (for development/preview mode)
start_with_pm2() {
    print_status "Starting application with PM2..."
    cd "$APP_DIR"
    
    # Stop existing instance if running
    pm2 delete christmas-tree-3d 2>/dev/null || true
    
    # Start using ecosystem file if exists, otherwise use direct command
    if [ -f "$APP_DIR/ecosystem.config.cjs" ]; then
        pm2 start ecosystem.config.cjs
    elif [ -f "$APP_DIR/ecosystem.config.js" ]; then
        pm2 start ecosystem.config.js
    else
        # Fallback: use direct command with proper format
        pm2 start pnpm --name christmas-tree-3d -- run preview -- --host 0.0.0.0 --port $PORT
    fi
    pm2 save
    
    # Setup PM2 to start on boot
    pm2 startup systemd -u $USER --hp $HOME 2>/dev/null || true
    
    print_success "Application started on port $PORT"
    print_status "Check status with: pm2 list"
    print_status "View logs with: pm2 logs christmas-tree-3d"
}

# Main deployment function
deploy() {
    echo ""
    echo -e "${GREEN}============================================${NC}"
    echo -e "${GREEN}  Christmas Tree 3D - Deployment Script    ${NC}"
    echo -e "${GREEN}  Domain: $DOMAIN                          ${NC}"
    echo -e "${GREEN}============================================${NC}"
    echo ""
    
    check_sudo
    
    print_status "Starting deployment..."
    echo ""
    
    # Install system dependencies
    install_nodejs
    install_pnpm
    install_nginx
    install_certbot
    
    echo ""
    
    # Build project
    install_dependencies
    build_project
    
    echo ""
    
    # Configure web server
    configure_nginx
    
    echo ""
    
    # Setup SSL
    setup_ssl
    
    echo ""
    
    # Start Vite preview server with PM2 for API upload support
    print_status "Starting Vite preview server for API upload support..."
    install_pm2
    start_with_pm2
    
    echo ""
    echo -e "${GREEN}============================================${NC}"
    echo -e "${GREEN}  Deployment Complete!                      ${NC}"
    echo -e "${GREEN}============================================${NC}"
    echo ""
    echo -e "Your site is now available at:"
    echo -e "  ${BLUE}http://$DOMAIN${NC}"
    echo -e "  ${BLUE}https://$DOMAIN${NC} (if SSL was configured)"
    echo ""
    echo -e "Vite preview server running on port $PORT for API upload"
    echo -e "Check PM2 status: ${BLUE}pm2 list${NC}"
    echo ""
}

# Show help
show_help() {
    echo "Usage: ./start.sh [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  deploy      Full deployment (install, build, configure nginx, SSL)"
    echo "  build       Build the project only"
    echo "  dev         Run development server"
    echo "  preview     Run preview mode with PM2"
    echo "  nginx       Configure nginx only"
    echo "  ssl         Setup SSL only"
    echo "  help        Show this help message"
    echo ""
    echo "If no command is provided, 'deploy' will be executed."
}

# Parse command line arguments
case "${1:-deploy}" in
    deploy)
        deploy
        ;;
    build)
        install_dependencies
        build_project
        ;;
    dev)
        install_dependencies
        cd "$APP_DIR" && pnpm run dev -- --host 0.0.0.0
        ;;
    preview)
        install_pm2
        install_dependencies
        build_project
        start_with_pm2
        ;;
    nginx)
        configure_nginx
        ;;
    ssl)
        setup_ssl
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        print_error "Unknown command: $1"
        show_help
        exit 1
        ;;
esac
