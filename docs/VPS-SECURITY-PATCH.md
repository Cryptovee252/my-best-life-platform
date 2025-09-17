# 🚨 IMMEDIATE VPS SECURITY PATCH
## Critical Security Files for Live Server Deployment

**URGENT**: Deploy these files to your VPS immediately to fix critical vulnerabilities.

---

## 🔥 CRITICAL FILES TO DEPLOY

### 1. **Secure Environment File** (`.env`)
```env
# CRITICAL: Replace with your actual values
DB_HOST=localhost
DB_NAME=your_actual_database_name
DB_USER=your_actual_username
DB_PASS=your_actual_secure_password
DB_PORT=3306

# SECURE JWT SECRET (64 characters)
JWT_SECRET=a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0u1v2w3x4y5z6a7b8c9d0e1f2g3h4i5j6k7l8m9n0o1p2q3r4s5t6u7v8w9x0y1z2

# Email Configuration
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-gmail@gmail.com
SMTP_PASS=your-gmail-app-password
SMTP_FROM_NAME=My Best Life
SMTP_FROM_EMAIL=your-gmail@gmail.com

# Application Settings
APP_NAME=My Best Life
APP_VERSION=1.0.0
APP_ENV=production
FRONTEND_URL=https://mybestlifeapp.com

# Security Settings
JWT_EXPIRY=86400
VERIFICATION_EXPIRY=86400
RESET_EXPIRY=3600
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=5
RATE_LIMIT_MAX_API_REQUESTS=100
MIN_PASSWORD_LENGTH=8
REQUIRE_UPPERCASE=true
REQUIRE_LOWERCASE=true
REQUIRE_NUMBERS=true
REQUIRE_SYMBOLS=true
MAX_LOGIN_ATTEMPTS=5
LOCKOUT_DURATION_MINUTES=15
SESSION_SECRET=a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0u1v2w3x4y5z6
COOKIE_SECURE=true
COOKIE_HTTP_ONLY=true
COOKIE_SAME_SITE=strict
FORCE_HTTPS=true
ENABLE_SECURITY_LOGGING=true
ENABLE_AUDIT_LOGGING=true
```

### 2. **Secure Apache Configuration** (`.htaccess`)
```apache
# Security Headers
<IfModule mod_headers.c>
    Header always set Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; font-src 'self'; connect-src 'self'; frame-ancestors 'none';"
    Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
    Header always set X-Frame-Options "DENY"
    Header always set X-Content-Type-Options "nosniff"
    Header always set X-XSS-Protection "1; mode=block"
    Header always set Referrer-Policy "strict-origin-when-cross-origin"
    Header always set Permissions-Policy "geolocation=(), microphone=(), camera=()"
    Header unset Server
    Header unset X-Powered-By
</IfModule>

# Force HTTPS
<IfModule mod_rewrite.c>
    RewriteEngine On
    RewriteCond %{HTTPS} off
    RewriteRule ^(.*)$ https://%{HTTP_HOST}%{REQUEST_URI} [L,R=301]
</IfModule>

# Block sensitive files
<Files ".env">
    Order allow,deny
    Deny from all
</Files>
<Files ".git">
    Order allow,deny
    Deny from all
</Files>
<Files "composer.json">
    Order allow,deny
    Deny from all
</Files>
```

---

## 🚀 DEPLOYMENT INSTRUCTIONS

### **Step 1: Connect to Your VPS**
```bash
# SSH into your VPS
ssh your-username@your-vps-ip
```

### **Step 2: Navigate to Your Website Directory**
```bash
# Find your website directory (usually one of these)
cd /var/www/html
# OR
cd /var/www/mybestlifeapp.com
# OR
cd /home/your-username/public_html
```

### **Step 3: Create Secure Environment File**
```bash
# Create .env file with secure values
nano .env
# Paste the .env content above and edit with your actual values
```

### **Step 4: Update Your PHP Configuration**
```bash
# Backup current config.php
cp config.php config.php.backup

# Update config.php to use environment variables
nano config.php
```

### **Step 5: Add Security Headers**
```bash
# Create .htaccess file
nano .htaccess
# Paste the .htaccess content above
```

### **Step 6: Set Secure Permissions**
```bash
chmod 600 .env
chmod 644 .htaccess
chmod 755 logs/
```

### **Step 7: Test the Changes**
```bash
# Test PHP syntax
php -l config.php

# Check if website loads
curl -I https://mybestlifeapp.com
```

---

## ⚠️ CRITICAL NOTES

1. **Replace JWT_SECRET**: Generate a new 64-character secret
2. **Update Database Credentials**: Use your actual database details
3. **Configure Email**: Set up your Gmail app password
4. **Test Functionality**: Ensure login/registration still works
5. **Monitor Logs**: Check for any errors after deployment

---

## 🔧 QUICK SECRET GENERATION

```bash
# Generate secure JWT secret (run this on your VPS)
php -r "echo 'JWT_SECRET=' . bin2hex(random_bytes(32)) . PHP_EOL;"
```

---

## 📞 EMERGENCY ROLLBACK

If something breaks:
```bash
# Restore backup
cp config.php.backup config.php

# Remove .env if causing issues
rm .env

# Restart web server
sudo systemctl restart apache2
# OR
sudo systemctl restart nginx
```

---

**DEPLOY IMMEDIATELY TO SECURE YOUR LIVE SITE!**
