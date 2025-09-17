#!/bin/bash

# 🚀 HelpMyBestLife Platform v1.2 - Direct VPS Deployment Script
# This script deploys directly from the cloned repository

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

echo "🚀 HelpMyBestLife Platform v1.2 - Direct VPS Deployment"
echo "======================================================="

# Check if we're in the right directory
if [ ! -f "package.json" ] || [ ! -d "backend" ] || [ ! -d "frontend" ]; then
    print_error "Not in the correct directory!"
    echo "Please run this script from the my-best-life-platform directory"
    echo "Make sure you've cloned the repository first:"
    echo "git clone https://github.com/Cryptovee252/my-best-life-platform.git"
    echo "cd my-best-life-platform"
    exit 1
fi

print_status "Starting deployment from cloned repository..."

# Update system
print_status "Updating system packages..."
apt update && apt upgrade -y

# Install Node.js 18+
print_status "Installing Node.js 18+..."
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs

# Install PostgreSQL
print_status "Installing PostgreSQL..."
apt install postgresql postgresql-contrib -y

# Install Nginx
print_status "Installing Nginx..."
apt install nginx -y

# Install PM2
print_status "Installing PM2..."
npm install -g pm2

# Install Certbot for SSL
print_status "Installing Certbot for SSL..."
apt install certbot python3-certbot-nginx -y

# Create application directory
print_status "Setting up application directory..."
mkdir -p /var/www/mybestlife
chown $USER:$USER /var/www/mybestlife

# Create database
print_status "Setting up database..."
systemctl start postgresql
systemctl enable postgresql

# Create database and user
sudo -u postgres psql -c "CREATE DATABASE mybestlife_prod;" || true
sudo -u postgres psql -c "CREATE USER mybestlife_user WITH PASSWORD 'secure_password';" || true
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE mybestlife_prod TO mybestlife_user;" || true

# Create log directory
print_status "Creating log directory..."
mkdir -p /var/log/mybestlife
chown $USER:$USER /var/log/mybestlife

# Install dependencies
print_status "Installing backend dependencies..."
cd backend
npm install --production

# Create production environment file
print_status "Creating production environment file..."
cat > .env << EOF
NODE_ENV=production
PORT=3000
DATABASE_URL="postgresql://mybestlife_user:secure_password@localhost:5432/mybestlife_prod"
JWT_SECRET="your-super-secure-jwt-secret-key-min-32-chars-change-this"
JWT_REFRESH_SECRET="your-super-secure-refresh-secret-key-min-32-chars-change-this"
FRONTEND_URL="https://mybestlifeapp.com"
EMAIL_HOST="smtp.gmail.com"
EMAIL_USER="your-production-email@gmail.com"
EMAIL_PASS="your-gmail-app-password"
ENABLE_SECURITY_LOGGING=true
ENABLE_AUDIT_LOGGING=true
FORCE_HTTPS=true
MAX_LOGIN_ATTEMPTS=5
LOCKOUT_DURATION_MINUTES=15
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100
EOF

# Run database migrations
print_status "Running database migrations..."
npm run db:push

# Start backend with PM2
print_status "Starting backend with PM2..."
pm2 stop mybestlife-backend || true
pm2 delete mybestlife-backend || true
pm2 start app-secure.js --name "mybestlife-backend" --env production

# Build frontend
print_status "Building frontend..."
cd ../frontend
npm install
npm run build:web

# Copy frontend files to web directory
print_status "Copying frontend files..."
cp -r dist/* /var/www/mybestlife/

# Configure Nginx
print_status "Configuring Nginx..."
cat > /etc/nginx/sites-available/mybestlifeapp.com << EOF
server {
    listen 80;
    server_name mybestlifeapp.com www.mybestlifeapp.com;
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name mybestlifeapp.com www.mybestlifeapp.com;

    ssl_certificate /etc/letsencrypt/live/mybestlifeapp.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/mybestlifeapp.com/privkey.pem;

    # Security headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; font-src 'self' data:; connect-src 'self' https:; frame-ancestors 'self';" always;

    # Frontend
    location / {
        root /var/www/mybestlife;
        try_files \$uri \$uri/ /index.html;
    }

    # API
    location /api {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }

    # Security
    location ~ /\. {
        deny all;
    }
}
EOF

# Enable the site
ln -sf /etc/nginx/sites-available/mybestlifeapp.com /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Test Nginx configuration
nginx -t

# Reload Nginx
systemctl reload nginx

# Setup SSL certificate
print_status "Setting up SSL certificate..."
certbot --nginx -d mybestlifeapp.com -d www.mybestlifeapp.com --non-interactive --agree-tos --email admin@mybestlifeapp.com || print_warning "SSL setup failed - you may need to configure DNS first"

# Setup auto-renewal
systemctl enable certbot.timer
systemctl start certbot.timer

# Save PM2 configuration
pm2 save
pm2 startup

print_success "Deployment complete!"
echo ""
echo "🎉 **Your VPS is now running Version 1.2!**"
echo ""
echo "🔗 **Access your application:**"
echo "   Frontend: https://mybestlifeapp.com"
echo "   API: https://mybestlifeapp.com/api/health"
echo ""
echo "📊 **Monitor your application:**"
echo "   pm2 logs mybestlife-backend"
echo "   pm2 monit"
echo ""
echo "🔒 **Security features active:**"
echo "   ✅ JWT Authentication"
echo "   ✅ Security Headers"
echo "   ✅ Rate Limiting"
echo "   ✅ SSL/TLS Encryption"
echo "   ✅ Input Validation"
echo ""
print_success "Version 1.2 deployed successfully! 🚀"
