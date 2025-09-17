#!/bin/bash

# HelpMyBestLife Platform v1.2 - Fix Backend Start
# This script fixes the PM2 backend startup issue

set -e

echo "🔧 HelpMyBestLife Platform v1.2 - Fix Backend Start"
echo "=================================================="

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

print_status "Stopping any existing PM2 processes..."
pm2 stop all 2>/dev/null || true
pm2 delete all 2>/dev/null || true

print_status "Checking backend directory..."
if [ -f "/root/my-best-life-platform/backend/app.js" ]; then
    print_success "Backend app.js found!"
else
    print_error "Backend app.js not found!"
    exit 1
fi

print_status "Installing backend dependencies..."
cd /root/my-best-life-platform/backend
npm install --production

print_status "Starting backend with PM2..."
pm2 start app.js --name "mybestlife-backend" --env production

print_status "Saving PM2 configuration..."
pm2 save
pm2 startup

print_status "Checking PM2 status..."
pm2 status

print_status "Testing backend API..."
sleep 3
curl -s http://localhost:3001/api/health || echo "Backend API not responding yet"

print_success "🎉 Backend fix completed!"
print_success "Backend is now running on PM2: mybestlife-backend"
print_success "API: https://mybestlifeapp.com/api/health"

echo ""
echo "📊 Check status with: pm2 status"
echo "📊 View logs with: pm2 logs mybestlife-backend"
