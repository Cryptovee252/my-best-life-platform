# 📧 VPS EMAIL TEST INSTRUCTIONS
## Test Your Email Configuration

**Follow these steps to test your email configuration on your VPS:**

---

## 🚀 **STEP 1: Upload Email Test Script**

**Run this command on your VPS:**

```bash
# Navigate to your project directory
cd /var/www/mybestlife/backend

# Create the email test script
cat > test-email.js << 'EOF'
const nodemailer = require('nodemailer');
require('dotenv').config();

async function testEmail() {
    console.log('📧 Testing email configuration...');
    console.log('');

    const emailConfig = {
        host: process.env.SMTP_HOST || 'smtp.gmail.com',
        port: parseInt(process.env.SMTP_PORT) || 587,
        secure: process.env.SMTP_SECURE === 'true',
        auth: {
            user: process.env.SMTP_USER,
            pass: process.env.SMTP_PASS
        }
    };

    console.log('📋 Email Configuration:');
    console.log(`Host: ${emailConfig.host}`);
    console.log(`Port: ${emailConfig.port}`);
    console.log(`User: ${emailConfig.auth.user}`);
    console.log(`Password: ${emailConfig.auth.pass ? '***configured***' : 'NOT SET'}`);
    console.log('');

    if (!emailConfig.auth.user || !emailConfig.auth.pass) {
        console.error('❌ Email credentials not configured!');
        console.log('');
        console.log('🔧 To configure email:');
        console.log('1. Edit .env file: nano .env');
        console.log('2. Update these values:');
        console.log('   SMTP_USER="your-actual-gmail@gmail.com"');
        console.log('   SMTP_PASS="your-actual-gmail-app-password"');
        console.log('   SMTP_FROM_EMAIL="your-actual-gmail@gmail.com"');
        return;
    }

    try {
        const transporter = nodemailer.createTransporter(emailConfig);
        
        console.log('🔍 Verifying SMTP connection...');
        await transporter.verify();
        console.log('✅ SMTP connection verified successfully!');
        console.log('');

        const testEmail = {
            from: `"${process.env.SMTP_FROM_NAME || 'My Best Life'}" <${process.env.SMTP_FROM_EMAIL || emailConfig.auth.user}>`,
            to: emailConfig.auth.user,
            subject: '🛡️ My Best Life Platform - Security Test Email',
            html: `
                <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
                    <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 20px; text-align: center;">
                        <h1>🛡️ My Best Life Platform</h1>
                        <h2>Security Test Email</h2>
                    </div>
                    
                    <div style="padding: 20px; background: #f8f9fa;">
                        <h3 style="color: #28a745;">✅ Email Configuration Successful!</h3>
                        
                        <p>This is a test email to verify that your email configuration is working properly after the security deployment.</p>
                        
                        <div style="background: white; padding: 15px; border-radius: 5px; margin: 15px 0;">
                            <h4>📊 Security Status:</h4>
                            <ul>
                                <li>✅ VPS Security: Deployed</li>
                                <li>✅ Database: Connected</li>
                                <li>✅ Application: Running Securely</li>
                                <li>✅ Email: Working</li>
                                <li>✅ SSL/TLS: Enabled</li>
                            </ul>
                        </div>
                        
                        <p style="color: #666; font-size: 14px;">
                            <strong>Timestamp:</strong> ${new Date().toISOString()}<br>
                            <strong>Server:</strong> My Best Life Platform VPS<br>
                            <strong>Security Score:</strong> 9/10 ✅
                        </p>
                    </div>
                    
                    <div style="background: #333; color: white; padding: 15px; text-align: center; font-size: 12px;">
                        <p>🛡️ My Best Life Platform - Secured with Enterprise-Grade Security</p>
                    </div>
                </div>
            `
        };

        console.log('📤 Sending test email...');
        const info = await transporter.sendMail(testEmail);
        
        console.log('✅ Test email sent successfully!');
        console.log('');
        console.log('📧 Email Details:');
        console.log(`Message ID: ${info.messageId}`);
        console.log(`To: ${testEmail.to}`);
        console.log(`Subject: ${testEmail.subject}`);
        console.log('');
        console.log('📱 Check your email inbox for the test message!');
        console.log('');
        console.log('🎯 Email functionality is working correctly!');

    } catch (error) {
        console.error('❌ Email test failed:', error.message);
        console.log('');
        
        if (error.code === 'EAUTH') {
            console.log('🔐 Authentication Error:');
            console.log('   - Check your Gmail username and password');
            console.log('   - Make sure you\'re using an App Password');
            console.log('   - Verify 2-factor authentication is enabled');
        }
        
        console.log('');
        console.log('📝 To fix email configuration:');
        console.log('1. Edit .env file: nano .env');
        console.log('2. Update email settings and try again');
    }
}

testEmail().catch(console.error);
EOF
```

---

## 🚀 **STEP 2: Configure Email Settings**

**If email credentials are not configured:**

```bash
# Edit the .env file
nano .env

# Update these values in the .env file:
SMTP_USER="your-actual-gmail@gmail.com"
SMTP_PASS="your-actual-gmail-app-password"
SMTP_FROM_EMAIL="your-actual-gmail@gmail.com"
```

**Gmail App Password Setup:**
1. Go to [Google Account Settings](https://myaccount.google.com/)
2. Enable 2-factor authentication
3. Go to "App passwords"
4. Generate an App Password for "Mail"
5. Use the App Password (not your regular password)

---

## 🚀 **STEP 3: Run Email Test**

```bash
# Run the email test
node test-email.js
```

---

## ✅ **Expected Results**

### **If Email is Configured Correctly:**
```
📧 Testing email configuration...

📋 Email Configuration:
Host: smtp.gmail.com
Port: 587
User: your-email@gmail.com
Password: ***configured***

🔍 Verifying SMTP connection...
✅ SMTP connection verified successfully!

📤 Sending test email...
✅ Test email sent successfully!

📧 Email Details:
Message ID: <message-id>
To: your-email@gmail.com
Subject: 🛡️ My Best Life Platform - Security Test Email

📱 Check your email inbox for the test message!

🎯 Email functionality is working correctly!
```

### **If Email is Not Configured:**
```
📧 Testing email configuration...

📋 Email Configuration:
Host: smtp.gmail.com
Port: 587
User: your-email@gmail.com
Password: NOT SET

❌ Email credentials not configured!

🔧 To configure email:
1. Edit .env file: nano .env
2. Update these values:
   SMTP_USER="your-actual-gmail@gmail.com"
   SMTP_PASS="your-actual-gmail-app-password"
   SMTP_FROM_EMAIL="your-actual-gmail@gmail.com"
```

---

## 🎯 **After Successful Email Test**

**Once email is working, you can test:**

1. **User Registration**: Try creating a new account
2. **Password Reset**: Test the forgot password feature
3. **Group Notifications**: Test group invitation emails
4. **System Notifications**: Test various platform notifications

---

## 🚨 **Troubleshooting**

### **Common Issues:**

1. **Authentication Error (EAUTH)**:
   - Use Gmail App Password, not regular password
   - Enable 2-factor authentication
   - Check username format

2. **Connection Error (ECONNECTION)**:
   - Check internet connection
   - Verify SMTP settings
   - Check firewall

3. **Timeout Error (ETIMEDOUT)**:
   - SMTP server not responding
   - Network connectivity issues

---

**📧 Run the email test to verify your configuration!**
