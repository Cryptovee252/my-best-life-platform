import { Tabs } from 'expo-router';
import { Ionicons, MaterialCommunityIcons, FontAwesome } from '@expo/vector-icons';
import { Platform } from 'react-native';

export default function TabsLayout() {
  return (
    <Tabs
      screenOptions={{
        headerShown: false,
        tabBarShowLabel: false,
        tabBarStyle: { 
          backgroundColor: '#111', 
          borderTopColor: '#222', 
          height: Platform.OS === 'ios' ? 80 : 60 
        },
        tabBarActiveTintColor: '#2ecc40',
        tabBarInactiveTintColor: '#fff',
      }}
    >
      <Tabs.Screen
        name="index"
        options={{
          title: 'Dashboard',
          tabBarIcon: ({ color, size, focused }) => (
            <MaterialCommunityIcons 
              name="view-dashboard" 
              size={size} 
              color={focused ? '#2ecc40' : '#fff'} 
            />
          ),
        }}
      />
      <Tabs.Screen
        name="stories"
        options={{
          title: 'Stories',
          tabBarIcon: ({ color, size, focused }) => (
            <MaterialCommunityIcons 
              name="newspaper-variant-outline" 
              size={size} 
              color={focused ? '#2ecc40' : '#fff'} 
            />
          ),
        }}
      />
      <Tabs.Screen
        name="groups"
        options={{
          title: 'Groups',
          tabBarIcon: ({ color, size, focused }) => (
            <Ionicons 
              name="people" 
              size={size} 
              color={focused ? '#2ecc40' : '#fff'} 
            />
          ),
        }}
      />
      <Tabs.Screen
        name="notifications"
        options={{
          title: 'Notifications',
          tabBarIcon: ({ color, size, focused }) => (
            <Ionicons 
              name="notifications-outline" 
              size={size} 
              color={focused ? '#2ecc40' : '#fff'} 
            />
          ),
        }}
      />
      <Tabs.Screen
        name="profile"
        options={{
          title: 'Profile',
          tabBarIcon: ({ color, size, focused }) => (
            <FontAwesome 
              name="user-o" 
              size={size} 
              color={focused ? '#2ecc40' : '#fff'} 
            />
          ),
        }}
      />
      <Tabs.Screen
        name="settings"
        options={{
          title: 'Settings',
          tabBarIcon: ({ color, size, focused }) => (
            <Ionicons 
              name="settings-outline" 
              size={size} 
              color={focused ? '#2ecc40' : '#fff'} 
            />
          ),
        }}
      />
    </Tabs>
  );
}
