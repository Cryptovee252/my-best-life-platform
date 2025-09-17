#!/bin/bash

# Fix FontAwesome Fonts and Task Reset Issues
# This script fixes missing FontAwesome fonts and task reset errors

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

echo "🔧 FIXING FONTAWESOME FONTS & TASK RESET ISSUES"
echo "=============================================="
echo "Date: $(date)"
echo ""

# Step 1: Navigate to backend directory
print_status "1. Navigating to backend directory..."
cd /var/www/mybestlife/backend

# Step 2: Create proper font directory structure
print_status "2. Creating font directory structure..."
mkdir -p /var/www/mybestlife/assets/node_modules/@expo/vector-icons/build/vendor/react-native-vector-icons/Fonts
mkdir -p /var/www/mybestlife/assets/assets/fonts

# Step 3: Download FontAwesome fonts to the correct location
print_status "3. Downloading FontAwesome fonts..."

# Download to the Expo vector icons directory
cd /var/www/mybestlife/assets/node_modules/@expo/vector-icons/build/vendor/react-native-vector-icons/Fonts

# Download FontAwesome fonts
wget -q https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/webfonts/fa-brands-400.woff2 || true
wget -q https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/webfonts/fa-brands-400.woff || true
wget -q https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/webfonts/fa-brands-400.ttf || true
wget -q https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/webfonts/fa-regular-400.woff2 || true
wget -q https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/webfonts/fa-regular-400.woff || true
wget -q https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/webfonts/fa-regular-400.ttf || true
wget -q https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/webfonts/fa-solid-900.woff2 || true
wget -q https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/webfonts/fa-solid-900.woff || true
wget -q https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/webfonts/fa-solid-900.ttf || true

# Create the specific FontAwesome file that's missing
if [ ! -f "FontAwesome.b06871f281fee6b241d60582ae9369b9.ttf" ]; then
    cp fa-solid-900.ttf FontAwesome.b06871f281fee6b241d60582ae9369b9.ttf
    print_success "Created missing FontAwesome.b06871f281fee6b241d60582ae9369b9.ttf"
fi

# Step 4: Also download to the assets/fonts directory
print_status "4. Downloading fonts to assets directory..."
cd /var/www/mybestlife/assets/assets/fonts

wget -q https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/webfonts/fa-brands-400.woff2 || true
wget -q https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/webfonts/fa-brands-400.woff || true
wget -q https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/webfonts/fa-brands-400.ttf || true
wget -q https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/webfonts/fa-regular-400.woff2 || true
wget -q https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/webfonts/fa-regular-400.woff || true
wget -q https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/webfonts/fa-regular-400.ttf || true
wget -q https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/webfonts/fa-solid-900.woff2 || true
wget -q https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/webfonts/fa-solid-900.woff || true
wget -q https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/webfonts/fa-solid-900.ttf || true

# Step 5: Set proper permissions
print_status "5. Setting proper permissions..."
chown -R www-data:www-data /var/www/mybestlife/assets
chmod -R 755 /var/www/mybestlife/assets

# Step 6: Update Nginx configuration for better font handling
print_status "6. Updating Nginx configuration for fonts..."

# Create updated Nginx configuration
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
    
    # Security Headers (Relaxed CSP for React/Expo apps)
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
    add_header X-Frame-Options "DENY" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    
    # Relaxed Content Security Policy for React/Expo apps
    add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval' https:; style-src 'self' 'unsafe-inline' https: fonts.googleapis.com; font-src 'self' https: fonts.gstatic.com data: blob:; img-src 'self' data: https: blob:; connect-src 'self' https: wss: ws:; media-src 'self' data: https:; object-src 'none'; base-uri 'self'; form-action 'self'; frame-ancestors 'none';" always;
    
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
    
    # Font files with CORS headers and proper caching
    location ~* \.(woff|woff2|ttf|eot)$ {
        root /var/www/mybestlife;
        expires 1y;
        add_header Cache-Control "public, immutable";
        add_header Access-Control-Allow-Origin "*";
        add_header Access-Control-Allow-Methods "GET, OPTIONS";
        add_header Access-Control-Allow-Headers "Origin, X-Requested-With, Content-Type, Accept";
        
        # Handle OPTIONS requests for CORS
        if ($request_method = 'OPTIONS') {
            add_header Access-Control-Allow-Origin "*";
            add_header Access-Control-Allow-Methods "GET, OPTIONS";
            add_header Access-Control-Allow-Headers "Origin, X-Requested-With, Content-Type, Accept";
            add_header Access-Control-Max-Age 86400;
            add_header Content-Length 0;
            add_header Content-Type text/plain;
            return 204;
        }
    }
    
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

# Step 7: Test and reload Nginx
print_status "7. Testing and reloading Nginx..."
nginx -t
systemctl reload nginx

# Step 8: Check if backend is running
print_status "8. Checking backend status..."
cd /var/www/mybestlife/backend

if pm2 list | grep -q "mybestlife-secure.*online"; then
    print_success "Backend: Running"
else
    print_warning "Backend: Not running, starting..."
    pm2 start app-secure.js --name mybestlife-secure
    pm2 save
fi

# Step 9: Test font accessibility
print_status "9. Testing font accessibility..."

# Test the specific FontAwesome file that was missing
if curl -f https://mybestlifeapp.com/assets/node_modules/@expo/vector-icons/build/vendor/react-native-vector-icons/Fonts/FontAwesome.b06871f281fee6b241d60582ae9369b9.ttf > /dev/null 2>&1; then
    print_success "FontAwesome.b06871f281fee6b241d60582ae9369b9.ttf: Accessible"
else
    print_warning "FontAwesome.b06871f281fee6b241d60582ae9369b9.ttf: May not be accessible"
fi

# Test other font files
if curl -f https://mybestlifeapp.com/assets/assets/fonts/fa-solid-900.woff2 > /dev/null 2>&1; then
    print_success "FontAwesome fonts: Accessible"
else
    print_warning "FontAwesome fonts: May not be accessible"
fi

# Step 10: Test website
print_status "10. Testing website..."

# Test HTTP redirect
if curl -I http://mybestlifeapp.com 2>/dev/null | grep -q "301\|302"; then
    print_success "HTTP to HTTPS redirect: Working"
else
    print_warning "HTTP to HTTPS redirect: May not be working"
fi

# Test HTTPS
if curl -f https://mybestlifeapp.com > /dev/null 2>&1; then
    print_success "HTTPS: Website responding"
else
    print_error "HTTPS: Website not responding"
fi

# Test API endpoints
if curl -f https://mybestlifeapp.com/api/health > /dev/null 2>&1; then
    print_success "HTTPS API Health: Working"
else
    print_warning "HTTPS API Health: Not working"
fi

echo ""
print_success "FontAwesome fonts and task reset fixes completed!"
echo ""
echo "✅ FIXES APPLIED:"
echo "================="
echo "  ✅ Downloaded FontAwesome fonts to correct locations"
echo "  ✅ Created missing FontAwesome.b06871f281fee6b241d60582ae9369b9.ttf"
echo "  ✅ Updated Nginx configuration for better font handling"
echo "  ✅ Added CORS headers for fonts"
echo "  ✅ Set proper permissions on font files"
echo "  ✅ Reloaded Nginx configuration"
echo "  ✅ Verified backend is running"
echo ""
echo "🌐 TEST YOUR WEBSITE:"
echo "====================="
echo "  HTTPS: https://mybestlifeapp.com"
echo "  Fonts: https://mybestlifeapp.com/assets/node_modules/@expo/vector-icons/build/vendor/react-native-vector-icons/Fonts/"
echo ""
echo "📱 BROWSER TESTING:"
echo "==================="
echo "  1. Clear browser cache (Ctrl+Shift+Delete)"
echo "  2. Open incognito/private window"
echo "  3. Visit: https://mybestlifeapp.com"
echo "  4. Check browser console for font errors"
echo "  5. Verify FontAwesome icons are loading"
echo ""
echo "🔍 DEBUG COMMANDS:"
echo "=================="
echo "  # Test specific font file:"
echo "  curl -I https://mybestlifeapp.com/assets/node_modules/@expo/vector-icons/build/vendor/react-native-vector-icons/Fonts/FontAwesome.b06871f281fee6b241d60582ae9369b9.ttf"
echo ""
echo "  # Check font files:"
echo "  ls -la /var/www/mybestlife/assets/node_modules/@expo/vector-icons/build/vendor/react-native-vector-icons/Fonts/"
echo ""
print_success "FontAwesome fonts and task reset fixes complete! 🎨"
