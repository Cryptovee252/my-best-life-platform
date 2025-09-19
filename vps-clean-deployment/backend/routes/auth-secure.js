const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const { PrismaClient } = require('@prisma/client');
const emailService = require('../services/emailService');
const { 
  authRateLimit, 
  secureAuth, 
  validatePassword, 
  sanitizeInput,
  logSecurityEvent,
  handleFailedLogin,
  resetFailedLoginAttempts
} = require('../middleware/security');

const router = express.Router();
const prisma = new PrismaClient();

// Apply rate limiting to all auth routes
router.use(authRateLimit);

// Apply input sanitization
router.use(sanitizeInput);

// Register endpoint
router.post('/register', validatePassword, async (req, res) => {
  try {
    const { name, username, email, phone, password } = req.body;

    // Validate required fields
    if (!name || !username || !email || !password) {
      return res.status(400).json({ 
        error: 'Missing required fields: name, username, email, password' 
      });
    }

    // Validate email format
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      return res.status(400).json({ error: 'Invalid email format' });
    }

    // Validate username format (alphanumeric and underscores only)
    const usernameRegex = /^[a-zA-Z0-9_]+$/;
    if (!usernameRegex.test(username) || username.length < 3 || username.length > 20) {
      return res.status(400).json({ 
        error: 'Username must be 3-20 characters long and contain only letters, numbers, and underscores' 
      });
    }

    // Check if user already exists
    const existingUser = await prisma.user.findFirst({
      where: {
        OR: [
          { email },
          { username },
          { phone: phone || undefined }
        ]
      }
    });

    if (existingUser) {
      return res.status(400).json({ 
        error: 'User already exists with this email, username, or phone' 
      });
    }

    // Hash password with higher salt rounds for better security
    const saltRounds = 12;
    const hashedPassword = await bcrypt.hash(password, saltRounds);

    // Generate secure verification token
    const verificationToken = crypto.randomBytes(32).toString('hex');
    const verificationExpires = new Date(Date.now() + 24 * 60 * 60 * 1000); // 24 hours

    // Create user
    const user = await prisma.user.create({
      data: {
        name,
        username,
        email,
        phone: phone || null,
        password: hashedPassword,
        dailyCP: 0,
        lifetimeCP: 0,
        daysActive: 1,
        startDate: new Date().toISOString().split('T')[0],
        lastActiveDate: new Date().toISOString().split('T')[0],
        isOnline: false,
        lastSeen: new Date(),
        emailVerified: false,
        verificationToken,
        verificationExpires
      }
    });

    // Send welcome email
    try {
      await emailService.sendWelcomeEmail(user);
    } catch (emailError) {
      console.error('Failed to send welcome email:', emailError);
      // Don't fail registration if email fails
    }

    // Send verification email
    try {
      await emailService.sendVerificationEmail(user, verificationToken);
    } catch (emailError) {
      console.error('Failed to send verification email:', emailError);
      // Don't fail registration if email fails
    }

    // Log successful registration
    await logSecurityEvent('REGISTRATION_SUCCESS', {
      userId: user.id,
      email: user.email,
      ip: req.ip,
      userAgent: req.get('User-Agent')
    });

    // Remove password and sensitive data from response
    const { password: _, verificationToken: __, verificationExpires: ___, ...userWithoutSensitive } = user;

    res.status(201).json({
      success: true,
      message: 'User registered successfully! Please check your email to verify your account.',
      user: userWithoutSensitive,
      requiresVerification: true
    });

  } catch (error) {
    console.error('Registration error:', error);
    
    // Log security event
    await logSecurityEvent('REGISTRATION_FAILURE', {
      email: req.body.email,
      ip: req.ip,
      error: error.message
    });

    res.status(500).json({ 
      error: 'Registration failed',
      message: process.env.NODE_ENV === 'production' ? 'Internal server error' : error.message
    });
  }
});

// Login endpoint
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password are required' });
    }

    // Find user by email
    const user = await prisma.user.findUnique({
      where: { email }
    });

    if (!user) {
      // Don't reveal if user exists or not
      await logSecurityEvent('LOGIN_FAILURE', {
        email,
        ip: req.ip,
        reason: 'User not found'
      });
      
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    // Check if account is locked
    if (user.isLocked && user.lockoutUntil && new Date() < user.lockoutUntil) {
      await logSecurityEvent('LOGIN_BLOCKED', {
        userId: user.id,
        email,
        ip: req.ip,
        lockoutUntil: user.lockoutUntil
      });
      
      return res.status(423).json({ 
        error: 'Account temporarily locked due to suspicious activity',
        lockoutUntil: user.lockoutUntil
      });
    }

    // Check password
    const isPasswordValid = await bcrypt.compare(password, user.password);
    if (!isPasswordValid) {
      // Handle failed login attempt
      await handleFailedLogin(user.id, req.ip);
      
      await logSecurityEvent('LOGIN_FAILURE', {
        userId: user.id,
        email,
        ip: req.ip,
        reason: 'Invalid password'
      });
      
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    // Check if email is verified (skip in development)
    if (!user.emailVerified && process.env.NODE_ENV === 'production') {
      return res.status(401).json({ 
        error: 'Please verify your email address before signing in',
        requiresVerification: true
      });
    }

    // Reset failed login attempts on successful login
    await resetFailedLoginAttempts(user.id);

    // Update last active date and online status
    await prisma.user.update({
      where: { id: user.id },
      data: {
        lastActiveDate: new Date().toISOString().split('T')[0],
        isOnline: true,
        lastSeen: new Date()
      }
    });

    // Generate JWT token with shorter expiry
    const token = jwt.sign(
      { 
        userId: user.id, 
        email: user.email,
        username: user.username,
        iat: Math.floor(Date.now() / 1000)
      },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRY || '7d' }
    );

    // Generate refresh token
    const refreshToken = jwt.sign(
      { userId: user.id, type: 'refresh' },
      process.env.JWT_REFRESH_SECRET || process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_REFRESH_EXPIRY || '30d' }
    );

    // Log successful login
    await logSecurityEvent('LOGIN_SUCCESS', {
      userId: user.id,
      email: user.email,
      ip: req.ip,
      userAgent: req.get('User-Agent')
    });

    // Remove password from response
    const { password: _, verificationToken: __, verificationExpires: ___, resetToken: ____, resetExpires: _____, ...userWithoutSensitive } = user;

    res.json({
      success: true,
      message: 'Login successful',
      user: userWithoutSensitive,
      token,
      refreshToken
    });

  } catch (error) {
    console.error('Login error:', error);
    
    await logSecurityEvent('LOGIN_ERROR', {
      email: req.body.email,
      ip: req.ip,
      error: error.message
    });
    
    res.status(500).json({ 
      error: 'Login failed',
      message: process.env.NODE_ENV === 'production' ? 'Internal server error' : error.message
    });
  }
});

// Refresh token endpoint
router.post('/refresh', async (req, res) => {
  try {
    const { refreshToken } = req.body;

    if (!refreshToken) {
      return res.status(400).json({ error: 'Refresh token is required' });
    }

    // Verify refresh token
    const decoded = jwt.verify(refreshToken, process.env.JWT_REFRESH_SECRET || process.env.JWT_SECRET);
    
    if (decoded.type !== 'refresh') {
      return res.status(401).json({ error: 'Invalid refresh token' });
    }

    // Check if user still exists
    const user = await prisma.user.findUnique({
      where: { id: decoded.userId },
      select: { id: true, email: true, username: true, emailVerified: true, isLocked: true }
    });

    if (!user || (process.env.NODE_ENV === 'production' && !user.emailVerified) || user.isLocked) {
      return res.status(401).json({ error: 'Invalid refresh token' });
    }

    // Generate new access token
    const newToken = jwt.sign(
      { 
        userId: user.id, 
        email: user.email,
        username: user.username,
        iat: Math.floor(Date.now() / 1000)
      },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRY || '7d' }
    );

    res.json({
      success: true,
      token: newToken
    });

  } catch (error) {
    console.error('Token refresh error:', error);
    
    if (error.name === 'JsonWebTokenError' || error.name === 'TokenExpiredError') {
      return res.status(401).json({ error: 'Invalid refresh token' });
    }
    
    res.status(500).json({ error: 'Token refresh failed' });
  }
});

// Verify Email endpoint
router.post('/verify-email', async (req, res) => {
  try {
    const { token } = req.body;

    if (!token) {
      return res.status(400).json({ error: 'Verification token is required' });
    }

    const user = await prisma.user.findFirst({
      where: {
        verificationToken: token,
        verificationExpires: {
          gt: new Date()
        }
      }
    });

    if (!user) {
      return res.status(400).json({ error: 'Invalid or expired verification token' });
    }

    // Update user as verified
    await prisma.user.update({
      where: { id: user.id },
      data: {
        emailVerified: true,
        verificationToken: null,
        verificationExpires: null
      }
    });

    // Log email verification
    await logSecurityEvent('EMAIL_VERIFIED', {
      userId: user.id,
      email: user.email,
      ip: req.ip
    });

    res.json({
      success: true,
      message: 'Email verified successfully! You can now sign in to your account.'
    });

  } catch (error) {
    console.error('Email verification error:', error);
    res.status(500).json({ 
      error: 'Email verification failed',
      message: process.env.NODE_ENV === 'production' ? 'Internal server error' : error.message
    });
  }
});

// Forgot Password endpoint
router.post('/forgot-password', async (req, res) => {
  try {
    const { email } = req.body;

    if (!email) {
      return res.status(400).json({ error: 'Email is required' });
    }

    const user = await prisma.user.findUnique({
      where: { email }
    });

    // Always return success to prevent email enumeration
    const response = {
      success: true,
      message: 'If an account with that email exists, a password reset link has been sent.'
    };

    if (!user) {
      return res.json(response);
    }

    // Generate secure reset token
    const resetToken = crypto.randomBytes(32).toString('hex');
    const resetExpires = new Date(Date.now() + 60 * 60 * 1000); // 1 hour

    // Update user with reset token
    await prisma.user.update({
      where: { id: user.id },
      data: {
        resetToken,
        resetExpires
      }
    });

    // Send password reset email
    try {
      await emailService.sendPasswordResetEmail(user, resetToken);
      
      // Log password reset request
      await logSecurityEvent('PASSWORD_RESET_REQUESTED', {
        userId: user.id,
        email: user.email,
        ip: req.ip
      });
    } catch (emailError) {
      console.error('Failed to send password reset email:', emailError);
    }

    res.json(response);

  } catch (error) {
    console.error('Forgot password error:', error);
    res.status(500).json({ 
      error: 'Failed to process password reset request',
      message: process.env.NODE_ENV === 'production' ? 'Internal server error' : error.message
    });
  }
});

// Reset Password endpoint
router.post('/reset-password', validatePassword, async (req, res) => {
  try {
    const { token, newPassword } = req.body;

    if (!token || !newPassword) {
      return res.status(400).json({ error: 'Token and new password are required' });
    }

    const user = await prisma.user.findFirst({
      where: {
        resetToken: token,
        resetExpires: {
          gt: new Date()
        }
      }
    });

    if (!user) {
      return res.status(400).json({ error: 'Invalid or expired reset token' });
    }

    // Hash new password
    const saltRounds = 12;
    const hashedPassword = await bcrypt.hash(newPassword, saltRounds);

    // Update user with new password and clear reset token
    await prisma.user.update({
      where: { id: user.id },
      data: {
        password: hashedPassword,
        resetToken: null,
        resetExpires: null,
        failedLoginAttempts: 0,
        isLocked: false,
        lockoutUntil: null
      }
    });

    // Log password reset
    await logSecurityEvent('PASSWORD_RESET_SUCCESS', {
      userId: user.id,
      email: user.email,
      ip: req.ip
    });

    res.json({
      success: true,
      message: 'Password reset successfully! You can now sign in with your new password.'
    });

  } catch (error) {
    console.error('Reset password error:', error);
    res.status(500).json({ 
      error: 'Password reset failed',
      message: process.env.NODE_ENV === 'production' ? 'Internal server error' : error.message
    });
  }
});

// Logout endpoint
router.post('/logout', secureAuth, async (req, res) => {
  try {
    // Update user's online status
    await prisma.user.update({
      where: { id: req.user.id },
      data: {
        isOnline: false,
        lastSeen: new Date()
      }
    });

    // Log logout
    await logSecurityEvent('LOGOUT', {
      userId: req.user.id,
      email: req.user.email,
      ip: req.ip
    });

    res.json({ success: true, message: 'Logout successful' });

  } catch (error) {
    console.error('Logout error:', error);
    res.status(500).json({ 
      error: 'Logout failed',
      message: process.env.NODE_ENV === 'production' ? 'Internal server error' : error.message
    });
  }
});

// Get current user endpoint
router.get('/me', secureAuth, async (req, res) => {
  try {
    // Remove sensitive data from response
    const { password: _, verificationToken: __, verificationExpires: ___, resetToken: ____, resetExpires: _____, ...userWithoutSensitive } = req.user;

    res.json({ 
      success: true, 
      user: userWithoutSensitive 
    });

  } catch (error) {
    console.error('Get user error:', error);
    res.status(500).json({ 
      error: 'Failed to get user information',
      message: process.env.NODE_ENV === 'production' ? 'Internal server error' : error.message
    });
  }
});

module.exports = router;
