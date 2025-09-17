# My Best Life - Complete VPS Setup Guide

## 🎯 **What We're Building**

Instead of using Hostinger's shared hosting (which doesn't support Node.js), we'll use your VPS to:
- **Host your Node.js backend** (registration, login, API)
- **Serve your frontend files** (HTML, CSS, JS)
- **Run PostgreSQL database** (user data, tasks, etc.)
- **Handle SSL certificates** (HTTPS security)

---

## 📋 **Prerequisites**

### **What You Need:**
1. **VPS Access**: SSH access to your VPS
2. **Domain Control**: Access to your domain's DNS settings
3. **VPS Details**: IP address, OS, and credentials

### **What I'll Provide:**
1. **Automated setup script** for your VPS
2. **GitHub Actions workflow** for automatic deployment
3. **Step-by-step instructions** for everything

---

## 🚀 **Step 1: VPS Information**

**Please provide:**
1. **VPS IP Address**: `xxx.xxx.xxx.xxx`
2. **VPS Provider**: (DigitalOcean, Linode, Vultr, etc.)
3. **Operating System**: (Ubuntu 20.04/22.04, CentOS, etc.)
4. **SSH Access**: Can you SSH into your VPS?

---

## 🌐 **Step 2: Domain Configuration**

### **Current Setup:**
```
mybestlifeapp.com → Hostinger Shared Hosting (No Node.js)
```

### **New Setup:**
```
mybestlifeapp.com → Your VPS (Full Node.js Support)
```

### **DNS Changes Needed:**
1. **Go to your domain registrar** (GoDaddy, Namecheap, etc.)
2. **Find DNS management**
3. **Update these records:**

```
Type: A
Name: @
Value: YOUR_VPS_IP_ADDRESS
TTL: 300

Type: A  
Name: www
Value: YOUR_VPS_IP_ADDRESS
TTL: 300
```

**DNS propagation takes 5-30 minutes.**

---

## 🖥️ **Step 3: VPS Setup (Automated)**

### **Option A: Automated Setup (Recommended)**
```bash
# SSH into your VPS
ssh root@YOUR_VPS_IP

# Download and run setup script
wget https://raw.githubusercontent.com/Cryptovee252/my-best-life-platform/main/vps-setup.sh
chmod +x vps-setup.sh
sudo ./vps-setup.sh
```

### **Option B: Manual Setup**
If you prefer manual setup, the script installs:
- **Node.js 18.x**
- **PM2** (process manager)
- **Nginx** (web server)
- **PostgreSQL** (database)
- **Certbot** (SSL certificates)
- **Firewall** (security)

---

## 📦 **Step 4: Deploy Your Application**

### **Automated Deployment (GitHub Actions)**
1. **Add VPS secrets to GitHub:**
   ```
   VPS_HOST: your-vps-ip-address
   VPS_USERNAME: root (or your username)
   VPS_SSH_KEY: your-private-ssh-key
   ```

2. **Push to GitHub** - automatic deployment happens!

### **Manual Deployment**
```bash
# Clone repository to VPS
cd /var/www/mybestlife
git clone https://github.com/Cryptovee252/my-best-life-platform.git .

# Install dependencies
cd backend
npm install --production

# Start application
pm2 start app-production.js --name mybestlife
pm2 save
pm2 startup
```

---

## 🔧 **Step 5: Configure Environment**

### **Create Environment File**
```bash
cd /var/www/mybestlife/backend
cp .env.template .env
nano .env
```

### **Environment Variables**
```env
NODE_ENV=production
PORT=3000
DATABASE_URL=postgresql://mybestlife:password@localhost:5432/mybestlife
JWT_SECRET=your-super-secret-jwt-key-here
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASS=your-app-password
FRONTEND_URL=https://mybestlifeapp.com
```

---

## 🗄️ **Step 6: Database Setup**

### **Create Database**
```bash
# Switch to postgres user
sudo -u postgres psql

# Create database and user
CREATE DATABASE mybestlife;
CREATE USER mybestlife WITH PASSWORD 'secure_password_here';
GRANT ALL PRIVILEGES ON DATABASE mybestlife TO mybestlife;
\q
```

### **Update Environment**
Update `DATABASE_URL` in your `.env` file with the actual password.

---

## 🔒 **Step 7: SSL Certificate**

### **Get SSL Certificate**
```bash
# Get SSL certificate
certbot --nginx -d mybestlifeapp.com -d www.mybestlifeapp.com
```

This automatically:
- Gets SSL certificate from Let's Encrypt
- Configures Nginx for HTTPS
- Sets up automatic renewal

---

## 🧪 **Step 8: Test Your Setup**

### **Test Backend API**
```bash
curl https://mybestlifeapp.com/api/health
```
Should return JSON response.

### **Test Registration**
1. Go to `https://mybestlifeapp.com/register.html`
2. Try to register a new user
3. Should work without errors!

---

## 📊 **Step 9: Monitoring & Management**

### **Check Application Status**
```bash
pm2 status
pm2 logs mybestlife
pm2 restart mybestlife
```

### **Check Nginx Status**
```bash
systemctl status nginx
nginx -t
systemctl reload nginx
```

### **Check Database**
```bash
sudo -u postgres psql -d mybestlife
```

---

## 🔄 **Step 10: Automatic Deployment**

### **Every time you push to GitHub:**
1. **GitHub Actions** automatically deploys to your VPS
2. **PM2** restarts your application
3. **Your website updates** automatically

### **Manual Deployment**
```bash
cd /var/www/mybestlife
./deploy-to-vps.sh
```

---

## 🆘 **Troubleshooting**

### **Common Issues:**

#### **1. Domain Not Working**
- Check DNS propagation: `nslookup mybestlifeapp.com`
- Verify A records point to VPS IP
- Wait for DNS propagation (up to 30 minutes)

#### **2. Application Not Starting**
```bash
pm2 logs mybestlife
pm2 restart mybestlife
```

#### **3. Database Connection Issues**
- Check PostgreSQL is running: `systemctl status postgresql`
- Verify DATABASE_URL in `.env`
- Check database exists: `sudo -u postgres psql -l`

#### **4. SSL Certificate Issues**
```bash
certbot certificates
certbot renew --dry-run
```

#### **5. Nginx Issues**
```bash
nginx -t
systemctl status nginx
tail -f /var/log/nginx/error.log
```

---

## 📁 **File Structure on VPS**

```
/var/www/mybestlife/
├── index.html              # Frontend files
├── register.html
├── login.html
├── backend/                # Backend application
│   ├── app-production.js   # Main application
│   ├── .env                # Environment variables
│   ├── package.json        # Dependencies
│   └── routes/             # API routes
├── deploy-to-vps.sh        # Deployment script
└── VPS-SETUP-INSTRUCTIONS.md
```

---

## 🎯 **Expected Result**

After completing this setup:
- ✅ **Domain**: `https://mybestlifeapp.com` works
- ✅ **Frontend**: Registration/login pages load
- ✅ **Backend**: API endpoints respond
- ✅ **Database**: User data is stored
- ✅ **SSL**: HTTPS security enabled
- ✅ **Deployment**: Automatic updates from GitHub

---

## 🚀 **Next Steps**

1. **Provide your VPS details** (IP, OS, access)
2. **Run the automated setup script**
3. **Update your domain DNS**
4. **Deploy your application**
5. **Test registration functionality**

---

## 💡 **Benefits of VPS vs Shared Hosting**

### **VPS Advantages:**
- ✅ **Full Node.js support**
- ✅ **Root access** and control
- ✅ **Better performance**
- ✅ **Custom configuration**
- ✅ **SSL certificates**
- ✅ **Database control**
- ✅ **Automatic deployment**

### **Shared Hosting Limitations:**
- ❌ **No Node.js support**
- ❌ **Limited control**
- ❌ **Performance restrictions**
- ❌ **No custom configuration**

---

**Ready to get started? Just provide your VPS details and I'll guide you through the entire setup process!** 🚀
