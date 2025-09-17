# 🚀 Quick Start Guide - HelpMyBestLife Development Platform Manager

## ⚡ Get Started in 3 Steps

### 1. **Launch the Manager** (Choose your OS)

**macOS (Recommended):**
```bash
# Double-click this file in Finder:
macos-launcher.command
```

**macOS (Alternative):**
```bash
# Run in Terminal:
./macos-launcher.command
```

**macOS (Python launcher):**
```bash
# Double-click this file in Finder:
launch-dev-manager.py
```

**Linux:**
```bash
./launch-dev-manager.sh
```

**Windows:**
```cmd
launch-dev-manager.bat
```

**Manual Launch:**
```bash
# Activate virtual environment
source dev-env/bin/activate  # macOS/Linux
# OR
dev-env\Scripts\activate.bat  # Windows

# Run the GUI
python dev-setup.py
```

### 2. **What You'll See**
- **Dashboard Tab**: Overview of all services (Backend, Frontend, Database)
- **Services Tab**: Individual control for each service
- **Database Tab**: Database operations (init, reset, migrations)
- **Logs Tab**: Real-time logs from all services
- **Settings Tab**: Configuration and advanced options

### 3. **Quick Actions**
- **🚀 Start All Services**: One-click to start everything
- **⏹️ Stop All Services**: One-click to stop everything
- **🔄 Restart All**: Restart all services
- **🧹 Clear Cache**: Clear npm, Expo, and Docker caches
- **📦 Install Dependencies**: Install all required packages

## 🎯 Key Features

### **Service Management**
- Start/Stop/Restart Backend (Node.js/Express)
- Start/Stop/Restart Frontend (React Native/Expo)
- Start/Stop/Restart Database (PostgreSQL via Docker)

### **Database Operations**
- Initialize database with Prisma
- Run migrations
- Reset database (with confirmation)
- View database status

### **Development Tools**
- Clear all caches
- Install dependencies
- Setup environment (.env file creation)
- Generate development reports

## 🔧 System Requirements

- **Python 3.7+** (included with most systems)
- **Node.js & npm** (for backend/frontend)
- **Docker & Docker Compose** (for database)
- **Git** (for version control)

## 🚨 Troubleshooting

### **If the GUI won't start:**
1. Make sure Python 3.7+ is installed
2. **On macOS**: Double-click `macos-launcher.command` (this will open Terminal and run properly)
3. **On Linux/Windows**: Run `./launch-dev-manager.sh` or `launch-dev-manager.bat`
4. Check that all dependencies are installed

### **If services won't start:**
1. Check that Docker is running
2. Verify Node.js and npm are installed
3. Check the logs tab for error messages

### **If database operations fail:**
1. Ensure Docker is running
2. Check that PostgreSQL container is healthy
3. Verify backend .env file exists

## 📁 File Structure

```
New/
├── dev-setup.py              # Main GUI application
├── macos-launcher.command    # macOS launcher (double-click this!)
├── launch-dev-manager.py     # Python launcher (alternative)
├── launch-dev-manager.sh     # Linux launcher
├── launch-dev-manager.bat    # Windows launcher
├── requirements.txt          # Python dependencies
├── dev-env/                 # Python virtual environment
├── backend/                 # Your Node.js backend
├── HelpMyBestLife/          # Your React Native frontend
└── docker-compose.yml       # Database configuration
```

## 🍎 macOS-Specific Notes

**The `.command` file is the recommended way to launch on macOS:**
- Double-click `macos-launcher.command` in Finder
- It will automatically open Terminal and run the manager
- No need to manually open Terminal or run commands
- Automatically handles virtual environment creation and dependency installation

**If you prefer Python:**
- Double-click `launch-dev-manager.py` in Finder
- This will run the Python launcher directly

## 🎉 You're Ready!

The Development Platform Manager will handle all the complexity of managing your development environment. Just launch it and use the intuitive interface to control your services!

---

**Need Help?** Check the main README.md for detailed documentation and troubleshooting.
