import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TextInput,
  TouchableOpacity,
  ScrollView,
  Alert,
  ActivityIndicator,
  KeyboardAvoidingView,
  Platform,
} from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { useRouter } from 'expo-router';
import { LinearGradient } from 'expo-linear-gradient';
import { Ionicons } from '@expo/vector-icons';
import { authService, RegisterCredentials } from '@/services/authService';
import { useUser } from '@/components/UserContext';

export default function RegisterScreen() {
  const insets = useSafeAreaInsets();
  const router = useRouter();
  const { register } = useUser();
  
  const [credentials, setCredentials] = useState<RegisterCredentials>({
    name: '',
    username: '',
    email: '',
    password: '',
  });
  
  const [confirmPassword, setConfirmPassword] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [isTestingConnection, setIsTestingConnection] = useState(false);
  const [showPassword, setShowPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);
  const [errors, setErrors] = useState<Partial<RegisterCredentials & { confirmPassword: string }>>({});
  const [isCheckingUsername, setIsCheckingUsername] = useState(false);

  const validateForm = (): boolean => {
    const newErrors: Partial<RegisterCredentials & { confirmPassword: string }> = {};

    // Name validation
    if (!credentials.name.trim()) {
      newErrors.name = 'Name is required';
    } else if (credentials.name.length < 2) {
      newErrors.name = 'Name must be at least 2 characters';
    } else if (credentials.name.length > 50) {
      newErrors.name = 'Name must be less than 50 characters';
    }

    // Username validation
    if (!credentials.username.trim()) {
      newErrors.username = 'Username is required';
    } else if (credentials.username.length < 3) {
      newErrors.username = 'Username must be at least 3 characters';
    } else if (credentials.username.length > 30) {
      newErrors.username = 'Username must be less than 30 characters';
    } else if (!/^[a-zA-Z0-9_]+$/.test(credentials.username)) {
      newErrors.username = 'Username can only contain letters, numbers, and underscores';
    }

    // Email validation
    if (!credentials.email.trim()) {
      newErrors.email = 'Email is required';
    } else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(credentials.email)) {
      newErrors.email = 'Please enter a valid email address';
    }

    // Password validation
    if (!credentials.password) {
      newErrors.password = 'Password is required';
    } else if (credentials.password.length < 6) {
      newErrors.password = 'Password must be at least 6 characters';
    }

    // Confirm password validation
    if (!confirmPassword) {
      newErrors.confirmPassword = 'Please confirm your password';
    } else if (credentials.password !== confirmPassword) {
      newErrors.confirmPassword = 'Passwords do not match';
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const checkUsernameAvailability = async (username: string) => {
    if (username.length < 3) return;
    
    setIsCheckingUsername(true);
    try {
      const isAvailable = await authService.checkUsername(username);
      if (!isAvailable) {
        setErrors(prev => ({ ...prev, username: 'Username is already taken' }));
      } else {
        setErrors(prev => ({ ...prev, username: undefined }));
      }
    } catch (error) {
      console.error('Error checking username:', error);
    } finally {
      setIsCheckingUsername(false);
    }
  };

  const handleRegister = async () => {
    if (!validateForm()) return;

    setIsLoading(true);
    try {
      const response = await authService.register(credentials);
      
      if (response.success) {
        Alert.alert('Success', 'Account created successfully! Please log in.', [
          { text: 'OK', onPress: () => router.replace('/auth/login') }
        ]);
      }
    } catch (error: any) {
      Alert.alert('Registration Failed', error.message || 'An error occurred during registration');
    } finally {
      setIsLoading(false);
    }
  };

  const testConnection = async () => {
    setIsTestingConnection(true);
    try {
      const isConnected = await authService.testConnection();
      if (isConnected) {
        Alert.alert('Connection Test', '✅ Backend is accessible!');
      } else {
        Alert.alert('Connection Test', '❌ Cannot connect to backend. Check if it\'s running.');
      }
    } catch (error) {
      Alert.alert('Connection Test', '❌ Connection test failed');
    } finally {
      setIsTestingConnection(false);
    }
  };

  const handleInputChange = (field: keyof RegisterCredentials, value: string) => {
    setCredentials(prev => ({ ...prev, [field]: value }));
    
    // Clear error when user starts typing
    if (errors[field]) {
      setErrors(prev => ({ ...prev, [field]: undefined }));
    }
    
    // Check username availability when username changes
    if (field === 'username') {
      checkUsernameAvailability(value);
    }
  };

  const handleConfirmPasswordChange = (value: string) => {
    setConfirmPassword(value);
    if (errors.confirmPassword) {
      setErrors(prev => ({ ...prev, confirmPassword: undefined }));
    }
  };

  return (
    <KeyboardAvoidingView 
      style={styles.container} 
      behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
    >
      <LinearGradient
        colors={['#1a1a2e', '#16213e', '#0f3460']}
        style={[styles.backgroundGradient, { paddingTop: insets.top }]}
      >
        <ScrollView 
          contentContainerStyle={styles.scrollContent}
          showsVerticalScrollIndicator={false}
        >
          {/* Header */}
          <View style={styles.header}>
            <TouchableOpacity
              style={styles.backButton}
              onPress={() => router.back()}
            >
              <Ionicons name="arrow-back" size={24} color="#fff" />
            </TouchableOpacity>
            
            <View style={styles.logoContainer}>
              <Text style={styles.logoText}>MBL</Text>
              <Text style={styles.logoSubtext}>My Best Life</Text>
            </View>
          </View>

          {/* Main Content */}
          <View style={styles.content}>
            <Text style={styles.title}>Create Account</Text>
            <Text style={styles.subtitle}>Start your journey to a better life</Text>

            {/* Registration Form */}
            <View style={styles.form}>
              {/* Name Input */}
              <View style={styles.inputContainer}>
                <View style={styles.inputIcon}>
                  <Ionicons name="person" size={20} color="#666" />
                </View>
                <TextInput
                  style={[styles.input, errors.name ? styles.inputError : null]}
                  placeholder="Full Name"
                  placeholderTextColor="#666"
                  value={credentials.name}
                  onChangeText={(value) => handleInputChange('name', value)}
                  autoCapitalize="words"
                  autoCorrect={false}
                />
              </View>
              {errors.name && <Text style={styles.errorText}>{errors.name}</Text>}

              {/* Username Input */}
              <View style={styles.inputContainer}>
                <View style={styles.inputIcon}>
                  <Ionicons name="at" size={20} color="#666" />
                </View>
                <TextInput
                  style={[styles.input, errors.username ? styles.inputError : null]}
                  placeholder="Username"
                  placeholderTextColor="#666"
                  value={credentials.username}
                  onChangeText={(value) => handleInputChange('username', value)}
                  autoCapitalize="none"
                  autoCorrect={false}
                />
                {isCheckingUsername && (
                  <View style={styles.checkingIndicator}>
                    <ActivityIndicator size="small" color="#2ecc40" />
                  </View>
                )}
              </View>
              {errors.username && <Text style={styles.errorText}>{errors.username}</Text>}

              {/* Email Input */}
              <View style={styles.inputContainer}>
                <View style={styles.inputIcon}>
                  <Ionicons name="mail" size={20} color="#666" />
                </View>
                <TextInput
                  style={[styles.input, errors.email ? styles.inputError : null]}
                  placeholder="Email Address"
                  placeholderTextColor="#666"
                  value={credentials.email}
                  onChangeText={(value) => handleInputChange('email', value)}
                  keyboardType="email-address"
                  autoCapitalize="none"
                  autoCorrect={false}
                />
              </View>
              {errors.email && <Text style={styles.errorText}>{errors.email}</Text>}

              {/* Password Input */}
              <View style={styles.inputContainer}>
                <View style={styles.inputIcon}>
                  <Ionicons name="lock-closed" size={20} color="#666" />
                </View>
                <TextInput
                  style={[styles.input, errors.password ? styles.inputError : null]}
                  placeholder="Password"
                  placeholderTextColor="#666"
                  value={credentials.password}
                  onChangeText={(value) => handleInputChange('password', value)}
                  secureTextEntry={!showPassword}
                  autoCapitalize="none"
                />
                <TouchableOpacity
                  style={styles.passwordToggle}
                  onPress={() => setShowPassword(!showPassword)}
                >
                  <Ionicons 
                    name={showPassword ? "eye-off" : "eye"} 
                    size={20} 
                    color="#666" 
                  />
                </TouchableOpacity>
              </View>
              {errors.password && <Text style={styles.errorText}>{errors.password}</Text>}

              {/* Confirm Password Input */}
              <View style={styles.inputContainer}>
                <View style={styles.inputIcon}>
                  <Ionicons name="lock-closed" size={20} color="#666" />
                </View>
                <TextInput
                  style={[styles.input, errors.confirmPassword ? styles.inputError : null]}
                  placeholder="Confirm Password"
                  placeholderTextColor="#666"
                  value={confirmPassword}
                  onChangeText={handleConfirmPasswordChange}
                  secureTextEntry={!showConfirmPassword}
                  autoCapitalize="none"
                />
                <TouchableOpacity
                  style={styles.passwordToggle}
                  onPress={() => setShowConfirmPassword(!showConfirmPassword)}
                >
                  <Ionicons 
                    name={showConfirmPassword ? "eye-off" : "eye"} 
                    size={20} 
                    color="#666" 
                  />
                </TouchableOpacity>
              </View>
              {errors.confirmPassword && <Text style={styles.errorText}>{errors.confirmPassword}</Text>}

              {/* Register Button */}
              <TouchableOpacity
                style={[styles.registerButton, isLoading ? styles.registerButtonDisabled : null]}
                onPress={handleRegister}
                disabled={isLoading}
              >
                {isLoading ? (
                  <ActivityIndicator color="#fff" size="small" />
                ) : (
                  <Text style={styles.registerButtonText}>Create Account</Text>
                )}
              </TouchableOpacity>

              {/* Connection Test Button */}
              <TouchableOpacity
                style={[styles.testButton, isTestingConnection && styles.disabledButton]}
                onPress={testConnection}
                disabled={isTestingConnection}
              >
                {isTestingConnection ? (
                  <Text style={styles.testButtonText}>Testing...</Text>
                ) : (
                  <Text style={styles.testButtonText}>Test Backend Connection</Text>
                )}
              </TouchableOpacity>

              {/* Divider */}
              <View style={styles.divider}>
                <View style={styles.dividerLine} />
                <Text style={styles.dividerText}>OR</Text>
                <View style={styles.dividerLine} />
              </View>

              {/* Login Link */}
              <View style={styles.loginContainer}>
                <Text style={styles.loginText}>Already have an account? </Text>
                <TouchableOpacity onPress={() => router.push('/auth/login')}>
                  <Text style={styles.loginLink}>Sign In</Text>
                </TouchableOpacity>
              </View>
            </View>
          </View>
        </ScrollView>
      </LinearGradient>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  backgroundGradient: {
    flex: 1,
  },
  scrollContent: {
    flexGrow: 1,
    paddingBottom: 40,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 20,
    paddingVertical: 20,
  },
  backButton: {
    padding: 8,
    borderRadius: 20,
    backgroundColor: 'rgba(255, 255, 255, 0.1)',
  },
  logoContainer: {
    flex: 1,
    alignItems: 'center',
    marginRight: 40,
  },
  logoText: {
    fontSize: 28,
    fontWeight: 'bold',
    color: '#2ecc40',
    letterSpacing: 2,
  },
  logoSubtext: {
    fontSize: 12,
    color: '#aaa',
    marginTop: 2,
  },
  content: {
    flex: 1,
    paddingHorizontal: 30,
    paddingTop: 20,
  },
  title: {
    fontSize: 32,
    fontWeight: 'bold',
    color: '#fff',
    textAlign: 'center',
    marginBottom: 10,
  },
  subtitle: {
    fontSize: 16,
    color: '#aaa',
    textAlign: 'center',
    marginBottom: 30,
  },
  form: {
    marginBottom: 30,
  },
  inputContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: 'rgba(255, 255, 255, 0.1)',
    borderRadius: 12,
    marginBottom: 20,
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.1)',
  },
  inputIcon: {
    paddingHorizontal: 15,
  },
  input: {
    flex: 1,
    color: '#fff',
    fontSize: 16,
    paddingVertical: 18,
    paddingHorizontal: 10,
  },
  inputError: {
    borderColor: '#ff4136',
    borderWidth: 1,
  },
  passwordToggle: {
    paddingHorizontal: 15,
  },
  checkingIndicator: {
    paddingHorizontal: 15,
  },
  errorText: {
    color: '#ff4136',
    fontSize: 14,
    marginTop: -15,
    marginBottom: 15,
    marginLeft: 15,
  },
  registerButton: {
    backgroundColor: '#2ecc40',
    borderRadius: 12,
    paddingVertical: 18,
    alignItems: 'center',
    marginTop: 10,
    shadowColor: '#2ecc40',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.3,
    shadowRadius: 8,
    elevation: 8,
  },
  registerButtonDisabled: {
    backgroundColor: '#666',
    shadowOpacity: 0,
    elevation: 0,
  },
  registerButtonText: {
    color: '#fff',
    fontSize: 18,
    fontWeight: 'bold',
  },
  testButton: {
    backgroundColor: '#007bff',
    borderRadius: 12,
    paddingVertical: 18,
    alignItems: 'center',
    marginTop: 10,
    shadowColor: '#007bff',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.3,
    shadowRadius: 8,
    elevation: 8,
  },
  testButtonText: {
    color: '#fff',
    fontSize: 18,
    fontWeight: 'bold',
  },
  disabledButton: {
    backgroundColor: '#666',
    shadowOpacity: 0,
    elevation: 0,
  },
  divider: {
    flexDirection: 'row',
    alignItems: 'center',
    marginVertical: 30,
  },
  dividerLine: {
    flex: 1,
    height: 1,
    backgroundColor: 'rgba(255, 255, 255, 0.2)',
  },
  dividerText: {
    color: '#aaa',
    fontSize: 14,
    marginHorizontal: 20,
  },
  loginContainer: {
    flexDirection: 'row',
    justifyContent: 'center',
    alignItems: 'center',
  },
  loginText: {
    color: '#aaa',
    fontSize: 16,
  },
  loginLink: {
    color: '#2ecc40',
    fontSize: 16,
    fontWeight: 'bold',
    textDecorationLine: 'underline',
  },
});
