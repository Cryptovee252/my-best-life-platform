#!/bin/bash

# HelpMyBestLife Platform v1.2 - Fix Nginx Caching
# This script completely fixes Nginx caching issues

set -e

echo "🔧 HelpMyBestLife Platform v1.2 - Fix Nginx Caching"
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

print_status "1. Stopping all services..."
pm2 stop all
systemctl stop nginx

print_status "2. Removing ALL cached files..."
# Remove Nginx cache
rm -rf /var/cache/nginx/*
rm -rf /var/lib/nginx/cache/*
rm -rf /tmp/nginx_cache/*

# Remove any proxy cache
rm -rf /var/cache/proxy/*

# Remove old frontend build completely
rm -rf /root/my-best-life-platform/frontend/dist

print_status "3. Checking for multiple Nginx configurations..."
# List all Nginx sites
echo "Enabled sites:"
ls -la /etc/nginx/sites-enabled/

echo ""
echo "Available sites:"
ls -la /etc/nginx/sites-available/

print_status "4. Removing ALL conflicting configurations..."
# Disable all sites first
rm -f /etc/nginx/sites-enabled/*

print_status "5. Creating a completely fresh Nginx configuration..."
cat > /etc/nginx/sites-available/mybestlifeapp.com << 'EOF'
server {
    listen 80;
    server_name mybestlifeapp.com www.mybestlifeapp.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name mybestlifeapp.com www.mybestlifeapp.com;
    
    # SSL Configuration
    ssl_certificate /etc/letsencrypt/live/mybestlifeapp.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/mybestlifeapp.com/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    
    # DISABLE ALL CACHING
    add_header Cache-Control "no-cache, no-store, must-revalidate" always;
    add_header Pragma "no-cache" always;
    add_header Expires "0" always;
    
    # Security headers
    add_header X-Frame-Options "DENY" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval' https:; style-src 'self' 'unsafe-inline' https: fonts.googleapis.com; font-src 'self' https: fonts.gstatic.com data:; img-src 'self' data: https: blob:; connect-src 'self' https: wss: ws:; media-src 'self' data: https:; object-src 'none'; base-uri 'self'; form-action 'self'; frame-ancestors 'none';" always;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
    
    # Rate limiting
    limit_req_zone $binary_remote_addr zone=api:10m rate=10r/m;
    limit_req_zone $binary_remote_addr zone=auth:10m rate=5r/m;
    
    # Frontend - Serve the UPDATED Expo React Native Web app
    location / {
        root /root/my-best-life-platform/frontend/dist;
        try_files $uri $uri/ /index.html;
        
        # FORCE NO CACHE for all files
        add_header Cache-Control "no-cache, no-store, must-revalidate" always;
        add_header Pragma "no-cache" always;
        add_header Expires "0" always;
        
        # Disable ETags
        etag off;
        
        # Disable Last-Modified
        if_modified_since off;
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
        
        # Disable proxy caching
        proxy_cache off;
        proxy_no_cache 1;
        
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
        
        # Disable proxy caching
        proxy_cache off;
        proxy_no_cache 1;
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

print_status "6. Enabling the new configuration..."
ln -sf /etc/nginx/sites-available/mybestlifeapp.com /etc/nginx/sites-enabled/

print_status "7. Testing Nginx configuration..."
nginx -t

print_status "8. Rebuilding frontend with fresh timestamp..."
cd /root/my-best-life-platform/frontend

# Install dependencies
npm install

# Build with no cache
npm run build:web

# Add timestamp to force refresh
TIMESTAMP=$(date +%s)
echo "<!-- Build timestamp: $TIMESTAMP -->" >> dist/index.html

print_status "9. Verifying new files..."
ls -la dist/
echo "New index.html timestamp:"
stat dist/index.html | grep Modify

print_status "10. Starting services..."
systemctl start nginx
pm2 start all

print_status "11. Testing the site..."
sleep 3
echo "Testing HTTPS response:"
curl -I https://mybestlifeapp.com

echo ""
echo "Testing what's being served:"
curl -s https://mybestlifeapp.com | head -10

print_success "🎉 Nginx caching completely disabled!"
print_success "Your site should now show the updated version!"
print_success "Try accessing: https://mybestlifeapp.com/?v=$TIMESTAMP"

echo ""
print_warning "If you still see the old version:"
echo "1. Clear your browser cache completely (Ctrl+Shift+Delete)"
echo "2. Try incognito/private mode"
echo "3. Try a different browser"
echo "4. Wait 2-3 minutes for changes to propagate"
echo "5. Check if you have any CDN or proxy in front of your VPS"
