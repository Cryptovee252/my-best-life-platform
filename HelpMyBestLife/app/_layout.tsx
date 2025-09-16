import FontAwesome from '@expo/vector-icons/FontAwesome';
import { DarkTheme, DefaultTheme, ThemeProvider } from '@react-navigation/native';
import { useFonts } from 'expo-font';
import { Stack } from 'expo-router';
import * as SplashScreen from 'expo-splash-screen';
import { useEffect } from 'react';
import 'react-native-reanimated';
import { SafeAreaProvider } from 'react-native-safe-area-context';

import { useColorScheme } from '@/components/useColorScheme';
import { CommitmentProvider } from '@/components/CommitmentContext';
import { GroupProvider } from '@/components/GroupContext';
import { NotificationProvider } from '@/components/NotificationContext';
import { UserProvider } from '@/components/UserContext';
import { AuthGuard } from '@/components/AuthGuard';
import { ErrorBoundary } from '@/components/ErrorBoundary';

export {
  // Catch any errors thrown by the Layout component.
  ErrorBoundary,
} from 'expo-router';

export const unstable_settings = {
  // Ensure that reloading on `/modal` keeps a back button present.
  initialRouteName: 'index',
};

// Prevent the splash screen from auto-hiding before asset loading is complete.
SplashScreen.preventAutoHideAsync();

export default function RootLayout() {
  const [loaded, error] = useFonts({
    SpaceMono: require('../assets/fonts/SpaceMono-Regular.ttf'),
    ...FontAwesome.font,
  });

  // Expo Router uses Error Boundaries to catch errors in the navigation tree.
  useEffect(() => {
    if (error) throw error;
  }, [error]);

  useEffect(() => {
    if (loaded) {
      SplashScreen.hideAsync();
    }
  }, [loaded]);

  if (!loaded) {
    return null;
  }

  return (
    <SafeAreaProvider>
      <UserProvider>
        <NotificationProvider>
          <GroupProvider>
            <CommitmentProvider>
              <AuthGuard>
                <RootLayoutNav />
              </AuthGuard>
            </CommitmentProvider>
          </GroupProvider>
        </NotificationProvider>
      </UserProvider>
    </SafeAreaProvider>
  );
}

function RootLayoutNav() {
  const colorScheme = useColorScheme();

  return (
    <ThemeProvider value={colorScheme === 'dark' ? DarkTheme : DefaultTheme}>
      <ErrorBoundary>
        <Stack>
          <Stack.Screen name="(tabs)" options={{ headerShown: false }} />
          <Stack.Screen name="auth" options={{ headerShown: false }} />
          <Stack.Screen name="mind" options={{ title: 'Mind' }} />
          <Stack.Screen name="body" options={{ title: 'Body' }} />
          <Stack.Screen name="soul" options={{ title: 'Soul' }} />
          <Stack.Screen name="modal" options={{ presentation: 'modal' }} />
          <Stack.Screen name="group" options={{ headerShown: false }} />
        </Stack>
      </ErrorBoundary>
    </ThemeProvider>
  );
}
