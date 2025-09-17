#!/bin/bash

# HelpMyBestLife Platform v1.2 - Fix Nginx Folder
# This script updates Nginx to serve the correct updated folder

set -e

echo "🔧 HelpMyBestLife Platform v1.2 - Fix Nginx Folder"
echo "================================================="

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

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

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    print_error "Please run as root (use sudo)"
    exit 1
fi

# Find the correct folder with the updated frontend
print_status "Finding the correct updated frontend folder..."

UPDATED_FRONTEND_PATH=""
if [ -f "/root/my-best-life-platform/frontend/dist/index.html" ]; then
    UPDATED_FRONTEND_PATH="/root/my-best-life-platform/frontend/dist"
    print_success "Found updated frontend at: $UPDATED_FRONTEND_PATH"
elif [ -f "/root/mybestlifeplatform/frontend/dist/index.html" ]; then
    UPDATED_FRONTEND_PATH="/root/mybestlifeplatform/frontend/dist"
    print_success "Found updated frontend at: $UPDATED_FRONTEND_PATH"
elif [ -f "/root/backend/frontend/dist/index.html" ]; then
    UPDATED_FRONTEND_PATH="/root/backend/frontend/dist"
    print_success "Found updated frontend at: $UPDATED_FRONTEND_PATH"
else
    print_error "Could not find updated frontend build!"
    exit 1
fi

print_status "Updating Nginx configuration to point to: $UPDATED_FRONTEND_PATH"

# Update Nginx configuration
cat > /etc/nginx/sites-available/mybestlifeapp.com << EOF
server {
    listen 80;
    server_name mybestlifeapp.com www.mybestlifeapp.com;
    
    # Security headers
    add_header X-Frame-Options "DENY" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; font-src 'self' data:; connect-src 'self' https:; frame-ancestors 'none';" always;
    
    # Rate limiting
    limit_req_zone \$binary_remote_addr zone=api:10m rate=10r/m;
    limit_req_zone \$binary_remote_addr zone=auth:10m rate=5r/m;
    
    # Frontend - Serve the UPDATED Expo React Native Web app
    location / {
        root $UPDATED_FRONTEND_PATH;
        try_files \$uri \$uri/ /index.html;
        
        # Cache static assets
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }
    
    # API routes
    location /api/ {
        limit_req zone=api burst=20 nodelay;
        proxy_pass http://localhost:3001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        
        # Timeout settings
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
    
    # Auth routes with stricter rate limiting
    location /api/auth/ {
        limit_req zone=auth burst=10 nodelay;
        proxy_pass http://localhost:3001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }
    
    # Health check
    location /health {
        proxy_pass http://localhost:3001/api/health;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

print_status "Testing Nginx configuration..."
nginx -t

print_status "Restarting Nginx..."
systemctl restart nginx

print_status "Testing what's being served..."
curl -s http://localhost/ | head -10

print_success "🎉 Nginx configuration updated!"
print_success "Now serving from: $UPDATED_FRONTEND_PATH"
print_success "Check https://mybestlifeapp.com to see the updated version!"

echo ""
echo "🔍 If it still shows the old version, run:"
echo "chmod +x find-correct-folder.sh && ./find-correct-folder.sh"
