-- My Best Life Platform - Database Setup for Shared Hosting
-- This script creates all necessary tables for the platform
-- Run this in your Hostinger phpMyAdmin or MySQL database

-- Create users table
CREATE TABLE IF NOT EXISTS `users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `username` varchar(50) UNIQUE NOT NULL,
  `email` varchar(255) UNIQUE NOT NULL,
  `phone` varchar(20) DEFAULT NULL,
  `password` varchar(255) NOT NULL,
  `dailyCP` int(11) DEFAULT 0,
  `lifetimeCP` int(11) DEFAULT 0,
  `daysActive` int(11) DEFAULT 1,
  `startDate` date DEFAULT CURRENT_DATE,
  `lastActiveDate` date DEFAULT CURRENT_DATE,
  `isOnline` tinyint(1) DEFAULT 0,
  `lastSeen` datetime DEFAULT CURRENT_TIMESTAMP,
  `emailVerified` tinyint(1) DEFAULT 0,
  `verificationToken` varchar(255) DEFAULT NULL,
  `verificationExpires` datetime DEFAULT NULL,
  `resetToken` varchar(255) DEFAULT NULL,
  `resetExpires` datetime DEFAULT NULL,
  `createdAt` datetime DEFAULT CURRENT_TIMESTAMP,
  `updatedAt` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_email` (`email`),
  KEY `idx_username` (`username`),
  KEY `idx_verification_token` (`verificationToken`),
  KEY `idx_reset_token` (`resetToken`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Create user_sessions table for JWT management
CREATE TABLE IF NOT EXISTS `user_sessions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `token` varchar(500) NOT NULL,
  `expires_at` datetime NOT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `ip_address` varchar(45) DEFAULT NULL,
  `user_agent` text DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_token` (`token`),
  KEY `idx_expires` (`expires_at`),
  FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Create email_logs table for tracking email delivery
CREATE TABLE IF NOT EXISTS `email_logs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) DEFAULT NULL,
  `email_type` enum('welcome','verification','password_reset','welcome_back') NOT NULL,
  `recipient_email` varchar(255) NOT NULL,
  `subject` varchar(255) NOT NULL,
  `sent_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `status` enum('sent','failed','pending') DEFAULT 'pending',
  `error_message` text DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_email_type` (`email_type`),
  KEY `idx_sent_at` (`sent_at`),
  FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Create user_activity table for tracking user engagement
CREATE TABLE IF NOT EXISTS `user_activity` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `activity_type` varchar(50) NOT NULL,
  `description` text DEFAULT NULL,
  `ip_address` varchar(45) DEFAULT NULL,
  `user_agent` text DEFAULT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_activity_type` (`activity_type`),
  KEY `idx_created_at` (`created_at`),
  FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Insert sample data for testing (optional)
INSERT INTO `users` (`name`, `username`, `email`, `password`, `emailVerified`, `createdAt`) VALUES
('Test User', 'testuser', 'test@example.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 1, NOW());

-- Create indexes for better performance
CREATE INDEX `idx_users_email_verified` ON `users` (`emailVerified`);
CREATE INDEX `idx_users_created_at` ON `users` (`createdAt`);
CREATE INDEX `idx_users_last_active` ON `users` (`lastActiveDate`);

-- Add comments for documentation
ALTER TABLE `users` COMMENT = 'Main user accounts table';
ALTER TABLE `user_sessions` COMMENT = 'JWT token management and user sessions';
ALTER TABLE `email_logs` COMMENT = 'Email delivery tracking and logging';
ALTER TABLE `user_activity` COMMENT = 'User activity and engagement tracking';



