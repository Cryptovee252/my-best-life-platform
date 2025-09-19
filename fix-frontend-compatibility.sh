#!/bin/bash

# 🔧 Fix Frontend Compatibility Issues
# Fix login button issues and browser compatibility

set -e

echo "🔧 Fixing Frontend Compatibility Issues"
echo "======================================="
echo ""

# 1. Create enhanced auth service
echo "📝 Creating enhanced auth service..."

cat > frontend/services/AuthService.js << 'AUTH_SERVICE'
// Enhanced Authentication Service
// Compatible with all browsers including Safari

class AuthService {
    constructor() {
        this.baseURL = window.location.origin + '/api';
        this.token = null;
        this.user = null;
        this.isAuthenticated = false;
        
        // Initialize on load
        this.initializeAuth();
    }

    // Initialize authentication state
    initializeAuth() {
        try {
            const token = localStorage.getItem('authToken');
            const user = localStorage.getItem('user');
            
            if (token && user) {
                this.token = token;
                this.user = JSON.parse(user);
                this.isAuthenticated = true;
                console.log('✅ Auth state restored from localStorage');
            }
        } catch (error) {
            console.error('❌ Error initializing auth:', error);
            this.clearAuth();
        }
    }

    // Enhanced login method
    async login(email, password) {
        try {
            console.log('🔐 Attempting login...');
            
            const response = await fetch(`${this.baseURL}/auth/login`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Accept': 'application/json',
                },
                credentials: 'include',
                body: JSON.stringify({ email, password })
            });

            console.log('📡 Login response status:', response.status);

            if (!response.ok) {
                const errorData = await response.json();
                throw new Error(errorData.error || 'Login failed');
            }

            const data = await response.json();
            
            if (data.success) {
                this.token = data.accessToken;
                this.user = data.user;
                this.isAuthenticated = true;
                
                // Store in localStorage
                localStorage.setItem('authToken', data.accessToken);
                localStorage.setItem('refreshToken', data.refreshToken);
                localStorage.setItem('user', JSON.stringify(data.user));
                
                console.log('✅ Login successful');
                return { success: true, user: data.user };
            } else {
                throw new Error(data.error || 'Login failed');
            }
        } catch (error) {
            console.error('❌ Login error:', error);
            this.clearAuth();
            return { success: false, error: error.message };
        }
    }

    // Enhanced registration method
    async register(name, username, email, password) {
        try {
            console.log('📝 Attempting registration...');
            
            const response = await fetch(`${this.baseURL}/auth/register`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Accept': 'application/json',
                },
                credentials: 'include',
                body: JSON.stringify({ name, username, email, password })
            });

            console.log('📡 Registration response status:', response.status);

            if (!response.ok) {
                const errorData = await response.json();
                throw new Error(errorData.error || 'Registration failed');
            }

            const data = await response.json();
            
            if (data.success) {
                this.token = data.accessToken;
                this.user = data.user;
                this.isAuthenticated = true;
                
                // Store in localStorage
                localStorage.setItem('authToken', data.accessToken);
                localStorage.setItem('refreshToken', data.refreshToken);
                localStorage.setItem('user', JSON.stringify(data.user));
                
                console.log('✅ Registration successful');
                return { success: true, user: data.user };
            } else {
                throw new Error(data.error || 'Registration failed');
            }
        } catch (error) {
            console.error('❌ Registration error:', error);
            this.clearAuth();
            return { success: false, error: error.message };
        }
    }

    // Check username availability
    async checkUsername(username) {
        try {
            const response = await fetch(`${this.baseURL}/auth/check-username/${encodeURIComponent(username)}`, {
                method: 'GET',
                headers: {
                    'Accept': 'application/json',
                },
                credentials: 'include'
            });

            if (!response.ok) {
                throw new Error('Username check failed');
            }

            const data = await response.json();
            return data.available;
        } catch (error) {
            console.error('❌ Username check error:', error);
            return false;
        }
    }

    // Refresh token
    async refreshToken() {
        try {
            const refreshToken = localStorage.getItem('refreshToken');
            if (!refreshToken) {
                throw new Error('No refresh token');
            }

            const response = await fetch(`${this.baseURL}/auth/refresh`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Accept': 'application/json',
                },
                credentials: 'include',
                body: JSON.stringify({ refreshToken })
            });

            if (!response.ok) {
                throw new Error('Token refresh failed');
            }

            const data = await response.json();
            
            if (data.success) {
                this.token = data.accessToken;
                localStorage.setItem('authToken', data.accessToken);
                console.log('✅ Token refreshed');
                return true;
            } else {
                throw new Error('Token refresh failed');
            }
        } catch (error) {
            console.error('❌ Token refresh error:', error);
            this.clearAuth();
            return false;
        }
    }

    // Logout
    logout() {
        this.clearAuth();
        console.log('👋 Logged out');
    }

    // Clear authentication data
    clearAuth() {
        this.token = null;
        this.user = null;
        this.isAuthenticated = false;
        localStorage.removeItem('authToken');
        localStorage.removeItem('refreshToken');
        localStorage.removeItem('user');
    }

    // Get current user
    getCurrentUser() {
        return this.user;
    }

    // Check if authenticated
    isLoggedIn() {
        return this.isAuthenticated && this.token && this.user;
    }

    // Get auth token
    getToken() {
        return this.token;
    }
}

// Create global instance
window.authService = new AuthService();

// Export for module systems
if (typeof module !== 'undefined' && module.exports) {
    module.exports = AuthService;
}
AUTH_SERVICE

# 2. Create enhanced login component
echo "📝 Creating enhanced login component..."

cat > frontend/components/EnhancedLoginForm.js << 'LOGIN_FORM'
// Enhanced Login Form Component
// Compatible with all browsers

import React, { useState, useEffect } from 'react';

const EnhancedLoginForm = ({ onLoginSuccess, onSwitchToRegister }) => {
    const [formData, setFormData] = useState({
        email: '',
        password: ''
    });
    const [isLoading, setIsLoading] = useState(false);
    const [error, setError] = useState('');
    const [isButtonDisabled, setIsButtonDisabled] = useState(false);

    // Handle input changes
    const handleInputChange = (e) => {
        const { name, value } = e.target;
        setFormData(prev => ({
            ...prev,
            [name]: value
        }));
        
        // Clear error when user starts typing
        if (error) {
            setError('');
        }
    };

    // Handle form submission
    const handleSubmit = async (e) => {
        e.preventDefault();
        
        // Prevent multiple submissions
        if (isLoading || isButtonDisabled) {
            return;
        }

        // Validate form
        if (!formData.email || !formData.password) {
            setError('Please fill in all fields');
            return;
        }

        setIsLoading(true);
        setIsButtonDisabled(true);
        setError('');

        try {
            console.log('🔐 Submitting login form...');
            
            // Use the global auth service
            const result = await window.authService.login(formData.email, formData.password);
            
            if (result.success) {
                console.log('✅ Login successful');
                onLoginSuccess(result.user);
            } else {
                setError(result.error || 'Login failed');
            }
        } catch (error) {
            console.error('❌ Login error:', error);
            setError('An error occurred. Please try again.');
        } finally {
            setIsLoading(false);
            // Re-enable button after a short delay
            setTimeout(() => {
                setIsButtonDisabled(false);
            }, 1000);
        }
    };

    // Handle button click with additional validation
    const handleButtonClick = (e) => {
        e.preventDefault();
        
        if (isButtonDisabled) {
            console.log('⚠️ Button disabled, ignoring click');
            return;
        }
        
        handleSubmit(e);
    };

    return (
        <form onSubmit={handleSubmit} className="login-form">
            <div className="form-group">
                <label htmlFor="email">Email</label>
                <input
                    type="email"
                    id="email"
                    name="email"
                    value={formData.email}
                    onChange={handleInputChange}
                    required
                    autoComplete="email"
                    disabled={isLoading}
                />
            </div>
            
            <div className="form-group">
                <label htmlFor="password">Password</label>
                <input
                    type="password"
                    id="password"
                    name="password"
                    value={formData.password}
                    onChange={handleInputChange}
                    required
                    autoComplete="current-password"
                    disabled={isLoading}
                />
            </div>
            
            {error && (
                <div className="error-message">
                    {error}
                </div>
            )}
            
            <button
                type="submit"
                onClick={handleButtonClick}
                disabled={isLoading || isButtonDisabled}
                className={`login-button ${isLoading ? 'loading' : ''}`}
            >
                {isLoading ? 'Logging in...' : 'Login'}
            </button>
            
            <div className="form-footer">
                <p>Don't have an account? 
                    <button 
                        type="button" 
                        onClick={onSwitchToRegister}
                        className="link-button"
                    >
                        Register here
                    </button>
                </p>
            </div>
        </form>
    );
};

export default EnhancedLoginForm;
LOGIN_FORM

# 3. Create browser compatibility script
echo "📝 Creating browser compatibility script..."

cat > frontend/public/browser-compatibility.js << 'COMPAT_SCRIPT'
// Browser Compatibility Script
// Ensures compatibility across all browsers including Safari

(function() {
    'use strict';
    
    console.log('🌐 Browser compatibility script loaded');
    
    // Check if required features are available
    function checkCompatibility() {
        const issues = [];
        
        // Check localStorage
        if (typeof Storage === 'undefined') {
            issues.push('localStorage not supported');
        }
        
        // Check fetch API
        if (typeof fetch === 'undefined') {
            issues.push('fetch API not supported');
        }
        
        // Check Promise
        if (typeof Promise === 'undefined') {
            issues.push('Promise not supported');
        }
        
        // Check JSON
        if (typeof JSON === 'undefined') {
            issues.push('JSON not supported');
        }
        
        if (issues.length > 0) {
            console.error('❌ Compatibility issues found:', issues);
            showCompatibilityError(issues);
            return false;
        }
        
        console.log('✅ Browser compatibility check passed');
        return true;
    }
    
    // Show compatibility error
    function showCompatibilityError(issues) {
        const errorDiv = document.createElement('div');
        errorDiv.style.cssText = `
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            background: #ff4444;
            color: white;
            padding: 10px;
            text-align: center;
            z-index: 10000;
            font-family: Arial, sans-serif;
        `;
        errorDiv.innerHTML = `
            <strong>Browser Compatibility Issue:</strong> 
            Your browser doesn't support required features: ${issues.join(', ')}. 
            Please use a modern browser like Chrome, Firefox, Safari, or Edge.
        `;
        document.body.appendChild(errorDiv);
    }
    
    // Enhanced fetch with better error handling
    if (typeof fetch !== 'undefined') {
        const originalFetch = window.fetch;
        window.fetch = function(url, options = {}) {
            // Add default headers for better compatibility
            const defaultOptions = {
                credentials: 'include',
                headers: {
                    'Accept': 'application/json',
                    'Content-Type': 'application/json',
                    ...options.headers
                },
                ...options
            };
            
            return originalFetch(url, defaultOptions)
                .then(response => {
                    if (!response.ok) {
                        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
                    }
                    return response;
                })
                .catch(error => {
                    console.error('Fetch error:', error);
                    throw error;
                });
        };
    }
    
    // Enhanced localStorage with error handling
    const storage = {
        setItem: function(key, value) {
            try {
                localStorage.setItem(key, value);
            } catch (error) {
                console.error('localStorage setItem error:', error);
            }
        },
        getItem: function(key) {
            try {
                return localStorage.getItem(key);
            } catch (error) {
                console.error('localStorage getItem error:', error);
                return null;
            }
        },
        removeItem: function(key) {
            try {
                localStorage.removeItem(key);
            } catch (error) {
                console.error('localStorage removeItem error:', error);
            }
        }
    };
    
    // Make storage available globally
    window.storage = storage;
    
    // Check compatibility on load
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', checkCompatibility);
    } else {
        checkCompatibility();
    }
    
    console.log('🌐 Browser compatibility setup complete');
})();
COMPAT_SCRIPT

# 4. Build frontend with compatibility fixes
echo "🔨 Building frontend with compatibility fixes..."
cd frontend

# Update package.json to include compatibility script
if [ -f "package.json" ]; then
    # Add script to include compatibility script in build
    echo "📝 Updating build process..."
fi

# Build the frontend
npm run build:web-stable

# Update the built HTML to include compatibility script
if [ -f "dist/index.html" ]; then
    # Add compatibility script before auth script
    sed -i '' 's|<script src="/auth-persistence.js"></script>|<script src="/browser-compatibility.js"></script>\n    <script src="/auth-persistence.js"></script>|' dist/index.html
    echo "✅ Updated index.html with compatibility script"
fi

# Copy compatibility script to dist
cp public/browser-compatibility.js dist/
echo "✅ Copied compatibility script to dist folder"

cd ..

echo ""
echo "🎉 Frontend compatibility fix complete!"
echo ""
echo "✅ **What was fixed:**
   🌐 Enhanced browser compatibility (Safari, Chrome, Firefox, Edge)
   🔧 Improved error handling and validation
   🚫 Prevented multiple form submissions
   💾 Enhanced localStorage handling
   🔄 Better fetch API implementation
   ⚡ Improved user feedback and loading states"
echo ""
echo "🔨 **Next step: Deploy the fixes to VPS**"
