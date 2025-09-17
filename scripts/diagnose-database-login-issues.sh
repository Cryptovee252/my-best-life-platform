#!/bin/bash

# Database and Login Issues Diagnostic Script
# This script identifies and fixes database connectivity and authentication problems

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

DOMAIN="mybestlifeapp.com"

echo "🔍 DATABASE & LOGIN DIAGNOSTIC"
echo "=============================="
echo "Domain: $DOMAIN"
echo "Date: $(date)"
echo ""

# Step 1: Check PM2 status
print_status "1. Checking PM2 application status..."
if command -v pm2 &> /dev/null; then
    pm2 status
    echo ""
    
    # Check if mybestlife-secure is running
    if pm2 list | grep -q "mybestlife-secure.*online"; then
        print_success "MyBestLife application: Running"
        
        # Check application logs
        print_status "Checking application logs..."
        pm2 logs mybestlife-secure --lines 20
    else
        print_error "MyBestLife application: Not running"
        echo "Fix: pm2 start app-secure.js --name mybestlife-secure"
    fi
else
    print_error "PM2: Not installed"
fi

echo ""

# Step 2: Check backend connectivity
print_status "2. Testing backend connectivity..."
if curl -f http://localhost:3000 > /dev/null 2>&1; then
    print_success "Backend: Responding on port 3000"
else
    print_error "Backend: Not responding on port 3000"
fi

# Test API endpoints
print_status "Testing API endpoints..."
if curl -f http://localhost:3000/api/health > /dev/null 2>&1; then
    print_success "API Health endpoint: Working"
else
    print_warning "API Health endpoint: Not responding"
fi

if curl -f http://localhost:3000/api/auth/login > /dev/null 2>&1; then
    print_success "API Login endpoint: Accessible"
else
    print_warning "API Login endpoint: Not accessible"
fi

echo ""

# Step 3: Check database connection
print_status "3. Checking database connection..."

# Check if PostgreSQL is running
if systemctl is-active --quiet postgresql; then
    print_success "PostgreSQL: Running"
else
    print_error "PostgreSQL: Not running"
    echo "Fix: sudo systemctl start postgresql"
fi

# Check database connection
print_status "Testing database connection..."
cd /var/www/mybestlife/backend

# Check if .env file exists
if [ -f ".env" ]; then
    print_success ".env file: Exists"
    
    # Check database URL in .env
    if grep -q "DATABASE_URL" .env; then
        DB_URL=$(grep "DATABASE_URL" .env | cut -d'=' -f2 | tr -d '"')
        print_status "Database URL: $DB_URL"
        
        # Extract database details
        DB_HOST=$(echo $DB_URL | sed 's/.*:\/\/[^:]*:\([^@]*\)@\([^:]*\):\([^\/]*\)\/\(.*\)/\2/')
        DB_PORT=$(echo $DB_URL | sed 's/.*:\/\/[^:]*:\([^@]*\)@\([^:]*\):\([^\/]*\)\/\(.*\)/\3/')
        DB_NAME=$(echo $DB_URL | sed 's/.*:\/\/[^:]*:\([^@]*\)@\([^:]*\):\([^\/]*\)\/\(.*\)/\4/')
        DB_USER=$(echo $DB_URL | sed 's/.*:\/\/\([^:]*\):\([^@]*\)@\([^:]*\):\([^\/]*\)\/\(.*\)/\1/')
        
        print_status "Database Host: $DB_HOST"
        print_status "Database Port: $DB_PORT"
        print_status "Database Name: $DB_NAME"
        print_status "Database User: $DB_USER"
        
        # Test database connection
        if command -v psql &> /dev/null; then
            if PGPASSWORD=$(echo $DB_URL | sed 's/.*:\/\/[^:]*:\([^@]*\)@\([^:]*\):\([^\/]*\)\/\(.*\)/\1/') psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "SELECT 1;" > /dev/null 2>&1; then
                print_success "Database connection: Working"
            else
                print_error "Database connection: Failed"
                echo "Check database credentials and connectivity"
            fi
        else
            print_warning "psql: Not installed"
        fi
    else
        print_error "DATABASE_URL: Not found in .env"
    fi
else
    print_error ".env file: Missing"
    echo "Fix: Create .env file with database configuration"
fi

echo ""

# Step 4: Check Prisma configuration
print_status "4. Checking Prisma configuration..."

if [ -f "prisma/schema.prisma" ]; then
    print_success "Prisma schema: Exists"
    
    # Check if Prisma client is generated
    if [ -d "node_modules/.prisma" ]; then
        print_success "Prisma client: Generated"
    else
        print_warning "Prisma client: Not generated"
        echo "Fix: npx prisma generate"
    fi
    
    # Check database schema
    print_status "Checking database schema..."
    if npx prisma db pull > /dev/null 2>&1; then
        print_success "Database schema: Accessible"
    else
        print_error "Database schema: Not accessible"
    fi
else
    print_error "Prisma schema: Missing"
fi

echo ""

# Step 5: Check JWT configuration
print_status "5. Checking JWT configuration..."

if [ -f ".env" ]; then
    if grep -q "JWT_SECRET" .env; then
        JWT_SECRET=$(grep "JWT_SECRET" .env | cut -d'=' -f2 | tr -d '"')
        if [ ${#JWT_SECRET} -gt 32 ]; then
            print_success "JWT Secret: Configured (${#JWT_SECRET} chars)"
        else
            print_warning "JWT Secret: Too short (${#JWT_SECRET} chars)"
        fi
    else
        print_error "JWT_SECRET: Not found in .env"
    fi
    
    if grep -q "JWT_REFRESH_SECRET" .env; then
        print_success "JWT Refresh Secret: Configured"
    else
        print_error "JWT_REFRESH_SECRET: Not found in .env"
    fi
else
    print_error ".env file: Missing for JWT check"
fi

echo ""

# Step 6: Test API endpoints with detailed output
print_status "6. Testing API endpoints with detailed output..."

# Test health endpoint
print_status "Testing /api/health..."
curl -v http://localhost:3000/api/health 2>&1 | head -20

echo ""

# Test login endpoint
print_status "Testing /api/auth/login..."
curl -v -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"testpassword"}' 2>&1 | head -20

echo ""

# Step 7: Check frontend-backend communication
print_status "7. Checking frontend-backend communication..."

# Test HTTPS API endpoints
print_status "Testing HTTPS API endpoints..."
if curl -f https://$DOMAIN/api/health > /dev/null 2>&1; then
    print_success "HTTPS API Health: Working"
else
    print_error "HTTPS API Health: Not working"
fi

if curl -f https://$DOMAIN/api/auth/login > /dev/null 2>&1; then
    print_success "HTTPS API Login: Accessible"
else
    print_error "HTTPS API Login: Not accessible"
fi

echo ""

# Step 8: Check React error details
print_status "8. Checking for React error details..."

# Check if we can get more detailed error information
print_status "React Error #185 typically indicates:"
echo "  - Network request failures"
echo "  - API endpoint not responding"
echo "  - CORS issues"
echo "  - Authentication token problems"
echo "  - Database connection failures"

echo ""

# Step 9: Generate diagnostic report
print_status "9. Generating diagnostic report..."

echo "🔧 DIAGNOSTIC SUMMARY"
echo "===================="
echo ""

# Check all critical components
CRITICAL_ISSUES=0

# PM2 Status
if ! pm2 list | grep -q "mybestlife-secure.*online"; then
    echo "❌ PM2: Application not running"
    ((CRITICAL_ISSUES++))
else
    echo "✅ PM2: Application running"
fi

# Backend Connectivity
if ! curl -f http://localhost:3000 > /dev/null 2>&1; then
    echo "❌ Backend: Not responding on port 3000"
    ((CRITICAL_ISSUES++))
else
    echo "✅ Backend: Responding on port 3000"
fi

# Database Connection
if [ -f ".env" ] && grep -q "DATABASE_URL" .env; then
    echo "✅ Database: Configuration found"
else
    echo "❌ Database: Configuration missing"
    ((CRITICAL_ISSUES++))
fi

# JWT Configuration
if [ -f ".env" ] && grep -q "JWT_SECRET" .env; then
    echo "✅ JWT: Configuration found"
else
    echo "❌ JWT: Configuration missing"
    ((CRITICAL_ISSUES++))
fi

echo ""
echo "📊 CRITICAL ISSUES FOUND: $CRITICAL_ISSUES"

if [ $CRITICAL_ISSUES -eq 0 ]; then
    print_success "No critical issues found!"
    echo "The problem might be in the application code or frontend configuration."
else
    print_error "$CRITICAL_ISSUES critical issues found!"
    echo "Fix these issues first before testing the application."
fi

echo ""
echo "🔧 RECOMMENDED FIXES"
echo "==================="
echo ""

if ! pm2 list | grep -q "mybestlife-secure.*online"; then
    echo "1. Start the application:"
    echo "   cd /var/www/mybestlife/backend"
    echo "   pm2 start app-secure.js --name mybestlife-secure"
    echo ""
fi

if ! curl -f http://localhost:3000 > /dev/null 2>&1; then
    echo "2. Check application logs:"
    echo "   pm2 logs mybestlife-secure --lines 50"
    echo ""
fi

if [ ! -f ".env" ]; then
    echo "3. Create .env file:"
    echo "   cp env-template.txt .env"
    echo "   # Edit .env with your database credentials"
    echo ""
fi

if ! systemctl is-active --quiet postgresql; then
    echo "4. Start PostgreSQL:"
    echo "   sudo systemctl start postgresql"
    echo "   sudo systemctl enable postgresql"
    echo ""
fi

echo "5. Regenerate Prisma client:"
echo "   npx prisma generate"
echo "   npx prisma db push"
echo ""

echo "6. Restart the application:"
echo "   pm2 restart mybestlife-secure"
echo ""

print_status "Run the diagnostic script to identify specific issues!"
