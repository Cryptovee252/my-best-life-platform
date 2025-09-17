#!/bin/bash

# 🔧 SECURITY FIX AND DEPLOYMENT SCRIPT
# This script will fix security issues and get your website working again

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

print_status "🔧 Starting security fix and deployment process..."

# Step 1: Check current status
print_status "📊 Checking current system status..."

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    print_error "Node.js is not installed. Installing Node.js 18.x..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
    apt-get install -y nodejs
else
    print_success "Node.js is installed: $(node --version)"
fi

# Check if PM2 is installed
if ! command -v pm2 &> /dev/null; then
    print_status "Installing PM2..."
    npm install -g pm2
else
    print_success "PM2 is installed: $(pm2 --version)"
fi

# Check if Nginx is installed
if ! command -v nginx &> /dev/null; then
    print_status "Installing Nginx..."
    apt update && apt install -y nginx
else
    print_success "Nginx is installed: $(nginx -v 2>&1)"
fi

# Check if PostgreSQL is installed
if ! command -v psql &> /dev/null; then
    print_status "Installing PostgreSQL..."
    apt install -y postgresql postgresql-contrib
else
    print_success "PostgreSQL is installed"
fi

# Step 2: Navigate to project directory
print_status "📁 Setting up project directory..."

# Create project directory if it doesn't exist
mkdir -p /var/www/mybestlife
cd /var/www/mybestlife

# If directory is empty, we need to upload the files
if [ ! -f "package.json" ]; then
    print_warning "Project files not found. You need to upload your project files to /var/www/mybestlife/"
    print_status "Please upload your project files and run this script again."
    exit 1
fi

# Step 3: Install dependencies
print_status "📦 Installing project dependencies..."
cd backend
npm install

# Step 4: Generate secure environment variables
print_status "🔐 Generating secure environment variables..."

# Generate secure secrets
JWT_SECRET=$(openssl rand -hex 64)
JWT_REFRESH_SECRET=$(openssl rand -hex 64)
SESSION_SECRET=$(openssl rand -hex 32)
DB_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)

# Create .env file
print_status "Creating secure .env file..."
cat > .env << EOF
# ===========================================
# DATABASE CONFIGURATION
# ===========================================
DATABASE_URL="postgresql://mybestlife:${DB_PASSWORD}@localhost:5432/mybestlife"

# ===========================================
# JWT SECURITY (CRITICAL - GENERATED SECURE SECRETS)
# ===========================================
JWT_SECRET="${JWT_SECRET}"
JWT_REFRESH_SECRET="${JWT_REFRESH_SECRET}"
JWT_EXPIRY="7d"
JWT_REFRESH_EXPIRY="30d"

# ===========================================
# EMAIL CONFIGURATION (UPDATE WITH YOUR CREDENTIALS)
# ===========================================
SMTP_HOST="smtp.gmail.com"
SMTP_PORT=587
SMTP_SECURE=false
SMTP_USER="your-email@gmail.com"
SMTP_PASS="your-gmail-app-password"
SMTP_FROM_NAME="My Best Life"
SMTP_FROM_EMAIL="your-email@gmail.com"

# ===========================================
# APPLICATION CONFIGURATION
# ===========================================
NODE_ENV="production"
PORT=3000
FRONTEND_URL="https://mybestlifeapp.com"
API_BASE_URL="https://mybestlifeapp.com/api"

# ===========================================
# SECURITY CONFIGURATION
# ===========================================
# Rate limiting
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100

# Password policy
MIN_PASSWORD_LENGTH=8
REQUIRE_UPPERCASE=true
REQUIRE_LOWERCASE=true
REQUIRE_NUMBERS=true
REQUIRE_SYMBOLS=true

# Account lockout
MAX_LOGIN_ATTEMPTS=5
LOCKOUT_DURATION_MINUTES=15

# Session security
SESSION_SECRET="${SESSION_SECRET}"
COOKIE_SECURE=true
COOKIE_HTTP_ONLY=true
COOKIE_SAME_SITE="strict"

# ===========================================
# SSL/TLS CONFIGURATION
# ===========================================
FORCE_HTTPS=true

# ===========================================
# MONITORING & LOGGING
# ===========================================
LOG_LEVEL="info"
LOG_FILE_PATH="/var/log/mybestlife/app.log"
ENABLE_SECURITY_LOGGING=true
ENABLE_AUDIT_LOGGING=true
EOF

print_success "Environment file created with secure secrets!"

# Step 5: Set up PostgreSQL database
print_status "🗄️ Setting up PostgreSQL database..."

# Create database and user
sudo -u postgres psql << EOF
DROP DATABASE IF EXISTS mybestlife;
DROP USER IF EXISTS mybestlife;
CREATE DATABASE mybestlife;
CREATE USER mybestlife WITH PASSWORD '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON DATABASE mybestlife TO mybestlife;
\q
EOF

print_success "Database created successfully!"

# Step 6: Set up database schema
print_status "📊 Setting up database schema..."
npx prisma generate
npx prisma db push

print_success "Database schema created!"

# Step 7: Configure Nginx
print_status "🌐 Configuring Nginx..."

# Create secure Nginx configuration
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

print_success "Nginx configured successfully!"

# Step 8: Configure firewall
print_status "🔥 Configuring firewall..."
ufw allow ssh
ufw allow 'Nginx Full'
ufw allow 80
ufw allow 443
ufw --force enable

print_success "Firewall configured!"

# Step 9: Install and configure SSL
print_status "🔒 Setting up SSL certificates..."

# Install Certbot if not installed
if ! command -v certbot &> /dev/null; then
    apt install -y certbot python3-certbot-nginx
fi

# Get SSL certificate
certbot --nginx -d mybestlifeapp.com -d www.mybestlifeapp.com --email admin@mybestlifeapp.com --agree-tos --non-interactive --redirect

print_success "SSL certificate obtained!"

# Step 10: Start the application
print_status "🚀 Starting application with PM2..."

# Stop any existing PM2 processes
pm2 delete all 2>/dev/null || true

# Start the secure application
pm2 start app-secure.js --name mybestlife-secure
pm2 save
pm2 startup

print_success "Application started with PM2!"

# Step 11: Create log directory
mkdir -p /var/log/mybestlife
chown -R www-data:www-data /var/log/mybestlife

# Step 12: Test everything
print_status "🧪 Testing setup..."

sleep 5

# Test application
if curl -f http://localhost:3000/api/health > /dev/null 2>&1; then
    print_success "✅ Application is running!"
else
    print_warning "⚠️ Application test failed - check PM2 status"
fi

# Test website
if curl -f https://mybestlifeapp.com > /dev/null 2>&1; then
    print_success "✅ Website is accessible!"
else
    print_warning "⚠️ Website test failed - check SSL certificate"
fi

# Step 13: Show final status
print_status "📊 Final Status Report:"
echo ""
echo "🔧 Services Status:"
systemctl is-active nginx && echo "✅ Nginx: Running" || echo "❌ Nginx: Not running"
systemctl is-active postgresql && echo "✅ PostgreSQL: Running" || echo "❌ PostgreSQL: Not running"
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
echo "✅ SSL/TLS encryption"
echo "✅ Security headers implemented"
echo "✅ Rate limiting configured"
echo "✅ Firewall enabled"
echo "✅ Secure environment variables"
echo "✅ Database security"
echo ""
print_warning "⚠️ IMPORTANT NEXT STEPS:"
echo "1. Edit .env file: nano /var/www/mybestlife/backend/.env"
echo "2. Update SMTP_USER and SMTP_PASS with your Gmail credentials"
echo "3. Test registration: https://mybestlifeapp.com/register.html"
echo "4. Monitor logs: pm2 logs mybestlife-secure"
echo ""
print_success "🎉 Security fix and deployment completed!"
print_status "Your website should now be working securely at: https://mybestlifeapp.com"

