# My Best Life - Automated Hostinger Deployment Setup

This guide will help you set up automated deployment from GitHub to your Hostinger account at `mybestlifeapp.com`.

## 🚀 What This Setup Provides

- **Automated Deployment**: Every push to main branch deploys to Hostinger
- **Zero Manual Work**: No more manual file uploads
- **Version Control**: Track all changes and rollback if needed
- **Error Monitoring**: GitHub Actions logs show deployment status
- **Easy Iteration**: Fix bugs and add features seamlessly

## 📋 Prerequisites

1. **Hostinger Account** with:
   - Node.js support enabled
   - FTP access credentials
   - PostgreSQL database
   - Domain: `mybestlifeapp.com`

2. **GitHub Repository**: Already set up ✅
3. **FTP Credentials**: From Hostinger control panel

## 🔧 Step 1: Get Hostinger FTP Credentials

### 1.1 Access Hostinger Control Panel
1. Log into your Hostinger account
2. Go to **Hosting** → **Manage** → **Files** → **FTP Accounts**
3. Note down or create FTP credentials:
   - **FTP Host**: `ftp.yourdomain.com` or IP address
   - **FTP Username**: Your FTP username
   - **FTP Password**: Your FTP password
   - **Port**: Usually 21

### 1.2 Alternative: File Manager Access
If you prefer using Hostinger's File Manager:
1. Go to **Hosting** → **Manage** → **Files** → **File Manager**
2. Note the server details for API access

## 🔐 Step 2: Configure GitHub Secrets

### 2.1 Add FTP Credentials to GitHub
1. Go to your GitHub repository: https://github.com/Cryptovee252/my-best-life-platform
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret** and add:

```
Name: HOSTINGER_FTP_HOST
Value: ftp.yourdomain.com (or your FTP host)
```

```
Name: HOSTINGER_FTP_USERNAME  
Value: your_ftp_username
```

```
Name: HOSTINGER_FTP_PASSWORD
Value: your_ftp_password
```

### 2.2 Optional: Add Database Secrets
If you want automated database setup:

```
Name: HOSTINGER_DB_URL
Value: postgresql://username:password@host:port/database
```

```
Name: JWT_SECRET
Value: your-super-secret-jwt-key-here
```

## 🏗️ Step 3: Configure Hostinger

### 3.1 Enable Node.js
1. In Hostinger control panel: **Hosting** → **Manage** → **Advanced** → **Node.js**
2. Enable Node.js for your domain
3. Set Node.js version to **18.x** or higher
4. Set entry point to: `backend/app.js`

### 3.2 Setup PostgreSQL Database
1. Go to **Databases** → **PostgreSQL**
2. Create a new database
3. Note down credentials for your `.env` file

### 3.3 Configure Domain
1. Ensure `mybestlifeapp.com` points to your Hostinger hosting
2. Enable SSL certificate (free with Hostinger)
3. Force HTTPS redirect

## 🚀 Step 4: Test Deployment

### 4.1 Trigger Manual Deployment
1. Go to your GitHub repository
2. Click **Actions** tab
3. Select **Simple Hostinger Deployment**
4. Click **Run workflow** → **Run workflow**

### 4.2 Monitor Deployment
- Watch the Actions logs in real-time
- Check for any error messages
- Verify files are uploaded to Hostinger

### 4.3 Test Your Website
1. Visit `https://mybestlifeapp.com`
2. Test registration and login
3. Verify all functionality works

## 🔄 Step 5: Daily Development Workflow

### 5.1 Making Changes
```bash
# 1. Create feature branch
git checkout -b feature/new-feature

# 2. Make your changes
# Edit files, add features, fix bugs

# 3. Commit changes
git add .
git commit -m "Add: new feature description"

# 4. Push to GitHub
git push origin feature/new-feature

# 5. Create Pull Request on GitHub
# 6. After review, merge to main
# 7. GitHub Actions automatically deploys to Hostinger!
```

### 5.2 Automatic Deployment
- **Every push to main** → Automatic deployment
- **Pull Request** → Tests run (no deployment)
- **Manual trigger** → Deploy anytime from Actions tab

## 🛠️ Step 6: Environment Configuration

### 6.1 Create .env File on Hostinger
1. Upload the deployment package
2. Copy `backend/.env.template` to `backend/.env`
3. Fill in your actual values:

```env
# Database Configuration
DATABASE_URL="postgresql://your_username:your_password@your_host:5432/your_database"

# JWT Configuration  
JWT_SECRET="your-super-secret-jwt-key-here"

# Email Configuration
SMTP_HOST="smtp.gmail.com"
SMTP_PORT=587
SMTP_USER="your-email@gmail.com"
SMTP_PASS="your-app-password"

# Frontend URL
FRONTEND_URL="https://mybestlifeapp.com"

# Node Environment
NODE_ENV="production"
```

### 6.2 Setup Database
```bash
# SSH into Hostinger or use Terminal
cd backend
npm install --production
npx prisma generate
npx prisma db push
```

### 6.3 Start Application
```bash
# Use the startup script
./start-app.sh

# Or manually
cd backend
pm2 start app.js --name "mybestlife"
pm2 save
```

## 📊 Step 7: Monitoring and Maintenance

### 7.1 Monitor Deployment Status
- **GitHub Actions**: Check deployment logs
- **Hostinger**: Monitor application status
- **PM2**: `pm2 status` and `pm2 logs mybestlife`

### 7.2 Common Issues and Solutions

#### Deployment Fails
- Check FTP credentials in GitHub Secrets
- Verify Hostinger FTP access
- Check file permissions

#### Application Won't Start
- Verify Node.js configuration
- Check `.env` file exists and is correct
- Run `pm2 logs mybestlife` for errors

#### Database Issues
- Verify DATABASE_URL format
- Check database credentials
- Ensure database is accessible

## 🎯 Benefits of This Setup

### ✅ **For You:**
- **No Manual Uploads**: Changes deploy automatically
- **Version Control**: Track all changes
- **Easy Rollbacks**: Revert to previous versions
- **Professional Workflow**: Industry-standard practices

### ✅ **For Development:**
- **Faster Iteration**: Fix bugs and deploy immediately
- **Error Tracking**: GitHub Actions logs show issues
- **Collaboration**: Others can contribute via Pull Requests
- **Backup**: Your code is safely stored on GitHub

### ✅ **For Users:**
- **Always Updated**: Latest features automatically deployed
- **Reliable**: Automated testing before deployment
- **Fast**: Optimized deployment process

## 🚨 Troubleshooting

### FTP Connection Issues
```bash
# Test FTP connection manually
ftp ftp.yourdomain.com
# Enter username and password
# Try to list files: ls
```

### Node.js Not Starting
```bash
# Check Node.js version
node --version

# Check if app.js exists
ls -la backend/app.js

# Check PM2 status
pm2 status
```

### Database Connection
```bash
# Test database connection
cd backend
npx prisma db push
```

## 📞 Support

### GitHub Actions Issues
- Check Actions tab in your repository
- Review workflow logs for errors
- Verify secrets are correctly set

### Hostinger Issues
- Contact Hostinger support
- Check Hostinger control panel
- Verify Node.js and database configuration

### Application Issues
- Check PM2 logs: `pm2 logs mybestlife`
- Verify environment variables
- Test API endpoints manually

## 🎉 Success Checklist

- [ ] GitHub repository connected to Hostinger
- [ ] FTP credentials added to GitHub Secrets
- [ ] Node.js enabled on Hostinger
- [ ] PostgreSQL database created
- [ ] Environment variables configured
- [ ] First deployment successful
- [ ] Website accessible at `mybestlifeapp.com`
- [ ] Registration and login working
- [ ] Email functionality working

---

**🎯 You're now ready for professional, automated deployment!**

Every time you push changes to GitHub, your website will automatically update. No more manual uploads, no more version confusion - just clean, professional development workflow.

**Next Steps:**
1. Set up the GitHub Secrets
2. Test the deployment
3. Start developing with confidence!

Your "My Best Life" platform is now ready for seamless iteration and professional deployment! 🚀
