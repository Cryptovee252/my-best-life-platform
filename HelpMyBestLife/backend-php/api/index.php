<?php
// My Best Life API Router
// This file handles API routing for shared hosting

// Set headers for API
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Get the requested endpoint
$request_uri = $_SERVER['REQUEST_URI'];
$path = parse_url($request_uri, PHP_URL_PATH);
$path_parts = explode('/', trim($path, '/'));

// Find the API endpoint - handle both /api/endpoint and /api/auth/endpoint
$endpoint = null;
$api_index = array_search('api', $path_parts);
if ($api_index !== false) {
    // Check if next part is 'auth'
    if (isset($path_parts[$api_index + 1]) && $path_parts[$api_index + 1] === 'auth') {
        // Handle /api/auth/endpoint pattern
        if (isset($path_parts[$api_index + 2])) {
            $endpoint = $path_parts[$api_index + 2];
        }
    } else {
        // Handle /api/endpoint pattern
        if (isset($path_parts[$api_index + 1])) {
            $endpoint = $path_parts[$api_index + 1];
        }
    }
}

// If no specific endpoint, show API info
if (!$endpoint) {
    echo json_encode([
        'status' => 'success',
        'message' => 'My Best Life API',
        'version' => '1.0.0',
        'endpoints' => [
            'POST /api/register' => 'User registration',
            'POST /api/login' => 'User login',
            'POST /api/verify-email' => 'Email verification',
            'POST /api/forgot-password' => 'Request password reset',
            'POST /api/reset-password' => 'Reset password',
            'GET /api/test' => 'Test API connection'
        ],
        'timestamp' => date('Y-m-d H:i:s')
    ]);
    exit();
}

// Route to appropriate endpoint
switch ($endpoint) {
    case 'register':
        require_once 'register.php';
        break;
        
    case 'login':
        require_once 'login.php';
        break;
        
    case 'verify-email':
        require_once 'verify-email.php';
        break;
        
    case 'forgot-password':
        require_once 'forgot-password.php';
        break;
        
    case 'reset-password':
        require_once 'reset-password.php';
        break;
        
    case 'test':
        require_once 'test.php';
        break;
        
    default:
        http_response_code(404);
        echo json_encode([
            'error' => 'Endpoint not found',
            'message' => "The endpoint '$endpoint' does not exist",
            'available_endpoints' => [
                'register', 'login', 'verify-email', 
                'forgot-password', 'reset-password', 'test'
            ]
        ]);
        break;
}
?>
