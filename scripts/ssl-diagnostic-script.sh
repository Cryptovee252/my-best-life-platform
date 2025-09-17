#!/bin/bash

# SSL Diagnostic Script for My Best Life Platform
# This script will identify SSL issues and provide solutions

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print functions
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

DOMAIN="mybestlifeapp.com"

echo "🔍 SSL DIAGNOSTIC REPORT"
echo "========================"
echo "Domain: $DOMAIN"
echo "Date: $(date)"
echo ""

# 1. Check if running on VPS
print_status "1. Checking server environment..."
if [ -f "/etc/os-release" ]; then
    OS_INFO=$(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)
    print_success "OS: $OS_INFO"
else
    print_warning "Not running on VPS - this script is designed for VPS deployment"
fi

# 2. Check Nginx status
print_status "2. Checking Nginx status..."
if systemctl is-active --quiet nginx; then
    print_success "Nginx: Running"
else
    print_error "Nginx: Not running"
    echo "Fix: sudo systemctl start nginx"
fi

# 3. Check Nginx configuration
print_status "3. Checking Nginx configuration..."
if nginx -t 2>/dev/null; then
    print_success "Nginx config: Valid"
else
    print_error "Nginx config: Invalid"
    echo "Fix: Check nginx configuration files"
fi

# 4. Check SSL certificate files
print_status "4. Checking SSL certificate files..."
if [ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]; then
    print_success "SSL certificate: Exists"
    
    # Check certificate expiry
    EXPIRY_DATE=$(openssl x509 -enddate -noout -in /etc/letsencrypt/live/$DOMAIN/fullchain.pem | cut -d= -f2)
    EXPIRY_TIMESTAMP=$(date -d "$EXPIRY_DATE" +%s)
    CURRENT_TIMESTAMP=$(date +%s)
    DAYS_UNTIL_EXPIRY=$(( (EXPIRY_TIMESTAMP - CURRENT_TIMESTAMP) / 86400 ))
    
    if [ $DAYS_UNTIL_EXPIRY -gt 30 ]; then
        print_success "Certificate expiry: $DAYS_UNTIL_EXPIRY days (Valid)"
    else
        print_warning "Certificate expiry: $DAYS_UNTIL_EXPIRY days (Expiring soon)"
    fi
else
    print_error "SSL certificate: Missing"
    echo "Fix: Run certbot to obtain certificate"
fi

if [ -f "/etc/letsencrypt/live/$DOMAIN/privkey.pem" ]; then
    print_success "SSL private key: Exists"
else
    print_error "SSL private key: Missing"
fi

# 5. Check Certbot status
print_status "5. Checking Certbot status..."
if command -v certbot &> /dev/null; then
    print_success "Certbot: Installed ($(certbot --version | head -1))"
    
    # Check certificate status
    if certbot certificates 2>/dev/null | grep -q "$DOMAIN"; then
        print_success "Certificate registered with Certbot"
    else
        print_warning "Certificate not registered with Certbot"
    fi
else
    print_error "Certbot: Not installed"
    echo "Fix: sudo apt install certbot python3-certbot-nginx"
fi

# 6. Check firewall
print_status "6. Checking firewall..."
if command -v ufw &> /dev/null; then
    if ufw status | grep -q "443/tcp"; then
        print_success "Firewall: Port 443 allowed"
    else
        print_warning "Firewall: Port 443 not explicitly allowed"
        echo "Fix: sudo ufw allow 443"
    fi
    
    if ufw status | grep -q "80/tcp"; then
        print_success "Firewall: Port 80 allowed"
    else
        print_warning "Firewall: Port 80 not explicitly allowed"
        echo "Fix: sudo ufw allow 80"
    fi
else
    print_warning "UFW firewall: Not installed"
fi

# 7. Test HTTP connectivity
print_status "7. Testing HTTP connectivity..."
if curl -f http://$DOMAIN > /dev/null 2>&1; then
    print_success "HTTP: Website responding"
else
    print_error "HTTP: Website not responding"
fi

# 8. Test HTTPS connectivity
print_status "8. Testing HTTPS connectivity..."
if curl -f https://$DOMAIN > /dev/null 2>&1; then
    print_success "HTTPS: Website responding"
else
    print_error "HTTPS: Website not responding"
    
    # Get detailed error
    echo "Detailed HTTPS error:"
    curl -v https://$DOMAIN 2>&1 | head -20
fi

# 9. Check SSL handshake
print_status "9. Testing SSL handshake..."
if echo | openssl s_client -servername $DOMAIN -connect $DOMAIN:443 2>/dev/null | grep -q "Verify return code: 0"; then
    print_success "SSL handshake: Successful"
else
    print_error "SSL handshake: Failed"
    
    # Get SSL error details
    echo "SSL error details:"
    echo | openssl s_client -servername $DOMAIN -connect $DOMAIN:443 2>&1 | grep -E "(verify|error|certificate)"
fi

# 10. Check Nginx SSL configuration
print_status "10. Checking Nginx SSL configuration..."
if [ -f "/etc/nginx/sites-available/mybestlife" ]; then
    if grep -q "ssl_certificate" /etc/nginx/sites-available/mybestlife; then
        print_success "Nginx SSL config: SSL directives found"
    else
        print_error "Nginx SSL config: No SSL directives found"
    fi
    
    if grep -q "listen 443" /etc/nginx/sites-available/mybestlife; then
        print_success "Nginx SSL config: Port 443 configured"
    else
        print_error "Nginx SSL config: Port 443 not configured"
    fi
else
    print_error "Nginx site config: File not found"
fi

# 11. Check backend application
print_status "11. Checking backend application..."
if systemctl is-active --quiet mybestlife-secure || pgrep -f "mybestlife" > /dev/null; then
    print_success "Backend application: Running"
else
    print_warning "Backend application: Not running"
    echo "Fix: Start your Node.js application"
fi

# 12. Check DNS
print_status "12. Checking DNS resolution..."
if nslookup $DOMAIN > /dev/null 2>&1; then
    print_success "DNS: Domain resolves"
    IP=$(nslookup $DOMAIN | grep "Address:" | tail -1 | awk '{print $2}')
    print_status "Domain resolves to: $IP"
else
    print_error "DNS: Domain does not resolve"
fi

echo ""
echo "🔧 COMMON SSL FIXES"
echo "==================="
echo ""
echo "If HTTPS is not working, try these fixes in order:"
echo ""
echo "1. 🔄 Restart Nginx:"
echo "   sudo systemctl restart nginx"
echo ""
echo "2. 🔒 Renew SSL certificate:"
echo "   sudo certbot renew --force-renewal"
echo "   sudo systemctl reload nginx"
echo ""
echo "3. 🛠️  Reinstall SSL certificate:"
echo "   sudo certbot delete --cert-name $DOMAIN"
echo "   sudo certbot --nginx -d $DOMAIN -d www.$DOMAIN"
echo ""
echo "4. 🔥 Reset Nginx configuration:"
echo "   sudo rm /etc/nginx/sites-enabled/mybestlife"
echo "   sudo ln -s /etc/nginx/sites-available/mybestlife /etc/nginx/sites-enabled/"
echo "   sudo nginx -t && sudo systemctl reload nginx"
echo ""
echo "5. 🌐 Check firewall:"
echo "   sudo ufw allow 443"
echo "   sudo ufw allow 80"
echo "   sudo ufw reload"
echo ""
echo "6. 📋 Verify SSL certificate:"
echo "   sudo certbot certificates"
echo "   openssl x509 -in /etc/letsencrypt/live/$DOMAIN/fullchain.pem -text -noout"
echo ""

print_status "Diagnostic complete! Check the results above and apply the appropriate fixes."
