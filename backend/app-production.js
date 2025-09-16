const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
require('dotenv').config();

const app = express();

// Get port from environment or default to 3000
const PORT = process.env.PORT || 3000;

// CORS configuration
const corsOptions = {
  origin: process.env.FRONTEND_URL || 'https://mybestlifeapp.com',
  credentials: true,
  optionsSuccessStatus: 200
};

// Middleware
app.use(cors(corsOptions));
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

// Serve static files from public_html
app.use(express.static('../'));

// Database connection will be tested by individual route handlers
console.log('✅ Using environment variables for configuration');
console.log('🌐 CORS Origin:', corsOptions.origin);
console.log('🔌 Port:', PORT);

// Routes
app.use('/api/auth', require('./routes/auth-direct'));
app.use('/api/users', require('./routes/users'));
app.use('/api/tasks', require('./routes/tasks'));
app.use('/api/groups', require('./routes/groups'));
app.use('/api/notifications', require('./routes/notifications'));
app.use('/api/stories', require('./routes/stories'));

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.json({ 
    status: 'OK', 
    message: 'HelpMyBestLife Backend is running',
    timestamp: new Date().toISOString(),
    database: 'PostgreSQL with Direct Connection',
    environment: process.env.NODE_ENV || 'development',
    config: {
      port: PORT,
      corsOrigin: corsOptions.origin,
      frontendUrl: process.env.FRONTEND_URL
    }
  });
});

// Root endpoint
app.get('/', (req, res) => {
  res.json({
    message: 'My Best Life Backend API',
    version: '1.0.0',
    endpoints: {
      health: '/api/health',
      auth: '/api/auth',
      users: '/api/users',
      tasks: '/api/tasks',
      groups: '/api/groups',
      notifications: '/api/notifications',
      stories: '/api/stories'
    }
  });
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error('❌ Error:', err.stack);
  res.status(500).json({ 
    error: 'Something went wrong!',
    message: process.env.NODE_ENV === 'production' ? 'Internal server error' : err.message,
    timestamp: new Date().toISOString()
  });
});

// Handle 404
app.use('*', (req, res) => {
  res.status(404).json({ 
    error: 'Endpoint not found',
    message: `Cannot ${req.method} ${req.originalUrl}`,
    availableEndpoints: [
      'GET /api/health',
      'POST /api/auth/register',
      'POST /api/auth/login',
      'GET /api/users/profile',
      'GET /api/tasks',
      'GET /api/groups'
    ]
  });
});

// Start server
app.listen(PORT, () => {
  console.log(`🚀 Server running on port ${PORT}`);
  console.log(`🌐 Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log(`📊 Health check: http://localhost:${PORT}/api/health`);
});

module.exports = app;
