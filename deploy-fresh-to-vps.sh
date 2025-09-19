#!/bin/bash

# 🚀 One-Command Fresh VPS Deployment
# This script will deploy your current local files to VPS

set -e

# VPS Configuration
VPS_IP="147.93.47.43"
VPS_USER="root"
VPS_DOMAIN="mybestlifeapp.com"

echo "🚀 Deploying fresh files to VPS..."
echo "VPS: $VPS_IP | Domain: $VPS_DOMAIN"
echo ""

# Run the fix script
./fix-vps-sync.sh

echo ""
echo "📤 Uploading to VPS..."
scp vps-clean-deployment.tar.gz $VPS_USER@$VPS_IP:/root/

echo ""
echo "🔧 Deploying on VPS..."
ssh $VPS_USER@$VPS_IP << 'EOF'
echo "Extracting deployment package..."
tar -xzf vps-clean-deployment.tar.gz
cd vps-clean-deployment

echo "Running deployment script..."
./fix-vps-deployment.sh

echo "Updating nginx configuration..."
sudo cp nginx-config /etc/nginx/sites-available/mybestlifeapp.com
sudo nginx -t && sudo systemctl reload nginx

echo "✅ Deployment complete!"
echo "🌐 Your site should now show the latest version!"
EOF

echo ""
echo "🎉 Fresh deployment complete!"
echo "Visit: https://$VPS_DOMAIN"
echo ""
echo "🔍 To verify deployment:"
echo "curl -I https://$VPS_DOMAIN"
echo "curl -I https://$VPS_DOMAIN/api/health"
