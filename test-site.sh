#!/bin/bash

# HelpMyBestLife Platform v1.2 - Test Site
# This script tests the site to see what's being served

set -e

echo "🧪 HelpMyBestLife Platform v1.2 - Test Site"
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

print_status "Testing HTTP (should redirect to HTTPS)..."
curl -I http://mybestlifeapp.com

echo ""
print_status "Testing HTTPS..."
curl -I https://mybestlifeapp.com

echo ""
print_status "Testing what's actually being served on HTTPS..."
curl -s https://mybestlifeapp.com | head -20

echo ""
print_status "Testing localhost..."
curl -s http://localhost | head -20

echo ""
print_status "Checking if the frontend files exist..."
ls -la /root/my-best-life-platform/frontend/dist/ | head -10

echo ""
print_status "Checking the index.html content..."
head -20 /root/my-best-life-platform/frontend/dist/index.html

print_success "Site testing completed!"
