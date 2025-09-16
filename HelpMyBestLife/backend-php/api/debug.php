<?php
// Debug endpoint to help troubleshoot API issues
header('Content-Type: application/json');

// Get request information
$request_info = [
    'method' => $_SERVER['REQUEST_METHOD'],
    'uri' => $_SERVER['REQUEST_URI'],
    'path' => parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH),
    'query' => $_SERVER['QUERY_STRING'] ?? '',
    'headers' => getallheaders(),
    'post_data' => file_get_contents('php://input'),
    'timestamp' => date('Y-m-d H:i:s'),
    'php_version' => PHP_VERSION,
    'server' => $_SERVER['SERVER_SOFTWARE'] ?? 'Unknown'
];

// Check if this is a registration request
if ($_SERVER['REQUEST_METHOD'] === 'POST' && strpos($_SERVER['REQUEST_URI'], 'register') !== false) {
    $request_info['registration_request'] = true;
    $request_info['post_data_parsed'] = json_decode(file_get_contents('php://input'), true);
}

echo json_encode($request_info, JSON_PRETTY_PRINT);
?>



