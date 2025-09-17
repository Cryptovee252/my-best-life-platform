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
if (!SecurityMiddleware::checkRateLimit("login_$clientIP", RATE_LIMIT_MAX_REQUESTS, RATE_LIMIT_WINDOW_MS)) {
    errorResponse('Too many login attempts. Please try again later.', 429);
}

// Get JSON input
$input = json_decode(file_get_contents('php://input'), true);

if (!$input) {
    errorResponse('Invalid JSON input');
}

// Validate required fields
$required_fields = ['email', 'password'];
foreach ($required_fields as $field) {
    if (empty($input[$field])) {
        errorResponse("Missing required field: $field");
    }
}

// Sanitize input
$email = SecurityMiddleware::sanitizeInput($input['email']);
$password = $input['password'];

// Validate email format
if (!SecurityMiddleware::validateEmail($email)) {
    errorResponse('Invalid email format');
}

try {
    $pdo = getDBConnection();
    if (!$pdo) {
        errorResponse('Database connection failed', 500);
    }

    // Find user by email
    $stmt = $pdo->prepare("SELECT * FROM users WHERE email = ?");
    $stmt->execute([$email]);
    $user = $stmt->fetch();

    if (!$user) {
        SecurityMiddleware::logSecurityEvent('LOGIN_FAILURE', [
            'email' => $email,
            'reason' => 'User not found',
            'ip' => $clientIP
        ]);
        errorResponse('Invalid email or password');
    }

    // Check account lockout
    $lockoutStatus = SecurityMiddleware::checkAccountLockout($user['id']);
    if ($lockoutStatus['locked']) {
        SecurityMiddleware::logSecurityEvent('LOGIN_BLOCKED', [
            'user_id' => $user['id'],
            'email' => $email,
            'lockout_until' => $lockoutStatus['until'],
            'ip' => $clientIP
        ]);
        errorResponse('Account temporarily locked due to suspicious activity', 423);
    }

    // Check if email is verified
    if (!$user['emailVerified']) {
        errorResponse('Please verify your email address before signing in', 401);
    }

    // Verify password
    if (!SecurityMiddleware::verifyPassword($password, $user['password'])) {
        SecurityMiddleware::handleFailedLogin($user['id'], $email);
        errorResponse('Invalid email or password');
    }

    // Reset failed login attempts on successful login
    SecurityMiddleware::resetFailedLoginAttempts($user['id']);

    // Update last active date and online status
    $stmt = $pdo->prepare("
        UPDATE users 
        SET lastActiveDate = CURRENT_DATE, lastSeen = NOW(), isOnline = 1 
        WHERE id = ?
    ");
    $stmt->execute([$user['id']]);

    // Generate secure JWT token
    $token = SecureJWT::generateToken([
        'user_id' => $user['id'],
        'email' => $user['email'],
        'username' => $user['username']
    ]);
    
    // Generate refresh token
    $refreshToken = SecureJWT::generateRefreshToken($user['id']);

    // Log successful login
    SecurityMiddleware::logSecurityEvent('LOGIN_SUCCESS', [
        'user_id' => $user['id'],
        'email' => $email,
        'ip' => $clientIP
    ]);

    // Remove sensitive data from response
    unset($user['password']);
    unset($user['verificationToken']);
    unset($user['verificationExpires']);
    unset($user['resetToken']);
    unset($user['resetExpires']);

    successResponse('Login successful', [
        'user' => $user,
        'token' => $token,
        'refreshToken' => $refreshToken
    ]);

} catch (PDOException $e) {
    logActivity("Database error during login: " . $e->getMessage(), 'ERROR');
    errorResponse('Login failed. Please try again.', 500);
} catch (Exception $e) {
    logActivity("General error during login: " . $e->getMessage(), 'ERROR');
    errorResponse('Login failed. Please try again.', 500);
}
?>




