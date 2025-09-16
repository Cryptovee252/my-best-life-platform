const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { PrismaClient } = require('@prisma/client');
const crypto = require('crypto');
const emailService = require('../services/emailService');

const router = express.Router();
const prisma = new PrismaClient();

// Register
router.post('/register', async (req, res) => {
  try {
    const { name, username, email, phone, password } = req.body;

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

    // Hash password
    const saltRounds = 10;
    const hashedPassword = await bcrypt.hash(password, saltRounds);

    // Generate email verification token
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
    res.status(500).json({ 
      error: 'Registration failed',
      message: error.message 
    });
  }
});

// Verify Email
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

    res.json({
      success: true,
      message: 'Email verified successfully! You can now sign in to your account.'
    });

  } catch (error) {
    console.error('Email verification error:', error);
    res.status(500).json({ 
      error: 'Email verification failed',
      message: error.message 
    });
  }
});

// Resend Verification Email
router.post('/resend-verification', async (req, res) => {
  try {
    const { email } = req.body;

    if (!email) {
      return res.status(400).json({ error: 'Email is required' });
    }

    const user = await prisma.user.findUnique({
      where: { email }
    });

    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    if (user.emailVerified) {
      return res.status(400).json({ error: 'Email is already verified' });
    }

    // Generate new verification token
    const verificationToken = crypto.randomBytes(32).toString('hex');
    const verificationExpires = new Date(Date.now() + 24 * 60 * 60 * 1000); // 24 hours

    // Update user with new token
    await prisma.user.update({
      where: { id: user.id },
      data: {
        verificationToken,
        verificationExpires
      }
    });

    // Send new verification email
    try {
      await emailService.sendVerificationEmail(user, verificationToken);
      res.json({
        success: true,
        message: 'Verification email sent successfully!'
      });
    } catch (emailError) {
      console.error('Failed to send verification email:', emailError);
      res.status(500).json({ error: 'Failed to send verification email' });
    }

  } catch (error) {
    console.error('Resend verification error:', error);
    res.status(500).json({ 
      error: 'Failed to resend verification email',
      message: error.message 
    });
  }
});

// Forgot Password
router.post('/forgot-password', async (req, res) => {
  try {
    const { email } = req.body;

    if (!email) {
      return res.status(400).json({ error: 'Email is required' });
    }

    const user = await prisma.user.findUnique({
      where: { email }
    });

    if (!user) {
      // Don't reveal if user exists or not for security
      return res.json({
        success: true,
        message: 'If an account with that email exists, a password reset link has been sent.'
      });
    }

    // Generate password reset token
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
      res.json({
        success: true,
        message: 'If an account with that email exists, a password reset link has been sent.'
      });
    } catch (emailError) {
      console.error('Failed to send password reset email:', emailError);
      res.status(500).json({ error: 'Failed to send password reset email' });
    }

  } catch (error) {
    console.error('Forgot password error:', error);
    res.status(500).json({ 
      error: 'Failed to process password reset request',
      message: error.message 
    });
  }
});

// Reset Password
router.post('/reset-password', async (req, res) => {
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
    const saltRounds = 10;
    const hashedPassword = await bcrypt.hash(newPassword, saltRounds);

    // Update user with new password and clear reset token
    await prisma.user.update({
      where: { id: user.id },
      data: {
        password: hashedPassword,
        resetToken: null,
        resetExpires: null
      }
    });

    res.json({
      success: true,
      message: 'Password reset successfully! You can now sign in with your new password.'
    });

  } catch (error) {
    console.error('Reset password error:', error);
    res.status(500).json({ 
      error: 'Password reset failed',
      message: error.message 
    });
  }
});

// Login
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    // Find user by email
    const user = await prisma.user.findUnique({
      where: { email }
    });

    if (!user) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    // Check password
    const isPasswordValid = await bcrypt.compare(password, user.password);
    if (!isPasswordValid) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    // Check if email is verified (optional - you can make this required)
    if (!user.emailVerified) {
      return res.status(401).json({ 
        error: 'Please verify your email address before signing in',
        requiresVerification: true
      });
    }

    // Update last active date and online status
    await prisma.user.update({
      where: { id: user.id },
      data: {
        lastActiveDate: new Date().toISOString().split('T')[0],
        isOnline: true,
        lastSeen: new Date()
      }
    });

    // Generate JWT token
    const token = jwt.sign(
      { userId: user.id, email: user.email },
      process.env.JWT_SECRET || 'your-secret-key',
      { expiresIn: '7d' }
    );

    // Remove password from response
    const { password: _, verificationToken: __, verificationExpires: ___, resetToken: ____, resetExpires: _____, ...userWithoutSensitive } = user;

    res.json({
      success: true,
      message: 'Login successful',
      user: userWithoutSensitive,
      token
    });

  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ 
      error: 'Login failed',
      message: error.message 
    });
  }
});

// Get current user
router.get('/me', async (req, res) => {
  try {
    const token = req.headers.authorization?.replace('Bearer ', '');
    
    if (!token) {
      return res.status(401).json({ error: 'No token provided' });
    }

    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'your-secret-key');
    const user = await prisma.user.findUnique({
      where: { id: decoded.userId }
    });

    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    // Remove password from response
    const { password: _, verificationToken: __, verificationExpires: ___, resetToken: ____, resetExpires: _____, ...userWithoutSensitive } = user;

    res.json({ success: true, user: userWithoutSensitive });

  } catch (error) {
    console.error('Get user error:', error);
    res.status(401).json({ error: 'Invalid token' });
  }
});

// Logout
router.post('/logout', async (req, res) => {
  try {
    const token = req.headers.authorization?.replace('Bearer ', '');
    
    if (!token) {
      return res.status(400).json({ error: 'No token provided' });
    }

    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'your-secret-key');
    
    // Update user's online status
    await prisma.user.update({
      where: { id: decoded.userId },
      data: {
        isOnline: false,
        lastSeen: new Date()
      }
    });

    res.json({ success: true, message: 'Logout successful' });

  } catch (error) {
    console.error('Logout error:', error);
    res.status(500).json({ 
      error: 'Logout failed',
      message: error.message 
    });
  }
});

// Test email connection
router.get('/test-email', async (req, res) => {
  try {
    const isConnected = await emailService.testConnection();
    if (isConnected) {
      res.json({ success: true, message: 'Email service is connected' });
    } else {
      res.status(500).json({ error: 'Email service connection failed' });
    }
  } catch (error) {
    console.error('Email test error:', error);
    res.status(500).json({ error: 'Email service test failed' });
  }
});

module.exports = router;
