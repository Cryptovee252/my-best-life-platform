#!/bin/bash

# 🚀 Quick VPS Deployment Script for HelpMyBestLife Platform v1.2
# Run this script on your VPS after uploading the files

set -e

echo "🚀 HelpMyBestLife Platform v1.2 - Quick VPS Deployment"
echo "======================================================"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

# Check if we're on the VPS
if [ ! -f "helpmybestlife-v1.2-vps-deployment.tar.gz" ]; then
    print_error "Deployment package not found!"
    echo "Please upload helpmybestlife-v1.2-vps-deployment.tar.gz to your VPS first."
    echo "Run: scp helpmybestlife-v1.2-vps-deployment.tar.gz root@147.93.47.43:/root/"
    exit 1
fi

print_status "Starting deployment..."

# Extract package
print_status "Extracting deployment package..."
tar -xzf helpmybestlife-v1.2-vps-deployment.tar.gz
cd vps-deployment

# Make scripts executable
chmod +x *.sh

# Run VPS setup
print_status "Setting up VPS environment..."
./setup-vps.sh

# Deploy application
print_status "Deploying application..."
./deploy-app.sh

# Configure Nginx
print_status "Configuring Nginx..."
cp nginx-config /etc/nginx/sites-available/mybestlifeapp.com
ln -sf /etc/nginx/sites-available/mybestlifeapp.com /etc/nginx/sites-enabled/
nginx -t
systemctl reload nginx

# Setup SSL
print_status "Setting up SSL certificate..."
./setup-ssl.sh

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
