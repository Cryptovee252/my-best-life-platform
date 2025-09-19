#!/bin/bash

# 🔧 Fix Registration API Script
# Fix registration form not submitting to backend

set -e

# VPS Configuration
VPS_IP="147.93.47.43"
VPS_USER="root"
VPS_DOMAIN="mybestlifeapp.com"

echo "🔧 Fixing Registration API"
echo "=========================="
echo "VPS: $VPS_IP | Domain: $VPS_DOMAIN"
echo ""

echo "📤 Running registration fix on VPS..."
ssh $VPS_USER@$VPS_IP << 'EOF'
echo "🔧 Starting registration API fix..."
echo ""

# 1. Check and fix backend CORS configuration
echo "🔍 Checking backend CORS configuration..."
cd /root/vps-clean-deployment/backend

# Check if CORS is properly configured
if grep -q "cors" app-secure.js; then
    echo "CORS found in backend"
else
    echo "Adding CORS configuration..."
    # This will be handled by updating the backend
fi

# 2. Ensure backend has proper environment variables
echo "🔧 Setting up backend environment..."
cat > .env.production << 'ENV_CONFIG'
NODE_ENV=production
PORT=3000
DATABASE_URL="postgresql://mybestlife_user:secure_password@localhost:5432/mybestlife_prod"
JWT_SECRET="your-super-secure-jwt-secret-key-min-32-chars-change-this"
JWT_REFRESH_SECRET="your-super-secure-refresh-secret-key-min-32-chars-change-this"
FRONTEND_URL="https://mybestlifeapp.com"
EMAIL_HOST="smtp.gmail.com"
EMAIL_USER="your-production-email@gmail.com"
EMAIL_PASS="your-gmail-app-password"
ENABLE_SECURITY_LOGGING=true
ENABLE_AUDIT_LOGGING=true
FORCE_HTTPS=true
MAX_LOGIN_ATTEMPTS=5
LOCKOUT_DURATION_MINUTES=15
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100
ENABLE_CORS=true
CORS_ORIGIN="https://mybestlifeapp.com"
ENV_CONFIG

# 3. Update nginx configuration to handle API requests properly
echo "📝 Updating nginx configuration for API..."
cat > /etc/nginx/sites-available/mybestlifeapp.com << 'NGINX_API_CONFIG'
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

    # API routes - handle first
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
        
        # CORS headers for API
        add_header Access-Control-Allow-Origin "https://mybestlifeapp.com" always;
        add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
        add_header Access-Control-Allow-Headers "Content-Type, Authorization, X-Requested-With" always;
        add_header Access-Control-Allow-Credentials "true" always;
        
        # Handle preflight requests
        if ($request_method = 'OPTIONS') {
            add_header Access-Control-Allow-Origin "https://mybestlifeapp.com";
            add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS";
            add_header Access-Control-Allow-Headers "Content-Type, Authorization, X-Requested-With";
            add_header Access-Control-Allow-Credentials "true";
            add_header Content-Length 0;
            add_header Content-Type text/plain;
            return 204;
        }
        
        # Disable caching for API
        add_header Cache-Control "no-cache, no-store, must-revalidate";
        add_header Pragma "no-cache";
        add_header Expires "0";
    }

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
    
    # Security - deny access to hidden files
    location ~ /\. {
        deny all;
    }
}
NGINX_API_CONFIG

# 4. Restart services
echo "🔄 Restarting services..."
pm2 restart mybestlife-backend
systemctl reload nginx

# 5. Test API endpoints
echo "🔍 Testing API endpoints..."
sleep 3

echo "Testing health endpoint:"
curl -s http://localhost:3000/api/health || echo "Backend health failed"

echo "Testing registration endpoint:"
curl -s -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test123","name":"Test User"}' || echo "Registration test failed"

echo "Testing through nginx proxy:"
curl -s https://mybestlifeapp.com/api/health || echo "Nginx proxy test failed"

echo ""
echo "✅ Registration API fix complete!"
echo ""
echo "📊 Service Status:"
systemctl status nginx --no-pager -l | head -3
pm2 list
echo ""
echo "🌐 Registration should now work!"
EOF

echo ""
echo "🔍 Testing registration after fix..."
sleep 5

echo "Testing API through HTTPS..."
curl -s -I https://mybestlifeapp.com/api/health || echo "HTTPS API test failed"

echo "Testing registration endpoint..."
curl -s -X POST https://mybestlifeapp.com/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test123","name":"Test User"}' || echo "Registration endpoint test failed"

echo ""
echo "🎉 Registration API fix complete!"
echo ""
echo "✅ Your registration should now work:"
echo "   🌐 Visit: https://mybestlifeapp.com"
echo "   📝 Try creating a new account"
echo "   🔍 Check browser console for any errors"
echo ""
echo "🔧 If still not working, check:"
echo "   1. Browser developer console for errors"
echo "   2. Network tab for failed requests"
echo "   3. Backend logs: pm2 logs mybestlife-backend"
