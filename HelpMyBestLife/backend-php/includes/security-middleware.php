<?php
// My Best Life Platform - Security Middleware
// Comprehensive security functions for authentication, rate limiting, and input validation

require_once __DIR__ . '/../config.php';

class SecurityMiddleware {
    
    private static $rateLimitStore = [];
    private static $lockoutStore = [];
    
    /**
     * Rate limiting implementation
     */
    public static function checkRateLimit($identifier, $maxRequests = null, $windowMs = null) {
        $maxRequests = $maxRequests ?? RATE_LIMIT_MAX_REQUESTS;
        $windowMs = $windowMs ?? RATE_LIMIT_WINDOW_MS;
        
        $now = time() * 1000; // Convert to milliseconds
        $windowStart = $now - $windowMs;
        
        // Initialize rate limit store if not exists
        if (!isset(self::$rateLimitStore[$identifier])) {
            self::$rateLimitStore[$identifier] = [];
        }
        
        // Clean old requests
        self::$rateLimitStore[$identifier] = array_filter(
            self::$rateLimitStore[$identifier],
            function($timestamp) use ($windowStart) {
                return $timestamp > $windowStart;
            }
        );
        
        // Check if limit exceeded
        if (count(self::$rateLimitStore[$identifier]) >= $maxRequests) {
            self::logSecurityEvent('RATE_LIMIT_EXCEEDED', [
                'identifier' => $identifier,
                'max_requests' => $maxRequests,
                'window_ms' => $windowMs,
                'ip' => self::getClientIP(),
                'user_agent' => $_SERVER['HTTP_USER_AGENT'] ?? 'Unknown'
            ]);
            
            return false;
        }
        
        // Add current request
        self::$rateLimitStore[$identifier][] = $now;
        
        return true;
    }
    
    /**
     * Account lockout management
     */
    public static function checkAccountLockout($userId) {
        $lockoutKey = "lockout_$userId";
        
        if (isset(self::$lockoutStore[$lockoutKey])) {
            $lockoutData = self::$lockoutStore[$lockoutKey];
            
            if ($lockoutData['until'] > time()) {
                return [
                    'locked' => true,
                    'until' => $lockoutData['until'],
                    'attempts' => $lockoutData['attempts']
                ];
            } else {
                // Lockout expired, remove it
                unset(self::$lockoutStore[$lockoutKey]);
            }
        }
        
        return ['locked' => false];
    }
    
    /**
     * Handle failed login attempt
     */
    public static function handleFailedLogin($userId, $email) {
        $lockoutKey = "lockout_$userId";
        $maxAttempts = MAX_LOGIN_ATTEMPTS;
        $lockoutDuration = LOCKOUT_DURATION_MINUTES * 60; // Convert to seconds
        
        if (!isset(self::$lockoutStore[$lockoutKey])) {
            self::$lockoutStore[$lockoutKey] = [
                'attempts' => 0,
                'until' => 0
            ];
        }
        
        self::$lockoutStore[$lockoutKey]['attempts']++;
        
        if (self::$lockoutStore[$lockoutKey]['attempts'] >= $maxAttempts) {
            self::$lockoutStore[$lockoutKey]['until'] = time() + $lockoutDuration;
            
            self::logSecurityEvent('ACCOUNT_LOCKED', [
                'user_id' => $userId,
                'email' => $email,
                'attempts' => self::$lockoutStore[$lockoutKey]['attempts'],
                'lockout_until' => self::$lockoutStore[$lockoutKey]['until'],
                'ip' => self::getClientIP()
            ]);
        } else {
            self::logSecurityEvent('LOGIN_FAILURE', [
                'user_id' => $userId,
                'email' => $email,
                'attempts' => self::$lockoutStore[$lockoutKey]['attempts'],
                'ip' => self::getClientIP()
            ]);
        }
    }
    
    /**
     * Reset failed login attempts on successful login
     */
    public static function resetFailedLoginAttempts($userId) {
        $lockoutKey = "lockout_$userId";
        unset(self::$lockoutStore[$lockoutKey]);
        
        self::logSecurityEvent('LOGIN_SUCCESS', [
            'user_id' => $userId,
            'ip' => self::getClientIP()
        ]);
    }
    
    /**
     * Enhanced password validation
     */
    public static function validatePassword($password) {
        $errors = [];
        
        if (strlen($password) < MIN_PASSWORD_LENGTH) {
            $errors[] = "Password must be at least " . MIN_PASSWORD_LENGTH . " characters long";
        }
        
        if (REQUIRE_UPPERCASE === 'true' && !preg_match('/[A-Z]/', $password)) {
            $errors[] = "Password must contain at least one uppercase letter";
        }
        
        if (REQUIRE_LOWERCASE === 'true' && !preg_match('/[a-z]/', $password)) {
            $errors[] = "Password must contain at least one lowercase letter";
        }
        
        if (REQUIRE_NUMBERS === 'true' && !preg_match('/\d/', $password)) {
            $errors[] = "Password must contain at least one number";
        }
        
        if (REQUIRE_SYMBOLS === 'true' && !preg_match('/[!@#$%^&*(),.?":{}|<>]/', $password)) {
            $errors[] = "Password must contain at least one special character";
        }
        
        return $errors;
    }
    
    /**
     * Enhanced input sanitization
     */
    public static function sanitizeInput($input) {
        if (is_array($input)) {
            return array_map([self::class, 'sanitizeInput'], $input);
        }
        
        if (is_string($input)) {
            // Remove null bytes
            $input = str_replace(chr(0), '', $input);
            
            // Trim whitespace
            $input = trim($input);
            
            // HTML entity encoding
            $input = htmlspecialchars($input, ENT_QUOTES | ENT_HTML5, 'UTF-8');
            
            // Remove potential script tags
            $input = preg_replace('/<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/mi', '', $input);
            
            return $input;
        }
        
        return $input;
    }
    
    /**
     * CSRF token generation and validation
     */
    public static function generateCSRFToken() {
        if (!isset($_SESSION['csrf_token'])) {
            $_SESSION['csrf_token'] = bin2hex(random_bytes(32));
        }
        return $_SESSION['csrf_token'];
    }
    
    public static function validateCSRFToken($token) {
        return isset($_SESSION['csrf_token']) && hash_equals($_SESSION['csrf_token'], $token);
    }
    
    /**
     * Security headers
     */
    public static function setSecurityHeaders() {
        // Content Security Policy
        $csp = "default-src 'self'; " .
               "script-src 'self' 'unsafe-inline'; " .
               "style-src 'self' 'unsafe-inline'; " .
               "img-src 'self' data: https:; " .
               "font-src 'self'; " .
               "connect-src 'self'; " .
               "frame-ancestors 'none';";
        
        header("Content-Security-Policy: $csp");
        
        // HTTP Strict Transport Security
        header("Strict-Transport-Security: max-age=31536000; includeSubDomains; preload");
        
        // X-Frame-Options
        header("X-Frame-Options: DENY");
        
        // X-Content-Type-Options
        header("X-Content-Type-Options: nosniff");
        
        // X-XSS-Protection
        header("X-XSS-Protection: 1; mode=block");
        
        // Referrer-Policy
        header("Referrer-Policy: strict-origin-when-cross-origin");
        
        // Permissions-Policy
        header("Permissions-Policy: geolocation=(), microphone=(), camera=()");
        
        // Hide server information
        header_remove('X-Powered-By');
        header_remove('Server');
    }
    
    /**
     * Get client IP address
     */
    public static function getClientIP() {
        $ipKeys = ['HTTP_CF_CONNECTING_IP', 'HTTP_X_FORWARDED_FOR', 'HTTP_X_FORWARDED', 
                   'HTTP_X_CLUSTER_CLIENT_IP', 'HTTP_FORWARDED_FOR', 'HTTP_FORWARDED', 
                   'REMOTE_ADDR'];
        
        foreach ($ipKeys as $key) {
            if (array_key_exists($key, $_SERVER) === true) {
                $ip = $_SERVER[$key];
                if (strpos($ip, ',') !== false) {
                    $ip = explode(',', $ip)[0];
                }
                $ip = trim($ip);
                if (filter_var($ip, FILTER_VALIDATE_IP, FILTER_FLAG_NO_PRIV_RANGE | FILTER_FLAG_NO_RES_RANGE)) {
                    return $ip;
                }
            }
        }
        
        return $_SERVER['REMOTE_ADDR'] ?? 'Unknown';
    }
    
    /**
     * Security event logging
     */
    public static function logSecurityEvent($eventType, $details = []) {
        if (defined('ENABLE_SECURITY_LOGGING') && ENABLE_SECURITY_LOGGING === 'true') {
            $logEntry = [
                'timestamp' => date('Y-m-d H:i:s'),
                'event_type' => $eventType,
                'ip' => self::getClientIP(),
                'user_agent' => $_SERVER['HTTP_USER_AGENT'] ?? 'Unknown',
                'details' => $details,
                'severity' => self::getSeverityLevel($eventType)
            ];
            
            $logFile = __DIR__ . '/../logs/security.log';
            $logDir = dirname($logFile);
            
            if (!is_dir($logDir)) {
                mkdir($logDir, 0755, true);
            }
            
            file_put_contents($logFile, json_encode($logEntry) . PHP_EOL, FILE_APPEND | LOCK_EX);
        }
    }
    
    /**
     * Get severity level for security events
     */
    private static function getSeverityLevel($eventType) {
        $severityMap = [
            'RATE_LIMIT_EXCEEDED' => 'HIGH',
            'ACCOUNT_LOCKED' => 'HIGH',
            'LOGIN_FAILURE' => 'MEDIUM',
            'LOGIN_SUCCESS' => 'LOW',
            'REGISTRATION_SUCCESS' => 'LOW',
            'REGISTRATION_FAILURE' => 'MEDIUM',
            'PASSWORD_RESET_REQUESTED' => 'MEDIUM',
            'PASSWORD_RESET_SUCCESS' => 'MEDIUM',
            'EMAIL_VERIFIED' => 'LOW',
            'SUSPICIOUS_ACTIVITY' => 'HIGH'
        ];
        
        return $severityMap[$eventType] ?? 'LOW';
    }
    
    /**
     * Validate email format
     */
    public static function validateEmail($email) {
        return filter_var($email, FILTER_VALIDATE_EMAIL) !== false;
    }
    
    /**
     * Validate username format
     */
    public static function validateUsername($username) {
        return preg_match('/^[a-zA-Z0-9_]{3,20}$/', $username);
    }
    
    /**
     * Generate secure random token
     */
    public static function generateSecureToken($length = 32) {
        return bin2hex(random_bytes($length));
    }
    
    /**
     * Secure password hashing
     */
    public static function hashPassword($password) {
        return password_hash($password, PASSWORD_ARGON2ID, [
            'memory_cost' => 65536, // 64 MB
            'time_cost' => 4,       // 4 iterations
            'threads' => 3          // 3 threads
        ]);
    }
    
    /**
     * Verify password
     */
    public static function verifyPassword($password, $hash) {
        return password_verify($password, $hash);
    }
}

// Auto-set security headers
SecurityMiddleware::setSecurityHeaders();
?>
