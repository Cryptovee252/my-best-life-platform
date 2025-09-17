<?php
// My Best Life Platform - PHP Configuration
// This file contains all configuration settings for shared hosting

// Database Configuration
define('DB_HOST', 'localhost'); // Usually localhost for shared hosting
define('DB_NAME', 'your_database_name'); // Replace with your actual database name
define('DB_USER', 'your_username'); // Replace with your actual username
define('DB_PASS', 'your_password'); // Replace with your actual password
define('DB_PORT', '3306'); // Usually 3306 for MySQL on shared hosting

// JWT Secret Key (generate a random string)
define('JWT_SECRET', 'mybestlife-super-secret-jwt-key-2024-very-long-and-secure');

// Email Configuration (Gmail)
define('SMTP_HOST', 'smtp.gmail.com');
define('SMTP_PORT', 587);
define('SMTP_USER', 'your-gmail@gmail.com'); // Replace with your Gmail
define('SMTP_PASS', 'your-app-password'); // Replace with your Gmail app password

// Frontend URL
define('FRONTEND_URL', 'https://mybestlifeapp.com');

// Application Settings
define('APP_NAME', 'My Best Life');
define('APP_VERSION', '1.0.0');
define('APP_ENV', 'production');

// Security Settings
define('JWT_EXPIRY', 86400); // 24 hours in seconds
define('VERIFICATION_EXPIRY', 86400); // 24 hours for email verification
define('RESET_EXPIRY', 3600); // 1 hour for password reset

// Error Reporting (disable in production)
error_reporting(0);
ini_set('display_errors', 0);

// Timezone
date_default_timezone_set('UTC');

// Start session if not already started
if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

// CORS Headers for API requests
header('Access-Control-Allow-Origin: ' . FRONTEND_URL);
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');
header('Access-Control-Allow-Credentials: true');

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Database Connection Function
function getDBConnection() {
    try {
        $dsn = "mysql:host=" . DB_HOST . ";dbname=" . DB_NAME . ";port=" . DB_PORT . ";charset=utf8mb4";
        $pdo = new PDO($dsn, DB_USER, DB_PASS, [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES => false,
        ]);
        return $pdo;
    } catch (PDOException $e) {
        error_log("Database connection failed: " . $e->getMessage());
        return false;
    }
}

// Utility Functions
function generateToken($length = 32) {
    return bin2hex(random_bytes($length));
}

function hashPassword($password) {
    return password_hash($password, PASSWORD_DEFAULT);
}

function verifyPassword($password, $hash) {
    return password_verify($password, $hash);
}

function sanitizeInput($input) {
    if (is_array($input)) {
        return array_map('sanitizeInput', $input);
    }
    return htmlspecialchars(trim($input), ENT_QUOTES, 'UTF-8');
}

function jsonResponse($data, $statusCode = 200) {
    http_response_code($statusCode);
    header('Content-Type: application/json');
    echo json_encode($data);
    exit();
}

function errorResponse($message, $statusCode = 400) {
    jsonResponse(['error' => $message], $statusCode);
}

function successResponse($message, $data = null, $statusCode = 200) {
    $response = ['success' => true, 'message' => $message];
    if ($data !== null) {
        $response['data'] = $data;
    }
    jsonResponse($response, $statusCode);
}

// JWT Functions (Simple implementation for shared hosting)
function generateJWT($payload) {
    $header = json_encode(['typ' => 'JWT', 'alg' => 'HS256']);
    $payload = json_encode($payload);
    
    $base64Header = str_replace(['+', '/', '='], ['-', '_', ''], base64_encode($header));
    $base64Payload = str_replace(['+', '/', '='], ['-', '_', ''], base64_encode($payload));
    
    $signature = hash_hmac('sha256', $base64Header . "." . $base64Payload, JWT_SECRET, true);
    $base64Signature = str_replace(['+', '/', '='], ['-', '_', ''], base64_encode($signature));
    
    return $base64Header . "." . $base64Payload . "." . $base64Signature;
}

function verifyJWT($token) {
    $parts = explode('.', $token);
    if (count($parts) !== 3) {
        return false;
    }
    
    $header = $parts[0];
    $payload = $parts[1];
    $signature = $parts[2];
    
    $expectedSignature = hash_hmac('sha256', $header . "." . $payload, JWT_SECRET, true);
    $expectedSignature = str_replace(['+', '/', '='], ['-', '_', ''], base64_encode($expectedSignature));
    
    if (!hash_equals($signature, $expectedSignature)) {
        return false;
    }
    
    $payloadData = json_decode(base64_decode(str_replace(['-', '_'], ['+', '/'], $payload)), true);
    
    if ($payloadData === null) {
        return false;
    }
    
    if (isset($payloadData['exp']) && $payloadData['exp'] < time()) {
        return false;
    }
    
    return $payloadData;
}

// Authentication Middleware
function requireAuth() {
    $headers = getallheaders();
    $token = null;
    
    if (isset($headers['Authorization'])) {
        $token = str_replace('Bearer ', '', $headers['Authorization']);
    } elseif (isset($_GET['token'])) {
        $token = $_GET['token'];
    }
    
    if (!$token) {
        errorResponse('No token provided', 401);
    }
    
    $payload = verifyJWT($token);
    if (!$payload) {
        errorResponse('Invalid or expired token', 401);
    }
    
    return $payload;
}

// Logging Function
function logActivity($message, $level = 'INFO') {
    $logFile = __DIR__ . '/logs/app.log';
    $logDir = dirname($logFile);
    
    if (!is_dir($logDir)) {
        mkdir($logDir, 0755, true);
    }
    
    $timestamp = date('Y-m-d H:i:s');
    $logEntry = "[$timestamp] [$level] $message" . PHP_EOL;
    
    file_put_contents($logFile, $logEntry, FILE_APPEND | LOCK_EX);
}
?>
