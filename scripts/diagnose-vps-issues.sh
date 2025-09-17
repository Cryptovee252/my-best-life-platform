#!/bin/bash

# 🔍 VPS DIAGNOSTIC SCRIPT
# This script will diagnose issues with your VPS and website

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

print_status "🔍 Starting VPS diagnostic..."

echo "=========================================="
echo "🔧 SYSTEM INFORMATION"
echo "=========================================="

# Check system info
echo "OS: $(lsb_release -d | cut -f2)"
echo "Kernel: $(uname -r)"
echo "Uptime: $(uptime -p)"
echo "Memory: $(free -h | grep '^Mem:' | awk '{print $3 "/" $2}')"
echo "Disk: $(df -h / | tail -1 | awk '{print $3 "/" $2 " (" $5 " used)"}')"

echo ""
echo "=========================================="
echo "🌐 NETWORK STATUS"
echo "=========================================="

# Check network connectivity
if ping -c 1 8.8.8.8 > /dev/null 2>&1; then
    print_success "Internet connectivity: OK"
else
    print_error "Internet connectivity: FAILED"
fi

# Check DNS resolution
if nslookup mybestlifeapp.com > /dev/null 2>&1; then
    print_success "DNS resolution for mybestlifeapp.com: OK"
    echo "IP: $(nslookup mybestlifeapp.com | grep 'Address:' | tail -1 | awk '{print $2}')"
else
    print_error "DNS resolution for mybestlifeapp.com: FAILED"
fi

echo ""
echo "=========================================="
echo "🔧 INSTALLED SOFTWARE"
echo "=========================================="

# Check Node.js
if command -v node &> /dev/null; then
    print_success "Node.js: $(node --version)"
else
    print_error "Node.js: NOT INSTALLED"
fi

# Check npm
if command -v npm &> /dev/null; then
    print_success "npm: $(npm --version)"
else
    print_error "npm: NOT INSTALLED"
fi

# Check PM2
if command -v pm2 &> /dev/null; then
    print_success "PM2: $(pm2 --version)"
else
    print_error "PM2: NOT INSTALLED"
fi

# Check Nginx
if command -v nginx &> /dev/null; then
    print_success "Nginx: $(nginx -v 2>&1)"
else
    print_error "Nginx: NOT INSTALLED"
fi

# Check PostgreSQL
if command -v psql &> /dev/null; then
    print_success "PostgreSQL: $(psql --version)"
else
    print_error "PostgreSQL: NOT INSTALLED"
fi

# Check Certbot
if command -v certbot &> /dev/null; then
    print_success "Certbot: $(certbot --version | head -1)"
else
    print_error "Certbot: NOT INSTALLED"
fi

echo ""
echo "=========================================="
echo "🚀 SERVICES STATUS"
echo "=========================================="

# Check Nginx status
if systemctl is-active --quiet nginx; then
    print_success "Nginx: Running"
else
    print_error "Nginx: Not running"
fi

# Check PostgreSQL status
if systemctl is-active --quiet postgresql; then
    print_success "PostgreSQL: Running"
else
    print_error "PostgreSQL: Not running"
fi

# Check PM2 processes
if command -v pm2 &> /dev/null; then
    echo ""
    echo "PM2 Processes:"
    pm2 status
else
    print_error "PM2: Not available"
fi

echo ""
echo "=========================================="
echo "📁 PROJECT FILES"
echo "=========================================="

# Check project directory
if [ -d "/var/www/mybestlife" ]; then
    print_success "Project directory exists: /var/www/mybestlife"
    
    # Check backend directory
    if [ -d "/var/www/mybestlife/backend" ]; then
        print_success "Backend directory exists"
        
        # Check package.json
        if [ -f "/var/www/mybestlife/backend/package.json" ]; then
            print_success "package.json exists"
        else
            print_error "package.json missing"
        fi
        
        # Check app-secure.js
        if [ -f "/var/www/mybestlife/backend/app-secure.js" ]; then
            print_success "app-secure.js exists"
        else
            print_error "app-secure.js missing"
        fi
        
        # Check .env file
        if [ -f "/var/www/mybestlife/backend/.env" ]; then
            print_success ".env file exists"
        else
            print_error ".env file missing (CRITICAL)"
        fi
        
        # Check node_modules
        if [ -d "/var/www/mybestlife/backend/node_modules" ]; then
            print_success "node_modules exists"
        else
            print_error "node_modules missing (run npm install)"
        fi
    else
        print_error "Backend directory missing"
    fi
else
    print_error "Project directory missing: /var/www/mybestlife"
fi

echo ""
echo "=========================================="
echo "🔒 SSL CERTIFICATES"
echo "=========================================="

# Check SSL certificates
if [ -d "/etc/letsencrypt/live/mybestlifeapp.com" ]; then
    print_success "SSL certificate directory exists"
    
    # Check certificate files
    if [ -f "/etc/letsencrypt/live/mybestlifeapp.com/fullchain.pem" ]; then
        print_success "SSL certificate file exists"
        
        # Check certificate expiry
        EXPIRY_DATE=$(openssl x509 -enddate -noout -in /etc/letsencrypt/live/mybestlifeapp.com/fullchain.pem | cut -d= -f2)
        EXPIRY_TIMESTAMP=$(date -d "$EXPIRY_DATE" +%s)
        CURRENT_TIMESTAMP=$(date +%s)
        DAYS_UNTIL_EXPIRY=$(( (EXPIRY_TIMESTAMP - CURRENT_TIMESTAMP) / 86400 ))
        
        if [ $DAYS_UNTIL_EXPIRY -gt 30 ]; then
            print_success "SSL certificate expires in $DAYS_UNTIL_EXPIRY days"
        elif [ $DAYS_UNTIL_EXPIRY -gt 0 ]; then
            print_warning "SSL certificate expires in $DAYS_UNTIL_EXPIRY days"
        else
            print_error "SSL certificate has expired!"
        fi
    else
        print_error "SSL certificate file missing"
    fi
else
    print_error "SSL certificate directory missing"
fi

echo ""
echo "=========================================="
echo "🌐 WEBSITE TESTS"
echo "=========================================="

# Test local application
if curl -f http://localhost:3000/api/health > /dev/null 2>&1; then
    print_success "Local application (port 3000): Responding"
else
    print_error "Local application (port 3000): Not responding"
fi

# Test HTTP website
if curl -f http://mybestlifeapp.com > /dev/null 2>&1; then
    print_success "HTTP website: Responding"
else
    print_error "HTTP website: Not responding"
fi

# Test HTTPS website
if curl -f https://mybestlifeapp.com > /dev/null 2>&1; then
    print_success "HTTPS website: Responding"
else
    print_error "HTTPS website: Not responding"
fi

# Test API endpoint
if curl -f https://mybestlifeapp.com/api/health > /dev/null 2>&1; then
    print_success "API endpoint: Responding"
else
    print_error "API endpoint: Not responding"
fi

echo ""
echo "=========================================="
echo "📊 NGINX CONFIGURATION"
echo "=========================================="

# Check Nginx configuration
if nginx -t > /dev/null 2>&1; then
    print_success "Nginx configuration: Valid"
else
    print_error "Nginx configuration: Invalid"
    echo "Error details:"
    nginx -t
fi

# Check if site is enabled
if [ -L "/etc/nginx/sites-enabled/mybestlife" ]; then
    print_success "Nginx site enabled: mybestlife"
else
    print_error "Nginx site not enabled"
fi

echo ""
echo "=========================================="
echo "🗄️ DATABASE STATUS"
echo "=========================================="

# Check database connection
if sudo -u postgres psql -d mybestlife -c "SELECT 1;" > /dev/null 2>&1; then
    print_success "Database connection: OK"
    
    # Check if tables exist
    TABLE_COUNT=$(sudo -u postgres psql -d mybestlife -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';" | tr -d ' ')
    if [ "$TABLE_COUNT" -gt 0 ]; then
        print_success "Database tables: $TABLE_COUNT tables found"
    else
        print_error "Database tables: No tables found"
    fi
else
    print_error "Database connection: FAILED"
fi

echo ""
echo "=========================================="
echo "📝 RECENT LOGS"
echo "=========================================="

# Show recent Nginx errors
echo "Recent Nginx errors:"
if [ -f "/var/log/nginx/error.log" ]; then
    tail -5 /var/log/nginx/error.log
else
    echo "No Nginx error log found"
fi

echo ""
echo "Recent application logs:"
if command -v pm2 &> /dev/null; then
    pm2 logs --lines 5
else
    echo "PM2 not available"
fi

echo ""
echo "=========================================="
echo "🎯 RECOMMENDED ACTIONS"
echo "=========================================="

# Generate recommendations based on findings
RECOMMENDATIONS=()

if ! command -v node &> /dev/null; then
    RECOMMENDATIONS+=("Install Node.js: curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && apt-get install -y nodejs")
fi

if ! command -v pm2 &> /dev/null; then
    RECOMMENDATIONS+=("Install PM2: npm install -g pm2")
fi

if ! command -v nginx &> /dev/null; then
    RECOMMENDATIONS+=("Install Nginx: apt install -y nginx")
fi

if ! command -v psql &> /dev/null; then
    RECOMMENDATIONS+=("Install PostgreSQL: apt install -y postgresql postgresql-contrib")
fi

if [ ! -f "/var/www/mybestlife/backend/.env" ]; then
    RECOMMENDATIONS+=("Create .env file: Run the fix-security-and-deployment.sh script")
fi

if [ ! -d "/var/www/mybestlife/backend/node_modules" ]; then
    RECOMMENDATIONS+=("Install dependencies: cd /var/www/mybestlife/backend && npm install")
fi

if ! systemctl is-active --quiet nginx; then
    RECOMMENDATIONS+=("Start Nginx: systemctl start nginx")
fi

if ! systemctl is-active --quiet postgresql; then
    RECOMMENDATIONS+=("Start PostgreSQL: systemctl start postgresql")
fi

if [ ${#RECOMMENDATIONS[@]} -eq 0 ]; then
    print_success "No critical issues found! Your setup looks good."
else
    print_warning "Found ${#RECOMMENDATIONS[@]} issues that need attention:"
    for i in "${!RECOMMENDATIONS[@]}"; do
        echo "$((i+1)). ${RECOMMENDATIONS[$i]}"
    done
fi

echo ""
print_status "🔍 Diagnostic complete!"
print_status "Run the fix-security-and-deployment.sh script to fix the identified issues."

