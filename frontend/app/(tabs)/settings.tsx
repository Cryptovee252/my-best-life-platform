import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  Switch,
  ScrollView,
  Alert,
  Platform,
} from 'react-native';
import { Ionicons, MaterialCommunityIcons } from '@expo/vector-icons';
import { useUser } from '@/components/UserContext';

export default function SettingsScreen() {
  const { logout, user, isAuthenticated } = useUser();
  const [notificationsEnabled, setNotificationsEnabled] = useState(true);
  const [emailNotifications, setEmailNotifications] = useState(true);
  const [pushNotifications, setPushNotifications] = useState(true);
  const [profilePrivate, setProfilePrivate] = useState(false);
  const [darkMode, setDarkMode] = useState(true);

  // Handlers
  const handleLogout = async () => {
    console.log('🔐 Settings handleLogout called!');
    console.log('🔐 Current user context:', { user: user?.id, isAuthenticated });
    
    Alert.alert('Logout', 'Are you sure you want to log out?', [
      { text: 'Cancel', style: 'cancel' },
      { 
        text: 'Logout', 
        style: 'destructive', 
        onPress: async () => {
          console.log('🔐 User confirmed logout, calling logout()...');
          try {
            await logout();
            console.log('🔐 Logout completed successfully');
            // AuthGuard will automatically redirect to login
          } catch (error) {
            console.error('❌ Logout error:', error);
            Alert.alert('Error', 'Failed to logout. Please try again.');
          }
        }
      },
    ]);
  };

  return (
    <ScrollView style={{ flex: 1, backgroundColor: '#111' }} contentContainerStyle={{ paddingBottom: 40 }}>
      <Text style={styles.header}>Settings</Text>

      {/* Account Section */}
      <Text style={styles.sectionTitle}>Account</Text>
      <View style={styles.sectionBox}>
        <TouchableOpacity style={styles.row} onPress={() => {/* TODO: Change password */}}>
          <MaterialCommunityIcons name="lock-reset" size={22} color="#2ecc40" style={styles.icon} />
          <Text style={styles.rowLabel}>Change Password</Text>
        </TouchableOpacity>
        <TouchableOpacity style={styles.row} onPress={() => {/* TODO: Change email */}}>
          <MaterialCommunityIcons name="email-edit-outline" size={22} color="#2ecc40" style={styles.icon} />
          <Text style={styles.rowLabel}>Change Email</Text>
        </TouchableOpacity>
        <TouchableOpacity style={styles.row} onPress={() => {/* TODO: Change phone */}}>
          <MaterialCommunityIcons name="cellphone-cog" size={22} color="#2ecc40" style={styles.icon} />
          <Text style={styles.rowLabel}>Change Phone</Text>
        </TouchableOpacity>
      </View>

      {/* Notifications Section */}
      <Text style={styles.sectionTitle}>Notifications</Text>
      <View style={styles.sectionBox}>
        <View style={styles.row}>
          <Ionicons name="notifications-outline" size={22} color="#2ecc40" style={styles.icon} />
          <Text style={styles.rowLabel}>Enable Notifications</Text>
          <Switch
            value={notificationsEnabled}
            onValueChange={setNotificationsEnabled}
            thumbColor={notificationsEnabled ? '#2ecc40' : '#888'}
            trackColor={{ true: '#2ecc40', false: '#444' }}
            style={styles.switch}
          />
        </View>
        <View style={styles.row}>
          <MaterialCommunityIcons name="email-outline" size={22} color="#2ecc40" style={styles.icon} />
          <Text style={styles.rowLabel}>Email Notifications</Text>
          <Switch
            value={emailNotifications}
            onValueChange={setEmailNotifications}
            thumbColor={emailNotifications ? '#2ecc40' : '#888'}
            trackColor={{ true: '#2ecc40', false: '#444' }}
            style={styles.switch}
          />
        </View>
        <View style={styles.row}>
          <MaterialCommunityIcons name="bell-ring-outline" size={22} color="#2ecc40" style={styles.icon} />
          <Text style={styles.rowLabel}>Push Notifications</Text>
          <Switch
            value={pushNotifications}
            onValueChange={setPushNotifications}
            thumbColor={pushNotifications ? '#2ecc40' : '#888'}
            trackColor={{ true: '#2ecc40', false: '#444' }}
            style={styles.switch}
          />
        </View>
      </View>

      {/* Privacy Section */}
      <Text style={styles.sectionTitle}>Privacy</Text>
      <View style={styles.sectionBox}>
        <View style={styles.row}>
          <MaterialCommunityIcons name="account-lock-outline" size={22} color="#2ecc40" style={styles.icon} />
          <Text style={styles.rowLabel}>Private Profile</Text>
          <Switch
            value={profilePrivate}
            onValueChange={setProfilePrivate}
            thumbColor={profilePrivate ? '#2ecc40' : '#888'}
            trackColor={{ true: '#2ecc40', false: '#444' }}
            style={styles.switch}
          />
        </View>
      </View>

      {/* Appearance Section */}
      <Text style={styles.sectionTitle}>Appearance</Text>
      <View style={styles.sectionBox}>
        <View style={styles.row}>
          <Ionicons name={darkMode ? 'moon' : 'sunny'} size={22} color="#2ecc40" style={styles.icon} />
          <Text style={styles.rowLabel}>Dark Mode</Text>
          <Switch
            value={darkMode}
            onValueChange={setDarkMode}
            thumbColor={darkMode ? '#2ecc40' : '#888'}
            trackColor={{ true: '#2ecc40', false: '#444' }}
            style={styles.switch}
          />
        </View>
      </View>

      {/* App Info Section */}
      <Text style={styles.sectionTitle}>App Info</Text>
      <View style={styles.sectionBox}>
        <View style={styles.row}>
          <Ionicons name="information-circle-outline" size={22} color="#2ecc40" style={styles.icon} />
          <Text style={styles.rowLabel}>Version</Text>
          <Text style={styles.rowValue}>1.0.0</Text>
        </View>
        <TouchableOpacity style={styles.row} onPress={() => {/* TODO: Open terms */}}>
          <MaterialCommunityIcons name="file-document-outline" size={22} color="#2ecc40" style={styles.icon} />
          <Text style={styles.rowLabel}>Terms of Service</Text>
        </TouchableOpacity>
        <TouchableOpacity style={styles.row} onPress={() => {/* TODO: Open privacy policy */}}>
          <MaterialCommunityIcons name="shield-lock-outline" size={22} color="#2ecc40" style={styles.icon} />
          <Text style={styles.rowLabel}>Privacy Policy</Text>
        </TouchableOpacity>
      </View>

      {/* Logout */}
      <TouchableOpacity 
        style={styles.logoutBtn} 
        onPress={() => {
          console.log('🔘 Settings logout button pressed!');
          Alert.alert('Test', 'Settings logout button was pressed!');
          handleLogout();
        }}
      >
        <Ionicons name="log-out-outline" size={22} color="#fff" style={styles.icon} />
        <Text style={styles.logoutText}>Logout</Text>
      </TouchableOpacity>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  header: {
    color: '#fff',
    fontSize: 32,
    fontWeight: 'bold',
    marginTop: Platform.OS === 'ios' ? 60 : 36,
    marginBottom: 18,
    marginLeft: 24,
  },
  sectionTitle: {
    color: '#aaa',
    fontSize: 16,
    fontWeight: 'bold',
    marginTop: 18,
    marginBottom: 6,
    marginLeft: 24,
  },
  sectionBox: {
    backgroundColor: '#181818',
    borderRadius: 14,
    marginHorizontal: 16,
    marginBottom: 8,
    padding: 8,
  },
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 12,
    paddingHorizontal: 8,
    borderBottomWidth: 1,
    borderBottomColor: '#222',
  },
  rowLabel: {
    color: '#fff',
    fontSize: 16,
    flex: 1,
    marginLeft: 10,
  },
  rowValue: {
    color: '#aaa',
    fontSize: 15,
    marginRight: 8,
  },
  icon: {
    marginRight: 2,
  },
  switch: {
    marginLeft: 8,
  },
  logoutBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: '#ff4136',
    borderRadius: 12,
    margin: 24,
    paddingVertical: 14,
  },
  logoutText: {
    color: '#fff',
    fontSize: 18,
    fontWeight: 'bold',
    marginLeft: 8,
  },
}); 