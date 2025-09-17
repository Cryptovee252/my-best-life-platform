#!/bin/bash

# HelpMyBestLife Platform v1.2 - VPS Debug Script
# This script helps diagnose why the VPS version looks different from local

set -e

echo "🔍 HelpMyBestLife Platform v1.2 - VPS Debug"
echo "=========================================="

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
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

print_status "Checking VPS deployment status..."

echo ""
print_status "1. Checking PM2 processes..."
pm2 status

echo ""
print_status "2. Checking Nginx status..."
systemctl status nginx --no-pager -l

echo ""
print_status "3. Checking Nginx configuration..."
nginx -t

echo ""
print_status "4. Checking if frontend files exist..."
ls -la /root/my-best-life-platform/frontend/dist/

echo ""
print_status "5. Checking Nginx site configuration..."
cat /etc/nginx/sites-available/mybestlifeapp.com

echo ""
print_status "6. Checking backend logs..."
pm2 logs mybestlife-backend --lines 20

echo ""
print_status "7. Testing backend API..."
curl -s http://localhost:3001/api/health || echo "Backend API not responding"

echo ""
print_status "8. Testing frontend files..."
curl -s -I http://localhost/ | head -5

echo ""
print_status "9. Checking if correct frontend is built..."
if [ -f "/root/my-best-life-platform/frontend/dist/index.html" ]; then
    echo "Frontend index.html exists"
    head -20 /root/my-best-life-platform/frontend/dist/index.html
else
    echo "Frontend index.html does NOT exist!"
fi

echo ""
print_status "10. Checking frontend package.json..."
cat /root/my-best-life-platform/frontend/package.json | grep -A 5 -B 5 "scripts"

echo ""
print_status "11. Checking if frontend was built correctly..."
ls -la /root/my-best-life-platform/frontend/dist/ | head -10

echo ""
print_success "Debug information collected!"
echo ""
print_warning "If the frontend looks different, we need to:"
echo "1. Rebuild the frontend properly"
echo "2. Check Nginx configuration"
echo "3. Ensure the correct files are being served"
