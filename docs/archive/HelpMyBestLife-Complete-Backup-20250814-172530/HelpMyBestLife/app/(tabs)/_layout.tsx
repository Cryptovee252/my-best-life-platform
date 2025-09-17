import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import { Ionicons, MaterialCommunityIcons, FontAwesome } from '@expo/vector-icons';
import DashboardScreen from './index';
import StoriesScreen from './stories';
import GroupsScreen from './groups';
import NotificationsScreen from './notifications';
import ProfileScreen from './profile';
import SettingsScreen from './settings';
import { Platform } from 'react-native';
import * as React from 'react';
import { GestureHandlerRootView } from 'react-native-gesture-handler';

const Tab = createBottomTabNavigator();

export default function TabsLayout() {
  return (
    <GestureHandlerRootView style={{ flex: 1 }}>
      <Tab.Navigator
        screenOptions={({ route }) => ({
          headerShown: false,
          tabBarShowLabel: false,
          tabBarStyle: { backgroundColor: '#111', borderTopColor: '#222', height: Platform.OS === 'ios' ? 80 : 60 },
          tabBarIcon: ({ color, size, focused }) => {
            if (route.name === 'Dashboard') {
              return <MaterialCommunityIcons name="view-dashboard" size={size} color={focused ? '#2ecc40' : '#fff'} />;
            } else if (route.name === 'Stories') {
              return <MaterialCommunityIcons name="newspaper-variant-outline" size={size} color={focused ? '#2ecc40' : '#fff'} />;
            } else if (route.name === 'Groups') {
              return <Ionicons name="people" size={size} color={focused ? '#2ecc40' : '#fff'} />;
            } else if (route.name === 'Notifications') {
              return <Ionicons name="notifications-outline" size={size} color={focused ? '#2ecc40' : '#fff'} />;
            } else if (route.name === 'Profile') {
              return <FontAwesome name="user-o" size={size} color={focused ? '#2ecc40' : '#fff'} />;
            } else if (route.name === 'Settings') {
              return <Ionicons name="settings-outline" size={size} color={focused ? '#2ecc40' : '#fff'} />;
            }
            return null;
          },
        })}
      >
        <Tab.Screen name="Dashboard" component={DashboardScreen} />
        <Tab.Screen name="Stories" component={StoriesScreen} />
        <Tab.Screen name="Groups" component={GroupsScreen} />
        <Tab.Screen name="Notifications" component={NotificationsScreen} />
        <Tab.Screen name="Profile" component={ProfileScreen} />
        <Tab.Screen name="Settings" component={SettingsScreen} />
      </Tab.Navigator>
    </GestureHandlerRootView>
  );
}
