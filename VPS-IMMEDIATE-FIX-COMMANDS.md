# 🚨 VPS IMMEDIATE FIX COMMANDS
## Run these commands on your VPS RIGHT NOW

**You're already connected to your VPS. Run these commands in order:**

---

## 🔧 IMMEDIATE FIX COMMANDS

### **1. Check your current location and find the project**
```bash
# Check where you are
pwd
ls -la

# If you don't see package.json, try these locations:
cd /var/www/mybestlife/backend
# OR
cd /var/www/html/backend
# OR
cd /home/root/mybestlife/backend

# Check if you found the right directory
ls -la
```

### **2. Generate secure secrets**
```bash
# Generate secure secrets
JWT_SECRET=$(openssl rand -hex 64)
JWT_REFRESH_SECRET=$(openssl rand -hex 64)
SESSION_SECRET=$(openssl rand -hex 32)
DB_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)

echo "Generated secrets:"
echo "JWT_SECRET: $JWT_SECRET"
echo "JWT_REFRESH_SECRET: $JWT_REFRESH_SECRET"
echo "SESSION_SECRET: $SESSION_SECRET"
echo "DB_PASSWORD: $DB_PASSWORD"
```

### **3. Create secure .env file**
```bash
# Create secure .env file
cat > .env << EOF
# My Best Life Platform - SECURE Environment Variables
# Generated on $(date)

# Database Configuration
DATABASE_URL="postgresql://mybestlife:${DB_PASSWORD}@localhost:5432/mybestlife"
DB_HOST=localhost
DB_PORT=5432
DB_NAME=mybestlife
DB_USER=mybestlife
DB_PASS=${DB_PASSWORD}

# JWT Security (CRITICAL - GENERATED SECURE SECRETS)
JWT_SECRET="${JWT_SECRET}"
JWT_REFRESH_SECRET="${JWT_REFRESH_SECRET}"
JWT_EXPIRY="7d"
JWT_REFRESH_EXPIRY="30d"

# Email Configuration (UPDATE WITH YOUR CREDENTIALS)
SMTP_HOST="smtp.gmail.com"
SMTP_PORT=587
SMTP_SECURE=false
SMTP_USER="your-email@gmail.com"
SMTP_PASS="your-gmail-app-password"
SMTP_FROM_NAME="My Best Life"
SMTP_FROM_EMAIL="your-email@gmail.com"

# Application Configuration
NODE_ENV="production"
PORT=3000
FRONTEND_URL="https://mybestlifeapp.com"
API_BASE_URL="https://mybestlifeapp.com/api"

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
SESSION_SECRET="${SESSION_SECRET}"
COOKIE_SECURE=true
COOKIE_HTTP_ONLY=true
COOKIE_SAME_SITE="strict"

# SSL/TLS Configuration
FORCE_HTTPS=true

# Monitoring & Logging
LOG_LEVEL="info"
LOG_FILE_PATH="/var/log/mybestlife/app.log"
ENABLE_SECURITY_LOGGING=true
ENABLE_AUDIT_LOGGING=true
EOF
```

### **4. Set secure permissions**
```bash
# Set secure file permissions
chmod 600 .env
mkdir -p logs
chmod 755 logs
```

### **5. Install dependencies**
```bash
# Install Node.js dependencies
npm install
```

### **6. Set up database**
```bash
# Create database and user
sudo -u postgres psql << EOF
DROP DATABASE IF EXISTS mybestlife;
DROP USER IF EXISTS mybestlife;
CREATE DATABASE mybestlife;
CREATE USER mybestlife WITH PASSWORD '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON DATABASE mybestlife TO mybestlife;
\q
EOF
```

### **7. Generate database schema**
```bash
# Generate Prisma client and push schema
npx prisma generate
npx prisma db push
```

### **8. Check what application files exist**
```bash
# Check what application files you have
ls -la *.js
```

### **9. Start the application**
```bash
# Stop any existing PM2 processes
pm2 delete all 2>/dev/null || true

# Start the application (choose the right file)
# If you have app-secure.js:
pm2 start app-secure.js --name mybestlife-secure

# OR if you have app.js:
pm2 start app.js --name mybestlife-secure

# OR if you have server.js:
pm2 start server.js --name mybestlife-secure

# OR if you have index.js:
pm2 start index.js --name mybestlife-secure

# Save PM2 configuration
pm2 save
```

### **10. Test the deployment**
```bash
# Wait for application to start
sleep 5

# Check PM2 status
pm2 status

# Test application health
curl http://localhost:3000/api/health

# Check recent logs
pm2 logs --lines 10
```

---

## ✅ SUCCESS INDICATORS

**You'll know it's working when:**
- ✅ `pm2 status` shows "online" for mybestlife-secure
- ✅ `curl http://localhost:3000/api/health` returns success
- ✅ No errors in `pm2 logs`
- ✅ Website loads at https://mybestlifeapp.com

---

## 🚨 EMERGENCY ROLLBACK

**If something breaks:**
```bash
# Restore from backup
cp .env.backup.* .env 2>/dev/null || true

# Restart application
pm2 restart mybestlife-secure
```

---

## ⚠️ IMPORTANT NEXT STEPS

**After successful deployment:**
1. **Update email credentials**: `nano .env`
2. **Test website**: https://mybestlifeapp.com
3. **Monitor logs**: `pm2 logs`

---

**🛡️ YOUR VPS WILL BE SECURE AFTER RUNNING THESE COMMANDS!**
