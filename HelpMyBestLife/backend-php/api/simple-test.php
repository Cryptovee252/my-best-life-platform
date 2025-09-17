<?php
// Simple API test - no dependencies
header('Content-Type: application/json');

echo json_encode([
    'status' => 'success',
    'message' => 'Simple API test working!',
    'timestamp' => date('Y-m-d H:i:s'),
    'php_version' => PHP_VERSION,
    'server' => $_SERVER['SERVER_SOFTWARE'] ?? 'Unknown',
    'request_method' => $_SERVER['REQUEST_METHOD'],
    'request_uri' => $_SERVER['REQUEST_URI']
]);
?>




