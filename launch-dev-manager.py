#!/usr/bin/env python3
"""
HelpMyBestLife Development Platform Manager Launcher
This script launches the development platform manager and can be double-clicked on macOS
"""

import os
import sys
import subprocess
import tkinter as tk
from tkinter import messagebox
from pathlib import Path

def main():
    """Main launcher function"""
    try:
        # Get the directory where this script is located
        script_dir = Path(__file__).parent
        os.chdir(script_dir)
        
        print(f"🚀 Launching HelpMyBestLife Development Platform Manager...")
        print(f"📁 Working directory: {os.getcwd()}")
        
        # Check if Python is available
        try:
            subprocess.run([sys.executable, "--version"], check=True, capture_output=True)
        except subprocess.CalledProcessError:
            messagebox.showerror("Error", "Python is not available. Please install Python 3.7+ and try again.")
            return
        
        # Check if virtual environment exists, create if not
        venv_path = script_dir / "dev-env"
        if not venv_path.exists():
            print("📦 Creating virtual environment...")
            subprocess.run([sys.executable, "-m", "venv", "dev-env"], check=True)
        
        # Determine the Python executable in the virtual environment
        if sys.platform == "darwin":  # macOS
            venv_python = venv_path / "bin" / "python"
        else:  # Windows/Linux
            venv_python = venv_path / "Scripts" / "python.exe" if sys.platform == "win32" else venv_path / "bin" / "python"
        
        # Check if required packages are installed
        print("📦 Checking dependencies...")
        try:
            subprocess.run([str(venv_python), "-c", "import psutil"], check=True, capture_output=True)
        except subprocess.CalledProcessError:
            print("📥 Installing required packages...")
            subprocess.run([str(venv_python), "-m", "pip", "install", "-r", "requirements.txt"], check=True)
        
        # Launch the application
        print("🎯 Starting Development Platform Manager...")
        subprocess.run([str(venv_python), "dev-setup.py"], check=True)
        
        print("👋 Development Platform Manager closed.")
        
    except subprocess.CalledProcessError as e:
        error_msg = f"Failed to launch Development Platform Manager: {str(e)}"
        print(f"❌ {error_msg}")
        messagebox.showerror("Error", error_msg)
    except Exception as e:
        error_msg = f"Unexpected error: {str(e)}"
        print(f"❌ {error_msg}")
        messagebox.showerror("Error", error_msg)
    
    # Keep the window open if there was an error
    if 'error_msg' in locals():
        input("Press Enter to continue...")

if __name__ == "__main__":
    main()
