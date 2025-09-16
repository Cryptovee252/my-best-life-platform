#!/bin/bash

# My Best Life - VPS Setup Script
# This script sets up your VPS to run the My Best Life platform

set -e

echo "🚀 My Best Life - VPS Setup Script"
echo "=================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

# Check if running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        print_error "Please run this script as root (use sudo)"
        exit 1
    fi
}

# Update system
update_system() {
    print_status "Updating system packages..."
    apt update && apt upgrade -y
    print_success "System updated!"
}

# Install Node.js
install_nodejs() {
    print_status "Installing Node.js 18.x..."
    
    # Install NodeSource repository
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
    
    # Install Node.js
    apt-get install -y nodejs
    
    # Verify installation
    node_version=$(node --version)
    npm_version=$(npm --version)
    
    print_success "Node.js installed: $node_version"
    print_success "npm installed: $npm_version"
}

# Install PM2
install_pm2() {
    print_status "Installing PM2 process manager..."
    npm install -g pm2
    print_success "PM2 installed!"
}

# Install Nginx
install_nginx() {
    print_status "Installing Nginx web server..."
    apt install -y nginx
    
    # Start and enable Nginx
    systemctl start nginx
    systemctl enable nginx
    
    print_success "Nginx installed and started!"
}

# Install PostgreSQL
install_postgresql() {
    print_status "Installing PostgreSQL database..."
    
    # Install PostgreSQL
    apt install -y postgresql postgresql-contrib
    
    # Start and enable PostgreSQL
    systemctl start postgresql
    systemctl enable postgresql
    
    print_success "PostgreSQL installed and started!"
}

# Create application directory
create_app_directory() {
    print_status "Creating application directory..."
    
    APP_DIR="/var/www/mybestlife"
    mkdir -p $APP_DIR
    chown -R www-data:www-data $APP_DIR
    chmod -R 755 $APP_DIR
    
    print_success "Application directory created: $APP_DIR"
}

# Configure Nginx
configure_nginx() {
    print_status "Configuring Nginx..."
    
    # Create Nginx configuration
    cat > /etc/nginx/sites-available/mybestlife << 'EOF'
server {
    listen 80;
    server_name mybestlifeapp.com www.mybestlifeapp.com;
    
    # Serve static files
    location / {
        root /var/www/mybestlife;
        try_files $uri $uri/ @backend;
    }
    
    # Proxy API requests to Node.js
    location /api/ {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
    
    # Proxy backend requests
    location /backend/ {
        proxy_pass http://localhost:3000/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
    
    # Fallback to backend for SPA routing
    location @backend {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}
EOF

    # Enable the site
    ln -sf /etc/nginx/sites-available/mybestlife /etc/nginx/sites-enabled/
    
    # Remove default site
    rm -f /etc/nginx/sites-enabled/default
    
    # Test Nginx configuration
    nginx -t
    
    # Reload Nginx
    systemctl reload nginx
    
    print_success "Nginx configured!"
}

# Install Certbot for SSL
install_certbot() {
    print_status "Installing Certbot for SSL certificates..."
    
    # Install Certbot
    apt install -y certbot python3-certbot-nginx
    
    print_success "Certbot installed!"
}

# Configure firewall
configure_firewall() {
    print_status "Configuring firewall..."
    
    # Install UFW if not present
    apt install -y ufw
    
    # Configure firewall rules
    ufw allow ssh
    ufw allow 'Nginx Full'
    ufw allow 3000
    
    # Enable firewall
    ufw --force enable
    
    print_success "Firewall configured!"
}

# Create deployment script
create_deployment_script() {
    print_status "Creating deployment script..."
    
    cat > /var/www/mybestlife/deploy.sh << 'EOF'
#!/bin/bash

# My Best Life - VPS Deployment Script

echo "🚀 Deploying My Best Life to VPS..."

# Pull latest code from GitHub
cd /var/www/mybestlife
git pull origin main

# Install/update dependencies
cd backend
npm install --production

# Restart application
pm2 restart mybestlife

echo "✅ Deployment complete!"
EOF

    chmod +x /var/www/mybestlife/deploy.sh
    chown www-data:www-data /var/www/mybestlife/deploy.sh
    
    print_success "Deployment script created!"
}

# Create environment template
create_env_template() {
    print_status "Creating environment template..."
    
    cat > /var/www/mybestlife/backend/.env.template << 'EOF'
# My Best Life - VPS Environment Configuration

# Node Environment
NODE_ENV=production
PORT=3000

# Database Configuration
DATABASE_URL=postgresql://mybestlife:password@localhost:5432/mybestlife

# JWT Configuration
JWT_SECRET=your-super-secret-jwt-key-here

# Email Configuration
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASS=your-app-password

# Frontend URL
FRONTEND_URL=https://mybestlifeapp.com
EOF

    print_success "Environment template created!"
}

# Setup PostgreSQL database
setup_database() {
    print_status "Setting up PostgreSQL database..."
    
    # Switch to postgres user and create database
    sudo -u postgres psql << 'EOF'
CREATE DATABASE mybestlife;
CREATE USER mybestlife WITH PASSWORD 'secure_password_here';
GRANT ALL PRIVILEGES ON DATABASE mybestlife TO mybestlife;
\q
EOF

    print_success "Database created!"
}

# Main setup function
main() {
    print_status "Starting VPS setup for My Best Life platform..."
    
    check_root
    update_system
    install_nodejs
    install_pm2
    install_nginx
    install_postgresql
    create_app_directory
    configure_nginx
    install_certbot
    configure_firewall
    create_deployment_script
    create_env_template
    setup_database
    
    echo ""
    print_success "🎉 VPS setup complete!"
    echo ""
    print_status "Next steps:"
    echo "1. Update your domain DNS to point to this VPS IP"
    echo "2. Deploy your application files to /var/www/mybestlife"
    echo "3. Configure environment variables in /var/www/mybestlife/backend/.env"
    echo "4. Start your application with PM2"
    echo "5. Get SSL certificate with: certbot --nginx -d mybestlifeapp.com"
    echo ""
    print_status "VPS IP Address: $(curl -s ifconfig.me)"
    print_status "Application directory: /var/www/mybestlife"
    print_status "Nginx configuration: /etc/nginx/sites-available/mybestlife"
}

# Run main function
main "$@"
