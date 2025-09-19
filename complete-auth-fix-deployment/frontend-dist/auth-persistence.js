// Authentication Persistence Fix
// This script ensures users stay logged in after page refresh

(function() {
    'use strict';
    
    console.log('🔐 Auth persistence script loaded');
    
    // Check if user is logged in on page load
    function checkAuthStatus() {
        const token = localStorage.getItem('authToken');
        const user = localStorage.getItem('user');
        
        if (token && user) {
            console.log('✅ User is logged in, restoring session');
            
            // Set up global auth state
            window.isAuthenticated = true;
            window.currentUser = JSON.parse(user);
            window.authToken = token;
            
            // Dispatch custom event for auth restoration
            window.dispatchEvent(new CustomEvent('authRestored', {
                detail: { user: window.currentUser, token: window.authToken }
            }));
            
            // Update UI if needed
            updateUIForLoggedInUser();
        } else {
            console.log('❌ No auth data found, user not logged in');
            window.isAuthenticated = false;
            window.currentUser = null;
            window.authToken = null;
        }
    }
    
    // Update UI for logged in user
    function updateUIForLoggedInUser() {
        // Hide login/register buttons
        const loginButtons = document.querySelectorAll('[data-auth="login"], [data-auth="register"]');
        loginButtons.forEach(btn => {
            if (btn) btn.style.display = 'none';
        });
        
        // Show user menu/profile
        const userMenus = document.querySelectorAll('[data-auth="user-menu"], [data-auth="profile"]');
        userMenus.forEach(menu => {
            if (menu) menu.style.display = 'block';
        });
        
        // Update user name if element exists
        const userNameElements = document.querySelectorAll('[data-user="name"]');
        userNameElements.forEach(el => {
            if (el && window.currentUser) {
                el.textContent = window.currentUser.name || window.currentUser.username;
            }
        });
    }
    
    // Enhanced token refresh function
    function refreshAuthToken() {
        const refreshToken = localStorage.getItem('refreshToken');
        if (!refreshToken) return;
        
        fetch('/api/auth/refresh', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({ refreshToken })
        })
        .then(response => response.json())
        .then(data => {
            if (data.success && data.token) {
                localStorage.setItem('authToken', data.token);
                window.authToken = data.token;
                console.log('✅ Token refreshed successfully');
            }
        })
        .catch(error => {
            console.error('❌ Token refresh failed:', error);
            // If refresh fails, clear auth data
            localStorage.removeItem('authToken');
            localStorage.removeItem('refreshToken');
            localStorage.removeItem('user');
            window.location.reload();
        });
    }
    
    // Set up periodic token refresh (every 50 minutes)
    setInterval(refreshAuthToken, 50 * 60 * 1000);
    
    // Check auth status on page load
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', checkAuthStatus);
    } else {
        checkAuthStatus();
    }
    
    // Also check on page show (back button, etc.)
    window.addEventListener('pageshow', checkAuthStatus);
    
    // Listen for storage changes (tabs sync)
    window.addEventListener('storage', function(e) {
        if (e.key === 'authToken' || e.key === 'user') {
            checkAuthStatus();
        }
    });
    
    console.log('🔐 Auth persistence setup complete');
})();
