<?php
require_once '../config.php';
require_once '../includes/security-middleware.php';
require_once '../includes/secure-jwt.php';

// Only allow POST requests
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    errorResponse('Method not allowed', 405);
}

// Check rate limiting
$clientIP = SecurityMiddleware::getClientIP();
if (!SecurityMiddleware::checkRateLimit("logout_$clientIP", RATE_LIMIT_MAX_API_REQUESTS, RATE_LIMIT_WINDOW_MS)) {
    errorResponse('Too many requests. Please try again later.', 429);
}

try {
    // Get token from header
    $token = SecureJWT::extractTokenFromHeader();
    
    if (!$token) {
        errorResponse('No token provided', 401);
    }
    
    // Verify token
    $payload = SecureJWT::verifyTokenSecure($token);
    
    if (!$payload) {
        errorResponse('Invalid or expired token', 401);
    }
    
    // Blacklist the token
    SecureJWT::blacklistToken($token);
    
    // Update user's online status
    $pdo = getDBConnection();
    if ($pdo) {
        $stmt = $pdo->prepare("
            UPDATE users 
            SET isOnline = 0, lastSeen = NOW() 
            WHERE id = ?
        ");
        $stmt->execute([$payload['user_id']]);
    }
    
    // Log logout event
    SecurityMiddleware::logSecurityEvent('LOGOUT', [
        'user_id' => $payload['user_id'],
        'email' => $payload['email'] ?? 'Unknown',
        'ip' => $clientIP
    ]);
    
    // Clear session
    if (session_status() === PHP_SESSION_ACTIVE) {
        session_destroy();
    }
    
    successResponse('Logout successful');
    
} catch (Exception $e) {
    SecurityMiddleware::logSecurityEvent('LOGOUT_ERROR', [
        'error' => $e->getMessage(),
        'ip' => $clientIP
    ]);
    
    errorResponse('Logout failed. Please try again.', 500);
}
?>
