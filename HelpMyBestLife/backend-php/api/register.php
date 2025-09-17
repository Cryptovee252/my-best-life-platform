<?php
require_once '../config.php';
require_once '../includes/security-middleware.php';

// Only allow POST requests
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    errorResponse('Method not allowed', 405);
}

// Check rate limiting
$clientIP = SecurityMiddleware::getClientIP();
if (!SecurityMiddleware::checkRateLimit("register_$clientIP", RATE_LIMIT_MAX_REQUESTS, RATE_LIMIT_WINDOW_MS)) {
    errorResponse('Too many registration attempts. Please try again later.', 429);
}

// Get JSON input
$input = json_decode(file_get_contents('php://input'), true);

if (!$input) {
    errorResponse('Invalid JSON input');
}

// Validate required fields
$required_fields = ['name', 'username', 'email', 'password'];
foreach ($required_fields as $field) {
    if (empty($input[$field])) {
        errorResponse("Missing required field: $field");
    }
}

// Sanitize input
$name = SecurityMiddleware::sanitizeInput($input['name']);
$username = SecurityMiddleware::sanitizeInput($input['username']);
$email = SecurityMiddleware::sanitizeInput($input['email']);
$phone = isset($input['phone']) ? SecurityMiddleware::sanitizeInput($input['phone']) : null;
$password = $input['password'];

// Validate email format
if (!SecurityMiddleware::validateEmail($email)) {
    errorResponse('Invalid email format');
}

// Enhanced password validation
$passwordErrors = SecurityMiddleware::validatePassword($password);
if (!empty($passwordErrors)) {
    errorResponse('Password does not meet requirements: ' . implode(', ', $passwordErrors));
}

// Validate username format
if (!SecurityMiddleware::validateUsername($username)) {
    errorResponse('Username must be 3-20 characters long and contain only letters, numbers, and underscores');
}

// Validate name length
if (strlen($name) < 2 || strlen($name) > 50) {
    errorResponse('Name must be between 2 and 50 characters long');
}

try {
    $pdo = getDBConnection();
    if (!$pdo) {
        errorResponse('Database connection failed', 500);
    }

    // Check if email already exists
    $stmt = $pdo->prepare("SELECT id FROM users WHERE email = ?");
    $stmt->execute([$email]);
    if ($stmt->fetch()) {
        errorResponse('Email already registered');
    }

    // Check if username already exists
    $stmt = $pdo->prepare("SELECT id FROM users WHERE username = ?");
    $stmt->execute([$username]);
    if ($stmt->fetch()) {
        errorResponse('Username already taken');
    }

    // Hash password with enhanced security
    $hashedPassword = SecurityMiddleware::hashPassword($password);

    // Generate secure verification token
    $verificationToken = SecurityMiddleware::generateSecureToken();
    $verificationExpires = date('Y-m-d H:i:s', time() + VERIFICATION_EXPIRY);

    // Insert new user
    $stmt = $pdo->prepare("
        INSERT INTO users (name, username, email, phone, password, verificationToken, verificationExpires, createdAt) 
        VALUES (?, ?, ?, ?, ?, ?, ?, NOW())
    ");
    
    $stmt->execute([
        $name, $username, $email, $phone, $hashedPassword, 
        $verificationToken, $verificationExpires
    ]);

    $userId = $pdo->lastInsertId();

    // Get the created user (without sensitive data)
    $stmt = $pdo->prepare("
        SELECT id, name, username, email, phone, dailyCP, lifetimeCP, daysActive, 
               startDate, lastActiveDate, isOnline, lastSeen, emailVerified, createdAt 
        FROM users WHERE id = ?
    ");
    $stmt->execute([$userId]);
    $user = $stmt->fetch();

    // Send welcome email
    $welcomeEmailSent = sendWelcomeEmail($user, $verificationToken);

    // Log the registration with security event
    SecurityMiddleware::logSecurityEvent('REGISTRATION_SUCCESS', [
        'user_id' => $userId,
        'email' => $email,
        'username' => $username,
        'ip' => $clientIP
    ]);

    // Log email attempt
    $emailStatus = $welcomeEmailSent ? 'sent' : 'failed';
    $stmt = $pdo->prepare("
        INSERT INTO email_logs (user_id, email_type, recipient_email, subject, status) 
        VALUES (?, 'welcome', ?, ?, ?)
    ");
    $stmt->execute([$userId, $email, 'Welcome to My Best Life!', $emailStatus]);

    successResponse(
        'User registered successfully! Please check your email to verify your account.',
        [
            'user' => $user,
            'requiresVerification' => true,
            'emailSent' => $welcomeEmailSent
        ],
        201
    );

} catch (PDOException $e) {
    logActivity("Database error during registration: " . $e->getMessage(), 'ERROR');
    errorResponse('Registration failed. Please try again.', 500);
} catch (Exception $e) {
    logActivity("General error during registration: " . $e->getMessage(), 'ERROR');
    errorResponse('Registration failed. Please try again.', 500);
}

// Function to send welcome email
function sendWelcomeEmail($user, $verificationToken) {
    try {
        require_once '../includes/email-service.php';
        
        $emailService = new EmailService();
        
        // Send welcome email
        $welcomeSent = $emailService->sendWelcomeEmail($user);
        
        // Send verification email
        $verificationSent = $emailService->sendVerificationEmail($user, $verificationToken);
        
        return $welcomeSent && $verificationSent;
        
    } catch (Exception $e) {
        logActivity("Email sending failed: " . $e->getMessage(), 'ERROR');
        return false;
    }
}
?>




