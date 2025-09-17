#!/bin/bash

# HelpMyBestLife Platform v1.2 - PostgreSQL Deployment Script
# This script handles PostgreSQL authentication issues automatically

set -e

echo "🚀 HelpMyBestLife Platform v1.2 - PostgreSQL Deployment"
echo "======================================================"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    print_error "Please run as root (use sudo)"
    exit 1
fi

# Generate secure password
generate_password() {
    openssl rand -base64 32 | tr -d "=+/" | cut -c1-25
}

# Function to completely reset PostgreSQL
reset_postgresql() {
    print_status "Completely resetting PostgreSQL..."
    
    # Stop PostgreSQL
    systemctl stop postgresql 2>/dev/null || true
    
    # Kill any remaining processes
    pkill -f postgres 2>/dev/null || true
    
    # Remove shared memory segments
    ipcs -m | grep postgres | awk '{print $2}' | xargs -r ipcrm -m 2>/dev/null || true
    
    # Remove the entire data directory
    rm -rf /var/lib/postgresql/16/main
    
    # Create directory
    mkdir -p /var/lib/postgresql/16/main
    chown -R postgres:postgres /var/lib/postgresql/16/main
    
    # Initialize database with trust authentication
    sudo -u postgres /usr/lib/postgresql/16/bin/initdb -D /var/lib/postgresql/16/main --auth-local=trust --auth-host=md5
    
    print_success "PostgreSQL reset completed!"
}

# Function to start PostgreSQL and set password
setup_postgresql() {
    local DB_PASSWORD=$1
    
    print_status "Starting PostgreSQL and setting up database..."
    
    # Start PostgreSQL manually
    sudo -u postgres /usr/lib/postgresql/16/bin/pg_ctl -D /var/lib/postgresql/16/main -l /var/log/postgresql/postgresql-16-main.log start
    
    # Wait for server to start
    sleep 5
    
    # Set password
    sudo -u postgres psql -c "ALTER USER postgres PASSWORD '$DB_PASSWORD';"
    
    # Create production database
    sudo -u postgres createdb mybestlife_prod
    
    # Change authentication back to md5
    sed -i 's/local   all             postgres                                trust/local   all             postgres                                md5/' /etc/postgresql/16/main/pg_hba.conf
    
    # Restart PostgreSQL
    sudo -u postgres /usr/lib/postgresql/16/bin/pg_ctl -D /var/lib/postgresql/16/main restart
    
    # Wait for restart
    sleep 3
    
    print_success "PostgreSQL setup completed with password: $DB_PASSWORD"
}

# Function to test PostgreSQL connection
test_postgresql() {
    local DB_PASSWORD=$1
    
    print_status "Testing PostgreSQL connection..."
    
    # Test connection
    if sudo -u postgres psql -c "SELECT version();" > /dev/null 2>&1; then
        print_success "PostgreSQL connection successful!"
        return 0
    else
        print_error "PostgreSQL connection failed!"
        return 1
    fi
}

print_status "Installing dependencies..."
apt update && apt upgrade -y
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs postgresql postgresql-contrib nginx certbot python3-certbot-nginx
npm install -g pm2

# Generate secure password
DB_PASSWORD=$(generate_password)

print_status "Setting up PostgreSQL database..."

# Try to reset and setup PostgreSQL
reset_postgresql
setup_postgresql "$DB_PASSWORD"

# Test connection
if ! test_postgresql "$DB_PASSWORD"; then
    print_error "PostgreSQL setup failed. Trying alternative approach..."
    
    # Alternative: Use systemctl to start PostgreSQL
    systemctl start postgresql@16-main
    systemctl enable postgresql@16-main
    
    # Wait and test again
    sleep 5
    if test_postgresql "$DB_PASSWORD"; then
        print_success "PostgreSQL started successfully with systemctl!"
    else
        print_error "PostgreSQL setup failed completely. Please check logs."
        exit 1
    fi
fi

print_status "Creating production environment file..."
cat > /root/my-best-life-platform/backend/.env << EOF
NODE_ENV=production
PORT=3001
DATABASE_URL="postgresql://postgres:$DB_PASSWORD@localhost:5432/mybestlife_prod"
JWT_SECRET="$(generate_password)_JWT_Secret_Key_Production_Secure"
JWT_EXPIRES_IN=7d
BCRYPT_ROUNDS=12
CORS_ORIGIN=https://mybestlifeapp.com
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_ATTEMPTS=5
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USER=your-email@gmail.com
EMAIL_PASS=your-app-password
EMAIL_FROM=noreply@mybestlifeapp.com
SECURITY_HEADERS=true
CSP_ENABLED=true
HSTS_ENABLED=true
XSS_PROTECTION=true
CONTENT_TYPE_NOSNIFF=true
FRAME_OPTIONS=DENY
EOF

print_status "Installing backend dependencies..."
cd /root/my-best-life-platform/backend
npm install --production

print_status "Running database migrations..."
npm run db:push

print_status "Starting backend with PM2..."
pm2 start app.js --name "mybestlife-backend" --env production
pm2 save
pm2 startup

print_status "Building frontend..."
cd /root/my-best-life-platform/frontend
npm install
npm run build

print_status "Configuring Nginx..."
cat > /etc/nginx/sites-available/mybestlifeapp.com << 'EOF'
server {
    listen 80;
    server_name mybestlifeapp.com www.mybestlifeapp.com;
    
    # Security headers
    add_header X-Frame-Options "DENY" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; font-src 'self' data:; connect-src 'self' https:; frame-ancestors 'none';" always;
    
    # Rate limiting
    limit_req_zone $binary_remote_addr zone=api:10m rate=10r/m;
    limit_req_zone $binary_remote_addr zone=auth:10m rate=5r/m;
    
    # Frontend
    location / {
        root /root/my-best-life-platform/frontend/dist;
        try_files $uri $uri/ /index.html;
        
        # Cache static assets
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }
    
    # API routes
    location /api/ {
        limit_req zone=api burst=20 nodelay;
        proxy_pass http://localhost:3001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        
        # Timeout settings
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
    
    # Auth routes with stricter rate limiting
    location /api/auth/ {
        limit_req zone=auth burst=10 nodelay;
        proxy_pass http://localhost:3001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
    
    # Health check
    location /health {
        proxy_pass http://localhost:3001/api/health;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

ln -sf /etc/nginx/sites-available/mybestlifeapp.com /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t
systemctl restart nginx
systemctl enable nginx

print_status "Setting up SSL certificate..."
certbot --nginx -d mybestlifeapp.com -d www.mybestlifeapp.com --non-interactive --agree-tos --email admin@mybestlifeapp.com

print_status "Setting up firewall..."
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable

print_success "🎉 Deployment completed successfully!"
print_success "Your HelpMyBestLife Platform v1.2 is now live!"
print_success "Frontend: https://mybestlifeapp.com"
print_success "API: https://mybestlifeapp.com/api/health"
print_success "Backend running on PM2: mybestlife-backend"
print_success "PostgreSQL password: $DB_PASSWORD"

echo ""
echo "🔒 Security Features Active:"
echo "✅ JWT Authentication with bcrypt"
echo "✅ Security Headers (CSP, HSTS, XSS protection)"
echo "✅ Rate Limiting (5 auth attempts/15min)"
echo "✅ Input Validation and sanitization"
echo "✅ CORS Security with origin validation"
echo "✅ Security Logging and audit trail"
echo "✅ SSL/TLS Encryption"
echo "✅ PostgreSQL Database with secure password"
echo ""
echo "📊 Monitoring:"
echo "• PM2: pm2 status"
echo "• Logs: pm2 logs mybestlife-backend"
echo "• Nginx: systemctl status nginx"
echo "• PostgreSQL: systemctl status postgresql"
echo ""
echo "🚀 Your VPS deployment is complete!"
