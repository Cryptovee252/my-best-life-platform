const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { Pool } = require('pg');
const config = require('../dev-config.json');

const router = express.Router();

// Create a direct PostgreSQL connection
const pool = new Pool({
  connectionString: config.database.url,
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
    const isPasswordValid = await bcrypt.compare(password, user.password);
    if (!isPasswordValid) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    // Update last active date and online status
    await pool.query(
      'UPDATE users SET lastActiveDate = CURRENT_DATE, isOnline = true, lastSeen = NOW() WHERE id = $1',
      [user.id]
    );

    // Generate JWT token
    const token = jwt.sign(
      { userId: user.id, email: user.email },
      process.env.JWT_SECRET || 'your-secret-key',
      { expiresIn: '7d' }
    );

    // Remove password from response
    const { password: _, ...userWithoutPassword } = user;

    res.json({
      success: true,
      message: 'Login successful',
      user: userWithoutPassword,
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

// Register
router.post('/register', async (req, res) => {
  try {
    const { name, username, email, phone, password } = req.body;

    // Check if user already exists
    const existingUser = await pool.query(
      'SELECT * FROM users WHERE email = $1 OR username = $2 OR phone = $3',
      [email, username, phone || null]
    );

    if (existingUser.rows.length > 0) {
      return res.status(400).json({ 
        error: 'User already exists with this email, username, or phone' 
      });
    }

    // Hash password
    const saltRounds = 10;
    const hashedPassword = await bcrypt.hash(password, saltRounds);

    // Create user
    const newUser = await pool.query(
      `INSERT INTO users (id, name, username, email, phone, password, dailyCP, lifetimeCP, daysActive, startDate, lastActiveDate, isOnline, lastSeen, createdAt, updatedAt)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15)
       RETURNING *`,
      [
        'user-' + Date.now(),
        name,
        username,
        email,
        phone || null,
        hashedPassword,
        0,
        0,
        1,
        new Date().toISOString().split('T')[0],
        new Date().toISOString().split('T')[0],
        false,
        new Date(),
        new Date(),
        new Date()
      ]
    );

    const user = newUser.rows[0];

    // Generate JWT token
    const token = jwt.sign(
      { userId: user.id, email: user.email },
      process.env.JWT_SECRET || 'your-secret-key',
      { expiresIn: '7d' }
    );

    // Remove password from response
    const { password: _, ...userWithoutPassword } = user;

    res.status(201).json({
      success: true,
      message: 'User registered successfully',
      user: userWithoutPassword,
      token
    });

  } catch (error) {
    console.error('Registration error:', error);
    res.status(500).json({ 
      error: 'Registration failed',
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
    const userResult = await pool.query(
      'SELECT * FROM users WHERE id = $1',
      [decoded.userId]
    );

    if (userResult.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    const user = userResult.rows[0];

    // Remove password from response
    const { password: _, ...userWithoutPassword } = user;

    res.json({ success: true, user: userWithoutPassword });

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
    await pool.query(
      'UPDATE users SET isOnline = false, lastSeen = NOW() WHERE id = $1',
      [decoded.userId]
    );

    res.json({ success: true, message: 'Logout successful' });

  } catch (error) {
    console.error('Logout error:', error);
    res.status(500).json({ 
      error: 'Logout failed',
      message: error.message 
    });
  }
});

module.exports = router;
