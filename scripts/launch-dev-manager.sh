#!/bin/bash

# HelpMyBestLife Development Platform Manager Launcher
# This script launches the development platform manager

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "🚀 Launching HelpMyBestLife Development Platform Manager..."
echo "📁 Working directory: $(pwd)"

# Check if Python is installed
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 is not installed. Please install Python 3.7+ and try again."
    echo "Press any key to continue..."
    read -n 1
    exit 1
fi

# Check if virtual environment exists, create if not
if [ ! -d "dev-env" ]; then
    echo "📦 Creating virtual environment..."
    python3 -m venv dev-env
fi

# Activate virtual environment
echo "🔧 Activating virtual environment..."
source dev-env/bin/activate

# Check if required packages are installed
echo "📦 Checking dependencies..."
python -c "import psutil" 2>/dev/null
if [ $? -ne 0 ]; then
    echo "📥 Installing required packages..."
    pip install -r requirements.txt
fi

# Launch the application
echo "🎯 Starting Development Platform Manager..."
python dev-setup.py

echo "👋 Development Platform Manager closed."
echo "Press any key to continue..."
read -n 1
