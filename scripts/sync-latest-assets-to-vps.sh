#!/bin/bash

# Sync Latest Assets to VPS Script
# This script syncs the latest assets from your local directory to the VPS

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

echo "🔄 SYNCING LATEST ASSETS TO VPS"
echo "==============================="
echo "Date: $(date)"
echo ""

# Configuration
VPS_HOST="147.93.47.43"
VPS_USER="root"
LOCAL_ASSETS_DIR="/Users/v./Documents/New/HelpMyBestLife"
VPS_ASSETS_DIR="/var/www/mybestlife"

print_status "Configuration:"
echo "  VPS Host: $VPS_HOST"
echo "  VPS User: $VPS_USER"
echo "  Local Assets: $LOCAL_ASSETS_DIR"
echo "  VPS Assets: $VPS_ASSETS_DIR"
echo ""

# Step 1: Check if local assets directory exists
print_status "1. Checking local assets directory..."
if [ ! -d "$LOCAL_ASSETS_DIR" ]; then
    print_error "Local assets directory not found: $LOCAL_ASSETS_DIR"
    exit 1
fi
print_success "Local assets directory found"

# Step 2: Check VPS connection
print_status "2. Testing VPS connection..."
if ! ssh -o ConnectTimeout=10 -o BatchMode=yes $VPS_USER@$VPS_HOST "echo 'VPS connection successful'" 2>/dev/null; then
    print_error "Cannot connect to VPS. Please check:"
    echo "  - VPS is running"
    echo "  - SSH key is configured"
    echo "  - Firewall allows SSH"
    echo "  - IP address is correct"
    exit 1
fi
print_success "VPS connection successful"

# Step 3: Create backup on VPS
print_status "3. Creating backup on VPS..."
ssh $VPS_USER@$VPS_HOST "
    BACKUP_DIR=\"/root/vps-backup-\$(date +%Y%m%d_%H%M%S)\"
    mkdir -p \"\$BACKUP_DIR\"
    if [ -d \"$VPS_ASSETS_DIR\" ]; then
        cp -r \"$VPS_ASSETS_DIR\" \"\$BACKUP_DIR/\"
        echo \"Backup created at: \$BACKUP_DIR\"
    else
        echo \"No existing assets to backup\"
    fi
"

# Step 4: Sync frontend assets
print_status "4. Syncing frontend assets..."

# Sync the main frontend files
rsync -avz --progress --delete \
    --exclude 'node_modules' \
    --exclude '.expo' \
    --exclude 'dist' \
    --exclude '*.log' \
    --exclude '.env' \
    --exclude '.git' \
    "$LOCAL_ASSETS_DIR/" \
    "$VPS_USER@$VPS_HOST:$VPS_ASSETS_DIR/"

print_success "Frontend assets synced"

# Step 5: Sync backend files
print_status "5. Syncing backend files..."
LOCAL_BACKEND_DIR="/Users/v./Documents/New/backend"
VPS_BACKEND_DIR="/var/www/mybestlife/backend"

if [ -d "$LOCAL_BACKEND_DIR" ]; then
    rsync -avz --progress --delete \
        --exclude 'node_modules' \
        --exclude '*.log' \
        --exclude '.env' \
        --exclude '.git' \
        "$LOCAL_BACKEND_DIR/" \
        "$VPS_USER@$VPS_HOST:$VPS_BACKEND_DIR/"
    print_success "Backend files synced"
else
    print_warning "Local backend directory not found: $LOCAL_BACKEND_DIR"
fi

# Step 6: Sync deployment packages
print_status "6. Syncing deployment packages..."

# Sync hostinger-deploy package
if [ -d "$LOCAL_ASSETS_DIR/hostinger-deploy" ]; then
    rsync -avz --progress \
        "$LOCAL_ASSETS_DIR/hostinger-deploy/" \
        "$VPS_USER@$VPS_HOST:$VPS_ASSETS_DIR/hostinger-deploy/"
    print_success "Hostinger deployment package synced"
fi

# Sync dist package
if [ -d "$LOCAL_ASSETS_DIR/dist" ]; then
    rsync -avz --progress \
        "$LOCAL_ASSETS_DIR/dist/" \
        "$VPS_USER@$VPS_HOST:$VPS_ASSETS_DIR/dist/"
    print_success "Dist package synced"
fi

# Step 7: Set proper permissions on VPS
print_status "7. Setting proper permissions on VPS..."
ssh $VPS_USER@$VPS_HOST "
    chown -R www-data:www-data $VPS_ASSETS_DIR
    chmod -R 755 $VPS_ASSETS_DIR
    
    # Set specific permissions for backend
    if [ -d '$VPS_BACKEND_DIR' ]; then
        chown -R www-data:www-data $VPS_BACKEND_DIR
        chmod -R 755 $VPS_BACKEND_DIR
        chmod 600 $VPS_BACKEND_DIR/.env 2>/dev/null || true
    fi
"

print_success "Permissions set"

# Step 8: Install dependencies on VPS
print_status "8. Installing dependencies on VPS..."
ssh $VPS_USER@$VPS_HOST "
    cd $VPS_BACKEND_DIR
    
    # Install backend dependencies
    if [ -f 'package.json' ]; then
        npm install --production
        echo 'Backend dependencies installed'
    fi
    
    # Generate Prisma client if schema exists
    if [ -f 'prisma/schema.prisma' ]; then
        npx prisma generate
        echo 'Prisma client generated'
    fi
"

print_success "Dependencies installed"

# Step 9: Restart services on VPS
print_status "9. Restarting services on VPS..."
ssh $VPS_USER@$VPS_HOST "
    # Restart PM2 application
    cd $VPS_BACKEND_DIR
    pm2 restart mybestlife-secure || pm2 start app-secure.js --name mybestlife-secure
    pm2 save
    
    # Reload Nginx
    nginx -t && systemctl reload nginx
    
    echo 'Services restarted'
"

print_success "Services restarted"

# Step 10: Test the deployment
print_status "10. Testing the deployment..."

# Test HTTPS
if curl -f https://mybestlifeapp.com > /dev/null 2>&1; then
    print_success "HTTPS: Website responding"
else
    print_warning "HTTPS: Website not responding"
fi

# Test API endpoints
if curl -f https://mybestlifeapp.com/api/health > /dev/null 2>&1; then
    print_success "HTTPS API Health: Working"
else
    print_warning "HTTPS API Health: Not working"
fi

# Test font accessibility
if curl -f https://mybestlifeapp.com/assets/node_modules/@expo/vector-icons/build/vendor/react-native-vector-icons/Fonts/FontAwesome.b06871f281fee6b241d60582ae9369b9.ttf > /dev/null 2>&1; then
    print_success "FontAwesome fonts: Accessible"
else
    print_warning "FontAwesome fonts: May not be accessible"
fi

echo ""
print_success "Asset sync completed!"
echo ""
echo "✅ SYNC COMPLETED:"
echo "=================="
echo "  ✅ Frontend assets synced from local to VPS"
echo "  ✅ Backend files synced from local to VPS"
echo "  ✅ Deployment packages synced"
echo "  ✅ Proper permissions set"
echo "  ✅ Dependencies installed"
echo "  ✅ Services restarted"
echo "  ✅ Deployment tested"
echo ""
echo "🌐 TEST YOUR WEBSITE:"
echo "====================="
echo "  HTTPS: https://mybestlifeapp.com"
echo "  Login: https://mybestlifeapp.com/login"
echo ""
echo "📱 BROWSER TESTING:"
echo "==================="
echo "  1. Clear browser cache (Ctrl+Shift+Delete)"
echo "  2. Open incognito/private window"
echo "  3. Visit: https://mybestlifeapp.com"
echo "  4. Check browser console for errors"
echo "  5. Verify all features are working"
echo ""
echo "🔍 DEBUG COMMANDS:"
echo "=================="
echo "  # Check VPS status:"
echo "  ssh $VPS_USER@$VPS_HOST 'pm2 status'"
echo ""
echo "  # Check VPS logs:"
echo "  ssh $VPS_USER@$VPS_HOST 'pm2 logs mybestlife-secure --lines 20'"
echo ""
echo "  # Check VPS files:"
echo "  ssh $VPS_USER@$VPS_HOST 'ls -la $VPS_ASSETS_DIR'"
echo ""
print_success "Asset sync complete! 🚀"
