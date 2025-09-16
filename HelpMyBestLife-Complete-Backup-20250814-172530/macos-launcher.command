#!/bin/bash

# HelpMyBestLife Development Platform Manager Launcher for macOS
# This .command file will open in Terminal when double-clicked

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "🚀 HelpMyBestLife Development Platform Manager"
echo "=============================================="
echo "📁 Working directory: $(pwd)"
echo ""

# Check if Python is installed
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 is not installed. Please install Python 3.7+ and try again."
    echo ""
    echo "You can install Python using Homebrew:"
    echo "  brew install python"
    echo ""
    echo "Or download from: https://www.python.org/downloads/"
    echo ""
    echo "Press any key to continue..."
    read -n 1
    exit 1
fi

echo "✅ Python 3 found: $(python3 --version)"

# Check if virtual environment exists, create if not
if [ ! -d "dev-env" ]; then
    echo "📦 Creating virtual environment..."
    python3 -m venv dev-env
    echo "✅ Virtual environment created"
else
    echo "✅ Virtual environment found"
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
    echo "✅ Dependencies installed"
else
    echo "✅ Dependencies already installed"
fi

echo ""
echo "🎯 Starting Development Platform Manager..."
echo ""

# Launch the application
python dev-setup.py

echo ""
echo "👋 Development Platform Manager closed."
echo "Press any key to close this window..."
read -n 1
