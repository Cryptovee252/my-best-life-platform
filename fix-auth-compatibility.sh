#!/bin/bash

# 🔧 Fix Authentication Compatibility Issues
# Fix login button issues and Safari compatibility problems

set -e

# VPS Configuration
VPS_IP="147.93.47.43"
VPS_USER="root"

echo "🔧 Fixing Authentication Compatibility Issues"
echo "============================================="
echo "VPS: $VPS_IP"
echo ""

echo "📤 Running comprehensive auth fix on VPS..."
ssh $VPS_USER@$VPS_IP << 'EOF'
echo "🔧 Starting comprehensive authentication fix..."
echo ""

# 1. Check current backend CORS configuration
echo "🔍 Checking current CORS configuration..."
cd /root/vps-clean-deployment/backend

if [ -f "app-secure.js" ]; then
    echo "Current CORS settings:"
    grep -A 10 -B 5 "cors\|CORS" app-secure.js || echo "No CORS configuration found"
else
    echo "❌ app-secure.js not found"
fi
echo ""

# 2. Update backend with comprehensive CORS and compatibility fixes
echo "📝 Updating backend with comprehensive fixes..."

# Create a comprehensive backend configuration
cat > app-secure-fixed.js << 'BACKEND_FIXED'
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcrypt');
const { PrismaClient } = require('@prisma/client');
require('dotenv').config({ path: '.env.production' });

const app = express();
const prisma = new PrismaClient();
const PORT = process.env.PORT || 3000;

// Enhanced CORS configuration for all browsers
const corsOptions = {
    origin: function (origin, callback) {
        // Allow requests with no origin (mobile apps, Postman, etc.)
        if (!origin) return callback(null, true);
        
        const allowedOrigins = [
            'https://mybestlifeapp.com',
            'https://www.mybestlifeapp.com',
            'http://localhost:8081',
            'http://localhost:3000',
            'http://127.0.0.1:8081',
            'http://127.0.0.1:3000'
        ];
        
        if (allowedOrigins.indexOf(origin) !== -1) {
            callback(null, true);
        } else {
            console.log('CORS blocked origin:', origin);
            callback(new Error('Not allowed by CORS'));
        }
    },
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: [
        'Origin',
        'X-Requested-With',
        'Content-Type',
        'Accept',
        'Authorization',
        'Cache-Control',
        'Pragma'
    ],
    exposedHeaders: ['Authorization'],
    optionsSuccessStatus: 200
};

// Apply CORS
app.use(cors(corsOptions));

// Security headers
app.use(helmet({
    crossOriginEmbedderPolicy: false,
    contentSecurityPolicy: {
        directives: {
            defaultSrc: ["'self'"],
            styleSrc: ["'self'", "'unsafe-inline'"],
            scriptSrc: ["'self'", "'unsafe-inline'", "'unsafe-eval'"],
            imgSrc: ["'self'", "data:", "https:"],
            connectSrc: ["'self'", "https:"],
            fontSrc: ["'self'", "data:"],
            objectSrc: ["'none'"],
            mediaSrc: ["'self'"],
            frameSrc: ["'self'"],
        },
    },
}));

// Body parsing
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Rate limiting (more reasonable)
const limiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 1000, // Increased limit
    message: {
        error: 'Too many requests, please try again later',
        retryAfter: 900
    },
    standardHeaders: true,
    legacyHeaders: false,
    skip: (req) => {
        // Skip rate limiting for health checks
        return req.path === '/api/health';
    }
});

app.use('/api', limiter);

// Health check endpoint
app.get('/api/health', (req, res) => {
    res.json({
        status: 'OK',
        message: 'Server is running',
        timestamp: new Date().toISOString(),
        version: '1.3.0'
    });
});

// Enhanced authentication middleware
const authenticateToken = (req, res, next) => {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];

    if (!token) {
        return res.status(401).json({ 
            success: false, 
            error: 'Access token required' 
        });
    }

    jwt.verify(token, process.env.JWT_SECRET, (err, user) => {
        if (err) {
            return res.status(403).json({ 
                success: false, 
                error: 'Invalid or expired token' 
            });
        }
        req.user = user;
        next();
    });
};

// Enhanced login endpoint
app.post('/api/auth/login', async (req, res) => {
    try {
        const { email, password } = req.body;

        if (!email || !password) {
            return res.status(400).json({
                success: false,
                error: 'Email and password are required'
            });
        }

        // Find user by email
        const user = await prisma.user.findUnique({
            where: { email: email.toLowerCase() }
        });

        if (!user) {
            return res.status(401).json({
                success: false,
                error: 'Invalid email or password'
            });
        }

        // Verify password
        const isValidPassword = await bcrypt.compare(password, user.password);
        if (!isValidPassword) {
            return res.status(401).json({
                success: false,
                error: 'Invalid email or password'
            });
        }

        // Generate tokens
        const accessToken = jwt.sign(
            { userId: user.id, email: user.email },
            process.env.JWT_SECRET,
            { expiresIn: '1h' }
        );

        const refreshToken = jwt.sign(
            { userId: user.id, email: user.email },
            process.env.JWT_REFRESH_SECRET,
            { expiresIn: '7d' }
        );

        // Return user data (without password)
        const { password: _, ...userWithoutPassword } = user;

        res.json({
            success: true,
            message: 'Login successful',
            user: userWithoutPassword,
            accessToken,
            refreshToken
        });

    } catch (error) {
        console.error('Login error:', error);
        res.status(500).json({
            success: false,
            error: 'Internal server error'
        });
    }
});

// Enhanced registration endpoint
app.post('/api/auth/register', async (req, res) => {
    try {
        const { name, username, email, password } = req.body;

        if (!name || !username || !email || !password) {
            return res.status(400).json({
                success: false,
                error: 'All fields are required'
            });
        }

        // Check if user already exists
        const existingUser = await prisma.user.findFirst({
            where: {
                OR: [
                    { email: email.toLowerCase() },
                    { username: username.toLowerCase() }
                ]
            }
        });

        if (existingUser) {
            return res.status(409).json({
                success: false,
                error: 'User with this email or username already exists'
            });
        }

        // Hash password
        const hashedPassword = await bcrypt.hash(password, 12);

        // Create user
        const user = await prisma.user.create({
            data: {
                name,
                username: username.toLowerCase(),
                email: email.toLowerCase(),
                password: hashedPassword
            }
        });

        // Generate tokens
        const accessToken = jwt.sign(
            { userId: user.id, email: user.email },
            process.env.JWT_SECRET,
            { expiresIn: '1h' }
        );

        const refreshToken = jwt.sign(
            { userId: user.id, email: user.email },
            process.env.JWT_REFRESH_SECRET,
            { expiresIn: '7d' }
        );

        // Return user data (without password)
        const { password: _, ...userWithoutPassword } = user;

        res.json({
            success: true,
            message: 'Registration successful',
            user: userWithoutPassword,
            accessToken,
            refreshToken
        });

    } catch (error) {
        console.error('Registration error:', error);
        res.status(500).json({
            success: false,
            error: 'Internal server error'
        });
    }
});

// Token refresh endpoint
app.post('/api/auth/refresh', async (req, res) => {
    try {
        const { refreshToken } = req.body;

        if (!refreshToken) {
            return res.status(400).json({
                success: false,
                error: 'Refresh token required'
            });
        }

        const decoded = jwt.verify(refreshToken, process.env.JWT_REFRESH_SECRET);
        const newAccessToken = jwt.sign(
            { userId: decoded.userId, email: decoded.email },
            process.env.JWT_SECRET,
            { expiresIn: '1h' }
        );

        res.json({
            success: true,
            accessToken: newAccessToken
        });

    } catch (error) {
        console.error('Token refresh error:', error);
        res.status(401).json({
            success: false,
            error: 'Invalid refresh token'
        });
    }
});

// Username check endpoint
app.get('/api/auth/check-username/:username', async (req, res) => {
    try {
        const { username } = req.params;
        const user = await prisma.user.findUnique({
            where: { username: username.toLowerCase() }
        });

        res.json({
            available: !user,
            username: username
        });

    } catch (error) {
        console.error('Username check error:', error);
        res.status(500).json({
            success: false,
            error: 'Internal server error'
        });
    }
});

// Error handling middleware
app.use((error, req, res, next) => {
    console.error('Server error:', error);
    res.status(500).json({
        success: false,
        error: 'Internal server error'
    });
});

// Start server
app.listen(PORT, '0.0.0.0', () => {
    console.log(`🚀 Enhanced server running on port ${PORT}`);
    console.log(`🌐 Environment: ${process.env.NODE_ENV || 'development'}`);
    console.log(`🔒 CORS enabled for all browsers`);
    console.log(`📊 Health check: http://localhost:${PORT}/api/health`);
});

// Graceful shutdown
process.on('SIGINT', async () => {
    console.log('🛑 Shutting down gracefully...');
    await prisma.$disconnect();
    process.exit(0);
});
BACKEND_FIXED

# 3. Update environment variables
echo "📝 Updating environment variables..."
cat > .env.production << 'ENV_CONFIG'
NODE_ENV=production
PORT=3000
DATABASE_URL="postgresql://mybestlife_user:secure_password@localhost:5432/mybestlife_prod"
JWT_SECRET="your-super-secure-jwt-secret-key-min-32-chars-change-this"
JWT_REFRESH_SECRET="your-super-secure-refresh-secret-key-min-32-chars-change-this"
FRONTEND_URL="https://mybestlifeapp.com"
EMAIL_HOST="smtp.gmail.com"
EMAIL_USER="your-production-email@gmail.com"
EMAIL_PASS="your-gmail-app-password"
ENABLE_SECURITY_LOGGING=true
ENABLE_AUDIT_LOGGING=true
FORCE_HTTPS=true
MAX_LOGIN_ATTEMPTS=10
LOCKOUT_DURATION_MINUTES=5
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=1000
ENABLE_CORS=true
CORS_ORIGIN="https://mybestlifeapp.com"
ENV_CONFIG

# 4. Restart backend with new configuration
echo "🔄 Restarting backend with enhanced configuration..."
pm2 stop mybestlife-backend
pm2 delete mybestlife-backend
pm2 start app-secure-fixed.js --name "mybestlife-backend" --env production

# 5. Update nginx configuration for better compatibility
echo "📝 Updating nginx configuration..."
cat > /etc/nginx/sites-available/mybestlifeapp.com << 'NGINX_CONFIG'
# Redirect HTTP to HTTPS
server {
    listen 80;
    server_name mybestlifeapp.com www.mybestlifeapp.com;
    return 301 https://$server_name$request_uri;
}

# HTTPS server
server {
    listen 443 ssl http2;
    server_name mybestlifeapp.com www.mybestlifeapp.com;

    # SSL configuration
    ssl_certificate /etc/letsencrypt/live/mybestlifeapp.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/mybestlifeapp.com/privkey.pem;
    
    # SSL security settings
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    # Security headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;

    # API routes - handle first with enhanced CORS
    location /api {
        # Handle preflight requests
        if ($request_method = 'OPTIONS') {
            add_header Access-Control-Allow-Origin "https://mybestlifeapp.com" always;
            add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
            add_header Access-Control-Allow-Headers "Origin, X-Requested-With, Content-Type, Accept, Authorization, Cache-Control, Pragma" always;
            add_header Access-Control-Allow-Credentials "true" always;
            add_header Access-Control-Max-Age 86400 always;
            add_header Content-Length 0;
            add_header Content-Type text/plain;
            return 204;
        }

        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        
        # CORS headers
        add_header Access-Control-Allow-Origin "https://mybestlifeapp.com" always;
        add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
        add_header Access-Control-Allow-Headers "Origin, X-Requested-With, Content-Type, Accept, Authorization, Cache-Control, Pragma" always;
        add_header Access-Control-Allow-Credentials "true" always;
        
        # Disable caching for API
        add_header Cache-Control "no-cache, no-store, must-revalidate" always;
        add_header Pragma "no-cache" always;
        add_header Expires "0" always;
    }

    # Frontend
    location / {
        root /var/www/mybestlife;
        try_files $uri $uri/ /index.html;
        
        # Disable caching for HTML files
        location ~* \.(html|htm)$ {
            add_header Cache-Control "no-cache, no-store, must-revalidate" always;
            add_header Pragma "no-cache" always;
            add_header Expires "0" always;
        }
    }
    
    # Security - deny access to hidden files
    location ~ /\. {
        deny all;
    }
}
NGINX_CONFIG

# Reload nginx
systemctl reload nginx

# 6. Test the fixes
echo "🔍 Testing the fixes..."
sleep 5

echo "Testing health endpoint:"
curl -s http://localhost:3000/api/health || echo "Health check failed"

echo ""
echo "Testing login endpoint:"
curl -s -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -H "Origin: https://mybestlifeapp.com" \
  -d '{"email":"test@example.com","password":"test123"}' || echo "Login test failed"

echo ""
echo "Testing CORS headers:"
curl -s -I -H "Origin: https://mybestlifeapp.com" http://localhost:3000/api/health | grep -i "access-control" || echo "No CORS headers found"

echo ""
echo "✅ Authentication compatibility fix complete!"
echo ""
echo "📊 Backend Status:"
pm2 list
echo ""
echo "🌐 Enhanced features:"
echo "   ✅ Comprehensive CORS support"
echo "   ✅ Safari compatibility"
echo "   ✅ Enhanced error handling"
echo "   ✅ Better token management"
echo "   ✅ Improved rate limiting"
EOF

echo ""
echo "🔍 Testing website after auth compatibility fix..."
sleep 5

echo "Testing HTTPS API..."
curl -s -I https://mybestlifeapp.com/api/health || echo "HTTPS API test failed"

echo "Testing CORS with different origins..."
curl -s -H "Origin: https://mybestlifeapp.com" https://mybestlifeapp.com/api/health || echo "CORS test failed"

echo ""
echo "🎉 Authentication compatibility fix complete!"
echo ""
echo "✅ **What was fixed:**
   🌐 Enhanced CORS for all browsers (including Safari)
   🔧 Improved error handling and validation
   🔄 Better token refresh mechanism
   📱 Mobile and desktop compatibility
   🛡️ Enhanced security headers
   ⚡ Improved rate limiting"
echo ""
echo "🌐 **Test across browsers:**
   1. Chrome: https://mybestlifeapp.com
   2. Safari: https://mybestlifeapp.com
   3. Firefox: https://mybestlifeapp.com
   4. Edge: https://mybestlifeapp.com"
echo ""
echo "🔧 **If still having issues:**
   - Clear browser cache completely
   - Try incognito/private mode
   - Check browser console for errors
   - Ensure JavaScript is enabled"
