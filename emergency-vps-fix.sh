#!/bin/bash

# 🚨 Emergency VPS Fix Script
# Restore your website immediately

set -e

# VPS Configuration
VPS_IP="147.93.47.43"
VPS_USER="root"
VPS_DOMAIN="mybestlifeapp.com"

echo "🚨 Emergency VPS Fix"
echo "==================="
echo "VPS: $VPS_IP | Domain: $VPS_DOMAIN"
echo ""

echo "📤 Running emergency fix on VPS..."
ssh $VPS_USER@$VPS_IP << 'EOF'
echo "🚨 Emergency Fix Starting..."
echo ""

# Stop all services
echo "Stopping all services..."
pm2 stop all || true
pm2 delete all || true
systemctl stop nginx || true

# Check if we have any deployment files
echo "Checking for deployment files..."
if [ -d "/root/vps-clean-deployment" ]; then
    echo "Found clean deployment, using it..."
    cd /root/vps-clean-deployment
elif [ -d "/root/vps-deployment" ]; then
    echo "Found old deployment, using it..."
    cd /root/vps-deployment
else
    echo "No deployment found, creating minimal setup..."
    mkdir -p /root/emergency-deployment
    cd /root/emergency-deployment
fi

# Ensure web directory exists
echo "Setting up web directory..."
sudo mkdir -p /var/www/mybestlife
sudo chown -R www-data:www-data /var/www/mybestlife

# If we have backend files, start them
if [ -d "backend" ]; then
    echo "Starting backend..."
    cd backend
    npm install --production --silent
    pm2 start app-secure.js --name "mybestlife-backend" --env production
    cd ..
else
    echo "No backend found, creating minimal backend..."
    cat > /root/emergency-backend.js << 'BACKEND_EOF'
const express = require('express');
const app = express();
const PORT = 3000;

app.use(express.json());

// Health check endpoint
app.get('/api/health', (req, res) => {
    res.json({ 
        status: 'OK', 
        message: 'Emergency backend running',
        timestamp: new Date().toISOString()
    });
});

// Basic API endpoint
app.get('/api/test', (req, res) => {
    res.json({ 
        message: 'Emergency API is working',
        version: '1.2.0'
    });
});

app.listen(PORT, () => {
    console.log(`Emergency backend running on port ${PORT}`);
});
BACKEND_EOF

    cd /root
    npm init -y
    npm install express --silent
    pm2 start emergency-backend.js --name "mybestlife-backend"
fi

# Create minimal frontend if needed
if [ ! -f "/var/www/mybestlife/index.html" ]; then
    echo "Creating minimal frontend..."
    cat > /var/www/mybestlife/index.html << 'FRONTEND_EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>MyBestLife App - Emergency Mode</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 0;
            padding: 20px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .container {
            text-align: center;
            max-width: 600px;
            padding: 40px;
            background: rgba(255, 255, 255, 0.1);
            border-radius: 20px;
            backdrop-filter: blur(10px);
        }
        h1 { font-size: 3em; margin-bottom: 20px; }
        p { font-size: 1.2em; margin-bottom: 30px; }
        .status { 
            background: rgba(0, 255, 0, 0.2); 
            padding: 20px; 
            border-radius: 10px; 
            margin: 20px 0;
        }
        .btn {
            background: #4CAF50;
            color: white;
            padding: 15px 30px;
            border: none;
            border-radius: 10px;
            font-size: 1.1em;
            cursor: pointer;
            text-decoration: none;
            display: inline-block;
            margin: 10px;
        }
        .btn:hover { background: #45a049; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 MyBestLife App</h1>
        <div class="status">
            <h2>✅ Emergency Mode Active</h2>
            <p>Your website is back online!</p>
        </div>
        <p>We're working on restoring full functionality...</p>
        <a href="/api/health" class="btn">Check API Status</a>
        <a href="/api/test" class="btn">Test Connection</a>
        <p><small>Version 1.2.0 - Emergency Recovery</small></p>
    </div>
    
    <script>
        // Test API connection
        fetch('/api/health')
            .then(response => response.json())
            .then(data => {
                console.log('API Status:', data);
                document.querySelector('.status p').innerHTML = 
                    `Backend: ${data.status} - ${data.message}`;
            })
            .catch(error => {
                console.error('API Error:', error);
                document.querySelector('.status p').innerHTML = 
                    'Backend: Checking...';
            });
    </script>
</body>
</html>
FRONTEND_EOF
fi

# Setup nginx configuration
echo "Setting up nginx..."
cat > /etc/nginx/sites-available/mybestlifeapp.com << 'NGINX_EOF'
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
    }
}
NGINX_EOF

# Enable site
ln -sf /etc/nginx/sites-available/mybestlifeapp.com /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Test and start nginx
nginx -t
systemctl start nginx
systemctl reload nginx

# Save PM2 config
pm2 save
pm2 startup || true

echo ""
echo "✅ Emergency fix complete!"
echo ""
echo "🔍 Testing services..."
curl -I http://localhost:3000/api/health || echo "Backend test failed"
curl -I http://localhost || echo "Frontend test failed"

echo ""
echo "📊 Service Status:"
systemctl status nginx --no-pager -l | head -5
pm2 list
echo ""
echo "🌐 Your website should be back online!"
EOF

echo ""
echo "🔍 Testing website after fix..."
sleep 5

echo "Testing HTTP..."
curl -I http://$VPS_DOMAIN || echo "HTTP not working"

echo "Testing HTTPS..."
curl -I https://$VPS_DOMAIN || echo "HTTPS not working"

echo ""
echo "🎉 Emergency fix complete!"
echo "Visit: http://$VPS_DOMAIN"
echo "Visit: https://$VPS_DOMAIN"
echo ""
echo "🔍 If still not working, check:"
echo "1. DNS settings point to $VPS_IP"
echo "2. Firewall allows ports 80 and 443"
echo "3. SSL certificate is valid"
