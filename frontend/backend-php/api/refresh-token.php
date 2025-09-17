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
if (!SecurityMiddleware::checkRateLimit("refresh_$clientIP", RATE_LIMIT_MAX_REQUESTS, RATE_LIMIT_WINDOW_MS)) {
    errorResponse('Too many refresh attempts. Please try again later.', 429);
}

// Get JSON input
$input = json_decode(file_get_contents('php://input'), true);

if (!$input || !isset($input['refreshToken'])) {
    errorResponse('Refresh token is required');
}

$refreshToken = $input['refreshToken'];

try {
    // Verify refresh token
    $payload = SecureJWT::verifyRefreshToken($refreshToken);
    
    if (!$payload) {
        SecurityMiddleware::logSecurityEvent('REFRESH_TOKEN_INVALID', [
            'ip' => $clientIP,
            'token' => substr($refreshToken, 0, 20) . '...' // Log partial token for debugging
        ]);
        errorResponse('Invalid or expired refresh token', 401);
    }
    
    // Check if user still exists and is active
    $pdo = getDBConnection();
    if (!$pdo) {
        errorResponse('Database connection failed', 500);
    }
    
    $stmt = $pdo->prepare("
        SELECT id, email, username, emailVerified, isLocked 
        FROM users 
        WHERE id = ? AND emailVerified = 1 AND isLocked = 0
    ");
    $stmt->execute([$payload['user_id']]);
    $user = $stmt->fetch();
    
    if (!$user) {
        SecurityMiddleware::logSecurityEvent('REFRESH_TOKEN_USER_NOT_FOUND', [
            'user_id' => $payload['user_id'],
            'ip' => $clientIP
        ]);
        errorResponse('User not found or account is locked', 401);
    }
    
    // Generate new access token
    $newToken = SecureJWT::generateToken([
        'user_id' => $user['id'],
        'email' => $user['email'],
        'username' => $user['username']
    ]);
    
    // Generate new refresh token
    $newRefreshToken = SecureJWT::generateRefreshToken($user['id']);
    
    // Blacklist old refresh token
    SecureJWT::blacklistToken($refreshToken);
    
    // Log token refresh
    SecurityMiddleware::logSecurityEvent('TOKEN_REFRESHED', [
        'user_id' => $user['id'],
        'email' => $user['email'],
        'ip' => $clientIP
    ]);
    
    successResponse('Token refreshed successfully', [
        'token' => $newToken,
        'refreshToken' => $newRefreshToken
    ]);
    
} catch (Exception $e) {
    SecurityMiddleware::logSecurityEvent('REFRESH_TOKEN_ERROR', [
        'error' => $e->getMessage(),
        'ip' => $clientIP
    ]);
    
    errorResponse('Token refresh failed. Please try again.', 500);
}
?>
