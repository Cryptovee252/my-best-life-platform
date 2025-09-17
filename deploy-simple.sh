#!/bin/bash

# HelpMyBestLife Platform v1.2 - Simple One-Command Deployment
# This script handles everything automatically with SQLite (no PostgreSQL issues)

set -e

echo "🚀 HelpMyBestLife Platform v1.2 - Simple Deployment"
echo "=================================================="

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root (use sudo)"
    exit 1
fi

# Generate secure password
generate_password() {
    openssl rand -base64 32 | tr -d "=+/" | cut -c1-25
}

print_status "Installing dependencies..."
apt update && apt upgrade -y
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs nginx certbot python3-certbot-nginx
npm install -g pm2

print_status "Setting up SQLite database (no authentication issues)..."
cat > /root/my-best-life-platform/backend/.env << EOF
NODE_ENV=production
PORT=3001
DATABASE_URL="file:./dev.db"
JWT_SECRET="$(generate_password)_JWT_Secret_Key_Production_Secure"
JWT_EXPIRES_IN=7d
BCRYPT_ROUNDS=12
CORS_ORIGIN=https://mybestlifeapp.com
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_ATTEMPTS=5
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USER=your-email@gmail.com
EMAIL_PASS=your-app-password
EMAIL_FROM=noreply@mybestlifeapp.com
SECURITY_HEADERS=true
CSP_ENABLED=true
HSTS_ENABLED=true
XSS_PROTECTION=true
CONTENT_TYPE_NOSNIFF=true
FRAME_OPTIONS=DENY
EOF

print_status "Installing backend dependencies..."
cd /root/my-best-life-platform/backend
npm install --production

print_status "Running database migrations..."
npm run db:push

print_status "Starting backend with PM2..."
pm2 start app.js --name "mybestlife-backend" --env production
pm2 save
pm2 startup

print_status "Building frontend..."
cd /root/my-best-life-platform/frontend
npm install
npm run build

print_status "Configuring Nginx..."
cat > /etc/nginx/sites-available/mybestlifeapp.com << 'EOF'
server {
    listen 80;
    server_name mybestlifeapp.com www.mybestlifeapp.com;
    
    # Security headers
    add_header X-Frame-Options "DENY" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; font-src 'self' data:; connect-src 'self' https:; frame-ancestors 'none';" always;
    
    # Rate limiting
    limit_req_zone $binary_remote_addr zone=api:10m rate=10r/m;
    limit_req_zone $binary_remote_addr zone=auth:10m rate=5r/m;
    
    # Frontend
    location / {
        root /root/my-best-life-platform/frontend/dist;
        try_files $uri $uri/ /index.html;
        
        # Cache static assets
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }
    
    # API routes
    location /api/ {
        limit_req zone=api burst=20 nodelay;
        proxy_pass http://localhost:3001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        
        # Timeout settings
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
    
    # Auth routes with stricter rate limiting
    location /api/auth/ {
        limit_req zone=auth burst=10 nodelay;
        proxy_pass http://localhost:3001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
    
    # Health check
    location /health {
        proxy_pass http://localhost:3001/api/health;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

ln -sf /etc/nginx/sites-available/mybestlifeapp.com /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t
systemctl restart nginx
systemctl enable nginx

print_status "Setting up SSL certificate..."
certbot --nginx -d mybestlifeapp.com -d www.mybestlifeapp.com --non-interactive --agree-tos --email admin@mybestlifeapp.com

print_status "Setting up firewall..."
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable

print_success "🎉 Deployment completed successfully!"
print_success "Your HelpMyBestLife Platform v1.2 is now live!"
print_success "Frontend: https://mybestlifeapp.com"
print_success "API: https://mybestlifeapp.com/api/health"
print_success "Backend running on PM2: mybestlife-backend"

echo ""
echo "🔒 Security Features Active:"
echo "✅ JWT Authentication with bcrypt"
echo "✅ Security Headers (CSP, HSTS, XSS protection)"
echo "✅ Rate Limiting (5 auth attempts/15min)"
echo "✅ Input Validation and sanitization"
echo "✅ CORS Security with origin validation"
echo "✅ Security Logging and audit trail"
echo "✅ SSL/TLS Encryption"
echo ""
echo "📊 Monitoring:"
echo "• PM2: pm2 status"
echo "• Logs: pm2 logs mybestlife-backend"
echo "• Nginx: systemctl status nginx"
echo ""
echo "🚀 Your VPS deployment is complete!"
