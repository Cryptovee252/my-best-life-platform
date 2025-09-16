import { Redirect } from 'expo-router';

export default function Index() {
  // This will be handled by AuthGuard
  // If authenticated, redirect to tabs
  // If not authenticated, redirect to login
  return <Redirect href="/(tabs)" />;
}
