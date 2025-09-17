#!/bin/bash

# My Best Life - Shared Hosting Deployment Script
# This script creates a deployment package for shared hosting (no Node.js required)

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print functions
print_header() {
    echo -e "${BLUE}🚀 My Best Life - Shared Hosting Deployment Script${NC}"
    echo "=============================================="
}

print_status() {
    echo -e "${YELLOW}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Configuration
FRONTEND_DIR="hostinger-deploy"
BACKEND_PHP_DIR="backend-php"
DEPLOY_DIR="shared-hosting-package"

# Main function
main() {
    print_header
    print_status "Starting shared hosting deployment package creation..."
    
    # Check prerequisites
    check_prerequisites
    
    # Create deployment package
    create_deployment_package
    
    # Copy files
    copy_files
    
    # Create documentation
    create_documentation
    
    print_success "🎉 Shared hosting deployment package created successfully!"
    echo ""
    echo "📁 Your deployment package is ready in: $DEPLOY_DIR/"
    echo ""
    echo "📋 Next steps:"
    echo "   1. Upload contents of $DEPLOY_DIR/ to your Hostinger public_html"
    echo "   2. Follow SHARED-HOSTING-GUIDE.md for setup instructions"
    echo "   3. Use the included database setup script"
    echo ""
    echo "🚀 Ready to deploy to shared hosting!"
}

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    if [ ! -d "$FRONTEND_DIR" ]; then
        print_error "Frontend directory '$FRONTEND_DIR' not found!"
        exit 1
    fi
    
    if [ ! -d "$BACKEND_PHP_DIR" ]; then
        print_error "PHP backend directory '$BACKEND_PHP_DIR' not found!"
        exit 1
    fi
    
    print_success "Prerequisites check passed!"
}

# Create deployment package
create_deployment_package() {
    print_status "Creating shared hosting deployment package..."
    
    # Remove existing package if it exists
    if [ -d "$DEPLOY_DIR" ]; then
        rm -rf "$DEPLOY_DIR"
    fi
    
    # Create package directory
    mkdir -p "$DEPLOY_DIR"
    mkdir -p "$DEPLOY_DIR/api"
    mkdir -p "$DEPLOY_DIR/includes"
    mkdir -p "$DEPLOY_DIR/logs"
    
    print_success "Deployment package created!"
}

# Copy files
copy_files() {
    print_status "Copying frontend files..."
    
    # Copy HTML files
    cp "$FRONTEND_DIR"/index-modern.html "$DEPLOY_DIR"/index.html
    cp "$FRONTEND_DIR"/register-modern.html "$DEPLOY_DIR"/register.html
    cp "$FRONTEND_DIR"/login-modern.html "$DEPLOY_DIR"/login.html
    cp "$FRONTEND_DIR"/verify-email.html "$DEPLOY_DIR"/verify-email.html
    cp "$FRONTEND_DIR"/reset-password.html "$DEPLOY_DIR"/reset-password.html
    
    # Copy assets
    cp "$FRONTEND_DIR"/MBL_Logo.webp "$DEPLOY_DIR"/
    cp "$FRONTEND_DIR"/favicon.ico "$DEPLOY_DIR"/
    
    print_status "Copying PHP backend files..."
    
    # Copy PHP configuration
    cp "$BACKEND_PHP_DIR"/config.php "$DEPLOY_DIR"/
    
    # Copy API endpoints
    cp "$BACKEND_PHP_DIR"/api/*.php "$DEPLOY_DIR"/api/
    
    # Copy includes
    cp "$BACKEND_PHP_DIR"/includes/*.php "$DEPLOY_DIR"/includes/
    
    # Copy database setup
    cp "$BACKEND_PHP_DIR"/database-setup.sql "$DEPLOY_DIR"/
    
    # Copy deployment guides
    cp ULTRA-DETAILED-DEPLOYMENT-GUIDE.md "$DEPLOY_DIR"/
    cp QUICK-REFERENCE-CARD.md "$DEPLOY_DIR"/
    
    print_success "All files copied successfully!"
}

# Create documentation
create_documentation() {
    print_status "Creating shared hosting documentation..."
    
    # Create shared hosting specific guide
    cat > "$DEPLOY_DIR"/SHARED-HOSTING-GUIDE.md << 'EOF'
# 🚀 My Best Life - Shared Hosting Deployment Guide

## 🎯 Overview

This guide is specifically designed for **shared hosting** accounts (like Hostinger shared hosting) that don't support Node.js applications. We've converted the backend to PHP, which is fully supported on all shared hosting plans.

## ✨ What's Different from Node.js Version

- ✅ **Backend**: PHP instead of Node.js
- ✅ **Database**: MySQL instead of PostgreSQL
- ✅ **Email**: PHPMailer instead of Nodemailer
- ✅ **No SSH required**: Everything done through File Manager
- ✅ **No command line**: All setup through Hostinger control panel

## 📋 Prerequisites

- ✅ Hostinger shared hosting account
- ✅ Domain connected to hosting (mybestlifeapp.com)
- ✅ Gmail account for sending emails
- ✅ Basic knowledge of using Hostinger control panel

## 🚀 Step-by-Step Deployment

### Phase 1: Email Setup (5 minutes)
1. Go to [myaccount.google.com](https://myaccount.google.com)
2. Enable 2-factor authentication
3. Generate an app password for "Mail"
4. **SAVE THIS PASSWORD** - you'll need it!

### Phase 2: Upload Files (10 minutes)
1. Login to [hpanel.hostinger.com](https://hpanel.hostinger.com)
2. Open File Manager for your domain
3. Go to `public_html` folder
4. Upload **ALL** files from your `shared-hosting-package` folder

### Phase 3: Create Database (5 minutes)
1. In Hostinger: Databases → MySQL Databases
2. Click "Create Database"
3. **SAVE** database name, username, password
4. Note: Host is usually `localhost`, Port is `3306`

### Phase 4: Configure PHP Settings (5 minutes)
1. In File Manager: Go to `public_html` folder
2. Open `config.php` file
3. Edit and fill in your database credentials
4. Fill in your Gmail app password
5. Save the file

### Phase 5: Setup Database Tables (5 minutes)
1. In Hostinger: Databases → phpMyAdmin
2. Click on your database
3. Go to SQL tab
4. Copy and paste the contents of `database-setup.sql`
5. Click "Go" to execute

### Phase 6: Test Everything (5 minutes)
1. Visit `https://mybestlifeapp.com`
2. Test registration
3. Check your email for verification
4. Test login
5. Verify SSL certificate is active

## 🔧 Configuration Details

### Database Configuration (config.php)
```php
define('DB_HOST', 'localhost');
define('DB_NAME', 'your_database_name');
define('DB_USER', 'your_username');
define('DB_PASS', 'your_password');
define('DB_PORT', '3306');
```

### Email Configuration (config.php)
```php
define('SMTP_HOST', 'smtp.gmail.com');
define('SMTP_PORT', 587);
define('SMTP_USER', 'your-gmail@gmail.com');
define('SMTP_PASS', 'your-app-password');
```

## 🚨 Common Issues & Solutions

### Issue: "Cannot connect to database"
**Solution:** Check your database credentials in `config.php`

### Issue: "Emails not sending"
**Solution:** Verify your Gmail app password in `config.php`

### Issue: "Website not loading"
**Solution:** Make sure all files are in `public_html` directory

### Issue: "PHP errors"
**Solution:** Check that `config.php` has all required fields filled

## 📱 What Your Users Will Experience

- ✨ **Beautiful landing page** that feels like a premium social platform
- 🔐 **Modern registration** with real-time validation
- 📧 **Professional welcome emails** sent immediately
- ✅ **Email verification** for security
- 🔑 **Sleek login experience** with password recovery
- 📱 **Mobile-optimized** design that works perfectly on all devices

## 🎉 Success Checklist

- ✅ Website loads at mybestlifeapp.com
- ✅ Registration form works
- ✅ Welcome email received
- ✅ Email verification works
- ✅ Login works
- ✅ Password reset works
- ✅ SSL certificate active (lock icon)
- ✅ Mobile responsive

## 📞 Getting Help

- **Hostinger Support:** [support.hostinger.com](https://support.hostinger.com)
- **Gmail Help:** [support.google.com/mail](https://support.google.com/mail)
- **This Guide:** SHARED-HOSTING-GUIDE.md

## 🎯 You're Ready!

Your My Best Life platform will be live at: `https://mybestlifeapp.com`

**Total deployment time:** About 35 minutes for shared hosting
**No technical knowledge required:** Everything done through Hostinger control panel

Your platform is designed to appeal to millennials and Gen Alpha with its modern, professional design that feels like a cool social media platform! 🚀✨
EOF

    # Create quick setup instructions
    cat > "$DEPLOY_DIR"/QUICK-SETUP.md << 'EOF'
# ⚡ Quick Setup - Shared Hosting

## 🚀 5-Minute Setup (After File Upload)

### 1. Configure Database (2 minutes)
- Edit `config.php` in File Manager
- Fill in your database credentials
- Save the file

### 2. Setup Database Tables (2 minutes)
- Go to phpMyAdmin in Hostinger
- Select your database
- Run the SQL from `database-setup.sql`

### 3. Test Everything (1 minute)
- Visit your website
- Test registration
- Check email verification

## 🔑 Required Credentials

- **Database Name:** `[your_database_name]`
- **Database Username:** `[your_username]`
- **Database Password:** `[your_password]`
- **Gmail App Password:** `[your_app_password]`

## ✅ You're Done!

Your platform will be live and fully functional!
EOF

    print_success "Documentation created successfully!"
}

# Run main function
main "$@"




