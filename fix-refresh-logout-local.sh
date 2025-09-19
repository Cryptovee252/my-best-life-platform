#!/bin/bash

# 🔧 Fix Refresh Logout Bug - Local Approach
# Fix page refresh causing user to be logged out by updating frontend locally

set -e

echo "🔧 Fixing Refresh Logout Bug - Local Approach"
echo "============================================="
echo ""

# 1. Build fresh frontend with auth persistence
echo "📝 Building frontend with auth persistence fix..."

# Create auth persistence script
cat > frontend/public/auth-persistence.js << 'AUTH_SCRIPT'
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

echo "✅ Created auth persistence script"

# 2. Build frontend
echo "🔨 Building frontend..."
cd frontend
npm run build:web-stable
echo "✅ Frontend built successfully"

# 3. Update the built HTML to include auth script
echo "📝 Updating built HTML with auth script..."
if [ -f "dist/index.html" ]; then
    # Add auth script before closing body tag
    sed -i '' 's|</body>|    <script src="/auth-persistence.js"></script>\n</body>|' dist/index.html
    echo "✅ Updated index.html with auth persistence script"
else
    echo "❌ dist/index.html not found"
fi

# 4. Copy auth script to dist
cp public/auth-persistence.js dist/
echo "✅ Copied auth script to dist folder"

cd ..

# 5. Create deployment package
echo "📦 Creating deployment package..."
rm -rf vps-refresh-fix-deployment
mkdir -p vps-refresh-fix-deployment

# Copy frontend dist
cp -r frontend/dist vps-refresh-fix-deployment/frontend-dist

# Create deployment script
cat > vps-refresh-fix-deployment/deploy-refresh-fix.sh << 'DEPLOY_SCRIPT'
#!/bin/bash

echo "🔧 Deploying refresh logout fix..."

# Stop backend temporarily
pm2 stop mybestlife-backend

# Deploy frontend
sudo cp -r frontend-dist/* /var/www/mybestlife/
sudo chown -R www-data:www-data /var/www/mybestlife

# Add token refresh endpoint to backend
cd /root/vps-clean-deployment/backend

# Add refresh endpoint
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

# Restart backend
pm2 restart mybestlife-backend

echo "✅ Refresh logout fix deployed!"
echo "🌐 Test by logging in and refreshing the page"
DEPLOY_SCRIPT

chmod +x vps-refresh-fix-deployment/deploy-refresh-fix.sh

# Create tar archive
tar -czf vps-refresh-fix-deployment.tar.gz vps-refresh-fix-deployment/

echo ""
echo "🎉 Refresh logout fix package created!"
echo ""
echo "📦 **Deployment Package:**"
echo "   File: vps-refresh-fix-deployment.tar.gz"
echo "   Size: $(du -h vps-refresh-fix-deployment.tar.gz | cut -f1)"
echo ""
echo "🚀 **Deploy to VPS:**
   1. Upload: scp vps-refresh-fix-deployment.tar.gz root@147.93.47.43:/root/
   2. SSH: ssh root@147.93.47.43
   3. Extract: tar -xzf vps-refresh-fix-deployment.tar.gz
   4. Deploy: cd vps-refresh-fix-deployment && ./deploy-refresh-fix.sh"
echo ""
echo "✅ **What this fixes:**
   🔐 Adds authentication persistence script
   🔄 Adds token refresh endpoint
   💾 Enhances localStorage handling
   🎨 Adds UI state restoration
   ⏰ Adds periodic token refresh"
echo ""
echo "🌐 **After deployment, test by:**
   1. Login to your account
   2. Refresh the page (F5)
   3. You should stay logged in!"
