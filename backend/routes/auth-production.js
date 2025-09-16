const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { Pool } = require('pg');
require('dotenv').config();

const router = express.Router();

// Create a direct PostgreSQL connection using environment variables
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
});

// Test database connection
pool.query('SELECT NOW()', (err, res) => {
  if (err) {
    console.error('❌ Direct DB connection failed:', err);
  } else {
    console.log('✅ Direct DB connection successful');
  }
});

// Login
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    // Find user by email using direct SQL
    const userResult = await pool.query(
      'SELECT * FROM users WHERE email = $1',
      [email]
    );

    if (userResult.rows.length === 0) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    const user = userResult.rows[0];

    // Check password
    const isValidPassword = await bcrypt.compare(password, user.password);
    if (!isValidPassword) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    // Generate JWT token
    const token = jwt.sign(
      { 
        userId: user.id, 
        email: user.email,
        username: user.username 
      },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );

    res.json({
      message: 'Login successful',
      token,
      user: {
        id: user.id,
        name: user.name,
        username: user.username,
        email: user.email,
        phone: user.phone,
        dailyCP: user.dailycp,
        lifetimeCP: user.lifetimecp,
        isEmailVerified: user.isemailverified,
        createdAt: user.createdat
      }
    });

  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Register
router.post('/register', async (req, res) => {
  try {
    const { name, username, email, phone, password } = req.body;

    // Validate required fields
    if (!name || !username || !email || !password) {
      return res.status(400).json({ 
        error: 'Missing required fields: name, username, email, password' 
      });
    }

    // Check if user already exists
    const existingUserResult = await pool.query(
      'SELECT id FROM users WHERE email = $1 OR username = $2 OR phone = $3',
      [email, username, phone || null]
    );

    if (existingUserResult.rows.length > 0) {
      return res.status(400).json({ 
        error: 'User already exists with this email, username, or phone' 
      });
    }

    // Hash password
    const saltRounds = 10;
    const hashedPassword = await bcrypt.hash(password, saltRounds);

    // Create user
    const userResult = await pool.query(
      `INSERT INTO users (name, username, email, phone, password, dailycp, lifetimecp, isemailverified, createdat, updatedat)
       VALUES ($1, $2, $3, $4, $5, 0, 0, false, NOW(), NOW())
       RETURNING id, name, username, email, phone, dailycp, lifetimecp, isemailverified, createdat`,
      [name, username, email, phone || null, hashedPassword]
    );

    const user = userResult.rows[0];

    // Generate JWT token
    const token = jwt.sign(
      { 
        userId: user.id, 
        email: user.email,
        username: user.username 
      },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );

    // TODO: Send welcome email
    console.log(`✅ New user registered: ${user.email}`);

    res.status(201).json({
      message: 'Registration successful',
      token,
      user: {
        id: user.id,
        name: user.name,
        username: user.username,
        email: user.email,
        phone: user.phone,
        dailyCP: user.dailycp,
        lifetimeCP: user.lifetimecp,
        isEmailVerified: user.isemailverified,
        createdAt: user.createdat
      }
    });

  } catch (error) {
    console.error('Registration error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Verify Email
router.post('/verify-email', async (req, res) => {
  try {
    const { token } = req.body;

    // Find user by verification token
    const userResult = await pool.query(
      'SELECT * FROM users WHERE verificationtoken = $1 AND verificationexpires > NOW()',
      [token]
    );

    if (userResult.rows.length === 0) {
      return res.status(400).json({ error: 'Invalid or expired verification token' });
    }

    const user = userResult.rows[0];

    // Update user as verified
    await pool.query(
      'UPDATE users SET isemailverified = true, verificationtoken = NULL, verificationexpires = NULL, updatedat = NOW() WHERE id = $1',
      [user.id]
    );

    res.json({ message: 'Email verified successfully' });

  } catch (error) {
    console.error('Email verification error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Forgot Password
router.post('/forgot-password', async (req, res) => {
  try {
    const { email } = req.body;

    // Find user by email
    const userResult = await pool.query(
      'SELECT * FROM users WHERE email = $1',
      [email]
    );

    if (userResult.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    // Generate reset token
    const resetToken = require('crypto').randomBytes(32).toString('hex');
    const resetExpires = new Date(Date.now() + 60 * 60 * 1000); // 1 hour

    // Update user with reset token
    await pool.query(
      'UPDATE users SET resettoken = $1, resetexpires = $2, updatedat = NOW() WHERE id = $3',
      [resetToken, resetExpires, userResult.rows[0].id]
    );

    // TODO: Send reset email
    console.log(`✅ Password reset token generated for: ${email}`);

    res.json({ message: 'Password reset email sent' });

  } catch (error) {
    console.error('Forgot password error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Reset Password
router.post('/reset-password', async (req, res) => {
  try {
    const { token, password } = req.body;

    // Find user by reset token
    const userResult = await pool.query(
      'SELECT * FROM users WHERE resettoken = $1 AND resetexpires > NOW()',
      [token]
    );

    if (userResult.rows.length === 0) {
      return res.status(400).json({ error: 'Invalid or expired reset token' });
    }

    const user = userResult.rows[0];

    // Hash new password
    const saltRounds = 10;
    const hashedPassword = await bcrypt.hash(password, saltRounds);

    // Update user password
    await pool.query(
      'UPDATE users SET password = $1, resettoken = NULL, resetexpires = NULL, updatedat = NOW() WHERE id = $2',
      [hashedPassword, user.id]
    );

    res.json({ message: 'Password reset successfully' });

  } catch (error) {
    console.error('Reset password error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

module.exports = router;
