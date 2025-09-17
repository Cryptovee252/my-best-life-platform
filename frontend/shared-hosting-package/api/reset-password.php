<?php
require_once '../config.php';

// Only allow POST requests
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    errorResponse('Method not allowed', 405);
}

// Get JSON input
$input = json_decode(file_get_contents('php://input'), true);

if (!$input || empty($input['token']) || empty($input['newPassword'])) {
    errorResponse('Reset token and new password are required');
}

$token = sanitizeInput($input['token']);
$newPassword = $input['newPassword'];

// Validate password length
if (strlen($newPassword) < 6) {
    errorResponse('Password must be at least 6 characters long');
}

try {
    $pdo = getDBConnection();
    if (!$pdo) {
        errorResponse('Database connection failed', 500);
    }

    // Find user with this reset token
    $stmt = $pdo->prepare("
        SELECT * FROM users 
        WHERE resetToken = ? AND resetExpires > NOW()
    ");
    $stmt->execute([$token]);
    $user = $stmt->fetch();

    if (!$user) {
        errorResponse('Invalid or expired reset token');
    }

    // Hash new password
    $hashedPassword = hashPassword($newPassword);

    // Update user password and clear reset token
    $stmt = $pdo->prepare("
        UPDATE users 
        SET password = ?, resetToken = NULL, resetExpires = NULL 
        WHERE id = ?
    ");
    $stmt->execute([$hashedPassword, $user['id']]);

    // Log the password reset
    logActivity("Password reset for user: {$user['email']} (ID: {$user['id']})", 'INFO');

    successResponse('Password reset successfully! You can now sign in with your new password.');

} catch (PDOException $e) {
    logActivity("Database error during password reset: " . $e->getMessage(), 'ERROR');
    errorResponse('Password reset failed. Please try again.', 500);
} catch (Exception $e) {
    logActivity("General error during password reset: " . $e->getMessage(), 'ERROR');
    errorResponse('Password reset failed. Please try again.', 500);
}
?>
