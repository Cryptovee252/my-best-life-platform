#!/bin/bash

# HelpMyBestLife Platform v1.2 - Build and Push Updated App
# This script builds the updated app locally and pushes to GitHub

set -e

echo "🚀 HelpMyBestLife Platform v1.2 - Build and Push"
echo "==============================================="

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
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

print_status "Building updated frontend locally..."

# Build the Expo app for web
cd frontend
npm run build:web

print_status "Verifying build..."
if [ -d "dist" ]; then
    print_success "Frontend build successful!"
    ls -la dist/
else
    print_error "Frontend build failed!"
    exit 1
fi

cd ..

print_status "Committing updated app to GitHub..."
git add .
git commit -m "🚀 Deploy updated HelpMyBestLife app to VPS

- Updated frontend with new design and branding
- Built Expo React Native app for web
- Ready for VPS deployment
- Version 1.2 with updated UI/UX"

print_status "Pushing to GitHub..."
git push origin main

print_success "🎉 Updated app pushed to GitHub!"
print_success "Now run on VPS: git pull origin main && chmod +x deploy-updated-app.sh && ./deploy-updated-app.sh"
