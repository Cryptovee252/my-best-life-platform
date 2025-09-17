# 🔍 FIND YOUR LIVE PROJECT DIRECTORY
## Locate the actual running project on your VPS

**You're right - that's just a backup! Let's find your live project.**

---

## 🎯 **SEARCH COMMANDS**

**Run these commands on your VPS to find the live project:**

### **1. Search for live project directories:**
```bash
# Look for common project locations
ls -la /var/www/
ls -la /var/www/html/
ls -la /home/

# Search for package.json files (Node.js projects)
find /var/www -name "package.json" -not -path "*/node_modules/*" -not -path "*/backup*" 2>/dev/null
find /home -name "package.json" -not -path "*/node_modules/*" -not -path "*/backup*" 2>/dev/null

# Search for app.js files
find /var/www -name "app.js" -not -path "*/node_modules/*" -not -path "*/backup*" 2>/dev/null
find /home -name "app.js" -not -path "*/node_modules/*" -not -path "*/backup*" 2>/dev/null

# Search for server.js files
find /var/www -name "server.js" -not -path "*/node_modules/*" -not -path "*/backup*" 2>/dev/null
find /home -name "server.js" -not -path "*/node_modules/*" -not -path "*/backup*" 2>/dev/null
```

### **2. Check PM2 processes to see where they're running from:**
```bash
# Check PM2 status and see file paths
pm2 list
pm2 show mybestlife-secure 2>/dev/null || echo "No mybestlife-secure process"
pm2 show mybestlife 2>/dev/null || echo "No mybestlife process"

# Check all PM2 processes
pm2 list --format table
```

### **3. Check web server configuration:**
```bash
# Check Nginx configuration
cat /etc/nginx/sites-enabled/default 2>/dev/null || echo "No default site"
ls -la /etc/nginx/sites-enabled/

# Check Apache configuration
cat /etc/apache2/sites-enabled/000-default.conf 2>/dev/null || echo "No default site"
ls -la /etc/apache2/sites-enabled/
```

### **4. Check running processes:**
```bash
# Check what Node.js processes are running
ps aux | grep node
ps aux | grep "mybestlife"

# Check what's listening on port 3000
netstat -tlnp | grep :3000
lsof -i :3000
```

### **5. Check common project locations:**
```bash
# Check these common locations
ls -la /var/www/html/
ls -la /var/www/mybestlife/
ls -la /home/root/
ls -la /home/ubuntu/
ls -la /opt/

# Look for any directory with "mybestlife" in the name
find /var/www -type d -name "*mybestlife*" 2>/dev/null
find /home -type d -name "*mybestlife*" 2>/dev/null
find /opt -type d -name "*mybestlife*" 2>/dev/null
```

---

## 🎯 **LIKELY LOCATIONS**

**Your live project is probably in one of these locations:**

### **Most Common:**
- `/var/www/html/` - Default web root
- `/var/www/mybestlife/` - Dedicated project directory
- `/home/root/mybestlife/` - User home directory
- `/opt/mybestlife/` - Application directory

### **Check these specific paths:**
```bash
# Check each likely location
ls -la /var/www/html/
ls -la /var/www/mybestlife/
ls -la /home/root/mybestlife/
ls -la /opt/mybestlife/

# Look for backend directories
ls -la /var/www/html/backend/
ls -la /var/www/mybestlife/backend/
ls -la /home/root/mybestlife/backend/
ls -la /opt/mybestlife/backend/
```

---

## 🔍 **IDENTIFY THE LIVE PROJECT**

**Once you find potential directories, check which one is live:**

```bash
# For each potential directory, check:
cd /path/to/potential/project

# 1. Check if it has the right files
ls -la
cat package.json | grep "name"

# 2. Check if it has a .env file
ls -la .env

# 3. Check if it has Prisma schema
ls -la prisma/schema.prisma

# 4. Check if it has the right application files
ls -la app.js server.js index.js
```

---

## 🚀 **ONCE YOU FIND THE LIVE PROJECT**

**When you locate the correct directory, run these commands:**

```bash
# Navigate to the live project
cd /path/to/live/project/backend

# Create backup
BACKUP_DIR="/root/backup-$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
cp -r . "$BACKUP_DIR/"

# Generate secure secrets
JWT_SECRET=$(openssl rand -hex 64)
JWT_REFRESH_SECRET=$(openssl rand -hex 64)
SESSION_SECRET=$(openssl rand -hex 32)

# Create secure .env file
cat > .env << EOF
DATABASE_URL="postgresql://mybestlife:your_existing_password@localhost:5432/mybestlife"
JWT_SECRET="${JWT_SECRET}"
JWT_REFRESH_SECRET="${JWT_REFRESH_SECRET}"
SESSION_SECRET="${SESSION_SECRET}"
NODE_ENV="production"
PORT=3000
FRONTEND_URL="https://mybestlifeapp.com"
EOF

# Set permissions and restart
chmod 600 .env
pm2 restart mybestlife-secure
```

---

## 🎯 **QUICK SEARCH COMMAND**

**Run this single command to find your live project:**

```bash
# Comprehensive search for live project
find /var/www /home /opt -name "package.json" -not -path "*/node_modules/*" -not -path "*/backup*" -exec dirname {} \; 2>/dev/null | head -10
```

---

**🔍 RUN THESE COMMANDS TO FIND YOUR LIVE PROJECT!**

The key is finding the directory that contains your actual running application, not the backup. Once we locate it, we can secure it while preserving all your data.

Let me know what you find when you run these search commands!
