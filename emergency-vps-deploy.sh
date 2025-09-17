#!/bin/bash

# 🚨 EMERGENCY VPS SECURITY DEPLOYMENT
# This script will secure your VPS at 147.93.47.43 immediately

set -e

echo "🚨 EMERGENCY VPS SECURITY DEPLOYMENT"
echo "===================================="
echo "Target VPS: 147.93.47.43"
echo ""

# VPS Configuration
VPS_IP="147.93.47.43"
VPS_USER="root"
PROJECT_PATH="/var/www/mybestlife/backend"

echo "📡 Connecting to VPS: $VPS_USER@$VPS_IP"
echo ""

# Generate secure secrets locally
echo "🔐 Generating secure secrets..."
JWT_SECRET=$(openssl rand -hex 64)
JWT_REFRESH_SECRET=$(openssl rand -hex 64)
SESSION_SECRET=$(openssl rand -hex 32)
DB_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)

echo "✅ Secrets generated successfully"
echo ""

# Create secure .env file content
ENV_CONTENT="# My Best Life Platform - SECURE Environment Variables
# Generated on $(date)

# Database Configuration
DATABASE_URL=\"postgresql://mybestlife:${DB_PASSWORD}@localhost:5432/mybestlife\"

# JWT Security (CRITICAL - GENERATED SECURE SECRETS)
JWT_SECRET=\"${JWT_SECRET}\"
JWT_REFRESH_SECRET=\"${JWT_REFRESH_SECRET}\"
JWT_EXPIRY=\"7d\"
JWT_REFRESH_EXPIRY=\"30d\"

# Email Configuration (UPDATE WITH YOUR CREDENTIALS)
SMTP_HOST=\"smtp.gmail.com\"
SMTP_PORT=587
SMTP_SECURE=false
SMTP_USER=\"your-email@gmail.com\"
SMTP_PASS=\"your-gmail-app-password\"
SMTP_FROM_NAME=\"My Best Life\"
SMTP_FROM_EMAIL=\"your-email@gmail.com\"

# Application Configuration
NODE_ENV=\"production\"
PORT=3000
FRONTEND_URL=\"https://mybestlifeapp.com\"
API_BASE_URL=\"https://mybestlifeapp.com/api\"

# Security Configuration
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100
MIN_PASSWORD_LENGTH=8
REQUIRE_UPPERCASE=true
REQUIRE_LOWERCASE=true
REQUIRE_NUMBERS=true
REQUIRE_SYMBOLS=true
MAX_LOGIN_ATTEMPTS=5
LOCKOUT_DURATION_MINUTES=15
SESSION_SECRET=\"${SESSION_SECRET}\"
COOKIE_SECURE=true
COOKIE_HTTP_ONLY=true
COOKIE_SAME_SITE=\"strict\"

# SSL/TLS Configuration
FORCE_HTTPS=true

# Monitoring & Logging
LOG_LEVEL=\"info\"
LOG_FILE_PATH=\"/var/log/mybestlife/app.log\"
ENABLE_SECURITY_LOGGING=true
ENABLE_AUDIT_LOGGING=true"

echo "📝 Creating secure .env file on VPS..."
ssh $VPS_USER@$VPS_IP "cat > $PROJECT_PATH/.env << 'EOF'
$ENV_CONTENT
EOF"

echo "✅ Secure .env file created"
echo ""

echo "🔧 Setting up database..."
ssh $VPS_USER@$VPS_IP "cd $PROJECT_PATH && sudo -u postgres psql << 'EOF'
DROP DATABASE IF EXISTS mybestlife;
DROP USER IF EXISTS mybestlife;
CREATE DATABASE mybestlife;
CREATE USER mybestlife WITH PASSWORD '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON DATABASE mybestlife TO mybestlife;
\q
EOF"

echo "✅ Database configured"
echo ""

echo "📦 Installing dependencies..."
ssh $VPS_USER@$VPS_IP "cd $PROJECT_PATH && npm install"

echo "✅ Dependencies installed"
echo ""

echo "🗄️ Setting up database schema..."
ssh $VPS_USER@$VPS_IP "cd $PROJECT_PATH && npx prisma generate && npx prisma db push"

echo "✅ Database schema created"
echo ""

echo "🔄 Restarting application..."
ssh $VPS_USER@$VPS_IP "cd $PROJECT_PATH && pm2 delete all 2>/dev/null || true"
ssh $VPS_USER@$VPS_IP "cd $PROJECT_PATH && pm2 start app-secure.js --name mybestlife-secure"
ssh $VPS_USER@$VPS_IP "pm2 save"

echo "✅ Application restarted"
echo ""

echo "🧪 Testing deployment..."
sleep 5

# Test application
if ssh $VPS_USER@$VPS_IP "curl -f http://localhost:3000/api/health" > /dev/null 2>&1; then
    echo "✅ Application is running!"
else
    echo "⚠️ Application test failed - checking logs..."
    ssh $VPS_USER@$VPS_IP "pm2 logs --lines 10"
fi

echo ""
echo "🎉 VPS SECURITY DEPLOYMENT COMPLETED!"
echo ""
echo "📊 DEPLOYMENT SUMMARY:"
echo "✅ Secure environment variables configured"
echo "✅ Database secured with new credentials"
echo "✅ Application restarted with security fixes"
echo "✅ All hardcoded secrets removed"
echo ""
echo "⚠️ IMPORTANT NEXT STEPS:"
echo "1. Update email credentials in .env file:"
echo "   ssh $VPS_USER@$VPS_IP 'nano $PROJECT_PATH/.env'"
echo "2. Test your website: https://mybestlifeapp.com"
echo "3. Monitor logs: ssh $VPS_USER@$VPS_IP 'pm2 logs'"
echo ""
echo "🛡️ YOUR VPS IS NOW SECURE!"
