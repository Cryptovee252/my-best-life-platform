#!/bin/bash

# HelpMyBestLife Platform v1.2 - Fix SSL Redirect
# This script fixes the 301 redirect issue and ensures HTTPS works properly

set -e

echo "🔒 HelpMyBestLife Platform v1.2 - Fix SSL Redirect"
echo "================================================="

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

print_status "Checking current SSL certificate status..."
certbot certificates

print_status "Checking if HTTPS site is configured..."
if [ -f "/etc/nginx/sites-available/mybestlifeapp.com" ]; then
    print_success "Found Nginx site configuration"
    grep -A 5 -B 5 "listen 443" /etc/nginx/sites-available/mybestlifeapp.com || echo "No HTTPS configuration found"
else
    print_error "Nginx site configuration not found!"
    exit 1
fi

print_status "Setting up SSL certificate with Certbot..."
certbot --nginx -d mybestlifeapp.com -d www.mybestlifeapp.com --non-interactive --agree-tos --email admin@mybestlifeapp.com

print_status "Testing Nginx configuration..."
nginx -t

print_status "Restarting Nginx..."
systemctl restart nginx

print_status "Testing HTTP redirect..."
curl -I http://mybestlifeapp.com

print_status "Testing HTTPS..."
curl -I https://mybestlifeapp.com

print_status "Testing what's actually being served on HTTPS..."
curl -s https://mybestlifeapp.com | head -10

print_success "🎉 SSL configuration completed!"
print_success "Your site should now work properly at: https://mybestlifeapp.com"
