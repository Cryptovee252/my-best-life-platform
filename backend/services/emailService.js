const nodemailer = require('nodemailer');

class EmailService {
    constructor() {
        this.transporter = nodemailer.createTransporter({
            host: process.env.SMTP_HOST || 'smtp.gmail.com',
            port: process.env.SMTP_PORT || 587,
            secure: false, // true for 465, false for other ports
            auth: {
                user: process.env.SMTP_USER,
                pass: process.env.SMTP_PASS
            }
        });
    }

    async sendWelcomeEmail(user) {
        try {
            const mailOptions = {
                from: `"My Best Life" <${process.env.SMTP_USER}>`,
                to: user.email,
                subject: 'Welcome to My Best Life! 🎉',
                html: `
                    <!DOCTYPE html>
                    <html>
                    <head>
                        <meta charset="utf-8">
                        <meta name="viewport" content="width=device-width, initial-scale=1.0">
                        <title>Welcome to My Best Life</title>
                        <style>
                            body {
                                font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                                line-height: 1.6;
                                color: #333;
                                max-width: 600px;
                                margin: 0 auto;
                                padding: 20px;
                                background-color: #f8f9fa;
                            }
                            .header {
                                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                                color: white;
                                padding: 40px 20px;
                                text-align: center;
                                border-radius: 12px 12px 0 0;
                            }
                            .header h1 {
                                margin: 0;
                                font-size: 28px;
                                font-weight: 700;
                            }
                            .header p {
                                margin: 10px 0 0 0;
                                opacity: 0.9;
                                font-size: 16px;
                            }
                            .content {
                                background: white;
                                padding: 40px 20px;
                                border-radius: 0 0 12px 12px;
                                box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
                            }
                            .welcome-message {
                                font-size: 18px;
                                color: #333;
                                margin-bottom: 30px;
                            }
                            .features {
                                margin: 30px 0;
                            }
                            .feature {
                                display: flex;
                                align-items: center;
                                margin: 15px 0;
                                padding: 15px;
                                background: #f8f9fa;
                                border-radius: 8px;
                            }
                            .feature i {
                                width: 20px;
                                margin-right: 15px;
                                color: #667eea;
                            }
                            .cta-button {
                                display: inline-block;
                                background: linear-gradient(135deg, #43e97b 0%, #38f9d7 100%);
                                color: white;
                                padding: 15px 30px;
                                text-decoration: none;
                                border-radius: 25px;
                                font-weight: 600;
                                margin: 20px 0;
                                text-align: center;
                            }
                            .footer {
                                text-align: center;
                                margin-top: 30px;
                                padding-top: 20px;
                                border-top: 1px solid #eee;
                                color: #666;
                                font-size: 14px;
                            }
                            .logo {
                                width: 60px;
                                height: 60px;
                                border-radius: 12px;
                                margin-bottom: 20px;
                            }
                        </style>
                    </head>
                    <body>
                        <div class="header">
                            <h1>Welcome to My Best Life! 🎉</h1>
                            <p>Your journey to personal excellence starts now</p>
                        </div>
                        
                        <div class="content">
                            <div class="welcome-message">
                                <p>Hi <strong>${user.name}</strong>,</p>
                                <p>Welcome to My Best Life! We're thrilled to have you join our community of people committed to personal growth, wellness, and living their best lives.</p>
                            </div>

                            <div class="features">
                                <h3>What you can do now:</h3>
                                <div class="feature">
                                    <i>✨</i>
                                    <span>Set up your personal goals and track your progress</span>
                                </div>
                                <div class="feature">
                                    <i>🤝</i>
                                    <span>Connect with like-minded individuals in our community</span>
                                </div>
                                <div class="feature">
                                    <i>📊</i>
                                    <span>Monitor your daily habits and wellness metrics</span>
                                </div>
                                <div class="feature">
                                    <i>🏆</i>
                                    <span>Earn points and celebrate your achievements</span>
                                </div>
                            </div>

                            <div style="text-align: center;">
                                <a href="${process.env.FRONTEND_URL || 'https://mybestlifeapp.com'}/dashboard" class="cta-button">
                                    Get Started Now
                                </a>
                            </div>

                            <div class="footer">
                                <p>If you have any questions, feel free to reach out to our support team.</p>
                                <p>Best regards,<br>The My Best Life Team</p>
                            </div>
                        </div>
                    </body>
                    </html>
                `
            };

            const result = await this.transporter.sendMail(mailOptions);
            console.log('Welcome email sent successfully to:', user.email);
            return result;
        } catch (error) {
            console.error('Error sending welcome email:', error);
            throw error;
        }
    }

    async sendVerificationEmail(user, verificationToken) {
        try {
            const verificationUrl = `${process.env.FRONTEND_URL || 'https://mybestlifeapp.com'}/verify-email?token=${verificationToken}`;
            
            const mailOptions = {
                from: `"My Best Life" <${process.env.SMTP_USER}>`,
                to: user.email,
                subject: 'Verify Your Email - My Best Life',
                html: `
                    <!DOCTYPE html>
                    <html>
                    <head>
                        <meta charset="utf-8">
                        <meta name="viewport" content="width=device-width, initial-scale=1.0">
                        <title>Verify Your Email</title>
                        <style>
                            body {
                                font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                                line-height: 1.6;
                                color: #333;
                                max-width: 600px;
                                margin: 0 auto;
                                padding: 20px;
                                background-color: #f8f9fa;
                            }
                            .header {
                                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                                color: white;
                                padding: 40px 20px;
                                text-align: center;
                                border-radius: 12px 12px 0 0;
                            }
                            .header h1 {
                                margin: 0;
                                font-size: 28px;
                                font-weight: 700;
                            }
                            .content {
                                background: white;
                                padding: 40px 20px;
                                border-radius: 0 0 12px 12px;
                                box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
                            }
                            .verification-button {
                                display: inline-block;
                                background: linear-gradient(135deg, #43e97b 0%, #38f9d7 100%);
                                color: white;
                                padding: 15px 30px;
                                text-decoration: none;
                                border-radius: 25px;
                                font-weight: 600;
                                margin: 20px 0;
                                text-align: center;
                            }
                            .footer {
                                text-align: center;
                                margin-top: 30px;
                                padding-top: 20px;
                                border-top: 1px solid #eee;
                                color: #666;
                                font-size: 14px;
                            }
                        </style>
                    </head>
                    <body>
                        <div class="header">
                            <h1>Verify Your Email Address</h1>
                        </div>
                        
                        <div class="content">
                            <p>Hi <strong>${user.name}</strong>,</p>
                            <p>Thank you for signing up for My Best Life! To complete your registration, please verify your email address by clicking the button below:</p>
                            
                            <div style="text-align: center;">
                                <a href="${verificationUrl}" class="verification-button">
                                    Verify Email Address
                                </a>
                            </div>
                            
                            <p>If the button doesn't work, you can copy and paste this link into your browser:</p>
                            <p style="word-break: break-all; color: #667eea;">${verificationUrl}</p>
                            
                            <p>This link will expire in 24 hours for security reasons.</p>
                            
                            <div class="footer">
                                <p>If you didn't create an account, you can safely ignore this email.</p>
                                <p>Best regards,<br>The My Best Life Team</p>
                            </div>
                        </div>
                    </body>
                    </html>
                `
            };

            const result = await this.transporter.sendMail(mailOptions);
            console.log('Verification email sent successfully to:', user.email);
            return result;
        } catch (error) {
            console.error('Error sending verification email:', error);
            throw error;
        }
    }

    async sendPasswordResetEmail(user, resetToken) {
        try {
            const resetUrl = `${process.env.FRONTEND_URL || 'https://mybestlifeapp.com'}/reset-password?token=${resetToken}`;
            
            const mailOptions = {
                from: `"My Best Life" <${process.env.SMTP_USER}>`,
                to: user.email,
                subject: 'Reset Your Password - My Best Life',
                html: `
                    <!DOCTYPE html>
                    <html>
                    <head>
                        <meta charset="utf-8">
                        <meta name="viewport" content="width=device-width, initial-scale=1.0">
                        <title>Reset Your Password</title>
                        <style>
                            body {
                                font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                                line-height: 1.6;
                                color: #333;
                                max-width: 600px;
                                margin: 0 auto;
                                padding: 20px;
                                background-color: #f8f9fa;
                            }
                            .header {
                                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                                color: white;
                                padding: 40px 20px;
                                text-align: center;
                                border-radius: 12px 12px 0 0;
                            }
                            .header h1 {
                                margin: 0;
                                font-size: 28px;
                                font-weight: 700;
                            }
                            .content {
                                background: white;
                                padding: 40px 20px;
                                border-radius: 0 0 12px 12px;
                                box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
                            }
                            .reset-button {
                                display: inline-block;
                                background: linear-gradient(135deg, #43e97b 0%, #38f9d7 100%);
                                color: white;
                                padding: 15px 30px;
                                text-decoration: none;
                                border-radius: 25px;
                                font-weight: 600;
                                margin: 20px 0;
                                text-align: center;
                            }
                            .footer {
                                text-align: center;
                                margin-top: 30px;
                                padding-top: 20px;
                                border-top: 1px solid #eee;
                                color: #666;
                                font-size: 14px;
                            }
                        </style>
                    </head>
                    <body>
                        <div class="header">
                            <h1>Reset Your Password</h1>
                        </div>
                        
                        <div class="content">
                            <p>Hi <strong>${user.name}</strong>,</p>
                            <p>We received a request to reset your password for your My Best Life account. Click the button below to create a new password:</p>
                            
                            <div style="text-align: center;">
                                <a href="${resetUrl}" class="reset-button">
                                    Reset Password
                                </a>
                            </div>
                            
                            <p>If the button doesn't work, you can copy and paste this link into your browser:</p>
                            <p style="word-break: break-all; color: #667eea;">${resetUrl}</p>
                            
                            <p>This link will expire in 1 hour for security reasons.</p>
                            
                            <p>If you didn't request a password reset, you can safely ignore this email.</p>
                            
                            <div class="footer">
                                <p>Best regards,<br>The My Best Life Team</p>
                            </div>
                        </div>
                    </body>
                    </html>
                `
            };

            const result = await this.transporter.sendMail(mailOptions);
            console.log('Password reset email sent successfully to:', user.email);
            return result;
        } catch (error) {
            console.error('Error sending password reset email:', error);
            throw error;
        }
    }

    async testConnection() {
        try {
            await this.transporter.verify();
            return true;
        } catch (error) {
            console.error('Email service connection test failed:', error);
            return false;
        }
    }
}

module.exports = new EmailService();



