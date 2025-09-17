# My Best Life - Quick Deployment Instructions

## Quick Setup

1. **Upload Files to Hostinger:**
   - Upload all files from this directory to your `public_html` folder
   - Ensure the structure matches:
     ```
     public_html/
     ├── index.html
     ├── register.html
     ├── login.html
     ├── MBL_Logo.webp
     ├── favicon.ico
     └── backend/
     ```

2. **Configure Environment:**
   - Create `.env` file in `backend/` directory
   - Set your database and email credentials

3. **Enable Node.js:**
   - In Hostinger control panel: Hosting → Manage → Advanced → Node.js
   - Set entry point to: `backend/app.js`
   - Set Node.js version to 18.x or higher

4. **Setup Database:**
   - Create PostgreSQL database in Hostinger
   - Update DATABASE_URL in `.env` file
   - Run: `npx prisma db push`

5. **Start Application:**
   - Install dependencies: `npm install`
   - Start with PM2: `pm2 start app.js --name "mybestlife"`

## Environment Variables (.env)

```env
DATABASE_URL="postgresql://username:password@host:port/database"
JWT_SECRET="your-super-secret-jwt-key-here"
SMTP_HOST="smtp.gmail.com"
SMTP_PORT=587
SMTP_USER="your-email@gmail.com"
SMTP_PASS="your-app-password"
FRONTEND_URL="https://mybestlifeapp.com"
NODE_ENV="production"
```

## Quick Commands

```bash
# Install dependencies
npm install

# Setup database
npx prisma generate
npx prisma db push

# Start application
pm2 start app.js --name "mybestlife"
pm2 startup
pm2 save
```

## Test Your Deployment

1. Visit your domain (e.g., https://mybestlifeapp.com)
2. Test registration and login
3. Verify email functionality
4. Check API endpoints

## Support

- Full deployment guide: HOSTINGER-DEPLOYMENT-GUIDE.md
- Hostinger support: Available through control panel
- Application issues: Check logs and error messages
