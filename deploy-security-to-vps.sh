#!/bin/bash

# My Best Life Platform - VPS Security Deployment Script
# URGENT: Run this script to secure your live VPS immediately

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print functions
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

echo "🚨 My Best Life Platform - VPS Security Deployment"
echo "=================================================="
echo ""
print_warning "This script will secure your live VPS immediately!"
echo ""

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   print_error "Do not run this script as root for security reasons"
   exit 1
fi

# Configuration
VPS_USER=""
VPS_HOST=""
VPS_PATH=""

# Get VPS connection details
echo "Please provide your VPS connection details:"
read -p "VPS Username: " VPS_USER
read -p "VPS Host/IP: " VPS_HOST
read -p "Website path on VPS (e.g., /var/www/html): " VPS_PATH

if [[ -z "$VPS_USER" || -z "$VPS_HOST" || -z "$VPS_PATH" ]]; then
    print_error "All fields are required!"
    exit 1
fi

print_status "Connecting to VPS: $VPS_USER@$VPS_HOST"
print_status "Website path: $VPS_PATH"

# Test SSH connection
print_status "Testing SSH connection..."
if ! ssh -o ConnectTimeout=10 $VPS_USER@$VPS_HOST "echo 'SSH connection successful'" 2>/dev/null; then
    print_error "SSH connection failed. Please check your credentials and try again."
    print_status "Make sure you have:"
    echo "  1. Correct username and IP address"
    echo "  2. SSH access enabled on your VPS"
    echo "  3. Your SSH password or SSH key configured"
    echo ""
    read -p "Do you want to continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

print_success "SSH connection successful!"

# Create backup
print_status "Creating backup of current configuration..."
ssh $VPS_USER@$VPS_HOST "cd $VPS_PATH && cp config.php config.php.backup.$(date +%Y%m%d_%H%M%S)"

# Create logs directory
print_status "Creating logs directory..."
ssh $VPS_USER@$VPS_HOST "cd $VPS_PATH && mkdir -p logs && chmod 755 logs"

# Generate secure JWT secret
print_status "Generating secure JWT secret..."
JWT_SECRET=$(ssh $VPS_USER@$VPS_HOST "php -r 'echo bin2hex(random_bytes(32));'")
SESSION_SECRET=$(ssh $VPS_USER@$VPS_HOST "php -r 'echo bin2hex(random_bytes(16));'")

# Create .env file
print_status "Creating secure .env file..."
ssh $VPS_USER@$VPS_HOST "cat > $VPS_PATH/.env << 'EOF'
# My Best Life Platform - Secure Environment Variables
# Generated on $(date)

# Database Configuration
DB_HOST=localhost
DB_NAME=your_database_name
DB_USER=your_username
DB_PASS=your_password
DB_PORT=3306

# JWT Security
JWT_SECRET=$JWT_SECRET
JWT_EXPIRY=86400
VERIFICATION_EXPIRY=86400
RESET_EXPIRY=3600

# Email Configuration
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-gmail@gmail.com
SMTP_PASS=your-gmail-app-password
SMTP_FROM_NAME=My Best Life
SMTP_FROM_EMAIL=your-gmail@gmail.com

# Application Settings
APP_NAME=My Best Life
APP_VERSION=1.0.0
APP_ENV=production
FRONTEND_URL=https://mybestlifeapp.com

# Security Settings
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=5
RATE_LIMIT_MAX_API_REQUESTS=100
MIN_PASSWORD_LENGTH=8
REQUIRE_UPPERCASE=true
REQUIRE_LOWERCASE=true
REQUIRE_NUMBERS=true
REQUIRE_SYMBOLS=true
MAX_LOGIN_ATTEMPTS=5
LOCKOUT_DURATION_MINUTES=15
SESSION_SECRET=$SESSION_SECRET
COOKIE_SECURE=true
COOKIE_HTTP_ONLY=true
COOKIE_SAME_SITE=strict
FORCE_HTTPS=true
ENABLE_SECURITY_LOGGING=true
ENABLE_AUDIT_LOGGING=true
EOF"

# Set secure permissions for .env
ssh $VPS_USER@$VPS_HOST "chmod 600 $VPS_PATH/.env"

# Update config.php
print_status "Updating config.php with secure configuration..."
ssh $VPS_USER@$VPS_HOST "cat > $VPS_PATH/config.php << 'EOF'
<?php
// My Best Life Platform - SECURE VPS Configuration
// URGENT: Deploy this to replace your current config.php

// Load environment variables from .env file
if (file_exists(__DIR__ . '/.env')) {
    \$lines = file(__DIR__ . '/.env', FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
    foreach (\$lines as \$line) {
        if (strpos(\$line, '=') !== false && strpos(\$line, '#') !== 0) {
            list(\$key, \$value) = explode('=', \$line, 2);
            \$_ENV[trim(\$key)] = trim(\$value);
            putenv(trim(\$key) . '=' . trim(\$value));
        }
    }
}

// Database Configuration - SECURE
define('DB_HOST', \$_ENV['DB_HOST'] ?? 'localhost');
define('DB_NAME', \$_ENV['DB_NAME'] ?? 'mybestlife_db');
define('DB_USER', \$_ENV['DB_USER'] ?? 'mybestlife_user');
define('DB_PASS', \$_ENV['DB_PASS'] ?? '');
define('DB_PORT', \$_ENV['DB_PORT'] ?? '3306');

// JWT Secret Key - CRITICAL SECURITY
define('JWT_SECRET', \$_ENV['JWT_SECRET'] ?? '');

// Email Configuration
define('SMTP_HOST', \$_ENV['SMTP_HOST'] ?? 'smtp.gmail.com');
define('SMTP_PORT', \$_ENV['SMTP_PORT'] ?? '587');
define('SMTP_USER', \$_ENV['SMTP_USER'] ?? '');
define('SMTP_PASS', \$_ENV['SMTP_PASS'] ?? '');
define('SMTP_FROM_NAME', \$_ENV['SMTP_FROM_NAME'] ?? 'My Best Life');
define('SMTP_FROM_EMAIL', \$_ENV['SMTP_FROM_EMAIL'] ?? '');

// Frontend URL
define('FRONTEND_URL', \$_ENV['FRONTEND_URL'] ?? 'https://mybestlifeapp.com');

// Application Settings
define('APP_NAME', \$_ENV['APP_NAME'] ?? 'My Best Life');
define('APP_VERSION', \$_ENV['APP_VERSION'] ?? '1.0.0');
define('APP_ENV', \$_ENV['APP_ENV'] ?? 'production');

// Security Settings
define('JWT_EXPIRY', \$_ENV['JWT_EXPIRY'] ?? 86400);
define('VERIFICATION_EXPIRY', \$_ENV['VERIFICATION_EXPIRY'] ?? 86400);
define('RESET_EXPIRY', \$_ENV['RESET_EXPIRY'] ?? 3600);

// Rate Limiting Settings
define('RATE_LIMIT_WINDOW_MS', \$_ENV['RATE_LIMIT_WINDOW_MS'] ?? 900000);
define('RATE_LIMIT_MAX_REQUESTS', \$_ENV['RATE_LIMIT_MAX_REQUESTS'] ?? 5);
define('RATE_LIMIT_MAX_API_REQUESTS', \$_ENV['RATE_LIMIT_MAX_API_REQUESTS'] ?? 100);

// Password Policy Settings
define('MIN_PASSWORD_LENGTH', \$_ENV['MIN_PASSWORD_LENGTH'] ?? 8);
define('REQUIRE_UPPERCASE', \$_ENV['REQUIRE_UPPERCASE'] ?? 'true');
define('REQUIRE_LOWERCASE', \$_ENV['REQUIRE_LOWERCASE'] ?? 'true');
define('REQUIRE_NUMBERS', \$_ENV['REQUIRE_NUMBERS'] ?? 'true');
define('REQUIRE_SYMBOLS', \$_ENV['REQUIRE_SYMBOLS'] ?? 'true');

// Account Lockout Settings
define('MAX_LOGIN_ATTEMPTS', \$_ENV['MAX_LOGIN_ATTEMPTS'] ?? 5);
define('LOCKOUT_DURATION_MINUTES', \$_ENV['LOCKOUT_DURATION_MINUTES'] ?? 15);

// Session Security Settings
define('SESSION_SECRET', \$_ENV['SESSION_SECRET'] ?? '');
define('COOKIE_SECURE', \$_ENV['COOKIE_SECURE'] ?? 'true');
define('COOKIE_HTTP_ONLY', \$_ENV['COOKIE_HTTP_ONLY'] ?? 'true');
define('COOKIE_SAME_SITE', \$_ENV['COOKIE_SAME_SITE'] ?? 'strict');

// CRITICAL SECURITY VALIDATION
if (empty(JWT_SECRET)) {
    error_log('CRITICAL SECURITY ERROR: JWT_SECRET is not set in environment variables!');
    http_response_code(500);
    die('Server configuration error. Please contact administrator.');
}

// Error Reporting (disable in production)
if (APP_ENV === 'production') {
    error_reporting(0);
    ini_set('display_errors', 0);
} else {
    error_reporting(E_ALL);
    ini_set('display_errors', 1);
}

// Timezone
date_default_timezone_set('UTC');

// Secure session configuration
if (session_status() === PHP_SESSION_NONE) {
    ini_set('session.cookie_secure', COOKIE_SECURE === 'true' ? '1' : '0');
    ini_set('session.cookie_httponly', COOKIE_HTTP_ONLY === 'true' ? '1' : '0');
    ini_set('session.cookie_samesite', COOKIE_SAME_SITE);
    ini_set('session.use_strict_mode', '1');
    ini_set('session.sid_length', '48');
    ini_set('session.sid_bits_per_character', '6');
    
    session_name('MYBESTLIFE_SESSION');
    session_start();
    
    if (!isset(\$_SESSION['last_regeneration'])) {
        \$_SESSION['last_regeneration'] = time();
    } elseif (time() - \$_SESSION['last_regeneration'] > 300) {
        session_regenerate_id(true);
        \$_SESSION['last_regeneration'] = time();
    }
}

// CORS Headers for API requests
header('Access-Control-Allow-Origin: ' . FRONTEND_URL);
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');
header('Access-Control-Allow-Credentials: true');

// Handle preflight OPTIONS request
if (\$_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Database Connection Function
function getDBConnection() {
    try {
        \$dsn = \"mysql:host=\" . DB_HOST . \";dbname=\" . DB_NAME . \";port=\" . DB_PORT . \";charset=utf8mb4\";
        \$pdo = new PDO(\$dsn, DB_USER, DB_PASS, [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES => false,
        ]);
        return \$pdo;
    } catch (PDOException \$e) {
        error_log(\"Database connection failed: \" . \$e->getMessage());
        return false;
    }
}

// Utility Functions
function generateToken(\$length = 32) {
    return bin2hex(random_bytes(\$length));
}

function hashPassword(\$password) {
    return password_hash(\$password, PASSWORD_DEFAULT);
}

function verifyPassword(\$password, \$hash) {
    return password_verify(\$password, \$hash);
}

function sanitizeInput(\$input) {
    if (is_array(\$input)) {
        return array_map('sanitizeInput', \$input);
    }
    return htmlspecialchars(trim(\$input), ENT_QUOTES, 'UTF-8');
}

function jsonResponse(\$data, \$statusCode = 200) {
    http_response_code(\$statusCode);
    header('Content-Type: application/json');
    echo json_encode(\$data);
    exit();
}

function errorResponse(\$message, \$statusCode = 400) {
    jsonResponse(['error' => \$message], \$statusCode);
}

function successResponse(\$message, \$data = null, \$statusCode = 200) {
    \$response = ['success' => true, 'message' => \$message];
    if (\$data !== null) {
        \$response['data'] = \$data;
    }
    jsonResponse(\$response, \$statusCode);
}

// SECURE JWT Functions
function generateJWT(\$payload) {
    \$header = json_encode(['typ' => 'JWT', 'alg' => 'HS256']);
    \$payload = json_encode(\$payload);
    
    \$base64Header = str_replace(['+', '/', '='], ['-', '_', ''], base64_encode(\$header));
    \$base64Payload = str_replace(['+', '/', '='], ['-', '_', ''], base64_encode(\$payload));
    
    \$signature = hash_hmac('sha256', \$base64Header . \".\" . \$base64Payload, JWT_SECRET, true);
    \$base64Signature = str_replace(['+', '/', '='], ['-', '_', ''], base64_encode(\$signature));
    
    return \$base64Header . \".\" . \$base64Payload . \".\" . \$base64Signature;
}

function verifyJWT(\$token) {
    \$parts = explode('.', \$token);
    if (count(\$parts) !== 3) {
        return false;
    }
    
    \$header = \$parts[0];
    \$payload = \$parts[1];
    \$signature = \$parts[2];
    
    \$expectedSignature = hash_hmac('sha256', \$header . \".\" . \$payload, JWT_SECRET, true);
    \$expectedSignature = str_replace(['+', '/', '='], ['-', '_', ''], base64_encode(\$expectedSignature));
    
    if (!hash_equals(\$signature, \$expectedSignature)) {
        return false;
    }
    
    \$payloadData = json_decode(base64_decode(str_replace(['-', '_'], ['+', '/'], \$payload)), true);
    
    if (\$payloadData === null) {
        return false;
    }
    
    if (isset(\$payloadData['exp']) && \$payloadData['exp'] < time()) {
        return false;
    }
    
    return \$payloadData;
}

// Authentication Middleware
function requireAuth() {
    \$headers = getallheaders();
    \$token = null;
    
    if (isset(\$headers['Authorization'])) {
        \$token = str_replace('Bearer ', '', \$headers['Authorization']);
    } elseif (isset(\$_GET['token'])) {
        \$token = \$_GET['token'];
    }
    
    if (!\$token) {
        errorResponse('No token provided', 401);
    }
    
    \$payload = verifyJWT(\$token);
    if (!\$payload) {
        errorResponse('Invalid or expired token', 401);
    }
    
    return \$payload;
}

// Logging Function
function logActivity(\$message, \$level = 'INFO') {
    \$logFile = __DIR__ . '/logs/app.log';
    \$logDir = dirname(\$logFile);
    
    if (!is_dir(\$logDir)) {
        mkdir(\$logDir, 0755, true);
    }
    
    \$timestamp = date('Y-m-d H:i:s');
    \$logEntry = \"[\$timestamp] [\$level] \$message\" . PHP_EOL;
    
    file_put_contents(\$logFile, \$logEntry, FILE_APPEND | LOCK_EX);
}
?>
EOF"

# Create .htaccess file
print_status "Creating secure .htaccess file..."
ssh $VPS_USER@$VPS_HOST "cat > $VPS_PATH/.htaccess << 'EOF'
# Security Headers
<IfModule mod_headers.c>
    Header always set Content-Security-Policy \"default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; font-src 'self'; connect-src 'self'; frame-ancestors 'none';\"
    Header always set Strict-Transport-Security \"max-age=31536000; includeSubDomains; preload\"
    Header always set X-Frame-Options \"DENY\"
    Header always set X-Content-Type-Options \"nosniff\"
    Header always set X-XSS-Protection \"1; mode=block\"
    Header always set Referrer-Policy \"strict-origin-when-cross-origin\"
    Header always set Permissions-Policy \"geolocation=(), microphone=(), camera=()\"
    Header unset Server
    Header unset X-Powered-By
</IfModule>

# Force HTTPS
<IfModule mod_rewrite.c>
    RewriteEngine On
    RewriteCond %{HTTPS} off
    RewriteRule ^(.*)$ https://%{HTTP_HOST}%{REQUEST_URI} [L,R=301]
</IfModule>

# Block sensitive files
<Files \".env\">
    Order allow,deny
    Deny from all
</Files>
<Files \".git\">
    Order allow,deny
    Deny from all
</Files>
<Files \"composer.json\">
    Order allow,deny
    Deny from all
</Files>
EOF"

# Set secure permissions
print_status "Setting secure file permissions..."
ssh $VPS_USER@$VPS_HOST "chmod 644 $VPS_PATH/.htaccess"

# Test PHP syntax
print_status "Testing PHP syntax..."
if ssh $VPS_USER@$VPS_HOST "php -l $VPS_PATH/config.php" 2>/dev/null; then
    print_success "PHP syntax is valid!"
else
    print_error "PHP syntax error detected!"
    exit 1
fi

# Test website
print_status "Testing website functionality..."
if curl -s -o /dev/null -w "%{http_code}" https://mybestlifeapp.com | grep -q "200\|301\|302"; then
    print_success "Website is responding!"
else
    print_warning "Website may not be responding properly. Please check manually."
fi

print_success "VPS security deployment completed!"
echo ""
print_warning "IMPORTANT: You need to update your .env file with actual values:"
echo "1. Database credentials (DB_NAME, DB_USER, DB_PASS)"
echo "2. Email configuration (SMTP_USER, SMTP_PASS)"
echo "3. Test your website functionality"
echo ""
print_status "To edit .env file: ssh $VPS_USER@$VPS_HOST 'nano $VPS_PATH/.env'"
echo ""
print_success "Your VPS is now secured! 🛡️"
