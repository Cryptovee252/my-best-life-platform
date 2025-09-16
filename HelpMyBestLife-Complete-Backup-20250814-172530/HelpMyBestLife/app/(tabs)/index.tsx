import React, { useState, useEffect, useMemo } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  Modal,
  TextInput,
  Image,
  Dimensions,
  Animated,
  Alert,
} from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { useRouter } from 'expo-router';
import { LinearGradient } from 'expo-linear-gradient';
import { Ionicons, MaterialCommunityIcons, FontAwesome5 } from '@expo/vector-icons';
import { useCommitment } from '@/components/CommitmentContext';
import { useGroup } from '@/components/GroupContext';
import { useNotification } from '@/components/NotificationContext';
import { useUser } from '@/components/UserContext';
import groupService from '@/services/groupService';

const { width, height } = Dimensions.get('window');

export default function DashboardScreen() {
  const insets = useSafeAreaInsets();
  const router = useRouter();
  const { getCP, getLifetimeCP } = useCommitment();
  const { groups, setCurrentGroup, joinGroup, createGroup } = useGroup();
  const { notifications, markAsRead, clearAll, addNotification } = useNotification();
  const { user, logout, forceLogout, testStateUpdate, triggerForceUpdate, isAuthenticated } = useUser();
  
  const [showCreateGroup, setShowCreateGroup] = useState(false);
  const [newGroupName, setNewGroupName] = useState('');
  const [showJoinGroup, setShowJoinGroup] = useState(false);
  const [joinGroupCode, setJoinGroupCode] = useState('');
  const [showNotifications, setShowNotifications] = useState(false);
  const [showProfile, setShowProfile] = useState(false);
  const [fadeAnim] = useState(new Animated.Value(0));
  const [slideAnim] = useState(new Animated.Value(50));
  const [hideEquilibrium, setHideEquilibrium] = useState(false);
  const [hideProgress, setHideProgress] = useState(false);
  const [hideGroups, setHideGroups] = useState(false);
  const [showTodayProgress, setShowTodayProgress] = useState(true);
  const [selectedGroup, setSelectedGroup] = useState<any | null>(null);

  // Debug: Monitor context changes
  useEffect(() => {
    console.log('🔍 Dashboard: Context changed:', { 
      isAuthenticated, 
      userId: user?.id, 
      isLoggedIn: user?.isLoggedIn,
      timestamp: new Date().toISOString()
    });
  }, [isAuthenticated, user?.id, user?.isLoggedIn]);

  const unreadCount = notifications.filter(n => !n.read).length;

  // Calculate equilibrium data using useMemo to avoid recalculating on every render
  const equilibriumData = useMemo(() => {
    try {
      const mindCP = user?.cpByCategory?.mind || 0;
      const bodyCP = user?.cpByCategory?.body || 0;
      const soulCP = user?.cpByCategory?.soul || 0;
      const total = mindCP + bodyCP + soulCP || 1;
      
      // Calculate percentages with goal of 33.33% each for balanced living
      const mindPercent = Math.round((mindCP / total) * 100);
      const bodyPercent = Math.round((bodyCP / total) * 100);
      const soulPercent = Math.round((soulCP / total) * 100);
      
      // Determine recommendation based on gaps
      let recommendation = '';
      let recommendationColor = '#2ecc40';
      
      if (mindPercent < 25 && bodyPercent < 25 && soulPercent < 25) {
        recommendation = 'Start with any category to begin your journey!';
        recommendationColor = '#2ecc40';
      } else if (mindPercent < 25) {
        recommendation = 'Focus on mind tasks to boost mental wellness';
        recommendationColor = '#2ecc40';
      } else if (bodyPercent < 25) {
        recommendation = 'Prioritize body tasks for physical health';
        recommendationColor = '#0074d9';
      } else if (soulPercent < 25) {
        recommendation = 'Nurture your soul with spiritual activities';
        recommendationColor = '#ff4136';
      } else if (mindPercent > 45) {
        recommendation = 'Great mental balance! Try body or soul tasks';
        recommendationColor = '#0074d9';
      } else if (bodyPercent > 45) {
        recommendation = 'Excellent physical health! Balance with mind/soul';
        recommendationColor = '#2ecc40';
      } else if (soulPercent > 45) {
        recommendation = 'Strong spiritual foundation! Add mind/body tasks';
        recommendationColor = '#2ecc40';
      } else {
        recommendation = 'Well balanced! Keep up the great work';
        recommendationColor = '#2ecc40';
      }
      
      return [
        { label: 'MIND', value: mindCP, percent: mindPercent, color: '#2ecc40', icon: 'brain' },
        { label: 'BODY', value: bodyCP, percent: bodyPercent, color: '#0074d9', icon: 'dumbbell' },
        { label: 'SOUL', value: soulCP, percent: soulPercent, color: '#ff4136', icon: 'heart' },
        { recommendation, recommendationColor }
      ];
    } catch (error) {
      console.error('Error calculating equilibrium data:', error);
      return [
        { label: 'MIND', value: 0, percent: 0, color: '#2ecc40', icon: 'brain' },
        { label: 'BODY', value: 0, percent: 0, color: '#0074d9', icon: 'dumbbell' },
        { label: 'SOUL', value: 0, percent: 0, color: '#ff4136', icon: 'heart' },
        { recommendation: 'Start your journey with any category!', recommendationColor: '#2ecc40' }
      ];
    }
  }, [user?.cpByCategory?.mind, user?.cpByCategory?.body, user?.cpByCategory?.soul]);

  // Calculate commitment category data using useMemo to avoid hooks violations
  const commitmentCategoriesData = useMemo(() => {
    return (['mind', 'body', 'soul'] as const).map((category) => {
      const color = category === 'mind' ? '#2ecc40' : category === 'body' ? '#0074d9' : '#ff4136';
      const dailyCP = getCP(category);
      const lifetimeCP = getLifetimeCP(category);
      const icon = category === 'mind' ? 'brain' : category === 'body' ? 'dumbbell' : 'heart';
      
      return {
        category,
        color,
        dailyCP,
        lifetimeCP,
        icon
      };
    });
  }, [getCP, getLifetimeCP]);

  useEffect(() => {
    Animated.parallel([
      Animated.timing(fadeAnim, {
        toValue: 1,
        duration: 1000,
        useNativeDriver: true,
      }),
      Animated.timing(slideAnim, {
        toValue: 0,
        duration: 800,
        useNativeDriver: true,
      }),
    ]).start();
  }, []);

  const handleLogout = async () => {
    console.log('🔐 Dashboard handleLogout called!');
    console.log('🔐 Current user context:', { user: user?.id, isAuthenticated });
    
    Alert.alert(
      'Logout',
      'Are you sure you want to logout?',
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Logout',
          style: 'destructive',
          onPress: async () => {
            console.log('🔐 User confirmed logout, calling logout()...');
            try {
              await logout();
              console.log('🔐 Logout completed successfully');
              console.log('🔐 Post-logout state check:', { user: user?.id, isAuthenticated });
              addNotification('Logged out successfully', 'success');
              // AuthGuard will automatically redirect to login
            } catch (error) {
              console.error('❌ Logout error:', error);
              addNotification('Error during logout', 'error');
            }
          },
        },
      ]
    );
  };

  const renderEquilibriumCircle = (data: any) => (
    <TouchableOpacity
      key={data.label}
      style={styles.equilibriumItem}
      onPress={() => {
        addNotification(`${data.label}: ${data.value} lifetime CP`, 'success');
      }}
    >
      <View style={[styles.progressCircle, { borderColor: data.color }]}>
        {/* Percentage indicator ring around the circle */}
        <View style={[styles.percentageRing, { borderColor: data.color }]}>
          <Text style={[styles.percentageText, { color: data.color }]}>{data.percent}%</Text>
        </View>
      </View>
      <Text style={styles.equilibriumLabel}>{data.label}</Text>
      <Text style={styles.equilibriumValue}>{data.value} CP</Text>
    </TouchableOpacity>
  );

  return (
    <View style={[styles.container, { paddingTop: insets.top }]}>
      <LinearGradient
        colors={['#1a1a2e', '#16213e', '#0f3460']}
        style={styles.backgroundGradient}
      />
      
      <Animated.View
        style={[
          styles.content,
          {
            opacity: fadeAnim,
            transform: [{ translateY: slideAnim }],
          },
        ]}
      >
        {/* Header */}
        <View style={styles.header}>
          <View style={styles.headerLeft}>
            <Image
              source={user.profilePic ? { uri: user.profilePic } : require('@/assets/images/MBL_Logo.webp')}
              style={styles.profileImage}
            />
            <View style={styles.userInfo}>
              <Text style={styles.userName}>{user?.name || 'User'}</Text>
              <Text style={styles.userStats}>
                Daily: <Text style={styles.highlight}>{user?.dailyCP || 0}</Text> | 
                Lifetime: <Text style={styles.highlight}>{user?.lifetimeCP || 0}</Text>
              </Text>
              <Text style={styles.activeDays}>Active for {user?.daysActive || 1} days</Text>
            </View>
          </View>
          
          <View style={styles.headerRight}>
            <TouchableOpacity
              style={styles.notificationButton}
              onPress={() => setShowNotifications(true)}
            >
              <Ionicons name="notifications" size={24} color="#fff" />
              {unreadCount > 0 && (
                <View style={styles.badge}>
                  <Text style={styles.badgeText}>{unreadCount}</Text>
                </View>
              )}
            </TouchableOpacity>
            
            <TouchableOpacity
              style={styles.settingsButton}
              onPress={() => setShowProfile(true)}
            >
              <Ionicons name="settings" size={24} color="#fff" />
            </TouchableOpacity>
          </View>
        </View>

        <ScrollView showsVerticalScrollIndicator={false} style={styles.scrollView}>
          {/* Equilibrium Section */}
          <View style={styles.section}>
            <TouchableOpacity 
              style={styles.sectionHeader}
              onPress={() => setHideEquilibrium(!hideEquilibrium)}
            >
              <View style={styles.sectionHeaderLeft}>
                <Text style={styles.sectionTitle}>Equilibrium Balance</Text>
                <Text style={styles.sectionSubtitle}>Your life balance across categories</Text>
              </View>
              <Ionicons 
                name={hideEquilibrium ? "chevron-down" : "chevron-up"} 
                size={20} 
                color="#aaa" 
              />
            </TouchableOpacity>
            
            {!hideEquilibrium && (
              <View style={styles.equilibriumWrapper}>
                <View style={styles.equilibriumContainer}>
                  {equilibriumData.slice(0, 3).map(renderEquilibriumCircle)}
                </View>
                {/* Recommendation on the far right */}
                <View style={styles.recommendationSidebar}>
                  <Text style={[styles.recommendationTitle, { color: equilibriumData[3]?.recommendationColor || '#2ecc40' }]}>
                    💡 Recommendation
                  </Text>
                  <Text style={[styles.recommendationText, { color: equilibriumData[3]?.recommendationColor || '#2ecc40' }]}>
                    {equilibriumData[3]?.recommendation || 'Keep striving for balance!'}
                  </Text>
                  <View style={styles.goalIndicator}>
                    <Text style={styles.goalText}>
                      🎯 Goal: 33% each
                    </Text>
                  </View>
                </View>
              </View>
            )}
          </View>

          {/* Quick Stats */}
          {showTodayProgress && (
            <View style={styles.section}>
              <TouchableOpacity 
                style={styles.sectionHeader}
                onPress={() => setShowTodayProgress(false)}
              >
                <View style={styles.sectionHeaderLeft}>
                  <Text style={styles.sectionTitle}>Today's Progress</Text>
                </View>
                <Ionicons 
                  name="chevron-up" 
                  size={20} 
                  color="#aaa" 
                />
              </TouchableOpacity>
              
              <View style={styles.statsContainer}>
                <View style={styles.statCard}>
                  <MaterialCommunityIcons name="target" size={18} color="#2ecc40" />
                  <Text style={styles.statValue}>{user.dailyCP}</Text>
                  <Text style={styles.statLabel}>Daily CP</Text>
                </View>
                <View style={styles.statCard}>
                  <MaterialCommunityIcons name="trophy" size={18} color="#ffd700" />
                  <Text style={styles.statValue}>{user.lifetimeCP}</Text>
                  <Text style={styles.statLabel}>Lifetime CP</Text>
                </View>
                <View style={styles.statCard}>
                  <MaterialCommunityIcons name="calendar" size={18} color="#0074d9" />
                  <Text style={styles.statValue}>{user.daysActive}</Text>
                  <Text style={styles.statLabel}>Days Active</Text>
                </View>
              </View>
            </View>
          )}

          {/* Groups Section */}
          <View style={styles.section}>
            <TouchableOpacity 
              style={styles.sectionHeader}
              onPress={() => setHideGroups(!hideGroups)}
            >
              <View style={styles.sectionHeaderLeft}>
                <Text style={styles.sectionTitle}>My Groups</Text>
              </View>
              <View style={styles.sectionHeaderRight}>
                <TouchableOpacity 
                  style={styles.addButton}
                  onPress={() => setShowCreateGroup(true)}
                >
                  <Ionicons name="add-circle" size={18} color="#2ecc40" />
                </TouchableOpacity>
                <Ionicons 
                  name={hideGroups ? "chevron-down" : "chevron-up"} 
                  size={20} 
                  color="#aaa" 
                />
              </View>
            </TouchableOpacity>
            
            {!hideGroups && (
              <ScrollView horizontal showsHorizontalScrollIndicator={false} style={styles.groupsContainer}>
                {groups.map((group) => (
                  <TouchableOpacity
                    key={group.id}
                    style={styles.groupCard}
                    onPress={() => {
                      setCurrentGroup(group.id);
                      router.push(`/group/${group.id}`);
                    }}
                  >
                    <LinearGradient
                      colors={['#2ecc40', '#27ae60']}
                      style={styles.groupGradient}
                    >
                      <Image source={require('@/assets/images/MBL_Logo.webp')} style={styles.groupIcon} />
                    </LinearGradient>
                    <Text style={styles.groupName}>{group.name}</Text>
                  </TouchableOpacity>
                ))}
                <TouchableOpacity style={styles.addGroupCard} onPress={() => setShowJoinGroup(true)}>
                  <Ionicons name="people" size={20} color="#2ecc40" />
                  <Text style={styles.addGroupText}>Join Group</Text>
                </TouchableOpacity>
              </ScrollView>
            )}
          </View>

          {/* Commitment Categories */}
          <View style={styles.section}>
            <View style={styles.sectionHeader}>
              <Text style={styles.sectionTitle}>Commitment Categories</Text>
            </View>
            {commitmentCategoriesData.map((category) => (
              <TouchableOpacity
                key={category.category}
                style={[styles.commitmentCard, { borderLeftColor: category.color }]}
                onPress={() => {
                  router.push('/' + category.category as '/mind' | '/body' | '/soul');
                }}
              >
                <LinearGradient
                  colors={[category.color + '20', category.color + '10']}
                  style={styles.commitmentGradient}
                >
                  <FontAwesome5 name={category.icon} size={20} color={category.color} />
                </LinearGradient>
                <View style={styles.commitmentContent}>
                  <Text style={[styles.commitmentLabel, { color: category.color }]}>
                    {category.category.charAt(0).toUpperCase() + category.category.slice(1)}
                  </Text>
                  <Text style={styles.commitmentPoints}>
                    Daily: {category.dailyCP} | Lifetime: {category.lifetimeCP}
                  </Text>
                </View>
                <Ionicons name="chevron-forward" size={20} color="#aaa" />
              </TouchableOpacity>
            ))}
          </View>
        </ScrollView>
      </Animated.View>

      {/* Modals */}
      <Modal visible={showCreateGroup} transparent animationType="slide">
        <View style={styles.modalOverlay}>
          <View style={styles.modalContent}>
            <Text style={styles.modalTitle}>Create New Group</Text>
            <TextInput
              style={styles.modalInput}
              placeholder="Group Name"
              placeholderTextColor="#aaa"
              value={newGroupName}
              onChangeText={setNewGroupName}
            />
            <View style={styles.modalButtons}>
              <TouchableOpacity
                style={[styles.modalButton, styles.cancelButton]}
                onPress={() => setShowCreateGroup(false)}
              >
                <Text style={styles.cancelButtonText}>Cancel</Text>
              </TouchableOpacity>
              <TouchableOpacity
                style={[styles.modalButton, styles.confirmButton]}
                onPress={async () => {
                  if (newGroupName.trim()) {
                    try {
                      // Create group using backend service for persistence
                      const newGroup = await groupService.createGroup({
                        name: newGroupName,
                        description: `Group created by ${user.name}`,
                        category: 'mixed',
                        isPrivate: false,
                        maxMembers: 100
                      });
                      
                      // Add to local context for immediate UI update
                      const newMember = {
                        id: user.id,
                        name: user.name,
                        groupCP: { mind: 0, body: 0, soul: 0 },
                      };
                      createGroup(newGroup.id, newGroup.name, user.id, newMember);
                      
                      setCurrentGroup(newGroup.id);
                      setShowCreateGroup(false);
                      setNewGroupName('');
                      addNotification(`Created group: ${newGroupName}`, 'success');
                      
                      // Navigate to the new group
                      router.push(`/group/${newGroup.id}`);
                    } catch (error) {
                      console.error('Error creating group:', error);
                      addNotification(`Failed to create group: ${error instanceof Error ? error.message : 'Unknown error'}`, 'error');
                    }
                  }
                }}
              >
                <Text style={styles.confirmButtonText}>Create</Text>
              </TouchableOpacity>
            </View>
          </View>
        </View>
      </Modal>

      <Modal visible={showJoinGroup} transparent animationType="slide">
        <View style={styles.modalOverlay}>
          <View style={styles.modalContent}>
            <Text style={styles.modalTitle}>Join Group</Text>
            <TextInput
              style={styles.modalInput}
              placeholder="Enter Group Code"
              placeholderTextColor="#aaa"
              value={joinGroupCode}
              onChangeText={setJoinGroupCode}
            />
            <View style={styles.modalButtons}>
              <TouchableOpacity
                style={[styles.modalButton, styles.cancelButton]}
                onPress={() => setShowJoinGroup(false)}
              >
                <Text style={styles.cancelButtonText}>Cancel</Text>
              </TouchableOpacity>
              <TouchableOpacity
                style={[styles.modalButton, styles.confirmButton]}
                onPress={() => {
                  if (joinGroupCode.trim()) {
                    joinGroup(joinGroupCode, {
                      id: user.id,
                      name: user.name,
                      groupCP: { mind: 0, body: 0, soul: 0 },
                    });
                    setCurrentGroup(joinGroupCode);
                    setShowJoinGroup(false);
                    setJoinGroupCode('');
                    const joinedGroup = groups.find(g => g.id === joinGroupCode);
                    addNotification(`Joined: ${joinedGroup ? joinedGroup.name : 'group'}`, 'success');
                    router.push(`/group/${joinGroupCode}`);
                  }
                }}
              >
                <Text style={styles.confirmButtonText}>Join</Text>
              </TouchableOpacity>
            </View>
          </View>
        </View>
      </Modal>

      <Modal visible={showNotifications} transparent animationType="fade">
        <View style={styles.modalOverlay}>
          <View style={[styles.modalContent, { maxHeight: height * 0.7 }]}>
            <Text style={styles.modalTitle}>Notifications</Text>
            <ScrollView style={styles.notificationsList}>
              {notifications.length === 0 ? (
                <Text style={styles.emptyText}>No notifications yet.</Text>
              ) : (
                notifications.map((n) => (
                  <TouchableOpacity
                    key={n.id}
                    style={[styles.notificationItem, n.read ? {} : { backgroundColor: '#2ecc4020' }]}
                    onPress={() => markAsRead(n.id)}
                  >
                    <Text style={[styles.notificationText, { color: n.type === 'error' ? '#ff4136' : n.type === 'success' ? '#2ecc40' : '#fff' }]}>
                      {n.message}
                    </Text>
                    <Text style={styles.notificationTime}>
                      {new Date(n.timestamp).toLocaleString()}
                    </Text>
                  </TouchableOpacity>
                ))
              )}
            </ScrollView>
            <View style={styles.modalButtons}>
              <TouchableOpacity
                style={[styles.modalButton, styles.cancelButton]}
                onPress={() => notifications.forEach(n => markAsRead(n.id))}
              >
                <Text style={styles.cancelButtonText}>Mark All Read</Text>
              </TouchableOpacity>
              <TouchableOpacity
                style={[styles.modalButton, styles.confirmButton]}
                onPress={clearAll}
              >
                <Text style={styles.confirmButtonText}>Clear All</Text>
              </TouchableOpacity>
            </View>
            <TouchableOpacity onPress={() => setShowNotifications(false)}>
              <Text style={styles.closeText}>Close</Text>
            </TouchableOpacity>
          </View>
        </View>
      </Modal>

      <Modal visible={showProfile} transparent animationType="slide">
        <View style={styles.modalOverlay}>
          <View style={styles.modalContent}>
            <Text style={styles.modalTitle}>Profile & Settings</Text>
            <View style={styles.profileInfo}>
              <Image
                source={user.profilePic ? { uri: user.profilePic } : require('@/assets/images/MBL_Logo.webp')}
                style={styles.profileModalImage}
              />
              <Text style={styles.profileName}>{user.name}</Text>
              <Text style={styles.profileEmail}>{user.email}</Text>
            </View>
            
            {/* Settings Toggles */}
            <View style={styles.settingsSection}>
              <Text style={styles.settingsTitle}>Dashboard Settings</Text>
              
              <TouchableOpacity 
                style={styles.settingToggle}
                onPress={() => setShowTodayProgress(!showTodayProgress)}
              >
                <View style={styles.settingToggleLeft}>
                  <Ionicons name="stats-chart" size={20} color="#2ecc40" />
                  <Text style={styles.settingToggleText}>Show Today's Progress</Text>
                </View>
                <View style={[styles.toggleSwitch, { backgroundColor: showTodayProgress ? '#2ecc40' : '#666' }]}>
                  <View style={[styles.toggleKnob, { 
                    transform: [{ translateX: showTodayProgress ? 16 : 0 }] 
                  }]} />
                </View>
              </TouchableOpacity>
            </View>
            
            <View style={styles.modalButtons}>
              <TouchableOpacity
                style={[styles.modalButton, styles.cancelButton]}
                onPress={() => setShowProfile(false)}
              >
                <Text style={styles.cancelButtonText}>Close</Text>
              </TouchableOpacity>
              <TouchableOpacity
                style={[styles.modalButton, styles.logoutButton]}
                onPress={() => {
                  console.log('🔘 Logout button pressed!');
                  setShowProfile(false); // Close modal first
                  handleLogout(); // Then handle logout
                }}
              >
                <Text style={styles.logoutButtonText}>Logout</Text>
              </TouchableOpacity>
            </View>
            
            {/* Debug: Test logout functionality */}
            <TouchableOpacity
              style={[styles.modalButton, { backgroundColor: '#ff6b35', marginTop: 10 }]}
              onPress={async () => {
                console.log('🧪 Debug: Direct logout test');
                setShowProfile(false);
                try {
                  await logout();
                  console.log('🧪 Debug: Direct logout successful');
                } catch (error) {
                  console.error('🧪 Debug: Direct logout failed:', error);
                }
              }}
            >
              <Text style={styles.logoutButtonText}>Debug Logout</Text>
            </TouchableOpacity>
            
            {/* Debug: Force logout test */}
            <TouchableOpacity
              style={[styles.modalButton, { backgroundColor: '#ff0000', marginTop: 10 }]}
              onPress={async () => {
                console.log('🧪 Debug: Force logout test');
                setShowProfile(false);
                try {
                  await forceLogout();
                  console.log('🧪 Debug: Force logout successful');
                } catch (error) {
                  console.error('🧪 Debug: Force logout failed:', error);
                }
              }}
            >
              <Text style={styles.logoutButtonText}>Force Logout</Text>
            </TouchableOpacity>
            
            {/* Debug: Show current state */}
            <View style={{ marginTop: 15, padding: 10, backgroundColor: '#f0f0f0', borderRadius: 8 }}>
              <Text style={{ fontSize: 12, color: '#666' }}>
                Debug State:
              </Text>
              <Text style={{ fontSize: 10, color: '#999' }}>
                isAuthenticated: {isAuthenticated ? 'true' : 'false'}
              </Text>
              <Text style={{ fontSize: 10, color: '#999' }}>
                user.id: {user?.id || 'undefined'}
              </Text>
              <Text style={{ fontSize: 10, color: '#999' }}>
                user.isLoggedIn: {user?.isLoggedIn ? 'true' : 'false'}
              </Text>
            </View>
          </View>
        </View>
      </Modal>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  backgroundGradient: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
    zIndex: -1,
  },
  content: {
    flex: 1,
    paddingHorizontal: 20,
    paddingTop: 20,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 30,
  },
  headerLeft: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  profileImage: {
    width: 80, // Increased from 70 by another 15%
    height: 80, // Increased from 70 by another 15%
    borderRadius: 40, // Increased from 35 by another 15%
    marginRight: 23, // Increased from 20 by another 15%
  },
  userInfo: {
    flex: 1,
  },
  userName: {
    color: '#fff',
    fontSize: 30, // Increased from 26 by another 15%
    fontWeight: 'bold',
    marginBottom: 7, // Increased from 6 by another 15%
  },
  userStats: {
    color: '#aaa',
    fontSize: 18, // Increased from 16 by another 15%
    marginBottom: 5, // Increased from 4 by another 15%
  },
  highlight: {
    color: '#FFD700',
    fontWeight: 'bold',
  },
  activeDays: {
    color: '#aaa',
    fontSize: 16, // Increased from 14 by another 15%
  },
  headerRight: {
    flexDirection: 'row',
  },
  notificationButton: {
    position: 'relative',
    marginRight: 15,
  },
  settingsButton: {
    marginLeft: 15,
  },
  badge: {
    position: 'absolute',
    top: -5,
    right: -5,
    backgroundColor: '#ff4136',
    borderRadius: 10,
    minWidth: 20,
    height: 20,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 5,
    zIndex: 2,
  },
  badgeText: {
    color: '#fff',
    fontSize: 12,
    fontWeight: 'bold',
  },
  scrollView: {
    flex: 1,
  },
  section: {
    marginBottom: 32,
  },
  sectionHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 16,
    paddingVertical: 8,
    borderRadius: 8,
    backgroundColor: 'rgba(255, 255, 255, 0.02)',
    paddingHorizontal: 12,
  },
  sectionHeaderLeft: {
    flex: 1,
  },
  sectionHeaderRight: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
  },
  sectionTitle: {
    color: '#fff',
    fontSize: 22,
    fontWeight: 'bold',
  },
  sectionSubtitle: {
    color: '#aaa',
    fontSize: 14,
    marginTop: 4,
  },
  equilibriumWrapper: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    marginTop: 10,
  },
  equilibriumContainer: {
    flexDirection: 'row',
    justifyContent: 'center',
    marginBottom: 10,
    paddingHorizontal: 5,
    flex: 1,
  },
  equilibriumItem: {
    alignItems: 'center',
    width: width * 0.22,
    marginHorizontal: 8,
  },
  progressCircle: {
    width: 70,
    height: 70,
    borderRadius: 35,
    borderWidth: 3,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 16,
    position: 'relative',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.25,
    shadowRadius: 3.84,
    elevation: 5,
  },
  percentageRing: {
    position: 'absolute',
    top: -5,
    left: -5,
    width: 80,
    height: 80,
    borderRadius: 40,
    borderWidth: 2,
    borderColor: 'transparent',
    alignItems: 'center',
    justifyContent: 'center',
    zIndex: 1,
  },
  percentageText: {
    fontSize: 12,
    fontWeight: 'bold',
    backgroundColor: 'rgba(0, 0, 0, 0.8)',
    paddingHorizontal: 6,
    paddingVertical: 2,
    borderRadius: 8,
    color: '#fff',
    textShadowColor: 'rgba(0, 0, 0, 0.8)',
    textShadowOffset: { width: 1, height: 1 },
    textShadowRadius: 2,
  },
  equilibriumLabel: {
    color: '#fff',
    fontSize: 12,
    fontWeight: '600',
    marginBottom: 6,
    textAlign: 'center',
  },
  equilibriumValue: {
    color: '#fff',
    fontSize: 14,
    fontWeight: 'bold',
    textAlign: 'center',
  },
  recommendationSidebar: {
    width: width * 0.28,
    paddingLeft: 15,
    alignItems: 'flex-start',
    backgroundColor: 'rgba(255, 255, 255, 0.05)',
    borderRadius: 12,
    padding: 12,
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.1)',
  },
  recommendationTitle: {
    fontSize: 16,
    fontWeight: 'bold',
    marginBottom: 8,
    textAlign: 'left',
  },
  recommendationText: {
    fontSize: 13,
    fontWeight: '500',
    textAlign: 'left',
    lineHeight: 18,
    marginBottom: 12,
  },
  goalIndicator: {
    paddingTop: 8,
    borderTopWidth: 1,
    borderTopColor: 'rgba(255, 255, 255, 0.1)',
  },
  goalText: {
    fontSize: 11,
    fontWeight: '500',
    textAlign: 'left',
    color: '#aaa',
  },
  statsContainer: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 10,
    paddingHorizontal: 5,
  },
  statCard: {
    alignItems: 'center',
    backgroundColor: 'rgba(255, 255, 255, 0.05)',
    borderRadius: 10, // Reduced from 12
    padding: 12, // Reduced from 16
    width: width * 0.28,
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.1)',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.2,
    shadowRadius: 2,
    elevation: 3,
  },
  statValue: {
    color: '#fff',
    fontSize: 18, // Reduced from 22
    fontWeight: 'bold',
    marginTop: 6, // Reduced from 8
    marginBottom: 3, // Reduced from 4
  },
  statLabel: {
    color: '#aaa',
    fontSize: 11, // Reduced from 12
    fontWeight: '500',
  },
  groupsContainer: {
    marginBottom: 10,
  },
  groupCard: {
    width: width * 0.11, // Reduced from 0.18 (40% smaller)
    height: width * 0.11, // Reduced from 0.18 (40% smaller)
    borderRadius: 8, // Reduced from 12
    marginRight: 8, // Reduced from 12
    overflow: 'hidden',
    backgroundColor: 'rgba(255, 255, 255, 0.05)',
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.1)',
  },
  groupGradient: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: 8, // Reduced from 12
  },
  groupIcon: {
    width: 90, // Increased from 72 by another 25%
    height: 90, // Increased from 72 by another 25%
    marginBottom: 2, // Reduced from 4
  },
  groupName: {
    color: '#fff',
    fontSize: 9, // Reduced from 11
    fontWeight: '600',
    textAlign: 'center',
    paddingHorizontal: 2, // Reduced from 4
    paddingBottom: 4, // Reduced from 8
  },
  addGroupCard: {
    width: width * 0.11, // Reduced from 0.18 (40% smaller)
    height: width * 0.11, // Reduced from 0.18 (40% smaller)
    borderRadius: 8, // Reduced from 12
    marginRight: 8, // Reduced from 12
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: 'rgba(46, 204, 64, 0.1)',
    borderWidth: 1,
    borderColor: 'rgba(46, 204, 64, 0.3)',
    borderStyle: 'dashed',
  },
  addGroupText: {
    color: '#2ecc40',
    fontSize: 9, // Reduced from 11
    fontWeight: '600',
    marginTop: 2, // Reduced from 4
  },
  addButton: {
    padding: 8,
    borderRadius: 8,
    backgroundColor: 'rgba(46, 204, 64, 0.1)',
    borderWidth: 1,
    borderColor: 'rgba(46, 204, 64, 0.2)',
  },
  commitmentCard: {
    flexDirection: 'row',
    alignItems: 'center',
    marginVertical: 6,
    borderRadius: 16,
    padding: 16,
    backgroundColor: 'rgba(255, 255, 255, 0.05)',
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.1)',
    borderLeftWidth: 4,
  },
  commitmentGradient: {
    width: 44,
    height: 44,
    borderRadius: 22,
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: 16,
  },
  commitmentContent: {
    flex: 1,
  },
  commitmentLabel: {
    fontSize: 16,
    fontWeight: 'bold',
    marginBottom: 4,
  },
  commitmentPoints: {
    color: '#fff',
    fontSize: 13,
    opacity: 0.8,
  },
  modalOverlay: {
    flex: 1,
    backgroundColor: 'rgba(0,0,0,0.6)',
    alignItems: 'center',
    justifyContent: 'center',
  },
  modalContent: {
    backgroundColor: '#222',
    borderRadius: 20,
    padding: 25,
    alignItems: 'center',
    width: width * 0.8,
    maxHeight: height * 0.7,
  },
  modalTitle: {
    color: '#fff',
    fontSize: 24,
    fontWeight: 'bold',
    marginBottom: 20,
  },
  modalInput: {
    backgroundColor: '#333',
    color: '#fff',
    borderRadius: 10,
    padding: 15,
    width: '100%',
    marginBottom: 15,
    fontSize: 16,
  },
  modalButtons: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    width: '100%',
    marginTop: 10,
  },
  modalButton: {
    paddingVertical: 12,
    paddingHorizontal: 25,
    borderRadius: 10,
  },
  cancelButton: {
    backgroundColor: '#444',
    borderWidth: 1,
    borderColor: '#444',
  },
  cancelButtonText: {
    color: '#aaa',
    fontSize: 16,
    fontWeight: 'bold',
  },
  confirmButton: {
    backgroundColor: '#2ecc40',
    borderWidth: 1,
    borderColor: '#2ecc40',
  },
  confirmButtonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: 'bold',
  },
  notificationsList: {
    width: '100%',
    maxHeight: height * 0.4,
  },
  notificationItem: {
    padding: 15,
    borderRadius: 12,
    marginBottom: 8,
    borderWidth: 1,
    borderColor: '#333',
  },
  notificationText: {
    fontSize: 16,
    lineHeight: 22,
    marginBottom: 5,
  },
  notificationTime: {
    color: '#aaa',
    fontSize: 12,
    textAlign: 'right',
  },
  emptyText: {
    color: '#aaa',
    textAlign: 'center',
    marginTop: 20,
    fontSize: 16,
  },
  closeText: {
    color: '#aaa',
    textAlign: 'center',
    marginTop: 15,
    fontSize: 16,
  },
  profileInfo: {
    alignItems: 'center',
    marginBottom: 20,
  },
  profileModalImage: {
    width: 80,
    height: 80,
    borderRadius: 40,
    marginBottom: 10,
  },
  profileName: {
    color: '#fff',
    fontSize: 20,
    fontWeight: 'bold',
    marginBottom: 5,
  },
  profileEmail: {
    color: '#aaa',
    fontSize: 14,
  },
  logoutButton: {
    backgroundColor: '#ff4136',
    borderWidth: 1,
    borderColor: '#ff4136',
  },
  logoutButtonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: 'bold',
  },
  settingsSection: {
    width: '100%',
    marginTop: 20,
    paddingHorizontal: 10,
  },
  settingsTitle: {
    color: '#fff',
    fontSize: 18,
    fontWeight: 'bold',
    marginBottom: 10,
    textAlign: 'left',
  },
  settingToggle: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: 12,
    paddingHorizontal: 15,
    borderRadius: 10,
    backgroundColor: 'rgba(255, 255, 255, 0.05)',
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.1)',
  },
  settingToggleLeft: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
  },
  settingToggleText: {
    color: '#fff',
    fontSize: 15,
    fontWeight: '500',
  },
  toggleSwitch: {
    width: 40,
    height: 20,
    borderRadius: 10,
    justifyContent: 'center',
    alignItems: 'center',
    paddingHorizontal: 2,
  },
  toggleKnob: {
    width: 16,
    height: 16,
    borderRadius: 8,
    backgroundColor: '#fff',
  },
});



