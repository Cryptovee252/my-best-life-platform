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
