<?php
require_once '../config.php';

// Only allow POST requests
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    errorResponse('Method not allowed', 405);
}

// Get JSON input
$input = json_decode(file_get_contents('php://input'), true);

if (!$input || empty($input['email'])) {
    errorResponse('Email address is required');
}

$email = sanitizeInput($input['email']);

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
        // Don't reveal if email exists or not for security
        successResponse('If an account with that email exists, a password reset link has been sent.');
        exit;
    }

    // Generate reset token
    $resetToken = generateToken();
    $resetExpires = date('Y-m-d H:i:s', time() + RESET_EXPIRY);

    // Update user with reset token
    $stmt = $pdo->prepare("
        UPDATE users 
        SET resetToken = ?, resetExpires = ? 
        WHERE id = ?
    ");
    $stmt->execute([$resetToken, $resetExpires, $user['id']]);

    // Send password reset email
    require_once '../includes/email-service.php';
    $emailService = new EmailService();
    $emailSent = $emailService->sendPasswordResetEmail($user, $resetToken);

    // Log the password reset request
    logActivity("Password reset requested for user: $email (ID: {$user['id']})", 'INFO');

    // Log email attempt
    $emailStatus = $emailSent ? 'sent' : 'failed';
    $stmt = $pdo->prepare("
        INSERT INTO email_logs (user_id, email_type, recipient_email, subject, status) 
        VALUES (?, 'password_reset', ?, ?, ?)
    ");
    $stmt->execute([$user['id'], $email, 'Reset Your Password - My Best Life', $emailStatus]);

    successResponse('If an account with that email exists, a password reset link has been sent.');

} catch (PDOException $e) {
    logActivity("Database error during forgot password: " . $e->getMessage(), 'ERROR');
    errorResponse('Password reset request failed. Please try again.', 500);
} catch (Exception $e) {
    logActivity("General error during forgot password: " . $e->getMessage(), 'ERROR');
    errorResponse('Password reset request failed. Please try again.', 500);
}
?>



