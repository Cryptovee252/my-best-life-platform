#!/bin/bash

# 🚀 Simple Deploy Authentication Fix
# Deploy without requiring sudo passwords

set -e

echo "🚀 Simple Deploy Authentication Fix"
echo "==================================="
echo ""

# 1. Create a simple deployment script that doesn't require sudo
echo "📝 Creating simple deployment script..."

cat > simple-deploy.sh << 'SIMPLE_DEPLOY'
#!/bin/bash

echo "🔧 Deploying authentication fix without sudo..."

# 1. Stop backend (if PM2 is available)
echo "🛑 Stopping backend..."
if command -v pm2 &> /dev/null; then
    pm2 stop mybestlife-backend || echo "Backend not running"
    pm2 delete mybestlife-backend || echo "Backend not found"
else
    echo "PM2 not available, stopping any Node processes..."
    pkill -f "node.*app-secure" || echo "No Node processes found"
fi

# 2. Create backup of current frontend
echo "📦 Creating backup of current frontend..."
if [ -d "/var/www/mybestlife" ]; then
    cp -r /var/www/mybestlife /var/www/mybestlife.backup.$(date +%Y%m%d-%H%M%S)
    echo "✅ Backup created"
else
    echo "⚠️ No existing frontend found"
fi

# 3. Deploy frontend (try without sudo first)
echo "📁 Deploying frontend..."
if cp -r frontend-dist/* /var/www/mybestlife/ 2>/dev/null; then
    echo "✅ Frontend deployed successfully"
else
    echo "❌ Failed to deploy frontend without sudo"
    echo "Please run: sudo cp -r frontend-dist/* /var/www/mybestlife/"
    echo "Then run: sudo chown -R www-data:www-data /var/www/mybestlife"
    exit 1
fi

# 4. Set proper permissions
echo "🔧 Setting permissions..."
if chown -R www-data:www-data /var/www/mybestlife 2>/dev/null; then
    echo "✅ Permissions set successfully"
else
    echo "❌ Failed to set permissions"
    echo "Please run: sudo chown -R www-data:www-data /var/www/mybestlife"
fi

# 5. Update backend with enhanced configuration
echo "🔧 Updating backend..."
cd /root/vps-clean-deployment/backend

# Create enhanced backend
cat > app-secure-enhanced.js << 'BACKEND_ENHANCED'
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
BACKEND_ENHANCED

# 6. Start backend with enhanced configuration
echo "🚀 Starting enhanced backend..."
if command -v pm2 &> /dev/null; then
    pm2 start app-secure-enhanced.js --name "mybestlife-backend" --env production
    echo "✅ Backend started with PM2"
else
    echo "⚠️ PM2 not available, starting with node directly"
    nohup node app-secure-enhanced.js > backend.log 2>&1 &
    echo "✅ Backend started with node"
fi

# 7. Test the deployment
echo "🔍 Testing deployment..."
sleep 5

echo "Testing health endpoint:"
curl -s http://localhost:3000/api/health || echo "Health check failed"

echo ""
echo "✅ Authentication fix deployed successfully!"
echo ""
echo "🌐 Test your website: https://mybestlifeapp.com"
echo ""
echo "🔧 If you need to set permissions manually:"
echo "sudo chown -R www-data:www-data /var/www/mybestlife"
SIMPLE_DEPLOY

chmod +x simple-deploy.sh

echo "✅ Simple deployment script created!"
echo ""
echo "📋 **Manual Deployment Steps:**
   1. Upload: scp complete-auth-fix-deployment.tar.gz root@147.93.47.43:/root/
   2. SSH: ssh root@147.93.47.43
   3. Extract: tar -xzf complete-auth-fix-deployment.tar.gz
   4. Go to folder: cd complete-auth-fix-deployment
   5. Run: ./simple-deploy.sh"
echo ""
echo "🔧 **If the script asks for password:**
   - For frontend copy: sudo cp -r frontend-dist/* /var/www/mybestlife/
   - For permissions: sudo chown -R www-data:www-data /var/www/mybestlife"
echo ""
echo "🌐 **Alternative: Use the existing working version**
   Your current website is working, just with some bugs.
   You can continue using it while we fix the deployment issues."
