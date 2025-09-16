#!/bin/bash

# VPS Diagnostic Script for My Best Life Platform
# This script will check all services and provide detailed information

echo "🔍 VPS DIAGNOSTIC REPORT"
echo "========================="
echo ""

echo "📅 Date: $(date)"
echo "🖥️  Server: $(hostname)"
echo ""

echo "🔧 POSTGRESQL STATUS"
echo "-------------------"
echo "1. PostgreSQL service status:"
systemctl status postgresql --no-pager -l

echo ""
echo "2. Available PostgreSQL clusters:"
ls /etc/postgresql/ 2>/dev/null || echo "No PostgreSQL clusters found"

echo ""
echo "3. PostgreSQL processes:"
ps aux | grep postgres | grep -v grep

echo ""
echo "4. PostgreSQL listening ports:"
netstat -tlnp | grep postgres

echo ""
echo "5. PostgreSQL configuration:"
if [ -d /etc/postgresql ]; then
    for version in /etc/postgresql/*; do
        if [ -d "$version" ]; then
            echo "Version: $(basename $version)"
            cat "$version/main/postgresql.conf" | grep -E "^(port|listen_addresses)" 2>/dev/null || echo "Config not found"
        fi
    done
fi

echo ""
echo "🌐 NGINX STATUS"
echo "---------------"
echo "1. Nginx service status:"
systemctl status nginx --no-pager -l

echo ""
echo "2. Nginx listening ports:"
netstat -tlnp | grep nginx

echo ""
echo "3. Nginx configuration test:"
nginx -t 2>&1

echo ""
echo "📱 APPLICATION STATUS"
echo "--------------------"
echo "1. PM2 status:"
pm2 status 2>/dev/null || echo "PM2 not running"

echo ""
echo "2. Application processes:"
ps aux | grep node | grep -v grep

echo ""
echo "3. Application listening ports:"
netstat -tlnp | grep :3000

echo ""
echo "🔒 FIREWALL STATUS"
echo "-----------------"
echo "1. UFW status:"
ufw status 2>/dev/null || echo "UFW not configured"

echo ""
echo "2. Listening ports:"
netstat -tlnp | grep LISTEN

echo ""
echo "📁 PROJECT FILES"
echo "---------------"
echo "1. Project directory:"
ls -la /var/www/mybestlife/ 2>/dev/null || echo "Project directory not found"

echo ""
echo "2. Backend directory:"
ls -la /var/www/mybestlife/backend/ 2>/dev/null || echo "Backend directory not found"

echo ""
echo "3. Environment file:"
if [ -f /var/www/mybestlife/backend/.env ]; then
    echo "✅ .env file exists"
    echo "Database URL: $(grep DATABASE_URL /var/www/mybestlife/backend/.env | head -1)"
else
    echo "❌ .env file not found"
fi

echo ""
echo "🗄️ DATABASE CONNECTION TEST"
echo "---------------------------"
echo "1. Test PostgreSQL connection:"
sudo -u postgres psql -c "SELECT version();" 2>&1 || echo "❌ PostgreSQL connection failed"

echo ""
echo "2. Test database exists:"
sudo -u postgres psql -c "\l" 2>&1 | grep mybestlife || echo "❌ mybestlife database not found"

echo ""
echo "3. Test user exists:"
sudo -u postgres psql -c "\du" 2>&1 | grep mybestlife || echo "❌ mybestlife user not found"

echo ""
echo "🌍 DOMAIN TEST"
echo "-------------"
echo "1. Domain resolution:"
nslookup mybestlifeapp.com 2>&1 || echo "❌ Domain resolution failed"

echo ""
echo "2. HTTP test:"
curl -I http://mybestlifeapp.com 2>&1 || echo "❌ HTTP connection failed"

echo ""
echo "3. HTTPS test:"
curl -I https://mybestlifeapp.com 2>&1 || echo "❌ HTTPS connection failed"

echo ""
echo "📋 SUMMARY"
echo "---------"
echo "✅ Services that are working:"
systemctl is-active postgresql >/dev/null 2>&1 && echo "  - PostgreSQL service"
systemctl is-active nginx >/dev/null 2>&1 && echo "  - Nginx service"
pm2 list >/dev/null 2>&1 && echo "  - PM2 process manager"

echo ""
echo "❌ Issues found:"
systemctl is-active postgresql >/dev/null 2>&1 || echo "  - PostgreSQL service not running"
systemctl is-active nginx >/dev/null 2>&1 || echo "  - Nginx service not running"
pm2 list >/dev/null 2>&1 || echo "  - PM2 not running"

echo ""
echo "🔧 NEXT STEPS"
echo "------------"
echo "1. Fix PostgreSQL cluster startup"
echo "2. Configure database connection"
echo "3. Start application with PM2"
echo "4. Set up SSL certificate"
echo "5. Test website functionality"

echo ""
echo "📝 END OF DIAGNOSTIC REPORT"
echo "============================"
