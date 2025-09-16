const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const rateLimit = require('express-rate-limit');
const helmet = require('helmet');
const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

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
    });
    
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
      styleSrc: ["'self'", "'unsafe-inline'"],
      scriptSrc: ["'self'"],
      imgSrc: ["'self'", "data:", "https:"],
      connectSrc: ["'self'"],
      fontSrc: ["'self'"],
      objectSrc: ["'none'"],
      mediaSrc: ["'self'"],
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
    if (user.isLocked && user.lockoutUntil && new Date() < user.lockoutUntil) {
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
    });

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
  const requireUppercase = process.env.REQUIRE_UPPERCASE === 'true';
  const requireLowercase = process.env.REQUIRE_LOWERCASE === 'true';
  const requireNumbers = process.env.REQUIRE_NUMBERS === 'true';
  const requireSymbols = process.env.REQUIRE_SYMBOLS === 'true';

  const errors = [];

  if (password.length < minLength) {
    errors.push(`Password must be at least ${minLength} characters long`);
  }

  if (requireUppercase && !/[A-Z]/.test(password)) {
    errors.push('Password must contain at least one uppercase letter');
  }

  if (requireLowercase && !/[a-z]/.test(password)) {
    errors.push('Password must contain at least one lowercase letter');
  }

  if (requireNumbers && !/\d/.test(password)) {
    errors.push('Password must contain at least one number');
  }

  if (requireSymbols && !/[!@#$%^&*(),.?":{}|<>]/.test(password)) {
    errors.push('Password must contain at least one special character');
  }

  if (errors.length > 0) {
    return res.status(400).json({ 
      error: 'Password does not meet requirements',
      requirements: errors
    });
  }

  next();
};

// Input sanitization middleware
const sanitizeInput = (req, res, next) => {
  const sanitize = (obj) => {
    if (typeof obj === 'string') {
      return obj.trim().replace(/[<>]/g, '');
    }
    if (typeof obj === 'object' && obj !== null) {
      const sanitized = {};
      for (const key in obj) {
        sanitized[key] = sanitize(obj[key]);
      }
      return sanitized;
    }
    return obj;
  };

  req.body = sanitize(req.body);
  req.query = sanitize(req.query);
  req.params = sanitize(req.params);
  
  next();
};

// Security logging function
const logSecurityEvent = async (eventType, details) => {
  if (process.env.ENABLE_SECURITY_LOGGING === 'true') {
    try {
      const logEntry = {
        eventType,
        details: JSON.stringify(details),
        timestamp: new Date().toISOString(),
        severity: getSeverityLevel(eventType)
      };

      // Log to file
      const fs = require('fs');
      const path = require('path');
      const logDir = path.dirname(process.env.LOG_FILE_PATH || '/var/log/mybestlife/app.log');
      
      if (!fs.existsSync(logDir)) {
        fs.mkdirSync(logDir, { recursive: true });
      }

      const logFile = path.join(logDir, 'security.log');
      fs.appendFileSync(logFile, JSON.stringify(logEntry) + '\n');

      // Also log to database if audit logging is enabled
      if (process.env.ENABLE_AUDIT_LOGGING === 'true') {
        await prisma.securityLog.create({
          data: logEntry
        });
      }
    } catch (error) {
      console.error('Failed to log security event:', error);
    }
  }
};

// Get severity level for security events
const getSeverityLevel = (eventType) => {
  const severityMap = {
    'RATE_LIMIT_EXCEEDED': 'HIGH',
    'AUTH_FAILURE': 'MEDIUM',
    'INVALID_TOKEN': 'MEDIUM',
    'SUSPICIOUS_ACTIVITY': 'HIGH',
    'ACCOUNT_LOCKED': 'HIGH',
    'PASSWORD_RESET': 'MEDIUM',
    'LOGIN_SUCCESS': 'LOW',
    'LOGOUT': 'LOW'
  };
  
  return severityMap[eventType] || 'LOW';
};

// Account lockout handler
const handleFailedLogin = async (userId, ip) => {
  const maxAttempts = parseInt(process.env.MAX_LOGIN_ATTEMPTS) || 5;
  const lockoutDuration = parseInt(process.env.LOCKOUT_DURATION_MINUTES) || 15;

  try {
    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: { failedLoginAttempts: true, lockoutUntil: true }
    });

    if (!user) return;

    const newAttempts = (user.failedLoginAttempts || 0) + 1;
    const lockoutUntil = newAttempts >= maxAttempts 
      ? new Date(Date.now() + lockoutDuration * 60 * 1000)
      : null;

    await prisma.user.update({
      where: { id: userId },
      data: {
        failedLoginAttempts: newAttempts,
        lockoutUntil,
        isLocked: newAttempts >= maxAttempts
      }
    });

    // Log security event
    if (newAttempts >= maxAttempts) {
      await logSecurityEvent('ACCOUNT_LOCKED', {
        userId,
        ip,
        attempts: newAttempts,
        lockoutUntil
      });
    }
  } catch (error) {
    console.error('Failed to handle failed login:', error);
  }
};

// Reset failed login attempts on successful login
const resetFailedLoginAttempts = async (userId) => {
  try {
    await prisma.user.update({
      where: { id: userId },
      data: {
        failedLoginAttempts: 0,
        lockoutUntil: null,
        isLocked: false
      }
    });
  } catch (error) {
    console.error('Failed to reset failed login attempts:', error);
  }
};

module.exports = {
  authRateLimit,
  apiRateLimit,
  securityHeaders,
  secureAuth,
  validatePassword,
  sanitizeInput,
  logSecurityEvent,
  handleFailedLogin,
  resetFailedLoginAttempts
};
