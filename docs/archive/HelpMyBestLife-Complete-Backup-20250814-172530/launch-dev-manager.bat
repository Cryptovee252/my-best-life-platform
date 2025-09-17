@echo off
chcp 65001 >nul
title HelpMyBestLife Development Platform Manager

echo 🚀 Launching HelpMyBestLife Development Platform Manager...
echo.

REM Check if Python is installed
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Python is not installed. Please install Python 3.7+ and try again.
    echo Download from: https://www.python.org/downloads/
    pause
    exit /b 1
)

REM Check if virtual environment exists, create if not
if not exist "dev-env" (
    echo 📦 Creating virtual environment...
    python -m venv dev-env
)

REM Activate virtual environment
echo 🔧 Activating virtual environment...
call dev-env\Scripts\activate.bat

REM Check if required packages are installed
echo 📦 Checking dependencies...
python -c "import psutil" >nul 2>&1
if %errorlevel% neq 0 (
    echo 📥 Installing required packages...
    pip install -r requirements.txt
    if %errorlevel% neq 0 (
        echo ❌ Failed to install packages. Please check your internet connection.
        pause
        exit /b 1
    )
)

REM Launch the application
echo 🎯 Starting Development Platform Manager...
python dev-setup.py

echo 👋 Development Platform Manager closed.
pause
