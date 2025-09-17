#!/bin/bash

# HelpMyBestLife Platform v1.2 - Local Development Setup
# This script sets up the project locally and prepares it for VPS deployment

set -e

echo "🚀 HelpMyBestLife Platform v1.2 - Local Development Setup"
echo "========================================================"

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

# Generate secure password
generate_password() {
    openssl rand -base64 32 | tr -d "=+/" | cut -c1-25
}

print_status "Setting up local development environment..."

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    print_warning "Node.js not found. Please install Node.js 18+ first."
    exit 1
fi

# Check if npm is installed
if ! command -v npm &> /dev/null; then
    print_warning "npm not found. Please install npm first."
    exit 1
fi

print_status "Installing backend dependencies..."
cd backend
npm install

print_status "Setting up local environment file..."
cat > .env << EOF
NODE_ENV=development
PORT=3001
DATABASE_URL="file:./dev.db"
JWT_SECRET="$(generate_password)_JWT_Secret_Key_Development"
JWT_EXPIRES_IN=7d
BCRYPT_ROUNDS=12
CORS_ORIGIN=http://localhost:3000
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_ATTEMPTS=5
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USER=your-email@gmail.com
EMAIL_PASS=your-app-password
EMAIL_FROM=noreply@mybestlifeapp.com
SECURITY_HEADERS=true
CSP_ENABLED=true
HSTS_ENABLED=true
XSS_PROTECTION=true
CONTENT_TYPE_NOSNIFF=true
FRAME_OPTIONS=DENY
EOF

print_status "Running database migrations..."
npm run db:push

print_status "Installing frontend dependencies..."
cd ../frontend
npm install

print_status "Building frontend..."
npm run build

print_success "Local development setup completed!"
echo ""
echo "🔧 To start the development server:"
echo "1. Backend: cd backend && npm start"
echo "2. Frontend: cd frontend && npm start"
echo ""
echo "🚀 To deploy to VPS:"
echo "1. Commit changes: git add . && git commit -m 'Ready for deployment'"
echo "2. Push to GitHub: git push origin main"
echo "3. On VPS: git pull origin main && chmod +x deploy-simple.sh && ./deploy-simple.sh"
echo ""
echo "📋 VPS Deployment Commands:"
echo "ssh root@147.93.47.43"
echo "cd /root/my-best-life-platform"
echo "git pull origin main"
echo "chmod +x deploy-simple.sh"
echo "./deploy-simple.sh"
echo ""
echo "🎯 Your project is ready for deployment!"
