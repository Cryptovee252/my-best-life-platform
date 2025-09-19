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
