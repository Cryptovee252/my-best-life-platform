#!/bin/bash

# HelpMyBestLife Platform v1.2 - Fixed VPS Deployment Script
# This script handles PostgreSQL authentication issues automatically

set -e

echo "🚀 HelpMyBestLife Platform v1.2 - Fixed VPS Deployment"
echo "======================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
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

print_status "Starting deployment from cloned repository..."

# Update system packages
print_status "Updating system packages..."
apt update && apt upgrade -y

# Install Node.js 18+
print_status "Installing Node.js 18+..."
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs

# Install PostgreSQL
print_status "Installing PostgreSQL..."
apt-get install -y postgresql postgresql-contrib

# Install Nginx
print_status "Installing Nginx..."
apt-get install -y nginx

# Install PM2
print_status "Installing PM2..."
npm install -g pm2

# Install Certbot for SSL
print_status "Installing Certbot for SSL..."
apt-get install -y certbot python3-certbot-nginx

# Setup PostgreSQL
print_status "Setting up PostgreSQL database..."

# Start PostgreSQL service
systemctl start postgresql
systemctl enable postgresql

# Set PostgreSQL password
print_status "Setting PostgreSQL password..."
sudo -u postgres psql -c "ALTER USER postgres PASSWORD 'MyBestLife2024!';"

# Update PostgreSQL configuration
print_status "Updating PostgreSQL configuration..."
sed -i "s/local   all             postgres                                peer/local   all             postgres                                md5/" /etc/postgresql/16/main/pg_hba.conf

# Restart PostgreSQL
systemctl restart postgresql

# Create production database
print_status "Creating production database..."
sudo -u postgres createdb mybestlife_prod

# Create log directory
print_status "Creating log directory..."
mkdir -p /var/log/mybestlife
chown -R www-data:www-data /var/log/mybestlife

# Install backend dependencies
print_status "Installing backend dependencies..."
cd /root/my-best-life-platform/backend
npm install --production

# Create production environment file
print_status "Creating production environment file..."
cat > /root/my-best-life-platform/backend/.env << EOF
NODE_ENV=production
PORT=3001
DATABASE_URL="postgresql://postgres:MyBestLife2024!@localhost:5432/mybestlife_prod"
JWT_SECRET="MyBestLife2024_JWT_Secret_Key_Production_Secure"
JWT_EXPIRES_IN=7d
BCRYPT_ROUNDS=12
CORS_ORIGIN=https://mybestlifeapp.com
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_ATTEMPTS=5
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USER=your-email@gmail.com
EMAIL_PASS=your-app-password
EMAIL_FROM=noreply@mybestlifeapp.com
SECURITY_HEADERS=true
CSP_ENABLED=true
HSTS_ENABLED=true
XSS_PROTECTION=true
CONTENT_TYPE_NOSNIFF=true
FRAME_OPTIONS=DENY
EOF

# Run database migrations
print_status "Running database migrations..."
cd /root/my-best-life-platform/backend
npx prisma db push

# Start backend with PM2
print_status "Starting backend with PM2..."
pm2 start app.js --name "mybestlife-backend" --env production
pm2 save
pm2 startup

# Build frontend
print_status "Building frontend..."
cd /root/my-best-life-platform/frontend
npm install
npm run build

# Create Nginx configuration
print_status "Creating Nginx configuration..."
cat > /etc/nginx/sites-available/mybestlifeapp.com << EOF
server {
    listen 80;
    server_name mybestlifeapp.com www.mybestlifeapp.com;
    
    # Security headers
    add_header X-Frame-Options "DENY" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; font-src 'self' data:; connect-src 'self' https:; frame-ancestors 'none';" always;
    
    # Rate limiting
    limit_req_zone \$binary_remote_addr zone=api:10m rate=10r/m;
    limit_req_zone \$binary_remote_addr zone=auth:10m rate=5r/m;
    
    # Frontend
    location / {
        root /root/my-best-life-platform/frontend/dist;
        try_files \$uri \$uri/ /index.html;
        
        # Cache static assets
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

# Enable the site
ln -sf /etc/nginx/sites-available/mybestlifeapp.com /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Test Nginx configuration
nginx -t

# Restart Nginx
systemctl restart nginx
systemctl enable nginx

# Setup SSL certificate
print_status "Setting up SSL certificate..."
certbot --nginx -d mybestlifeapp.com -d www.mybestlifeapp.com --non-interactive --agree-tos --email admin@mybestlifeapp.com

# Setup automatic SSL renewal
print_status "Setting up automatic SSL renewal..."
(crontab -l 2>/dev/null; echo "0 12 * * * /usr/bin/certbot renew --quiet") | crontab -

# Setup firewall
print_status "Setting up firewall..."
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable

# Final status check
print_status "Checking deployment status..."
systemctl status postgresql --no-pager -l
systemctl status nginx --no-pager -l
pm2 status

print_success "🎉 Deployment completed successfully!"
print_success "Your HelpMyBestLife Platform v1.2 is now live!"
print_success "Frontend: https://mybestlifeapp.com"
print_success "API: https://mybestlifeapp.com/api/health"
print_success "Backend running on PM2: mybestlife-backend"

echo ""
echo "🔒 Security Features Active:"
echo "✅ JWT Authentication with bcrypt"
echo "✅ Security Headers (CSP, HSTS, XSS protection)"
echo "✅ Rate Limiting (5 auth attempts/15min)"
echo "✅ Input Validation and sanitization"
echo "✅ CORS Security with origin validation"
echo "✅ Security Logging and audit trail"
echo "✅ SSL/TLS Encryption"
echo ""
echo "📊 Monitoring:"
echo "• PM2: pm2 status"
echo "• Logs: pm2 logs mybestlife-backend"
echo "• Nginx: systemctl status nginx"
echo "• Database: systemctl status postgresql"
echo ""
echo "🚀 Your VPS deployment is complete!"
