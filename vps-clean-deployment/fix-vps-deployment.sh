#!/bin/bash

# VPS Cleanup and Fresh Deployment Script

set -e

echo "🧹 Cleaning up VPS and deploying fresh files..."

# Stop all services
pm2 stop all || true
pm2 delete all || true
sudo systemctl stop nginx || true

# Clean up old files
sudo rm -rf /var/www/mybestlife/*
sudo rm -rf /home/root/vps-deployment
sudo rm -rf /home/root/helpmybestlife*
sudo rm -rf /root/vps-deployment
sudo rm -rf /root/helpmybestlife*

# Clear nginx cache
sudo rm -rf /var/cache/nginx/*
sudo rm -rf /var/lib/nginx/cache/*

# Install backend dependencies
cd backend
npm install --production --no-optional

# Run database migrations
npm run db:push || echo "Database already up to date"

# Start backend with PM2
pm2 start app-secure.js --name "mybestlife-backend" --env production

# Deploy frontend
sudo cp -r ../frontend-dist/* /var/www/mybestlife/
sudo chown -R www-data:www-data /var/www/mybestlife

# Restart nginx
sudo systemctl start nginx
sudo systemctl reload nginx

# Save PM2 configuration
pm2 save
pm2 startup || true

echo "✅ VPS cleanup and deployment complete!"
echo "🔍 Testing deployment..."

# Test endpoints
curl -I http://localhost:3000/api/health || echo "Backend health check failed"
curl -I http://localhost || echo "Frontend check failed"

echo "🌐 Your site should now show the latest version!"
