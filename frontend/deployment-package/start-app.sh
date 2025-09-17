#!/bin/bash

# My Best Life - Application Startup Script

echo "🚀 Starting My Best Life application..."

# Navigate to backend directory
cd backend

# Install dependencies if not already installed
if [ ! -d "node_modules" ]; then
    echo "Installing dependencies..."
    npm install
fi

# Generate Prisma client
echo "Generating Prisma client..."
npx prisma generate

# Start application with PM2
echo "Starting application with PM2..."
pm2 start app.js --name "mybestlife"

# Save PM2 configuration
pm2 save

echo "✅ Application started successfully!"
echo "📊 Check status with: pm2 status"
echo "📝 View logs with: pm2 logs mybestlife"
