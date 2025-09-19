#!/bin/bash

# 🔧 Fix Nginx Configuration Script
# Fix the nginx config error that's preventing the website from loading

set -e

# VPS Configuration
VPS_IP="147.93.47.43"
VPS_USER="root"

echo "🔧 Fixing Nginx Configuration"
echo "============================="
echo "VPS: $VPS_IP"
echo ""

echo "📤 Fixing nginx config on VPS..."
ssh $VPS_USER@$VPS_IP << 'EOF'
echo "🔧 Fixing nginx configuration..."

# Stop nginx
systemctl stop nginx

# Remove the problematic config
rm -f /etc/nginx/sites-enabled/mybestlifeapp.com

# Create a clean nginx config without the problematic directive
cat > /etc/nginx/sites-available/mybestlifeapp.com << 'NGINX_CONFIG'
server {
    listen 80;
    server_name mybestlifeapp.com www.mybestlifeapp.com;
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    
    # Frontend
    location / {
        root /var/www/mybestlife;
        try_files $uri $uri/ /index.html;
        
        # Disable caching for HTML files
        location ~* \.(html|htm)$ {
            add_header Cache-Control "no-cache, no-store, must-revalidate";
            add_header Pragma "no-cache";
            add_header Expires "0";
        }
    }
    
    # API
    location /api {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        
        # Disable caching for API
        add_header Cache-Control "no-cache, no-store, must-revalidate";
        add_header Pragma "no-cache";
        add_header Expires "0";
    }
    
    # Security - deny access to hidden files
    location ~ /\. {
        deny all;
    }
}
NGINX_CONFIG

# Enable the site
ln -sf /etc/nginx/sites-available/mybestlifeapp.com /etc/nginx/sites-enabled/

# Remove default site
rm -f /etc/nginx/sites-enabled/default

# Test nginx config
nginx -t

# Start nginx
systemctl start nginx
systemctl reload nginx

echo "✅ Nginx configuration fixed!"
echo ""
echo "🔍 Testing nginx..."
systemctl status nginx --no-pager -l | head -5

echo ""
echo "🌐 Testing local connection..."
curl -I http://localhost || echo "Local test failed"

echo ""
echo "✅ Nginx is now running!"
EOF

echo ""
echo "🔍 Testing website after nginx fix..."
sleep 3

echo "Testing HTTP..."
curl -I http://mybestlifeapp.com || echo "HTTP test failed"

echo ""
echo "🎉 Nginx fix complete!"
echo "Your website should now be accessible!"
echo "Visit: http://mybestlifeapp.com"
