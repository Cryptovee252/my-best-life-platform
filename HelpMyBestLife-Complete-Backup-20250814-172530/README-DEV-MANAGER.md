# 🚀 HelpMyBestLife Development Platform Manager

A comprehensive, one-click GUI application for managing your HelpMyBestLife development environment. This tool provides an intuitive interface to start, stop, restart, and manage all aspects of your development platform.

## ✨ Features

### 🎯 **One-Click Operations**
- **Start All Services** - Launch backend, frontend, and database with one click
- **Stop All Services** - Gracefully shut down all running services
- **Restart All Services** - Quick restart for all components
- **Clear Cache** - Clean npm, Expo, and Docker caches

### 🔧 **Service Management**
- **Backend Server** - Start/stop/restart Node.js backend
- **Frontend App** - Manage React Native/Expo development server
- **Database** - Control PostgreSQL database via Docker
- **Real-time Status** - Live monitoring of all services

### 🗄️ **Database Operations**
- **Initialize Database** - Set up Prisma schema and database
- **Run Migrations** - Execute database migrations
- **Reset Database** - Clean slate for development
- **Database Info** - View container status and schema details

### 📋 **Development Tools**
- **Install Dependencies** - Auto-install npm packages for both projects
- **Setup Environment** - Create .env files and configure development setup
- **Live Logs** - Real-time monitoring of service logs
- **Project Explorer** - Quick access to project folders

### ⚙️ **Configuration & Settings**
- **Port Management** - Configure backend port settings
- **Environment Selection** - Switch between dev/staging/production
- **Auto-start Options** - Configure services to start automatically
- **Settings Persistence** - Save and load your preferences

## 🚀 Quick Start

### Prerequisites
- **Python 3.7+** (with tkinter support)
- **Node.js 16+** and npm
- **Docker** and Docker Compose
- **Git** (for version control)

### Installation

1. **Clone or download** the development manager files to your project root
2. **Install Python dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

### Launch Options

#### 🐧 **Linux/macOS:**
```bash
chmod +x launch-dev-manager.sh
./launch-dev-manager.sh
```

#### 🪟 **Windows:**
```cmd
launch-dev-manager.bat
```

#### 🐍 **Direct Python:**
```bash
python3 dev-setup.py
```

## 📱 Interface Overview

### 🏠 **Dashboard Tab**
- **Platform Status** - Real-time service status indicators
- **Quick Actions** - One-click buttons for common operations
- **System Information** - Platform details and project paths

### ⚙️ **Services Tab**
- **Backend Controls** - Start/stop/restart backend server
- **Frontend Controls** - Manage Expo development server
- **Docker Controls** - Control database and container services

### 🗄️ **Database Tab**
- **Database Operations** - Initialize, reset, and migrate database
- **Database Information** - View container status and schema details

### 📋 **Logs Tab**
- **Live Logs** - Real-time log monitoring
- **Service Logs** - Individual service log viewing
- **Log Management** - Clear and manage log displays

### ⚙️ **Settings Tab**
- **Configuration** - Port, environment, and auto-start settings
- **Advanced Options** - Project folder access and report generation

## 🔧 Configuration

### Environment Variables
The manager automatically creates a `.env` file in your backend directory:

```env
# Database Configuration
DATABASE_URL="postgresql://mybestlife:devpassword@localhost:5432/mybestlife_db"

# JWT Secret
JWT_SECRET="your-secret-key-here"

# Server Configuration
PORT=3000
NODE_ENV=development

# CORS Configuration
CORS_ORIGIN="http://localhost:8081"
```

### Port Configuration
- **Backend Port**: Default 3000 (configurable)
- **Frontend Port**: Default 8081 (Expo standard)
- **Database Port**: Default 5432 (PostgreSQL)

## 🛠️ Troubleshooting

### Common Issues

#### ❌ **Backend Won't Start**
- Check if port 3000 is available
- Verify Node.js and npm are installed
- Check backend dependencies are installed

#### ❌ **Frontend Won't Start**
- Ensure Expo CLI is installed globally
- Check if port 8081 is available
- Verify frontend dependencies are installed

#### ❌ **Database Connection Failed**
- Ensure Docker is running
- Check if PostgreSQL container is healthy
- Verify database credentials in .env file

#### ❌ **Permission Denied Errors**
- Run launcher with appropriate permissions
- Check file ownership and permissions
- Ensure Python has access to project directories

### Debug Mode
Enable detailed logging by checking the "Auto-refresh logs" option in the Logs tab.

## 📊 System Requirements

### Minimum Requirements
- **OS**: Windows 10, macOS 10.14+, Ubuntu 18.04+
- **RAM**: 4GB available
- **Storage**: 2GB free space
- **Python**: 3.7+
- **Node.js**: 16+

### Recommended Requirements
- **OS**: Windows 11, macOS 12+, Ubuntu 20.04+
- **RAM**: 8GB available
- **Storage**: 5GB free space
- **Python**: 3.9+
- **Node.js**: 18+

## 🔄 Updates and Maintenance

### Keeping Updated
- The manager automatically checks for configuration changes
- Settings are persisted between sessions
- Logs are maintained for debugging purposes

### Backup and Recovery
- Configuration is saved to `dev-config.json`
- Reports can be generated for environment documentation
- All operations are logged for audit purposes

## 🤝 Contributing

### Development
To contribute to the development manager:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

### Feature Requests
Suggest new features by:
- Opening an issue on GitHub
- Describing the desired functionality
- Providing use case examples

## 📄 License

This development platform manager is part of the HelpMyBestLife project and follows the same licensing terms.

## 🆘 Support

### Getting Help
- Check the troubleshooting section above
- Review the logs for error details
- Ensure all prerequisites are met
- Verify service configurations

### Reporting Issues
When reporting issues, please include:
- Operating system and version
- Python and Node.js versions
- Error messages from logs
- Steps to reproduce the issue

---

**Happy Developing! 🎉**

The HelpMyBestLife Development Platform Manager is designed to make your development workflow smooth and efficient. With one-click operations and comprehensive monitoring, you can focus on building great features instead of managing infrastructure.
