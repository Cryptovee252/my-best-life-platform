<?php
require_once '../config.php';

// Allow both GET and POST for testing
if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    successResponse('My Best Life API is working!', [
        'status' => 'success',
        'message' => 'API endpoint is accessible',
        'timestamp' => date('Y-m-d H:i:s'),
        'php_version' => PHP_VERSION,
        'server' => $_SERVER['SERVER_SOFTWARE'] ?? 'Unknown'
    ]);
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $input = json_decode(file_get_contents('php://input'), true);
    
    successResponse('POST request received successfully!', [
        'status' => 'success',
        'message' => 'POST endpoint is working',
        'received_data' => $input,
        'timestamp' => date('Y-m-d H:i:s')
    ]);
}

// If we get here, method not allowed
errorResponse('Method not allowed', 405);
?>
