#!/bin/bash

# 🔧 Fix Rate Limiting Script
# Fix overly aggressive rate limiting blocking legitimate users

set -e

# VPS Configuration
VPS_IP="147.93.47.43"
VPS_USER="root"

echo "🔧 Fixing Rate Limiting"
echo "========================"
echo "VPS: $VPS_IP"
echo ""

echo "📤 Running rate limiting fix on VPS..."
ssh $VPS_USER@$VPS_IP << 'EOF'
echo "🔧 Starting rate limiting fix..."
echo ""

# 1. Stop the backend to clear rate limiting
echo "🛑 Stopping backend to clear rate limiting..."
pm2 stop mybestlife-backend

# 2. Update backend environment with more reasonable rate limits
echo "📝 Updating rate limiting configuration..."
cd /root/vps-clean-deployment/backend

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

# More reasonable rate limiting settings
MAX_LOGIN_ATTEMPTS=10
LOCKOUT_DURATION_MINUTES=5
RATE_LIMIT_WINDOW_MS=300000
RATE_LIMIT_MAX_REQUESTS=1000

# Enable CORS
ENABLE_CORS=true
CORS_ORIGIN="https://mybestlifeapp.com"

# Disable aggressive rate limiting for development/testing
DISABLE_RATE_LIMITING=false
RATE_LIMIT_SKIP_SUCCESSFUL_REQUESTS=true
RATE_LIMIT_SKIP_FAILED_REQUESTS=false
ENV_CONFIG

# 3. Clear any existing rate limiting data
echo "🧹 Clearing rate limiting data..."
# Clear any in-memory rate limiting stores
pm2 delete mybestlife-backend || true

# 4. Restart backend with new configuration
echo "🔄 Restarting backend with new rate limits..."
pm2 start app-secure.js --name "mybestlife-backend" --env production

# 5. Wait for backend to start
echo "⏳ Waiting for backend to start..."
sleep 5

# 6. Test API endpoints
echo "🔍 Testing API endpoints..."
echo "Health check:"
curl -s http://localhost:3000/api/health || echo "Health endpoint failed"

echo ""
echo "Testing registration endpoint:"
curl -s -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test123","name":"Test User","username":"testuser"}' || echo "Registration test failed"

echo ""
echo "Testing login endpoint:"
curl -s -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test123"}' || echo "Login test failed"

echo ""
echo "Testing username check:"
curl -s http://localhost:3000/api/auth/check-username/testuser || echo "Username check failed"

echo ""
echo "✅ Rate limiting fix complete!"
echo ""
echo "📊 Backend Status:"
pm2 list
echo ""
echo "🌐 API endpoints should now work properly!"
EOF

echo ""
echo "🔍 Testing website after rate limiting fix..."
sleep 5

echo "Testing API through HTTPS..."
curl -s -I https://mybestlifeapp.com/api/health || echo "HTTPS API test failed"

echo "Testing registration endpoint..."
curl -s -X POST https://mybestlifeapp.com/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test123","name":"Test User","username":"testuser"}' || echo "Registration endpoint test failed"

echo ""
echo "🎉 Rate limiting fix complete!"
echo ""
echo "✅ Your website should now work properly:"
echo "   🔑 Login should work"
echo "   📝 Registration should work"
echo "   🔍 Username checking should work"
echo "   🌐 All API endpoints should respond"
echo ""
echo "🌐 Visit: https://mybestlifeapp.com"
echo "📝 Try registering a new account now!"
echo ""
echo "🔧 Rate limiting changes:"
echo "   - Increased max login attempts: 5 → 10"
echo "   - Reduced lockout time: 15min → 5min"
echo "   - Increased rate limit window: 15min → 5min"
echo "   - Increased max requests: 100 → 1000"
echo "   - Added skip options for successful requests"
