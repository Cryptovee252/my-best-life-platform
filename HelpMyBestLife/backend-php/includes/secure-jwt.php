<?php
// My Best Life Platform - Secure JWT Implementation
// Enhanced JWT handling with proper security measures

require_once __DIR__ . '/../config.php';

class SecureJWT {
    
    /**
     * Generate a secure JWT token
     */
    public static function generateToken($payload, $expiry = null) {
        $expiry = $expiry ?? JWT_EXPIRY;
        
        // Add standard claims
        $payload['iat'] = time(); // Issued at
        $payload['exp'] = time() + $expiry; // Expiration
        $payload['iss'] = APP_NAME; // Issuer
        $payload['aud'] = FRONTEND_URL; // Audience
        
        // Add random nonce for additional security
        $payload['nonce'] = bin2hex(random_bytes(16));
        
        $header = json_encode(['typ' => 'JWT', 'alg' => 'HS256']);
        $payload = json_encode($payload);
        
        $base64Header = str_replace(['+', '/', '='], ['-', '_', ''], base64_encode($header));
        $base64Payload = str_replace(['+', '/', '='], ['-', '_', ''], base64_encode($payload));
        
        $signature = hash_hmac('sha256', $base64Header . "." . $base64Payload, JWT_SECRET, true);
        $base64Signature = str_replace(['+', '/', '='], ['-', '_', ''], base64_encode($signature));
        
        return $base64Header . "." . $base64Payload . "." . $base64Signature;
    }
    
    /**
     * Verify and decode a JWT token
     */
    public static function verifyToken($token) {
        $parts = explode('.', $token);
        if (count($parts) !== 3) {
            return false;
        }
        
        list($header, $payload, $signature) = $parts;
        
        // Verify signature
        $expectedSignature = hash_hmac('sha256', $header . "." . $payload, JWT_SECRET, true);
        $expectedSignature = str_replace(['+', '/', '='], ['-', '_', ''], base64_encode($expectedSignature));
        
        if (!hash_equals($signature, $expectedSignature)) {
            return false;
        }
        
        // Decode payload
        $payloadData = json_decode(base64_decode(str_replace(['-', '_'], ['+', '/'], $payload)), true);
        
        if ($payloadData === null) {
            return false;
        }
        
        // Check expiration
        if (isset($payloadData['exp']) && $payloadData['exp'] < time()) {
            return false;
        }
        
        // Check issued at (not before current time - 5 minutes for clock skew)
        if (isset($payloadData['iat']) && $payloadData['iat'] > time() + 300) {
            return false;
        }
        
        // Check audience
        if (isset($payloadData['aud']) && $payloadData['aud'] !== FRONTEND_URL) {
            return false;
        }
        
        // Check issuer
        if (isset($payloadData['iss']) && $payloadData['iss'] !== APP_NAME) {
            return false;
        }
        
        return $payloadData;
    }
    
    /**
     * Generate refresh token
     */
    public static function generateRefreshToken($userId) {
        $payload = [
            'user_id' => $userId,
            'type' => 'refresh',
            'iat' => time(),
            'exp' => time() + (JWT_EXPIRY * 30), // 30 days
            'iss' => APP_NAME,
            'aud' => FRONTEND_URL,
            'nonce' => bin2hex(random_bytes(16))
        ];
        
        return self::generateToken($payload, JWT_EXPIRY * 30);
    }
    
    /**
     * Verify refresh token
     */
    public static function verifyRefreshToken($token) {
        $payload = self::verifyToken($token);
        
        if (!$payload) {
            return false;
        }
        
        // Check if it's a refresh token
        if (!isset($payload['type']) || $payload['type'] !== 'refresh') {
            return false;
        }
        
        return $payload;
    }
    
    /**
     * Extract token from Authorization header
     */
    public static function extractTokenFromHeader() {
        $headers = getallheaders();
        
        if (isset($headers['Authorization'])) {
            $authHeader = $headers['Authorization'];
            if (preg_match('/Bearer\s+(.*)$/i', $authHeader, $matches)) {
                return $matches[1];
            }
        }
        
        return null;
    }
    
    /**
     * Require authentication middleware
     */
    public static function requireAuth() {
        $token = self::extractTokenFromHeader();
        
        if (!$token) {
            http_response_code(401);
            header('Content-Type: application/json');
            echo json_encode(['error' => 'No token provided', 'code' => 'NO_TOKEN']);
            exit;
        }
        
        $payload = self::verifyToken($token);
        
        if (!$payload) {
            http_response_code(401);
            header('Content-Type: application/json');
            echo json_encode(['error' => 'Invalid or expired token', 'code' => 'INVALID_TOKEN']);
            exit;
        }
        
        return $payload;
    }
    
    /**
     * Blacklist token (for logout)
     */
    public static function blacklistToken($token) {
        // In a production environment, you would store this in Redis or database
        // For now, we'll use a simple file-based approach
        $blacklistFile = __DIR__ . '/../logs/token_blacklist.json';
        
        $blacklist = [];
        if (file_exists($blacklistFile)) {
            $blacklist = json_decode(file_get_contents($blacklistFile), true) ?? [];
        }
        
        $blacklist[hash('sha256', $token)] = time();
        
        // Clean old entries (older than 30 days)
        $cutoff = time() - (30 * 24 * 60 * 60);
        $blacklist = array_filter($blacklist, function($timestamp) use ($cutoff) {
            return $timestamp > $cutoff;
        });
        
        file_put_contents($blacklistFile, json_encode($blacklist));
    }
    
    /**
     * Check if token is blacklisted
     */
    public static function isTokenBlacklisted($token) {
        $blacklistFile = __DIR__ . '/../logs/token_blacklist.json';
        
        if (!file_exists($blacklistFile)) {
            return false;
        }
        
        $blacklist = json_decode(file_get_contents($blacklistFile), true) ?? [];
        return isset($blacklist[hash('sha256', $token)]);
    }
    
    /**
     * Enhanced token verification with blacklist check
     */
    public static function verifyTokenSecure($token) {
        // Check if token is blacklisted
        if (self::isTokenBlacklisted($token)) {
            return false;
        }
        
        return self::verifyToken($token);
    }
}
?>
