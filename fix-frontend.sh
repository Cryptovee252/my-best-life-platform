#!/bin/bash

# HelpMyBestLife Platform v1.2 - Frontend Fix Script
# This script properly rebuilds and deploys the frontend

set -e

echo "🔧 HelpMyBestLife Platform v1.2 - Frontend Fix"
echo "============================================="

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

print_status "Stopping current services..."
pm2 stop mybestlife-backend 2>/dev/null || true
systemctl stop nginx 2>/dev/null || true

print_status "Cleaning up old frontend build..."
rm -rf /root/my-best-life-platform/frontend/dist
rm -rf /root/my-best-life-platform/frontend/node_modules

print_status "Installing frontend dependencies..."
cd /root/my-best-life-platform/frontend
npm install

print_status "Building frontend for production..."
npm run build

print_status "Verifying frontend build..."
if [ -f "/root/my-best-life-platform/frontend/dist/index.html" ]; then
    print_success "Frontend build successful!"
    ls -la /root/my-best-life-platform/frontend/dist/
else
    print_error "Frontend build failed!"
    exit 1
fi

print_status "Updating Nginx configuration..."
cat > /etc/nginx/sites-available/mybestlifeapp.com << 'EOF'
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
    limit_req_zone $binary_remote_addr zone=api:10m rate=10r/m;
    limit_req_zone $binary_remote_addr zone=auth:10m rate=5r/m;
    
    # Frontend - Serve React app
    location / {
        root /root/my-best-life-platform/frontend/dist;
        try_files $uri $uri/ /index.html;
        
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
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        
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
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
    
    # Health check
    location /health {
        proxy_pass http://localhost:3001/api/health;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

print_status "Testing Nginx configuration..."
nginx -t

print_status "Starting services..."
systemctl start nginx
systemctl enable nginx
pm2 start mybestlife-backend

print_status "Testing frontend..."
curl -s -I http://localhost/ | head -5

print_status "Testing backend API..."
curl -s http://localhost:3001/api/health || echo "Backend API not responding"

print_success "🎉 Frontend fix completed!"
print_success "Your HelpMyBestLife Platform should now look like the local version!"
print_success "Frontend: https://mybestlifeapp.com"
print_success "API: https://mybestlifeapp.com/api/health"

echo ""
echo "🔍 If it still looks different, run the debug script:"
echo "chmod +x debug-vps.sh && ./debug-vps.sh"
