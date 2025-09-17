# Deploy HelpMyBestLife to Hostinger

## Prerequisites
1. A Hostinger hosting account
2. Access to Hostinger's File Manager or FTP
3. Your domain name configured

## Step 1: Prepare the Build

The web build has been created in the `dist` folder. This contains all the necessary files for your website.

## Step 2: Upload to Hostinger

### Option A: Using Hostinger File Manager

1. **Login to Hostinger Control Panel**
   - Go to your Hostinger dashboard
   - Navigate to "File Manager"

2. **Navigate to Public HTML**
   - Go to `public_html` folder (or your domain's root directory)

3. **Upload Files**
   - Upload ALL contents from the `dist` folder to `public_html`
   - Make sure to maintain the folder structure
   - Include all subdirectories (`_expo`, `assets`, `group`, `(tabs)`, etc.)

### Option B: Using FTP

1. **Get FTP Credentials**
   - From Hostinger control panel, go to "FTP Accounts"
   - Note your FTP hostname, username, and password

2. **Connect via FTP Client**
   - Use FileZilla, WinSCP, or any FTP client
   - Connect to your Hostinger FTP server

3. **Upload Files**
   - Navigate to `public_html` directory
   - Upload all contents from the `dist` folder

## Step 3: Configure Domain

1. **Set Default Page**
   - Ensure `index.html` is set as the default page
   - This should be automatic, but verify in Hostinger settings

2. **Enable HTTPS** (Recommended)
   - In Hostinger control panel, enable SSL certificate
   - This ensures secure connections

## Step 4: Test Your Website

1. **Visit Your Domain**
   - Go to `https://yourdomain.com`
   - The app should load and be fully functional

2. **Test Features**
   - Try completing tasks in different categories
   - Check if CP calculations work
   - Verify group functionality
   - Test notifications

## Step 5: Backend Setup (Optional)

If you want to use the backend features:

1. **Set up Node.js Hosting**
   - Hostinger offers Node.js hosting
   - Upload the `backend` folder to your Node.js hosting
   - Configure environment variables

2. **Update Frontend API URLs**
   - Modify the API endpoints in the frontend to point to your backend
   - Update the base URL in your app configuration

## Troubleshooting

### Common Issues

1. **404 Errors**
   - Ensure all files are uploaded to the correct directory
   - Check that `index.html` is in the root of `public_html`

2. **JavaScript Errors**
   - Verify all `_expo` files are uploaded
   - Check browser console for specific errors

3. **Styling Issues**
   - Clear browser cache
   - Ensure CSS files are properly uploaded

4. **Routing Issues**
   - Hostinger may need URL rewriting for SPA routing
   - Create a `.htaccess` file in `public_html`:

```apache
RewriteEngine On
RewriteBase /
RewriteRule ^index\.html$ - [L]
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule . /index.html [L]
```

## File Structure After Upload

Your `public_html` should look like this:
```
public_html/
├── index.html
├── mind.html
├── body.html
├── soul.html
├── profile.html
├── settings.html
├── stories.html
├── notifications.html
├── modal.html
├── two.html
├── +not-found.html
├── _sitemap.html
├── favicon.ico
├── metadata.json
├── _expo/
│   └── static/
│       └── js/
│           └── web/
│               └── entry-*.js
├── assets/
├── group/
└── (tabs)/
```

## Performance Optimization

1. **Enable Gzip Compression**
   - In Hostinger control panel, enable Gzip compression
   - This will reduce file sizes and improve loading speed

2. **Set Cache Headers**
   - Configure caching for static assets
   - This improves performance for returning visitors

3. **CDN Integration** (Optional)
   - Consider using a CDN for better global performance
   - Hostinger offers CDN services

## Security Considerations

1. **HTTPS Only**
   - Ensure your site uses HTTPS
   - Redirect HTTP to HTTPS

2. **File Permissions**
   - Set appropriate file permissions (644 for files, 755 for directories)
   - Don't make files executable unless necessary

3. **Regular Updates**
   - Keep your app updated
   - Monitor for security vulnerabilities

## Support

If you encounter issues:
1. Check Hostinger's knowledge base
2. Contact Hostinger support
3. Review browser console for errors
4. Verify all files are uploaded correctly

## Maintenance

1. **Regular Backups**
   - Keep backups of your uploaded files
   - Use Hostinger's backup features

2. **Monitor Performance**
   - Use Hostinger's performance monitoring
   - Check Google PageSpeed Insights

3. **Update Content**
   - Regularly update your app
   - Monitor user feedback and analytics
