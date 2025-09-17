<?php
// My Best Life Platform - Security Setup Script
// This script helps set up secure environment variables and validates security configuration

require_once __DIR__ . '/config.php';

class SecuritySetup {
    
    public static function generateSecureSecrets() {
        echo "🔐 Generating secure secrets...\n";
        
        $secrets = [
            'JWT_SECRET' => bin2hex(random_bytes(64)),
            'SESSION_SECRET' => bin2hex(random_bytes(32)),
            'DB_PASS' => bin2hex(random_bytes(16)),
            'SMTP_PASS' => 'your-gmail-app-password-here'
        ];
        
        echo "Generated secrets:\n";
        foreach ($secrets as $key => $value) {
            echo "$key=$value\n";
        }
        
        return $secrets;
    }
    
    public static function createEnvFile($secrets) {
        echo "\n📝 Creating .env file...\n";
        
        $envContent = "# My Best Life Platform - Environment Variables\n";
        $envContent .= "# Generated on " . date('Y-m-d H:i:s') . "\n\n";
        
        $envContent .= "# Database Configuration\n";
        $envContent .= "DB_HOST=localhost\n";
        $envContent .= "DB_NAME=mybestlife_db\n";
        $envContent .= "DB_USER=mybestlife_user\n";
        $envContent .= "DB_PASS=" . $secrets['DB_PASS'] . "\n";
        $envContent .= "DB_PORT=3306\n\n";
        
        $envContent .= "# JWT Security\n";
        $envContent .= "JWT_SECRET=" . $secrets['JWT_SECRET'] . "\n";
        $envContent .= "JWT_EXPIRY=86400\n";
        $envContent .= "VERIFICATION_EXPIRY=86400\n";
        $envContent .= "RESET_EXPIRY=3600\n\n";
        
        $envContent .= "# Email Configuration\n";
        $envContent .= "SMTP_HOST=smtp.gmail.com\n";
        $envContent .= "SMTP_PORT=587\n";
        $envContent .= "SMTP_USER=your-gmail@gmail.com\n";
        $envContent .= "SMTP_PASS=" . $secrets['SMTP_PASS'] . "\n";
        $envContent .= "SMTP_FROM_NAME=My Best Life\n";
        $envContent .= "SMTP_FROM_EMAIL=your-gmail@gmail.com\n\n";
        
        $envContent .= "# Application Configuration\n";
        $envContent .= "APP_NAME=My Best Life\n";
        $envContent .= "APP_VERSION=1.0.0\n";
        $envContent .= "APP_ENV=production\n";
        $envContent .= "FRONTEND_URL=https://mybestlifeapp.com\n\n";
        
        $envContent .= "# Security Configuration\n";
        $envContent .= "RATE_LIMIT_WINDOW_MS=900000\n";
        $envContent .= "RATE_LIMIT_MAX_REQUESTS=5\n";
        $envContent .= "RATE_LIMIT_MAX_API_REQUESTS=100\n\n";
        
        $envContent .= "# Password Policy\n";
        $envContent .= "MIN_PASSWORD_LENGTH=8\n";
        $envContent .= "REQUIRE_UPPERCASE=true\n";
        $envContent .= "REQUIRE_LOWERCASE=true\n";
        $envContent .= "REQUIRE_NUMBERS=true\n";
        $envContent .= "REQUIRE_SYMBOLS=true\n\n";
        
        $envContent .= "# Account Lockout\n";
        $envContent .= "MAX_LOGIN_ATTEMPTS=5\n";
        $envContent .= "LOCKOUT_DURATION_MINUTES=15\n\n";
        
        $envContent .= "# Session Security\n";
        $envContent .= "SESSION_SECRET=" . $secrets['SESSION_SECRET'] . "\n";
        $envContent .= "COOKIE_SECURE=true\n";
        $envContent .= "COOKIE_HTTP_ONLY=true\n";
        $envContent .= "COOKIE_SAME_SITE=strict\n\n";
        
        $envContent .= "# SSL/TLS Configuration\n";
        $envContent .= "FORCE_HTTPS=true\n\n";
        
        $envContent .= "# Monitoring & Logging\n";
        $envContent .= "LOG_LEVEL=info\n";
        $envContent .= "LOG_FILE_PATH=/var/log/mybestlife/app.log\n";
        $envContent .= "ENABLE_SECURITY_LOGGING=true\n";
        $envContent .= "ENABLE_AUDIT_LOGGING=true\n";
        $envContent .= "ENABLE_RATE_LIMIT_LOGGING=true\n";
        
        $envFile = __DIR__ . '/.env';
        
        if (file_put_contents($envFile, $envContent)) {
            echo "✅ .env file created successfully!\n";
            echo "📁 Location: $envFile\n";
            
            // Set secure permissions
            chmod($envFile, 0600);
            echo "🔒 Set secure file permissions (600)\n";
        } else {
            echo "❌ Failed to create .env file\n";
            return false;
        }
        
        return true;
    }
    
    public static function createLogDirectories() {
        echo "\n📁 Creating log directories...\n";
        
        $logDirs = [
            __DIR__ . '/logs',
            __DIR__ . '/logs/security',
            __DIR__ . '/logs/audit',
            __DIR__ . '/logs/errors'
        ];
        
        foreach ($logDirs as $dir) {
            if (!is_dir($dir)) {
                if (mkdir($dir, 0755, true)) {
                    echo "✅ Created directory: $dir\n";
                } else {
                    echo "❌ Failed to create directory: $dir\n";
                }
            } else {
                echo "📁 Directory already exists: $dir\n";
            }
        }
    }
    
    public static function validateSecurityConfiguration() {
        echo "\n🔍 Validating security configuration...\n";
        
        $checks = [
            'JWT_SECRET' => !empty(JWT_SECRET),
            'DB_PASS' => !empty(DB_PASS),
            'SMTP_PASS' => !empty(SMTP_PASS),
            'FRONTEND_URL' => !empty(FRONTEND_URL),
            'MIN_PASSWORD_LENGTH' => MIN_PASSWORD_LENGTH >= 8,
            'RATE_LIMIT_MAX_REQUESTS' => RATE_LIMIT_MAX_REQUESTS <= 10,
            'MAX_LOGIN_ATTEMPTS' => MAX_LOGIN_ATTEMPTS <= 10
        ];
        
        $allPassed = true;
        
        foreach ($checks as $check => $passed) {
            if ($passed) {
                echo "✅ $check: OK\n";
            } else {
                echo "❌ $check: FAILED\n";
                $allPassed = false;
            }
        }
        
        if ($allPassed) {
            echo "\n🎉 All security checks passed!\n";
        } else {
            echo "\n⚠️  Some security checks failed. Please review your configuration.\n";
        }
        
        return $allPassed;
    }
    
    public static function testDatabaseConnection() {
        echo "\n🗄️  Testing database connection...\n";
        
        try {
            $pdo = getDBConnection();
            if ($pdo) {
                echo "✅ Database connection successful\n";
                
                // Test a simple query
                $stmt = $pdo->query("SELECT 1");
                if ($stmt) {
                    echo "✅ Database query test successful\n";
                    return true;
                }
            }
        } catch (Exception $e) {
            echo "❌ Database connection failed: " . $e->getMessage() . "\n";
        }
        
        return false;
    }
    
    public static function runSecurityTests() {
        echo "\n🧪 Running security tests...\n";
        
        // Test password hashing
        $testPassword = 'TestPassword123!';
        $hashedPassword = SecurityMiddleware::hashPassword($testPassword);
        $verifyResult = SecurityMiddleware::verifyPassword($testPassword, $hashedPassword);
        
        if ($verifyResult) {
            echo "✅ Password hashing test passed\n";
        } else {
            echo "❌ Password hashing test failed\n";
        }
        
        // Test JWT generation and verification
        $testPayload = ['user_id' => 1, 'email' => 'test@example.com'];
        $token = SecureJWT::generateToken($testPayload);
        $verifiedPayload = SecureJWT::verifyToken($token);
        
        if ($verifiedPayload && $verifiedPayload['user_id'] === 1) {
            echo "✅ JWT generation and verification test passed\n";
        } else {
            echo "❌ JWT generation and verification test failed\n";
        }
        
        // Test input sanitization
        $maliciousInput = '<script>alert("xss")</script>';
        $sanitizedInput = SecurityMiddleware::sanitizeInput($maliciousInput);
        
        if (strpos($sanitizedInput, '<script>') === false) {
            echo "✅ Input sanitization test passed\n";
        } else {
            echo "❌ Input sanitization test failed\n";
        }
    }
    
    public static function displaySecurityRecommendations() {
        echo "\n📋 Security Recommendations:\n";
        echo "1. 🔒 Change all default passwords and secrets\n";
        echo "2. 🛡️  Enable HTTPS with proper SSL certificates\n";
        echo "3. 📊 Set up security monitoring and alerting\n";
        echo "4. 🔄 Regularly update dependencies and packages\n";
        echo "5. 📝 Implement regular security audits\n";
        echo "6. 🚨 Set up incident response procedures\n";
        echo "7. 👥 Train team members on security best practices\n";
        echo "8. 🔍 Monitor logs for suspicious activity\n";
        echo "9. 💾 Implement secure backup procedures\n";
        echo "10. 🏗️  Use secure coding practices\n";
    }
}

// Run the security setup
echo "🛡️  My Best Life Platform - Security Setup\n";
echo "==========================================\n";

// Check if running from command line
if (php_sapi_name() !== 'cli') {
    die("This script must be run from the command line.\n");
}

// Generate secrets
$secrets = SecuritySetup::generateSecureSecrets();

// Create .env file
SecuritySetup::createEnvFile($secrets);

// Create log directories
SecuritySetup::createLogDirectories();

// Validate configuration
SecuritySetup::validateSecurityConfiguration();

// Test database connection
SecuritySetup::testDatabaseConnection();

// Run security tests
SecuritySetup::runSecurityTests();

// Display recommendations
SecuritySetup::displaySecurityRecommendations();

echo "\n🎉 Security setup completed!\n";
echo "Next steps:\n";
echo "1. Review and update the .env file with your actual values\n";
echo "2. Set up your database with the generated credentials\n";
echo "3. Configure your email service\n";
echo "4. Test all endpoints\n";
echo "5. Deploy to production with HTTPS\n";
?>
