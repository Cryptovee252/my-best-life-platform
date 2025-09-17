<?php
// My Best Life Platform - Email Service for Shared Hosting
// This service handles all email functionality using PHPMailer

class EmailService {
    private $mailer;
    
    public function __construct() {
        // Initialize PHPMailer
        require_once 'PHPMailer/PHPMailer.php';
        require_once 'PHPMailer/SMTP.php';
        require_once 'PHPMailer/Exception.php';
        
        $this->mailer = new PHPMailer\PHPMailer\PHPMailer(true);
        
        try {
            // Server settings
            $this->mailer->isSMTP();
            $this->mailer->Host = SMTP_HOST;
            $this->mailer->SMTPAuth = true;
            $this->mailer->Username = SMTP_USER;
            $this->mailer->Password = SMTP_PASS;
            $this->mailer->SMTPSecure = PHPMailer\PHPMailer\PHPMailer::ENCRYPTION_STARTTLS;
            $this->mailer->Port = SMTP_PORT;
            
            // Default settings
            $this->mailer->setFrom(SMTP_USER, APP_NAME);
            $this->mailer->isHTML(true);
            $this->mailer->CharSet = 'UTF-8';
            
        } catch (Exception $e) {
            logActivity("Email service initialization failed: " . $e->getMessage(), 'ERROR');
        }
    }
    
    /**
     * Send welcome email to new user
     */
    public function sendWelcomeEmail($user) {
        try {
            $this->mailer->clearAddresses();
            $this->mailer->addAddress($user['email'], $user['name']);
            $this->mailer->Subject = 'Welcome to My Best Life! 🚀';
            
            $htmlBody = $this->getWelcomeEmailTemplate($user);
            $textBody = $this->getWelcomeEmailTextTemplate($user);
            
            $this->mailer->Body = $htmlBody;
            $this->mailer->AltBody = $textBody;
            
            $result = $this->mailer->send();
            
            if ($result) {
                logActivity("Welcome email sent to: " . $user['email'], 'INFO');
            }
            
            return $result;
            
        } catch (Exception $e) {
            logActivity("Welcome email failed for " . $user['email'] . ": " . $e->getMessage(), 'ERROR');
            return false;
        }
    }
    
    /**
     * Send email verification email
     */
    public function sendVerificationEmail($user, $verificationToken) {
        try {
            $this->mailer->clearAddresses();
            $this->mailer->addAddress($user['email'], $user['name']);
            $this->mailer->Subject = 'Verify Your Email - My Best Life';
            
            $verificationUrl = FRONTEND_URL . '/verify-email.html?token=' . $verificationToken;
            
            $htmlBody = $this->getVerificationEmailTemplate($user, $verificationUrl);
            $textBody = $this->getVerificationEmailTextTemplate($user, $verificationUrl);
            
            $this->mailer->Body = $htmlBody;
            $this->mailer->AltBody = $textBody;
            
            $result = $this->mailer->send();
            
            if ($result) {
                logActivity("Verification email sent to: " . $user['email'], 'INFO');
            }
            
            return $result;
            
        } catch (Exception $e) {
            logActivity("Verification email failed for " . $user['email'] . ": " . $e->getMessage(), 'ERROR');
            return false;
        }
    }
    
    /**
     * Send password reset email
     */
    public function sendPasswordResetEmail($user, $resetToken) {
        try {
            $this->mailer->clearAddresses();
            $this->mailer->addAddress($user['email'], $user['name']);
            $this->mailer->Subject = 'Reset Your Password - My Best Life';
            
            $resetUrl = FRONTEND_URL . '/reset-password.html?token=' . $resetToken;
            
            $htmlBody = $this->getPasswordResetEmailTemplate($user, $resetUrl);
            $textBody = $this->getPasswordResetEmailTextTemplate($user, $resetUrl);
            
            $this->mailer->Body = $htmlBody;
            $this->mailer->AltBody = $textBody;
            
            $result = $this->mailer->send();
            
            if ($result) {
                logActivity("Password reset email sent to: " . $user['email'], 'INFO');
            }
            
            return $result;
            
        } catch (Exception $e) {
            logActivity("Password reset email failed for " . $user['email'] . ": " . $e->getMessage(), 'ERROR');
            return false;
        }
    }
    
    /**
     * Test email connection
     */
    public function testConnection() {
        try {
            $this->mailer->clearAddresses();
            $this->mailer->addAddress(SMTP_USER); // Send to self for testing
            $this->mailer->Subject = 'My Best Life - Email Test';
            $this->mailer->Body = 'This is a test email to verify your email configuration is working correctly.';
            $this->mailer->AltBody = 'This is a test email to verify your email configuration is working correctly.';
            
            $result = $this->mailer->send();
            
            if ($result) {
                logActivity("Email test successful", 'INFO');
            }
            
            return $result;
            
        } catch (Exception $e) {
            logActivity("Email test failed: " . $e->getMessage(), 'ERROR');
            return false;
        }
    }
    
    /**
     * Get welcome email HTML template
     */
    private function getWelcomeEmailTemplate($user) {
        return '
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Welcome to My Best Life!</title>
            <style>
                body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
                .container { max-width: 600px; margin: 0 auto; padding: 20px; }
                .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
                .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
                .button { display: inline-block; background: #667eea; color: white; padding: 15px 30px; text-decoration: none; border-radius: 25px; margin: 20px 0; }
                .footer { text-align: center; margin-top: 30px; color: #666; font-size: 14px; }
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <h1>🚀 Welcome to My Best Life!</h1>
                    <p>Your journey to greatness starts now</p>
                </div>
                <div class="content">
                    <h2>Hi ' . htmlspecialchars($user['name']) . '!</h2>
                    <p>Welcome to <strong>My Best Life</strong> - the platform that will help you unlock your full potential and create the life you\'ve always dreamed of!</p>
                    
                    <p>We\'re excited to have you join our community of people who are committed to:</p>
                    <ul>
                        <li>🌟 Personal growth and development</li>
                        <li>💪 Building healthy habits</li>
                        <li>🎯 Achieving meaningful goals</li>
                        <li>🤝 Connecting with like-minded individuals</li>
                    </ul>
                    
                    <p><strong>Next Step:</strong> Please check your email for a verification link to activate your account and start your journey!</p>
                    
                    <p>If you have any questions or need support, don\'t hesitate to reach out to our team.</p>
                    
                    <p>Here\'s to your best life! 🎉</p>
                    
                    <p>Best regards,<br>The My Best Life Team</p>
                </div>
                <div class="footer">
                    <p>© 2024 My Best Life. All rights reserved.</p>
                    <p>This email was sent to ' . htmlspecialchars($user['email']) . '</p>
                </div>
            </div>
        </body>
        </html>';
    }
    
    /**
     * Get welcome email text template
     */
    private function getWelcomeEmailTextTemplate($user) {
        return "Welcome to My Best Life!\n\n" .
               "Hi " . $user['name'] . "!\n\n" .
               "Welcome to My Best Life - the platform that will help you unlock your full potential and create the life you've always dreamed of!\n\n" .
               "We're excited to have you join our community of people who are committed to personal growth, building healthy habits, achieving meaningful goals, and connecting with like-minded individuals.\n\n" .
               "Next Step: Please check your email for a verification link to activate your account and start your journey!\n\n" .
               "If you have any questions or need support, don't hesitate to reach out to our team.\n\n" .
               "Here's to your best life!\n\n" .
               "Best regards,\nThe My Best Life Team\n\n" .
               "© 2024 My Best Life. All rights reserved.\n" .
               "This email was sent to " . $user['email'];
    }
    
    /**
     * Get verification email HTML template
     */
    private function getVerificationEmailTemplate($user, $verificationUrl) {
        return '
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Verify Your Email - My Best Life</title>
            <style>
                body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
                .container { max-width: 600px; margin: 0 auto; padding: 20px; }
                .header { background: linear-gradient(135deg, #43e97b 0%, #38f9d7 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
                .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
                .button { display: inline-block; background: #43e97b; color: white; padding: 15px 30px; text-decoration: none; border-radius: 25px; margin: 20px 0; }
                .footer { text-align: center; margin-top: 30px; color: #666; font-size: 14px; }
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <h1>✅ Verify Your Email</h1>
                    <p>Complete your My Best Life account setup</p>
                </div>
                <div class="content">
                    <h2>Hi ' . htmlspecialchars($user['name']) . '!</h2>
                    <p>Thanks for joining <strong>My Best Life</strong>! To complete your account setup, please verify your email address.</p>
                    
                    <p>Click the button below to verify your email and start your journey:</p>
                    
                    <div style="text-align: center;">
                        <a href="' . $verificationUrl . '" class="button">Verify My Email</a>
                    </div>
                    
                    <p>Or copy and paste this link into your browser:</p>
                    <p style="word-break: break-all; background: #eee; padding: 15px; border-radius: 5px; font-size: 12px;">' . $verificationUrl . '</p>
                    
                    <p><strong>Important:</strong> This verification link will expire in 24 hours for security reasons.</p>
                    
                    <p>If you didn\'t create this account, you can safely ignore this email.</p>
                    
                    <p>Best regards,<br>The My Best Life Team</p>
                </div>
                <div class="footer">
                    <p>© 2024 My Best Life. All rights reserved.</p>
                    <p>This email was sent to ' . htmlspecialchars($user['email']) . '</p>
                </div>
            </div>
        </body>
        </html>';
    }
    
    /**
     * Get verification email text template
     */
    private function getVerificationEmailTextTemplate($user, $verificationUrl) {
        return "Verify Your Email - My Best Life\n\n" .
               "Hi " . $user['name'] . "!\n\n" .
               "Thanks for joining My Best Life! To complete your account setup, please verify your email address.\n\n" .
               "Click the link below to verify your email and start your journey:\n\n" .
               $verificationUrl . "\n\n" .
               "Important: This verification link will expire in 24 hours for security reasons.\n\n" .
               "If you didn't create this account, you can safely ignore this email.\n\n" .
               "Best regards,\nThe My Best Life Team\n\n" .
               "© 2024 My Best Life. All rights reserved.\n" .
               "This email was sent to " . $user['email'];
    }
    
    /**
     * Get password reset email HTML template
     */
    private function getPasswordResetEmailTemplate($user, $resetUrl) {
        return '
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Reset Your Password - My Best Life</title>
            <style>
                body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
                .container { max-width: 600px; margin: 0 auto; padding: 20px; }
                .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
                .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
                .button { display: inline-block; background: #667eea; color: white; padding: 15px 30px; text-decoration: none; border-radius: 25px; margin: 20px 0; }
                .footer { text-align: center; margin-top: 30px; color: #666; font-size: 14px; }
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <h1>🔐 Reset Your Password</h1>
                    <p>Secure your My Best Life account</p>
                </div>
                <div class="content">
                    <h2>Hi ' . htmlspecialchars($user['name']) . '!</h2>
                    <p>We received a request to reset your password for your <strong>My Best Life</strong> account.</p>
                    
                    <p>Click the button below to create a new password:</p>
                    
                    <div style="text-align: center;">
                        <a href="' . $resetUrl . '" class="button">Reset My Password</a>
                    </div>
                    
                    <p>Or copy and paste this link into your browser:</p>
                    <p style="word-break: break-all; background: #eee; padding: 15px; border-radius: 5px; font-size: 12px;">' . $resetUrl . '</p>
                    
                    <p><strong>Important:</strong> This reset link will expire in 1 hour for security reasons.</p>
                    
                    <p>If you didn\'t request a password reset, you can safely ignore this email. Your password will remain unchanged.</p>
                    
                    <p>Best regards,<br>The My Best Life Team</p>
                </div>
                <div class="footer">
                    <p>© 2024 My Best Life. All rights reserved.</p>
                    <p>This email was sent to ' . htmlspecialchars($user['email']) . '</p>
                </div>
            </div>
        </body>
        </html>';
    }
    
    /**
     * Get password reset email text template
     */
    private function getPasswordResetEmailTextTemplate($user, $resetUrl) {
        return "Reset Your Password - My Best Life\n\n" .
               "Hi " . $user['name'] . "!\n\n" .
               "We received a request to reset your password for your My Best Life account.\n\n" .
               "Click the link below to create a new password:\n\n" .
               $resetUrl . "\n\n" .
               "Important: This reset link will expire in 1 hour for security reasons.\n\n" .
               "If you didn't request a password reset, you can safely ignore this email. Your password will remain unchanged.\n\n" .
               "Best regards,\nThe My Best Life Team\n\n" .
               "© 2024 My Best Life. All rights reserved.\n" .
               "This email was sent to " . $user['email'];
    }
}
?>
