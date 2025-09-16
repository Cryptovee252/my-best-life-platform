# Hostinger Node.js Setup Guide

## 🚨 Current Issue: Backend API Not Running

Your frontend is deployed successfully, but the Node.js backend isn't running. This is why registration fails with a 404 error.

## 🔧 Step-by-Step Fix

### 1. Access Hostinger Control Panel
1. Go to [Hostinger Control Panel](https://hpanel.hostinger.com)
2. Log in with your credentials
3. Select your domain: `mybestlifeapp.com`

### 2. Enable Node.js
1. Go to **Hosting** → **Manage** → **Advanced** → **Node.js**
2. Click **Enable Node.js**
3. Set **Node.js Version**: `18.x` or higher
4. Set **Application Root**: `public_html`
5. Set **Application Startup File**: `backend/app.js`
6. Click **Save**

### 3. Configure Environment Variables
1. In the Node.js section, find **Environment Variables**
2. Add the following variables:

```
NODE_ENV=production
PORT=3000
DATABASE_URL=postgresql://your_username:your_password@your_host:5432/your_database
JWT_SECRET=your-super-secret-jwt-key-here
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASS=your-app-password
FRONTEND_URL=https://mybestlifeapp.com
```

### 4. Setup PostgreSQL Database
1. Go to **Databases** → **PostgreSQL**
2. Click **Create Database**
3. Note down:
   - Database name
   - Username
   - Password
   - Host
   - Port (usually 5432)

### 5. Install Dependencies and Start Application

#### Option A: Using Hostinger Terminal (if available)
1. Go to **Hosting** → **Manage** → **Advanced** → **Terminal**
2. Run these commands:

```bash
cd public_html/backend
npm install --production
npx prisma generate
npx prisma db push
pm2 start app.js --name "mybestlife"
pm2 save
pm2 startup
```

#### Option B: Using File Manager
1. Go to **File Manager**
2. Navigate to `public_html/backend`
3. Create a `.env` file with your environment variables
4. Run the startup script: `./start-app.sh`

### 6. Verify Node.js is Running
1. In Node.js section, check **Application Status**
2. Should show "Running" or "Active"
3. Check **Application Logs** for any errors

## 🔍 Troubleshooting

### Common Issues:

#### 1. Node.js Not Starting
- **Check**: Application Startup File is set to `backend/app.js`
- **Check**: Node.js version is 18.x or higher
- **Check**: Environment variables are set correctly

#### 2. Database Connection Issues
- **Check**: DATABASE_URL format is correct
- **Check**: Database credentials are correct
- **Check**: Database is accessible from hosting

#### 3. Port Issues
- **Check**: PORT environment variable is set
- **Check**: Hostinger allows the port you're using

#### 4. File Permissions
- **Check**: Files have correct permissions (755 for directories, 644 for files)
- **Check**: Node.js has permission to read files

## 📋 Quick Checklist

- [ ] Node.js enabled in Hostinger
- [ ] Application Startup File: `backend/app.js`
- [ ] Node.js version: 18.x or higher
- [ ] Environment variables configured
- [ ] PostgreSQL database created
- [ ] Dependencies installed (`npm install`)
- [ ] Database schema pushed (`npx prisma db push`)
- [ ] Application started with PM2
- [ ] Application status shows "Running"

## 🧪 Test Your Setup

### 1. Test Node.js Application
```bash
curl https://mybestlifeapp.com/backend/api/auth/register
```
Should return a response (not 404)

### 2. Test Registration
1. Go to `https://mybestlifeapp.com/register.html`
2. Try to register a new user
3. Check for any error messages

### 3. Check Application Logs
```bash
pm2 logs mybestlife
```

## 🆘 If You Need Help

### Hostinger Support
- **Live Chat**: Available in control panel
- **Knowledge Base**: [Hostinger Help Center](https://support.hostinger.com)
- **Node.js Guide**: [Hostinger Node.js Documentation](https://support.hostinger.com/en/articles/1583299-how-to-use-node-js)

### Common Commands
```bash
# Check PM2 status
pm2 status

# View application logs
pm2 logs mybestlife

# Restart application
pm2 restart mybestlife

# Stop application
pm2 stop mybestlife

# Start application
pm2 start app.js --name "mybestlife"
```

## 🎯 Expected Result

After completing these steps:
- ✅ Node.js application should be running
- ✅ API endpoints should respond (not 404)
- ✅ Registration should work
- ✅ Database should be connected
- ✅ Email functionality should work

## 📞 Next Steps

1. **Complete the Node.js setup** using this guide
2. **Test the registration** functionality
3. **Let me know** if you encounter any issues
4. **I'll help troubleshoot** any remaining problems

---

**Remember**: The frontend is already deployed and working. We just need to get the Node.js backend running on Hostinger!
