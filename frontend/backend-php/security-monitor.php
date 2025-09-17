<?php
// My Best Life Platform - Security Monitoring Script
// Real-time security monitoring and alerting system

require_once __DIR__ . '/config.php';
require_once __DIR__ . '/includes/security-middleware.php';

class SecurityMonitor {
    
    private $logFile;
    private $alertThresholds;
    
    public function __construct() {
        $this->logFile = __DIR__ . '/logs/security.log';
        $this->alertThresholds = [
            'failed_logins_per_hour' => 50,
            'rate_limit_exceeded_per_hour' => 100,
            'suspicious_ips_per_hour' => 20,
            'account_lockouts_per_hour' => 10
        ];
    }
    
    /**
     * Monitor security events in real-time
     */
    public function monitorSecurityEvents() {
        echo "🔍 Starting security monitoring...\n";
        
        $lastCheck = time();
        $eventCounts = [
            'failed_logins' => 0,
            'rate_limit_exceeded' => 0,
            'account_lockouts' => 0,
            'suspicious_ips' => []
        ];
        
        while (true) {
            $currentTime = time();
            
            // Check for new security events every 30 seconds
            if ($currentTime - $lastCheck >= 30) {
                $this->analyzeSecurityEvents($eventCounts);
                $lastCheck = $currentTime;
            }
            
            // Check for alerts every 5 minutes
            if ($currentTime % 300 === 0) {
                $this->checkSecurityAlerts($eventCounts);
            }
            
            sleep(1);
        }
    }
    
    /**
     * Analyze security events from log file
     */
    private function analyzeSecurityEvents(&$eventCounts) {
        if (!file_exists($this->logFile)) {
            return;
        }
        
        $lines = file($this->logFile, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
        $recentEvents = array_slice($lines, -100); // Analyze last 100 events
        
        foreach ($recentEvents as $line) {
            $event = json_decode($line, true);
            if (!$event) continue;
            
            $eventTime = strtotime($event['timestamp']);
            $oneHourAgo = time() - 3600;
            
            // Only analyze events from the last hour
            if ($eventTime < $oneHourAgo) continue;
            
            switch ($event['event_type']) {
                case 'LOGIN_FAILURE':
                    $eventCounts['failed_logins']++;
                    break;
                    
                case 'RATE_LIMIT_EXCEEDED':
                    $eventCounts['rate_limit_exceeded']++;
                    break;
                    
                case 'ACCOUNT_LOCKED':
                    $eventCounts['account_lockouts']++;
                    break;
                    
                case 'SUSPICIOUS_ACTIVITY':
                    $ip = $event['ip'] ?? 'unknown';
                    if (!isset($eventCounts['suspicious_ips'][$ip])) {
                        $eventCounts['suspicious_ips'][$ip] = 0;
                    }
                    $eventCounts['suspicious_ips'][$ip]++;
                    break;
            }
        }
    }
    
    /**
     * Check for security alerts
     */
    private function checkSecurityAlerts($eventCounts) {
        $alerts = [];
        
        // Check failed login threshold
        if ($eventCounts['failed_logins'] > $this->alertThresholds['failed_logins_per_hour']) {
            $alerts[] = [
                'type' => 'HIGH_FAILED_LOGINS',
                'message' => "High number of failed login attempts: {$eventCounts['failed_logins']} in the last hour",
                'severity' => 'HIGH'
            ];
        }
        
        // Check rate limit threshold
        if ($eventCounts['rate_limit_exceeded'] > $this->alertThresholds['rate_limit_exceeded_per_hour']) {
            $alerts[] = [
                'type' => 'HIGH_RATE_LIMIT_EXCEEDED',
                'message' => "High number of rate limit violations: {$eventCounts['rate_limit_exceeded']} in the last hour",
                'severity' => 'MEDIUM'
            ];
        }
        
        // Check account lockout threshold
        if ($eventCounts['account_lockouts'] > $this->alertThresholds['account_lockouts_per_hour']) {
            $alerts[] = [
                'type' => 'HIGH_ACCOUNT_LOCKOUTS',
                'message' => "High number of account lockouts: {$eventCounts['account_lockouts']} in the last hour",
                'severity' => 'HIGH'
            ];
        }
        
        // Check for suspicious IPs
        foreach ($eventCounts['suspicious_ips'] as $ip => $count) {
            if ($count > $this->alertThresholds['suspicious_ips_per_hour']) {
                $alerts[] = [
                    'type' => 'SUSPICIOUS_IP',
                    'message' => "Suspicious activity from IP: $ip ($count events in the last hour)",
                    'severity' => 'HIGH',
                    'ip' => $ip
                ];
            }
        }
        
        // Send alerts
        foreach ($alerts as $alert) {
            $this->sendSecurityAlert($alert);
        }
        
        // Reset counters
        $eventCounts['failed_logins'] = 0;
        $eventCounts['rate_limit_exceeded'] = 0;
        $eventCounts['account_lockouts'] = 0;
        $eventCounts['suspicious_ips'] = [];
    }
    
    /**
     * Send security alert
     */
    private function sendSecurityAlert($alert) {
        $timestamp = date('Y-m-d H:i:s');
        $message = "[$timestamp] SECURITY ALERT: {$alert['message']}";
        
        echo "🚨 $message\n";
        
        // Log alert
        $alertLog = __DIR__ . '/logs/security-alerts.log';
        file_put_contents($alertLog, $message . "\n", FILE_APPEND | LOCK_EX);
        
        // Send email alert (if configured)
        if (defined('SMTP_USER') && !empty(SMTP_USER)) {
            $this->sendEmailAlert($alert);
        }
        
        // Send webhook alert (if configured)
        $this->sendWebhookAlert($alert);
    }
    
    /**
     * Send email alert
     */
    private function sendEmailAlert($alert) {
        try {
            $subject = "Security Alert: {$alert['type']}";
            $body = "Security Alert Details:\n\n";
            $body .= "Type: {$alert['type']}\n";
            $body .= "Severity: {$alert['severity']}\n";
            $body .= "Message: {$alert['message']}\n";
            $body .= "Time: " . date('Y-m-d H:i:s') . "\n";
            $body .= "Server: " . gethostname() . "\n";
            
            // Use PHP mail function (configure with proper SMTP in production)
            mail(SMTP_FROM_EMAIL, $subject, $body);
            
        } catch (Exception $e) {
            error_log("Failed to send email alert: " . $e->getMessage());
        }
    }
    
    /**
     * Send webhook alert
     */
    private function sendWebhookAlert($alert) {
        // This would integrate with services like Slack, Discord, or PagerDuty
        // For now, just log the webhook data
        $webhookData = [
            'timestamp' => date('c'),
            'alert' => $alert,
            'server' => gethostname()
        ];
        
        $webhookLog = __DIR__ . '/logs/webhook-alerts.log';
        file_put_contents($webhookLog, json_encode($webhookData) . "\n", FILE_APPEND | LOCK_EX);
    }
    
    /**
     * Generate security report
     */
    public function generateSecurityReport($hours = 24) {
        echo "📊 Generating security report for the last $hours hours...\n";
        
        if (!file_exists($this->logFile)) {
            echo "No security log file found.\n";
            return;
        }
        
        $lines = file($this->logFile, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
        $cutoffTime = time() - ($hours * 3600);
        
        $report = [
            'total_events' => 0,
            'event_types' => [],
            'severity_counts' => [],
            'top_ips' => [],
            'failed_logins' => 0,
            'successful_logins' => 0,
            'account_lockouts' => 0,
            'rate_limit_violations' => 0
        ];
        
        foreach ($lines as $line) {
            $event = json_decode($line, true);
            if (!$event) continue;
            
            $eventTime = strtotime($event['timestamp']);
            if ($eventTime < $cutoffTime) continue;
            
            $report['total_events']++;
            
            // Count event types
            $eventType = $event['event_type'];
            if (!isset($report['event_types'][$eventType])) {
                $report['event_types'][$eventType] = 0;
            }
            $report['event_types'][$eventType]++;
            
            // Count severity levels
            $severity = $event['severity'] ?? 'UNKNOWN';
            if (!isset($report['severity_counts'][$severity])) {
                $report['severity_counts'][$severity] = 0;
            }
            $report['severity_counts'][$severity]++;
            
            // Count IPs
            $ip = $event['ip'] ?? 'unknown';
            if (!isset($report['top_ips'][$ip])) {
                $report['top_ips'][$ip] = 0;
            }
            $report['top_ips'][$ip]++;
            
            // Count specific events
            switch ($eventType) {
                case 'LOGIN_FAILURE':
                    $report['failed_logins']++;
                    break;
                case 'LOGIN_SUCCESS':
                    $report['successful_logins']++;
                    break;
                case 'ACCOUNT_LOCKED':
                    $report['account_lockouts']++;
                    break;
                case 'RATE_LIMIT_EXCEEDED':
                    $report['rate_limit_violations']++;
                    break;
            }
        }
        
        // Sort top IPs
        arsort($report['top_ips']);
        $report['top_ips'] = array_slice($report['top_ips'], 0, 10, true);
        
        // Display report
        echo "\n📈 Security Report Summary:\n";
        echo "========================\n";
        echo "Total Events: {$report['total_events']}\n";
        echo "Failed Logins: {$report['failed_logins']}\n";
        echo "Successful Logins: {$report['successful_logins']}\n";
        echo "Account Lockouts: {$report['account_lockouts']}\n";
        echo "Rate Limit Violations: {$report['rate_limit_violations']}\n";
        
        echo "\n📊 Event Types:\n";
        foreach ($report['event_types'] as $type => $count) {
            echo "  $type: $count\n";
        }
        
        echo "\n🚨 Severity Levels:\n";
        foreach ($report['severity_counts'] as $severity => $count) {
            echo "  $severity: $count\n";
        }
        
        echo "\n🌐 Top IP Addresses:\n";
        foreach ($report['top_ips'] as $ip => $count) {
            echo "  $ip: $count events\n";
        }
        
        // Save report to file
        $reportFile = __DIR__ . '/logs/security-report-' . date('Y-m-d-H-i-s') . '.json';
        file_put_contents($reportFile, json_encode($report, JSON_PRETTY_PRINT));
        echo "\n💾 Report saved to: $reportFile\n";
        
        return $report;
    }
    
    /**
     * Block suspicious IPs
     */
    public function blockSuspiciousIPs() {
        echo "🚫 Checking for IPs to block...\n";
        
        $report = $this->generateSecurityReport(1); // Last hour
        
        foreach ($report['top_ips'] as $ip => $count) {
            if ($count > 50) { // Block IPs with more than 50 events in the last hour
                echo "🚫 Blocking suspicious IP: $ip ($count events)\n";
                $this->blockIP($ip);
            }
        }
    }
    
    /**
     * Block an IP address
     */
    private function blockIP($ip) {
        // This would integrate with firewall rules (iptables, ufw, etc.)
        // For now, just log the block action
        $blockLog = __DIR__ . '/logs/blocked-ips.log';
        $blockEntry = [
            'timestamp' => date('Y-m-d H:i:s'),
            'ip' => $ip,
            'reason' => 'Suspicious activity',
            'action' => 'blocked'
        ];
        
        file_put_contents($blockLog, json_encode($blockEntry) . "\n", FILE_APPEND | LOCK_EX);
    }
}

// Command line interface
if (php_sapi_name() === 'cli') {
    $monitor = new SecurityMonitor();
    
    $command = $argv[1] ?? 'monitor';
    
    switch ($command) {
        case 'monitor':
            $monitor->monitorSecurityEvents();
            break;
            
        case 'report':
            $hours = $argv[2] ?? 24;
            $monitor->generateSecurityReport($hours);
            break;
            
        case 'block':
            $monitor->blockSuspiciousIPs();
            break;
            
        default:
            echo "Usage: php security-monitor.php [monitor|report|block]\n";
            echo "  monitor - Start real-time monitoring\n";
            echo "  report [hours] - Generate security report\n";
            echo "  block - Block suspicious IPs\n";
            break;
    }
}
?>
