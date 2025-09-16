# 🔐 SECURITY CONFIGURATION GUIDE
## My Best Life Platform - Secure Environment Setup

### Environment Variables Template

Create a `.env` file in your backend directory with the following secure configuration:

```env
# ===========================================
# DATABASE CONFIGURATION
# ===========================================
DATABASE_URL="postgresql://username:password@localhost:5432/database_name"

# ===========================================
# JWT SECURITY (CRITICAL - GENERATE NEW SECRETS)
# ===========================================
# Generate secure secrets using:
# node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"
JWT_SECRET="your-super-secure-jwt-secret-key-here-minimum-64-characters"
JWT_REFRESH_SECRET="your-super-secure-refresh-secret-key-here-minimum-64-characters"
JWT_EXPIRY="7d"
JWT_REFRESH_EXPIRY="30d"

# ===========================================
# EMAIL CONFIGURATION
# ===========================================
SMTP_HOST="smtp.gmail.com"
SMTP_PORT=587
SMTP_SECURE=false
SMTP_USER="your-email@gmail.com"
SMTP_PASS="your-gmail-app-password"
SMTP_FROM_NAME="My Best Life"
SMTP_FROM_EMAIL="your-email@gmail.com"

# ===========================================
# APPLICATION CONFIGURATION
# ===========================================
NODE_ENV="production"
PORT=3000
FRONTEND_URL="https://mybestlifeapp.com"
API_BASE_URL="https://mybestlifeapp.com/api"

# ===========================================
# SECURITY CONFIGURATION
# ===========================================
# Rate limiting
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100

# Password policy
MIN_PASSWORD_LENGTH=8
REQUIRE_UPPERCASE=true
REQUIRE_LOWERCASE=true
REQUIRE_NUMBERS=true
REQUIRE_SYMBOLS=true

# Account lockout
MAX_LOGIN_ATTEMPTS=5
LOCKOUT_DURATION_MINUTES=15

# Session security
SESSION_SECRET="your-session-secret-key-here-minimum-32-characters"
COOKIE_SECURE=true
COOKIE_HTTP_ONLY=true
COOKIE_SAME_SITE="strict"

# ===========================================
# SSL/TLS CONFIGURATION
# ===========================================
SSL_CERT_PATH="/etc/ssl/certs/mybestlifeapp.com.crt"
SSL_KEY_PATH="/etc/ssl/private/mybestlifeapp.com.key"
FORCE_HTTPS=true

# ===========================================
# MONITORING & LOGGING
# ===========================================
LOG_LEVEL="info"
LOG_FILE_PATH="/var/log/mybestlife/app.log"
ENABLE_SECURITY_LOGGING=true
ENABLE_AUDIT_LOGGING=true
```

### Critical Security Steps

1. **Generate New JWT Secrets**
   ```bash
   node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"
   ```

2. **Update Database Credentials**
   - Use strong passwords (minimum 16 characters)
   - Enable SSL for database connections
   - Use least privilege access

3. **Configure Email Security**
   - Use Gmail App Passwords (not regular passwords)
   - Enable 2FA on Gmail account
   - Use secure SMTP settings

4. **Implement Rate Limiting**
   - Limit login attempts to 5 per 15 minutes
   - Limit API requests to 100 per 15 minutes
   - Implement progressive delays

5. **Enable Security Headers**
   - Content Security Policy (CSP)
   - HTTP Strict Transport Security (HSTS)
   - X-Frame-Options
   - X-Content-Type-Options

### Production Security Checklist

- [ ] Remove all hardcoded secrets
- [ ] Generate cryptographically secure JWT secrets
- [ ] Enable HTTPS with proper SSL certificates
- [ ] Implement rate limiting
- [ ] Add security headers
- [ ] Enable audit logging
- [ ] Configure firewall rules
- [ ] Set up monitoring and alerting
- [ ] Implement backup encryption
- [ ] Regular security updates
