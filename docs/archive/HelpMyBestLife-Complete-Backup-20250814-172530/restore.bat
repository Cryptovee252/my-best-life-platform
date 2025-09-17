@echo off
chcp 65001 >nul
title HelpMyBestLife Development Environment Restore

echo 🔄 Restoring HelpMyBestLife Development Environment...
echo ==================================================
echo.

REM Get the directory where this script is located
cd /d "%~dp0"

echo 📁 Working directory: %CD%
echo.

REM Check if Python is installed
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Python is not installed. Please install Python 3.7+ and try again.
    echo Download from: https://www.python.org/downloads/
    pause
    exit /b 1
)

echo ✅ Python found: 
python --version

REM Create virtual environment
echo.
echo 📦 Creating virtual environment...
python -m venv dev-env
if %errorlevel% neq 0 (
    echo ❌ Failed to create virtual environment
    pause
    exit /b 1
)
echo ✅ Virtual environment created

REM Activate virtual environment
echo 🔧 Activating virtual environment...
call dev-env\Scripts\activate.bat

REM Install dependencies
echo 📥 Installing required packages...
pip install -r requirements.txt
if %errorlevel% neq 0 (
    echo ❌ Failed to install packages
    pause
    exit /b 1
)
echo ✅ Dependencies installed

REM Install Node.js dependencies for backend
if exist "backend" (
    echo 📦 Installing backend dependencies...
    cd backend
    if exist "package.json" (
        npm install
        if %errorlevel% neq 0 (
            echo ⚠️  Warning: Failed to install backend dependencies
        ) else (
            echo ✅ Backend dependencies installed
        )
    )
    cd ..
)

REM Install Node.js dependencies for frontend
if exist "HelpMyBestLife" (
    echo 📦 Installing frontend dependencies...
    cd HelpMyBestLife
    if exist "package.json" (
        npm install
        if %errorlevel% neq 0 (
            echo ⚠️  Warning: Failed to install frontend dependencies
        ) else (
            echo ✅ Frontend dependencies installed
        )
    )
    cd ..
)

echo.
echo 🎉 Restoration complete! Your development environment is ready.
echo.
echo To start the development console, run:
echo   python dev-setup.py
echo.
echo Or use one of the launcher scripts:
echo   - launch-dev-manager.bat (Windows)
echo   - launch-dev-manager.sh (Linux/macOS)
echo   - macos-launcher.command (macOS)
echo.
pause
