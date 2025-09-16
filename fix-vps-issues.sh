#!/bin/bash

# VPS Fix Script for My Best Life Platform
# This script will fix all identified issues step by step

echo "🔧 FIXING VPS ISSUES"
echo "===================="
echo ""

# Function to print status
print_status() {
    echo "🔄 $1"
}

print_success() {
    echo "✅ $1"
}

print_error() {
    echo "❌ $1"
}

# Step 1: Fix PostgreSQL configuration
print_status "Step 1: Fixing PostgreSQL configuration..."

# Stop PostgreSQL
systemctl stop postgresql

# Edit postgresql.conf to listen on all addresses
sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" /etc/postgresql/16/main/postgresql.conf
sed -i "s/listen_addresses = 'localhost'/listen_addresses = '*'/" /etc/postgresql/16/main/postgresql.conf

# Edit pg_hba.conf to allow connections
echo "host    all             all             127.0.0.1/32            md5" >> /etc/postgresql/16/main/pg_hba.conf
echo "host    all             all             ::1/128                 md5" >> /etc/postgresql/16/main/pg_hba.conf

# Start PostgreSQL
systemctl start postgresql
systemctl enable postgresql

print_success "PostgreSQL configuration updated!"

# Step 2: Test database connection
print_status "Step 2: Testing database connection..."

# Test connection
sudo -u postgres psql -c "SELECT version();" > /dev/null 2>&1
if [ $? -eq 0 ]; then
    print_success "Database connection successful!"
else
    print_error "Database connection failed!"
    exit 1
fi

# Step 3: Navigate to project directory
print_status "Step 3: Navigating to project directory..."
cd /var/www/mybestlife/backend

# Step 4: Install dependencies
print_status "Step 4: Installing dependencies..."
npm install

# Step 5: Generate Prisma client
print_status "Step 5: Generating Prisma client..."
npx prisma generate

# Step 6: Push database schema
print_status "Step 6: Pushing database schema..."
npx prisma db push

# Step 7: Stop existing PM2 processes
print_status "Step 7: Stopping existing PM2 processes..."
pm2 stop all
pm2 delete all

# Step 8: Start application with PM2
print_status "Step 8: Starting application with PM2..."
pm2 start app-secure.js --name "mybestlife"

# Step 9: Save PM2 configuration
print_status "Step 9: Saving PM2 configuration..."
pm2 save
pm2 startup

# Step 10: Check application status
print_status "Step 10: Checking application status..."
sleep 5
pm2 status

# Step 11: Test application endpoint
print_status "Step 11: Testing application endpoint..."
curl -f http://localhost:3000/api/health > /dev/null 2>&1
if [ $? -eq 0 ]; then
    print_success "Application is running on port 3000!"
else
    print_error "Application failed to start on port 3000!"
    echo "PM2 logs:"
    pm2 logs mybestlife --lines 20
fi

# Step 12: Set up SSL certificate
print_status "Step 12: Setting up SSL certificate..."

# Stop Nginx temporarily
systemctl stop nginx

# Get SSL certificate
certbot certonly --standalone -d mybestlifeapp.com --non-interactive --agree-tos --email testlvlup@gmail.com

# Start Nginx
systemctl start nginx

# Step 13: Test SSL
print_status "Step 13: Testing SSL certificate..."
curl -I https://mybestlifeapp.com > /dev/null 2>&1
if [ $? -eq 0 ]; then
    print_success "SSL certificate is working!"
else
    print_error "SSL certificate setup failed!"
fi

# Step 14: Final status check
print_status "Step 14: Final status check..."
echo ""
echo "📊 FINAL STATUS:"
echo "================="
echo "PostgreSQL: $(systemctl is-active postgresql)"
echo "Nginx: $(systemctl is-active nginx)"
echo "PM2: $(pm2 list | grep mybestlife | awk '{print $10}')"
echo "SSL: $(curl -I https://mybestlifeapp.com 2>&1 | grep -o 'HTTP/[0-9.]* [0-9]*' | head -1)"

echo ""
echo "🌐 TEST YOUR WEBSITE:"
echo "===================="
echo "HTTP:  http://mybestlifeapp.com"
echo "HTTPS: https://mybestlifeapp.com"

echo ""
print_success "VPS fixes completed!"
echo "Your website should now be working with SSL!"
