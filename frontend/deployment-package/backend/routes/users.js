const express = require('express');
const jwt = require('jsonwebtoken');
const { PrismaClient } = require('@prisma/client');

const router = express.Router();
const prisma = new PrismaClient();

// Middleware to verify JWT token
const authenticateToken = (req, res, next) => {
  const token = req.headers.authorization?.replace('Bearer ', '');
  
  if (!token) {
    return res.status(401).json({ error: 'Access token required' });
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'your-secret-key');
    req.user = decoded;
    next();
  } catch (error) {
    return res.status(403).json({ error: 'Invalid token' });
  }
};

// Get user profile
router.get('/profile', authenticateToken, async (req, res) => {
  try {
    const user = await prisma.user.findUnique({
      where: { id: req.user.userId },
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
        createdAt: true,
        updatedAt: true
      }
    });

    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    res.json({ user });
  } catch (error) {
    console.error('Get profile error:', error);
    res.status(500).json({ 
      error: 'Failed to get profile',
      message: error.message 
    });
  }
});

// Update user profile
router.put('/profile', authenticateToken, async (req, res) => {
  try {
    const { name, username, profilePic } = req.body;
    const updateData = {};

    if (name !== undefined) updateData.name = name;
    if (username !== undefined) updateData.username = username;
    if (profilePic !== undefined) updateData.profilePic = profilePic;

    if (Object.keys(updateData).length === 0) {
      return res.status(400).json({ error: 'No fields to update' });
    }

    // Check if username is already taken by another user
    if (username) {
      const existingUser = await prisma.user.findFirst({
        where: {
          username,
          id: { not: req.user.userId }
        }
      });

      if (existingUser) {
        return res.status(400).json({ error: 'Username already taken' });
      }
    }

    const updatedUser = await prisma.user.update({
      where: { id: req.user.userId },
      data: updateData,
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
        createdAt: true,
        updatedAt: true
      }
    });

    res.json({ 
      message: 'Profile updated successfully',
      user: updatedUser 
    });
  } catch (error) {
    console.error('Update profile error:', error);
    res.status(500).json({ 
      error: 'Failed to update profile',
      message: error.message 
    });
  }
});

// Get user commitment points
router.get('/commitment-points', authenticateToken, async (req, res) => {
  try {
    const user = await prisma.user.findUnique({
      where: { id: req.user.userId },
      select: {
        dailyCP: true,
        lifetimeCP: true,
        daysActive: true,
        startDate: true,
        lastActiveDate: true
      }
    });

    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    res.json({ 
      dailyCP: user.dailyCP,
      lifetimeCP: user.lifetimeCP,
      daysActive: user.daysActive,
      startDate: user.startDate,
      lastActiveDate: user.lastActiveDate
    });
  } catch (error) {
    console.error('Get commitment points error:', error);
    res.status(500).json({ 
      error: 'Failed to get commitment points',
      message: error.message 
    });
  }
});

// Add commitment points
router.post('/commitment-points', authenticateToken, async (req, res) => {
  try {
    const { points, category } = req.body;

    if (!points || typeof points !== 'number' || points <= 0) {
      return res.status(400).json({ error: 'Valid points value required' });
    }

    const user = await prisma.user.findUnique({
      where: { id: req.user.userId }
    });

    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    // Check if it's a new day
    const today = new Date().toISOString().split('T')[0];
    const isNewDay = user.lastActiveDate !== today;

    // Update user data
    const updatedUser = await prisma.user.update({
      where: { id: req.user.userId },
      data: {
        dailyCP: isNewDay ? points : user.dailyCP + points,
        lifetimeCP: user.lifetimeCP + points,
        daysActive: isNewDay ? user.daysActive + 1 : user.daysActive,
        lastActiveDate: today,
        lastSeen: new Date()
      },
      select: {
        dailyCP: true,
        lifetimeCP: true,
        daysActive: true,
        lastActiveDate: true
      }
    });

    res.json({
      message: 'Commitment points added successfully',
      pointsAdded: points,
      category: category || 'general',
      dailyCP: updatedUser.dailyCP,
      lifetimeCP: updatedUser.lifetimeCP,
      daysActive: updatedUser.daysActive,
      lastActiveDate: updatedUser.lastActiveDate
    });
  } catch (error) {
    console.error('Add commitment points error:', error);
    res.status(500).json({ 
      error: 'Failed to add commitment points',
      message: error.message 
    });
  }
});

// Get user statistics
router.get('/stats', authenticateToken, async (req, res) => {
  try {
    const user = await prisma.user.findUnique({
      where: { id: req.user.userId },
      select: {
        dailyCP: true,
        lifetimeCP: true,
        daysActive: true,
        startDate: true,
        lastActiveDate: true,
        createdAt: true
      }
    });

    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    // Calculate additional stats
    const startDate = new Date(user.startDate);
    const today = new Date();
    const totalDays = Math.ceil((today - startDate) / (1000 * 60 * 60 * 24));
    const averageCP = totalDays > 0 ? Math.round(user.lifetimeCP / totalDays) : 0;

    res.json({
      dailyCP: user.dailyCP,
      lifetimeCP: user.lifetimeCP,
      daysActive: user.daysActive,
      startDate: user.startDate,
      lastActiveDate: user.lastActiveDate,
      totalDays,
      averageCP,
      createdAt: user.createdAt
    });
  } catch (error) {
    console.error('Get stats error:', error);
    res.status(500).json({ 
      error: 'Failed to get user statistics',
      message: error.message 
    });
  }
});

// Get all users (for leaderboard)
router.get('/leaderboard', async (req, res) => {
  try {
    const users = await prisma.user.findMany({
      select: {
        id: true,
        name: true,
        username: true,
        profilePic: true,
        dailyCP: true,
        lifetimeCP: true,
        daysActive: true,
        isOnline: true,
        lastSeen: true
      },
      orderBy: [
        { lifetimeCP: 'desc' },
        { dailyCP: 'desc' }
      ],
      take: 50
    });

    res.json({ users });
  } catch (error) {
    console.error('Get leaderboard error:', error);
    res.status(500).json({ 
      error: 'Failed to get leaderboard',
      message: error.message 
    });
  }
});

module.exports = router; 