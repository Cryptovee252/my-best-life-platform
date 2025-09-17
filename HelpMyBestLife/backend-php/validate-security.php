<?php
// My Best Life Platform - Security Validation Script
// Comprehensive security testing and validation

require_once __DIR__ . '/config.php';
require_once __DIR__ . '/includes/security-middleware.php';
require_once __DIR__ . '/includes/secure-jwt.php';

class SecurityValidator {
    
    private $results = [];
    private $passed = 0;
    private $failed = 0;
    
    public function runAllTests() {
        echo "🛡️  My Best Life Platform - Security Validation\n";
        echo "============================================\n\n";
        
        $this->testEnvironmentVariables();
        $this->testPasswordSecurity();
        $this->testJWTSecurity();
        $this->testInputSanitization();
        $this->testRateLimiting();
        $this->testAccountLockout();
        $this->testSecurityHeaders();
        $this->testDatabaseSecurity();
        $this->testFilePermissions();
        $this->testSSLConfiguration();
        
        $this->displayResults();
        return $this->passed === ($this->passed + $this->failed);
    }
    
    private function testEnvironmentVariables() {
        echo "🔐 Testing Environment Variables...\n";
        
        $requiredVars = [
            'JWT_SECRET' => JWT_SECRET,
            'DB_PASS' => DB_PASS,
            'SMTP_PASS' => SMTP_PASS,
            'SESSION_SECRET' => SESSION_SECRET
        ];
        
        foreach ($requiredVars as $var => $value) {
            if (empty($value)) {
                $this->addResult("❌ $var is not set", false);
            } elseif (strlen($value) < 32) {
                $this->addResult("⚠️  $var is too short (minimum 32 characters)", false);
            } else {
                $this->addResult("✅ $var is properly configured", true);
            }
        }
        
        // Check for hardcoded secrets
        if (strpos(JWT_SECRET, 'mybestlife-super-secret') !== false) {
            $this->addResult("❌ JWT_SECRET contains hardcoded value", false);
        } else {
            $this->addResult("✅ JWT_SECRET is not hardcoded", true);
        }
    }
    
    private function testPasswordSecurity() {
        echo "\n🔒 Testing Password Security...\n";
        
        $testPasswords = [
            'weak' => '123456',
            'medium' => 'password123',
            'strong' => 'MySecure123!',
            'very_strong' => 'MyVerySecurePassword123!@#'
        ];
        
        foreach ($testPasswords as $type => $password) {
            $errors = SecurityMiddleware::validatePassword($password);
            if (empty($errors)) {
                $this->addResult("✅ $type password passes validation", true);
            } else {
                $this->addResult("❌ $type password fails: " . implode(', ', $errors), false);
            }
        }
        
        // Test password hashing
        $testPassword = 'TestPassword123!';
        $hashed = SecurityMiddleware::hashPassword($testPassword);
        $verified = SecurityMiddleware::verifyPassword($testPassword, $hashed);
        
        if ($verified) {
            $this->addResult("✅ Password hashing and verification works", true);
        } else {
            $this->addResult("❌ Password hashing and verification failed", false);
        }
    }
    
    private function testJWTSecurity() {
        echo "\n🎫 Testing JWT Security...\n";
        
        $testPayload = [
            'user_id' => 1,
            'email' => 'test@example.com',
            'username' => 'testuser'
        ];
        
        // Test token generation
        $token = SecureJWT::generateToken($testPayload);
        if (empty($token)) {
            $this->addResult("❌ JWT token generation failed", false);
        } else {
            $this->addResult("✅ JWT token generation works", true);
        }
        
        // Test token verification
        $verifiedPayload = SecureJWT::verifyToken($token);
        if ($verifiedPayload && $verifiedPayload['user_id'] === 1) {
            $this->addResult("✅ JWT token verification works", true);
        } else {
            $this->addResult("❌ JWT token verification failed", false);
        }
        
        // Test token blacklisting
        SecureJWT::blacklistToken($token);
        $blacklistedPayload = SecureJWT::verifyTokenSecure($token);
        if (!$blacklistedPayload) {
            $this->addResult("✅ JWT token blacklisting works", true);
        } else {
            $this->addResult("❌ JWT token blacklisting failed", false);
        }
        
        // Test refresh token
        $refreshToken = SecureJWT::generateRefreshToken(1);
        $refreshPayload = SecureJWT::verifyRefreshToken($refreshToken);
        if ($refreshPayload && $refreshPayload['type'] === 'refresh') {
            $this->addResult("✅ Refresh token generation and verification works", true);
        } else {
            $this->addResult("❌ Refresh token generation and verification failed", false);
        }
    }
    
    private function testInputSanitization() {
        echo "\n🧹 Testing Input Sanitization...\n";
        
        $maliciousInputs = [
            '<script>alert("xss")</script>',
            'SELECT * FROM users WHERE id = 1',
            '../../../etc/passwd',
            'javascript:alert("xss")',
            '<img src=x onerror=alert("xss")>'
        ];
        
        foreach ($maliciousInputs as $input) {
            $sanitized = SecurityMiddleware::sanitizeInput($input);
            
            // Check if dangerous patterns are removed
            $dangerousPatterns = ['<script>', 'SELECT *', '../', 'javascript:', 'onerror='];
            $isSafe = true;
            
            foreach ($dangerousPatterns as $pattern) {
                if (stripos($sanitized, $pattern) !== false) {
                    $isSafe = false;
                    break;
                }
            }
            
            if ($isSafe) {
                $this->addResult("✅ Input sanitization removes dangerous patterns", true);
            } else {
                $this->addResult("❌ Input sanitization failed to remove dangerous patterns", false);
            }
        }
    }
    
    private function testRateLimiting() {
        echo "\n⏱️  Testing Rate Limiting...\n";
        
        $testIdentifier = 'test_rate_limit_' . time();
        $maxRequests = 3;
        $windowMs = 1000; // 1 second for testing
        
        // Test normal requests
        for ($i = 0; $i < $maxRequests; $i++) {
            $allowed = SecurityMiddleware::checkRateLimit($testIdentifier, $maxRequests, $windowMs);
            if (!$allowed) {
                $this->addResult("❌ Rate limiting blocked request $i", false);
                return;
            }
        }
        $this->addResult("✅ Rate limiting allows normal requests", true);
        
        // Test rate limit exceeded
        $blocked = SecurityMiddleware::checkRateLimit($testIdentifier, $maxRequests, $windowMs);
        if (!$blocked) {
            $this->addResult("❌ Rate limiting failed to block excess requests", false);
        } else {
            $this->addResult("✅ Rate limiting blocks excess requests", true);
        }
    }
    
    private function testAccountLockout() {
        echo "\n🔒 Testing Account Lockout...\n";
        
        $testUserId = 999999; // Non-existent user ID for testing
        $testEmail = 'test@example.com';
        
        // Test failed login handling
        for ($i = 0; $i < 3; $i++) {
            SecurityMiddleware::handleFailedLogin($testUserId, $testEmail);
        }
        
        $lockoutStatus = SecurityMiddleware::checkAccountLockout($testUserId);
        if (!$lockoutStatus['locked']) {
            $this->addResult("❌ Account lockout not triggered after multiple failures", false);
        } else {
            $this->addResult("✅ Account lockout triggered after multiple failures", true);
        }
        
        // Test lockout reset
        SecurityMiddleware::resetFailedLoginAttempts($testUserId);
        $lockoutStatus = SecurityMiddleware::checkAccountLockout($testUserId);
        if ($lockoutStatus['locked']) {
            $this->addResult("❌ Account lockout not reset after successful login", false);
        } else {
            $this->addResult("✅ Account lockout reset after successful login", true);
        }
    }
    
    private function testSecurityHeaders() {
        echo "\n🛡️  Testing Security Headers...\n";
        
        // Test if security headers are set
        $headers = headers_list();
        $requiredHeaders = [
            'Content-Security-Policy',
            'Strict-Transport-Security',
            'X-Frame-Options',
            'X-Content-Type-Options',
            'X-XSS-Protection'
        ];
        
        foreach ($requiredHeaders as $header) {
            $found = false;
            foreach ($headers as $h) {
                if (stripos($h, $header) !== false) {
                    $found = true;
                    break;
                }
            }
            
            if ($found) {
                $this->addResult("✅ Security header $header is set", true);
            } else {
                $this->addResult("❌ Security header $header is missing", false);
            }
        }
    }
    
    private function testDatabaseSecurity() {
        echo "\n🗄️  Testing Database Security...\n";
        
        try {
            $pdo = getDBConnection();
            if ($pdo) {
                $this->addResult("✅ Database connection successful", true);
                
                // Test prepared statement
                $stmt = $pdo->prepare("SELECT 1 as test");
                $stmt->execute();
                $result = $stmt->fetch();
                
                if ($result && $result['test'] == 1) {
                    $this->addResult("✅ Prepared statements work correctly", true);
                } else {
                    $this->addResult("❌ Prepared statements failed", false);
                }
            } else {
                $this->addResult("❌ Database connection failed", false);
            }
        } catch (Exception $e) {
            $this->addResult("❌ Database test failed: " . $e->getMessage(), false);
        }
    }
    
    private function testFilePermissions() {
        echo "\n📁 Testing File Permissions...\n";
        
        $files = [
            '.env' => 0600,
            '.htaccess' => 0644,
            'logs/' => 0755
        ];
        
        foreach ($files as $file => $expectedPerms) {
            $fullPath = __DIR__ . '/' . $file;
            if (file_exists($fullPath)) {
                $actualPerms = fileperms($fullPath) & 0777;
                if ($actualPerms === $expectedPerms) {
                    $this->addResult("✅ File permissions correct for $file", true);
                } else {
                    $this->addResult("❌ File permissions incorrect for $file (expected: $expectedPerms, actual: $actualPerms)", false);
                }
            } else {
                $this->addResult("⚠️  File $file does not exist", false);
            }
        }
    }
    
    private function testSSLConfiguration() {
        echo "\n🔐 Testing SSL Configuration...\n";
        
        // Test HTTPS enforcement
        if (isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on') {
            $this->addResult("✅ HTTPS is enabled", true);
        } else {
            $this->addResult("❌ HTTPS is not enabled", false);
        }
        
        // Test SSL certificate (if available)
        if (function_exists('openssl_x509_parse')) {
            $this->addResult("✅ OpenSSL extension available for SSL testing", true);
        } else {
            $this->addResult("⚠️  OpenSSL extension not available", false);
        }
    }
    
    private function addResult($message, $passed) {
        $this->results[] = $message;
        if ($passed) {
            $this->passed++;
        } else {
            $this->failed++;
        }
    }
    
    private function displayResults() {
        echo "\n📊 Security Validation Results\n";
        echo "============================\n";
        
        foreach ($this->results as $result) {
            echo "$result\n";
        }
        
        echo "\n📈 Summary\n";
        echo "==========\n";
        echo "✅ Passed: {$this->passed}\n";
        echo "❌ Failed: {$this->failed}\n";
        echo "📊 Total: " . ($this->passed + $this->failed) . "\n";
        
        $percentage = round(($this->passed / ($this->passed + $this->failed)) * 100, 2);
        echo "🎯 Success Rate: {$percentage}%\n";
        
        if ($percentage >= 90) {
            echo "\n🎉 EXCELLENT! Security implementation is production-ready!\n";
        } elseif ($percentage >= 80) {
            echo "\n✅ GOOD! Security implementation is mostly ready with minor issues.\n";
        } elseif ($percentage >= 70) {
            echo "\n⚠️  FAIR! Security implementation needs improvement.\n";
        } else {
            echo "\n❌ POOR! Security implementation needs significant work.\n";
        }
        
        echo "\n🛡️  Security Score: " . $this->calculateSecurityScore() . "/10\n";
    }
    
    private function calculateSecurityScore() {
        $total = $this->passed + $this->failed;
        if ($total === 0) return 0;
        
        $percentage = ($this->passed / $total) * 100;
        
        if ($percentage >= 95) return 10;
        if ($percentage >= 90) return 9;
        if ($percentage >= 85) return 8;
        if ($percentage >= 80) return 7;
        if ($percentage >= 75) return 6;
        if ($percentage >= 70) return 5;
        if ($percentage >= 60) return 4;
        if ($percentage >= 50) return 3;
        if ($percentage >= 40) return 2;
        if ($percentage >= 30) return 1;
        return 0;
    }
}

// Run validation if called from command line
if (php_sapi_name() === 'cli') {
    $validator = new SecurityValidator();
    $success = $validator->runAllTests();
    exit($success ? 0 : 1);
}
?>
