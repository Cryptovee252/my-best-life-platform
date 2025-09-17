#!/bin/bash

# HelpMyBestLife Platform v1.2 - Find Correct Folder
# This script identifies which folder is being served and fixes the routing

set -e

echo "🔍 HelpMyBestLife Platform v1.2 - Find Correct Folder"
echo "===================================================="

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

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    print_error "Please run as root (use sudo)"
    exit 1
fi

print_status "Searching for all HelpMyBestLife folders..."

echo ""
print_status "1. Checking root directory..."
ls -la /root/ | grep -i "mybestlife\|helpmybestlife" || echo "No folders found in /root/"

echo ""
print_status "2. Checking for folders with 'mybestlife' in name..."
find /root -type d -name "*mybestlife*" -o -name "*helpmybestlife*" 2>/dev/null || echo "No folders found"

echo ""
print_status "3. Checking current Nginx configuration..."
cat /etc/nginx/sites-available/mybestlifeapp.com | grep "root " || echo "No root directive found"

echo ""
print_status "4. Checking what's actually being served..."
curl -s http://localhost/ | head -20 || echo "Cannot connect to localhost"

echo ""
print_status "5. Checking PM2 processes..."
pm2 status

echo ""
print_status "6. Checking if there are multiple frontend builds..."
find /root -name "index.html" -path "*/frontend/dist/*" 2>/dev/null || echo "No frontend builds found"

echo ""
print_status "7. Checking for old vs new frontend files..."
if [ -f "/root/my-best-life-platform/frontend/dist/index.html" ]; then
    echo "Found new frontend build at: /root/my-best-life-platform/frontend/dist/"
    head -10 /root/my-best-life-platform/frontend/dist/index.html
else
    echo "New frontend build not found at expected location"
fi

echo ""
print_status "8. Checking for other possible locations..."
if [ -f "/root/mybestlifeplatform/frontend/dist/index.html" ]; then
    echo "Found frontend build at: /root/mybestlifeplatform/frontend/dist/"
    head -10 /root/mybestlifeplatform/frontend/dist/index.html
fi

if [ -f "/root/backend/frontend/dist/index.html" ]; then
    echo "Found frontend build at: /root/backend/frontend/dist/"
    head -10 /root/backend/frontend/dist/index.html
fi

echo ""
print_success "Folder analysis completed!"
echo ""
print_warning "Next steps:"
echo "1. Identify which folder has the OLD version"
echo "2. Update Nginx to point to the NEW version"
echo "3. Restart services"
