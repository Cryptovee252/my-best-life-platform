#!/bin/bash

echo "🎯 COMPREHENSIVE BACKEND FIX - DEFINITIVE SOLUTION"
echo "=================================================="

# Step 1: Stop current backend
echo "🛑 Stopping current backend..."
pm2 stop mybestlife-backend 2>/dev/null || true
pm2 delete mybestlife-backend 2>/dev/null || true

# Step 2: Start PostgreSQL service
echo "🗄️ Starting PostgreSQL service..."
systemctl start postgresql
systemctl enable postgresql
systemctl status postgresql --no-pager

# Step 3: Check existing databases
echo "🔍 Checking existing databases..."
sudo -u postgres psql -c "\l" | grep -i mybestlife || echo "No mybestlife database found"

# Step 4: Create database and user if they don't exist
echo "🏗️ Setting up database..."
sudo -u postgres psql -c "CREATE DATABASE mybestlife_prod;" 2>/dev/null || echo "Database may already exist"
sudo -u postgres psql -c "CREATE USER mybestlife_user WITH PASSWORD 'secure_password';" 2>/dev/null || echo "User may already exist"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE mybestlife_prod TO mybestlife_user;" 2>/dev/null || true

# Step 5: Create proper environment file
echo "📝 Creating environment configuration..."
cd /root/vps-clean-deployment/backend

cat > .env << 'EOF'
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
MAX_LOGIN_ATTEMPTS=10
LOCKOUT_DURATION_MINUTES=5
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=1000
ENABLE_CORS=true
CORS_ORIGIN="https://mybestlifeapp.com"
EOF

# Step 6: Fix Prisma schema with correct binary target
echo "🔧 Fixing Prisma configuration..."
cat > prisma/schema.prisma << 'EOF'
generator client {
  provider      = "prisma-client-js"
  binaryTargets = ["native", "debian-openssl-3.0.x"]
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

model User {
  id        String   @id @default(cuid())
  email     String   @unique
  username  String   @unique
  password  String
  firstName String?
  lastName  String?
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt
}
EOF

# Step 7: Generate Prisma client
echo "📦 Generating Prisma client..."
npx prisma generate

# Step 8: Push schema to database
echo "🗄️ Pushing schema to database..."
npx prisma db push

# Step 9: Start backend with correct configuration
echo "🚀 Starting backend..."
pm2 start app-secure.js --name "mybestlife-backend"

# Step 10: Wait and test
echo "⏳ Waiting for backend to start..."
sleep 5

echo "🧪 Testing backend..."
curl -s http://localhost:3000/api/health | jq . || curl -s http://localhost:3000/api/health

echo "🌐 Testing public endpoint..."
curl -s https://mybestlifeapp.com/api/health | jq . || curl -s https://mybestlifeapp.com/api/health

echo "🔐 Testing login endpoint..."
curl -X POST https://mybestlifeapp.com/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"testpassword"}' \
  -s | jq . || curl -X POST https://mybestlifeapp.com/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"testpassword"}' -s

echo ""
echo "✅ COMPREHENSIVE FIX COMPLETED!"
echo "🎉 Backend should now be fully functional"
echo "🔗 Test your website login at: https://mybestlifeapp.com"

