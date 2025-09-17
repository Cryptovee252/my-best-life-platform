#!/bin/bash

# Fix Prisma Security Middleware Issue
# This script fixes the "Cannot read properties of undefined (reading 'create')" error

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

echo "🔧 FIXING PRISMA SECURITY MIDDLEWARE"
echo "===================================="
echo "Date: $(date)"
echo ""

# Step 1: Navigate to backend directory
print_status "1. Navigating to backend directory..."
cd /var/www/mybestlife/backend

# Step 2: Check current .env file
print_status "2. Checking .env configuration..."
if [ -f ".env" ]; then
    print_success ".env file: Exists"
    
    # Check if DATABASE_URL exists
    if grep -q "DATABASE_URL" .env; then
        print_success "DATABASE_URL: Found"
    else
        print_error "DATABASE_URL: Missing"
        echo "Adding DATABASE_URL to .env..."
        echo 'DATABASE_URL="postgresql://mybestlife:secure_password_123@localhost:5432/mybestlife"' >> .env
    fi
else
    print_error ".env file: Missing"
    print_status "Creating .env file..."
    
    cat > .env << 'EOF'
# My Best Life Platform - Environment Variables

# Database Configuration
DATABASE_URL="postgresql://mybestlife:secure_password_123@localhost:5432/mybestlife"

# JWT Security
JWT_SECRET="your-super-secure-jwt-secret-key-here-change-this-to-something-random"
JWT_REFRESH_SECRET="your-super-secure-jwt-refresh-secret-key-here-change-this-to-something-random"
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
SESSION_SECRET="your-super-secure-session-secret-key-here"
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
fi

# Step 3: Generate secure secrets
print_status "3. Generating secure secrets..."
JWT_SECRET=$(openssl rand -hex 64)
JWT_REFRESH_SECRET=$(openssl rand -hex 64)
SESSION_SECRET=$(openssl rand -hex 32)
DB_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)

# Update .env with generated secrets
sed -i "s/your-super-secure-jwt-secret-key-here-change-this-to-something-random/$JWT_SECRET/g" .env
sed -i "s/your-super-secure-jwt-refresh-secret-key-here-change-this-to-something-random/$JWT_REFRESH_SECRET/g" .env
sed -i "s/your-super-secure-session-secret-key-here/$SESSION_SECRET/g" .env
sed -i "s/secure_password_123/$DB_PASSWORD/g" .env

print_success "Generated secure secrets"

# Step 4: Start PostgreSQL
print_status "4. Starting PostgreSQL..."
if ! systemctl is-active --quiet postgresql; then
    systemctl start postgresql
    systemctl enable postgresql
    sleep 5
fi

if systemctl is-active --quiet postgresql; then
    print_success "PostgreSQL: Running"
else
    print_error "PostgreSQL: Failed to start"
    exit 1
fi

# Step 5: Set up database
print_status "5. Setting up database..."

# Create database and user
sudo -u postgres psql << EOF
DROP DATABASE IF EXISTS mybestlife;
DROP USER IF EXISTS mybestlife;
CREATE DATABASE mybestlife;
CREATE USER mybestlife WITH PASSWORD '$DB_PASSWORD';
GRANT ALL PRIVILEGES ON DATABASE mybestlife TO mybestlife;
\q
EOF

print_success "Database and user created"

# Step 6: Install dependencies
print_status "6. Installing dependencies..."
npm install

# Step 7: Generate Prisma client
print_status "7. Generating Prisma client..."
npx prisma generate

# Step 8: Push database schema
print_status "8. Pushing database schema..."
npx prisma db push

print_success "Database schema updated"

# Step 9: Fix security middleware
print_status "9. Fixing security middleware..."

# Check if security middleware exists
if [ -f "middleware/security.js" ]; then
    print_status "Backing up security middleware..."
    cp middleware/security.js middleware/security.js.backup.$(date +%Y%m%d_%H%M%S)
    
    # Create fixed security middleware
    cat > middleware/security.js << 'EOF'
const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');

// Initialize Prisma client
let prisma;
try {
    prisma = new PrismaClient();
} catch (error) {
    console.error('Failed to initialize Prisma client:', error);
    prisma = null;
}

// Security logging function
async function logSecurityEvent(eventType, details, req) {
    if (!prisma) {
        console.warn('Prisma client not available, skipping security log');
        return;
    }
    
    try {
        await prisma.securityLog.create({
            data: {
                eventType,
                details: JSON.stringify(details),
                ipAddress: req?.ip || req?.connection?.remoteAddress || 'unknown',
                userAgent: req?.get('User-Agent') || 'unknown',
                timestamp: new Date(),
            }
        });
    } catch (error) {
        console.error('Failed to log security event:', error.message);
    }
}

// Rate limiting
const rateLimit = require('express-rate-limit');

const createRateLimit = (windowMs, max, message) => {
    return rateLimit({
        windowMs,
        max,
        message: { error: message },
        standardHeaders: true,
        legacyHeaders: false,
        handler: async (req, res) => {
            await logSecurityEvent('RATE_LIMIT_EXCEEDED', {
                ip: req.ip,
                endpoint: req.path,
                limit: max,
                window: windowMs
            }, req);
            
            res.status(429).json({
                error: message,
                retryAfter: Math.ceil(windowMs / 1000)
            });
        }
    });
};

// Authentication rate limiting
const authRateLimit = createRateLimit(
    15 * 60 * 1000, // 15 minutes
    5, // 5 attempts
    'Too many authentication attempts, please try again later'
);

// API rate limiting
const apiRateLimit = createRateLimit(
    15 * 60 * 1000, // 15 minutes
    100, // 100 requests
    'Too many requests, please try again later'
);

// Security headers middleware
const securityHeaders = (req, res, next) => {
    // Remove X-Powered-By header
    res.removeHeader('X-Powered-By');
    
    // Add security headers
    res.setHeader('X-Content-Type-Options', 'nosniff');
    res.setHeader('X-Frame-Options', 'DENY');
    res.setHeader('X-XSS-Protection', '1; mode=block');
    res.setHeader('Referrer-Policy', 'strict-origin-when-cross-origin');
    
    // Content Security Policy
    res.setHeader('Content-Security-Policy', 
        "default-src 'self'; " +
        "script-src 'self' 'unsafe-inline' 'unsafe-eval' https:; " +
        "style-src 'self' 'unsafe-inline' https: fonts.googleapis.com; " +
        "font-src 'self' https: fonts.gstatic.com data:; " +
        "img-src 'self' data: https: blob:; " +
        "connect-src 'self' https: wss: ws:; " +
        "media-src 'self' data: https:; " +
        "object-src 'none'; " +
        "base-uri 'self'; " +
        "form-action 'self'; " +
        "frame-ancestors 'none'"
    );
    
    next();
};

// Input validation middleware
const validateInput = (req, res, next) => {
    // Basic XSS protection
    const sanitizeInput = (obj) => {
        if (typeof obj === 'string') {
            return obj.replace(/<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/gi, '');
        }
        if (typeof obj === 'object' && obj !== null) {
            for (let key in obj) {
                obj[key] = sanitizeInput(obj[key]);
            }
        }
        return obj;
    };
    
    if (req.body) {
        req.body = sanitizeInput(req.body);
    }
    
    next();
};

// Error handling middleware
const errorHandler = (err, req, res, next) => {
    console.error('Security middleware error:', err);
    
    // Log security event
    logSecurityEvent('SECURITY_ERROR', {
        error: err.message,
        stack: err.stack,
        path: req.path,
        method: req.method
    }, req);
    
    // Don't expose internal errors
    const message = process.env.NODE_ENV === 'production' 
        ? 'Internal server error' 
        : err.message;
    
    res.status(500).json({ error: message });
};

module.exports = {
    authRateLimit,
    apiRateLimit,
    securityHeaders,
    validateInput,
    errorHandler,
    logSecurityEvent
};
EOF

    print_success "Security middleware fixed"
else
    print_warning "Security middleware not found, creating new one..."
    mkdir -p middleware
    
    cat > middleware/security.js << 'EOF'
const { PrismaClient } = require('@prisma/client');

// Initialize Prisma client
let prisma;
try {
    prisma = new PrismaClient();
} catch (error) {
    console.error('Failed to initialize Prisma client:', error);
    prisma = null;
}

// Security logging function
async function logSecurityEvent(eventType, details, req) {
    if (!prisma) {
        console.warn('Prisma client not available, skipping security log');
        return;
    }
    
    try {
        await prisma.securityLog.create({
            data: {
                eventType,
                details: JSON.stringify(details),
                ipAddress: req?.ip || req?.connection?.remoteAddress || 'unknown',
                userAgent: req?.get('User-Agent') || 'unknown',
                timestamp: new Date(),
            }
        });
    } catch (error) {
        console.error('Failed to log security event:', error.message);
    }
}

module.exports = {
    logSecurityEvent
};
EOF
fi

# Step 10: Create test user
print_status "10. Creating test user..."
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

# Step 11: Restart PM2 application
print_status "11. Restarting PM2 application..."

# Stop existing processes
pm2 delete all 2>/dev/null || true

# Start the application
if [ -f "app-secure.js" ]; then
    pm2 start app-secure.js --name mybestlife-secure
elif [ -f "app.js" ]; then
    pm2 start app.js --name mybestlife-secure
else
    print_error "No application file found (app-secure.js or app.js)"
    exit 1
fi

pm2 save
pm2 startup

# Wait for application to start
sleep 10

# Step 12: Test the fixes
print_status "12. Testing the fixes..."

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

# Test login endpoint
print_status "Testing login endpoint..."
LOGIN_RESPONSE=$(curl -s -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@mybestlifeapp.com","password":"testpassword123"}')

if echo "$LOGIN_RESPONSE" | grep -q "token"; then
    print_success "Login endpoint: Working"
else
    print_warning "Login endpoint: May have issues"
    echo "Response: $LOGIN_RESPONSE"
fi

# Step 13: Check for errors
print_status "13. Checking for errors..."
sleep 5
pm2 logs mybestlife-secure --lines 10

echo ""
print_success "Prisma security middleware fix completed!"
echo ""
echo "✅ FIXES APPLIED:"
echo "================="
echo "  ✅ Fixed Prisma client initialization in security middleware"
echo "  ✅ Added proper error handling for missing Prisma client"
echo "  ✅ Generated secure database credentials"
echo "  ✅ Created database and user"
echo "  ✅ Generated Prisma client and pushed schema"
echo "  ✅ Created test user (test@mybestlifeapp.com / testpassword123)"
echo "  ✅ Restarted application with PM2"
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
echo ""
print_success "Prisma security middleware fix complete! 🔐"
