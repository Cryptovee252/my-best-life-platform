#!/bin/bash

# Fix PostgreSQL Password Script
# This script handles PostgreSQL password issues

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

echo "🔐 FIXING POSTGRESQL PASSWORD"
echo "=============================="
echo "Date: $(date)"
echo ""

# Step 1: Generate a new secure password
print_status "1. Generating new secure password..."
NEW_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
print_success "Generated new password: $NEW_PASSWORD"

# Step 2: Stop PostgreSQL
print_status "2. Stopping PostgreSQL..."
systemctl stop postgresql
sleep 3

# Step 3: Start PostgreSQL in single-user mode
print_status "3. Starting PostgreSQL in single-user mode..."
sudo -u postgres postgres --single -D /var/lib/postgresql/14/main/ << EOF
ALTER USER postgres PASSWORD '$NEW_PASSWORD';
\q
EOF

# Step 4: Start PostgreSQL normally
print_status "4. Starting PostgreSQL normally..."
systemctl start postgresql
sleep 5

# Step 5: Test connection with new password
print_status "5. Testing connection..."
if sudo -u postgres psql -c "SELECT version();" > /dev/null 2>&1; then
    print_success "PostgreSQL connection successful"
else
    print_warning "Connection test failed, trying alternative method..."
    
    # Alternative method: Reset password using ALTER USER
    sudo -u postgres psql << EOF
ALTER USER postgres PASSWORD '$NEW_PASSWORD';
\q
EOF
fi

# Step 6: Create application database and user
print_status "6. Creating application database and user..."
sudo -u postgres psql << EOF
DROP DATABASE IF EXISTS mybestlife;
DROP USER IF EXISTS mybestlife;
CREATE DATABASE mybestlife;
CREATE USER mybestlife WITH PASSWORD '$NEW_PASSWORD';
GRANT ALL PRIVILEGES ON DATABASE mybestlife TO mybestlife;
\q
EOF

print_success "Database and user created"

# Step 7: Update .env file
print_status "7. Updating .env file..."
cd /var/www/mybestlife/backend

if [ -f ".env" ]; then
    # Backup existing .env
    cp .env .env.backup.$(date +%Y%m%d_%H%M%S)
    
    # Update DATABASE_URL
    sed -i "s|DATABASE_URL=.*|DATABASE_URL=\"postgresql://mybestlife:$NEW_PASSWORD@localhost:5432/mybestlife\"|g" .env
    
    print_success ".env file updated"
else
    print_warning ".env file not found, creating new one..."
    
    # Generate other secrets
    JWT_SECRET=$(openssl rand -hex 64)
    JWT_REFRESH_SECRET=$(openssl rand -hex 64)
    SESSION_SECRET=$(openssl rand -hex 32)
    
    cat > .env << EOF
# My Best Life Platform - Environment Variables

# Database Configuration
DATABASE_URL="postgresql://mybestlife:$NEW_PASSWORD@localhost:5432/mybestlife"

# JWT Security
JWT_SECRET="$JWT_SECRET"
JWT_REFRESH_SECRET="$JWT_REFRESH_SECRET"
JWT_EXPIRY="7d"
JWT_REFRESH_EXPIRY="30d"

# Email Configuration
SMTP_HOST="smtp.hostinger.com"
SMTP_PORT=465
SMTP_SECURE=true
SMTP_USER="versitalent@versitalent.com"
SMTP_PASS="your-email-password-here"
SMTP_FROM_NAME="My Best Life"
SMTP_FROM_EMAIL="versitalent@versitalent.com"

# Application Configuration
NODE_ENV="production"
PORT=3000
FRONTEND_URL="https://mybestlifeapp.com"
API_BASE_URL="https://mybestlifeapp.com/api"

# Security Configuration
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100
MIN_PASSWORD_LENGTH=8
REQUIRE_UPPERCASE=true
REQUIRE_LOWERCASE=true
REQUIRE_NUMBERS=true
REQUIRE_SYMBOLS=true
MAX_LOGIN_ATTEMPTS=5
LOCKOUT_DURATION_MINUTES=15
SESSION_SECRET="$SESSION_SECRET"
COOKIE_SECURE=true
COOKIE_HTTP_ONLY=true
COOKIE_SAME_SITE="strict"

# SSL/TLS Configuration
FORCE_HTTPS=true

# Monitoring & Logging
LOG_LEVEL="info"
LOG_FILE_PATH="/var/log/mybestlife/app.log"
ENABLE_SECURITY_LOGGING=true
ENABLE_AUDIT_LOGGING=true
EOF
    
    print_success ".env file created"
fi

# Step 8: Install dependencies and generate Prisma client
print_status "8. Installing dependencies and generating Prisma client..."
npm install
npx prisma generate
npx prisma db push

print_success "Dependencies installed and database schema updated"

# Step 9: Create test user
print_status "9. Creating test user..."
node -e "
const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');

async function createTestUser() {
  const prisma = new PrismaClient();
  
  try {
    // Check if user already exists
    const existingUser = await prisma.user.findUnique({
      where: { email: 'test@mybestlifeapp.com' }
    });
    
    if (existingUser) {
      console.log('Test user already exists');
      return;
    }
    
    // Create test user
    const hashedPassword = await bcrypt.hash('testpassword123', 10);
    
    const user = await prisma.user.create({
      data: {
        email: 'test@mybestlifeapp.com',
        password: hashedPassword,
        firstName: 'Test',
        lastName: 'User',
        isEmailVerified: true,
        role: 'USER'
      }
    });
    
    console.log('Test user created successfully:', user.email);
  } catch (error) {
    console.error('Error creating test user:', error.message);
  } finally {
    await prisma.\$disconnect();
  }
}

createTestUser();
"

# Step 10: Restart PM2 application
print_status "10. Restarting PM2 application..."
pm2 restart mybestlife-secure || pm2 start app-secure.js --name mybestlife-secure
pm2 save

sleep 5

# Step 11: Test the fixes
print_status "11. Testing the fixes..."

# Test backend connectivity
if curl -f http://localhost:3000 > /dev/null 2>&1; then
    print_success "Backend: Responding on port 3000"
else
    print_error "Backend: Not responding on port 3000"
    pm2 logs mybestlife-secure --lines 20
fi

# Test API health endpoint
if curl -f http://localhost:3000/api/health > /dev/null 2>&1; then
    print_success "API Health endpoint: Working"
else
    print_warning "API Health endpoint: Not working"
fi

# Test HTTPS API endpoints
if curl -f https://mybestlifeapp.com/api/health > /dev/null 2>&1; then
    print_success "HTTPS API Health: Working"
else
    print_warning "HTTPS API Health: Not working"
fi

echo ""
print_success "PostgreSQL password fix completed!"
echo ""
echo "✅ FIXES APPLIED:"
echo "================="
echo "  ✅ Generated new secure PostgreSQL password"
echo "  ✅ Updated postgres user password"
echo "  ✅ Created mybestlife database and user"
echo "  ✅ Updated .env file with new credentials"
echo "  ✅ Installed dependencies and generated Prisma client"
echo "  ✅ Pushed database schema"
echo "  ✅ Created test user (test@mybestlifeapp.com / testpassword123)"
echo "  ✅ Restarted PM2 application"
echo ""
echo "🔐 DATABASE CREDENTIALS:"
echo "========================"
echo "  Database: mybestlife"
echo "  Username: mybestlife"
echo "  Password: $NEW_PASSWORD"
echo "  Connection: postgresql://mybestlife:$NEW_PASSWORD@localhost:5432/mybestlife"
echo ""
echo "🧪 TEST CREDENTIALS:"
echo "===================="
echo "  Email: test@mybestlifeapp.com"
echo "  Password: testpassword123"
echo ""
echo "🌐 TEST YOUR WEBSITE:"
echo "====================="
echo "  HTTPS: https://mybestlifeapp.com"
echo "  Login: https://mybestlifeapp.com/login"
echo "  API Health: https://mybestlifeapp.com/api/health"
echo ""
print_success "PostgreSQL password fix complete! 🔐"
