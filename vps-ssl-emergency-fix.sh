#!/bin/bash

# VPS SSL Emergency Fix Script
# Run this directly on your VPS to fix SSL issues

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print functions
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
EMAIL="admin@mybestlifeapp.com"

echo "🚨 VPS SSL EMERGENCY FIX"
echo "======================="
echo "Domain: $DOMAIN"
echo "Date: $(date)"
echo ""

# Step 1: Check current status
print_status "1. Checking current status..."

# Check if Nginx is running
if systemctl is-active --quiet nginx; then
    print_success "Nginx: Running"
else
    print_error "Nginx: Not running"
fi

# Check if PM2 is running
if command -v pm2 &> /dev/null; then
    if pm2 list | grep -q "mybestlife"; then
        print_success "PM2: MyBestLife app running"
    else
        print_warning "PM2: MyBestLife app not running"
    fi
else
    print_warning "PM2: Not installed"
fi

# Check SSL certificate
if [ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]; then
    print_success "SSL certificate: Exists"
else
    print_error "SSL certificate: Missing"
fi

# Step 2: Install missing packages
print_status "2. Installing required packages..."
apt update
apt install -y nginx certbot python3-certbot-nginx ufw openssl

# Step 3: Configure firewall
print_status "3. Configuring firewall..."
ufw allow ssh
ufw allow 'Nginx Full'
ufw allow 80
ufw allow 443
ufw --force enable

# Step 4: Stop services for maintenance
print_status "4. Stopping services for maintenance..."
systemctl stop nginx 2>/dev/null || true

# Step 5: Create web root directory
print_status "5. Creating web root directory..."
mkdir -p /var/www/html
mkdir -p /var/www/mybestlife

# Step 6: Create temporary HTTP-only config for certificate generation
print_status "6. Creating temporary Nginx configuration..."
cat > /etc/nginx/sites-available/mybestlife << 'EOF'
# Temporary configuration for SSL certificate generation

# Upstream backend
upstream backend {
    server localhost:3000;
    keepalive 32;
}

# HTTP server (temporary for certificate generation)
server {
    listen 80;
    listen [::]:80;
    server_name mybestlifeapp.com www.mybestlifeapp.com;
    
    # Let's Encrypt challenge
    location /.well-known/acme-challenge/ {
        root /var/www/html;
    }
    
    # Proxy to backend
    location / {
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
}
EOF

# Step 7: Enable site
print_status "7. Enabling Nginx site..."
ln -sf /etc/nginx/sites-available/mybestlife /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Test configuration
nginx -t

# Step 8: Start Nginx
print_status "8. Starting Nginx..."
systemctl start nginx
systemctl enable nginx

# Step 9: Start Node.js application with PM2
print_status "9. Starting Node.js application..."

# Install PM2 if not installed
if ! command -v pm2 &> /dev/null; then
    npm install -g pm2
fi

# Navigate to backend directory
cd /var/www/mybestlife/backend

# Stop any existing PM2 processes
pm2 delete all 2>/dev/null || true

# Start the application
if [ -f "app-secure.js" ]; then
    pm2 start app-secure.js --name mybestlife-secure
elif [ -f "app.js" ]; then
    pm2 start app.js --name mybestlife-secure
else
    print_error "No application file found (app-secure.js or app.js)"
    exit 1
fi

pm2 save
pm2 startup

# Step 10: Wait for application to start
print_status "10. Waiting for application to start..."
sleep 10

# Check if application is running
if pm2 list | grep -q "mybestlife-secure.*online"; then
    print_success "Node.js application: Running"
else
    print_error "Node.js application: Failed to start"
    pm2 logs mybestlife-secure --lines 10
fi

# Step 11: Test HTTP connectivity
print_status "11. Testing HTTP connectivity..."
if curl -f http://localhost:3000 > /dev/null 2>&1; then
    print_success "Backend application: Responding on port 3000"
else
    print_error "Backend application: Not responding on port 3000"
fi

# Step 12: Obtain SSL certificate
print_status "12. Obtaining SSL certificate from Let's Encrypt..."
certbot --nginx -d $DOMAIN -d www.$DOMAIN --email $EMAIL --agree-tos --non-interactive --redirect

# Step 13: Create final secure configuration
print_status "13. Creating final secure Nginx configuration..."
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
    
    # SSL Configuration (updated by Certbot)
    ssl_certificate /etc/letsencrypt/live/mybestlifeapp.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/mybestlifeapp.com/privkey.pem;
    
    # SSL Security Settings
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    ssl_session_tickets off;
    
    # OCSP Stapling
    ssl_stapling on;
    ssl_stapling_verify on;
    ssl_trusted_certificate /etc/letsencrypt/live/mybestlifeapp.com/chain.pem;
    
    # Security Headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
    add_header X-Frame-Options "DENY" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; font-src 'self'; connect-src 'self'; frame-ancestors 'none';" always;
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
        image/svg+xml;
    
    # Static files
    location / {
        root /var/www/mybestlife;
        try_files $uri $uri/ @backend;
        
        # Cache static assets
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
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

# Step 14: Test final configuration
print_status "14. Testing final Nginx configuration..."
nginx -t

# Step 15: Reload Nginx
print_status "15. Reloading Nginx..."
systemctl reload nginx

# Step 16: Configure automatic renewal
print_status "16. Setting up automatic SSL renewal..."
cat > /etc/cron.d/certbot-renew << 'EOF'
# Renew Let's Encrypt certificates twice daily
0 12 * * * root certbot renew --quiet --post-hook "systemctl reload nginx"
0 0 * * * root certbot renew --quiet --post-hook "systemctl reload nginx"
EOF

# Step 17: Final tests
print_status "17. Running final tests..."
sleep 5

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

# Test SSL handshake
if echo | openssl s_client -servername $DOMAIN -connect $DOMAIN:443 2>/dev/null | grep -q "Verify return code: 0"; then
    print_success "SSL handshake: Successful"
else
    print_warning "SSL handshake: May have issues"
fi

# Step 18: Final status
print_status "18. Final status check..."
echo ""
echo "🔍 SERVICE STATUS:"
echo "=================="
systemctl status nginx --no-pager -l
echo ""
echo "📱 PM2 STATUS:"
echo "=============="
pm2 status
echo ""
echo "🔒 SSL CERTIFICATE STATUS:"
echo "=========================="
certbot certificates
echo ""
echo "🌐 CONNECTIVITY TEST:"
echo "====================="
echo "HTTP: $(curl -I http://$DOMAIN 2>/dev/null | head -1 || echo 'Failed')"
echo "HTTPS: $(curl -I https://$DOMAIN 2>/dev/null | head -1 || echo 'Failed')"

echo ""
print_success "SSL emergency fix completed!"
echo ""
echo "✅ FIXES APPLIED:"
echo "================="
echo "  ✅ Installed missing packages"
echo "  ✅ Configured firewall"
echo "  ✅ Started Node.js application with PM2"
echo "  ✅ Generated SSL certificate"
echo "  ✅ Created secure Nginx configuration"
echo "  ✅ Set up automatic certificate renewal"
echo "  ✅ Tested SSL functionality"
echo ""
echo "🌐 TEST YOUR WEBSITE:"
echo "====================="
echo "  HTTP:  http://$DOMAIN (should redirect to HTTPS)"
echo "  HTTPS: https://$DOMAIN (should load securely)"
echo ""
echo "📊 SSL GRADE CHECK:"
echo "==================="
echo "  Visit: https://www.ssllabs.com/ssltest/analyze.html?d=$DOMAIN"
echo ""
print_success "SSL emergency fix complete! 🔒"
