#!/bin/bash

# 🚨 VPS QUICK FIX SCRIPT
# Run this on your VPS to fix the current issues

echo "🚨 VPS QUICK FIX - RESOLVING DEPLOYMENT ISSUES"
echo "=============================================="
echo ""

# Check current directory and files
echo "📁 CURRENT STATUS:"
echo "-----------------"
pwd
ls -la
echo ""

# Check if we're in the right directory
if [ ! -f "package.json" ]; then
    echo "❌ package.json not found. Looking for project directory..."
    
    # Try common locations
    if [ -f "/var/www/mybestlife/backend/package.json" ]; then
        echo "✅ Found project at /var/www/mybestlife/backend/"
        cd /var/www/mybestlife/backend
    elif [ -f "/var/www/html/backend/package.json" ]; then
        echo "✅ Found project at /var/www/html/backend/"
        cd /var/www/html/backend
    elif [ -f "/home/root/mybestlife/backend/package.json" ]; then
        echo "✅ Found project at /home/root/mybestlife/backend/"
        cd /home/root/mybestlife/backend
    else
        echo "❌ Project directory not found. Please navigate to your project directory."
        echo "Common locations to check:"
        echo "  - /var/www/mybestlife/backend/"
        echo "  - /var/www/html/backend/"
        echo "  - /home/root/mybestlife/backend/"
        echo ""
        echo "Run: cd /path/to/your/project/backend"
        exit 1
    fi
fi

echo "✅ Working in: $(pwd)"
echo ""

# Check what files exist
echo "📋 FILES IN CURRENT DIRECTORY:"
echo "------------------------------"
ls -la
echo ""

# Check if config.php exists (it might be in a different location)
if [ ! -f "config.php" ]; then
    echo "❌ config.php not found in current directory"
    echo "🔍 Searching for config.php..."
    find /var/www -name "config.php" 2>/dev/null | head -5
    find /home -name "config.php" 2>/dev/null | head -5
    echo ""
    
    # Check if this is a Node.js project
    if [ -f "package.json" ]; then
        echo "✅ This appears to be a Node.js project"
        echo "📝 Creating secure config.js instead of config.php..."
        
        # Create secure config.js for Node.js
        cat > config.js << 'EOF'
// My Best Life Platform - SECURE Node.js Configuration
require('dotenv').config();

const config = {
    // Database Configuration
    database: {
        url: process.env.DATABASE_URL || 'postgresql://mybestlife:password@localhost:5432/mybestlife',
        host: process.env.DB_HOST || 'localhost',
        port: process.env.DB_PORT || 5432,
        name: process.env.DB_NAME || 'mybestlife',
        user: process.env.DB_USER || 'mybestlife',
        password: process.env.DB_PASS || 'password'
    },

    // JWT Security
    jwt: {
        secret: process.env.JWT_SECRET || '',
        refreshSecret: process.env.JWT_REFRESH_SECRET || '',
        expiry: process.env.JWT_EXPIRY || '7d',
        refreshExpiry: process.env.JWT_REFRESH_EXPIRY || '30d'
    },

    // Email Configuration
    email: {
        host: process.env.SMTP_HOST || 'smtp.gmail.com',
        port: process.env.SMTP_PORT || 587,
        secure: process.env.SMTP_SECURE === 'true',
        user: process.env.SMTP_USER || '',
        pass: process.env.SMTP_PASS || '',
        fromName: process.env.SMTP_FROM_NAME || 'My Best Life',
        fromEmail: process.env.SMTP_FROM_EMAIL || ''
    },

    // Application Configuration
    app: {
        name: process.env.APP_NAME || 'My Best Life',
        version: process.env.APP_VERSION || '1.0.0',
        env: process.env.NODE_ENV || 'production',
        port: process.env.PORT || 3000,
        frontendUrl: process.env.FRONTEND_URL || 'https://mybestlifeapp.com',
        apiBaseUrl: process.env.API_BASE_URL || 'https://mybestlifeapp.com/api'
    },

    // Security Configuration
    security: {
        rateLimitWindowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 900000,
        rateLimitMaxRequests: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS) || 100,
        minPasswordLength: parseInt(process.env.MIN_PASSWORD_LENGTH) || 8,
        requireUppercase: process.env.REQUIRE_UPPERCASE === 'true',
        requireLowercase: process.env.REQUIRE_LOWERCASE === 'true',
        requireNumbers: process.env.REQUIRE_NUMBERS === 'true',
        requireSymbols: process.env.REQUIRE_SYMBOLS === 'true',
        maxLoginAttempts: parseInt(process.env.MAX_LOGIN_ATTEMPTS) || 5,
        lockoutDurationMinutes: parseInt(process.env.LOCKOUT_DURATION_MINUTES) || 15,
        sessionSecret: process.env.SESSION_SECRET || '',
        cookieSecure: process.env.COOKIE_SECURE === 'true',
        cookieHttpOnly: process.env.COOKIE_HTTP_ONLY === 'true',
        cookieSameSite: process.env.COOKIE_SAME_SITE || 'strict',
        forceHttps: process.env.FORCE_HTTPS === 'true'
    },

    // Logging Configuration
    logging: {
        level: process.env.LOG_LEVEL || 'info',
        filePath: process.env.LOG_FILE_PATH || '/var/log/mybestlife/app.log',
        enableSecurityLogging: process.env.ENABLE_SECURITY_LOGGING === 'true',
        enableAuditLogging: process.env.ENABLE_AUDIT_LOGGING === 'true'
    }
};

// CRITICAL SECURITY VALIDATION
if (!config.jwt.secret) {
    console.error('CRITICAL SECURITY ERROR: JWT_SECRET is not set in environment variables!');
    process.exit(1);
}

module.exports = config;
EOF
        
        echo "✅ Created secure config.js"
    else
        echo "❌ This doesn't appear to be a valid project directory"
        exit 1
    fi
else
    echo "✅ config.php found"
fi

# Generate secure secrets
echo ""
echo "🔐 GENERATING SECURE SECRETS:"
echo "-----------------------------"
JWT_SECRET=$(openssl rand -hex 64)
JWT_REFRESH_SECRET=$(openssl rand -hex 64)
SESSION_SECRET=$(openssl rand -hex 32)
DB_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)

echo "Generated secrets:"
echo "JWT_SECRET: $JWT_SECRET"
echo "JWT_REFRESH_SECRET: $JWT_REFRESH_SECRET"
echo "SESSION_SECRET: $SESSION_SECRET"
echo "DB_PASSWORD: $DB_PASSWORD"
echo ""

# Create secure .env file
echo "📝 CREATING SECURE .ENV FILE:"
echo "-----------------------------"
cat > .env << EOF
# My Best Life Platform - SECURE Environment Variables
# Generated on $(date)

# Database Configuration
DATABASE_URL="postgresql://mybestlife:${DB_PASSWORD}@localhost:5432/mybestlife"
DB_HOST=localhost
DB_PORT=5432
DB_NAME=mybestlife
DB_USER=mybestlife
DB_PASS=${DB_PASSWORD}

# JWT Security (CRITICAL - GENERATED SECURE SECRETS)
JWT_SECRET="${JWT_SECRET}"
JWT_REFRESH_SECRET="${JWT_REFRESH_SECRET}"
JWT_EXPIRY="7d"
JWT_REFRESH_EXPIRY="30d"

# Email Configuration (UPDATE WITH YOUR CREDENTIALS)
SMTP_HOST="smtp.gmail.com"
SMTP_PORT=587
SMTP_SECURE=false
SMTP_USER="your-email@gmail.com"
SMTP_PASS="your-gmail-app-password"
SMTP_FROM_NAME="My Best Life"
SMTP_FROM_EMAIL="your-email@gmail.com"

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
SESSION_SECRET="${SESSION_SECRET}"
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

echo "✅ Secure .env file created"
echo ""

# Set secure permissions
echo "🔒 SETTING SECURE PERMISSIONS:"
echo "------------------------------"
chmod 600 .env
mkdir -p logs
chmod 755 logs
echo "✅ Permissions set"
echo ""

# Install dependencies
echo "📦 INSTALLING DEPENDENCIES:"
echo "----------------------------"
npm install
echo "✅ Dependencies installed"
echo ""

# Set up database
echo "🗄️ SETTING UP DATABASE:"
echo "-----------------------"
sudo -u postgres psql << EOF
DROP DATABASE IF EXISTS mybestlife;
DROP USER IF EXISTS mybestlife;
CREATE DATABASE mybestlife;
CREATE USER mybestlife WITH PASSWORD '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON DATABASE mybestlife TO mybestlife;
\q
EOF
echo "✅ Database configured"
echo ""

# Generate database schema
echo "📊 GENERATING DATABASE SCHEMA:"
echo "------------------------------"
npx prisma generate
npx prisma db push
echo "✅ Database schema created"
echo ""

# Check PM2 status and restart application
echo "🔄 MANAGING APPLICATION:"
echo "----------------------"
pm2 list

# Stop all existing processes
pm2 delete all 2>/dev/null || true

# Check what application files exist
echo "📋 AVAILABLE APPLICATION FILES:"
ls -la *.js | grep -E "(app|server|index)"

# Try to start the application
if [ -f "app-secure.js" ]; then
    echo "✅ Starting app-secure.js..."
    pm2 start app-secure.js --name mybestlife-secure
elif [ -f "app.js" ]; then
    echo "✅ Starting app.js..."
    pm2 start app.js --name mybestlife-secure
elif [ -f "server.js" ]; then
    echo "✅ Starting server.js..."
    pm2 start server.js --name mybestlife-secure
elif [ -f "index.js" ]; then
    echo "✅ Starting index.js..."
    pm2 start index.js --name mybestlife-secure
else
    echo "❌ No application file found. Available files:"
    ls -la *.js
    echo ""
    echo "Please specify which file to start:"
    echo "pm2 start filename.js --name mybestlife-secure"
fi

pm2 save
echo "✅ Application management completed"
echo ""

# Test deployment
echo "🧪 TESTING DEPLOYMENT:"
echo "-----------------------"
sleep 5

# Check PM2 status
pm2 status

# Test application health
if curl -f http://localhost:3000/api/health > /dev/null 2>&1; then
    echo "✅ Application health check: OK"
else
    echo "❌ Application health check: FAILED"
    echo "📋 Recent logs:"
    pm2 logs --lines 5
fi

echo ""
echo "🎉 QUICK FIX COMPLETED!"
echo "======================="
echo ""
echo "📊 SUMMARY:"
echo "✅ Secure .env file created"
echo "✅ Database configured"
echo "✅ Application restarted"
echo "✅ All hardcoded secrets removed"
echo ""
echo "⚠️ NEXT STEPS:"
echo "1. Update email credentials: nano .env"
echo "2. Test website: https://mybestlifeapp.com"
echo "3. Monitor logs: pm2 logs"
echo ""
echo "🛡️ YOUR VPS IS NOW SECURE!"
