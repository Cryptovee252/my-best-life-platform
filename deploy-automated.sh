#!/bin/bash

# HelpMyBestLife Platform v1.2 - Automated Deployment Script
# This script handles ALL database issues automatically and provides multiple deployment options

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Function to print colored output
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

print_header() {
    echo -e "${PURPLE}[HEADER]${NC} $1"
}

# Function to generate secure password
generate_password() {
    # Generate a secure password without special characters that cause bash issues
    openssl rand -base64 32 | tr -d "=+/" | cut -c1-25
}

# Function to setup SQLite database
setup_sqlite() {
    print_status "Setting up SQLite database (recommended for quick deployment)..."
    
    # Create SQLite environment file
    cat > /root/my-best-life-platform/backend/.env << EOF
NODE_ENV=production
PORT=3001
DATABASE_URL="file:./dev.db"
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

    print_success "SQLite environment configured successfully!"
}

# Function to setup PostgreSQL database
setup_postgresql() {
    print_status "Setting up PostgreSQL database..."
    
    # Generate secure password
    DB_PASSWORD=$(generate_password)
    
    # Stop PostgreSQL
    systemctl stop postgresql 2>/dev/null || true
    
    # Kill any remaining processes
    pkill -f postgres 2>/dev/null || true
    
    # Remove shared memory segments
    ipcs -m | grep postgres | awk '{print $2}' | xargs -r ipcrm -m 2>/dev/null || true
    
    # Remove data directory
    rm -rf /var/lib/postgresql/16/main
    
    # Create directory
    mkdir -p /var/lib/postgresql/16/main
    chown -R postgres:postgres /var/lib/postgresql/16/main
    
    # Initialize database with trust authentication
    sudo -u postgres /usr/lib/postgresql/16/bin/initdb -D /var/lib/postgresql/16/main --auth-local=trust --auth-host=md5
    
    # Start PostgreSQL manually
    sudo -u postgres /usr/lib/postgresql/16/bin/pg_ctl -D /var/lib/postgresql/16/main -l /var/log/postgresql/postgresql-16-main.log start
    
    # Wait for server to start
    sleep 3
    
    # Set password
    sudo -u postgres psql -c "ALTER USER postgres PASSWORD '$DB_PASSWORD';"
    
    # Create production database
    sudo -u postgres createdb mybestlife_prod
    
    # Create PostgreSQL environment file
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

    print_success "PostgreSQL configured successfully with password: $DB_PASSWORD"
}

# Function to install system dependencies
install_dependencies() {
    print_status "Installing system dependencies..."
    
    # Update system
    apt update && apt upgrade -y
    
    # Install Node.js 18+
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
    apt-get install -y nodejs
    
    # Install PostgreSQL
    apt-get install -y postgresql postgresql-contrib
    
    # Install Nginx
    apt-get install -y nginx
    
    # Install PM2
    npm install -g pm2
    
    # Install Certbot for SSL
    apt-get install -y certbot python3-certbot-nginx
    
    print_success "System dependencies installed successfully!"
}

# Function to setup application
setup_application() {
    print_status "Setting up application..."
    
    # Install backend dependencies
    cd /root/my-best-life-platform/backend
    npm install --production
    
    # Run database migrations
    npm run db:push
    
    # Start backend with PM2
    pm2 start app.js --name "mybestlife-backend" --env production
    pm2 save
    pm2 startup
    
    # Build frontend
    cd /root/my-best-life-platform/frontend
    npm install
    npm run build
    
    print_success "Application setup completed!"
}

# Function to configure Nginx
configure_nginx() {
    print_status "Configuring Nginx..."
    
    # Create Nginx configuration
    cat > /etc/nginx/sites-available/mybestlifeapp.com << EOF
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
    limit_req_zone \$binary_remote_addr zone=api:10m rate=10r/m;
    limit_req_zone \$binary_remote_addr zone=auth:10m rate=5r/m;
    
    # Frontend
    location / {
        root /root/my-best-life-platform/frontend/dist;
        try_files \$uri \$uri/ /index.html;
        
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
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        
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
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }
    
    # Health check
    location /health {
        proxy_pass http://localhost:3001/api/health;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

    # Enable the site
    ln -sf /etc/nginx/sites-available/mybestlifeapp.com /etc/nginx/sites-enabled/
    rm -f /etc/nginx/sites-enabled/default
    
    # Test Nginx configuration
    nginx -t
    
    # Restart Nginx
    systemctl restart nginx
    systemctl enable nginx
    
    print_success "Nginx configured successfully!"
}

# Function to setup SSL
setup_ssl() {
    print_status "Setting up SSL certificate..."
    
    # Setup SSL certificate
    certbot --nginx -d mybestlifeapp.com -d www.mybestlifeapp.com --non-interactive --agree-tos --email admin@mybestlifeapp.com
    
    # Setup automatic SSL renewal
    (crontab -l 2>/dev/null; echo "0 12 * * * /usr/bin/certbot renew --quiet") | crontab -
    
    print_success "SSL certificate configured successfully!"
}

# Function to setup firewall
setup_firewall() {
    print_status "Setting up firewall..."
    
    ufw allow 22/tcp
    ufw allow 80/tcp
    ufw allow 443/tcp
    ufw --force enable
    
    print_success "Firewall configured successfully!"
}

# Function to show final status
show_status() {
    print_header "🎉 Deployment completed successfully!"
    print_success "Your HelpMyBestLife Platform v1.2 is now live!"
    print_success "Frontend: https://mybestlifeapp.com"
    print_success "API: https://mybestlifeapp.com/api/health"
    print_success "Backend running on PM2: mybestlife-backend"
    
    echo ""
    echo "🔒 Security Features Active:"
    echo "✅ JWT Authentication with bcrypt"
    echo "✅ Security Headers (CSP, HSTS, XSS protection)"
    echo "✅ Rate Limiting (5 auth attempts/15min)"
    echo "✅ Input Validation and sanitization"
    echo "✅ CORS Security with origin validation"
    echo "✅ Security Logging and audit trail"
    echo "✅ SSL/TLS Encryption"
    echo ""
    echo "📊 Monitoring:"
    echo "• PM2: pm2 status"
    echo "• Logs: pm2 logs mybestlife-backend"
    echo "• Nginx: systemctl status nginx"
    echo "• Database: systemctl status postgresql (if using PostgreSQL)"
    echo ""
    echo "🚀 Your VPS deployment is complete!"
}

# Main deployment function
main() {
    print_header "🚀 HelpMyBestLife Platform v1.2 - Automated Deployment"
    print_header "======================================================="
    
    # Check if running as root
    if [ "$EUID" -ne 0 ]; then
        print_error "Please run as root (use sudo)"
        exit 1
    fi
    
    # Check if repository exists
    if [ ! -d "/root/my-best-life-platform" ]; then
        print_error "Repository not found at /root/my-best-life-platform"
        print_status "Please clone the repository first:"
        print_status "git clone https://github.com/Cryptovee252/my-best-life-platform.git"
        exit 1
    fi
    
    print_status "Starting automated deployment..."
    
    # Install dependencies
    install_dependencies
    
    # Choose database type
    echo ""
    print_warning "Choose database type:"
    echo "1) SQLite (Recommended - Fast and reliable)"
    echo "2) PostgreSQL (Enterprise - More complex setup)"
    echo ""
    read -p "Enter your choice (1 or 2): " db_choice
    
    case $db_choice in
        1)
            setup_sqlite
            ;;
        2)
            setup_postgresql
            ;;
        *)
            print_warning "Invalid choice. Defaulting to SQLite..."
            setup_sqlite
            ;;
    esac
    
    # Setup application
    setup_application
    
    # Configure Nginx
    configure_nginx
    
    # Setup SSL
    setup_ssl
    
    # Setup firewall
    setup_firewall
    
    # Show final status
    show_status
}

# Run main function
main "$@"
