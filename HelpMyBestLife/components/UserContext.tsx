import React, { createContext, useContext, useState, ReactNode, useEffect, useRef, useMemo, useCallback } from 'react';
import { View, Text, Platform } from 'react-native';
import AsyncStorage from '@react-native-async-storage/async-storage';
import authService from '@/services/authService';

// Fallback for AsyncStorage if it fails to load
const safeAsyncStorage = {
  getItem: async (key: string): Promise<string | null> => {
    try {
      // Check if we're in a browser environment
      if (typeof window === 'undefined') {
        return null;
      }
      return await AsyncStorage.getItem(key);
    } catch (error) {
      console.error('AsyncStorage getItem error:', error);
      return null;
    }
  },
  setItem: async (key: string, value: string): Promise<void> => {
    try {
      // Check if we're in a browser environment
      if (typeof window === 'undefined') {
        return;
      }
      await AsyncStorage.setItem(key, value);
    } catch (error) {
      console.error('AsyncStorage setItem error:', error);
      throw error;
    }
  },
  removeItem: async (key: string): Promise<void> => {
    try {
      // Check if we're in a browser environment
      if (typeof window === 'undefined') {
        return;
      }
      await AsyncStorage.removeItem(key);
    } catch (error) {
      console.error('AsyncStorage removeItem error:', error);
    }
  }
};

export type User = {
  id: string;
  name: string;
  username: string;
  email: string;
  phone: string;
  profilePic: string;
  dailyCP: number;
  lifetimeCP: number;
  cpByCategory: { mind: number; body: number; soul: number };
  daysActive: number;
  trends: number[];
  isLoggedIn: boolean;
  startDate: string;
  lastActiveDate: string;
  isOnline?: boolean;
  lastSeen?: string;
};

const DEFAULT_USER: User = {
  id: '1',
  name: 'My Best Life',
  username: 'mybestlife',
  email: 'help@mybestlife.com',
  phone: '+1 555-123-4567',
  profilePic: '',
  dailyCP: 0,
  lifetimeCP: 0,
  cpByCategory: { mind: 0, body: 0, soul: 0 },
  daysActive: 1,
  trends: [0, 0, 0, 0, 0, 0, 0],
  isLoggedIn: false,
  startDate: new Date().toISOString().slice(0, 10),
  lastActiveDate: new Date().toISOString().slice(0, 10),
};

type UserContextType = {
  user: User;
  setUserState: (u: User) => void;
  updateUser: (fields: Partial<User>) => void;
  refreshUserData: () => void;
  updateCPData: (dailyCP: number, lifetimeCP: number, cpByCategory: { mind: number; body: number; soul: number }) => void;
  logout: () => Promise<void>;
  forceLogout: () => Promise<void>;
  testStateUpdate: () => void;
  triggerForceUpdate: () => void;
  login: (email: string, password: string) => Promise<User>;
  register: (name: string, username: string, email: string, password: string) => Promise<User>;
  isLoading: boolean;
  isAuthenticated: boolean;
  checkAuthStatus: () => Promise<void>;
  checkAuthImmediate: () => boolean;
};

const UserContext = createContext<UserContextType | undefined>(undefined);

export function useUser() {
  const ctx = useContext(UserContext);
  if (!ctx) throw new Error('useUser must be used within UserProvider');
  return ctx;
}

function getDaysSinceStart(startDate: string): number {
  const start = new Date(startDate);
  const today = new Date();
  const diffTime = Math.abs(today.getTime() - start.getTime());
  const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
  return Math.max(1, diffDays);
}

const USER_KEY = 'user_data';
const START_DATE_KEY = 'user_start_date';

export function UserProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User>(DEFAULT_USER);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const isUpdating = useRef(false);
  const saveTimeoutRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const isLoadingRef = useRef(false);

  console.log('UserProvider rendering, isLoading:', isLoading, 'error:', error, 'isAuthenticated:', isAuthenticated);
  
  // Create a safe setUser function that prevents multiple simultaneous updates
  const setUserState = useCallback((newUser: User) => {
    console.log('setUserState called with:', newUser);
    if (isUpdating.current) {
      console.warn('User update already in progress, skipping');
      return;
    }
    isUpdating.current = true;
    try {
      setUser(newUser);
    } finally {
      isUpdating.current = false;
    }
  }, []);

  // Debounced save function to prevent rapid successive saves
  const debouncedSave = useCallback((userData: User) => {
    if (saveTimeoutRef.current) {
      clearTimeout(saveTimeoutRef.current);
    }
    saveTimeoutRef.current = setTimeout(async () => {
      try {
        await saveUserData(userData);
      } catch (error) {
        console.error('Error in debounced save:', error);
      }
    }, 100);
  }, []);

  // Load user data from AsyncStorage and check authentication status
  useEffect(() => {
    // Only run on client side
    if (typeof window === 'undefined') {
      setIsLoading(false);
      return;
    }
    
    // Add a small delay for web to ensure proper hydration
    const timer = setTimeout(() => {
      checkAuthStatus().catch(err => {
        console.error('Failed to check auth status:', err);
        setError(err.message);
        setIsLoading(false);
      });
    }, Platform.OS === 'web' ? 200 : 0);
    
    return () => clearTimeout(timer);

    // Cleanup function to clear timeout on unmount
    return () => {
      if (saveTimeoutRef.current) {
        clearTimeout(saveTimeoutRef.current);
      }
    };
  }, []); // Empty dependency array to run only once

  // Debug: Monitor state changes
  useEffect(() => {
    console.log('🔍 UserContext state changed:', { 
      isAuthenticated, 
      isLoading, 
      userId: user.id,
      isLoggedIn: user.isLoggedIn 
    });
  }, [isAuthenticated, isLoading, user.id, user.isLoggedIn]);

  // Debug: Monitor logout specifically
  useEffect(() => {
    if (!isAuthenticated && user.id === DEFAULT_USER.id) {
      console.log('🚨 LOGOUT DETECTED: User is now logged out');
    }
  }, [isAuthenticated, user.id]);

  const checkAuthStatus = useCallback(async () => {
    try {
      const token = await authService.getToken();
      if (token) {
        // Try to get user profile from backend
        const profile = await authService.getProfile();
        if (profile) {
          const authenticatedUser: User = {
            id: profile._id,
            name: profile.name,
            username: profile.username,
            email: profile.email,
            phone: '', // Backend doesn't have phone field
            profilePic: profile.profilePic || '',
            dailyCP: profile.dailyCP || 0,
            lifetimeCP: profile.lifetimeCP || 0,
            cpByCategory: profile.cpByCategory || { mind: 0, body: 0, soul: 0 },
            daysActive: profile.daysActive || 1,
            trends: [0, 0, 0, 0, 0, 0, 0], // Backend doesn't have trends field
            isLoggedIn: true,
            startDate: profile.startDate || new Date().toISOString().slice(0, 10),
            lastActiveDate: profile.lastActiveDate || new Date().toISOString().slice(0, 10),
            isOnline: profile.isOnline || false,
            lastSeen: profile.lastSeen || new Date().toISOString(),
          };
          setUserState(authenticatedUser);
          setIsAuthenticated(true);
          await saveUserData(authenticatedUser);
        } else {
          // Token exists but profile fetch failed, clear auth locally
          console.log('❌ Profile fetch failed, clearing local auth');
          await authService.clearStoredAuth();
          setUserState(DEFAULT_USER);
          setIsAuthenticated(false);
        }
      } else {
        // No token, load local user data if available
        await loadUserData();
      }
    } catch (error) {
      console.error('Error checking auth status:', error);
      // If there's an error, try to load local data
      await loadUserData();
    } finally {
      setIsLoading(false);
    }
  }, [setUserState]);

  const loadUserData = useCallback(async () => {
    if (isLoadingRef.current) {
      console.log('loadUserData already in progress, skipping');
      return;
    }
    
    isLoadingRef.current = true;
    try {
      const userStr = await safeAsyncStorage.getItem(USER_KEY);
      if (userStr) {
        const savedUser = JSON.parse(userStr);
        // Validate the saved user data
        if (savedUser && typeof savedUser === 'object' && savedUser.id) {
          setUserState(savedUser);
        } else {
          console.warn('Invalid user data found, using default');
          setUserState(DEFAULT_USER);
        }
      }
    } catch (e) {
      console.error('Error loading user data:', e);
      setUserState(DEFAULT_USER);
    } finally {
      setIsLoading(false);
      isLoadingRef.current = false;
    }
  }, [setUserState]);

  // Save user data to AsyncStorage
  const saveUserData = useCallback(async (userData: User) => {
    try {
      console.log('Attempting to save user data:', userData);
      const userDataString = JSON.stringify(userData);
      console.log('Serialized user data:', userDataString);
      await safeAsyncStorage.setItem(USER_KEY, userDataString);
      console.log('User data saved successfully');
    } catch (e) {
      console.error('Error saving user data:', e);
      throw e; // Re-throw to handle in calling function
    }
  }, []);

  const updateUser = useCallback((fields: Partial<User>) => {
    const updatedUser = { ...user, ...fields };
    setUserState(updatedUser);
    debouncedSave(updatedUser);
  }, [user, setUserState, debouncedSave]);

  const updateCPData = useCallback((dailyCP: number, lifetimeCP: number, cpByCategory: { mind: number; body: number; soul: number }) => {
    const daysActive = getDaysSinceStart(user.startDate);
    const updatedUser = {
      ...user,
      dailyCP,
      lifetimeCP,
      cpByCategory,
      daysActive,
      lastActiveDate: new Date().toISOString().slice(0, 10),
    };
    setUserState(updatedUser);
    debouncedSave(updatedUser);
  }, [user, setUserState, debouncedSave]);

  const logout = useCallback(async () => {
    try {
      console.log('🔄 Starting logout process...');
      
      // Call backend logout endpoint
      if (isAuthenticated) {
        try {
          await authService.logout();
        } catch (backendError) {
          console.warn('⚠️ Backend logout failed, continuing with local logout:', backendError);
        }
      }
      
      // Clear all authentication data immediately
      await authService.forceLogout();
      
      // Clear commitment data for current user
      if (user?.id) {
        const commitmentKeys = [
          `commitment_completed_${user.id}`,
          `commitment_lastResetDate_${user.id}`,
          `commitment_lifetimeCP_${user.id}`,
          `commitment_startDate_${user.id}`,
        ];
        await Promise.all(commitmentKeys.map(key => safeAsyncStorage.removeItem(key)));
      }
      
      // Reset state immediately and synchronously
      const loggedOutUser = {
        ...DEFAULT_USER,
        isLoggedIn: false,
      };
      
      // Update both states in the same render cycle
      setUserState(loggedOutUser);
      setIsAuthenticated(false);
      
      console.log('✅ Logout completed successfully');
      
    } catch (error) {
      console.error('❌ Error during logout:', error);
      // Even if there's an error, clear local state
      const loggedOutUser = {
        ...DEFAULT_USER,
        isLoggedIn: false,
      };
      setUserState(loggedOutUser);
      setIsAuthenticated(false);
    }
  }, [setUserState, isAuthenticated, user?.id]);

  const login = useCallback(async (email: string, password: string) => {
    try {
      console.log('Login attempt with email:', email);
      
      // Call backend login
      const response = await authService.login({ email, password });
      
      if (response.user && response.token) {
        const loggedInUser: User = {
          id: response.user._id,
          name: response.user.name,
          username: response.user.username,
          email: response.user.email,
          phone: '', // Backend doesn't have phone field
          profilePic: response.user.profilePic || '',
          dailyCP: response.user.dailyCP || 0,
          lifetimeCP: response.user.lifetimeCP || 0,
          cpByCategory: response.user.cpByCategory || { mind: 0, body: 0, soul: 0 },
          daysActive: response.user.daysActive || 1,
          trends: [0, 0, 0, 0, 0, 0, 0], // Backend doesn't have trends field
          isLoggedIn: true,
          startDate: response.user.startDate || new Date().toISOString().slice(0, 10),
          lastActiveDate: response.user.lastActiveDate || new Date().toISOString().slice(0, 10),
          isOnline: response.user.isOnline || true,
          lastSeen: response.user.lastSeen || new Date().toISOString(),
        };
        
        console.log('Created authenticated user object:', loggedInUser);
        
        // Save to AsyncStorage first
        await saveUserData(loggedInUser);
        console.log('User data saved to AsyncStorage');
        
        // Then update state
        setUserState(loggedInUser);
        setIsAuthenticated(true);
        console.log('User state updated and authenticated');
        
        return loggedInUser;
      } else {
        throw new Error('Invalid login response');
      }
    } catch (error) {
      console.error('Error during login:', error);
      throw error;
    }
  }, [saveUserData, setUserState]);

  const register = useCallback(async (name: string, username: string, email: string, password: string) => {
    try {
      console.log('Registration attempt for:', { name, username, email });
      
      // Call backend register
      const response = await authService.register({ name, username, email, password });
      
      if (response.user && response.token) {
        const newUser: User = {
          id: response.user._id,
          name: response.user.name,
          username: response.user.username,
          email: response.user.email,
          phone: '', // Backend doesn't have phone field
          profilePic: response.user.profilePic || '',
          dailyCP: response.user.dailyCP || 0,
          lifetimeCP: response.user.lifetimeCP || 0,
          cpByCategory: response.user.cpByCategory || { mind: 0, body: 0, soul: 0 },
          daysActive: response.user.daysActive || 1,
          trends: [0, 0, 0, 0, 0, 0, 0], // Backend doesn't have trends field
          isLoggedIn: true,
          startDate: response.user.startDate || new Date().toISOString().slice(0, 10),
          lastActiveDate: response.user.lastActiveDate || new Date().toISOString().slice(0, 10),
          isOnline: response.user.isOnline || true,
          lastSeen: response.user.lastSeen || new Date().toISOString(),
        };
        
        setUserState(newUser);
        setIsAuthenticated(true);
        await saveUserData(newUser);
        return newUser;
      } else {
        throw new Error('Invalid registration response');
      }
    } catch (error) {
      console.error('Error during registration:', error);
      throw error;
    }
  }, [saveUserData, setUserState]);

  const refreshUserData = useCallback(() => {
    if (!isLoadingRef.current && !isLoading) {
      loadUserData();
    }
  }, [loadUserData, isLoading, isLoadingRef.current]);

  // Check if user is authenticated without async operations
  const checkAuthImmediate = useCallback(() => {
    return isAuthenticated && user.isLoggedIn && user.id !== DEFAULT_USER.id;
  }, [isAuthenticated, user.isLoggedIn, user.id]);

  const forceLogout = useCallback(async () => {
    try {
      console.log('🚨 FORCE LOGOUT: Bypassing normal logout flow');
      
      // Clear all AsyncStorage immediately
      const allKeys = [
        'auth_token',
        'auth_user',
        'user_data',
        'user_start_date'
      ];
      
      await Promise.all(allKeys.map(key => safeAsyncStorage.removeItem(key)));
      console.log('✅ All AsyncStorage cleared');
      
      // Reset state immediately
      const loggedOutUser = {
        ...DEFAULT_USER,
        isLoggedIn: false,
      };
      
      setUserState(loggedOutUser);
      setIsAuthenticated(false);
      
      console.log('✅ Force logout completed');
      
    } catch (error) {
      console.error('❌ Force logout error:', error);
      // Even if there's an error, reset state
      const loggedOutUser = {
        ...DEFAULT_USER,
        isLoggedIn: false,
      };
      setUserState(loggedOutUser);
      setIsAuthenticated(false);
    }
  }, [setUserState]);

  const testStateUpdate = useCallback(() => {
    console.log('🧪 Testing state update...');
    console.log('🧪 Before update - isAuthenticated:', isAuthenticated, 'user.id:', user.id);
    
    // Try to force a state update
    setIsAuthenticated(false);
    setUserState({
      ...DEFAULT_USER,
      isLoggedIn: false,
      id: 'test-' + Date.now()
    });
    
    console.log('🧪 After update - state should be updated');
  }, [isAuthenticated, user.id]);

  // Force update mechanism
  const [forceUpdate, setForceUpdate] = useState(0);
  const triggerForceUpdate = useCallback(() => {
    console.log('🔄 Triggering force update...');
    setForceUpdate(prev => prev + 1);
  }, []);

  // Create context values unconditionally - this fixes the hooks violation
  const fallbackValue = useMemo(() => ({
    user: DEFAULT_USER,
    setUserState,
    updateUser,
    refreshUserData,
    updateCPData,
    logout,
    forceLogout,
    testStateUpdate,
    triggerForceUpdate,
    login,
    register,
    isLoading,
    isAuthenticated: false,
    checkAuthStatus,
    checkAuthImmediate,
  }), [setUserState, updateUser, refreshUserData, updateCPData, logout, forceLogout, testStateUpdate, triggerForceUpdate, login, register, isLoading, checkAuthStatus, checkAuthImmediate]);

  const contextValue = useMemo(() => ({
    user,
    setUserState,
    updateUser,
    refreshUserData,
    updateCPData,
    logout,
    forceLogout,
    testStateUpdate,
    triggerForceUpdate,
    login,
    register,
    isLoading,
    isAuthenticated,
    checkAuthStatus,
    checkAuthImmediate,
  }), [user, setUserState, updateUser, refreshUserData, updateCPData, logout, forceLogout, testStateUpdate, triggerForceUpdate, login, register, isLoading, isAuthenticated, checkAuthStatus, checkAuthImmediate]);

  // Don't render children until user data is loaded
  if (isLoading) {
    return (
      <View style={{ flex: 1, justifyContent: 'center', alignItems: 'center', backgroundColor: '#111' }}>
        <Text style={{ color: '#fff' }}>Loading...</Text>
      </View>
    );
  }

  // If there's an error, show error state with fallback context
  if (error) {
    console.error('UserProvider error:', error);
    return (
      <UserContext.Provider value={fallbackValue}>
        {children}
      </UserContext.Provider>
    );
  }

  return (
    <UserContext.Provider value={contextValue}>
      {children}
    </UserContext.Provider>
  );
} 