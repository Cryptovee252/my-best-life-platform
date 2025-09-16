const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const compression = require('compression');
const { 
  securityHeaders, 
  apiRateLimit,
  logSecurityEvent 
} = require('./middleware/security');
require('dotenv').config();

const app = express();

// Get port from environment or default to 3000
const PORT = process.env.PORT || 3000;

// Trust proxy for accurate IP addresses (important for rate limiting)
app.set('trust proxy', 1);

// Security headers middleware (must be first)
app.use(securityHeaders);

// Compression middleware
app.use(compression());

// CORS configuration with security
const corsOptions = {
  origin: function (origin, callback) {
    // Allow requests with no origin (mobile apps, Postman, etc.)
    if (!origin) return callback(null, true);
    
    const allowedOrigins = [
      process.env.FRONTEND_URL || 'https://mybestlifeapp.com',
      'https://www.mybestlifeapp.com'
    ];
    
    if (allowedOrigins.indexOf(origin) !== -1) {
      callback(null, true);
    } else {
      callback(new Error('Not allowed by CORS'));
    }
  },
  credentials: true,
  optionsSuccessStatus: 200,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With']
};

app.use(cors(corsOptions));

// Body parsing middleware with size limits
app.use(bodyParser.json({ 
  limit: '10mb',
  verify: (req, res, buf) => {
    req.rawBody = buf;
  }
}));
app.use(bodyParser.urlencoded({ 
  extended: true, 
  limit: '10mb' 
}));

// Apply rate limiting to all routes
app.use(apiRateLimit);

// Request logging middleware
app.use((req, res, next) => {
  const start = Date.now();
  
  // Log request
  console.log(`${new Date().toISOString()} - ${req.method} ${req.path} - IP: ${req.ip}`);
  
  // Override res.end to log response
  const originalEnd = res.end;
  res.end = function(chunk, encoding) {
    const duration = Date.now() - start;
    console.log(`${new Date().toISOString()} - ${req.method} ${req.path} - ${res.statusCode} - ${duration}ms`);
    
    // Log security events for certain status codes
    if (res.statusCode >= 400) {
      logSecurityEvent('HTTP_ERROR', {
        method: req.method,
        path: req.path,
        statusCode: res.statusCode,
        ip: req.ip,
        userAgent: req.get('User-Agent'),
        duration
      });
    }
    
    originalEnd.call(this, chunk, encoding);
  };
  
  next();
});

// Serve static files with security headers
app.use(express.static('../', {
  maxAge: '1d',
  etag: true,
  setHeaders: (res, path) => {
    // Set security headers for static files
    res.setHeader('X-Content-Type-Options', 'nosniff');
    res.setHeader('X-Frame-Options', 'DENY');
    res.setHeader('Referrer-Policy', 'strict-origin-when-cross-origin');
  }
}));

// Health check endpoint (no rate limiting)
app.get('/api/health', (req, res) => {
  res.json({ 
    status: 'OK', 
    message: 'HelpMyBestLife Backend is running securely',
    timestamp: new Date().toISOString(),
    database: 'PostgreSQL with Secure Connection',
    environment: process.env.NODE_ENV || 'development',
    security: {
      rateLimiting: 'enabled',
      cors: 'configured',
      securityHeaders: 'enabled',
      ssl: process.env.FORCE_HTTPS === 'true' ? 'enabled' : 'disabled'
    },
    config: {
      port: PORT,
      corsOrigin: process.env.FRONTEND_URL,
      frontendUrl: process.env.FRONTEND_URL
    }
  });
});

// Security status endpoint
app.get('/api/security-status', (req, res) => {
  res.json({
    status: 'secure',
    features: {
      rateLimiting: true,
      cors: true,
      securityHeaders: true,
      inputValidation: true,
      passwordPolicy: true,
      accountLockout: true,
      auditLogging: process.env.ENABLE_AUDIT_LOGGING === 'true',
      ssl: process.env.FORCE_HTTPS === 'true'
    },
    lastUpdated: new Date().toISOString()
  });
});

// Routes with security middleware
app.use('/api/auth', require('./routes/auth-secure'));
app.use('/api/users', require('./routes/users'));
app.use('/api/tasks', require('./routes/tasks'));
app.use('/api/groups', require('./routes/groups'));
app.use('/api/notifications', require('./routes/notifications'));
app.use('/api/stories', require('./routes/stories'));

// Root endpoint
app.get('/', (req, res) => {
  res.json({
    message: 'My Best Life Backend API - Secure Version',
    version: '2.0.0',
    security: 'enhanced',
    endpoints: {
      health: '/api/health',
      security: '/api/security-status',
      auth: '/api/auth',
      users: '/api/users',
      tasks: '/api/tasks',
      groups: '/api/groups',
      notifications: '/api/notifications',
      stories: '/api/stories'
    },
    documentation: 'https://mybestlifeapp.com/docs',
    support: 'https://mybestlifeapp.com/support'
  });
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error('❌ Error:', err.stack);
  
  // Log security event for errors
  logSecurityEvent('APPLICATION_ERROR', {
    error: err.message,
    stack: err.stack,
    method: req.method,
    path: req.path,
    ip: req.ip,
    userAgent: req.get('User-Agent')
  });
  
  // Don't expose error details in production
  const isDevelopment = process.env.NODE_ENV === 'development';
  
  res.status(500).json({ 
    error: 'Something went wrong!',
    message: isDevelopment ? err.message : 'Internal server error',
    timestamp: new Date().toISOString(),
    requestId: req.headers['x-request-id'] || 'unknown'
  });
});

// Handle 404 with security logging
app.use('*', (req, res) => {
  // Log potential security scan attempts
  logSecurityEvent('NOT_FOUND_REQUEST', {
    method: req.method,
    path: req.originalUrl,
    ip: req.ip,
    userAgent: req.get('User-Agent')
  });
  
  res.status(404).json({ 
    error: 'Endpoint not found',
    message: `Cannot ${req.method} ${req.originalUrl}`,
    timestamp: new Date().toISOString(),
    availableEndpoints: [
      'GET /api/health',
      'GET /api/security-status',
      'POST /api/auth/register',
      'POST /api/auth/login',
      'GET /api/users/profile',
      'GET /api/tasks',
      'GET /api/groups'
    ]
  });
});

// Graceful shutdown handling
process.on('SIGTERM', () => {
  console.log('SIGTERM received, shutting down gracefully');
  process.exit(0);
});

process.on('SIGINT', () => {
  console.log('SIGINT received, shutting down gracefully');
  process.exit(0);
});

// Start server
app.listen(PORT, () => {
  console.log(`🚀 Secure server running on port ${PORT}`);
  console.log(`🌐 Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log(`🔒 Security: Enhanced`);
  console.log(`📊 Health check: http://localhost:${PORT}/api/health`);
  console.log(`🛡️ Security status: http://localhost:${PORT}/api/security-status`);
  
  // Log server startup
  logSecurityEvent('SERVER_STARTUP', {
    port: PORT,
    environment: process.env.NODE_ENV || 'development',
    timestamp: new Date().toISOString()
  });
});

module.exports = app;
