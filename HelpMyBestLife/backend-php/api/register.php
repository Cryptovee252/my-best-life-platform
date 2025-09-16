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
$required_fields = ['name', 'username', 'email', 'password'];
foreach ($required_fields as $field) {
    if (empty($input[$field])) {
        errorResponse("Missing required field: $field");
    }
}

// Sanitize input
$name = sanitizeInput($input['name']);
$username = sanitizeInput($input['username']);
$email = sanitizeInput($input['email']);
$phone = isset($input['phone']) ? sanitizeInput($input['phone']) : null;
$password = $input['password'];

// Validate email format
if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    errorResponse('Invalid email format');
}

// Validate password length
if (strlen($password) < 6) {
    errorResponse('Password must be at least 6 characters long');
}

// Validate username format (alphanumeric and underscores only)
if (!preg_match('/^[a-zA-Z0-9_]+$/', $username)) {
    errorResponse('Username can only contain letters, numbers, and underscores');
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

    // Hash password
    $hashedPassword = hashPassword($password);

    // Generate verification token
    $verificationToken = generateToken();
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

    // Log the registration
    logActivity("User registered: $email (ID: $userId)", 'INFO');

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



