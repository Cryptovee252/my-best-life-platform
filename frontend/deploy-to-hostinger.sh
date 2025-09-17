#!/bin/bash

# My Best Life - Hostinger Deployment Script
# This script helps automate the deployment process

set -e

echo "🚀 My Best Life - Hostinger Deployment Script"
echo "=============================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
FRONTEND_DIR="hostinger-deploy"
BACKEND_DIR="../backend"
DEPLOY_DIR="deployment-package"

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

# Check if required directories exist
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    if [ ! -d "$FRONTEND_DIR" ]; then
        print_error "Frontend directory '$FRONTEND_DIR' not found!"
        exit 1
    fi
    
    if [ ! -d "$BACKEND_DIR" ]; then
        print_error "Backend directory '$BACKEND_DIR' not found!"
        exit 1
    fi
    
    print_success "Prerequisites check passed!"
}

# Create deployment package
create_deployment_package() {
    print_status "Creating deployment package..."
    
    # Remove existing deployment directory
    if [ -d "$DEPLOY_DIR" ]; then
        rm -rf "$DEPLOY_DIR"
    fi
    
    # Create deployment directory
    mkdir -p "$DEPLOY_DIR"
    
    # Copy frontend files
    print_status "Copying frontend files..."
    cp "$FRONTEND_DIR"/index-modern.html "$DEPLOY_DIR"/index.html
    cp "$FRONTEND_DIR"/register-modern.html "$DEPLOY_DIR"/register.html
    cp "$FRONTEND_DIR"/login-modern.html "$DEPLOY_DIR"/login.html
    cp "$FRONTEND_DIR"/verify-email.html "$DEPLOY_DIR"/verify-email.html
    cp "$FRONTEND_DIR"/reset-password.html "$DEPLOY_DIR"/reset-password.html
    cp "$FRONTEND_DIR"/MBL_Logo.webp "$DEPLOY_DIR"/
    cp "$FRONTEND_DIR"/favicon.ico "$DEPLOY_DIR"/
    
    # Copy deployment guides
    cp "$FRONTEND_DIR"/../ULTRA-DETAILED-DEPLOYMENT-GUIDE.md "$DEPLOY_DIR"/
    cp "$FRONTEND_DIR"/../QUICK-REFERENCE-CARD.md "$DEPLOY_DIR"/
    
    # Copy backend files
    print_status "Copying backend files..."
    cp -r "$BACKEND_DIR" "$DEPLOY_DIR"/
    
    # Create deployment instructions
    create_deployment_instructions
    
    print_success "Deployment package created in '$DEPLOY_DIR' directory!"
}

# Create deployment instructions
create_deployment_instructions() {
    cat > "$DEPLOY_DIR"/DEPLOYMENT-INSTRUCTIONS.md << 'EOF'
# My Best Life - Quick Deployment Instructions

## Quick Setup

1. **Upload Files to Hostinger:**
   - Upload all files from this directory to your `public_html` folder
   - Ensure the structure matches:
     ```
     public_html/
     ├── index.html
     ├── register.html
     ├── login.html
     ├── MBL_Logo.webp
     ├── favicon.ico
     └── backend/
     ```

2. **Configure Environment:**
   - Create `.env` file in `backend/` directory
   - Set your database and email credentials

3. **Enable Node.js:**
   - In Hostinger control panel: Hosting → Manage → Advanced → Node.js
   - Set entry point to: `backend/app.js`
   - Set Node.js version to 18.x or higher

4. **Setup Database:**
   - Create PostgreSQL database in Hostinger
   - Update DATABASE_URL in `.env` file
   - Run: `npx prisma db push`

5. **Start Application:**
   - Install dependencies: `npm install`
   - Start with PM2: `pm2 start app.js --name "mybestlife"`

## Environment Variables (.env)

```env
DATABASE_URL="postgresql://username:password@host:port/database"
JWT_SECRET="your-super-secret-jwt-key-here"
SMTP_HOST="smtp.gmail.com"
SMTP_PORT=587
SMTP_USER="your-email@gmail.com"
SMTP_PASS="your-app-password"
FRONTEND_URL="https://mybestlifeapp.com"
NODE_ENV="production"
```

## Quick Commands

```bash
# Install dependencies
npm install

# Setup database
npx prisma generate
npx prisma db push

# Start application
pm2 start app.js --name "mybestlife"
pm2 startup
pm2 save
```

## Test Your Deployment

1. Visit your domain (e.g., https://mybestlifeapp.com)
2. Test registration and login
3. Verify email functionality
4. Check API endpoints

## Support

- Full deployment guide: HOSTINGER-DEPLOYMENT-GUIDE.md
- Hostinger support: Available through control panel
- Application issues: Check logs and error messages
EOF

    print_success "Deployment instructions created!"
}

# Create environment template
create_env_template() {
    cat > "$DEPLOY_DIR"/backend/.env.template << 'EOF'
# My Best Life - Environment Configuration Template
# Copy this file to .env and fill in your actual values

# Database Configuration
DATABASE_URL="postgresql://username:password@host:port/database"

# JWT Configuration
JWT_SECRET="your-super-secret-jwt-key-here"

# Email Configuration (Gmail example)
SMTP_HOST="smtp.gmail.com"
SMTP_PORT=587
SMTP_USER="your-email@gmail.com"
SMTP_PASS="your-app-password"

# Frontend URL
FRONTEND_URL="https://mybestlifeapp.com"

# Node Environment
NODE_ENV="production"
EOF

    print_success "Environment template created!"
}

# Create startup script
create_startup_script() {
    cat > "$DEPLOY_DIR"/start-app.sh << 'EOF'
#!/bin/bash

# My Best Life - Application Startup Script

echo "🚀 Starting My Best Life application..."

# Navigate to backend directory
cd backend

# Install dependencies if not already installed
if [ ! -d "node_modules" ]; then
    echo "Installing dependencies..."
    npm install
fi

# Generate Prisma client
echo "Generating Prisma client..."
npx prisma generate

# Start application with PM2
echo "Starting application with PM2..."
pm2 start app.js --name "mybestlife"

# Save PM2 configuration
pm2 save

echo "✅ Application started successfully!"
echo "📊 Check status with: pm2 status"
echo "📝 View logs with: pm2 logs mybestlife"
EOF

    chmod +x "$DEPLOY_DIR"/start-app.sh
    print_success "Startup script created!"
}

# Create package.json for production
create_production_package() {
    cat > "$DEPLOY_DIR"/backend/package.production.json << 'EOF'
{
  "name": "mybestlife-backend",
  "version": "1.0.0",
  "description": "Backend for My Best Life app",
  "main": "app.js",
  "scripts": {
    "start": "node app.js",
    "dev": "nodemon app.js",
    "db:generate": "prisma generate",
    "db:push": "prisma db push",
    "db:studio": "prisma studio",
    "deploy": "npm install --production && npx prisma generate && pm2 start app.js --name mybestlife"
  },
  "dependencies": {
    "@prisma/client": "^5.7.1",
    "bcryptjs": "^3.0.2",
    "body-parser": "^2.2.0",
    "cors": "^2.8.5",
    "dotenv": "^16.5.0",
    "express": "^4.18.2",
    "jsonwebtoken": "^9.0.2",
    "nodemailer": "^6.9.0",
    "pg": "^8.16.3"
  },
  "devDependencies": {
    "prisma": "^5.7.1"
  },
  "engines": {
    "node": ">=18.0.0"
  }
}
EOF

    print_success "Production package.json created!"
}

# Create README for deployment
create_deployment_readme() {
    cat > "$DEPLOY_DIR"/README.md << 'EOF'
# My Best Life - Deployment Package

This directory contains everything you need to deploy My Best Life to your Hostinger hosting account.

## What's Included

- **Frontend Files**: Modern, responsive HTML pages with animations
- **Backend Application**: Node.js API with PostgreSQL database
- **Email Service**: Welcome emails and verification system
- **Deployment Scripts**: Automated setup and startup scripts
- **Documentation**: Complete deployment guide and instructions

## Quick Start

1. **Upload Files**: Upload all contents to your `public_html` directory
2. **Configure Environment**: Set up your `.env` file with credentials
3. **Enable Node.js**: Configure Node.js in Hostinger control panel
4. **Setup Database**: Create PostgreSQL database and run migrations
5. **Start Application**: Use the provided startup script

## File Structure

```
public_html/
├── index.html              # Landing page
├── register.html           # Registration page
├── login.html             # Login page
├── MBL_Logo.webp          # Application logo
├── favicon.ico            # Browser icon
├── backend/               # Backend application
│   ├── app.js            # Main application file
│   ├── package.json      # Dependencies
│   ├── .env.template     # Environment template
│   ├── prisma/           # Database schema
│   ├── routes/           # API routes
│   ├── services/         # Business logic
│   └── middleware/       # Authentication
├── start-app.sh          # Startup script
├── DEPLOYMENT-INSTRUCTIONS.md  # Quick setup guide
└── README.md             # This file
```

## Features

- ✨ Modern, responsive design
- 🔐 Secure authentication system
- 📧 Email verification and welcome emails
- 🗄️ PostgreSQL database with Prisma ORM
- 🚀 Optimized for production deployment
- 📱 Mobile-friendly interface
- 🎨 Beautiful animations and effects

## Support

- **Deployment Guide**: HOSTINGER-DEPLOYMENT-GUIDE.md
- **Quick Instructions**: DEPLOYMENT-INSTRUCTIONS.md
- **Hostinger Support**: Available through control panel

## License

This application is proprietary software. All rights reserved.

---

**My Best Life** - Transform your life, one day at a time.
EOF

    print_success "Deployment README created!"
}

# Main deployment process
main() {
    print_status "Starting deployment package creation..."
    
    check_prerequisites
    create_deployment_package
    create_env_template
    create_startup_script
    create_production_package
    create_deployment_readme
    
    echo ""
    print_success "🎉 Deployment package created successfully!"
    echo ""
    echo "📁 Your deployment package is ready in: $DEPLOY_DIR/"
    echo ""
    echo "📋 Next steps:"
    echo "   1. Upload contents of $DEPLOY_DIR/ to your Hostinger public_html"
    echo "   2. Follow DEPLOYMENT-INSTRUCTIONS.md for quick setup"
    echo "   3. Use HOSTINGER-DEPLOYMENT-GUIDE.md for detailed instructions"
    echo ""
    echo "🚀 Ready to deploy to Hostinger!"
}

# Run main function
main "$@"
