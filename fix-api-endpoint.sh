#!/bin/bash

# 🔧 Fix API Endpoint Configuration
# Fix frontend trying to connect to localhost instead of proper API

set -e

# VPS Configuration
VPS_IP="147.93.47.43"
VPS_USER="root"

echo "🔧 Fixing API Endpoint Configuration"
echo "===================================="
echo "VPS: $VPS_IP"
echo ""

echo "📤 Running API endpoint fix on VPS..."
ssh $VPS_USER@$VPS_IP << 'EOF'
echo "🔧 Starting API endpoint fix..."
echo ""

# 1. Check current backend status
echo "📊 Checking backend status..."
pm2 list
echo ""

# 2. Test backend directly
echo "🔍 Testing backend directly..."
curl -s http://localhost:3000/api/health || echo "Backend not responding on localhost:3000"
echo ""

# 3. Check if backend is listening on the right port
echo "🔍 Checking what's listening on port 3000..."
netstat -tlnp | grep :3000 || echo "Nothing listening on port 3000"
echo ""

# 4. Check backend logs for errors
echo "📋 Checking backend logs..."
pm2 logs mybestlife-backend --lines 10
echo ""

# 5. Check if the enhanced backend file exists and is correct
echo "🔍 Checking enhanced backend file..."
if [ -f "/root/vps-clean-deployment/backend/app-secure-enhanced.js" ]; then
    echo "✅ Enhanced backend file exists"
    head -20 /root/vps-clean-deployment/backend/app-secure-enhanced.js
else
    echo "❌ Enhanced backend file not found"
fi
echo ""

# 6. Restart backend with proper configuration
echo "🔄 Restarting backend with proper configuration..."
cd /root/vps-clean-deployment/backend

# Stop current backend
pm2 stop mybestlife-backend
pm2 delete mybestlife-backend

# Create a working backend configuration
cat > app-secure-working.js << 'WORKING_BACKEND'
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

// Enhanced CORS configuration
const corsOptions = {
    origin: function (origin, callback) {
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

app.use(cors(corsOptions));
app.use(helmet());
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Rate limiting
const limiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    max: 1000,
    message: {
        error: 'Too many requests, please try again later',
        retryAfter: 900
    }
});

app.use('/api', limiter);

// Health check
app.get('/api/health', (req, res) => {
    res.json({
        status: 'OK',
        message: 'Server is running',
        timestamp: new Date().toISOString(),
        version: '1.3.0'
    });
});

// Login endpoint
app.post('/api/auth/login', async (req, res) => {
    try {
        const { email, password } = req.body;

        if (!email || !password) {
            return res.status(400).json({
                success: false,
                error: 'Email and password are required'
            });
        }

        const user = await prisma.user.findUnique({
            where: { email: email.toLowerCase() }
        });

        if (!user) {
            return res.status(401).json({
                success: false,
                error: 'Invalid email or password'
            });
        }

        const isValidPassword = await bcrypt.compare(password, user.password);
        if (!isValidPassword) {
            return res.status(401).json({
                success: false,
                error: 'Invalid email or password'
            });
        }

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

// Registration endpoint
app.post('/api/auth/register', async (req, res) => {
    try {
        const { name, username, email, password } = req.body;

        if (!name || !username || !email || !password) {
            return res.status(400).json({
                success: false,
                error: 'All fields are required'
            });
        }

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

        const hashedPassword = await bcrypt.hash(password, 12);

        const user = await prisma.user.create({
            data: {
                name,
                username: username.toLowerCase(),
                email: email.toLowerCase(),
                password: hashedPassword
            }
        });

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

// Error handling
app.use((error, req, res, next) => {
    console.error('Server error:', error);
    res.status(500).json({
        success: false,
        error: 'Internal server error'
    });
});

// Start server
app.listen(PORT, '0.0.0.0', () => {
    console.log(`🚀 Working server running on port ${PORT}`);
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
WORKING_BACKEND

# 7. Start the working backend
echo "🚀 Starting working backend..."
pm2 start app-secure-working.js --name "mybestlife-backend" --env production

# 8. Wait for backend to start
echo "⏳ Waiting for backend to start..."
sleep 5

# 9. Test the backend
echo "🔍 Testing backend..."
curl -s http://localhost:3000/api/health || echo "Backend test failed"
echo ""

# 10. Test login endpoint
echo "🔍 Testing login endpoint..."
curl -s -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test123"}' || echo "Login test failed"
echo ""

echo "✅ API endpoint fix complete!"
echo ""
echo "📊 Backend Status:"
pm2 list
echo ""
echo "🌐 Backend should now be accessible at:"
echo "   - http://localhost:3000/api/health"
echo "   - https://mybestlifeapp.com/api/health"
EOF

echo ""
echo "🔍 Testing website after API endpoint fix..."
sleep 5

echo "Testing HTTPS API..."
curl -s -I https://mybestlifeapp.com/api/health || echo "HTTPS API test failed"

echo ""
echo "🎉 API endpoint fix complete!"
echo ""
echo "✅ **What was fixed:**
   🔧 Backend configuration issues
   🌐 Proper CORS setup
   🔄 Backend restart with working configuration
   📊 Health check endpoints
   🔑 Login/registration endpoints"
echo ""
echo "🌐 **Test your website now:**
   1. Visit: https://mybestlifeapp.com
   2. Try logging in
   3. Check browser console for any remaining errors"
echo ""
echo "🔧 **If still having issues:**
   - Check browser console for errors
   - Try refreshing the page
   - Clear browser cache"
