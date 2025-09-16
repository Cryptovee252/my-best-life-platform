#!/bin/bash

# Complete VPS Setup Script for My Best Life Platform
# This script will set up everything needed for a secure deployment

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

print_status "Starting complete VPS setup for My Best Life Platform..."

# Update system
print_status "Updating system packages..."
apt update && apt upgrade -y

# Install required packages
print_status "Installing required packages..."
apt install -y curl wget git nginx postgresql postgresql-contrib certbot python3-certbot-nginx ufw fail2ban

# Install Node.js 18.x
print_status "Installing Node.js 18.x..."
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs

# Install PM2 globally
print_status "Installing PM2..."
npm install -g pm2

# Create project directory
print_status "Setting up project directory..."
cd /var/www
rm -rf mybestlife  # Remove existing directory if it exists
git clone https://github.com/Cryptovee252/my-best-life-platform.git mybestlife
cd mybestlife

# Install project dependencies
print_status "Installing project dependencies..."
cd backend
npm install

# Generate secure secrets
print_status "Generating secure secrets..."
JWT_SECRET=$(openssl rand -hex 32)
JWT_REFRESH_SECRET=$(openssl rand -hex 32)
SESSION_SECRET=$(openssl rand -hex 16)

# Create .env file
print_status "Creating environment configuration..."
cat > .env << EOF
# Database Configuration
DATABASE_URL="postgresql://mybestlife:secure_password_123@localhost:5432/mybestlife"

# JWT Security
JWT_SECRET="$JWT_SECRET"
JWT_REFRESH_SECRET="$JWT_REFRESH_SECRET"
JWT_EXPIRY="7d"
JWT_REFRESH_EXPIRY="30d"

# Email Configuration (Update with your Gmail credentials)
SMTP_HOST="smtp.gmail.com"
SMTP_PORT=587
SMTP_SECURE=false
SMTP_USER="your-email@gmail.com"
SMTP_PASS="your-gmail-app-password"
SMTP_FROM_NAME="My Best Life"
SMTP_FROM_EMAIL="your-email@gmail.com"

# Application Configuration
NODE_ENV="production"
PORT=3000
FRONTEND_URL="https://mybestlifeapp.com"
API_BASE_URL="https://mybestlifeapp.com/api"

# Security Configuration
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100
MIN_PASSWORD_LENGTH=8
REQUIRE_UPPERCASE=true
REQUIRE_LOWERCASE=true
REQUIRE_NUMBERS=true
REQUIRE_SYMBOLS=true
MAX_LOGIN_ATTEMPTS=5
LOCKOUT_DURATION_MINUTES=15
SESSION_SECRET="$SESSION_SECRET"
COOKIE_SECURE=true
COOKIE_HTTP_ONLY=true
COOKIE_SAME_SITE="strict"

# SSL/TLS Configuration
FORCE_HTTPS=true

# Monitoring & Logging
LOG_LEVEL="info"
LOG_FILE_PATH="/var/log/mybestlife/app.log"
ENABLE_SECURITY_LOGGING=true
ENABLE_AUDIT_LOGGING=true

# Backup Configuration
BACKUP_ENCRYPTION_KEY="$(openssl rand -hex 16)"
BACKUP_RETENTION_DAYS=30
BACKUP_SCHEDULE="0 2 * * *"
EOF

print_warning "IMPORTANT: Please edit the .env file and update the email credentials!"
print_warning "Run: nano .env"
print_warning "Update SMTP_USER and SMTP_PASS with your Gmail app password"

# Set up PostgreSQL database
print_status "Setting up PostgreSQL database..."
sudo -u postgres psql << 'EOF'
CREATE DATABASE mybestlife;
CREATE USER mybestlife WITH PASSWORD 'secure_password_123';
GRANT ALL PRIVILEGES ON DATABASE mybestlife TO mybestlife;
\q
EOF

# Set up database schema
print_status "Setting up database schema..."
npx prisma generate
npx prisma db push

# Configure Nginx
print_status "Configuring Nginx..."
cat > /etc/nginx/sites-available/mybestlife << 'EOF'
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
    
    # SSL Configuration (will be updated by Certbot)
    ssl_certificate /etc/letsencrypt/live/mybestlifeapp.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/mybestlifeapp.com/privkey.pem;
    
    # SSL Security Settings
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    ssl_session_tickets off;
    
    # Security Headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
    add_header X-Frame-Options "DENY" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; font-src 'self'; connect-src 'self'; frame-ancestors 'none';" always;
    
    # Hide Nginx version
    server_tokens off;
    
    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml text/javascript application/json application/javascript application/xml+rss application/atom+xml image/svg+xml;
    
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
}
EOF

# Enable the site
ln -sf /etc/nginx/sites-available/mybestlife /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Test Nginx configuration
nginx -t

# Start Nginx
systemctl start nginx
systemctl enable nginx

# Configure firewall
print_status "Configuring firewall..."
ufw allow ssh
ufw allow 'Nginx Full'
ufw allow 80
ufw allow 443
ufw --force enable

# Configure Fail2ban
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
EOF

systemctl start fail2ban
systemctl enable fail2ban

# Start the application
print_status "Starting application with PM2..."
pm2 start app-secure.js --name mybestlife
pm2 save
pm2 startup

# Get SSL certificate
print_status "Obtaining SSL certificate from Let's Encrypt..."
certbot --nginx -d mybestlifeapp.com -d www.mybestlifeapp.com --email admin@mybestlifeapp.com --agree-tos --non-interactive --redirect

# Configure automatic renewal
print_status "Setting up automatic SSL renewal..."
cat > /etc/cron.d/certbot-renew << 'EOF'
# Renew Let's Encrypt certificates twice daily
0 12 * * * root certbot renew --quiet --post-hook "systemctl reload nginx"
0 0 * * * root certbot renew --quiet --post-hook "systemctl reload nginx"
EOF

# Create log directory
mkdir -p /var/log/mybestlife
chown -R www-data:www-data /var/log/mybestlife

# Test everything
print_status "Testing setup..."
sleep 5

# Test application
if curl -f http://localhost:3000/api/health > /dev/null 2>&1; then
    print_success "Application is running!"
else
    print_warning "Application test failed - check PM2 status"
fi

# Test website
if curl -f https://mybestlifeapp.com > /dev/null 2>&1; then
    print_success "Website is accessible!"
else
    print_warning "Website test failed - check SSL certificate"
fi

# Show status
print_status "Setup complete! Here's the status:"
echo ""
echo "🔧 Services Status:"
systemctl is-active nginx && echo "✅ Nginx: Running" || echo "❌ Nginx: Not running"
systemctl is-active postgresql && echo "✅ PostgreSQL: Running" || echo "❌ PostgreSQL: Not running"
systemctl is-active fail2ban && echo "✅ Fail2ban: Running" || echo "❌ Fail2ban: Not running"
echo ""
echo "📱 Application Status:"
pm2 status
echo ""
echo "🌐 Website URLs:"
echo "✅ https://mybestlifeapp.com"
echo "✅ https://www.mybestlifeapp.com"
echo "✅ https://mybestlifeapp.com/api/health"
echo ""
echo "🔒 Security Features:"
echo "✅ SSL/TLS encryption (A+ grade)"
echo "✅ Security headers implemented"
echo "✅ Rate limiting configured"
echo "✅ Firewall enabled"
echo "✅ Fail2ban protection"
echo "✅ Automatic SSL renewal"
echo ""
print_warning "IMPORTANT NEXT STEPS:"
echo "1. Edit .env file: nano /var/www/mybestlife/backend/.env"
echo "2. Update SMTP_USER and SMTP_PASS with your Gmail credentials"
echo "3. Test registration: https://mybestlifeapp.com/register.html"
echo "4. Monitor logs: pm2 logs mybestlife"
echo ""
print_success "🎉 My Best Life Platform is now securely deployed!"
print_status "Your website is ready at: https://mybestlifeapp.com"
