import React, { useEffect } from 'react';
import { useRouter, useSegments } from 'expo-router';
import { useUser } from './UserContext';

// Authentication guard component
export function AuthGuard({ children }: { children: React.ReactNode }) {
  const { isAuthenticated, isLoading } = useUser();
  const segments = useSegments();
  const router = useRouter();

  console.log('🔒 AuthGuard render:', { isAuthenticated, isLoading, segments });

  useEffect(() => {
    console.log('🔒 AuthGuard effect running:', { isAuthenticated, isLoading, segments });
    
    if (isLoading) {
      console.log('⏳ AuthGuard: Still loading, skipping redirect');
      return; // Don't redirect while loading
    }

    const inAuthGroup = segments[0] === 'auth';
    console.log('📍 AuthGuard: Current location:', { inAuthGroup, segments });
    
    if (!isAuthenticated && !inAuthGroup) {
      // Redirect to login if not authenticated and not already in auth group
      console.log('🚨 AuthGuard: User not authenticated, redirecting to login');
      console.log('🚨 AuthGuard: Current segments:', segments);
      console.log('🚨 AuthGuard: isAuthenticated:', isAuthenticated);
      
      // Force navigation to login
      router.replace('/auth/login');
      return;
    }

    if (isAuthenticated && inAuthGroup) {
      // Redirect to main app if authenticated and in auth group
      console.log('✅ AuthGuard: User authenticated, redirecting to main app');
      router.replace('/(tabs)');
      return;
    }

    console.log('✅ AuthGuard: No redirect needed');
  }, [isAuthenticated, isLoading, segments, router]);

  // Add a debug effect to monitor state changes
  useEffect(() => {
    console.log('🔍 AuthGuard state monitor:', { 
      isAuthenticated, 
      isLoading, 
      segments: segments.join('/'),
      timestamp: new Date().toISOString()
    });
  }, [isAuthenticated, isLoading, segments]);

  return <>{children}</>;
}
