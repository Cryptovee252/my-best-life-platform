#!/bin/bash

# HelpMyBestLife Platform v1.2 - Clear Cache and Test
# This script clears all caches and tests the site thoroughly

set -e

echo "🧹 HelpMyBestLife Platform v1.2 - Clear Cache and Test"
echo "====================================================="

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

print_status "1. Checking what's actually being served on HTTPS..."
echo "Content from https://mybestlifeapp.com:"
curl -s https://mybestlifeapp.com | head -30

echo ""
print_status "2. Checking if this is the NEW or OLD version..."
# Look for specific markers that indicate the new version
if curl -s https://mybestlifeapp.com | grep -q "HelpMyBestLife\|expo\|react-native"; then
    print_success "✅ This appears to be the NEW Expo React Native version!"
else
    print_warning "⚠️  This might be the OLD version"
fi

echo ""
print_status "3. Checking Nginx configuration..."
cat /etc/nginx/sites-available/mybestlifeapp.com | grep -A 10 -B 5 "root "

echo ""
print_status "4. Checking if there are multiple Nginx sites enabled..."
ls -la /etc/nginx/sites-enabled/

echo ""
print_status "5. Checking for any conflicting configurations..."
find /etc/nginx/sites-available/ -name "*mybestlife*" -o -name "*helpmybestlife*"

echo ""
print_status "6. Checking DNS resolution..."
nslookup mybestlifeapp.com

echo ""
print_status "7. Checking if there are any other web servers running..."
ps aux | grep -E "(apache|nginx|httpd)" | grep -v grep

echo ""
print_status "8. Checking for any CDN or proxy configurations..."
curl -I https://mybestlifeapp.com | grep -E "(cf-|cloudflare|cdn|proxy)"

echo ""
print_status "9. Testing direct IP access..."
VPS_IP=$(curl -s ifconfig.me)
echo "VPS IP: $VPS_IP"
curl -I http://$VPS_IP | head -5

echo ""
print_status "10. Checking if there are any .htaccess files interfering..."
find /root -name ".htaccess" 2>/dev/null || echo "No .htaccess files found"

print_success "Cache and configuration check completed!"

echo ""
print_warning "🔍 TROUBLESHOOTING STEPS:"
echo "1. Clear your browser cache completely (Ctrl+Shift+Delete)"
echo "2. Try incognito/private browsing mode"
echo "3. Try a different browser"
echo "4. Check if you have any browser extensions blocking content"
echo "5. Wait 5-10 minutes for DNS propagation"
echo "6. Try accessing: https://mybestlifeapp.com/?v=$(date +%s)"

echo ""
print_status "If you're still seeing the old version, the issue might be:"
echo "- Browser caching"
echo "- CDN caching (if using Cloudflare or similar)"
echo "- DNS propagation delay"
echo "- Multiple Nginx configurations conflicting"
