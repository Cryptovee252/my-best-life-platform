#!/bin/bash

# 🔍 Check Registration API Script
# Diagnose why registration form isn't working

set -e

# VPS Configuration
VPS_IP="147.93.47.43"
VPS_USER="root"

echo "🔍 Checking Registration API"
echo "============================"
echo "VPS: $VPS_IP"
echo ""

echo "📤 Running API check on VPS..."
ssh $VPS_USER@$VPS_IP << 'EOF'
echo "🔍 Registration API Check"
echo "========================="
echo ""

# Check backend status
echo "📊 Backend Status:"
pm2 list
echo ""

# Check if backend is responding
echo "🌐 Backend API Tests:"
echo "Health check:"
curl -s http://localhost:3000/api/health || echo "Health endpoint failed"
echo ""

echo "Auth endpoints test:"
curl -s -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test123","name":"Test User"}' || echo "Register endpoint failed"
echo ""

# Check backend logs for errors
echo "📋 Recent Backend Logs:"
pm2 logs mybestlife-backend --lines 20
echo ""

# Check nginx proxy configuration
echo "🔧 Nginx Proxy Check:"
nginx -t
echo ""

# Test nginx proxy to backend
echo "🌐 Nginx Proxy Test:"
curl -s http://localhost/api/health || echo "Nginx proxy failed"
echo ""

# Check if CORS is configured
echo "🔍 CORS Configuration:"
curl -s -I http://localhost:3000/api/health | grep -i "access-control" || echo "No CORS headers found"
echo ""

# Check frontend files
echo "📁 Frontend Files Check:"
ls -la /var/www/mybestlife/ | head -10
echo ""

# Check if frontend has proper API configuration
echo "🔍 Frontend API Configuration:"
grep -r "api" /var/www/mybestlife/ | head -5 || echo "No API references found"
echo ""

echo "✅ Registration API check complete!"
EOF

echo ""
echo "🔍 Registration API check complete!"
echo ""
echo "📋 Check the output above for:"
echo "1. Is the backend running?"
echo "2. Are API endpoints responding?"
echo "3. Is nginx proxying correctly?"
echo "4. Are there CORS issues?"
echo "5. Are there errors in backend logs?"
echo ""
echo "🚀 If issues found, we'll fix them next!"
