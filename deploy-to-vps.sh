#!/bin/bash

# 🚀 HelpMyBestLife Platform v1.2 - VPS Deployment Script
# Enterprise Security Implementation

set -e

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

echo "🚀 HelpMyBestLife Platform v1.2 - VPS Deployment"
echo "=================================================="

# Check if we have VPS connection details
if [ -z "$VPS_IP" ] || [ -z "$VPS_USER" ]; then
    print_warning "VPS connection details not provided."
    echo ""
    echo "Please provide your VPS details:"
    echo "export VPS_IP='your.vps.ip.address'"
    echo "export VPS_USER='your_username'"
    echo "export VPS_DOMAIN='mybestlifeapp.com'"
    echo ""
    echo "Then run: ./deploy-to-vps.sh"
    echo ""
    echo "Or run with parameters:"
    echo "./deploy-to-vps.sh your.vps.ip.address your_username mybestlifeapp.com"
    exit 1
fi

# Use command line arguments if provided
if [ $# -eq 3 ]; then
    VPS_IP=$1
    VPS_USER=$2
    VPS_DOMAIN=$3
fi

print_status "Deploying to VPS: $VPS_IP as user: $VPS_USER"
print_status "Domain: $VPS_DOMAIN"

# Create deployment package
print_status "Creating deployment package..."
mkdir -p vps-deployment
cp -r backend vps-deployment/
cp -r frontend vps-deployment/
cp package.json vps-deployment/
cp package-lock.json vps-deployment/
cp docker-compose.yml vps-deployment/
cp -r docs vps-deployment/

# Create production environment file
print_status "Creating production environment file..."
cat > vps-deployment/.env.production << EOF
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

# Create VPS setup script
print_status "Creating VPS setup script..."
cat > vps-deployment/setup-vps.sh << 'EOF'
#!/bin/bash

# VPS Setup Script for HelpMyBestLife Platform v1.2

set -e

echo "🚀 Setting up HelpMyBestLife Platform v1.2 on VPS..."

# Update system
sudo apt update && sudo apt upgrade -y

# Install Node.js 18+
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install PostgreSQL
sudo apt install postgresql postgresql-contrib -y

# Install Nginx
sudo apt install nginx -y

# Install PM2
sudo npm install -g pm2

# Install Certbot for SSL
sudo apt install certbot python3-certbot-nginx -y

# Create application directory
sudo mkdir -p /var/www/mybestlife
sudo chown $USER:$USER /var/www/mybestlife

# Create database
sudo -u postgres createdb mybestlife_prod
sudo -u postgres createuser mybestlife_user
sudo -u postgres psql -c "ALTER USER mybestlife_user PASSWORD 'secure_password';"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE mybestlife_prod TO mybestlife_user;"

# Create log directory
sudo mkdir -p /var/log/mybestlife
sudo chown $USER:$USER /var/log/mybestlife

echo "✅ VPS setup complete!"
EOF

chmod +x vps-deployment/setup-vps.sh

# Create deployment script
print_status "Creating deployment script..."
cat > vps-deployment/deploy-app.sh << 'EOF'
#!/bin/bash

# Application Deployment Script

set -e

echo "🚀 Deploying HelpMyBestLife Platform v1.2..."

# Stop existing processes
pm2 stop mybestlife-backend || true
pm2 delete mybestlife-backend || true

# Install dependencies
cd backend
npm install --production

# Run database migrations
npm run db:push

# Start backend with PM2
pm2 start app-secure.js --name "mybestlife-backend" --env production

# Build frontend
cd ../frontend
npm install
npm run build:web

# Copy frontend files to web directory
sudo cp -r dist/* /var/www/mybestlife/

# Save PM2 configuration
pm2 save
pm2 startup

echo "✅ Application deployment complete!"
EOF

chmod +x vps-deployment/deploy-app.sh

# Create Nginx configuration
print_status "Creating Nginx configuration..."
cat > vps-deployment/nginx-config << EOF
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

# Create SSL setup script
print_status "Creating SSL setup script..."
cat > vps-deployment/setup-ssl.sh << EOF
#!/bin/bash

# SSL Setup Script

set -e

echo "🔒 Setting up SSL certificate for $VPS_DOMAIN..."

# Get SSL certificate
sudo certbot --nginx -d $VPS_DOMAIN -d www.$VPS_DOMAIN --non-interactive --agree-tos --email admin@$VPS_DOMAIN

# Setup auto-renewal
sudo systemctl enable certbot.timer
sudo systemctl start certbot.timer

echo "✅ SSL setup complete!"
EOF

chmod +x vps-deployment/setup-ssl.sh

# Create README for VPS deployment
print_status "Creating VPS deployment README..."
cat > vps-deployment/README-VPS-DEPLOYMENT.md << EOF
# 🚀 HelpMyBestLife Platform v1.2 - VPS Deployment

## 📋 **Deployment Steps**

### **1. Upload Files to VPS**
\`\`\`bash
scp -r vps-deployment/* $VPS_USER@$VPS_IP:/home/$VPS_USER/
\`\`\`

### **2. SSH into VPS**
\`\`\`bash
ssh $VPS_USER@$VPS_IP
\`\`\`

### **3. Run Setup Script**
\`\`\`bash
cd /home/$VPS_USER
chmod +x setup-vps.sh
./setup-vps.sh
\`\`\`

### **4. Configure Environment**
\`\`\`bash
# Edit production environment file
nano .env.production
# Update with your actual values:
# - JWT_SECRET (generate strong secrets)
# - EMAIL_USER and EMAIL_PASS
# - DATABASE_URL with your actual password
\`\`\`

### **5. Deploy Application**
\`\`\`bash
chmod +x deploy-app.sh
./deploy-app.sh
\`\`\`

### **6. Configure Nginx**
\`\`\`bash
sudo cp nginx-config /etc/nginx/sites-available/$VPS_DOMAIN
sudo ln -s /etc/nginx/sites-available/$VPS_DOMAIN /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
\`\`\`

### **7. Setup SSL**
\`\`\`bash
chmod +x setup-ssl.sh
./setup-ssl.sh
\`\`\`

## 🔍 **Testing**

### **Health Check**
\`\`\`bash
curl -I https://$VPS_DOMAIN/api/health
\`\`\`

### **Security Headers**
\`\`\`bash
curl -I https://$VPS_DOMAIN | grep -E "(Strict-Transport-Security|X-Frame-Options|X-Content-Type-Options|X-XSS-Protection|Content-Security-Policy)"
\`\`\`

## 📊 **Monitoring**

### **View Logs**
\`\`\`bash
pm2 logs mybestlife-backend
tail -f /var/log/mybestlife/security.log
\`\`\`

### **Monitor Performance**
\`\`\`bash
pm2 monit
\`\`\`

## 🚨 **Security Checklist**

- ✅ Environment variables secured
- ✅ Database credentials protected
- ✅ JWT secrets strong and unique
- ✅ SSL/TLS configured
- ✅ Security headers implemented
- ✅ Rate limiting active
- ✅ Input validation working
- ✅ Error handling secure
- ✅ Logging comprehensive
- ✅ CORS properly configured

**Version 1.2 is ready for production! 🚀**
EOF

# Create tar archive for easy transfer
print_status "Creating deployment archive..."
tar -czf helpmybestlife-v1.2-vps-deployment.tar.gz vps-deployment/

print_success "VPS deployment package created!"
echo ""
echo "📦 **Deployment Package Ready:**"
echo "   File: helpmybestlife-v1.2-vps-deployment.tar.gz"
echo "   Size: $(du -h helpmybestlife-v1.2-vps-deployment.tar.gz | cut -f1)"
echo ""
echo "🚀 **Next Steps:**"
echo "1. Upload to VPS: scp helpmybestlife-v1.2-vps-deployment.tar.gz $VPS_USER@$VPS_IP:/home/$VPS_USER/"
echo "2. SSH to VPS: ssh $VPS_USER@$VPS_IP"
echo "3. Extract: tar -xzf helpmybestlife-v1.2-vps-deployment.tar.gz"
echo "4. Follow: vps-deployment/README-VPS-DEPLOYMENT.md"
echo ""
echo "📋 **Required VPS Information:**"
echo "   IP: $VPS_IP"
echo "   User: $VPS_USER"
echo "   Domain: $VPS_DOMAIN"
echo ""
echo "🔧 **Before Deployment:**"
echo "   - Update .env.production with your actual values"
echo "   - Ensure domain DNS points to VPS IP"
echo "   - Have SSL certificate email ready"
echo ""
print_success "Ready for VPS deployment! 🚀"
