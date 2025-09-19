#!/bin/bash

# 🧹 VPS Cleanup Script
# This script will clean up your VPS and keep only essential files

set -e

# VPS Configuration
VPS_IP="147.93.47.43"
VPS_USER="root"

echo "🧹 VPS Cleanup Script"
echo "====================="
echo "VPS: $VPS_IP"
echo ""

echo "📤 Uploading cleanup script to VPS..."
cat > vps-cleanup-remote.sh << 'EOF'
#!/bin/bash

echo "🧹 Starting VPS cleanup..."

# Stop services
pm2 stop all || true
sudo systemctl stop nginx || true

# Clean up old deployment folders
echo "Removing old deployment folders..."
sudo rm -rf /home/root/vps-deployment
sudo rm -rf /home/root/helpmybestlife*
sudo rm -rf /root/vps-deployment
sudo rm -rf /root/helpmybestlife*
sudo rm -rf /root/vps-clean-deployment*

# Clean up old backups
sudo rm -rf /root/backups
sudo rm -rf /root/complete-backup-*
sudo rm -rf /root/quick-backup-*

# Clean up old logs
sudo rm -rf /var/log/mybestlife/old-*
sudo find /var/log -name "*.log.old" -delete

# Clean up temporary files
sudo rm -rf /tmp/helpmybestlife*
sudo rm -rf /tmp/vps-*

# Clean up old node_modules (keep current ones)
find /var/www -name "node_modules" -type d -exec rm -rf {} + 2>/dev/null || true

# Clean up package archives
sudo rm -f /root/*.tar.gz
sudo rm -f /root/*.zip

# Clean up old nginx configs
sudo rm -f /etc/nginx/sites-available/helpmybestlife*
sudo rm -f /etc/nginx/sites-enabled/helpmybestlife*

# Restart services
sudo systemctl start nginx
pm2 start all || true

echo "✅ VPS cleanup complete!"
echo ""
echo "📊 Current VPS structure:"
echo "========================="
echo "Web files: /var/www/mybestlife/"
echo "Backend: /var/www/mybestlife/backend/"
echo "Logs: /var/log/mybestlife/"
echo "PM2 processes:"
pm2 list
echo ""
echo "Disk usage:"
df -h
echo ""
echo "Memory usage:"
free -h
EOF

scp vps-cleanup-remote.sh $VPS_USER@$VPS_IP:/root/

echo "🔧 Running cleanup on VPS..."
ssh $VPS_USER@$VPS_IP << 'EOF'
chmod +x vps-cleanup-remote.sh
./vps-cleanup-remote.sh
rm vps-cleanup-remote.sh
EOF

echo ""
echo "✅ VPS cleanup complete!"
echo ""
echo "📁 Your VPS now has a clean structure:"
echo "   /var/www/mybestlife/ - Web files"
echo "   /var/log/mybestlife/ - Application logs"
echo "   PM2 processes - Backend services"
echo ""
echo "🚀 Ready for fresh deployment!"
