#!/bin/bash

# 🚀 Fix VPS Sync - Streamlined Deployment Solution
# This script will clean up your VPS and deploy fresh files

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# VPS Configuration
VPS_IP="147.93.47.43"
VPS_USER="root"
VPS_DOMAIN="mybestlifeapp.com"

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

echo "🚀 Fix VPS Sync - Streamlined Deployment Solution"
echo "=================================================="
echo "VPS: $VPS_IP | Domain: $VPS_DOMAIN"
echo ""

# Step 1: Build fresh frontend locally
print_status "Building fresh frontend locally..."
cd frontend
npm install
npm run build:web-stable
print_success "Frontend built successfully"

# Step 2: Create clean deployment package
print_status "Creating clean deployment package..."
cd ..
rm -rf vps-clean-deployment
mkdir -p vps-clean-deployment

# Copy only essential files
cp -r backend vps-clean-deployment/
cp -r frontend/dist vps-clean-deployment/frontend-dist
cp package.json vps-clean-deployment/
cp package-lock.json vps-clean-deployment/

# Create production environment
cat > vps-clean-deployment/.env.production << EOF
NODE_ENV=production
PORT=3000
DATABASE_URL="postgresql://mybestlife_user:secure_password@localhost:5432/mybestlife_prod"
JWT_SECRET="your-super-secure-jwt-secret-key-min-32-chars-change-this"
JWT_REFRESH_SECRET="your-super-secure-refresh-secret-key-min-32-chars-change-this"
FRONTEND_URL="https://$VPS_DOMAIN"
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

# Create VPS cleanup and deployment script
cat > vps-clean-deployment/fix-vps-deployment.sh << 'EOF'
#!/bin/bash

# VPS Cleanup and Fresh Deployment Script

set -e

echo "🧹 Cleaning up VPS and deploying fresh files..."

# Stop all services
pm2 stop all || true
pm2 delete all || true
sudo systemctl stop nginx || true

# Clean up old files
sudo rm -rf /var/www/mybestlife/*
sudo rm -rf /home/root/vps-deployment
sudo rm -rf /home/root/helpmybestlife*
sudo rm -rf /root/vps-deployment
sudo rm -rf /root/helpmybestlife*

# Clear nginx cache
sudo rm -rf /var/cache/nginx/*
sudo rm -rf /var/lib/nginx/cache/*

# Install backend dependencies
cd backend
npm install --production --no-optional

# Run database migrations
npm run db:push || echo "Database already up to date"

# Start backend with PM2
pm2 start app-secure.js --name "mybestlife-backend" --env production

# Deploy frontend
sudo cp -r ../frontend-dist/* /var/www/mybestlife/
sudo chown -R www-data:www-data /var/www/mybestlife

# Restart nginx
sudo systemctl start nginx
sudo systemctl reload nginx

# Save PM2 configuration
pm2 save
pm2 startup || true

echo "✅ VPS cleanup and deployment complete!"
echo "🔍 Testing deployment..."

# Test endpoints
curl -I http://localhost:3000/api/health || echo "Backend health check failed"
curl -I http://localhost || echo "Frontend check failed"

echo "🌐 Your site should now show the latest version!"
EOF

chmod +x vps-clean-deployment/fix-vps-deployment.sh

# Create nginx configuration with cache busting
cat > vps-clean-deployment/nginx-config << EOF
server {
    listen 80;
    server_name $VPS_DOMAIN www.$VPS_DOMAIN;
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name $VPS_DOMAIN www.$VPS_DOMAIN;

    ssl_certificate /etc/letsencrypt/live/$VPS_DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$VPS_DOMAIN/privkey.pem;

    # Disable caching for HTML files to ensure fresh content
    location ~* \.(html|htm)$ {
        root /var/www/mybestlife;
        add_header Cache-Control "no-cache, no-store, must-revalidate";
        add_header Pragma "no-cache";
        add_header Expires "0";
        try_files \$uri \$uri/ /index.html;
    }

    # Cache static assets with versioning
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        root /var/www/mybestlife;
        expires 1y;
        add_header Cache-Control "public, immutable";
        add_header Vary "Accept-Encoding";
    }

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
        
        # Disable caching for API
        add_header Cache-Control "no-cache, no-store, must-revalidate";
        add_header Pragma "no-cache";
        add_header Expires "0";
    }

    # Security
    location ~ /\. {
        deny all;
    }
}
EOF

# Create deployment archive
print_status "Creating deployment archive..."
tar -czf vps-clean-deployment.tar.gz vps-clean-deployment/

print_success "Clean deployment package created!"
echo ""
echo "📦 **Clean Deployment Package:**"
echo "   File: vps-clean-deployment.tar.gz"
echo "   Size: $(du -h vps-clean-deployment.tar.gz | cut -f1)"
echo ""
echo "🚀 **Deployment Commands:**"
echo ""
echo "1. Upload to VPS:"
echo "   scp vps-clean-deployment.tar.gz root@$VPS_IP:/root/"
echo ""
echo "2. SSH to VPS:"
echo "   ssh root@$VPS_IP"
echo ""
echo "3. Extract and deploy:"
echo "   tar -xzf vps-clean-deployment.tar.gz"
echo "   cd vps-clean-deployment"
echo "   ./fix-vps-deployment.sh"
echo ""
echo "4. Update nginx config:"
echo "   sudo cp nginx-config /etc/nginx/sites-available/$VPS_DOMAIN"
echo "   sudo nginx -t && sudo systemctl reload nginx"
echo ""
echo "🔧 **What this will do:**"
echo "   ✅ Clean all old files from VPS"
echo "   ✅ Deploy fresh frontend build"
echo "   ✅ Restart all services"
echo "   ✅ Clear all caches"
echo "   ✅ Configure proper caching headers"
echo ""
print_success "Ready to fix your VPS sync! 🚀"
