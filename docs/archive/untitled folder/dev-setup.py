#!/usr/bin/env python3
"""
HelpMyBestLife Development Platform Manager
A comprehensive GUI application for managing development environment setup
"""

import tkinter as tk
from tkinter import ttk, messagebox, scrolledtext, filedialog
import subprocess
import threading
import os
import sys
import json
import time
import psutil
import webbrowser
from pathlib import Path
import platform

class DevPlatformManager:
    def __init__(self, root):
        self.root = root
        self.root.title("HelpMyBestLife Dev Platform Manager")
        self.root.geometry("1200x800")
        
        # Ultra-modern neon color palette
        self.colors = {
            'bg_primary': '#0a0a0f',      # Deep space black
            'bg_secondary': '#1a1a2e',    # Dark cosmic blue
            'bg_tertiary': '#16213e',     # Deep ocean blue
            'bg_card': '#1e1e3f',         # Card background
            'bg_modal': '#2d2d5f',        # Modal background
            'accent_primary': '#00d4ff',   # Electric blue
            'accent_secondary': '#7c3aed', # Vibrant purple
            'accent_success': '#00ff88',   # Neon green
            'accent_warning': '#ff6b35',   # Hot orange
            'accent_error': '#ff0055',     # Neon red
            'accent_info': '#00ffff',      # Cyan
            'text_primary': '#ffffff',     # Pure white
            'text_secondary': '#e2e8f0',  # Light gray
            'text_muted': '#94a3b8',      # Muted gray
            'border': '#374151',          # Border color
            'border_light': '#4b5563',    # Light border
            'button_gradient_start': '#2d2d5f',  # Button gradient start
            'button_gradient_end': '#1e1e3f',    # Button gradient end
            'button_hover': '#3d3d6f'     # Button hover state
        }
        
        self.root.configure(bg=self.colors['bg_primary'])
        
        # Set icon if available
        try:
            self.root.iconbitmap('icon.ico')
        except:
            pass
        
        # Project paths
        self.project_root = Path(__file__).parent
        self.backend_path = self.project_root / "backend"
        self.frontend_path = self.project_root / "HelpMyBestLife"
        
        # Process tracking
        self.backend_process = None
        self.frontend_process = None
        self.docker_process = None
        
        # Status variables
        self.backend_running = False
        self.frontend_running = False
        self.docker_running = False
        
        self.setup_ui()
        self.check_initial_status()
        
    def create_modern_card(self, parent, title, margin_bottom):
        """Create an ultra-modern neon card container with glowing effects"""
        # Create main card frame
        card_frame = tk.Frame(parent, bg=self.colors['bg_card'], bd=2, relief='solid')
        card_frame.pack(fill=tk.X, pady=(0, margin_bottom), padx=5)
        
        # Create title bar with neon effect
        title_frame = tk.Frame(card_frame, bg=self.colors['accent_primary'], height=40)
        title_frame.pack(fill=tk.X, pady=(0, 15))
        title_frame.pack_propagate(False)
        
        # Title label with modern font
        title_label = tk.Label(title_frame, text=title,
                              bg=self.colors['accent_primary'], fg='#000000',
                              font=('Segoe UI', 13, 'bold'))
        title_label.pack(pady=10)
        
        # Content frame
        content_frame = tk.Frame(card_frame, bg=self.colors['bg_card'])
        content_frame.pack(fill=tk.BOTH, expand=True, padx=15, pady=(0, 15))
        
        return content_frame
        
    def create_scrollable_frame(self, parent):
        """Create a scrollable frame for tab content"""
        # Create main frame
        main_frame = tk.Frame(parent, bg=self.colors['bg_primary'])
        
        # Create canvas
        canvas = tk.Canvas(main_frame, bg=self.colors['bg_primary'], highlightthickness=0)
        scrollbar = ttk.Scrollbar(main_frame, orient="vertical", command=canvas.yview)
        
        # Create scrollable frame
        scrollable_frame = tk.Frame(canvas, bg=self.colors['bg_primary'])
        scrollable_frame.bind(
            "<Configure>",
            lambda e: canvas.configure(scrollregion=canvas.bbox("all"))
        )
        
        # Add frame to canvas
        canvas.create_window((0, 0), window=scrollable_frame, anchor="nw")
        canvas.configure(yscrollcommand=scrollbar.set)
        
        # Pack canvas and scrollbar
        canvas.pack(side="left", fill="both", expand=True)
        scrollbar.pack(side="right", fill="y")
        
        # Bind mouse wheel scrolling
        def _on_mousewheel(event):
            canvas.yview_scroll(int(-1*(event.delta/120)), "units")
        
        canvas.bind_all("<MouseWheel>", _on_mousewheel)
        
        # Bind keyboard scrolling
        def _on_key_press(event):
            if event.keysym == "Up":
                canvas.yview_scroll(-1, "units")
            elif event.keysym == "Down":
                canvas.yview_scroll(1, "units")
            elif event.keysym == "Page_Up":
                canvas.yview_scroll(-1, "pages")
            elif event.keysym == "Page_Down":
                canvas.yview_scroll(1, "pages")
            elif event.keysym == "Home":
                canvas.yview_moveto(0)
            elif event.keysym == "End":
                canvas.yview_moveto(1)
        
        canvas.bind("<KeyPress>", _on_key_press)
        canvas.focus_set()  # Make canvas focusable for keyboard events
        
        return main_frame, scrollable_frame
        
    def setup_ui(self):
        # Configure style
        style = ttk.Style()
        style.theme_use('clam')
        
        # Configure modern colors for ttk widgets
        style.configure('Title.TLabel', 
                       background=self.colors['bg_primary'], 
                       foreground=self.colors['text_primary'], 
                       font=('Segoe UI', 18, 'bold'))
        
        style.configure('Status.TLabel', 
                       background=self.colors['bg_secondary'], 
                       foreground=self.colors['text_primary'], 
                       font=('Segoe UI', 11))
        
        style.configure('Action.TButton', 
                       background=self.colors['accent_primary'], 
                       foreground=self.colors['text_primary'])
        
        # Configure notebook style with neon effects
        style.configure('TNotebook', 
                       background=self.colors['bg_primary'],
                       borderwidth=0)
        style.configure('TNotebook.Tab', 
                       background=self.colors['bg_secondary'],
                       foreground=self.colors['text_secondary'],
                       padding=[20, 12],
                       font=('Segoe UI', 11, 'bold'))
        style.map('TNotebook.Tab',
                 background=[('selected', self.colors['accent_primary']),
                           ('active', self.colors['accent_secondary'])],
                 foreground=[('selected', '#000000'),
                           ('active', self.colors['text_primary'])])
        
        # Main container
        main_frame = tk.Frame(self.root, bg=self.colors['bg_primary'])
        main_frame.pack(fill=tk.BOTH, expand=True, padx=25, pady=25)
        
        # Title with modern styling
        title_frame = tk.Frame(main_frame, bg=self.colors['bg_primary'])
        title_frame.pack(fill=tk.X, pady=(0, 30))
        
        title_label = tk.Label(title_frame, 
                               text="🚀 HelpMyBestLife Development Platform", 
                               bg=self.colors['bg_primary'],
                               fg=self.colors['accent_primary'],
                               font=('Segoe UI', 28, 'bold'))
        title_label.pack()
        
        subtitle_label = tk.Label(title_frame,
                                 text="Professional Development Environment Manager",
                                 bg=self.colors['bg_primary'],
                                 fg=self.colors['accent_secondary'],
                                 font=('Segoe UI', 16))
        subtitle_label.pack(pady=(5, 0))
        
        # Add a subtle separator line
        separator = tk.Frame(title_frame, height=2, bg=self.colors['accent_primary'])
        separator.pack(fill=tk.X, pady=(15, 0))
        
        # Create notebook for tabs with modern styling
        notebook = ttk.Notebook(main_frame)
        notebook.pack(fill=tk.BOTH, expand=True)
        
        # Main Dashboard Tab
        self.create_dashboard_tab(notebook)
        
        # Services Tab
        self.create_services_tab(notebook)
        
        # Database Tab
        self.create_database_tab(notebook)
        
        # Logs Tab
        self.create_logs_tab(notebook)
        
        # Settings Tab
        self.create_settings_tab(notebook)
        
    def create_dashboard_tab(self, notebook):
        main_frame, dashboard_frame = self.create_scrollable_frame(notebook)
        notebook.add(main_frame, text="📊 Dashboard")
        
        # Status Overview with modern card design
        status_frame = self.create_modern_card(dashboard_frame, "Platform Status", 20)
        
        # Backend Status
        backend_status_frame = tk.Frame(status_frame, bg=self.colors['bg_card'])
        backend_status_frame.pack(fill=tk.X, pady=12, padx=15)
        
        tk.Label(backend_status_frame, text="Backend Server:", 
                bg=self.colors['bg_card'], fg=self.colors['text_primary'], 
                font=('Segoe UI', 11, 'bold')).pack(side=tk.LEFT)
        
        self.backend_status_label = tk.Label(backend_status_frame, text="❌ Stopped", 
                                           bg=self.colors['bg_card'], fg=self.colors['accent_error'], 
                                           font=('Segoe UI', 11, 'bold'))
        self.backend_status_label.pack(side=tk.LEFT, padx=(15, 0))
        
        # Frontend Status
        frontend_status_frame = tk.Frame(status_frame, bg=self.colors['bg_card'])
        frontend_status_frame.pack(fill=tk.X, pady=8, padx=15)
        
        tk.Label(frontend_status_frame, text="Frontend App:", 
                bg=self.colors['bg_card'], fg=self.colors['text_primary'], 
                font=('Segoe UI', 11, 'bold')).pack(side=tk.LEFT)
        
        self.frontend_status_label = tk.Label(frontend_status_frame, text="❌ Stopped", 
                                            bg=self.colors['bg_card'], fg=self.colors['accent_error'], 
                                            font=('Segoe UI', 11, 'bold'))
        self.frontend_status_label.pack(side=tk.LEFT, padx=(15, 0))
        
        # Database Status
        db_status_frame = tk.Frame(status_frame, bg=self.colors['bg_card'])
        db_status_frame.pack(fill=tk.X, pady=8, padx=15)
        
        tk.Label(db_status_frame, text="Database:", 
                bg=self.colors['bg_card'], fg=self.colors['text_primary'], 
                font=('Segoe UI', 11, 'bold')).pack(side=tk.LEFT)
        
        self.db_status_label = tk.Label(db_status_frame, text="❌ Stopped", 
                                      bg=self.colors['bg_card'], fg=self.colors['accent_error'], 
                                      font=('Segoe UI', 11, 'bold'))
        self.db_status_label.pack(side=tk.LEFT, padx=(15, 0))
        
        # Quick Actions with modern button grid
        actions_frame = self.create_modern_card(dashboard_frame, "Quick Actions", 25)
        
        # Action buttons in a modern grid layout
        buttons_frame = tk.Frame(actions_frame, bg=self.colors['bg_card'])
        buttons_frame.pack(pady=25, padx=20)
        
        # Row 1 - Service Control
        row1 = tk.Frame(buttons_frame, bg=self.colors['bg_card'])
        row1.pack(pady=8)
        
        self.create_modern_button(row1, "🚀 Start All Services", 
                                self.start_all_services, self.colors['accent_success'], 18)
        self.create_modern_button(row1, "⏹️ Stop All Services", 
                                self.stop_all_services, self.colors['accent_error'], 18)
        self.create_modern_button(row1, "🔄 Restart All", 
                                self.restart_all_services, self.colors['accent_info'], 18)
        
        # Row 2 - Maintenance
        row2 = tk.Frame(buttons_frame, bg=self.colors['bg_card'])
        row2.pack(pady=8)
        
        self.create_modern_button(row2, "🧹 Clear Cache", 
                                self.clear_cache, self.colors['accent_warning'], 18)
        self.create_modern_button(row2, "📦 Install Dependencies", 
                                self.install_dependencies, self.colors['accent_secondary'], 18)
        self.create_modern_button(row2, "🔧 Setup Environment", 
                                self.setup_environment, self.colors['accent_info'], 18)
        
        # Row 3 - Status & Access
        row3 = tk.Frame(buttons_frame, bg=self.colors['bg_card'])
        row3.pack(pady=8)
        
        self.create_modern_button(row3, "🔄 Refresh All Status", 
                                self.refresh_all_status, self.colors['accent_success'], 18)
        self.create_modern_button(row3, "🌐 Open Backend", 
                                self.open_backend_browser, self.colors['accent_info'], 18)
        self.create_modern_button(row3, "📱 Open Frontend", 
                                self.open_frontend_browser, self.colors['accent_secondary'], 18)
        
        # Row 4 - Database & Diagnostics
        row4 = tk.Frame(buttons_frame, bg=self.colors['bg_card'])
        row4.pack(pady=8)
        
        self.create_modern_button(row4, "🗄️ Open Database", 
                                self.open_database_browser, self.colors['accent_secondary'], 18)
        self.create_modern_button(row4, "📦 Check Dependencies", 
                                self.check_dependencies, self.colors['accent_warning'], 18)
        self.create_modern_button(row4, "🔍 Check Backend Details", 
                                self.check_backend_details, self.colors['accent_info'], 18)
        
        # Row 5 - Logs & Ports
        row5 = tk.Frame(buttons_frame, bg=self.colors['bg_card'])
        row5.pack(pady=8)
        
        self.create_modern_button(row5, "📋 Show Backend Logs", 
                                self.show_backend_logs, self.colors['accent_secondary'], 18)
        self.create_modern_button(row5, "🔌 Check Port Status", 
                                self.check_port_status, self.colors['accent_warning'], 18)
        
        # System Info with modern styling
        info_frame = self.create_modern_card(dashboard_frame, "System Information", 20)
        
        info_text = f"""
        Platform: {platform.system()} {platform.release()}
        Python: {sys.version.split()[0]}
        Project Root: {self.project_root}
        Backend Path: {self.backend_path}
        Frontend Path: {self.frontend_path}
        """
        
        info_label = tk.Label(info_frame, text=info_text, 
                            bg=self.colors['bg_card'], fg=self.colors['text_secondary'], 
                            font=('Segoe UI', 10),
                            justify=tk.LEFT)
        info_label.pack(pady=15, padx=20, anchor=tk.W)
        
    def create_modern_button(self, parent, text, command, color, width):
        """Create an ultra-modern neon button with high contrast"""
        # Create a frame for the button to add border effects
        button_frame = tk.Frame(parent, bg=self.colors['bg_card'])
        button_frame.pack(side=tk.LEFT, padx=8, pady=4)
        
        # Create the actual button with modern styling
        button = tk.Button(button_frame, text=text, command=command,
                          bg=color, fg='#000000',  # Black text for maximum contrast
                          font=('Segoe UI', 10, 'bold'),
                          width=width, height=2,
                          relief='flat',
                          bd=0,
                          cursor='hand2',
                          activebackground=self.colors['button_hover'],
                          activeforeground='#000000')
        
        # Add a subtle border effect
        button_frame.configure(bg=color, bd=2, relief='solid')
        
        # Pack the button inside the frame
        button.pack(padx=2, pady=2)
        
        # Enhanced hover effects
        def on_enter(e):
            button_frame.configure(bg=self.colors['button_hover'])
            button.configure(bg=self.colors['button_hover'])
            
        def on_leave(e):
            button_frame.configure(bg=color)
            button.configure(bg=color)
            
        button.bind('<Enter>', on_enter)
        button.bind('<Leave>', on_leave)
        button_frame.bind('<Enter>', on_enter)
        button_frame.bind('<Leave>', on_leave)

        return button_frame
        
    def adjust_color(self, color, amount):
        """Adjust color brightness for hover effects"""
        # Simple color adjustment - you could implement more sophisticated color manipulation
        if amount > 0:
            return self.colors['accent_primary']  # Lighter variant
        else:
            return self.colors['accent_secondary']  # Darker variant

    def create_services_tab(self, notebook):
        main_frame, services_frame = self.create_scrollable_frame(notebook)
        notebook.add(main_frame, text="🚀 Services")
        
        # Backend Controls with modern design
        backend_frame = self.create_modern_card(services_frame, "Backend Server", 25)
        
        backend_controls = tk.Frame(backend_frame, bg=self.colors['bg_card'])
        backend_controls.pack(pady=20, padx=20)
        
        self.create_modern_button(backend_controls, "🚀 Start Backend", 
                                self.start_backend, self.colors['accent_success'], 16)
        self.create_modern_button(backend_controls, "⏹️ Stop Backend", 
                                self.stop_backend, self.colors['accent_error'], 16)
        self.create_modern_button(backend_controls, "🔄 Restart Backend", 
                                self.restart_backend, self.colors['accent_info'], 16)
        self.create_modern_button(backend_controls, "📋 View Logs", 
                                self.view_backend_logs, self.colors['accent_warning'], 16)
        
        # Frontend Controls with modern design
        frontend_frame = self.create_modern_card(services_frame, "Frontend App", 25)
        
        frontend_controls = tk.Frame(frontend_frame, bg=self.colors['bg_card'])
        frontend_controls.pack(pady=20, padx=20)
        
        self.create_modern_button(frontend_controls, "🚀 Start Frontend", 
                                self.start_frontend, self.colors['accent_success'], 16)
        self.create_modern_button(frontend_controls, "⏹️ Stop Frontend", 
                                self.stop_frontend, self.colors['accent_error'], 16)
        self.create_modern_button(frontend_controls, "🔄 Restart Frontend", 
                                self.restart_frontend, self.colors['accent_info'], 16)
        self.create_modern_button(frontend_controls, "🌐 Open in Browser", 
                                self.open_frontend_browser, self.colors['accent_secondary'], 16)
        
        # Docker Controls with modern design
        docker_frame = self.create_modern_card(services_frame, "Docker Services", 25)
        
        docker_controls = tk.Frame(docker_frame, bg=self.colors['bg_card'])
        docker_controls.pack(pady=20, padx=20)
        
        self.create_modern_button(docker_controls, "🚀 Start Docker", 
                                self.start_docker, self.colors['accent_success'], 16)
        self.create_modern_button(docker_controls, "⏹️ Stop Docker", 
                                self.stop_docker, self.colors['accent_error'], 16)
        self.create_modern_button(docker_controls, "🔄 Restart Docker", 
                                self.restart_docker, self.colors['accent_info'], 16)
        self.create_modern_button(docker_controls, "📊 Docker Status", 
                                self.check_docker_status, self.colors['accent_warning'], 16)
        self.create_modern_button(docker_controls, "📋 View Logs", 
                                self.show_docker_logs, self.colors['accent_warning'], 16)
        self.create_modern_button(docker_controls, "🔍 Detailed Check", 
                                self.check_docker_detailed, self.colors['accent_info'], 16)
        
    def create_database_tab(self, notebook):
        main_frame, database_frame = self.create_scrollable_frame(notebook)
        notebook.add(main_frame, text="🗄️ Database")
        
        # Database Operations with modern design
        db_ops_frame = self.create_modern_card(database_frame, "Database Operations", 25)
        
        db_controls = tk.Frame(db_ops_frame, bg=self.colors['bg_card'])
        db_controls.pack(pady=20, padx=20)
        
        self.create_modern_button(db_controls, "🗄️ Initialize Database", 
                                self.init_database, self.colors['accent_success'], 18)
        self.create_modern_button(db_controls, "🔄 Reset Database", 
                                self.reset_database, self.colors['accent_error'], 18)
        self.create_modern_button(db_controls, "📊 Run Migrations", 
                                self.run_migrations, self.colors['accent_info'], 18)
        
        # Database Info with modern design
        db_info_frame = self.create_modern_card(database_frame, "Database Information", 25)
        
        self.db_info_text = scrolledtext.ScrolledText(db_info_frame, height=10, 
                                                    bg=self.colors['bg_tertiary'], 
                                                    fg=self.colors['text_primary'], 
                                                    font=('Consolas', 9),
                                                    insertbackground=self.colors['text_primary'],
                                                    selectbackground=self.colors['accent_primary'],
                                                    selectforeground=self.colors['text_primary'])
        self.db_info_text.pack(fill=tk.BOTH, expand=True, padx=20, pady=20)
        
        # Refresh button with modern styling
        refresh_frame = tk.Frame(db_info_frame, bg=self.colors['bg_card'])
        refresh_frame.pack(pady=(0, 20))
        
        self.create_modern_button(refresh_frame, "🔄 Refresh Database Info", 
                                self.refresh_db_info, self.colors['accent_secondary'], 20)
        
    def create_logs_tab(self, notebook):
        main_frame, logs_frame = self.create_scrollable_frame(notebook)
        notebook.add(main_frame, text="📋 Logs")
        
        # Log Controls with modern design
        log_controls_frame = self.create_modern_card(logs_frame, "Log Controls", 25)
        
        controls_buttons = tk.Frame(log_controls_frame, bg=self.colors['bg_card'])
        controls_buttons.pack(pady=20, padx=20)
        
        self.create_modern_button(controls_buttons, "📋 Backend Logs", 
                                self.show_backend_logs, self.colors['accent_success'], 16)
        self.create_modern_button(controls_buttons, "📱 Frontend Logs", 
                                self.show_frontend_logs, self.colors['accent_info'], 16)
        self.create_modern_button(controls_buttons, "🐳 Docker Logs", 
                                self.show_docker_logs, self.colors['accent_warning'], 16)
        self.create_modern_button(controls_buttons, "🧹 Clear Logs", 
                                self.clear_logs, self.colors['accent_error'], 16)
        
        # Log Display with modern design
        log_display_frame = self.create_modern_card(logs_frame, "Live Logs", 0)
        
        self.log_text = scrolledtext.ScrolledText(log_display_frame, 
                                                bg=self.colors['bg_tertiary'], 
                                                fg=self.colors['accent_success'], 
                                                font=('Consolas', 9),
                                                insertbackground=self.colors['accent_success'],
                                                selectbackground=self.colors['accent_primary'],
                                                selectforeground=self.colors['text_primary'])
        self.log_text.pack(fill=tk.BOTH, expand=True, padx=20, pady=20)
        
        # Auto-refresh checkbox with modern styling
        checkbox_frame = tk.Frame(log_display_frame, bg=self.colors['bg_card'])
        checkbox_frame.pack(pady=(0, 20))
        
        self.auto_refresh_var = tk.BooleanVar(value=True)
        tk.Checkbutton(checkbox_frame, text="🔄 Auto-refresh logs", 
                      variable=self.auto_refresh_var, 
                      bg=self.colors['bg_card'], 
                      fg=self.colors['text_primary'],
                      selectcolor=self.colors['accent_primary'], 
                      font=('Segoe UI', 10),
                      activebackground=self.colors['bg_card'],
                      activeforeground=self.colors['text_primary']).pack()
        
    def create_settings_tab(self, notebook):
        main_frame, settings_frame = self.create_scrollable_frame(notebook)
        notebook.add(main_frame, text="⚙️ Settings")
        
        # Settings content
        settings_label = tk.Label(settings_frame, text="Platform Settings", 
                                 bg=self.colors['bg_primary'], fg=self.colors['text_primary'],
                                 font=('Segoe UI', 20, 'bold'))
        settings_label.pack(pady=20)
        
        # Configuration
        config_frame = self.create_modern_card(settings_frame, "Configuration", 20)
        
        # Port settings
        port_frame = tk.Frame(config_frame, bg=self.colors['bg_card'])
        port_frame.pack(pady=10, padx=15)
        
        tk.Label(port_frame, text="Backend Port:", 
                bg=self.colors['bg_card'], fg=self.colors['text_primary'], 
                font=('Segoe UI', 10)).pack(side=tk.LEFT)
        
        self.backend_port_var = tk.StringVar(value="3000")
        port_entry = tk.Entry(port_frame, textvariable=self.backend_port_var, 
                             bg=self.colors['bg_tertiary'], fg=self.colors['text_primary'],
                             font=('Segoe UI', 10), relief='flat', bd=1,
                             insertbackground=self.colors['text_primary'])
        port_entry.pack(side=tk.LEFT, padx=(10, 0))
        
        # Environment settings
        env_frame = tk.Frame(config_frame, bg=self.colors['bg_card'])
        env_frame.pack(pady=10, padx=15)
        
        tk.Label(env_frame, text="Environment:", 
                bg=self.colors['bg_card'], fg=self.colors['text_primary'], 
                font=('Segoe UI', 10)).pack(side=tk.LEFT)
        
        self.env_var = tk.StringVar(value="development")
        env_combo = ttk.Combobox(env_frame, textvariable=self.env_var, 
                                values=["development", "staging", "production"],
                                state="readonly", width=15)
        env_combo.pack(side=tk.LEFT, padx=(10, 0))
        
        # Auto-start settings
        auto_frame = tk.Frame(config_frame, bg=self.colors['bg_card'])
        auto_frame.pack(pady=10, padx=15)
        
        self.auto_start_var = tk.BooleanVar(value=False)
        tk.Checkbutton(auto_frame, text="Auto-start services on launch", 
                      variable=self.auto_start_var, bg=self.colors['bg_card'], 
                      fg=self.colors['text_primary'], selectcolor=self.colors['accent_primary'],
                      font=('Segoe UI', 10), activebackground=self.colors['bg_card'],
                      activeforeground=self.colors['text_primary']).pack()
        
        # Save button
        save_button = self.create_modern_button(config_frame, "💾 Save Configuration", 
                                             self.save_configuration, self.colors['accent_success'], 20)
        save_button.pack(pady=20)
        
        # Advanced Settings
        advanced_frame = self.create_modern_card(settings_frame, "Advanced Settings", 20)
        
        advanced_controls = tk.Frame(advanced_frame, bg=self.colors['bg_card'])
        advanced_controls.pack(pady=20, padx=15)
        
        # Advanced buttons
        open_folder_btn = self.create_modern_button(advanced_controls, "📁 Open Project Folder", 
                                                  self.open_project_folder, self.colors['accent_info'], 20)
        
        generate_report_btn = self.create_modern_button(advanced_controls, "📊 Generate Report", 
                                                      self.generate_report, self.colors['accent_secondary'], 20)
        
        reset_settings_btn = self.create_modern_button(advanced_controls, "🔄 Reset All Settings", 
                                                     self.reset_settings, self.colors['accent_warning'], 20)
        
        # Backup and Restore section
        backup_frame = self.create_modern_card(settings_frame, "💾 Backup & Restore", 20)
        
        backup_controls = tk.Frame(backup_frame, bg=self.colors['bg_card'])
        backup_controls.pack(pady=20, padx=15)
        
        # Backup buttons
        backup_btn = self.create_modern_button(backup_controls, "💾 Create Complete Backup", 
                                             self.create_complete_backup, self.colors['accent_success'], 25)
        backup_btn.pack(pady=(0, 10))
        
        quick_backup_btn = self.create_modern_button(backup_controls, "⚡ Quick Backup (Core Files)", 
                                                   self.create_quick_backup, self.colors['accent_secondary'], 25)
        quick_backup_btn.pack(pady=(0, 10))
        
        # Restore button
        restore_btn = self.create_modern_button(backup_controls, "🔄 Restore from Backup", 
                                              self.restore_from_backup, self.colors['accent_warning'], 25)
        restore_btn.pack(pady=(0, 10))
        
        # Verify backup button
        verify_btn = self.create_modern_button(backup_controls, "🔍 Verify Backup Integrity", 
                                             self.verify_backup_integrity, self.colors['accent_info'], 25)
        verify_btn.pack(pady=(0, 10))
        
        # Backup info
        backup_info = tk.Label(backup_controls, 
                              text="Backup includes: Console, Launchers, Dependencies, & Project Files",
                              bg=self.colors['bg_card'], fg=self.colors['text_secondary'],
                              font=('Segoe UI', 9), wraplength=400)
        backup_info.pack(pady=10)

    def check_initial_status(self):
        """Check initial status of all services"""
        self.check_backend_status()
        self.check_frontend_status()
        self.check_docker_status()
        
    def check_backend_status(self):
        """Check if backend is running"""
        try:
            # Check if port is in use
            import socket
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            result = sock.connect_ex(('localhost', int(self.backend_port_var.get())))
            sock.close()
            
            if result == 0:
                self.backend_running = True
                self.backend_status_label.config(text="✅ Running", fg='#2ecc40')
            else:
                self.backend_running = False
                self.backend_status_label.config(text="❌ Stopped", fg='#ff4136')
        except:
            self.backend_running = False
            self.backend_status_label.config(text="❌ Error", fg='#ff4136')
            
    def check_frontend_status(self):
        """Check if frontend is running"""
        try:
            # Check if Expo dev server is running
            result = subprocess.run(['lsof', '-i', ':8081'], 
                                 capture_output=True, text=True, timeout=5)
            if result.returncode == 0:
                self.frontend_running = True
                self.frontend_status_label.config(text="✅ Running", fg='#2ecc40')
            else:
                self.frontend_running = False
                self.frontend_status_label.config(text="❌ Stopped", fg='#ff4136')
        except:
            self.frontend_running = False
            self.frontend_status_label.config(text="❌ Error", fg='#ff4136')
            
    def check_docker_status(self):
        """Check if Docker is running and services are available"""
        try:
            # First check if Docker daemon is running
            result = subprocess.run(['docker', 'info'], 
                                 capture_output=True, text=True, timeout=5)
            if result.returncode != 0:
                self.docker_running = False
                self.db_status_label.config(text="❌ Docker Daemon Stopped", fg='#ff4136')
                return
            
            # Check if our specific services are running
            os.chdir(self.project_root)
            result = subprocess.run(['docker-compose', 'ps'], 
                                 capture_output=True, text=True, timeout=5)
            
            if result.returncode == 0 and 'Up' in result.stdout:
                self.docker_running = True
                self.db_status_label.config(text="✅ Services Running", fg='#2ecc40')
            else:
                self.docker_running = False
                self.db_status_label.config(text="⚠️ Daemon Running, Services Stopped", fg='#ff851b')
                
        except Exception as e:
            self.docker_running = False
            self.db_status_label.config(text="❌ Error", fg='#ff4136')
            print(f"Docker status check error: {e}")
    
    def refresh_all_status(self):
        """Refresh all service statuses"""
        self.log_message("Refreshing all service statuses...")
        self.check_backend_status()
        self.check_frontend_status()
        self.check_docker_status()
        self.log_message("Status refresh completed!")
    
    def check_docker_detailed(self):
        """Detailed Docker status check with more information"""
        try:
            self.log_message("Performing detailed Docker status check...")
            
            # Check Docker daemon
            result = subprocess.run(['docker', 'info'], 
                                 capture_output=True, text=True, timeout=5)
            if result.returncode != 0:
                self.log_message("❌ Docker daemon is not running")
                self.log_message("💡 Please start Docker Desktop first")
                return False
            
            self.log_message("✅ Docker daemon is running")
            
            # Check Docker Compose
            try:
                result = subprocess.run(['docker-compose', '--version'], 
                                     capture_output=True, text=True, timeout=5)
                if result.returncode == 0:
                    self.log_message(f"✅ Docker Compose available: {result.stdout.strip()}")
                else:
                    self.log_message("❌ Docker Compose not available")
                    return False
            except Exception as e:
                self.log_message(f"❌ Docker Compose error: {e}")
                return False
            
            # Check if services are running
            os.chdir(self.project_root)
            result = subprocess.run(['docker-compose', 'ps'], 
                                 capture_output=True, text=True, timeout=5)
            
            if result.returncode == 0:
                if 'Up' in result.stdout:
                    self.log_message("✅ Docker services are running")
                    return True
                else:
                    self.log_message("⚠️ Docker services are not running")
                    self.log_message("💡 Use 'Start Docker' to start services")
                    return False
            else:
                self.log_message(f"❌ Docker Compose error: {result.stderr}")
                return False
                
        except Exception as e:
            self.log_message(f"❌ Docker check error: {e}")
            return False
    
    # Service Management Methods
    def start_all_services(self):
        """Start all services"""
        threading.Thread(target=self._start_all_services_thread, daemon=True).start()
        
    def _start_all_services_thread(self):
        """Thread to start all services"""
        try:
            self.log_message("Starting all services...")
            
            # Start Docker first
            if not self.docker_running:
                self.log_message("Starting Docker services...")
                self.start_docker()
                time.sleep(8)  # Wait longer for Docker services to be ready
                
                # Check Docker status again
                self.check_docker_status()
                if not self.docker_running:
                    self.log_message("Warning: Docker services may not be fully ready")
                
            # Start backend
            if not self.backend_running:
                self.log_message("Starting backend server...")
                self.start_backend()
                time.sleep(3)
                
            # Start frontend
            if not self.frontend_running:
                self.log_message("Starting frontend app...")
                self.start_frontend()
                
            self.log_message("All services started successfully!")
            self.root.after(0, lambda: messagebox.showinfo("Success", "All services started!"))
            
        except Exception as e:
            self.log_message(f"Error starting services: {str(e)}")
            self.root.after(0, lambda: messagebox.showerror("Error", f"Failed to start services: {str(e)}"))
    
    def stop_all_services(self):
        """Stop all services"""
        try:
            self.log_message("Stopping all services...")
            
            self.stop_backend()
            self.stop_frontend()
            self.stop_docker()
            
            self.log_message("All services stopped!")
            messagebox.showinfo("Success", "All services stopped!")
            
        except Exception as e:
            self.log_message(f"Error stopping services: {str(e)}")
            messagebox.showerror("Error", f"Failed to stop services: {str(e)}")
    
    def restart_all_services(self):
        """Restart all services"""
        self.stop_all_services()
        time.sleep(2)
        self.start_all_services()
    
    def start_backend(self):
        """Start backend server"""
        try:
            if self.backend_running:
                messagebox.showinfo("Info", "Backend is already running!")
                return
                
            self.log_message("Starting backend server...")
            
            # Change to backend directory
            os.chdir(self.backend_path)
            
            # Check if dependencies are installed
            if not os.path.exists('node_modules'):
                self.log_message("❌ Backend dependencies not installed. Installing now...")
                try:
                    subprocess.run(['npm', 'install'], check=True, timeout=60)
                    self.log_message("✅ Dependencies installed successfully")
                except Exception as e:
                    self.log_message(f"❌ Failed to install dependencies: {e}")
                    messagebox.showerror("Error", "Failed to install backend dependencies. Please run 'Check Dependencies' first.")
                    return
            
            # Check if .env file exists
            if not os.path.exists('.env'):
                self.log_message("⚠️ .env file not found. Creating default...")
                self.setup_environment()
            
            # Start backend process with better error handling
            self.log_message("Starting npm run dev...")
            self.backend_process = subprocess.Popen(
                ['npm', 'run', 'dev'],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
                bufsize=1,
                universal_newlines=True
            )
            
            # Wait a bit for server to start
            time.sleep(5)  # Increased wait time
            
            # Check if process failed immediately
            if self.backend_process.poll() is not None:
                stdout, stderr = self.backend_process.communicate()
                if stderr:
                    self.log_message(f"❌ Backend failed immediately: {stderr}")
                if stdout:
                    self.log_message(f"Backend output: {stdout}")
                self.log_message("Backend startup failed!")
                return
            
            # Check backend status
            self.check_backend_status()
            
            if self.backend_running:
                self.log_message("✅ Backend started successfully!")
            else:
                # Process is still running but port check failed
                self.log_message("⚠️ Backend process started but port not responding yet...")
                
                # Try to get any error output
                try:
                    # Non-blocking read of stderr
                    if self.backend_process.stderr:
                        stderr_data = ""
                        try:
                            stderr_data = self.backend_process.stderr.read()
                        except:
                            pass
                        if stderr_data:
                            self.log_message(f"Backend stderr: {stderr_data}")
                except:
                    pass
                
                # Wait a bit more and check again
                time.sleep(3)
                self.check_backend_status()
                if self.backend_running:
                    self.log_message("✅ Backend is now responding!")
                else:
                    self.log_message("❌ Backend still not responding on expected port")
                    self.log_message("💡 Use 'Check Backend Details' to diagnose the issue")
                
        except Exception as e:
            self.log_message(f"Error starting backend: {str(e)}")
            messagebox.showerror("Error", f"Failed to start backend: {str(e)}")
        finally:
            os.chdir(self.project_root)
    
    def stop_backend(self):
        """Stop backend server"""
        try:
            if self.backend_process:
                self.backend_process.terminate()
                self.backend_process = None
                
            # Kill any process using the backend port
            port = int(self.backend_port_var.get())
            subprocess.run(['lsof', '-ti', f':{port}', '-sTCP:LISTEN'], 
                         capture_output=True, text=True)
            
            self.backend_running = False
            self.backend_status_label.config(text="❌ Stopped", fg='#ff4136')
            self.log_message("Backend stopped!")
            
        except Exception as e:
            self.log_message(f"Error stopping backend: {str(e)}")
    
    def restart_backend(self):
        """Restart backend server"""
        self.stop_backend()
        time.sleep(2)
        self.start_backend()
    
    def start_frontend(self):
        """Start frontend app"""
        try:
            if self.frontend_running:
                messagebox.showinfo("Info", "Frontend is already running!")
                return
                
            self.log_message("Starting frontend app...")
            
            # Change to frontend directory
            os.chdir(self.frontend_path)
            
            # Start frontend process with better error handling
            self.frontend_process = subprocess.Popen(
                ['npm', 'start'],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
                bufsize=1,
                universal_newlines=True
            )
            
            # Wait a bit for server to start
            time.sleep(5)
            self.check_frontend_status()
            
            if self.frontend_running:
                self.log_message("Frontend started successfully!")
            else:
                # Get error output if startup failed
                if self.frontend_process.poll() is not None:
                    stdout, stderr = self.frontend_process.communicate()
                    if stderr:
                        self.log_message(f"Frontend startup error: {stderr}")
                    if stdout:
                        self.log_message(f"Frontend output: {stdout}")
                self.log_message("Frontend failed to start!")
                
        except Exception as e:
            self.log_message(f"Error starting frontend: {str(e)}")
            messagebox.showerror("Error", f"Failed to start frontend: {str(e)}")
    
    def stop_frontend(self):
        """Stop frontend app"""
        try:
            if self.frontend_process:
                self.frontend_process.terminate()
                self.frontend_process = None
                
            # Kill any process using the frontend port
            subprocess.run(['lsof', '-ti', ':8081', '-sTCP:LISTEN'], 
                         capture_output=True, text=True)
            
            self.frontend_running = False
            self.frontend_status_label.config(text="❌ Stopped", fg='#ff4136')
            self.log_message("Frontend stopped!")
            
        except Exception as e:
            self.log_message(f"Error stopping frontend: {str(e)}")
    
    def restart_frontend(self):
        """Restart frontend app"""
        self.stop_frontend()
        time.sleep(2)
        self.start_frontend()
    
    def start_docker(self):
        """Start Docker services"""
        try:
            # Check if Docker daemon is running first
            result = subprocess.run(['docker', 'info'], 
                                 capture_output=True, text=True, timeout=5)
            if result.returncode != 0:
                messagebox.showerror("Error", "Docker daemon is not running. Please start Docker Desktop first.")
                return
            
            if self.docker_running:
                messagebox.showinfo("Info", "Docker services are already running!")
                return
                
            self.log_message("Starting Docker services...")
            
            # Start Docker Compose
            os.chdir(self.project_root)
            result = subprocess.run(['docker-compose', 'up', '-d'], 
                                 capture_output=True, text=True, timeout=30)
            
            if result.returncode == 0:
                time.sleep(5)  # Wait for services to start
                self.check_docker_status()
                
                if self.docker_running:
                    self.log_message("Docker services started successfully!")
                else:
                    self.log_message("Docker services started but not fully ready yet")
            else:
                self.log_message(f"Docker services failed to start: {result.stderr}")
                messagebox.showerror("Error", f"Failed to start Docker services: {result.stderr}")
                
        except subprocess.TimeoutExpired:
            self.log_message("Docker services startup timed out")
            messagebox.showerror("Error", "Docker services startup timed out. Check Docker Desktop.")
        except FileNotFoundError:
            self.log_message("Docker or Docker Compose not found")
            messagebox.showerror("Error", "Docker or Docker Compose not found. Please install Docker Desktop.")
        except Exception as e:
            self.log_message(f"Error starting Docker: {str(e)}")
            messagebox.showerror("Error", f"Failed to start Docker: {str(e)}")
    
    def stop_docker(self):
        """Stop Docker services"""
        try:
            self.log_message("Stopping Docker services...")
            
            os.chdir(self.project_root)
            subprocess.run(['docker-compose', 'down'], check=True)
            
            self.docker_running = False
            self.db_status_label.config(text="❌ Stopped", fg='#ff4136')
            self.log_message("Docker services stopped!")
            
        except Exception as e:
            self.log_message(f"Error stopping Docker: {str(e)}")
    
    def restart_docker(self):
        """Restart Docker services"""
        self.stop_docker()
        time.sleep(2)
        self.start_docker()
    
    # Database Methods
    def init_database(self):
        """Initialize database"""
        try:
            self.log_message("Initializing database...")
            
            if not self.docker_running:
                messagebox.showwarning("Warning", "Docker must be running to initialize database!")
                return
            
            os.chdir(self.backend_path)
            
            # Run Prisma migrations
            subprocess.run(['npx', 'prisma', 'db', 'push'], check=True)
            subprocess.run(['npx', 'prisma', 'generate'], check=True)
            
            self.log_message("Database initialized successfully!")
            messagebox.showinfo("Success", "Database initialized!")
            
        except Exception as e:
            self.log_message(f"Error initializing database: {str(e)}")
            messagebox.showerror("Error", f"Failed to initialize database: {str(e)}")
    
    def reset_database(self):
        """Reset database"""
        if messagebox.askyesno("Confirm", "Are you sure you want to reset the database? This will delete all data!"):
            try:
                self.log_message("Resetting database...")
                
                os.chdir(self.backend_path)
                
                # Reset Prisma database
                subprocess.run(['npx', 'prisma', 'db', 'push', '--force-reset'], check=True)
                
                self.log_message("Database reset successfully!")
                messagebox.showinfo("Success", "Database reset!")
                
            except Exception as e:
                self.log_message(f"Error resetting database: {str(e)}")
                messagebox.showerror("Error", f"Failed to reset database: {str(e)}")
    
    def run_migrations(self):
        """Run database migrations"""
        try:
            self.log_message("Running database migrations...")
            
            os.chdir(self.backend_path)
            
            # Run Prisma migrations
            subprocess.run(['npx', 'prisma', 'migrate', 'deploy'], check=True)
            
            self.log_message("Migrations completed successfully!")
            messagebox.showinfo("Success", "Migrations completed!")
            
        except Exception as e:
            self.log_message(f"Error running migrations: {str(e)}")
            messagebox.showerror("Error", f"Failed to run migrations: {str(e)}")
    
    def refresh_db_info(self):
        """Refresh database information"""
        try:
            self.db_info_text.delete(1.0, tk.END)
            
            if not self.docker_running:
                self.db_info_text.insert(tk.END, "Docker is not running. Start Docker to view database info.")
                return
            
            # Get Docker container info
            result = subprocess.run(['docker', 'ps'], capture_output=True, text=True)
            if result.returncode == 0:
                self.db_info_text.insert(tk.END, "=== Docker Containers ===\n")
                self.db_info_text.insert(tk.END, result.stdout)
                self.db_info_text.insert(tk.END, "\n")
            
            # Get database schema info
            try:
                os.chdir(self.backend_path)
                result = subprocess.run(['npx', 'prisma', 'db', 'pull'], 
                                     capture_output=True, text=True)
                if result.returncode == 0:
                    self.db_info_text.insert(tk.END, "=== Database Schema ===\n")
                    self.db_info_text.insert(tk.END, "Schema pulled successfully\n")
                else:
                    self.db_info_text.insert(tk.END, "=== Database Schema ===\n")
                    self.db_info_text.insert(tk.END, "Failed to pull schema\n")
            except:
                self.db_info_text.insert(tk.END, "=== Database Schema ===\n")
                self.db_info_text.insert(tk.END, "Error accessing Prisma\n")
                
        except Exception as e:
            self.db_info_text.insert(tk.END, f"Error refreshing database info: {str(e)}")
    
    # Utility Methods
    def clear_cache(self):
        """Clear all cache"""
        try:
            self.log_message("Clearing cache...")
            
            # Clear npm cache
            subprocess.run(['npm', 'cache', 'clean', '--force'], 
                         capture_output=True, text=True)
            
            # Clear Expo cache
            subprocess.run(['npx', 'expo', 'r', '-c'], 
                         capture_output=True, text=True)
            
            # Clear Docker cache
            if self.docker_running:
                subprocess.run(['docker', 'system', 'prune', '-f'], 
                             capture_output=True, text=True)
            
            self.log_message("Cache cleared successfully!")
            messagebox.showinfo("Success", "Cache cleared!")
            
        except Exception as e:
            self.log_message(f"Error clearing cache: {str(e)}")
            messagebox.showerror("Error", f"Failed to clear cache: {str(e)}")
    
    def check_dependencies(self):
        """Check if dependencies are properly installed"""
        try:
            self.log_message("Checking dependencies...")
            
            # Check frontend dependencies
            os.chdir(self.frontend_path)
            if not os.path.exists('node_modules'):
                self.log_message("❌ Frontend: node_modules not found")
            else:
                self.log_message("✅ Frontend: node_modules found")
            
            # Check backend dependencies
            os.chdir(self.backend_path)
            if not os.path.exists('node_modules'):
                self.log_message("❌ Backend: node_modules not found")
            else:
                self.log_message("✅ Backend: node_modules found")
            
            # Check package.json files
            if not os.path.exists('package.json'):
                self.log_message("❌ Backend: package.json not found")
            else:
                self.log_message("✅ Backend: package.json found")
            
            # Check if npm is available
            try:
                result = subprocess.run(['npm', '--version'], 
                                     capture_output=True, text=True, timeout=5)
                if result.returncode == 0:
                    self.log_message(f"✅ npm version: {result.stdout.strip()}")
                else:
                    self.log_message("❌ npm not working properly")
            except Exception as e:
                self.log_message(f"❌ npm error: {e}")
            
            # Check Node.js version
            try:
                result = subprocess.run(['node', '--version'], 
                                     capture_output=True, text=True, timeout=5)
                if result.returncode == 0:
                    self.log_message(f"✅ Node.js version: {result.stdout.strip()}")
                else:
                    self.log_message("❌ Node.js not working properly")
            except Exception as e:
                self.log_message(f"❌ Node.js error: {e}")
            
            self.log_message("Dependency check completed!")
            
        except Exception as e:
            self.log_message(f"Error checking dependencies: {str(e)}")
        finally:
            os.chdir(self.project_root)
    
    def check_backend_details(self):
        """Check detailed backend status and configuration"""
        try:
            self.log_message("🔍 Checking backend details...")
            
            # Check backend directory
            os.chdir(self.backend_path)
            
            # Check package.json scripts
            if os.path.exists('package.json'):
                try:
                    import json
                    with open('package.json', 'r') as f:
                        pkg_data = json.load(f)
                    
                    scripts = pkg_data.get('scripts', {})
                    dev_script = scripts.get('dev', '')
                    self.log_message(f"📋 Dev script: {dev_script}")
                    
                    # Check if nodemon is available
                    if 'nodemon' in dev_script:
                        try:
                            result = subprocess.run(['npx', 'nodemon', '--version'], 
                                                 capture_output=True, text=True, timeout=5)
                            if result.returncode == 0:
                                self.log_message(f"✅ Nodemon version: {result.stdout.strip()}")
                            else:
                                self.log_message("❌ Nodemon not working")
                        except Exception as e:
                            self.log_message(f"❌ Nodemon error: {e}")
                    
                except Exception as e:
                    self.log_message(f"❌ Error reading package.json: {e}")
            
            # Check .env file
            if os.path.exists('.env'):
                self.log_message("✅ .env file exists")
                try:
                    with open('.env', 'r') as f:
                        env_content = f.read()
                        if 'DATABASE_URL' in env_content:
                            self.log_message("✅ DATABASE_URL configured")
                        else:
                            self.log_message("❌ DATABASE_URL not found in .env")
                        if 'PORT' in env_content:
                            self.log_message("✅ PORT configured")
                        else:
                            self.log_message("❌ PORT not found in .env")
                except Exception as e:
                    self.log_message(f"❌ Error reading .env: {e}")
            else:
                self.log_message("❌ .env file not found")
            
            # Check if backend process is running
            if self.backend_process:
                if self.backend_process.poll() is None:
                    self.log_message("✅ Backend process is running")
                    # Check what ports are actually being used
                    try:
                        result = subprocess.run(['lsof', '-i', '-P'], 
                                             capture_output=True, text=True, timeout=5)
                        if result.returncode == 0:
                            lines = result.stdout.split('\n')
                            for line in lines:
                                if 'node' in line and 'LISTEN' in line:
                                    self.log_message(f"🔌 Node process listening: {line}")
                    except Exception as e:
                        self.log_message(f"❌ Error checking ports: {e}")
                else:
                    self.log_message(f"❌ Backend process has stopped (exit code: {self.backend_process.returncode})")
            else:
                self.log_message("❌ No backend process found")
            
            # Check expected port
            expected_port = self.backend_port_var.get()
            self.log_message(f"🎯 Expected backend port: {expected_port}")
            
            # Check if port is actually in use
            try:
                import socket
                sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
                sock.settimeout(1)
                result = sock.connect_ex(('localhost', int(expected_port)))
                sock.close()
                if result == 0:
                    self.log_message(f"✅ Port {expected_port} is responding")
                else:
                    self.log_message(f"❌ Port {expected_port} is not responding")
            except Exception as e:
                self.log_message(f"❌ Error checking port {expected_port}: {e}")
            
            self.log_message("Backend details check completed!")
            
        except Exception as e:
            self.log_message(f"Error checking backend details: {str(e)}")
        finally:
            os.chdir(self.project_root)
    
    def check_port_status(self):
        """Check what's running on various ports"""
        try:
            self.log_message("🔌 Checking port status...")
            
            # Check backend port
            backend_port = self.backend_port_var.get()
            self.log_message(f"🎯 Backend port {backend_port}:")
            
            try:
                import socket
                sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
                sock.settimeout(1)
                result = sock.connect_ex(('localhost', int(backend_port)))
                sock.close()
                if result == 0:
                    self.log_message(f"  ✅ Port {backend_port} is responding")
                else:
                    self.log_message(f"  ❌ Port {backend_port} is not responding")
            except Exception as e:
                self.log_message(f"  ❌ Error checking port {backend_port}: {e}")
            
            # Check frontend port
            frontend_port = 8081
            self.log_message(f"📱 Frontend port {frontend_port}:")
            try:
                import socket
                sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
                sock.settimeout(1)
                result = sock.connect_ex(('localhost', frontend_port))
                sock.close()
                if result == 0:
                    self.log_message(f"  ✅ Port {frontend_port} is responding")
                else:
                    self.log_message(f"  ❌ Port {frontend_port} is not responding")
            except Exception as e:
                self.log_message(f"  ❌ Error checking port {frontend_port}: {e}")
            
            # Check database port
            db_port = 5432
            self.log_message(f"🗄️ Database port {db_port}:")
            try:
                import socket
                sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
                sock.settimeout(1)
                result = sock.connect_ex(('localhost', db_port))
                sock.close()
                if result == 0:
                    self.log_message(f"  ✅ Port {db_port} is responding")
                else:
                    self.log_message(f"  ❌ Port {db_port} is not responding")
            except Exception as e:
                self.log_message(f"  ❌ Error checking port {db_port}: {e}")
            
            # Check what processes are listening on ports
            try:
                result = subprocess.run(['lsof', '-i', '-P'], 
                                     capture_output=True, text=True, timeout=5)
                if result.returncode == 0:
                    self.log_message("🔍 Processes listening on ports:")
                    lines = result.stdout.split('\n')
                    for line in lines:
                        if 'LISTEN' in line and ('node' in line or 'npm' in line or 'expo' in line):
                            self.log_message(f"  {line}")
                else:
                    self.log_message("❌ Could not get process list")
            except Exception as e:
                self.log_message(f"❌ Error getting process list: {e}")
            
            self.log_message("Port status check completed!")
            
        except Exception as e:
            self.log_message(f"Error checking port status: {str(e)}")
    
    def install_dependencies(self):
        """Install all dependencies"""
        try:
            self.log_message("Installing dependencies...")
            
            # Install backend dependencies
            os.chdir(self.backend_path)
            subprocess.run(['npm', 'install'], check=True)
            
            # Install frontend dependencies
            os.chdir(self.frontend_path)
            subprocess.run(['npm', 'install'], check=True)
            
            self.log_message("Dependencies installed successfully!")
            messagebox.showinfo("Success", "Dependencies installed!")
            
        except Exception as e:
            self.log_message(f"Error installing dependencies: {str(e)}")
            messagebox.showerror("Error", f"Failed to install dependencies: {str(e)}")
        finally:
            os.chdir(self.project_root)
    
    def setup_environment(self):
        """Setup development environment"""
        try:
            self.log_message("Setting up development environment...")
            
            # Create .env file if it doesn't exist
            env_file = self.backend_path / ".env"
            if not env_file.exists():
                env_content = """# Backend Configuration
PORT=3000
NODE_ENV=development

# MongoDB Configuration (using MongoDB since models are Mongoose-based)
MONGO_URI=mongodb://localhost:27017/helpmybestlife

# JWT Configuration
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production

# CORS Configuration
CORS_ORIGIN=http://localhost:8081
"""
                with open(env_file, 'w') as f:
                    f.write(env_content)
                self.log_message("Created .env file")
            
            # Install dependencies
            self.install_dependencies()
            
            # Initialize database
            if self.docker_running:
                self.init_database()
            
            self.log_message("Environment setup completed!")
            messagebox.showinfo("Success", "Environment setup completed!")
            
        except Exception as e:
            self.log_message(f"Error setting up environment: {str(e)}")
            messagebox.showerror("Error", f"Failed to setup environment: {str(e)}")
    
    # Log Methods
    def log_message(self, message):
        """Add message to log display"""
        timestamp = time.strftime("%H:%M:%S")
        log_entry = f"[{timestamp}] {message}\n"
        
        self.log_text.insert(tk.END, log_entry)
        self.log_text.see(tk.END)
        
        # Also print to console
        print(log_entry.strip())
    
    def show_backend_logs(self):
        """Show backend logs"""
        try:
            if self.backend_process and self.backend_process.poll() is None:
                # Process is still running, try to get recent output
                try:
                    # Try to read available output without blocking
                    stdout_data = ""
                    stderr_data = ""
                    
                    # Check if there's any output available
                    if hasattr(self.backend_process.stdout, 'readable'):
                        try:
                            stdout_data = self.backend_process.stdout.read()
                        except:
                            pass
                    
                    if hasattr(self.backend_process.stderr, 'readable'):
                        try:
                            stderr_data = self.backend_process.stderr.read()
                        except:
                            pass
                    
                    if stdout_data:
                        self.log_message("Backend output:")
                        self.log_message(stdout_data[-500:] if len(stdout_data) > 500 else stdout_data)
                    if stderr_data:
                        self.log_message("Backend errors:")
                        self.log_message(stderr_data[-500:] if len(stderr_data) > 500 else stderr_data)
                    if not stdout_data and not stderr_data:
                        self.log_message("Backend is running but no recent output")
                        
                except Exception as e:
                    self.log_message(f"Could not read live logs: {e}")
                    # Fallback to process status
                    if self.backend_process.poll() is None:
                        self.log_message("Backend process is running")
                    else:
                        self.log_message("Backend process has stopped")
            else:
                self.log_message("Backend is not running")
        except Exception as e:
            self.log_message(f"Error getting backend logs: {str(e)}")
    
    def show_frontend_logs(self):
        """Show frontend logs"""
        try:
            if self.frontend_process and self.frontend_process.poll() is None:
                # Process is still running, try to get recent output
                try:
                    # Try to read available output without blocking
                    stdout_data = ""
                    stderr_data = ""
                    
                    # Check if there's any output available
                    if hasattr(self.frontend_process.stdout, 'readable'):
                        try:
                            stdout_data = self.frontend_process.stdout.read()
                        except:
                            pass
                    
                    if hasattr(self.frontend_process.stderr, 'readable'):
                        try:
                            stderr_data = self.frontend_process.stderr.read()
                        except:
                            pass
                    
                    if stdout_data:
                        self.log_message("Frontend output:")
                        self.log_message(stdout_data[-500:] if len(stdout_data) > 500 else stdout_data)
                    if stderr_data:
                        self.log_message("Frontend errors:")
                        self.log_message(stderr_data[-500:] if len(stderr_data) > 500 else stderr_data)
                    if not stdout_data and not stderr_data:
                        self.log_message("Frontend is running but no recent output")
                        
                except Exception as e:
                    self.log_message(f"Could not read live logs: {e}")
                    # Fallback to process status
                    if self.frontend_process.poll() is None:
                        self.log_message("Frontend process is running")
                    else:
                        self.log_message("Frontend process has stopped")
            else:
                self.log_message("Frontend is not running")
        except Exception as e:
            self.log_message(f"Error getting frontend logs: {str(e)}")
    
    def show_docker_logs(self):
        """Show Docker logs"""
        if self.docker_running:
            try:
                result = subprocess.run(['docker-compose', 'logs'], 
                                     capture_output=True, text=True)
                if result.returncode == 0:
                    self.log_message("Docker logs:")
                    self.log_message(result.stdout[:500] + "..." if len(result.stdout) > 500 else result.stdout)
            except Exception as e:
                self.log_message(f"Error getting Docker logs: {str(e)}")
        else:
            if self.docker_running:
                self.log_message("Docker is running but no logs available")
            else:
                self.log_message("Docker is not running")
    
    def clear_logs(self):
        """Clear log display"""
        self.log_text.delete(1.0, tk.END)
        self.log_message("Logs cleared")
    
    # Browser and File Methods
    def open_frontend_browser(self):
        """Open frontend in browser"""
        try:
            webbrowser.open('http://localhost:8081')
            self.log_message("Opening frontend in browser...")
        except Exception as e:
            self.log_message(f"Error opening browser: {str(e)}")
    
    def open_backend_browser(self):
        """Open backend in browser"""
        try:
            port = self.backend_port_var.get()
            webbrowser.open(f'http://localhost:{port}')
            self.log_message(f"Opening backend on port {port} in browser...")
        except Exception as e:
            self.log_message(f"Error opening backend in browser: {str(e)}")
    
    def open_database_browser(self):
        """Open database management interface"""
        try:
            # Try to open pgAdmin or similar if available
            # For now, just show database info
            if self.docker_running:
                self.log_message("Database is running via Docker. Use the Database tab to view info.")
                # You could add pgAdmin or other database management tools here
            else:
                self.log_message("Database is not running. Start Docker services first.")
        except Exception as e:
            self.log_message(f"Error opening database interface: {str(e)}")
    
    def open_project_folder(self):
        """Open project folder in file explorer"""
        try:
            if platform.system() == "Darwin":  # macOS
                subprocess.run(['open', str(self.project_root)])
            elif platform.system() == "Windows":
                subprocess.run(['explorer', str(self.project_root)])
            else:  # Linux
                subprocess.run(['xdg-open', str(self.project_root)])
        except Exception as e:
            self.log_message(f"Error opening project folder: {str(e)}")
    
    # Configuration Methods
    def save_configuration(self):
        """Save configuration"""
        try:
            config = {
                'backend_port': self.backend_port_var.get(),
                'environment': self.env_var.get(),
                'auto_start': self.auto_start_var.get()
            }
            
            config_file = self.project_root / "dev-config.json"
            with open(config_file, 'w') as f:
                json.dump(config, f, indent=2)
            
            self.log_message("Configuration saved!")
            messagebox.showinfo("Success", "Configuration saved!")
            
        except Exception as e:
            self.log_message(f"Error saving configuration: {str(e)}")
            messagebox.showerror("Error", f"Failed to save configuration: {str(e)}")
    
    def load_configuration(self):
        """Load configuration"""
        try:
            config_file = self.project_root / "dev-config.json"
            if config_file.exists():
                with open(config_file, 'r') as f:
                    config = json.load(f)
                
                self.backend_port_var.set(config.get('backend_port', '3000'))
                self.env_var.set(config.get('environment', 'development'))
                self.auto_start_var.set(config.get('auto_start', False))
                
                self.log_message("Configuration loaded!")
        except Exception as e:
            self.log_message(f"Error loading configuration: {str(e)}")
    
    # Advanced Methods
    def create_complete_backup(self):
        """Create a complete backup of the entire development environment"""
        try:
            self.log_message("Starting complete backup creation...")
            
            # Ask user for backup location
            backup_dir = filedialog.askdirectory(
                title="Select Backup Location",
                initialdir=str(Path.home())
            )
            
            if not backup_dir:
                self.log_message("Backup cancelled by user")
                return
            
            backup_path = Path(backup_dir)
            timestamp = time.strftime('%Y%m%d-%H%M%S')
            backup_name = f"HelpMyBestLife-Complete-Backup-{timestamp}"
            backup_full_path = backup_path / backup_name
            
            # Create backup directory
            backup_full_path.mkdir(exist_ok=True)
            
            # Files and directories to backup
            backup_items = [
                # Core console and launchers
                "dev-setup.py",
                "launch-dev-manager.py",
                "launch-dev-manager.sh",
                "launch-dev-manager.bat",
                "macos-launcher.command",
                "requirements.txt",
                "package.json",
                "package-lock.json",
                "tsconfig.json",
                "app.json",
                "docker-compose.yml",
                
                # Documentation
                "README.md",
                "README-DEV-MANAGER.md",
                "QUICK-START.md",
                "DEPLOYMENT-GUIDE.md",
                "PLATFORM-ENHANCEMENTS.md",
                "HOSTINGER-DEPLOYMENT-SUMMARY.md",
                "AUTHENTICATION-FEATURES.md",
                
                # Project directories
                "backend",
                "HelpMyBestLife",
                "prisma",
                
                # Configuration
                ".vscode",
                ".expo"
            ]
            
            # Create backup manifest
            manifest = {
                "backup_info": {
                    "name": backup_name,
                    "created": time.strftime('%Y-%m-%d %H:%M:%S'),
                    "version": "1.0",
                    "description": "Complete HelpMyBestLife Development Environment Backup"
                },
                "files": [],
                "directories": [],
                "restore_instructions": [
                    "1. Extract the backup to a new location",
                    "2. Navigate to the backup directory",
                    "3. Run the appropriate launcher for your platform:",
                    "   - Windows: launch-dev-manager.bat",
                    "   - macOS: macos-launcher.command",
                    "   - Linux: launch-dev-manager.sh",
                    "4. The launcher will automatically set up the environment"
                ]
            }
            
            total_items = len(backup_items)
            processed = 0
            
            # Create progress window
            progress_window = tk.Toplevel(self.root)
            progress_window.title("Creating Backup...")
            progress_window.geometry("500x200")
            progress_window.configure(bg=self.colors['bg_primary'])
            progress_window.transient(self.root)
            progress_window.grab_set()
            
            # Progress label
            progress_label = tk.Label(progress_window, 
                                    text="Creating complete backup...",
                                    bg=self.colors['bg_primary'], fg=self.colors['text_primary'],
                                    font=('Segoe UI', 12, 'bold'))
            progress_label.pack(pady=20)
            
            # Progress bar
            progress_bar = ttk.Progressbar(progress_window, length=400, mode='determinate')
            progress_bar.pack(pady=10)
            
            # Status label
            status_label = tk.Label(progress_window, 
                                   text="Preparing backup...",
                                   bg=self.colors['bg_primary'], fg=self.colors['text_secondary'],
                                   font=('Segoe UI', 10))
            status_label.pack(pady=10)
            
            # Update progress
            def update_progress(current, total, status):
                progress_bar['value'] = (current / total) * 100
                status_label.config(text=status)
                progress_window.update()
            
            try:
                for item in backup_items:
                    item_path = self.project_root / item
                    
                    if item_path.exists():
                        if item_path.is_file():
                            # Copy file
                            dest_path = backup_full_path / item
                            dest_path.parent.mkdir(parents=True, exist_ok=True)
                            
                            # Handle special files that might be large
                            if item in ["package-lock.json", "node_modules"]:
                                # Skip very large files, just note them
                                manifest["files"].append({
                                    "name": item,
                                    "type": "file",
                                    "note": "Large file - reinstall with npm install"
                                })
                            else:
                                import shutil
                                shutil.copy2(item_path, dest_path)
                                manifest["files"].append({
                                    "name": item,
                                    "type": "file",
                                    "size": item_path.stat().st_size
                                })
                                
                        elif item_path.is_dir():
                            # Copy directory (excluding large subdirectories)
                            dest_path = backup_full_path / item
                            
                            if item in ["backend", "HelpMyBestLife"]:
                                # For project directories, copy structure but exclude node_modules
                                self._copy_project_directory(item_path, dest_path, manifest)
                                manifest["directories"].append({
                                    "name": item,
                                    "type": "project_directory",
                                    "note": "Excludes node_modules - reinstall with npm install"
                                })
                            else:
                                # For other directories, copy everything
                                import shutil
                                shutil.copytree(item_path, dest_path, dirs_exist_ok=True)
                                manifest["directories"].append({
                                    "name": item,
                                    "type": "directory"
                                })
                    
                    processed += 1
                    update_progress(processed, total_items, f"Processing: {item}")
                
                # Create restore script
                self._create_restore_script(backup_full_path)
                
                # Save manifest
                manifest_file = backup_full_path / "backup-manifest.json"
                with open(manifest_file, 'w') as f:
                    json.dump(manifest, f, indent=2)
                
                # Create README for backup
                readme_content = f"""# HelpMyBestLife Complete Backup - {timestamp}

This is a complete backup of your HelpMyBestLife development environment.

## What's Included
- Development console (dev-setup.py)
- All platform launchers (Windows, macOS, Linux)
- Project source code (backend & frontend)
- Configuration files
- Documentation
- Database schema

## What's NOT Included (for size reasons)
- node_modules directories (will be reinstalled)
- Virtual environment (will be recreated)
- Large binary files

## How to Restore
1. Extract this backup to a new location
2. Navigate to the backup directory
3. Run the appropriate launcher for your platform:
   - **Windows**: Double-click `launch-dev-manager.bat`
   - **macOS**: Double-click `macos-launcher.command`
   - **Linux**: Run `./launch-dev-manager.sh`
4. The launcher will automatically:
   - Create a new virtual environment
   - Install required dependencies
   - Set up the development environment

## Backup Details
- Created: {time.strftime('%Y-%m-%d %H:%M:%S')}
- Total files: {len(manifest['files'])}
- Total directories: {len(manifest['directories'])}

## Support
If you encounter issues during restoration, check the backup-manifest.json file for detailed information.
"""
                
                readme_file = backup_full_path / "README.md"
                with open(readme_file, 'w') as f:
                    f.write(readme_content)
                
                # Create compressed archive
                import shutil
                archive_path = backup_path / f"{backup_name}.zip"
                
                # Use shutil.make_archive for cross-platform compatibility
                shutil.make_archive(str(archive_path).replace('.zip', ''), 'zip', backup_full_path)
                
                # Remove the uncompressed directory
                import shutil
                shutil.rmtree(backup_full_path)
                
                progress_window.destroy()
                
                self.log_message(f"Complete backup created: {archive_path}")
                messagebox.showinfo("Backup Complete!", 
                                  f"Complete backup created successfully!\n\n"
                                  f"Location: {archive_path}\n\n"
                                  f"The backup includes all necessary files to restore your "
                                  f"complete development environment.")
                
            except Exception as e:
                progress_window.destroy()
                raise e
                
        except Exception as e:
            self.log_message(f"Error creating backup: {str(e)}")
            messagebox.showerror("Backup Error", f"Failed to create backup: {str(e)}")
    
    def create_quick_backup(self):
        """Create a quick backup of core files only"""
        try:
            self.log_message("Starting quick backup creation...")
            
            # Ask user to select backup location
            backup_dir = filedialog.askdirectory(
                title="Select Quick Backup Location",
                initialdir=str(Path.home())
            )
            
            if not backup_dir:
                self.log_message("Quick backup cancelled by user")
                return
            
            backup_path = Path(backup_dir)
            timestamp = time.strftime('%Y%m%d-%H%M%S')
            backup_name = f"HelpMyBestLife-Quick-Backup-{timestamp}"
            backup_full_path = backup_path / backup_name
            
            # Create backup directory
            backup_full_path.mkdir(exist_ok=True)
            
            # Core files only - essential for quick restoration
            core_files = [
                # Essential launchers and setup
                "dev-setup.py",
                "launch-dev-manager.py",
                "launch-dev-manager.sh",
                "launch-dev-manager.bat",
                "macos-launcher.command",
                
                # Core configuration
                "requirements.txt",
                "package.json",
                "tsconfig.json",
                "app.json",
                "docker-compose.yml",
                
                # Essential documentation
                "README.md",
                "README-DEV-MANAGER.md",
                "QUICK-START.md",
                
                # Core project structure (source only, no dependencies)
                "backend/src",
                "backend/package.json",
                "backend/tsconfig.json",
                "HelpMyBestLife/App.js",
                "HelpMyBestLife/package.json",
                "HelpMyBestLife/app.json",
                "prisma/schema.prisma"
            ]
            
            # Create backup manifest
            manifest = {
                "backup_info": {
                    "name": backup_name,
                    "created": time.strftime('%Y-%m-%d %H:%M:%S'),
                    "version": "1.0",
                    "description": "Quick HelpMyBestLife Core Files Backup",
                    "type": "quick_backup"
                },
                "files": [],
                "directories": [],
                "restore_instructions": [
                    "1. Extract the backup to a new location",
                    "2. Navigate to the backup directory",
                    "3. Run the appropriate launcher for your platform:",
                    "   - Windows: launch-dev-manager.bat",
                    "   - macOS: macos-launcher.command",
                    "   - Linux: launch-dev-manager.sh",
                    "4. The launcher will automatically set up the environment"
                ],
                "note": "This is a quick backup containing only core files. For a complete backup, use 'Create Complete Backup'."
            }
            
            total_items = len(core_files)
            processed = 0
            
            # Create progress window
            progress_window = tk.Toplevel(self.root)
            progress_window.title("Creating Quick Backup...")
            progress_window.geometry("500x200")
            progress_window.configure(bg=self.colors['bg_primary'])
            progress_window.transient(self.root)
            progress_window.grab_set()
            
            # Progress label
            progress_label = tk.Label(progress_window, 
                                    text="Creating quick backup...",
                                    bg=self.colors['bg_primary'], fg=self.colors['text_primary'],
                                    font=('Segoe UI', 12, 'bold'))
            progress_label.pack(pady=20)
            
            # Progress bar
            progress_bar = ttk.Progressbar(progress_window, length=400, mode='determinate')
            progress_bar.pack(pady=10)
            
            # Status label
            status_label = tk.Label(progress_window, 
                                   text="Preparing quick backup...",
                                   bg=self.colors['bg_primary'], fg=self.colors['text_secondary'],
                                   font=('Segoe UI', 10))
            status_label.pack(pady=10)
            
            # Update progress
            def update_progress(current, total, status):
                progress_bar['value'] = (current / total) * 100
                status_label.config(text=status)
                progress_window.update()
            
            try:
                for item in core_files:
                    item_path = self.project_root / item
                    
                    if item_path.exists():
                        if item_path.is_file():
                            # Copy file
                            dest_path = backup_full_path / item
                            dest_path.parent.mkdir(parents=True, exist_ok=True)
                            
                            import shutil
                            shutil.copy2(item_path, dest_path)
                            manifest["files"].append({
                                "name": item,
                                "type": "file",
                                "size": item_path.stat().st_size
                            })
                                
                        elif item_path.is_dir():
                            # Copy directory (only source files, exclude dependencies)
                            dest_path = backup_full_path / item
                            
                            if "src" in item or item in ["prisma"]:
                                # For source directories, copy everything
                                import shutil
                                shutil.copytree(item_path, dest_path, dirs_exist_ok=True)
                                manifest["directories"].append({
                                    "name": item,
                                    "type": "source_directory"
                                })
                            else:
                                # For other directories, copy only essential files
                                self._copy_core_files_only(item_path, dest_path, manifest)
                                manifest["directories"].append({
                                    "name": item,
                                    "type": "core_files_only",
                                    "note": "Only essential configuration and source files included"
                                })
                    
                    processed += 1
                    update_progress(processed, total_items, f"Processing: {item}")
                
                # Create restore script
                self._create_restore_script(backup_full_path)
                
                # Save manifest
                manifest_file = backup_full_path / "backup-manifest.json"
                with open(manifest_file, 'w') as f:
                    json.dump(manifest, f, indent=2)
                
                # Create README for quick backup
                readme_content = f"""# HelpMyBestLife Quick Backup - {timestamp}

This is a quick backup of your HelpMyBestLife development environment containing only core files.

## What's Included
- Development console (dev-setup.py)
- All platform launchers (Windows, macOS, Linux)
- Core configuration files
- Essential documentation
- Source code (excluding dependencies)
- Database schema

## What's NOT Included
- node_modules directories
- Virtual environment
- Large binary files
- Generated files
- Dependencies (will be reinstalled)

## How to Restore
1. Extract this backup to a new location
2. Navigate to the backup directory
3. Run the appropriate launcher for your platform:
   - **Windows**: Double-click `launch-dev-manager.bat`
   - **macOS**: Double-click `macos-launcher.command`
   - **Linux**: Run `./launch-dev-manager.sh`
4. The launcher will automatically:
   - Create a new virtual environment
   - Install required dependencies
   - Set up the development environment

## Backup Details
- Created: {time.strftime('%Y-%m-%d %H:%M:%S')}
- Total files: {len(manifest['files'])}
- Total directories: {len(manifest['directories'])}
- Type: Quick Backup (Core Files Only)

## When to Use
- Quick file transfers
- Source code backup
- Configuration backup
- When you don't need a complete backup

## Support
If you encounter issues during restoration, check the backup-manifest.json file for detailed information.
"""
                
                readme_file = backup_full_path / "README.md"
                with open(readme_file, 'w') as f:
                    f.write(readme_content)
                
                # Create compressed archive
                import shutil
                archive_path = backup_path / f"{backup_name}.zip"
                
                # Use shutil.make_archive for cross-platform compatibility
                shutil.make_archive(str(archive_path).replace('.zip', ''), 'zip', backup_full_path)
                
                # Remove the uncompressed directory
                import shutil
                shutil.rmtree(backup_full_path)
                
                progress_window.destroy()
                
                self.log_message(f"Quick backup created: {archive_path}")
                messagebox.showinfo("Quick Backup Complete!", 
                                  f"Quick backup created successfully!\n\n"
                                  f"Location: {archive_path}\n\n"
                                  f"This backup contains only core files for quick restoration.\n"
                                  f"Size: {archive_path.stat().st_size / (1024*1024):.2f} MB")
                
            except Exception as e:
                progress_window.destroy()
                raise e
                
        except Exception as e:
            self.log_message(f"Error creating quick backup: {str(e)}")
            messagebox.showerror("Quick Backup Error", f"Failed to create quick backup: {str(e)}")
    
    def verify_backup_integrity(self):
        """Verify the integrity of a backup file"""
        try:
            self.log_message("Starting backup integrity verification...")
            
            # Ask user to select backup file
            backup_file = filedialog.askopenfilename(
                title="Select Backup File to Verify",
                filetypes=[("ZIP files", "*.zip"), ("All files", "*.*")],
                initialdir=str(Path.home())
            )
            
            if not backup_file:
                self.log_message("Verification cancelled by user")
                return
            
            backup_path = Path(backup_file)
            
            # Create verification window
            verify_window = tk.Toplevel(self.root)
            verify_window.title("Verifying Backup Integrity...")
            verify_window.geometry("600x400")
            verify_window.configure(bg=self.colors['bg_primary'])
            verify_window.transient(self.root)
            verify_window.grab_set()
            
            # Title
            title_label = tk.Label(verify_window, 
                                  text="🔍 Backup Integrity Verification",
                                  bg=self.colors['bg_primary'], fg=self.colors['text_primary'],
                                  font=('Segoe UI', 16, 'bold'))
            title_label.pack(pady=20)
            
            # Progress bar
            progress_bar = ttk.Progressbar(verify_window, length=500, mode='indeterminate')
            progress_bar.pack(pady=10)
            progress_bar.start()
            
            # Status label
            status_label = tk.Label(verify_window, 
                                   text="Verifying backup integrity...",
                                   bg=self.colors['bg_primary'], fg=self.colors['text_secondary'],
                                   font=('Segoe UI', 10))
            status_label.pack(pady=10)
            
            # Results text area
            results_text = scrolledtext.ScrolledText(verify_window, 
                                                   bg=self.colors['bg_tertiary'], 
                                                   fg=self.colors['text_primary'], 
                                                   font=('Consolas', 9),
                                                   height=15)
            results_text.pack(pady=10, padx=20, fill=tk.BOTH, expand=True)
            
            def update_status(status, result=""):
                status_label.config(text=status)
                if result:
                    results_text.insert(tk.END, f"{result}\n")
                    results_text.see(tk.END)
                verify_window.update()
            
            try:
                import zipfile
                import tempfile
                
                update_status("Opening backup file...")
                results_text.insert(tk.END, f"📁 Verifying: {backup_path.name}\n")
                results_text.insert(tk.END, f"📊 File size: {backup_path.stat().st_size / (1024*1024):.2f} MB\n\n")
                
                # Test ZIP file integrity
                update_status("Testing ZIP file integrity...")
                try:
                    with zipfile.ZipFile(backup_path, 'r') as zip_ref:
                        # Test ZIP file
                        zip_ref.testzip()
                        results_text.insert(tk.END, "✅ ZIP file integrity: PASSED\n")
                        
                        # List contents
                        file_list = zip_ref.namelist()
                        results_text.insert(tk.END, f"📋 Total files in backup: {len(file_list)}\n\n")
                        
                        # Check for essential files
                        essential_files = [
                            "dev-setup.py",
                            "launch-dev-manager.py",
                            "launch-dev-manager.sh",
                            "launch-dev-manager.bat",
                            "macos-launcher.command",
                            "requirements.txt",
                            "package.json"
                        ]
                        
                        update_status("Checking essential files...")
                        missing_files = []
                        for essential in essential_files:
                            if any(essential in f for f in file_list):
                                results_text.insert(tk.END, f"✅ {essential}: Found\n")
                            else:
                                results_text.insert(tk.END, f"❌ {essential}: Missing\n")
                                missing_files.append(essential)
                        
                        if missing_files:
                            results_text.insert(tk.END, f"\n⚠️  Warning: {len(missing_files)} essential files missing\n")
                        else:
                            results_text.insert(tk.END, "\n🎉 All essential files present!\n")
                        
                        # Check for project directories
                        update_status("Checking project structure...")
                        project_dirs = ["backend", "HelpMyBestLife", "prisma"]
                        for project_dir in project_dirs:
                            if any(project_dir in f for f in file_list):
                                results_text.insert(tk.END, f"✅ {project_dir}/: Found\n")
                            else:
                                results_text.insert(tk.END, f"❌ {project_dir}/: Missing\n")
                        
                        # Check for restore scripts
                        update_status("Checking restore scripts...")
                        restore_scripts = ["restore.sh", "restore.bat"]
                        for script in restore_scripts:
                            if any(script in f for f in file_list):
                                results_text.insert(tk.END, f"✅ {script}: Found\n")
                            else:
                                results_text.insert(tk.END, f"❌ {script}: Missing\n")
                        
                        # Check for documentation
                        update_status("Checking documentation...")
                        docs = ["README.md", "backup-manifest.json"]
                        for doc in docs:
                            if any(doc in f for f in file_list):
                                results_text.insert(tk.END, f"✅ {doc}: Found\n")
                            else:
                                results_text.insert(tk.END, f"❌ {doc}: Missing\n")
                        
                        # Calculate backup size breakdown
                        update_status("Calculating backup statistics...")
                        total_size = 0
                        file_types = {}
                        
                        for file_info in zip_ref.infolist():
                            size = file_info.file_size
                            total_size += size
                            
                            # Categorize by file type
                            ext = Path(file_info.filename).suffix.lower()
                            if ext:
                                file_types[ext] = file_types.get(ext, 0) + size
                            else:
                                file_types['no_extension'] = file_types.get('no_extension', 0) + size
                        
                        results_text.insert(tk.END, f"\n📊 Backup Statistics:\n")
                        results_text.insert(tk.END, f"   Total uncompressed size: {total_size / (1024*1024):.2f} MB\n")
                        results_text.insert(tk.END, f"   Compression ratio: {((1 - backup_path.stat().st_size / total_size) * 100):.1f}%\n")
                        
                        results_text.insert(tk.END, f"\n📁 File type breakdown:\n")
                        for ext, size in sorted(file_types.items(), key=lambda x: x[1], reverse=True):
                            if ext == 'no_extension':
                                ext = 'Directories'
                            results_text.insert(tk.END, f"   {ext}: {size / (1024*1024):.2f} MB\n")
                        
                        # Overall assessment
                        update_status("Generating assessment...")
                        results_text.insert(tk.END, f"\n🔍 Overall Assessment:\n")
                        
                        if not missing_files and len(file_list) > 50:  # Assuming good backup has many files
                            results_text.insert(tk.END, "   🎉 EXCELLENT: Backup appears complete and healthy\n")
                        elif not missing_files:
                            results_text.insert(tk.END, "   ✅ GOOD: Backup contains all essential files\n")
                        elif len(missing_files) <= 2:
                            results_text.insert(tk.END, "   ⚠️  FAIR: Backup missing some non-critical files\n")
                        else:
                            results_text.insert(tk.END, "   ❌ POOR: Backup missing critical files\n")
                        
                        results_text.insert(tk.END, f"\n💡 Recommendation: ")
                        if not missing_files:
                            results_text.insert(tk.END, "Backup is ready for restoration\n")
                        else:
                            results_text.insert(tk.END, "Consider creating a new backup\n")
                        
                except zipfile.BadZipFile:
                    results_text.insert(tk.END, "❌ ZIP file integrity: FAILED - File is corrupted\n")
                except Exception as e:
                    results_text.insert(tk.END, f"❌ ZIP file integrity: ERROR - {str(e)}\n")
                
                progress_bar.stop()
                update_status("Verification complete!")
                
                # Add close button
                close_btn = self.create_modern_button(verify_window, "Close", 
                                                   verify_window.destroy, self.colors['accent_success'], 15)
                close_btn.pack(pady=20)
                
            except Exception as e:
                progress_bar.stop()
                results_text.insert(tk.END, f"\n❌ Verification failed: {str(e)}\n")
                update_status("Verification failed!")
                
                # Add close button
                close_btn = self.create_modern_button(verify_window, "Close", 
                                                   verify_window.destroy, self.colors['accent_error'], 15)
                close_btn.pack(pady=20)
                
        except Exception as e:
            self.log_message(f"Error verifying backup: {str(e)}")
            messagebox.showerror("Verification Error", f"Failed to verify backup: {str(e)}")
    
    def _copy_project_directory(self, src_path, dest_path, manifest):
        """Copy project directory excluding large subdirectories"""
        import shutil
        
        # Create destination directory
        dest_path.mkdir(parents=True, exist_ok=True)
        
        # Copy files and subdirectories, excluding node_modules
        for item in src_path.iterdir():
            if item.name == "node_modules":
                # Skip node_modules, add note to manifest
                continue
            elif item.is_file():
                shutil.copy2(item, dest_path / item.name)
            elif item.is_dir():
                # Recursively copy subdirectories
                self._copy_project_directory(item, dest_path / item.name, manifest)
    
    def _copy_core_files_only(self, src_path, dest_path, manifest):
        """Copy only core/essential files from a directory, excluding dependencies and generated files"""
        import shutil
        
        # Create destination directory
        dest_path.mkdir(parents=True, exist_ok=True)
        
        # Define essential file patterns and extensions
        essential_extensions = {
            '.js', '.ts', '.jsx', '.tsx', '.json', '.md', '.txt', '.yml', '.yaml',
            '.prisma', '.sql', '.env.example', '.gitignore', '.dockerignore'
        }
        
        essential_files = {
            'package.json', 'tsconfig.json', 'app.json', 'app.config.js', 'metro.config.js',
            'babel.config.js', 'webpack.config.js', 'vite.config.js', 'tailwind.config.js',
            'README.md', 'CHANGELOG.md', 'LICENSE', '.env.example', '.gitignore',
            'docker-compose.yml', 'Dockerfile', '.dockerignore'
        }
        
        # Copy files and subdirectories, being selective about what to include
        for item in src_path.iterdir():
            if item.is_file():
                # Include essential files and files with essential extensions
                if (item.name in essential_files or 
                    item.suffix.lower() in essential_extensions or
                    item.name.startswith('.env') or
                    'config' in item.name.lower()):
                    
                    shutil.copy2(item, dest_path / item.name)
                    manifest["files"].append({
                        "name": str(item.relative_to(self.project_root)),
                        "type": "core_file",
                        "size": item.stat().st_size
                    })
                else:
                    # Skip non-essential files
                    continue
                    
            elif item.is_dir():
                # Only copy certain subdirectories
                if (item.name in ['src', 'components', 'pages', 'utils', 'hooks', 'types', 'styles', 'assets'] or
                    item.name.startswith('app') or
                    item.name in ['config', 'constants', 'services', 'models', 'routes']):
                    
                    # Recursively copy essential subdirectories
                    self._copy_core_files_only(item, dest_path / item.name, manifest)
                else:
                    # Skip dependency and build directories
                    continue
    
    def _create_restore_script(self, backup_path):
        """Create a restore script for easy restoration"""
        # Create Unix/Linux/macOS restore script
        restore_script_unix = f"""#!/bin/bash
# HelpMyBestLife Development Environment Restore Script
# Generated on {time.strftime('%Y-%m-%d %H:%M:%S')}

echo "🔄 Restoring HelpMyBestLife Development Environment..."
echo "=================================================="

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${{BASH_SOURCE[0]}}")" && pwd)"
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
"""
        
        # Create Windows batch restore script
        restore_script_windows = f"""@echo off
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
call dev-env\\Scripts\\activate.bat

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
"""
        
        # Save the Unix restore script
        restore_file_unix = backup_path / "restore.sh"
        with open(restore_file_unix, 'w') as f:
            f.write(restore_script_unix)
        
        # Save the Windows restore script
        restore_file_windows = backup_path / "restore.bat"
        with open(restore_file_windows, 'w') as f:
            f.write(restore_script_windows)
        
        # Make Unix script executable
        restore_file_unix.chmod(0o755)
    
    def restore_from_backup(self):
        """Restore the development environment from a backup"""
        try:
            self.log_message("Starting backup restoration...")
            
            # Ask user to select backup file
            backup_file = filedialog.askopenfilename(
                title="Select Backup File to Restore",
                filetypes=[("ZIP files", "*.zip"), ("All files", "*.*")],
                initialdir=str(Path.home())
            )
            
            if not backup_file:
                self.log_message("Restore cancelled by user")
                return
            
            backup_path = Path(backup_file)
            
            # Confirm restoration
            if not messagebox.askyesno("Confirm Restoration", 
                                      f"Are you sure you want to restore from:\n{backup_path.name}\n\n"
                                      f"This will overwrite your current development environment!"):
                self.log_message("Restore cancelled by user")
                return
            
            # Create progress window
            progress_window = tk.Toplevel(self.root)
            progress_window.title("Restoring from Backup...")
            progress_window.geometry("500x200")
            progress_window.configure(bg=self.colors['bg_primary'])
            progress_window.transient(self.root)
            progress_window.grab_set()
            
            # Progress label
            progress_label = tk.Label(progress_window, 
                                    text="Restoring from backup...",
                                    bg=self.colors['bg_primary'], fg=self.colors['text_primary'],
                                    font=('Segoe UI', 12, 'bold'))
            progress_label.pack(pady=20)
            
            # Progress bar
            progress_bar = ttk.Progressbar(progress_window, length=400, mode='indeterminate')
            progress_bar.pack(pady=10)
            progress_bar.start()
            
            # Status label
            status_label = tk.Label(progress_window, 
                                   text="Extracting backup...",
                                   bg=self.colors['bg_primary'], fg=self.colors['text_secondary'],
                                   font=('Segoe UI', 10))
            status_label.pack(pady=10)
            
            try:
                # Extract backup
                import zipfile
                import tempfile
                
                # Create temporary directory for extraction
                with tempfile.TemporaryDirectory() as temp_dir:
                    temp_path = Path(temp_dir)
                    
                    status_label.config(text="Extracting backup files...")
                    progress_window.update()
                    
                    # Extract ZIP file
                    with zipfile.ZipFile(backup_path, 'r') as zip_ref:
                        zip_ref.extractall(temp_path)
                    
                    # Find the backup directory
                    backup_dirs = [d for d in temp_path.iterdir() if d.is_dir()]
                    if not backup_dirs:
                        raise Exception("Invalid backup format - no directory found")
                    
                    backup_dir = backup_dirs[0]
                    
                    status_label.config(text="Restoring files...")
                    progress_window.update()
                    
                    # Restore files to project root
                    for item in backup_dir.iterdir():
                        if item.name == "README.md" or item.name == "backup-manifest.json":
                            continue  # Skip backup documentation
                        
                        dest_path = self.project_root / item.name
                        
                        if item.is_file():
                            # Copy file
                            import shutil
                            shutil.copy2(item, dest_path)
                        elif item.is_dir():
                            # Copy directory
                            if dest_path.exists():
                                import shutil
                                shutil.rmtree(dest_path)
                            import shutil
                            shutil.copytree(item, dest_path)
                    
                    status_label.config(text="Setting up environment...")
                    progress_window.update()
                    
                    # Create virtual environment if it doesn't exist
                    venv_path = self.project_root / "dev-env"
                    if not venv_path.exists():
                        import subprocess
                        subprocess.run([sys.executable, "-m", "venv", "dev-env"], 
                                     cwd=self.project_root, check=True)
                    
                    # Install Python dependencies
                    if (self.project_root / "requirements.txt").exists():
                        import subprocess
                        if sys.platform == "win32":
                            venv_python = venv_path / "Scripts" / "python.exe"
                        else:
                            venv_python = venv_path / "bin" / "python"
                        
                        subprocess.run([str(venv_python), "-m", "pip", "install", "-r", "requirements.txt"], 
                                     cwd=self.project_root, check=True)
                
                progress_window.destroy()
                
                self.log_message("Backup restoration completed successfully!")
                messagebox.showinfo("Restore Complete!", 
                                  "Development environment restored successfully!\n\n"
                                  "The environment has been restored with all your files and configurations.\n\n"
                                  "Note: Node.js dependencies (node_modules) will need to be reinstalled.\n"
                                  "You can do this by running the appropriate launcher script.")
                
                # Refresh the application
                self.refresh_all_status()
                
            except Exception as e:
                progress_window.destroy()
                raise e
                
        except Exception as e:
            self.log_message(f"Error restoring from backup: {str(e)}")
            messagebox.showerror("Restore Error", f"Failed to restore from backup: {str(e)}")
    
    def generate_report(self):
        """Generate development environment report"""
        try:
            report = f"""
=== HelpMyBestLife Development Environment Report ===
Generated: {time.strftime("%Y-%m-%d %H:%M:%S")}

System Information:
- Platform: {platform.system()} {platform.release()}
- Python: {sys.version.split()[0]}
- Project Root: {self.project_root}

Service Status:
- Backend: {'Running' if self.backend_running else 'Stopped'}
- Frontend: {'Running' if self.frontend_running else 'Stopped'}
- Database: {'Running' if self.docker_running else 'Stopped'}

Configuration:
- Backend Port: {self.backend_port_var.get()}
- Environment: {self.env_var.get()}
- Auto-start: {self.auto_start_var.get()}

Dependencies:
- Backend: {'Installed' if (self.backend_path / 'node_modules').exists() else 'Not Installed'}
- Frontend: {'Installed' if (self.frontend_path / 'node_modules').exists() else 'Not Installed'}
"""
            
            # Save report to file
            report_file = self.project_root / f"dev-report-{time.strftime('%Y%m%d-%H%M%S')}.txt"
            with open(report_file, 'w') as f:
                f.write(report)
            
            self.log_message(f"Report generated: {report_file}")
            messagebox.showinfo("Success", f"Report generated: {report_file}")
            
        except Exception as e:
            self.log_message(f"Error generating report: {str(e)}")
            messagebox.showerror("Error", f"Failed to generate report: {str(e)}")
    
    def reset_settings(self):
        """Reset all settings to defaults"""
        if messagebox.askyesno("Confirm", "Are you sure you want to reset all settings to defaults?"):
            try:
                self.backend_port_var.set("3000")
                self.env_var.set("development")
                self.auto_start_var.set(False)
                
                # Delete config file
                config_file = self.project_root / "dev-config.json"
                if config_file.exists():
                    config_file.unlink()
                
                self.log_message("Settings reset to defaults!")
                messagebox.showinfo("Success", "Settings reset to defaults!")
                
            except Exception as e:
                self.log_message(f"Error resetting settings: {str(e)}")
                messagebox.showerror("Error", f"Failed to reset settings: {str(e)}")
    
    # Docker Status Check - This method is now handled by the improved check_docker_status above
    # Removing duplicate method to fix the "Docker is not running" popup issue
    
    def view_backend_logs(self):
        """View backend logs in a new window"""
        if not self.backend_running:
            messagebox.showwarning("Warning", "Backend is not running!")
            return
        
        # Create a new window for backend logs
        log_window = tk.Toplevel(self.root)
        log_window.title("Backend Logs")
        log_window.geometry("800x600")
        log_window.configure(bg=self.colors['bg_primary'])
        
        log_text = scrolledtext.ScrolledText(log_window, 
                                           bg=self.colors['bg_tertiary'], 
                                           fg=self.colors['accent_success'], 
                                           font=('Consolas', 9),
                                           insertbackground=self.colors['text_primary'],
                                           selectbackground=self.colors['accent_primary'],
                                           selectforeground=self.colors['text_primary'])
        log_text.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)
        
        # Add some sample logs (you can implement real-time log reading)
        log_text.insert(tk.END, "Backend logs will appear here...\n")
        log_text.insert(tk.END, "Implement real-time log reading for live logs.\n")

def main():
    """Main function"""
    root = tk.Tk()
    app = DevPlatformManager(root)
    
    # Load configuration
    app.load_configuration()
    
    # Start status monitoring
    def update_status():
        app.check_backend_status()
        app.check_frontend_status()
        app.check_docker_status()
        root.after(10000, update_status)  # Update every 10 seconds
    
    root.after(1000, update_status)
    
    # Run the application
    root.mainloop()

if __name__ == "__main__":
    main()
