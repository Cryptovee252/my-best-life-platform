#!/bin/bash

# 🚀 Backup v1.3 Stable Version
# Backup current working version with login/registration fixes

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

echo "🚀 Backup v1.3 Stable Version"
echo "============================="
echo "Backing up current working version with fixes"
echo ""

# Create backup directory
BACKUP_DIR="backups/v1.3-stable-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

print_status "Creating backup in: $BACKUP_DIR"

# Copy all essential files
print_status "Copying project files..."
cp -r frontend "$BACKUP_DIR/"
cp -r backend "$BACKUP_DIR/"
cp -r scripts "$BACKUP_DIR/"
cp -r docs "$BACKUP_DIR/"
cp package.json "$BACKUP_DIR/"
cp package-lock.json "$BACKUP_DIR/"
cp tsconfig.json "$BACKUP_DIR/"
cp docker-compose.yml "$BACKUP_DIR/"
cp README.md "$BACKUP_DIR/"

# Copy deployment scripts
print_status "Copying deployment scripts..."
cp *.sh "$BACKUP_DIR/" 2>/dev/null || true
cp *.md "$BACKUP_DIR/" 2>/dev/null || true

# Create version info file
print_status "Creating version info..."
cat > "$BACKUP_DIR/VERSION-INFO.md" << 'EOF'
# HelpMyBestLife Platform v1.3.0 - Stable Version

## 🎉 What's Fixed in v1.3.0

### ✅ **Major Fixes:**
- **Rate Limiting Fixed**: Resolved 429 "Too Many Requests" errors
- **Login Working**: Users can now log in successfully
- **Registration Working**: New users can create accounts
- **SSL/HTTPS Working**: Secure connection established
- **API Endpoints Working**: All backend APIs responding correctly
- **Database Connected**: PostgreSQL connection established

### 🔧 **Technical Improvements:**
- Updated rate limiting settings (10 attempts, 5min lockout)
- Fixed CORS configuration for frontend-backend communication
- Improved nginx proxy configuration
- Enhanced security headers
- Better error handling and logging

### 🚀 **Deployment Status:**
- **VPS**: 147.93.47.43
- **Domain**: mybestlifeapp.com
- **SSL**: Let's Encrypt certificate active
- **Backend**: PM2 managed, running on port 3000
- **Frontend**: Nginx served from /var/www/mybestlife/
- **Database**: PostgreSQL with Prisma ORM

### 🐛 **Known Issues (To Fix in v1.4):**
- Page refresh causes logout (session persistence issue)
- Some UI/UX improvements needed
- Additional error handling for edge cases

### 📋 **Deployment Commands:**
```bash
# Deploy this version to VPS
./deploy-fresh-to-vps.sh

# Or use the emergency fix if needed
./emergency-vps-fix.sh
```

### 🔒 **Security Features:**
- JWT authentication with refresh tokens
- Rate limiting (reasonable limits)
- CORS protection
- Security headers (HSTS, CSP, etc.)
- Input validation and sanitization
- Password hashing with bcrypt

**Version**: 1.3.0
**Date**: $(date)
**Status**: Stable (Production Ready)
**Next**: v1.4.0 (Bug fixes and improvements)
EOF

# Create deployment package
print_status "Creating deployment package..."
cd "$BACKUP_DIR"
tar -czf "../helpmybestlife-v1.3-stable.tar.gz" .
cd ..

print_success "Backup created successfully!"
echo ""
echo "📦 **Backup Details:**"
echo "   Directory: $BACKUP_DIR"
echo "   Package: helpmybestlife-v1.3-stable.tar.gz"
echo "   Size: $(du -h helpmybestlife-v1.3-stable.tar.gz | cut -f1)"
echo ""

# Git operations
print_status "Committing to Git..."

# Add all changes
git add .

# Create commit
git commit -m "🚀 Release v1.3.0 - Stable Version

✅ Major Fixes:
- Fixed rate limiting (429 errors resolved)
- Login and registration working
- SSL/HTTPS properly configured
- API endpoints responding correctly
- Database connection established

🔧 Technical Improvements:
- Updated rate limiting settings
- Fixed CORS configuration
- Improved nginx proxy
- Enhanced security headers

🐛 Known Issues (v1.4):
- Page refresh causes logout
- UI/UX improvements needed

Status: Stable (Production Ready)"
print_success "Git commit created"

# Create git tag
print_status "Creating git tag v1.3.0..."
git tag -a "v1.3.0" -m "Release v1.3.0 - Stable Version with Login/Registration Fixes"
print_success "Git tag v1.3.0 created"

# Push to GitHub
print_status "Pushing to GitHub..."
git push origin main
git push origin v1.3.0
print_success "Pushed to GitHub successfully"

echo ""
echo "🎉 **v1.3.0 Backup Complete!**"
echo ""
echo "📋 **What was backed up:**
   ✅ All source code (frontend, backend)
   ✅ Deployment scripts
   ✅ Documentation
   ✅ Version info and changelog
   ✅ Git commit and tag v1.3.0
   ✅ Pushed to GitHub"
echo ""
echo "🔗 **GitHub:**
   Repository: Updated with v1.3.0
   Tag: v1.3.0 created
   Commit: Latest changes pushed"
echo ""
echo "📦 **Backup Files:**
   Directory: $BACKUP_DIR/
   Package: helpmybestlife-v1.3-stable.tar.gz"
echo ""
print_success "Ready to fix the refresh logout bug in v1.4! 🚀"
