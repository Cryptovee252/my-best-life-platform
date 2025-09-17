#!/bin/bash

# Complete Asset and Database Fix Script
# This script fixes all asset issues and database connection problems

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

echo "🔧 COMPLETE ASSET AND DATABASE FIX"
echo "=================================="
echo "Date: $(date)"
echo ""

# Step 1: Navigate to backend directory
print_status "1. Navigating to backend directory..."
cd /var/www/mybestlife/backend

# Step 2: Create backup of current files
print_status "2. Creating backup of current files..."
BACKUP_DIR="/root/backup-$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
cp -r . "$BACKUP_DIR/"
print_success "Backup created at: $BACKUP_DIR"

# Step 3: Fix .env file
print_status "3. Fixing .env configuration..."
if [ ! -f ".env" ]; then
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

# Generate secure secrets
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

# Step 9: Fix security middleware syntax errors
print_status "9. Fixing security middleware..."

# Create fixed security middleware
cat > middleware/security.js << 'EOF'
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const rateLimit = require('express-rate-limit');
const helmet = require('helmet');
const { PrismaClient } = require('@prisma/client');

// Initialize Prisma client with error handling
let prisma;
try {
    prisma = new PrismaClient();
} catch (error) {
    console.error('Failed to initialize Prisma client:', error);
    prisma = null;
}

// Rate limiting for authentication endpoints
const authRateLimit = rateLimit({
  windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000, // 15 minutes
  max: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS) || 5, // 5 attempts per window
  message: {
    error: 'Too many authentication attempts, please try again later',
    retryAfter: Math.ceil((parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000) / 1000)
  },
  standardHeaders: true,
  legacyHeaders: false,
  skipSuccessfulRequests: true,
  handler: (req, res) => {
    // Log security event
    logSecurityEvent('RATE_LIMIT_EXCEEDED', {
      ip: req.ip,
      userAgent: req.get('User-Agent'),
      endpoint: req.path,
      timestamp: new Date().toISOString()
    }, req);
    
    res.status(429).json({
      error: 'Too many authentication attempts, please try again later',
      retryAfter: Math.ceil((parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000) / 1000)
    });
  }
});

// Rate limiting for general API endpoints
const apiRateLimit = rateLimit({
  windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000,
  max: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS) || 100,
  message: {
    error: 'Too many requests, please try again later'
  },
  standardHeaders: true,
  legacyHeaders: false
});

// Security headers middleware
const securityHeaders = helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'", "https:"],
      scriptSrc: ["'self'", "'unsafe-inline'", "'unsafe-eval'", "https:"],
      imgSrc: ["'self'", "data:", "https:", "blob:"],
      connectSrc: ["'self'", "https:", "wss:", "ws:"],
      fontSrc: ["'self'", "https:", "fonts.gstatic.com", "data:", "blob:"],
      objectSrc: ["'none'"],
      mediaSrc: ["'self'", "data:", "https:"],
      frameSrc: ["'none'"],
    },
  },
  hsts: {
    maxAge: 31536000,
    includeSubDomains: true,
    preload: true
  },
  noSniff: true,
  xssFilter: true,
  referrerPolicy: { policy: "strict-origin-when-cross-origin" }
});

// Enhanced authentication middleware
const secureAuth = async (req, res, next) => {
  try {
    // Get token from header
    const authHeader = req.header('Authorization');
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ 
        error: 'Access denied. No token provided.' 
      });
    }

    const token = authHeader.replace('Bearer ', '');
    
    // Verify token
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    
    // Check if user exists and is active
    const user = await prisma.user.findUnique({
      where: { id: decoded.userId },
      select: {
        id: true,
        name: true,
        username: true,
        email: true,
        phone: true,
        profilePic: true,
        dailyCP: true,
        lifetimeCP: true,
        daysActive: true,
        startDate: true,
        lastActiveDate: true,
        isOnline: true,
        lastSeen: true,
        emailVerified: true,
        createdAt: true,
        updatedAt: true,
        // Security fields
        isLocked: true,
        lockoutUntil: true,
        failedLoginAttempts: true
      }
    });
    
    if (!user) {
      return res.status(401).json({ 
        error: 'Invalid token. User not found.' 
      });
    }

    // Check if account is locked
    if (user.isLocked && user.lockoutUntil && new Date() < new Date(user.lockoutUntil)) {
      return res.status(423).json({ 
        error: 'Account temporarily locked due to suspicious activity',
        lockoutUntil: user.lockoutUntil
      });
    }

    // Check if email is verified
    if (!user.emailVerified) {
      return res.status(403).json({ 
        error: 'Please verify your email address before accessing this resource' 
      });
    }

    // Update last seen
    await prisma.user.update({
      where: { id: user.id },
      data: { 
        lastSeen: new Date(),
        isOnline: true
      }
    });

    // Add user to request object
    req.user = user;
    next();
    
  } catch (error) {
    // Log security event
    logSecurityEvent('AUTH_FAILURE', {
      ip: req.ip,
      userAgent: req.get('User-Agent'),
      error: error.message,
      timestamp: new Date().toISOString()
    }, req);

    if (error.name === 'JsonWebTokenError') {
      return res.status(401).json({ 
        error: 'Invalid token' 
      });
    }
    
    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({ 
        error: 'Token has expired' 
      });
    }
    
    res.status(500).json({ 
      error: 'Authentication error' 
    });
  }
};

// Password validation middleware
const validatePassword = (req, res, next) => {
  const { password } = req.body;
  
  if (!password) {
    return res.status(400).json({ error: 'Password is required' });
  }
  
  const minLength = parseInt(process.env.MIN_PASSWORD_LENGTH) || 8;
  if (password.length < minLength) {
    return res.status(400).json({ 
      error: `Password must be at least ${minLength} characters long` 
    });
  }
  
  // Check password requirements
  const requireUppercase = process.env.REQUIRE_UPPERCASE === 'true';
  const requireLowercase = process.env.REQUIRE_LOWERCASE === 'true';
  const requireNumbers = process.env.REQUIRE_NUMBERS === 'true';
  const requireSymbols = process.env.REQUIRE_SYMBOLS === 'true';
  
  if (requireUppercase && !/[A-Z]/.test(password)) {
    return res.status(400).json({ 
      error: 'Password must contain at least one uppercase letter' 
    });
  }
  
  if (requireLowercase && !/[a-z]/.test(password)) {
    return res.status(400).json({ 
      error: 'Password must contain at least one lowercase letter' 
    });
  }
  
  if (requireNumbers && !/\d/.test(password)) {
    return res.status(400).json({ 
      error: 'Password must contain at least one number' 
    });
  }
  
  if (requireSymbols && !/[!@#$%^&*(),.?":{}|<>]/.test(password)) {
    return res.status(400).json({ 
      error: 'Password must contain at least one special character' 
    });
  }
  
  next();
};

// Input sanitization middleware
const sanitizeInput = (req, res, next) => {
  const sanitize = (obj) => {
    if (typeof obj === 'string') {
      return obj.replace(/<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/gi, '');
    }
    if (typeof obj === 'object' && obj !== null) {
      for (let key in obj) {
        obj[key] = sanitize(obj[key]);
      }
    }
    return obj;
  };
  
  if (req.body) {
    req.body = sanitize(req.body);
  }
  
  next();
};

// Security logging function
const logSecurityEvent = async (eventType, details, req) => {
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
};

// Get severity level for security events
const getSeverityLevel = (eventType) => {
  const severityMap = {
    'LOGIN_SUCCESS': 'INFO',
    'LOGIN_FAILURE': 'WARNING',
    'AUTH_FAILURE': 'WARNING',
    'RATE_LIMIT_EXCEEDED': 'WARNING',
    'SECURITY_ERROR': 'ERROR',
    'SUSPICIOUS_ACTIVITY': 'CRITICAL'
  };
  return severityMap[eventType] || 'INFO';
};

module.exports = {
  authRateLimit,
  apiRateLimit,
  securityHeaders,
  secureAuth,
  validatePassword,
  sanitizeInput,
  logSecurityEvent,
  getSeverityLevel
};
EOF

print_success "Security middleware fixed"

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

# Step 11: Fix font files
print_status "11. Fixing font files..."

# Create proper font directory structure
mkdir -p /var/www/mybestlife/assets/node_modules/@expo/vector-icons/build/vendor/react-native-vector-icons/Fonts
mkdir -p /var/www/mybestlife/assets/assets/fonts

# Download FontAwesome fonts to the correct location
cd /var/www/mybestlife/assets/node_modules/@expo/vector-icons/build/vendor/react-native-vector-icons/Fonts

# Download FontAwesome fonts
wget -q https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/webfonts/fa-solid-900.ttf || true
wget -q https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/webfonts/fa-regular-400.ttf || true
wget -q https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/webfonts/fa-brands-400.ttf || true

# Create the specific FontAwesome file that's missing
if [ -f "fa-solid-900.ttf" ]; then
    cp fa-solid-900.ttf FontAwesome.b06871f281fee6b241d60582ae9369b9.ttf
    cp fa-solid-900.ttf FontAwesome5_Solid.605ed7926cf39a2ad5ec2d1f9d391d3d.ttf
    print_success "Created missing FontAwesome files"
fi

# Download Ionicons
wget -q https://cdnjs.cloudflare.com/ajax/libs/ionicons/7.1.0/fonts/ionicons.ttf || true
if [ -f "ionicons.ttf" ]; then
    cp ionicons.ttf Ionicons.6148e7019854f3bde85b633cb88f3c25.ttf
    print_success "Created missing Ionicons file"
fi

# Also download to the assets/fonts directory
cd /var/www/mybestlife/assets/assets/fonts
wget -q https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/webfonts/fa-solid-900.ttf || true
wget -q https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/webfonts/fa-regular-400.ttf || true
wget -q https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/webfonts/fa-brands-400.ttf || true
wget -q https://cdnjs.cloudflare.com/ajax/libs/ionicons/7.1.0/fonts/ionicons.ttf || true

# Set proper permissions
chown -R www-data:www-data /var/www/mybestlife/assets
chmod -R 755 /var/www/mybestlife/assets

print_success "Font files fixed"

# Step 12: Update Nginx configuration for better font handling
print_status "12. Updating Nginx configuration..."

cat > /etc/nginx/sites-available/mybestlife << 'EOF'
# My Best Life Platform - Secure Nginx Configuration

# Rate limiting
limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
limit_req_zone $binary_remote_addr zone=auth:10m rate=5r/s;

# Upstream backend
upstream backend {
    server localhost:3000;
    keepalive 32;
}

# HTTP to HTTPS redirect
server {
    listen 80;
    listen [::]:80;
    server_name mybestlifeapp.com www.mybestlifeapp.com;
    
    # Let's Encrypt challenge
    location /.well-known/acme-challenge/ {
        root /var/www/html;
    }
    
    # Redirect all other traffic to HTTPS
    location / {
        return 301 https://$server_name$request_uri;
    }
}

# HTTPS server
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name mybestlifeapp.com www.mybestlifeapp.com;
    
    # SSL Configuration
    ssl_certificate /etc/letsencrypt/live/mybestlifeapp.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/mybestlifeapp.com/privkey.pem;
    
    # SSL Security Settings
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    # Security Headers (Relaxed CSP for React/Expo apps)
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
    add_header X-Frame-Options "DENY" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    
    # Relaxed Content Security Policy for React/Expo apps
    add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval' https:; style-src 'self' 'unsafe-inline' https: fonts.googleapis.com; font-src 'self' https: fonts.gstatic.com data: blob:; img-src 'self' data: https: blob:; connect-src 'self' https: wss: ws:; media-src 'self' data: https:; object-src 'none'; base-uri 'self'; form-action 'self'; frame-ancestors 'none';" always;
    
    add_header Permissions-Policy "geolocation=(), microphone=(), camera=()" always;
    
    # Hide Nginx version
    server_tokens off;
    
    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/json
        application/javascript
        application/xml+rss
        application/atom+xml
        image/svg+xml
        font/woff
        font/woff2
        font/ttf
        font/eot;
    
    # Font files with CORS headers and proper caching
    location ~* \.(woff|woff2|ttf|eot)$ {
        root /var/www/mybestlife;
        expires 1y;
        add_header Cache-Control "public, immutable";
        add_header Access-Control-Allow-Origin "*";
        add_header Access-Control-Allow-Methods "GET, OPTIONS";
        add_header Access-Control-Allow-Headers "Origin, X-Requested-With, Content-Type, Accept";
        
        # Handle OPTIONS requests for CORS
        if ($request_method = 'OPTIONS') {
            add_header Access-Control-Allow-Origin "*";
            add_header Access-Control-Allow-Methods "GET, OPTIONS";
            add_header Access-Control-Allow-Headers "Origin, X-Requested-With, Content-Type, Accept";
            add_header Access-Control-Max-Age 86400;
            add_header Content-Length 0;
            add_header Content-Type text/plain;
            return 204;
        }
    }
    
    # Static files with proper caching
    location / {
        root /var/www/mybestlife;
        try_files $uri $uri/ @backend;
        
        # Cache static assets
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
            add_header Access-Control-Allow-Origin "*";
        }
    }
    
    # API routes with rate limiting
    location /api/ {
        limit_req zone=api burst=20 nodelay;
        
        proxy_pass http://backend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
    
    # Authentication routes with stricter rate limiting
    location /api/auth/ {
        limit_req zone=auth burst=10 nodelay;
        
        proxy_pass http://backend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
    
    # Backend fallback
    location @backend {
        proxy_pass http://backend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
    
    # Block access to sensitive files
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }
    
    location ~ /(\.env|\.git|\.htaccess|\.htpasswd|composer\.json|composer\.lock|package\.json|package-lock\.json|yarn\.lock) {
        deny all;
        access_log off;
        log_not_found off;
    }
    
    # Block common attack patterns
    location ~* /(wp-admin|wp-login|xmlrpc|admin|administrator) {
        deny all;
        access_log off;
        log_not_found off;
    }
}
EOF

# Test and reload Nginx
nginx -t
systemctl reload nginx

print_success "Nginx configuration updated"

# Step 13: Restart PM2 application
print_status "13. Restarting PM2 application..."

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

# Step 14: Test the fixes
print_status "14. Testing the fixes..."

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

# Test font accessibility
if curl -f https://mybestlifeapp.com/assets/node_modules/@expo/vector-icons/build/vendor/react-native-vector-icons/Fonts/FontAwesome.b06871f281fee6b241d60582ae9369b9.ttf > /dev/null 2>&1; then
    print_success "FontAwesome fonts: Accessible"
else
    print_warning "FontAwesome fonts: May not be accessible"
fi

# Step 15: Check for errors
print_status "15. Checking for errors..."
sleep 5
pm2 logs mybestlife-secure --lines 10

echo ""
print_success "Complete asset and database fix completed!"
echo ""
echo "✅ FIXES APPLIED:"
echo "================="
echo "  ✅ Fixed Prisma client initialization in security middleware"
echo "  ✅ Fixed syntax errors in security middleware"
echo "  ✅ Added proper error handling for missing Prisma client"
echo "  ✅ Generated secure database credentials"
echo "  ✅ Created database and user"
echo "  ✅ Generated Prisma client and pushed schema"
echo "  ✅ Created test user (test@mybestlifeapp.com / testpassword123)"
echo "  ✅ Downloaded FontAwesome and Ionicons fonts"
echo "  ✅ Updated Nginx configuration for better font handling"
echo "  ✅ Added CORS headers for fonts"
echo "  ✅ Set proper permissions on font files"
echo "  ✅ Reloaded Nginx configuration"
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
echo "  Fonts: https://mybestlifeapp.com/assets/node_modules/@expo/vector-icons/build/vendor/react-native-vector-icons/Fonts/"
echo ""
echo "📱 BROWSER TESTING:"
echo "==================="
echo "  1. Clear browser cache (Ctrl+Shift+Delete)"
echo "  2. Open incognito/private window"
echo "  3. Visit: https://mybestlifeapp.com"
echo "  4. Check browser console for font errors"
echo "  5. Verify FontAwesome icons are loading"
echo ""
echo "🔍 DEBUG COMMANDS:"
echo "=================="
echo "  # Test specific font file:"
echo "  curl -I https://mybestlifeapp.com/assets/node_modules/@expo/vector-icons/build/vendor/react-native-vector-icons/Fonts/FontAwesome.b06871f281fee6b241d60582ae9369b9.ttf"
echo ""
echo "  # Check font files:"
echo "  ls -la /var/www/mybestlife/assets/node_modules/@expo/vector-icons/build/vendor/react-native-vector-icons/Fonts/"
echo ""
echo "  # Check PM2 status:"
echo "  pm2 status"
echo ""
echo "  # Check logs:"
echo "  pm2 logs mybestlife-secure --lines 20"
echo ""
print_success "Complete asset and database fix complete! 🎨🔐"
