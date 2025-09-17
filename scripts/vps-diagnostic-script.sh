#!/bin/bash

# 🔍 VPS DIAGNOSTIC SCRIPT
# Run this on your VPS to check security status and identify issues

echo "🔍 VPS SECURITY DIAGNOSTIC REPORT"
echo "=================================="
echo "Date: $(date)"
echo "VPS: $(hostname)"
echo ""

# Check system status
echo "📊 SYSTEM STATUS:"
echo "-----------------"
echo "Uptime: $(uptime)"
echo "Load: $(cat /proc/loadavg)"
echo "Memory: $(free -h | grep Mem)"
echo "Disk: $(df -h / | tail -1)"
echo ""

# Check services
echo "🔧 SERVICES STATUS:"
echo "-------------------"
systemctl is-active nginx && echo "✅ Nginx: Running" || echo "❌ Nginx: Not running"
systemctl is-active postgresql && echo "✅ PostgreSQL: Running" || echo "❌ PostgreSQL: Not running"
systemctl is-active apache2 && echo "✅ Apache2: Running" || echo "❌ Apache2: Not running"
echo ""

# Check PM2 status
echo "📱 PM2 APPLICATION STATUS:"
echo "-------------------------"
if command -v pm2 &> /dev/null; then
    pm2 status
else
    echo "❌ PM2 not installed"
fi
echo ""

# Check project directory
echo "📁 PROJECT DIRECTORY STATUS:"
echo "----------------------------"
PROJECT_DIR="/var/www/mybestlife/backend"
if [ -d "$PROJECT_DIR" ]; then
    echo "✅ Project directory exists: $PROJECT_DIR"
    cd "$PROJECT_DIR"
    
    # Check .env file
    if [ -f ".env" ]; then
        echo "✅ .env file exists"
        echo "📝 .env file permissions: $(ls -la .env)"
        
        # Check for hardcoded secrets
        if grep -q "mybestlife-super-secret" .env 2>/dev/null; then
            echo "❌ CRITICAL: Hardcoded JWT secret found in .env!"
        else
            echo "✅ No hardcoded secrets in .env"
        fi
        
        # Check JWT secret
        if grep -q "JWT_SECRET=" .env && ! grep -q "JWT_SECRET=\"\"" .env; then
            echo "✅ JWT_SECRET is configured"
        else
            echo "❌ CRITICAL: JWT_SECRET is not properly configured!"
        fi
    else
        echo "❌ CRITICAL: .env file missing!"
    fi
    
    # Check config.php
    if [ -f "config.php" ]; then
        echo "✅ config.php exists"
        
        # Check for hardcoded secrets in config.php
        if grep -q "mybestlife-super-secret" config.php 2>/dev/null; then
            echo "❌ CRITICAL: Hardcoded JWT secret found in config.php!"
        else
            echo "✅ No hardcoded secrets in config.php"
        fi
    else
        echo "❌ CRITICAL: config.php missing!"
    fi
    
    # Check package.json
    if [ -f "package.json" ]; then
        echo "✅ package.json exists"
    else
        echo "❌ package.json missing"
    fi
    
    # Check node_modules
    if [ -d "node_modules" ]; then
        echo "✅ node_modules exists"
    else
        echo "❌ node_modules missing - run 'npm install'"
    fi
    
else
    echo "❌ Project directory not found: $PROJECT_DIR"
fi
echo ""

# Check database
echo "🗄️ DATABASE STATUS:"
echo "-------------------"
if command -v psql &> /dev/null; then
    if sudo -u postgres psql -c "\l" | grep -q "mybestlife"; then
        echo "✅ mybestlife database exists"
    else
        echo "❌ mybestlife database missing"
    fi
    
    if sudo -u postgres psql -c "\du" | grep -q "mybestlife"; then
        echo "✅ mybestlife user exists"
    else
        echo "❌ mybestlife user missing"
    fi
else
    echo "❌ PostgreSQL not installed"
fi
echo ""

# Check SSL certificate
echo "🔒 SSL CERTIFICATE STATUS:"
echo "--------------------------"
if command -v certbot &> /dev/null; then
    if [ -f "/etc/letsencrypt/live/mybestlifeapp.com/fullchain.pem" ]; then
        echo "✅ SSL certificate exists"
        echo "📅 Certificate expiry: $(openssl x509 -in /etc/letsencrypt/live/mybestlifeapp.com/fullchain.pem -noout -dates | grep notAfter)"
    else
        echo "❌ SSL certificate missing"
    fi
else
    echo "❌ Certbot not installed"
fi
echo ""

# Check firewall
echo "🔥 FIREWALL STATUS:"
echo "-------------------"
if command -v ufw &> /dev/null; then
    ufw status
else
    echo "❌ UFW firewall not installed"
fi
echo ""

# Check application logs
echo "📋 RECENT APPLICATION LOGS:"
echo "--------------------------"
if [ -f "$PROJECT_DIR/logs/app.log" ]; then
    echo "Last 10 lines of app.log:"
    tail -10 "$PROJECT_DIR/logs/app.log"
else
    echo "❌ Application log file not found"
fi
echo ""

# Check PM2 logs
echo "📋 RECENT PM2 LOGS:"
echo "-------------------"
if command -v pm2 &> /dev/null; then
    pm2 logs --lines 5
else
    echo "❌ PM2 not available"
fi
echo ""

# Check website accessibility
echo "🌐 WEBSITE ACCESSIBILITY:"
echo "-------------------------"
if curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/api/health | grep -q "200"; then
    echo "✅ Application health check: OK"
else
    echo "❌ Application health check: FAILED"
fi

if curl -s -o /dev/null -w "%{http_code}" https://mybestlifeapp.com | grep -q "200\|301\|302"; then
    echo "✅ Website accessibility: OK"
else
    echo "❌ Website accessibility: FAILED"
fi
echo ""

# Security recommendations
echo "🛡️ SECURITY RECOMMENDATIONS:"
echo "-----------------------------"
echo "1. Ensure .env file has secure JWT secrets"
echo "2. Update email credentials in .env file"
echo "3. Test login/registration functionality"
echo "4. Monitor application logs for errors"
echo "5. Verify SSL certificate is valid"
echo "6. Check firewall rules are properly configured"
echo ""

echo "🎯 NEXT STEPS:"
echo "-------------"
echo "1. If any ❌ issues found, address them immediately"
echo "2. Update email credentials: nano $PROJECT_DIR/.env"
echo "3. Test website: https://mybestlifeapp.com"
echo "4. Monitor logs: pm2 logs"
echo ""

echo "🔍 DIAGNOSTIC COMPLETE!"
echo "======================="