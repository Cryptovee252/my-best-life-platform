#!/bin/bash

# HelpMyBestLife Platform v1.2 - Check CDN/Proxy
# This script checks if there's a CDN or proxy caching your site

set -e

echo "🌐 HelpMyBestLife Platform v1.2 - Check CDN/Proxy"
echo "==============================================="

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

print_status "1. Checking DNS resolution..."
echo "DNS records for mybestlifeapp.com:"
dig mybestlifeapp.com +short

echo ""
print_status "2. Checking if domain points to your VPS..."
VPS_IP=$(curl -s ifconfig.me)
echo "Your VPS IP: $VPS_IP"
echo "Domain resolves to:"
dig mybestlifeapp.com +short

echo ""
print_status "3. Checking for CDN headers..."
echo "Headers from https://mybestlifeapp.com:"
curl -I https://mybestlifeapp.com 2>/dev/null | grep -E "(cf-|cloudflare|cdn|proxy|cache|server)" || echo "No CDN headers found"

echo ""
print_status "4. Checking for Cloudflare specifically..."
if curl -I https://mybestlifeapp.com 2>/dev/null | grep -q "cloudflare"; then
    print_warning "⚠️  CLOUDFLARE DETECTED! This is likely the issue."
    echo "Cloudflare is caching your old site. You need to:"
    echo "1. Log into your Cloudflare dashboard"
    echo "2. Go to Caching > Configuration"
    echo "3. Click 'Purge Everything'"
    echo "4. Or set development mode to bypass cache"
else
    print_success "✅ No Cloudflare detected"
fi

echo ""
print_status "5. Checking for other CDN services..."
curl -I https://mybestlifeapp.com 2>/dev/null | grep -E "(amazonaws|fastly|keycdn|maxcdn|bunnycdn)" || echo "No other CDN services detected"

echo ""
print_status "6. Testing direct VPS access..."
echo "Testing direct IP access:"
curl -I http://$VPS_IP 2>/dev/null | head -5

echo ""
print_status "7. Checking if there are multiple domains pointing to your VPS..."
echo "Checking what domains resolve to your VPS IP:"
dig -x $VPS_IP +short

echo ""
print_status "8. Checking Hostinger DNS settings..."
echo "If you're using Hostinger, check:"
echo "1. DNS Management in your Hostinger control panel"
echo "2. Make sure mybestlifeapp.com points to $VPS_IP"
echo "3. Check if there's any CDN or proxy enabled"
echo "4. Look for 'Cloudflare' or 'CDN' options in Hostinger"

print_success "CDN/Proxy check completed!"

echo ""
print_warning "🔍 MOST LIKELY ISSUES:"
echo "1. Cloudflare CDN caching (most common)"
echo "2. Hostinger CDN/proxy enabled"
echo "3. Browser cache (try incognito mode)"
echo "4. DNS propagation delay"

echo ""
print_status "SOLUTIONS:"
echo "1. If Cloudflare: Purge cache in Cloudflare dashboard"
echo "2. If Hostinger CDN: Disable CDN in Hostinger control panel"
echo "3. If browser cache: Clear cache or use incognito mode"
echo "4. If DNS: Wait 5-10 minutes for propagation"
