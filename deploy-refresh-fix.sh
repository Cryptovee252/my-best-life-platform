#!/bin/bash

# 🚀 Deploy Refresh Logout Fix
# Upload and deploy the refresh logout fix to VPS

set -e

# VPS Configuration
VPS_IP="147.93.47.43"
VPS_USER="root"

echo "🚀 Deploying Refresh Logout Fix"
echo "==============================="
echo "VPS: $VPS_IP"
echo ""

# Upload the fix package
echo "📤 Uploading refresh fix package..."
scp vps-refresh-fix-deployment.tar.gz $VPS_USER@$VPS_IP:/root/

echo ""
echo "🔧 Deploying fix on VPS..."
ssh $VPS_USER@$VPS_IP << 'EOF'
echo "🔧 Deploying refresh logout fix..."

# Extract the package
tar -xzf vps-refresh-fix-deployment.tar.gz
cd vps-refresh-fix-deployment

# Run the deployment script
./deploy-refresh-fix.sh

echo ""
echo "✅ Refresh logout fix deployed successfully!"
echo ""
echo "🌐 Test by:"
echo "   1. Visit: https://mybestlifeapp.com"
echo "   2. Login to your account"
echo "   3. Refresh the page (F5 or Ctrl+R)"
echo "   4. You should stay logged in!"
EOF

echo ""
echo "🎉 Refresh logout fix deployment complete!"
echo ""
echo "✅ **What was deployed:**
   🔐 Authentication persistence script
   🔄 Token refresh endpoint
   💾 Enhanced localStorage handling
   🎨 UI state restoration
   ⏰ Periodic token refresh"
echo ""
echo "🌐 **Test the fix:**
   1. Visit: https://mybestlifeapp.com
   2. Login to your account
   3. Refresh the page (F5)
   4. You should stay logged in!"
echo ""
echo "🔧 **If still having issues:**
   - Check browser console for errors
   - Clear browser cache and try again
   - Check if localStorage is enabled"
