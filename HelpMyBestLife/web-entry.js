import { registerRootComponent } from 'expo';
import { Platform } from 'react-native';
import App from './App';

// Web-specific entry point to prevent hydration issues
if (Platform.OS === 'web') {
  // Ensure DOM is ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => {
      registerRootComponent(App);
    });
  } else {
    registerRootComponent(App);
  }
} else {
  registerRootComponent(App);
}
