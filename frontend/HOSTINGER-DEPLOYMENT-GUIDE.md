# My Best Life - Hostinger Deployment Guide

This guide will walk you through deploying the My Best Life platform to your Hostinger hosting account.

## Prerequisites

- Hostinger hosting account with Node.js support
- Domain name (e.g., mybestlifeapp.com)
- Access to Hostinger control panel
- Git repository access

## Step 1: Prepare Your Hostinger Account

### 1.1 Enable Node.js
1. Log into your Hostinger control panel
2. Go to "Hosting" → "Manage" → "Advanced" → "Node.js"
3. Enable Node.js for your domain
4. Set Node.js version to 18.x or higher

### 1.2 Configure Domain
1. Point your domain (mybestlifeapp.com) to your Hostinger hosting
2. Set up SSL certificate (free with Hostinger)
3. Configure DNS settings if needed

## Step 2: Upload Files to Hostinger

### 2.1 Upload Frontend Files
1. Use File Manager or FTP to upload the following files to your public_html directory:
   - `index-modern.html` → `index.html`
   - `register-modern.html` → `register.html`
   - `login-modern.html` → `login.html`
   - `MBL_Logo.webp`
   - `favicon.ico`

### 2.2 Upload Backend Files
1. Create a new directory called `backend` in your public_html
2. Upload all backend files from the `backend/` folder
3. Ensure the following structure:
   ```
   public_html/
   ├── index.html
   ├── register.html
   ├── login.html
   ├── MBL_Logo.webp
   ├── favicon.ico
   └── backend/
       ├── app.js
       ├── package.json
       ├── prisma/
       ├── routes/
       ├── services/
       └── middleware/
   ```

## Step 3: Configure Environment Variables

### 3.1 Create .env File
Create a `.env` file in your backend directory with the following variables:

```env
# Database Configuration
DATABASE_URL="postgresql://username:password@host:port/database"

# JWT Configuration
JWT_SECRET="your-super-secret-jwt-key-here"

# Email Configuration (Gmail example)
SMTP_HOST="smtp.gmail.com"
SMTP_PORT=587
SMTP_USER="your-email@gmail.com"
SMTP_PASS="your-app-password"

# Frontend URL
FRONTEND_URL="https://mybestlifeapp.com"

# Node Environment
NODE_ENV="production"
```

### 3.2 Gmail App Password Setup
1. Go to your Google Account settings
2. Enable 2-factor authentication
3. Generate an App Password for "Mail"
4. Use this password in SMTP_PASS

## Step 4: Database Setup

### 4.1 PostgreSQL Database
1. In Hostinger control panel, go to "Databases" → "PostgreSQL"
2. Create a new PostgreSQL database
3. Note down:
   - Database name
   - Username
   - Password
   - Host
   - Port

### 4.2 Update Database URL
Update your `.env` file with the actual database credentials:

```env
DATABASE_URL="postgresql://your_username:your_password@your_host:5432/your_database_name"
```

### 4.3 Initialize Database
1. SSH into your hosting (if available) or use Hostinger's Terminal
2. Navigate to backend directory
3. Run database setup:

```bash
cd backend
npm install
npx prisma generate
npx prisma db push
```

## Step 5: Install Dependencies

### 5.1 Install Node.js Dependencies
In your backend directory:

```bash
npm install
npm install -g pm2
```

### 5.2 Install Production Dependencies
```bash
npm install --production
```

## Step 6: Configure Hostinger

### 6.1 Set Node.js Entry Point
1. In Hostinger control panel, go to "Node.js"
2. Set the entry point to: `backend/app.js`
3. Set the Node.js version to 18.x or higher

### 6.2 Configure Domain
1. Set your domain to point to the Node.js application
2. Ensure the domain is properly configured for Node.js

## Step 7: Start the Application

### 7.1 Start with PM2
```bash
cd backend
pm2 start app.js --name "mybestlife"
pm2 startup
pm2 save
```

### 7.2 Alternative: Start with Node
```bash
cd backend
node app.js
```

## Step 8: Test Your Deployment

### 8.1 Test Frontend
1. Visit `https://mybestlifeapp.com`
2. Verify the landing page loads correctly
3. Test navigation between pages

### 8.2 Test Backend
1. Test registration: `https://mybestlifeapp.com/register.html`
2. Test login: `https://mybestlifeapp.com/login.html`
3. Verify API endpoints are working

### 8.3 Test Email Functionality
1. Register a new user
2. Check if welcome email is received
3. Verify email verification works

## Step 9: SSL and Security

### 9.1 Enable SSL
1. In Hostinger control panel, go to "SSL"
2. Enable SSL for your domain
3. Force HTTPS redirect

### 9.2 Security Headers
Add security headers to your backend:

```javascript
// In app.js
app.use(helmet());
app.use(cors({
  origin: ['https://mybestlifeapp.com'],
  credentials: true
}));
```

## Step 10: Monitoring and Maintenance

### 10.1 Monitor Application
```bash
pm2 status
pm2 logs mybestlife
pm2 monit
```

### 10.2 Set up Logging
Ensure your application logs are properly configured for production.

### 10.3 Regular Backups
Set up regular database backups through Hostinger's control panel.

## Troubleshooting

### Common Issues

#### 1. Node.js Not Starting
- Check Node.js version compatibility
- Verify entry point configuration
- Check error logs in Hostinger control panel

#### 2. Database Connection Issues
- Verify DATABASE_URL format
- Check database credentials
- Ensure database is accessible from hosting

#### 3. Email Not Working
- Verify SMTP credentials
- Check if Gmail app password is correct
- Ensure SMTP port is not blocked

#### 4. Frontend Not Loading
- Check file permissions
- Verify file paths
- Check browser console for errors

### Debug Commands

```bash
# Check Node.js version
node --version

# Check npm version
npm --version

# Check PM2 status
pm2 status

# View application logs
pm2 logs mybestlife

# Restart application
pm2 restart mybestlife
```

## Performance Optimization

### 1. Enable Compression
```javascript
const compression = require('compression');
app.use(compression());
```

### 2. Cache Static Files
```javascript
app.use(express.static('public', {
  maxAge: '1d',
  etag: true
}));
```

### 3. Database Optimization
- Add database indexes
- Optimize queries
- Use connection pooling

## Backup and Recovery

### 1. Database Backup
```bash
pg_dump -h host -U username -d database > backup.sql
```

### 2. File Backup
Regularly backup your application files and configuration.

### 3. Recovery Plan
Document your recovery procedures for different failure scenarios.

## Support and Maintenance

### 1. Regular Updates
- Keep Node.js updated
- Update dependencies regularly
- Monitor security advisories

### 2. Performance Monitoring
- Monitor response times
- Track error rates
- Monitor resource usage

### 3. User Support
- Set up support email
- Create help documentation
- Monitor user feedback

## Final Checklist

- [ ] Frontend files uploaded and accessible
- [ ] Backend application running
- [ ] Database connected and initialized
- [ ] Email functionality working
- [ ] SSL certificate enabled
- [ ] Domain properly configured
- [ ] Application monitoring set up
- [ ] Backup procedures configured
- [ ] Security measures implemented
- [ ] Performance optimized

## Contact and Support

For technical support:
- Hostinger Support: Available through control panel
- Application Issues: Check logs and error messages
- Database Issues: Verify credentials and connectivity

## Additional Resources

- [Hostinger Node.js Documentation](https://www.hostinger.com/help/nodejs)
- [Node.js Best Practices](https://nodejs.org/en/docs/guides/nodejs-docker-webapp/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Nodemailer Documentation](https://nodemailer.com/)

---

**Note**: This guide assumes you have basic knowledge of Node.js, PostgreSQL, and web hosting. If you encounter issues, refer to Hostinger's support documentation or contact their support team.




