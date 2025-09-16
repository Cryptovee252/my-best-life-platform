#!/bin/bash
# HelpMyBestLife Development Environment Restore Script
# Generated on 2025-08-14 17:25:30

echo "🔄 Restoring HelpMyBestLife Development Environment..."
echo "=================================================="

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "📁 Working directory: $SCRIPT_DIR"

# Check if Python is installed
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 is not installed. Please install Python 3.7+ and try again."
    echo "You can install Python using Homebrew: brew install python"
    echo "Or download from: https://www.python.org/downloads/"
    echo ""
    echo "Press any key to continue..."
    read -n 1
    exit 1
fi

echo "✅ Python 3 found: $(python3 --version)"

# Create virtual environment
echo "📦 Creating virtual environment..."
python3 -m venv dev-env
echo "✅ Virtual environment created"

# Activate virtual environment
echo "🔧 Activating virtual environment..."
source dev-env/bin/activate

# Install dependencies
echo "📥 Installing required packages..."
pip install -r requirements.txt
echo "✅ Dependencies installed"

# Install Node.js dependencies for backend
if [ -d "backend" ]; then
    echo "📦 Installing backend dependencies..."
    cd backend
    if [ -f "package.json" ]; then
        npm install
        echo "✅ Backend dependencies installed"
    fi
    cd ..
fi

# Install Node.js dependencies for frontend
if [ -d "HelpMyBestLife" ]; then
    echo "📦 Installing frontend dependencies..."
    cd HelpMyBestLife
    if [ -f "package.json" ]; then
        npm install
        echo "✅ Frontend dependencies installed"
    fi
    cd ..
fi

echo ""
echo "🎉 Restoration complete! Your development environment is ready."
echo ""
echo "To start the development console, run:"
echo "  python3 dev-setup.py"
echo ""
echo "Or use one of the launcher scripts:"
echo "  - launch-dev-manager.sh (Linux/macOS)"
echo "  - launch-dev-manager.bat (Windows)"
echo "  - macos-launcher.command (macOS)"
echo ""
echo "Press any key to continue..."
read -n 1
