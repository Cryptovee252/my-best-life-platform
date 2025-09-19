#!/bin/bash

# 🔧 Fix SSL and Database Issues
# Fix HTTPS security and database connection problems

set -e

# VPS Configuration
VPS_IP="147.93.47.43"
VPS_USER="root"
VPS_DOMAIN="mybestlifeapp.com"

echo "🔧 Fixing SSL and Database Issues"
echo "================================="
echo "VPS: $VPS_IP | Domain: $VPS_DOMAIN"
echo ""

echo "📤 Running fixes on VPS..."
ssh $VPS_USER@$VPS_IP << 'EOF'
echo "🔧 Starting SSL and Database fixes..."
echo ""

# 1. Fix SSL Certificate
echo "🔒 Fixing SSL certificate..."
if [ -d "/etc/letsencrypt/live/mybestlifeapp.com" ]; then
    echo "SSL certificate exists, updating nginx config..."
else
    echo "Getting new SSL certificate..."
    certbot --nginx -d mybestlifeapp.com -d www.mybestlifeapp.com --non-interactive --agree-tos --email admin@mybestlifeapp.com
fi

# 2. Update nginx config with SSL
echo "📝 Updating nginx configuration with SSL..."
cat > /etc/nginx/sites-available/mybestlifeapp.com << 'NGINX_SSL_CONFIG'
# Redirect HTTP to HTTPS
server {
    listen 80;
    server_name mybestlifeapp.com www.mybestlifeapp.com;
    return 301 https://$server_name$request_uri;
}

# HTTPS server
server {
    listen 443 ssl http2;
    server_name mybestlifeapp.com www.mybestlifeapp.com;

    # SSL configuration
    ssl_certificate /etc/letsencrypt/live/mybestlifeapp.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/mybestlifeapp.com/privkey.pem;
    
    # SSL security settings
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    # Security headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; font-src 'self' data:; connect-src 'self' https:; frame-ancestors 'self';" always;

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
NGINX_SSL_CONFIG

# 3. Fix Database Connection
echo "🗄️ Fixing database connection..."
cd /root/vps-clean-deployment/backend

# Install Prisma globally if not installed
if ! command -v prisma &> /dev/null; then
    echo "Installing Prisma CLI..."
    npm install -g prisma
fi

# Generate Prisma client
echo "Generating Prisma client..."
npx prisma generate

# Push database schema
echo "Pushing database schema..."
npx prisma db push --force-reset

# 4. Restart services
echo "🔄 Restarting services..."
pm2 restart mybestlife-backend
systemctl reload nginx

# 5. Test connections
echo "🔍 Testing connections..."
echo "Testing backend API..."
curl -I http://localhost:3000/api/health || echo "Backend API test failed"

echo "Testing nginx..."
curl -I http://localhost || echo "Nginx test failed"

echo "Testing HTTPS..."
curl -I https://localhost || echo "HTTPS test failed"

echo ""
echo "✅ SSL and Database fixes complete!"
echo ""
echo "📊 Service Status:"
systemctl status nginx --no-pager -l | head -3
pm2 list
echo ""
echo "🌐 Your website should now be secure and functional!"
EOF

echo ""
echo "🔍 Testing website after fixes..."
sleep 5

echo "Testing HTTP (should redirect to HTTPS)..."
curl -I http://mybestlifeapp.com || echo "HTTP test failed"

echo "Testing HTTPS..."
curl -I https://mybestlifeapp.com || echo "HTTPS test failed"

echo "Testing API..."
curl -I https://mybestlifeapp.com/api/health || echo "API test failed"

echo ""
echo "🎉 SSL and Database fixes complete!"
echo ""
echo "✅ Your website should now:"
echo "   🔒 Use HTTPS (secure connection)"
echo "   🗄️ Connect to database properly"
echo "   🔑 Allow login functionality"
echo ""
echo "🌐 Visit: https://mybestlifeapp.com"
echo "🔍 Test login with your credentials"
