const fs = require('fs');
const path = require('path');
const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

class SecurityLogger {
  constructor() {
    this.logDir = process.env.LOG_FILE_PATH ? path.dirname(process.env.LOG_FILE_PATH) : '/var/log/mybestlife';
    this.securityLogFile = path.join(this.logDir, 'security.log');
    this.auditLogFile = path.join(this.logDir, 'audit.log');
    this.errorLogFile = path.join(this.logDir, 'error.log');
    
    // Ensure log directory exists
    this.ensureLogDirectory();
    
    // Initialize log rotation
    this.initializeLogRotation();
  }

  ensureLogDirectory() {
    if (!fs.existsSync(this.logDir)) {
      fs.mkdirSync(this.logDir, { recursive: true });
      fs.chmodSync(this.logDir, 0o755);
    }
  }

  initializeLogRotation() {
    // Check log file sizes and rotate if necessary
    const maxSize = 10 * 1024 * 1024; // 10MB
    
    [this.securityLogFile, this.auditLogFile, this.errorLogFile].forEach(logFile => {
      if (fs.existsSync(logFile) && fs.statSync(logFile).size > maxSize) {
        this.rotateLogFile(logFile);
      }
    });
  }

  rotateLogFile(logFile) {
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
    const rotatedFile = `${logFile}.${timestamp}`;
    
    try {
      fs.renameSync(logFile, rotatedFile);
      
      // Compress old log file
      const { execSync } = require('child_process');
      execSync(`gzip ${rotatedFile}`, { stdio: 'ignore' });
      
      console.log(`Log file rotated: ${logFile} -> ${rotatedFile}.gz`);
    } catch (error) {
      console.error('Failed to rotate log file:', error);
    }
  }

  formatLogEntry(level, message, metadata = {}) {
    const timestamp = new Date().toISOString();
    const logEntry = {
      timestamp,
      level,
      message,
      metadata: JSON.stringify(metadata),
      pid: process.pid,
      hostname: require('os').hostname()
    };
    
    return JSON.stringify(logEntry);
  }

  writeToFile(filename, logEntry) {
    try {
      fs.appendFileSync(filename, logEntry + '\n');
    } catch (error) {
      console.error('Failed to write to log file:', error);
    }
  }

  async writeToDatabase(logEntry) {
    if (process.env.ENABLE_AUDIT_LOGGING === 'true') {
      try {
        // Create security log table if it doesn't exist
        await prisma.$executeRaw`
          CREATE TABLE IF NOT EXISTS security_logs (
            id SERIAL PRIMARY KEY,
            timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            level VARCHAR(20) NOT NULL,
            message TEXT NOT NULL,
            metadata JSONB,
            pid INTEGER,
            hostname VARCHAR(255)
          )
        `;

        await prisma.$executeRaw`
          INSERT INTO security_logs (timestamp, level, message, metadata, pid, hostname)
          VALUES ($1, $2, $3, $4, $5, $6)
        `, [
          new Date(logEntry.timestamp),
          logEntry.level,
          logEntry.message,
          logEntry.metadata,
          logEntry.pid,
          logEntry.hostname
        ];
      } catch (error) {
        console.error('Failed to write to database:', error);
      }
    }
  }

  // Security event logging
  async logSecurityEvent(eventType, details = {}) {
    const severity = this.getSeverityLevel(eventType);
    const logEntry = this.formatLogEntry(severity, `Security Event: ${eventType}`, details);
    
    // Write to security log file
    this.writeToFile(this.securityLogFile, logEntry);
    
    // Write to database
    await this.writeToDatabase(JSON.parse(logEntry));
    
    // Console output for critical events
    if (severity === 'CRITICAL' || severity === 'HIGH') {
      console.error(`🚨 SECURITY ALERT: ${eventType}`, details);
    }
  }

  // Audit logging
  async logAuditEvent(action, details = {}) {
    const logEntry = this.formatLogEntry('INFO', `Audit: ${action}`, details);
    
    // Write to audit log file
    this.writeToFile(this.auditLogFile, logEntry);
    
    // Write to database
    await this.writeToDatabase(JSON.parse(logEntry));
  }

  // Error logging
  async logError(error, context = {}) {
    const logEntry = this.formatLogEntry('ERROR', error.message, {
      stack: error.stack,
      ...context
    });
    
    // Write to error log file
    this.writeToFile(this.errorLogFile, logEntry);
    
    // Write to database
    await this.writeToDatabase(JSON.parse(logEntry));
    
    // Console output
    console.error('❌ ERROR:', error.message, context);
  }

  // Application logging
  async logApplication(level, message, metadata = {}) {
    const logEntry = this.formatLogEntry(level, message, metadata);
    
    // Write to appropriate log file based on level
    if (level === 'ERROR') {
      this.writeToFile(this.errorLogFile, logEntry);
    } else {
      this.writeToFile(this.auditLogFile, logEntry);
    }
    
    // Write to database
    await this.writeToDatabase(JSON.parse(logEntry));
  }

  getSeverityLevel(eventType) {
    const severityMap = {
      // Critical events
      'ACCOUNT_COMPROMISED': 'CRITICAL',
      'UNAUTHORIZED_ACCESS': 'CRITICAL',
      'DATA_BREACH': 'CRITICAL',
      'MALICIOUS_ACTIVITY': 'CRITICAL',
      
      // High severity events
      'RATE_LIMIT_EXCEEDED': 'HIGH',
      'ACCOUNT_LOCKED': 'HIGH',
      'SUSPICIOUS_LOGIN': 'HIGH',
      'MULTIPLE_FAILED_LOGINS': 'HIGH',
      'SQL_INJECTION_ATTEMPT': 'HIGH',
      'XSS_ATTEMPT': 'HIGH',
      
      // Medium severity events
      'AUTH_FAILURE': 'MEDIUM',
      'INVALID_TOKEN': 'MEDIUM',
      'PASSWORD_RESET_REQUESTED': 'MEDIUM',
      'EMAIL_VERIFICATION_FAILED': 'MEDIUM',
      'UNUSUAL_ACTIVITY': 'MEDIUM',
      
      // Low severity events
      'LOGIN_SUCCESS': 'LOW',
      'LOGOUT': 'LOW',
      'EMAIL_VERIFIED': 'LOW',
      'PASSWORD_RESET_SUCCESS': 'LOW',
      'REGISTRATION_SUCCESS': 'LOW'
    };
    
    return severityMap[eventType] || 'INFO';
  }

  // Get security statistics
  async getSecurityStats(timeframe = '24h') {
    try {
      const timeCondition = this.getTimeCondition(timeframe);
      
      const stats = await prisma.$queryRaw`
        SELECT 
          level,
          COUNT(*) as count,
          COUNT(DISTINCT metadata->>'ip') as unique_ips,
          COUNT(DISTINCT metadata->>'userId') as unique_users
        FROM security_logs 
        WHERE timestamp >= ${timeCondition}
        GROUP BY level
        ORDER BY count DESC
      `;
      
      return stats;
    } catch (error) {
      console.error('Failed to get security stats:', error);
      return [];
    }
  }

  getTimeCondition(timeframe) {
    const now = new Date();
    let hours;
    
    switch (timeframe) {
      case '1h': hours = 1; break;
      case '24h': hours = 24; break;
      case '7d': hours = 24 * 7; break;
      case '30d': hours = 24 * 30; break;
      default: hours = 24;
    }
    
    return new Date(now.getTime() - hours * 60 * 60 * 1000);
  }

  // Get recent security events
  async getRecentSecurityEvents(limit = 50) {
    try {
      const events = await prisma.$queryRaw`
        SELECT 
          timestamp,
          level,
          message,
          metadata
        FROM security_logs 
        WHERE level IN ('CRITICAL', 'HIGH', 'MEDIUM')
        ORDER BY timestamp DESC
        LIMIT ${limit}
      `;
      
      return events;
    } catch (error) {
      console.error('Failed to get recent security events:', error);
      return [];
    }
  }

  // Clean up old logs
  async cleanupOldLogs(retentionDays = 30) {
    try {
      const cutoffDate = new Date();
      cutoffDate.setDate(cutoffDate.getDate() - retentionDays);
      
      await prisma.$executeRaw`
        DELETE FROM security_logs 
        WHERE timestamp < ${cutoffDate}
      `;
      
      console.log(`Cleaned up security logs older than ${retentionDays} days`);
    } catch (error) {
      console.error('Failed to cleanup old logs:', error);
    }
  }

  // Export logs for analysis
  async exportLogs(startDate, endDate, format = 'json') {
    try {
      const logs = await prisma.$queryRaw`
        SELECT *
        FROM security_logs 
        WHERE timestamp >= ${startDate} AND timestamp <= ${endDate}
        ORDER BY timestamp DESC
      `;
      
      if (format === 'csv') {
        return this.convertToCSV(logs);
      }
      
      return logs;
    } catch (error) {
      console.error('Failed to export logs:', error);
      return [];
    }
  }

  convertToCSV(logs) {
    if (logs.length === 0) return '';
    
    const headers = Object.keys(logs[0]).join(',');
    const rows = logs.map(log => 
      Object.values(log).map(value => 
        typeof value === 'string' ? `"${value.replace(/"/g, '""')}"` : value
      ).join(',')
    );
    
    return [headers, ...rows].join('\n');
  }
}

// Create singleton instance
const securityLogger = new SecurityLogger();

module.exports = securityLogger;
