const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const config = require('./dev-config.json');

const app = express();

// Middleware
app.use(cors({
  origin: config.cors.origin,
  credentials: config.cors.credentials
}));
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

// Database connection will be tested by individual route handlers
console.log('✅ Using direct PostgreSQL connections');

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
    database: 'PostgreSQL with Prisma',
    config: {
      port: config.server.port,
      corsOrigin: config.cors.origin
    }
  });
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ 
    error: 'Something went wrong!',
    message: err.message 
  });
});

// Handle 404
app.use('*', (req, res) => {
  res.status(404).json({ error: 'Route not found' });
});

const PORT = config.server.port;

app.listen(PORT, () => {
  console.log(`🚀 Server running on port ${PORT}`);
  console.log(`📊 Database: PostgreSQL with Prisma`);
  console.log(`🔗 Health check: http://localhost:${PORT}/api/health`);
  console.log(`🌐 CORS origin: ${config.cors.origin}`);
});

// Graceful shutdown
process.on('SIGINT', () => {
  console.log('\n🛑 Shutting down gracefully...');
  process.exit(0);
});

process.on('SIGTERM', () => {
  console.log('\n🛑 Shutting down gracefully...');
  process.exit(0);
});
