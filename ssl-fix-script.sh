#!/bin/bash

# SSL Fix Script for My Best Life Platform
# This script fixes common SSL issues

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

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   print_error "This script must be run as root (use sudo)"
   exit 1
fi

DOMAIN="mybestlifeapp.com"
EMAIL="admin@mybestlifeapp.com"

echo "🔧 SSL FIX SCRIPT"
echo "================="
echo "Domain: $DOMAIN"
echo "Date: $(date)"
echo ""

# Step 1: Update system packages
print_status "1. Updating system packages..."
apt update && apt upgrade -y

# Step 2: Install required packages
print_status "2. Installing required packages..."
apt install -y nginx certbot python3-certbot-nginx ufw openssl

# Step 3: Configure firewall
print_status "3. Configuring firewall..."
ufw allow ssh
ufw allow 'Nginx Full'
ufw allow 80
ufw allow 443
ufw --force enable

# Step 4: Stop any existing services
print_status "4. Stopping services for maintenance..."
systemctl stop nginx 2>/dev/null || true

# Step 5: Backup existing configuration
print_status "5. Backing up existing configuration..."
mkdir -p /backup/ssl-fix-$(date +%Y%m%d-%H%M%S)
cp -r /etc/nginx/sites-available/mybestlife /backup/ssl-fix-$(date +%Y%m%d-%H%M%S)/ 2>/dev/null || true
cp -r /etc/letsencrypt/live/$DOMAIN /backup/ssl-fix-$(date +%Y%m%d-%H%M%S)/ 2>/dev/null || true

# Step 6: Remove existing SSL certificate (if any)
print_status "6. Cleaning up existing SSL certificate..."
certbot delete --cert-name $DOMAIN --non-interactive 2>/dev/null || true

# Step 7: Create temporary HTTP-only Nginx config for certificate generation
print_status "7. Creating temporary Nginx configuration..."
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

# Step 8: Enable site and test configuration
print_status "8. Enabling Nginx site..."
ln -sf /etc/nginx/sites-available/mybestlife /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Test Nginx configuration
nginx -t

# Step 9: Start Nginx
print_status "9. Starting Nginx..."
systemctl start nginx
systemctl enable nginx

# Step 10: Obtain SSL certificate
print_status "10. Obtaining SSL certificate from Let's Encrypt..."
certbot --nginx -d $DOMAIN -d www.$DOMAIN --email $EMAIL --agree-tos --non-interactive --redirect

# Step 11: Create final secure Nginx configuration
print_status "11. Creating final secure Nginx configuration..."
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

# Step 12: Test final configuration
print_status "12. Testing final Nginx configuration..."
nginx -t

# Step 13: Reload Nginx
print_status "13. Reloading Nginx..."
systemctl reload nginx

# Step 14: Configure automatic renewal
print_status "14. Setting up automatic SSL renewal..."
cat > /etc/cron.d/certbot-renew << 'EOF'
# Renew Let's Encrypt certificates twice daily
0 12 * * * root certbot renew --quiet --post-hook "systemctl reload nginx"
0 0 * * * root certbot renew --quiet --post-hook "systemctl reload nginx"
EOF

# Step 15: Test SSL
print_status "15. Testing SSL configuration..."
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

# Step 16: Final status check
print_status "16. Final status check..."
echo ""
echo "🔍 SERVICE STATUS:"
echo "=================="
systemctl status nginx --no-pager -l
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
print_success "SSL fix script completed!"
echo ""
echo "✅ FIXES APPLIED:"
echo "================="
echo "  ✅ Updated system packages"
echo "  ✅ Installed required SSL tools"
echo "  ✅ Configured firewall"
echo "  ✅ Generated new SSL certificate"
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
print_success "SSL fix complete! 🔒"
