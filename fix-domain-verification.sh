#!/bin/bash

# Fix Domain Verification for SSL Certificate
# This script addresses the domain verification issue

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

echo "🔍 DOMAIN VERIFICATION FIX"
echo "========================="
echo "Domain: $DOMAIN"
echo "Date: $(date)"
echo ""

# Step 1: Check DNS resolution
print_status "1. Checking DNS resolution..."
if nslookup $DOMAIN > /dev/null 2>&1; then
    IP=$(nslookup $DOMAIN | grep "Address:" | tail -1 | awk '{print $2}')
    print_success "Domain resolves to: $IP"
else
    print_error "Domain does not resolve"
    echo "Fix: Update your DNS settings to point to this server"
    exit 1
fi

# Step 2: Check server's public IP
print_status "2. Checking server's public IP..."
SERVER_IP=$(curl -s ifconfig.me)
print_status "Server's public IP: $SERVER_IP"

if [ "$IP" = "$SERVER_IP" ]; then
    print_success "DNS points to this server"
else
    print_error "DNS does not point to this server"
    echo "Expected: $SERVER_IP"
    echo "Actual: $IP"
    echo "Fix: Update DNS A record to point to $SERVER_IP"
fi

# Step 3: Test HTTP connectivity
print_status "3. Testing HTTP connectivity..."
if curl -f http://$DOMAIN > /dev/null 2>&1; then
    print_success "HTTP: Website responding"
else
    print_error "HTTP: Website not responding"
fi

# Step 4: Check if Let's Encrypt challenge directory is accessible
print_status "4. Testing Let's Encrypt challenge directory..."
mkdir -p /var/www/html/.well-known/acme-challenge
echo "test" > /var/www/html/.well-known/acme-challenge/test.txt

if curl -f http://$DOMAIN/.well-known/acme-challenge/test.txt > /dev/null 2>&1; then
    print_success "Let's Encrypt challenge directory: Accessible"
    rm /var/www/html/.well-known/acme-challenge/test.txt
else
    print_error "Let's Encrypt challenge directory: Not accessible"
    echo "This is likely the cause of the SSL certificate failure"
fi

# Step 5: Check Nginx configuration
print_status "5. Checking Nginx configuration..."
if grep -q "\.well-known/acme-challenge" /etc/nginx/sites-available/mybestlife; then
    print_success "Nginx: ACME challenge location configured"
else
    print_error "Nginx: ACME challenge location missing"
fi

# Step 6: Check if domain is accessible from internet
print_status "6. Testing external accessibility..."
EXTERNAL_TEST=$(curl -s -o /dev/null -w "%{http_code}" http://$DOMAIN)
if [ "$EXTERNAL_TEST" = "200" ]; then
    print_success "External access: Working (HTTP 200)"
elif [ "$EXTERNAL_TEST" = "301" ] || [ "$EXTERNAL_TEST" = "302" ]; then
    print_success "External access: Working (HTTP $EXTERNAL_TEST - redirect)"
else
    print_error "External access: Not working (HTTP $EXTERNAL_TEST)"
fi

echo ""
echo "🔧 SOLUTIONS"
echo "============"
echo ""

if [ "$IP" != "$SERVER_IP" ]; then
    echo "1. 🌐 DNS ISSUE - Update DNS Records:"
    echo "   - Go to your domain registrar (GoDaddy, Namecheap, etc.)"
    echo "   - Update A record for $DOMAIN to point to $SERVER_IP"
    echo "   - Update A record for www.$DOMAIN to point to $SERVER_IP"
    echo "   - Wait 5-10 minutes for DNS propagation"
    echo ""
fi

echo "2. 🔄 Alternative SSL Certificate Methods:"
echo ""
echo "   Option A: Use standalone mode (temporarily stop Nginx):"
echo "   systemctl stop nginx"
echo "   certbot certonly --standalone -d $DOMAIN -d www.$DOMAIN"
echo "   systemctl start nginx"
echo ""
echo "   Option B: Use webroot mode:"
echo "   certbot certonly --webroot -w /var/www/html -d $DOMAIN -d www.$DOMAIN"
echo ""
echo "   Option C: Use DNS challenge (if you have API access):"
echo "   certbot certonly --manual --preferred-challenges dns -d $DOMAIN -d www.$DOMAIN"
echo ""

echo "3. 🛠️  Manual Certificate Configuration:"
echo "   If you get a certificate, manually configure Nginx:"
echo "   - Edit /etc/nginx/sites-available/mybestlife"
echo "   - Add SSL directives pointing to certificate files"
echo "   - Reload Nginx: systemctl reload nginx"
echo ""

echo "4. 🔍 Debug Commands:"
echo "   - Check DNS: nslookup $DOMAIN"
echo "   - Test HTTP: curl -I http://$DOMAIN"
echo "   - Check Nginx: nginx -t"
echo "   - View logs: tail -f /var/log/nginx/error.log"
echo ""

print_status "Run the appropriate solution based on the diagnosis above."
