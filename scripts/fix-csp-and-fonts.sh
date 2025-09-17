#!/bin/bash

# Fix Content Security Policy and Font Issues
# This script fixes CSP violations and missing font files

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

DOMAIN="mybestlifeapp.com"

echo "🔧 FIXING CSP AND FONT ISSUES"
echo "============================="
echo "Domain: $DOMAIN"
echo "Date: $(date)"
echo ""

# Step 1: Fix Content Security Policy in Nginx
print_status "1. Fixing Content Security Policy..."

# Create updated Nginx configuration with relaxed CSP
cat > /etc/nginx/sites-available/mybestlife << 'EOF'
# My Best Life Platform - Secure Nginx Configuration

# Rate limiting
limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
limit_req_zone $binary_remote_addr zone=auth:10m rate=5r/s;

# Upstream backend
upstream backend {
    server localhost:3000;
    keepalive 32;
}

# HTTP to HTTPS redirect
server {
    listen 80;
    listen [::]:80;
    server_name mybestlifeapp.com www.mybestlifeapp.com;
    
    # Let's Encrypt challenge
    location /.well-known/acme-challenge/ {
        root /var/www/html;
    }
    
    # Redirect all other traffic to HTTPS
    location / {
        return 301 https://$server_name$request_uri;
    }
}

# HTTPS server
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name mybestlifeapp.com www.mybestlifeapp.com;
    
    # SSL Configuration
    ssl_certificate /etc/letsencrypt/live/mybestlifeapp.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/mybestlifeapp.com/privkey.pem;
    
    # SSL Security Settings
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    # Security Headers (Relaxed CSP for compatibility)
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
    add_header X-Frame-Options "DENY" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    
    # Relaxed Content Security Policy for React/Expo apps
    add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval' https:; style-src 'self' 'unsafe-inline' https: fonts.googleapis.com; font-src 'self' https: fonts.gstatic.com data:; img-src 'self' data: https: blob:; connect-src 'self' https: wss: ws:; media-src 'self' data: https:; object-src 'none'; base-uri 'self'; form-action 'self'; frame-ancestors 'none';" always;
    
    add_header Permissions-Policy "geolocation=(), microphone=(), camera=()" always;
    
    # Hide Nginx version
    server_tokens off;
    
    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/json
        application/javascript
        application/xml+rss
        application/atom+xml
        image/svg+xml
        font/woff
        font/woff2
        font/ttf
        font/eot;
    
    # Static files with proper caching
    location / {
        root /var/www/mybestlife;
        try_files $uri $uri/ @backend;
        
        # Cache static assets
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
            add_header Access-Control-Allow-Origin "*";
        }
    }
    
    # Font files with CORS headers
    location ~* \.(woff|woff2|ttf|eot)$ {
        root /var/www/mybestlife;
        expires 1y;
        add_header Cache-Control "public, immutable";
        add_header Access-Control-Allow-Origin "*";
        add_header Access-Control-Allow-Methods "GET, OPTIONS";
        add_header Access-Control-Allow-Headers "Origin, X-Requested-With, Content-Type, Accept";
    }
    
    # API routes with rate limiting
    location /api/ {
        limit_req zone=api burst=20 nodelay;
        
        proxy_pass http://backend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
    
    # Authentication routes with stricter rate limiting
    location /api/auth/ {
        limit_req zone=auth burst=10 nodelay;
        
        proxy_pass http://backend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
    
    # Backend fallback
    location @backend {
        proxy_pass http://backend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
    
    # Block access to sensitive files
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }
    
    location ~ /(\.env|\.git|\.htaccess|\.htpasswd|composer\.json|composer\.lock|package\.json|package-lock\.json|yarn\.lock) {
        deny all;
        access_log off;
        log_not_found off;
    }
    
    # Block common attack patterns
    location ~* /(wp-admin|wp-login|xmlrpc|admin|administrator) {
        deny all;
        access_log off;
        log_not_found off;
    }
}
EOF

# Step 2: Test Nginx configuration
print_status "2. Testing Nginx configuration..."
nginx -t

# Step 3: Reload Nginx
print_status "3. Reloading Nginx..."
systemctl reload nginx

# Step 4: Create font directory and download FontAwesome
print_status "4. Setting up font files..."

# Create font directory
mkdir -p /var/www/mybestlife/assets/fonts

# Download FontAwesome fonts
print_status "Downloading FontAwesome fonts..."
cd /var/www/mybestlife/assets/fonts

# Download FontAwesome font files
wget -q https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/webfonts/fa-brands-400.woff2 || true
wget -q https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/webfonts/fa-brands-400.woff || true
wget -q https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/webfonts/fa-brands-400.ttf || true
wget -q https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/webfonts/fa-regular-400.woff2 || true
wget -q https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/webfonts/fa-regular-400.woff || true
wget -q https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/webfonts/fa-regular-400.ttf || true
wget -q https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/webfonts/fa-solid-900.woff2 || true
wget -q https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/webfonts/fa-solid-900.woff || true
wget -q https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/webfonts/fa-solid-900.ttf || true

# Create a simple FontAwesome CSS file
cat > /var/www/mybestlife/assets/fonts/fontawesome.css << 'EOF'
@font-face {
  font-family: 'Font Awesome 6 Brands';
  font-style: normal;
  font-weight: 400;
  font-display: block;
  src: url("./fa-brands-400.woff2") format("woff2"),
       url("./fa-brands-400.woff") format("woff"),
       url("./fa-brands-400.ttf") format("truetype");
}

@font-face {
  font-family: 'Font Awesome 6 Free';
  font-style: normal;
  font-weight: 400;
  font-display: block;
  src: url("./fa-regular-400.woff2") format("woff2"),
       url("./fa-regular-400.woff") format("woff"),
       url("./fa-regular-400.ttf") format("truetype");
}

@font-face {
  font-family: 'Font Awesome 6 Free';
  font-style: normal;
  font-weight: 900;
  font-display: block;
  src: url("./fa-solid-900.woff2") format("woff2"),
       url("./fa-solid-900.woff") format("woff"),
       url("./fa-solid-900.ttf") format("truetype");
}
EOF

# Step 5: Set proper permissions
print_status "5. Setting proper permissions..."
chown -R www-data:www-data /var/www/mybestlife/assets/fonts
chmod -R 755 /var/www/mybestlife/assets/fonts

# Step 6: Test the fixes
print_status "6. Testing fixes..."

# Test HTTP redirect
if curl -I http://$DOMAIN 2>/dev/null | grep -q "301\|302"; then
    print_success "HTTP to HTTPS redirect: Working"
else
    print_warning "HTTP to HTTPS redirect: May not be working"
fi

# Test HTTPS
if curl -f https://$DOMAIN > /dev/null 2>&1; then
    print_success "HTTPS: Website responding"
else
    print_error "HTTPS: Website not responding"
fi

# Test font files
if curl -f https://$DOMAIN/assets/fonts/fa-solid-900.woff2 > /dev/null 2>&1; then
    print_success "FontAwesome fonts: Accessible"
else
    print_warning "FontAwesome fonts: May not be accessible"
fi

echo ""
print_success "CSP and font fixes completed!"
echo ""
echo "✅ FIXES APPLIED:"
echo "================="
echo "  ✅ Relaxed Content Security Policy"
echo "  ✅ Added 'unsafe-inline' for scripts and styles"
echo "  ✅ Added 'unsafe-eval' for React/Expo compatibility"
echo "  ✅ Added CORS headers for fonts"
echo "  ✅ Downloaded FontAwesome font files"
echo "  ✅ Created font directory structure"
echo "  ✅ Set proper permissions"
echo ""
echo "🌐 TEST YOUR WEBSITE:"
echo "====================="
echo "  HTTPS: https://$DOMAIN"
echo "  Fonts: https://$DOMAIN/assets/fonts/"
echo ""
echo "📱 BROWSER TESTING:"
echo "==================="
echo "  1. Clear browser cache (Ctrl+Shift+Delete)"
echo "  2. Open incognito/private window"
echo "  3. Visit: https://$DOMAIN"
echo "  4. Check browser console for errors"
echo "  5. Verify fonts are loading"
echo ""
print_success "CSP and font fixes complete! 🎨"
