import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TextInput,
  TouchableOpacity,
  Image,
  ScrollView,
  Alert,
  KeyboardAvoidingView,
  Platform,
} from 'react-native';
import { useRouter } from 'expo-router';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { useUser } from '@/components/UserContext';
import { useNotification } from '@/components/NotificationContext';

export default function LoginScreen() {
  const insets = useSafeAreaInsets();
  const router = useRouter();
  const { login } = useUser();
  const { addNotification } = useNotification();
  
  const [formData, setFormData] = useState({
    email: '',
    password: '',
  });
  const [loading, setLoading] = useState(false);

  const handleLogin = async () => {
    // Validate form data
    if (!formData.email.trim()) {
      Alert.alert('Error', 'Please enter your email');
      return;
    }
    if (!formData.password) {
      Alert.alert('Error', 'Please enter your password');
      return;
    }

    // Basic email validation
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(formData.email.trim())) {
      Alert.alert('Error', 'Please enter a valid email address');
      return;
    }

    setLoading(true);
    
    try {
      // Simulate login process
      await new Promise(resolve => setTimeout(resolve, 1000));
      
      console.log('Attempting to login with:', formData.email);
      
      // Use the login function from UserContext with proper error handling
      const loginResult = await login({
        name: formData.email.split('@')[0], // Use email prefix as name
        email: formData.email.trim(),
      });
      
      console.log('Login result:', loginResult);
      
      if (loginResult && loginResult.isLoggedIn) {
        addNotification('Welcome back to HelpMyBestLife!', 'success');
        
        // Navigate to main app after successful login
        console.log('Navigating to main app...');
        router.replace('/(tabs)');
      } else {
        throw new Error('Login failed - user not properly logged in');
      }
    } catch (error) {
      console.error('Login error:', error);
      Alert.alert('Error', 'Something went wrong during login. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  const handleRegister = () => {
    router.push('/register');
  };

  const handleForgotPassword = () => {
    Alert.alert('Forgot Password', 'Password reset functionality will be implemented soon.');
  };

  return (
    <KeyboardAvoidingView 
      style={[styles.container, { paddingTop: insets.top }]} 
      behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
    >
      <ScrollView contentContainerStyle={styles.scrollContent} showsVerticalScrollIndicator={false}>
        {/* Logo and Header */}
        <View style={styles.header}>
          <Image 
            source={require('@/assets/images/MBL_Logo.webp')} 
            style={styles.logo}
            resizeMode="contain"
          />
          <Text style={styles.appName}>HelpMyBestLife</Text>
          <Text style={styles.tagline}>Welcome back to your journey</Text>
        </View>

        {/* Login Form */}
        <View style={styles.formContainer}>
          <Text style={styles.formTitle}>Sign In</Text>
          
          <TextInput
            style={styles.input}
            placeholder="Email Address"
            placeholderTextColor="#aaa"
            value={formData.email}
            onChangeText={(text) => setFormData({ ...formData, email: text })}
            keyboardType="email-address"
            autoCapitalize="none"
            autoComplete="email"
          />
          
          <TextInput
            style={styles.input}
            placeholder="Password"
            placeholderTextColor="#aaa"
            value={formData.password}
            onChangeText={(text) => setFormData({ ...formData, password: text })}
            secureTextEntry
            autoComplete="password"
          />

          <TouchableOpacity style={styles.forgotPasswordBtn} onPress={handleForgotPassword}>
            <Text style={styles.forgotPasswordText}>Forgot Password?</Text>
          </TouchableOpacity>

          <TouchableOpacity
            style={[styles.loginBtn, loading && styles.loginBtnDisabled]}
            onPress={handleLogin}
            disabled={loading}
          >
            <Text style={styles.loginBtnText}>
              {loading ? 'Signing In...' : 'Sign In'}
            </Text>
          </TouchableOpacity>

          <View style={styles.divider}>
            <View style={styles.dividerLine} />
            <Text style={styles.dividerText}>or</Text>
            <View style={styles.dividerLine} />
          </View>

          <TouchableOpacity style={styles.registerBtn} onPress={handleRegister}>
            <Text style={styles.registerBtnText}>Don't have an account? Sign Up</Text>
          </TouchableOpacity>
        </View>

        {/* Quick Features */}
        <View style={styles.featuresContainer}>
          <Text style={styles.featuresTitle}>Continue your journey:</Text>
          <View style={styles.featureItem}>
            <Text style={styles.featureIcon}>📈</Text>
            <Text style={styles.featureText}>Track your daily progress</Text>
          </View>
          <View style={styles.featureItem}>
            <Text style={styles.featureIcon}>🎯</Text>
            <Text style={styles.featureText}>Complete today's tasks</Text>
          </View>
          <View style={styles.featureItem}>
            <Text style={styles.featureIcon}>⚖️</Text>
            <Text style={styles.featureText}>Check your equilibrium balance</Text>
          </View>
          <View style={styles.featureItem}>
            <Text style={styles.featureIcon}>👥</Text>
            <Text style={styles.featureText}>Connect with your groups</Text>
          </View>
        </View>
      </ScrollView>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#111',
  },
  scrollContent: {
    flexGrow: 1,
    paddingBottom: 40,
  },
  header: {
    alignItems: 'center',
    paddingVertical: 40,
    paddingHorizontal: 20,
  },
  logo: {
    width: 120,
    height: 120,
    marginBottom: 16,
  },
  appName: {
    color: '#fff',
    fontSize: 28,
    fontWeight: 'bold',
    marginBottom: 8,
  },
  tagline: {
    color: '#aaa',
    fontSize: 16,
    textAlign: 'center',
    maxWidth: 280,
  },
  formContainer: {
    paddingHorizontal: 20,
    marginBottom: 30,
  },
  formTitle: {
    color: '#fff',
    fontSize: 24,
    fontWeight: 'bold',
    marginBottom: 24,
    textAlign: 'center',
  },
  input: {
    backgroundColor: '#222',
    color: '#fff',
    borderRadius: 12,
    padding: 16,
    marginBottom: 16,
    fontSize: 16,
    borderWidth: 1,
    borderColor: '#333',
  },
  forgotPasswordBtn: {
    alignSelf: 'flex-end',
    marginBottom: 24,
  },
  forgotPasswordText: {
    color: '#2ecc40',
    fontSize: 14,
    textDecorationLine: 'underline',
  },
  loginBtn: {
    backgroundColor: '#2ecc40',
    borderRadius: 12,
    paddingVertical: 16,
    alignItems: 'center',
    marginBottom: 24,
  },
  loginBtnDisabled: {
    backgroundColor: '#1a8a2a',
  },
  loginBtnText: {
    color: '#fff',
    fontSize: 18,
    fontWeight: 'bold',
  },
  divider: {
    flexDirection: 'row',
    alignItems: 'center',
    marginVertical: 20,
  },
  dividerLine: {
    flex: 1,
    height: 1,
    backgroundColor: '#333',
  },
  dividerText: {
    color: '#aaa',
    marginHorizontal: 16,
    fontSize: 14,
  },
  registerBtn: {
    alignItems: 'center',
    paddingVertical: 12,
  },
  registerBtnText: {
    color: '#2ecc40',
    fontSize: 16,
    textDecorationLine: 'underline',
  },
  featuresContainer: {
    paddingHorizontal: 20,
    marginTop: 20,
  },
  featuresTitle: {
    color: '#fff',
    fontSize: 20,
    fontWeight: 'bold',
    marginBottom: 16,
    textAlign: 'center',
  },
  featureItem: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 12,
    paddingHorizontal: 20,
  },
  featureIcon: {
    fontSize: 24,
    marginRight: 12,
  },
  featureText: {
    color: '#fff',
    fontSize: 16,
    flex: 1,
  },
});
