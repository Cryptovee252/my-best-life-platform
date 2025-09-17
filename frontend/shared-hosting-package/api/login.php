<?php
require_once '../config.php';

// Only allow POST requests
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    errorResponse('Method not allowed', 405);
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
$email = sanitizeInput($input['email']);
$password = $input['password'];

// Validate email format
if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
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
        errorResponse('Invalid email or password');
    }

    // Check if email is verified
    if (!$user['emailVerified']) {
        errorResponse('Please verify your email address before signing in', 401);
    }

    // Verify password
    if (!verifyPassword($password, $user['password'])) {
        errorResponse('Invalid email or password');
    }

    // Update last active date and online status
    $stmt = $pdo->prepare("
        UPDATE users 
        SET lastActiveDate = CURRENT_DATE, lastSeen = NOW(), isOnline = 1 
        WHERE id = ?
    ");
    $stmt->execute([$user['id']]);

    // Generate JWT token
    $token = generateJWT([
        'user_id' => $user['id'],
        'email' => $user['email'],
        'exp' => time() + JWT_EXPIRY
    ]);

    // Log the login
    logActivity("User logged in: $email (ID: {$user['id']})", 'INFO');

    // Remove sensitive data from response
    unset($user['password']);
    unset($user['verificationToken']);
    unset($user['verificationExpires']);
    unset($user['resetToken']);
    unset($user['resetExpires']);

    successResponse('Login successful', [
        'user' => $user,
        'token' => $token
    ]);

} catch (PDOException $e) {
    logActivity("Database error during login: " . $e->getMessage(), 'ERROR');
    errorResponse('Login failed. Please try again.', 500);
} catch (Exception $e) {
    logActivity("General error during login: " . $e->getMessage(), 'ERROR');
    errorResponse('Login failed. Please try again.', 500);
}
?>
