#!/bin/bash

# 🚨 Emergency VPS Diagnostic Script
# Check what's wrong with your website

set -e

# VPS Configuration
VPS_IP="147.93.47.43"
VPS_USER="root"

echo "🚨 Emergency VPS Diagnostic"
echo "============================"
echo "VPS: $VPS_IP"
echo ""

echo "📤 Running diagnostic on VPS..."
ssh $VPS_USER@$VPS_IP << 'EOF'
echo "🔍 VPS Diagnostic Report"
echo "========================"
echo ""

echo "📊 System Status:"
echo "-----------------"
echo "Uptime: $(uptime)"
echo "Disk usage:"
df -h
echo ""
echo "Memory usage:"
free -h
echo ""

echo "🌐 Nginx Status:"
echo "---------------"
systemctl status nginx --no-pager -l || echo "Nginx not running!"
echo ""

echo "🔧 PM2 Status:"
echo "--------------"
pm2 list || echo "PM2 not running!"
echo ""

echo "📁 Web Directory Check:"
echo "----------------------"
ls -la /var/www/mybestlife/ || echo "Web directory doesn't exist!"
echo ""

echo "🔗 Port Status:"
echo "--------------"
netstat -tlnp | grep -E ":(80|443|3000)" || echo "No services listening on web ports!"
echo ""

echo "📋 Nginx Configuration:"
echo "----------------------"
nginx -t || echo "Nginx config has errors!"
echo ""

echo "🔍 Recent Logs:"
echo "-------------"
echo "Nginx error log (last 10 lines):"
tail -10 /var/log/nginx/error.log 2>/dev/null || echo "No nginx error log"
echo ""
echo "PM2 logs (last 10 lines):"
pm2 logs --lines 10 2>/dev/null || echo "No PM2 logs"
echo ""

echo "🌐 Test Local Connections:"
echo "-------------------------"
curl -I http://localhost:3000/api/health 2>/dev/null || echo "Backend not responding on port 3000"
curl -I http://localhost 2>/dev/null || echo "Nginx not responding on port 80"
echo ""

echo "🔧 Service Restart Test:"
echo "-----------------------"
echo "Attempting to restart services..."
systemctl restart nginx
pm2 restart all || pm2 start all
echo "Services restarted!"
echo ""

echo "✅ Diagnostic complete!"
EOF

echo ""
echo "🔍 Running external connectivity test..."
curl -I http://$VPS_IP || echo "VPS not accessible from outside"
curl -I https://$VPS_IP || echo "HTTPS not accessible from outside"

echo ""
echo "🌐 Testing domain..."
curl -I http://mybestlifeapp.com || echo "Domain not accessible"
curl -I https://mybestlifeapp.com || echo "HTTPS domain not accessible"

echo ""
echo "📋 Diagnostic Summary:"
echo "===================="
echo "Check the output above for:"
echo "1. Are nginx and PM2 running?"
echo "2. Are the web ports (80, 443, 3000) listening?"
echo "3. Are there any error messages in logs?"
echo "4. Is the web directory populated?"
echo "5. Can you connect to the VPS externally?"
echo ""
echo "🚨 If services are down, run the emergency fix script!"
