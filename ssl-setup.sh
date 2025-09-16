#!/bin/bash

# SSL/TLS Security Setup Script for My Best Life Platform
# This script configures secure SSL/TLS certificates and security headers

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

# Configuration
DOMAIN="mybestlifeapp.com"
EMAIL="admin@mybestlifeapp.com"
NGINX_CONFIG="/etc/nginx/sites-available/mybestlife"
SSL_CONFIG_DIR="/etc/ssl/mybestlife"

print_status "Starting SSL/TLS security setup for $DOMAIN"

# Update system packages
print_status "Updating system packages..."
apt update && apt upgrade -y

# Install required packages
print_status "Installing required packages..."
apt install -y nginx certbot python3-certbot-nginx ufw fail2ban

# Create SSL configuration directory
print_status "Creating SSL configuration directory..."
mkdir -p $SSL_CONFIG_DIR
chmod 700 $SSL_CONFIG_DIR

# Configure firewall
print_status "Configuring firewall..."
ufw allow ssh
ufw allow 'Nginx Full'
ufw allow 80
ufw allow 443
ufw --force enable

# Create secure Nginx configuration
print_status "Creating secure Nginx configuration..."
cat > $NGINX_CONFIG << 'EOF'
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

# Enable the site
print_status "Enabling Nginx site..."
ln -sf /etc/nginx/sites-available/mybestlife /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Test Nginx configuration
print_status "Testing Nginx configuration..."
nginx -t

# Start Nginx
print_status "Starting Nginx..."
systemctl start nginx
systemctl enable nginx

# Get SSL certificate
print_status "Obtaining SSL certificate from Let's Encrypt..."
certbot --nginx -d $DOMAIN -d www.$DOMAIN --email $EMAIL --agree-tos --non-interactive --redirect

# Configure automatic renewal
print_status "Setting up automatic SSL renewal..."
cat > /etc/cron.d/certbot-renew << 'EOF'
# Renew Let's Encrypt certificates twice daily
0 12 * * * root certbot renew --quiet --post-hook "systemctl reload nginx"
0 0 * * * root certbot renew --quiet --post-hook "systemctl reload nginx"
EOF

# Configure Fail2ban for additional security
print_status "Configuring Fail2ban..."
cat > /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5

[nginx-http-auth]
enabled = true
port = http,https
logpath = /var/log/nginx/error.log

[nginx-limit-req]
enabled = true
port = http,https
logpath = /var/log/nginx/error.log
maxretry = 10

[nginx-badbots]
enabled = true
port = http,https
logpath = /var/log/nginx/access.log
maxretry = 2

[nginx-noscript]
enabled = true
port = http,https
logpath = /var/log/nginx/access.log
maxretry = 6

[nginx-proxy]
enabled = true
port = http,https
logpath = /var/log/nginx/access.log
maxretry = 2
EOF

# Start Fail2ban
print_status "Starting Fail2ban..."
systemctl start fail2ban
systemctl enable fail2ban

# Create SSL monitoring script
print_status "Creating SSL monitoring script..."
cat > /usr/local/bin/ssl-monitor.sh << 'EOF'
#!/bin/bash

# SSL Certificate Monitoring Script
DOMAIN="mybestlifeapp.com"
EMAIL="admin@mybestlifeapp.com"

# Check certificate expiration
EXPIRY_DATE=$(echo | openssl s_client -servername $DOMAIN -connect $DOMAIN:443 2>/dev/null | openssl x509 -noout -dates | grep notAfter | cut -d= -f2)
EXPIRY_TIMESTAMP=$(date -d "$EXPIRY_DATE" +%s)
CURRENT_TIMESTAMP=$(date +%s)
DAYS_UNTIL_EXPIRY=$(( (EXPIRY_TIMESTAMP - CURRENT_TIMESTAMP) / 86400 ))

if [ $DAYS_UNTIL_EXPIRY -lt 30 ]; then
    echo "SSL certificate for $DOMAIN expires in $DAYS_UNTIL_EXPIRY days" | mail -s "SSL Certificate Expiring Soon" $EMAIL
fi

echo "SSL certificate expires in $DAYS_UNTIL_EXPIRY days"
EOF

chmod +x /usr/local/bin/ssl-monitor.sh

# Add SSL monitoring to cron
print_status "Setting up SSL monitoring..."
echo "0 9 * * * root /usr/local/bin/ssl-monitor.sh" >> /etc/cron.d/ssl-monitor

# Create security audit script
print_status "Creating security audit script..."
cat > /usr/local/bin/security-audit.sh << 'EOF'
#!/bin/bash

# Security Audit Script
echo "=== Security Audit Report - $(date) ==="
echo

echo "1. SSL Certificate Status:"
certbot certificates

echo
echo "2. Nginx Configuration Test:"
nginx -t

echo
echo "3. Fail2ban Status:"
fail2ban-client status

echo
echo "4. Firewall Status:"
ufw status verbose

echo
echo "5. SSL Grade Check:"
curl -s "https://api.ssllabs.com/api/v3/analyze?host=mybestlifeapp.com&publish=off&startNew=on" | grep -o '"grade":"[^"]*"'

echo
echo "6. Security Headers Check:"
curl -I https://mybestlifeapp.com | grep -E "(Strict-Transport-Security|X-Frame-Options|X-Content-Type-Options|X-XSS-Protection|Content-Security-Policy)"

echo
echo "=== End of Security Audit ==="
EOF

chmod +x /usr/local/bin/security-audit.sh

# Reload Nginx with new configuration
print_status "Reloading Nginx..."
systemctl reload nginx

# Test SSL configuration
print_status "Testing SSL configuration..."
sleep 5
curl -I https://$DOMAIN > /dev/null 2>&1 && print_success "SSL is working correctly" || print_warning "SSL test failed"

# Final security check
print_status "Running final security audit..."
/usr/local/bin/security-audit.sh

print_success "SSL/TLS security setup completed!"
print_status "Your website is now secured with:"
echo "  ✅ SSL/TLS encryption"
echo "  ✅ Security headers"
echo "  ✅ Rate limiting"
echo "  ✅ Fail2ban protection"
echo "  ✅ Automatic certificate renewal"
echo "  ✅ Security monitoring"

print_status "Next steps:"
echo "  1. Test your website: https://$DOMAIN"
echo "  2. Run security audit: /usr/local/bin/security-audit.sh"
echo "  3. Monitor SSL expiry: /usr/local/bin/ssl-monitor.sh"
echo "  4. Check SSL grade: https://www.ssllabs.com/ssltest/analyze.html?d=$DOMAIN"

print_success "Security setup complete! 🔒"
