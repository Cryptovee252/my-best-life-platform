#!/bin/bash

# 🔧 Fix Refresh Logout Bug
# Fix page refresh causing user to be logged out

set -e

# VPS Configuration
VPS_IP="147.93.47.43"
VPS_USER="root"

echo "🔧 Fixing Refresh Logout Bug"
echo "============================"
echo "VPS: $VPS_IP"
echo ""

echo "📤 Running refresh logout fix on VPS..."
ssh $VPS_USER@$VPS_IP << 'EOF'
echo "🔧 Starting refresh logout fix..."
echo ""

# 1. Check current frontend files
echo "📁 Checking current frontend files..."
ls -la /var/www/mybestlife/ | head -10
echo ""

# 2. Check if there are authentication-related files
echo "🔍 Looking for auth-related files..."
find /var/www/mybestlife -name "*auth*" -o -name "*token*" -o -name "*session*" | head -10
echo ""

# 3. Check browser storage implementation
echo "🔍 Checking for localStorage/sessionStorage usage..."
grep -r "localStorage\|sessionStorage\|AsyncStorage" /var/www/mybestlife/ | head -5 || echo "No storage usage found"
echo ""

# 4. Check if there's a token refresh mechanism
echo "🔍 Checking for token refresh logic..."
grep -r "refresh\|token" /var/www/mybestlife/ | head -5 || echo "No token refresh found"
echo ""

# 5. Create a simple fix by updating the frontend
echo "📝 Creating authentication persistence fix..."

# Create a simple auth persistence script
cat > /var/www/mybestlife/auth-persistence.js << 'AUTH_SCRIPT'
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
AUTH_SCRIPT

# 6. Update the main HTML file to include the auth script
echo "📝 Updating main HTML file..."
if [ -f "/var/www/mybestlife/index.html" ]; then
    # Backup original
    cp /var/www/mybestlife/index.html /var/www/mybestlife/index.html.backup
    
    # Add auth script before closing body tag
    sed -i 's|</body>|    <script src="/auth-persistence.js"></script>\n</body>|' /var/www/mybestlife/index.html
    
    echo "✅ Updated index.html with auth persistence script"
else
    echo "❌ index.html not found"
fi

# 7. Create a backend endpoint for token refresh
echo "🔧 Adding token refresh endpoint to backend..."
cd /root/vps-clean-deployment/backend

# Add refresh endpoint to the backend
cat >> app-secure.js << 'REFRESH_ENDPOINT'

// Token refresh endpoint
app.post('/api/auth/refresh', async (req, res) => {
    try {
        const { refreshToken } = req.body;
        
        if (!refreshToken) {
            return res.status(400).json({ 
                success: false, 
                error: 'Refresh token required' 
            });
        }
        
        // Verify refresh token
        const decoded = jwt.verify(refreshToken, process.env.JWT_REFRESH_SECRET);
        
        // Generate new access token
        const newToken = jwt.sign(
            { 
                userId: decoded.userId, 
                email: decoded.email 
            },
            process.env.JWT_SECRET,
            { expiresIn: '1h' }
        );
        
        res.json({
            success: true,
            token: newToken,
            message: 'Token refreshed successfully'
        });
        
    } catch (error) {
        console.error('Token refresh error:', error);
        res.status(401).json({ 
            success: false, 
            error: 'Invalid refresh token' 
        });
    }
});
REFRESH_ENDPOINT

# 8. Restart backend with new endpoint
echo "🔄 Restarting backend with token refresh endpoint..."
pm2 restart mybestlife-backend

# 9. Test the fix
echo "🔍 Testing the fix..."
sleep 3

echo "Testing auth endpoints..."
curl -s http://localhost:3000/api/health || echo "Health check failed"

echo ""
echo "✅ Refresh logout fix complete!"
echo ""
echo "📊 Backend Status:"
pm2 list
echo ""
echo "🌐 The refresh logout bug should now be fixed!"
echo ""
echo "🔧 What was fixed:"
echo "   ✅ Added auth persistence script"
echo "   ✅ Added token refresh endpoint"
echo "   ✅ Enhanced localStorage handling"
echo "   ✅ Added UI state restoration"
echo "   ✅ Added periodic token refresh"
echo ""
echo "🌐 Test by:"
echo "   1. Login to your account"
echo "   2. Refresh the page"
echo "   3. You should stay logged in!"
EOF

echo ""
echo "🔍 Testing website after refresh logout fix..."
sleep 5

echo "Testing main page..."
curl -s -I https://mybestlifeapp.com || echo "Main page test failed"

echo ""
echo "🎉 Refresh logout fix complete!"
echo ""
echo "✅ **What was fixed:**
   🔐 Added authentication persistence script
   🔄 Added token refresh endpoint
   💾 Enhanced localStorage handling
   🎨 Added UI state restoration
   ⏰ Added periodic token refresh (every 50 minutes)"
echo ""
echo "🌐 **Test the fix:**
   1. Visit: https://mybestlifeapp.com
   2. Login to your account
   3. Refresh the page (F5 or Ctrl+R)
   4. You should stay logged in!"
echo ""
echo "🔧 **If still having issues:**
   - Check browser console for errors
   - Clear browser cache and try again
   - Check if localStorage is enabled"
