<?php
require_once '../config.php';

// Only allow POST requests
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    errorResponse('Method not allowed', 405);
}

// Get JSON input
$input = json_decode(file_get_contents('php://input'), true);

if (!$input || empty($input['token'])) {
    errorResponse('Verification token is required');
}

$token = sanitizeInput($input['token']);

try {
    $pdo = getDBConnection();
    if (!$pdo) {
        errorResponse('Database connection failed', 500);
    }

    // Find user with this verification token
    $stmt = $pdo->prepare("
        SELECT * FROM users 
        WHERE verificationToken = ? AND verificationExpires > NOW()
    ");
    $stmt->execute([$token]);
    $user = $stmt->fetch();

    if (!$user) {
        errorResponse('Invalid or expired verification token');
    }

    // Update user to verified
    $stmt = $pdo->prepare("
        UPDATE users 
        SET emailVerified = 1, verificationToken = NULL, verificationExpires = NULL 
        WHERE id = ?
    ");
    $stmt->execute([$user['id']]);

    // Log the verification
    logActivity("Email verified for user: {$user['email']} (ID: {$user['id']})", 'INFO');

    // Remove sensitive data from response
    unset($user['password']);
    unset($user['verificationToken']);
    unset($user['verificationExpires']);
    unset($user['resetToken']);
    unset($user['resetExpires']);

    successResponse('Email verified successfully! You can now sign in to your account.', [
        'user' => $user
    ]);

} catch (PDOException $e) {
    logActivity("Database error during email verification: " . $e->getMessage(), 'ERROR');
    errorResponse('Email verification failed. Please try again.', 500);
} catch (Exception $e) {
    logActivity("General error during email verification: " . $e->getMessage(), 'ERROR');
    errorResponse('Email verification failed. Please try again.', 500);
}
?>



