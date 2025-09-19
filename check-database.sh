#!/bin/bash

# 🔍 Check Database Connection Script
# Diagnose database and login issues

set -e

# VPS Configuration
VPS_IP="147.93.47.43"
VPS_USER="root"

echo "🔍 Checking Database Connection"
echo "==============================="
echo "VPS: $VPS_IP"
echo ""

echo "📤 Running database check on VPS..."
ssh $VPS_USER@$VPS_IP << 'EOF'
echo "🔍 Database Connection Check"
echo "============================"
echo ""

# Check PostgreSQL status
echo "📊 PostgreSQL Status:"
systemctl status postgresql --no-pager -l | head -5
echo ""

# Check if database exists
echo "🗄️ Database Check:"
sudo -u postgres psql -c "\l" | grep mybestlife || echo "Database not found"
echo ""

# Check if user exists
echo "👤 User Check:"
sudo -u postgres psql -c "\du" | grep mybestlife || echo "User not found"
echo ""

# Check backend environment
echo "🔧 Backend Environment:"
cd /root/vps-clean-deployment/backend
if [ -f ".env.production" ]; then
    echo "Environment file exists:"
    grep -E "(DATABASE_URL|NODE_ENV)" .env.production || echo "No database config found"
else
    echo "No .env.production file found"
fi
echo ""

# Check Prisma status
echo "🔍 Prisma Status:"
if command -v prisma &> /dev/null; then
    echo "Prisma CLI installed"
    npx prisma db pull --print || echo "Prisma connection failed"
else
    echo "Prisma CLI not installed"
fi
echo ""

# Check backend logs
echo "📋 Recent Backend Logs:"
pm2 logs mybestlife-backend --lines 10
echo ""

# Test API endpoints
echo "🌐 API Tests:"
curl -s http://localhost:3000/api/health | head -3 || echo "Health endpoint failed"
curl -s http://localhost:3000/api/auth/status | head -3 || echo "Auth endpoint failed"
echo ""

echo "✅ Database check complete!"
EOF

echo ""
echo "🔍 Database check complete!"
echo ""
echo "📋 Check the output above for:"
echo "1. Is PostgreSQL running?"
echo "2. Does the database exist?"
echo "3. Does the user exist?"
echo "4. Are environment variables set?"
echo "5. Is Prisma working?"
echo "6. Are API endpoints responding?"
echo ""
echo "🚀 If issues found, run the SSL/Database fix script:"
echo "./fix-ssl-and-database.sh"
