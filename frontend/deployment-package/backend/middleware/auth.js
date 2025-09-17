const jwt = require('jsonwebtoken');
const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

const auth = async (req, res, next) => {
  try {
    // Get token from header
    const token = req.header('Authorization')?.replace('Bearer ', '');
    
    if (!token) {
      return res.status(401).json({ 
        error: 'No token, authorization denied' 
      });
    }
    
    // Verify token
    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'fallback_secret_key');
    
    // Check if user exists using Prisma
    const user = await prisma.user.findUnique({
      where: { id: decoded.userId || decoded.id },
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
      return res.status(401).json({ 
        error: 'Token is not valid' 
      });
    }
    
    // Add user to request object
    req.user = user;
    next();
    
  } catch (error) {
    console.error('Auth middleware error:', error);
    
    if (error.name === 'JsonWebTokenError') {
      return res.status(401).json({ 
        error: 'Token is not valid' 
      });
    }
    
    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({ 
        error: 'Token has expired' 
      });
    }
    
    res.status(500).json({ 
      error: 'Server error in auth middleware' 
    });
  }
};

module.exports = auth; 