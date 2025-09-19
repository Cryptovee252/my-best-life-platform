import AsyncStorage from '@react-native-async-storage/async-storage';

import { API_BASE_URL } from '@/constants/api';

export interface AuthUser {
  _id: string;
  name: string;
  username: string;
  email: string;
  profilePic: string;
  dailyCP: number;
  lifetimeCP: number;
  cpByCategory: { mind: number; body: number; soul: number };
  daysActive: number;
  startDate: string;
  lastActiveDate: string;
  isOnline: boolean;
  lastSeen: string;
  createdAt: string;
  updatedAt: string;
}

export interface LoginCredentials {
  email: string;
  password: string;
}

export interface RegisterCredentials {
  name: string;
  username: string;
  email: string;
  password: string;
}

export interface AuthResponse {
  success: boolean;
  message: string;
  token: string;
  user: AuthUser;
}

export interface ProfileUpdateData {
  name?: string;
  username?: string;
  profilePic?: string;
}

class AuthService {
  private token: string | null = null;
  private user: AuthUser | null = null;

  constructor() {
    // Only load stored auth on client side
    if (typeof window !== 'undefined') {
      this.loadStoredAuth();
    }
  }

  private async loadStoredAuth() {
    try {
      // Check if we're in a browser environment
      if (typeof window === 'undefined') {
        return;
      }
      
      const storedToken = await AsyncStorage.getItem('auth_token');
      const storedUser = await AsyncStorage.getItem('auth_user');
      
      if (storedToken && storedUser) {
        this.token = storedToken;
        this.user = JSON.parse(storedUser);
      }
    } catch (error) {
      console.error('Error loading stored auth:', error);
    }
  }

  private async storeAuth(token: string, user: AuthUser) {
    try {
      await AsyncStorage.setItem('auth_token', token);
      await AsyncStorage.setItem('auth_user', JSON.stringify(user));
      this.token = token;
      this.user = user;
    } catch (error) {
      console.error('Error storing auth:', error);
      throw error;
    }
  }

  async logout(): Promise<void> {
    try {
      console.log('🔐 AuthService: Starting logout process');
      
      if (this.token) {
        console.log('📡 AuthService: Calling backend logout endpoint');
        try {
          const response = await fetch(`${API_BASE_URL}/auth/logout`, {
            method: 'POST',
            headers: this.getAuthHeaders(),
          });
          
          if (response.ok) {
            console.log('✅ AuthService: Backend logout successful');
          } else {
            console.warn('⚠️ AuthService: Backend logout returned status:', response.status);
          }
        } catch (error) {
          console.warn('⚠️ AuthService: Backend logout failed, continuing with local cleanup:', error);
        }
      } else {
        console.log('ℹ️ AuthService: No token to logout from backend');
      }
    } catch (error) {
      console.error('❌ AuthService: Logout API error:', error);
    } finally {
      console.log('🗑️ AuthService: Clearing stored authentication data');
      await this.clearStoredAuth();
      console.log('✅ AuthService: Logout process completed');
    }
  }

  async clearStoredAuth(): Promise<void> {
    try {
      console.log('🗑️ AuthService: Clearing stored auth data');
      
      // Clear memory
      this.token = null;
      this.user = null;
      
      // Clear AsyncStorage
      await AsyncStorage.removeItem('auth_token');
      await AsyncStorage.removeItem('auth_user');
      
      console.log('✅ AuthService: Stored auth data cleared');
    } catch (error) {
      console.error('❌ AuthService: Error clearing stored auth:', error);
      // Even if clearing fails, reset memory state
      this.token = null;
      this.user = null;
    }
  }

  private getAuthHeaders(): HeadersInit {
    const headers: HeadersInit = {
      'Content-Type': 'application/json',
    };
    
    if (this.token) {
      headers['Authorization'] = `Bearer ${this.token}`;
    }
    
    return headers;
  }

  async register(credentials: RegisterCredentials): Promise<AuthResponse> {
    try {
      const url = `${API_BASE_URL}/auth/register`;
      console.log('🔐 Attempting registration at:', url);
      console.log('📝 Registration data:', credentials);
      
      const response = await fetch(url, {
        method: 'POST',
        headers: this.getAuthHeaders(),
        body: JSON.stringify(credentials),
      });

      console.log('📡 Registration response status:', response.status);
      console.log('📡 Registration response headers:', response.headers);

      const data = await response.json();
      console.log('📡 Registration response data:', data);

      if (!response.ok) {
        console.error('❌ Registration failed with status:', response.status);
        throw new Error(data.error || `Registration failed: ${response.status}`);
      }

      if (data.success && data.token && data.user) {
        console.log('✅ Registration successful, storing auth data');
        await this.storeAuth(data.token, data.user);
      } else {
        console.error('❌ Registration response missing required fields:', data);
        throw new Error('Invalid registration response format');
      }

      return data;
    } catch (error) {
      console.error('❌ Registration error:', error);
      if (error instanceof TypeError && error.message.includes('fetch')) {
        console.error('🌐 Network error - check if backend is running and accessible');
        console.error('🔗 API URL:', API_BASE_URL);
      }
      throw error;
    }
  }

  async login(credentials: LoginCredentials): Promise<AuthResponse> {
    try {
      const url = `${API_BASE_URL}/auth/login`;
      console.log('🔐 Attempting login at:', url);
      console.log('📝 Login data:', { email: credentials.email, password: '***' });
      
      const response = await fetch(url, {
        method: 'POST',
        headers: this.getAuthHeaders(),
        body: JSON.stringify(credentials),
      });

      console.log('📡 Login response status:', response.status);
      console.log('📡 Login response headers:', response.headers);

      const data = await response.json();
      console.log('📡 Login response data:', data);

      if (!response.ok) {
        console.error('❌ Login failed with status:', response.status);
        throw new Error(data.error || `Login failed: ${response.status}`);
      }

      if (data.success && data.token && data.user) {
        console.log('✅ Login successful, storing auth data');
        await this.storeAuth(data.token, data.user);
      } else {
        console.error('❌ Login response missing required fields:', data);
        throw new Error('Invalid login response format');
      }

      return data;
    } catch (error) {
      console.error('❌ Login error:', error);
      if (error instanceof TypeError && error.message.includes('fetch')) {
        console.error('🌐 Network error - check if backend is running and accessible');
        console.error('🔗 API URL:', API_BASE_URL);
      }
      throw error;
    }
  }

  async getProfile(): Promise<AuthUser> {
    try {
      if (!this.token) {
        throw new Error('No authentication token');
      }

      const response = await fetch(`${API_BASE_URL}/auth/me`, {
        method: 'GET',
        headers: this.getAuthHeaders(),
      });

      const data = await response.json();

      if (!response.ok) {
        throw new Error(data.error || 'Failed to fetch profile');
      }

      if (data.success && data.user) {
        this.user = data.user;
        await AsyncStorage.setItem('auth_user', JSON.stringify(data.user));
        return data.user;
      }

      throw new Error('Invalid response format');
    } catch (error) {
      console.error('Get profile error:', error);
      throw error;
    }
  }

  async updateProfile(updateData: ProfileUpdateData): Promise<AuthUser> {
    try {
      if (!this.token) {
        throw new Error('No authentication token');
      }

      const response = await fetch(`${API_BASE_URL}/auth/profile`, {
        method: 'PUT',
        headers: this.getAuthHeaders(),
        body: JSON.stringify(updateData),
      });

      const data = await response.json();

      if (!response.ok) {
        throw new Error(data.error || 'Failed to update profile');
      }

      if (data.success && data.user) {
        this.user = data.user;
        await AsyncStorage.setItem('auth_user', JSON.stringify(data.user));
        return data.user;
      }

      throw new Error('Invalid response format');
    } catch (error) {
      console.error('Update profile error:', error);
      throw error;
    }
  }

  async changePassword(currentPassword: string, newPassword: string): Promise<void> {
    try {
      if (!this.token) {
        throw new Error('No authentication token');
      }

      const response = await fetch(`${API_BASE_URL}/auth/change-password`, {
        method: 'POST',
        headers: this.getAuthHeaders(),
        body: JSON.stringify({ currentPassword, newPassword }),
      });

      const data = await response.json();

      if (!response.ok) {
        throw new Error(data.error || 'Failed to change password');
      }

      if (!data.success) {
        throw new Error('Password change failed');
      }
    } catch (error) {
      console.error('Change password error:', error);
      throw error;
    }
  }

  async checkUsername(username: string): Promise<boolean> {
    try {
      const response = await fetch(`${API_BASE_URL}/auth/check-username/${username}`, {
        method: 'GET',
        headers: this.getAuthHeaders(),
      });

      const data = await response.json();

      if (!response.ok) {
        throw new Error(data.error || 'Failed to check username');
      }

      return data.available;
    } catch (error) {
      console.error('Check username error:', error);
      throw error;
    }
  }

  // Test connection to backend
  async testConnection(): Promise<boolean> {
    try {
      const url = `${API_BASE_URL.replace('/api', '')}/api/health`;
      console.log('🔍 Testing connection to:', url);
      
      const response = await fetch(url, {
        method: 'GET',
        headers: {
          'Content-Type': 'application/json',
        },
      });

      console.log('📡 Health check response status:', response.status);
      
      if (response.ok) {
        const data = await response.json();
        console.log('✅ Backend connection successful:', data);
        return true;
      } else {
        console.error('❌ Backend health check failed:', response.status);
        return false;
      }
    } catch (error) {
      console.error('❌ Connection test failed:', error);
      if (error instanceof TypeError && error.message.includes('fetch')) {
        console.error('🌐 Network error - check if backend is running and accessible');
        console.error('🔗 API URL:', API_BASE_URL);
      }
      return false;
    }
  }

  async isAuthenticated(): Promise<boolean> {
    try {
      if (this.token && this.user) {
        return true;
      }
      
      // Check AsyncStorage if not in memory
      const storedToken = await AsyncStorage.getItem('auth_token');
      const storedUser = await AsyncStorage.getItem('auth_user');
      
      if (storedToken && storedUser) {
        this.token = storedToken;
        this.user = JSON.parse(storedUser);
        return true;
      }
      
      return false;
    } catch (error) {
      console.error('Error checking authentication status:', error);
      return false;
    }
  }

  getCurrentUser(): AuthUser | null {
    return this.user;
  }

  async getToken(): Promise<string | null> {
    try {
      // First check memory
      if (this.token) {
        return this.token;
      }
      
      // If not in memory, try to load from AsyncStorage
      const storedToken = await AsyncStorage.getItem('auth_token');
      if (storedToken) {
        this.token = storedToken;
        return storedToken;
      }
      
      return null;
    } catch (error) {
      console.error('Error getting token:', error);
      return null;
    }
  }

  async refreshAuth(): Promise<void> {
    if (this.token && this.user) {
      try {
        await this.getProfile();
      } catch (error) {
        console.error('Failed to refresh auth:', error);
        await this.clearStoredAuth();
      }
    }
  }

  async forceLogout(): Promise<void> {
    try {
      console.log('🚨 AuthService: Force logout - clearing all data');
      
      // Clear memory immediately
      this.token = null;
      this.user = null;
      
      // Clear all AsyncStorage items
      const keysToRemove = [
        'auth_token',
        'auth_user',
        'user_data',
        'user_start_date'
      ];
      
      await Promise.all(keysToRemove.map(key => AsyncStorage.removeItem(key)));
      
      console.log('✅ AuthService: Force logout completed');
    } catch (error) {
      console.error('❌ AuthService: Error during force logout:', error);
      // Even if clearing fails, reset memory state
      this.token = null;
      this.user = null;
    }
  }
}

export const authService = new AuthService();
export default authService;
