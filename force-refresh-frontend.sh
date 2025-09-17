#!/bin/bash

# HelpMyBestLife Platform v1.2 - Force Refresh Frontend
# This script forces a complete refresh of the frontend

set -e

echo "🔄 HelpMyBestLife Platform v1.2 - Force Refresh Frontend"
echo "======================================================="

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

print_status "2. Clearing all caches..."
# Clear Nginx cache
rm -rf /var/cache/nginx/*
rm -rf /var/lib/nginx/cache/*

# Clear any browser cache files
find /root -name "*.cache" -delete 2>/dev/null || true

print_status "3. Removing old frontend build..."
rm -rf /root/my-best-life-platform/frontend/dist

print_status "4. Rebuilding frontend with fresh timestamp..."
cd /root/my-best-life-platform/frontend

# Add timestamp to force cache busting
TIMESTAMP=$(date +%s)
echo "Building with timestamp: $TIMESTAMP"

# Install dependencies
npm install

# Build with no cache
npm run build:web

print_status "5. Adding cache-busting headers to index.html..."
# Add timestamp to HTML to force browser refresh
sed -i "s|<title|<title data-timestamp=\"$TIMESTAMP\"|" dist/index.html

print_status "6. Updating Nginx configuration with cache-busting..."
cat > /etc/nginx/sites-available/mybestlifeapp.com << EOF
server {
    listen 80;
    server_name mybestlifeapp.com www.mybestlifeapp.com;
    return 301 https://\$server_name\$request_uri;
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
    
    # Security headers
    add_header X-Frame-Options "DENY" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval' https:; style-src 'self' 'unsafe-inline' https: fonts.googleapis.com; font-src 'self' https: fonts.gstatic.com data:; img-src 'self' data: https: blob:; connect-src 'self' https: wss: ws:; media-src 'self' data: https:; object-src 'none'; base-uri 'self'; form-action 'self'; frame-ancestors 'none';" always;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
    
    # Cache busting headers
    add_header Cache-Control "no-cache, no-store, must-revalidate" always;
    add_header Pragma "no-cache" always;
    add_header Expires "0" always;
    
    # Rate limiting
    limit_req_zone \$binary_remote_addr zone=api:10m rate=10r/m;
    limit_req_zone \$binary_remote_addr zone=auth:10m rate=5r/m;
    
    # Frontend - Serve the UPDATED Expo React Native Web app
    location / {
        root /root/my-best-life-platform/frontend/dist;
        try_files \$uri \$uri/ /index.html;
        
        # Force no cache for HTML files
        location ~* \.html$ {
            add_header Cache-Control "no-cache, no-store, must-revalidate";
            add_header Pragma "no-cache";
            add_header Expires "0";
        }
        
        # Cache static assets with versioning
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

print_status "7. Testing Nginx configuration..."
nginx -t

print_status "8. Starting services..."
systemctl start nginx
pm2 start all

print_status "9. Testing the site..."
sleep 3
curl -I https://mybestlifeapp.com

print_status "10. Checking what's being served..."
curl -s https://mybestlifeapp.com | head -10

print_success "🎉 Frontend force refresh completed!"
print_success "Your site should now show the updated version!"
print_success "Try accessing: https://mybestlifeapp.com/?refresh=$TIMESTAMP"

echo ""
print_warning "If you still see the old version:"
echo "1. Clear your browser cache completely"
echo "2. Try incognito/private mode"
echo "3. Try a different browser"
echo "4. Wait 2-3 minutes for changes to propagate"
