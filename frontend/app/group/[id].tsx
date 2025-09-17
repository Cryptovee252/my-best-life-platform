import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  Alert,
  ActivityIndicator,
  RefreshControl,
  Dimensions,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { LinearGradient } from 'expo-linear-gradient';
import { Ionicons } from '@expo/vector-icons';
import { useLocalSearchParams, router } from 'expo-router';
import groupService, { Group, GroupStory, GroupMessage, GroupTask, GroupCP } from '../../services/groupService';
import { useUser } from '../../components/UserContext';
import { useGroup } from '../../components/GroupContext';

const { width } = Dimensions.get('window');

type TabType = 'overview' | 'stories' | 'messages' | 'tasks' | 'cp' | 'members';

export default function GroupDetailScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const { user } = useUser();
  const { groups } = useGroup();
  const [group, setGroup] = useState<Group | null>(null);
  const [activeTab, setActiveTab] = useState<TabType>('overview');
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [stories, setStories] = useState<GroupStory[]>([]);
  const [messages, setMessages] = useState<GroupMessage[]>([]);
  const [tasks, setTasks] = useState<GroupTask[]>([]);
  const [cp, setCp] = useState<GroupCP | null>(null);
  const [isMember, setIsMember] = useState(false);
  const [isAdmin, setIsAdmin] = useState(false);

  useEffect(() => {
    if (id) {
      loadGroupData();
    }
  }, [id, groups]);

  const loadGroupData = async () => {
    try {
      setLoading(true);
      
      // First check if it's a demo group from context
      const contextGroup = groups.find(g => g.id === id);
      if (contextGroup) {
        // Convert context group to service group format
        const convertedGroup: Group = {
          id: contextGroup.id,
          name: contextGroup.name,
          description: '',
          isPrivate: false,
          maxMembers: 100,
          createdBy: contextGroup.adminId,
          createdAt: new Date().toISOString(),
          updatedAt: new Date().toISOString(),
          members: contextGroup.members.map(member => ({
            id: member.id,
            groupId: contextGroup.id,
            userId: member.id,
            role: 'member',
            joinedAt: new Date().toISOString(),
            name: member.name,
            profilePic: member.avatarUrl
          }))
        };
        setGroup(convertedGroup);
        setIsMember(true);
        setIsAdmin(contextGroup.adminId === user.id);
        setLoading(false);
        return;
      }
      
      // Try to load group from backend service
      try {
        const groupData = await groupService.getGroupById(id);
        setGroup(groupData);
        
        // Check if user is a member and admin
        const userGroups = await groupService.getUserGroups();
        const userGroup = userGroups.find(g => g.id === id);
        setIsMember(!!userGroup);
        setIsAdmin(userGroup?.isAdmin || false);
        
        // Load initial data based on active tab
        await loadTabData(activeTab);
      } catch (backendError) {
        console.error('Backend group load failed:', backendError);
        // If backend fails, show group not found
        setGroup(null);
      }
      
    } catch (error) {
      console.error('Error loading group data:', error);
      Alert.alert('Error', 'Failed to load group data');
    } finally {
      setLoading(false);
    }
  };

  const loadTabData = async (tab: TabType) => {
    try {
      switch (tab) {
        case 'stories':
          const groupStories = await groupService.getGroupStories(id);
          setStories(groupStories);
          await groupService.saveGroupStoriesToStorage(id, groupStories);
          break;
        case 'messages':
          const groupMessages = await groupService.getGroupMessages(id);
          setMessages(groupMessages);
          await groupService.saveGroupMessagesToStorage(id, groupMessages);
          break;
        case 'tasks':
          const groupTasks = await groupService.getGroupTasks(id);
          setTasks(groupTasks);
          await groupService.saveGroupTasksToStorage(id, groupTasks);
          break;
        case 'cp':
          const groupCP = await groupService.getGroupCP(id);
          setCp(groupCP);
          break;
      }
    } catch (error) {
      console.error(`Error loading ${tab} data:`, error);
      // Fallback to local storage for some data
      if (tab === 'stories') {
        const localStories = await groupService.loadGroupStoriesFromStorage(id);
        setStories(localStories);
      } else if (tab === 'messages') {
        const localMessages = await groupService.loadGroupMessagesFromStorage(id);
        setMessages(localMessages);
      } else if (tab === 'tasks') {
        const localTasks = await groupService.loadGroupTasksFromStorage(id);
        setTasks(localTasks);
      }
    }
  };

  const onRefresh = async () => {
    setRefreshing(true);
    await loadGroupData();
    setRefreshing(false);
  };

  const handleTabChange = async (tab: TabType) => {
    setActiveTab(tab);
    await loadTabData(tab);
  };

  const handleJoinGroup = async () => {
    try {
      await groupService.joinGroup(id);
      setIsMember(true);
      Alert.alert('Success', 'Successfully joined the group!');
      await loadGroupData();
    } catch (error) {
      console.error('Error joining group:', error);
      Alert.alert('Error', error instanceof Error ? error.message : 'Failed to join group');
    }
  };

  const handleLeaveGroup = async () => {
    Alert.alert(
      'Leave Group',
      `Are you sure you want to leave "${group?.name}"?`,
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Leave',
          style: 'destructive',
          onPress: async () => {
            try {
              await groupService.leaveGroup(id);
              setIsMember(false);
              setIsAdmin(false);
              Alert.alert('Success', 'Successfully left the group');
              router.back();
            } catch (error) {
              console.error('Error leaving group:', error);
              Alert.alert('Error', error instanceof Error ? error.message : 'Failed to leave group');
            }
          },
        },
      ]
    );
  };

  const handleDeleteGroup = async () => {
    Alert.alert(
      'Delete Group',
      `Are you sure you want to delete "${group?.name}"? This action cannot be undone.`,
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Delete',
          style: 'destructive',
          onPress: async () => {
            try {
              await groupService.deleteGroup(id);
              Alert.alert('Success', 'Group deleted successfully');
              router.back();
            } catch (error) {
              console.error('Error deleting group:', error);
              Alert.alert('Error', error instanceof Error ? error.message : 'Failed to delete group');
            }
          },
        },
      ]
    );
  };

  const navigateToCreateStory = () => {
    router.push(`/group/${id}/create-story`);
  };

  const navigateToCreateTask = () => {
    router.push(`/group/${id}/create-task`);
  };

  const navigateToChat = () => {
    router.push(`/group/${id}/chat`);
  };

  if (loading) {
    return (
      <SafeAreaView style={styles.container}>
        <LinearGradient
          colors={['#667eea', '#764ba2']}
          style={styles.gradient}
        >
          <View style={styles.loadingContainer}>
            <ActivityIndicator size="large" color="#fff" />
            <Text style={styles.loadingText}>Loading group...</Text>
          </View>
        </LinearGradient>
      </SafeAreaView>
    );
  }

  if (!group) {
    return (
      <SafeAreaView style={styles.container}>
        <LinearGradient
          colors={['#667eea', '#764ba2']}
          style={styles.gradient}
        >
          <View style={styles.errorContainer}>
            <Ionicons name="alert-circle" size={64} color="#fff" />
            <Text style={styles.errorTitle}>Group Not Found</Text>
            <Text style={styles.errorSubtitle}>
              The group you're looking for doesn't exist or has been removed.
            </Text>
            <TouchableOpacity
              style={styles.backButton}
              onPress={() => router.back()}
            >
              <Text style={styles.actionButtonText}>Go Back</Text>
            </TouchableOpacity>
          </View>
        </LinearGradient>
      </SafeAreaView>
    );
  }

  const renderHeader = () => (
    <View style={styles.header}>
      <TouchableOpacity
        style={styles.backButton}
        onPress={() => router.back()}
      >
        <Ionicons name="arrow-back" size={24} color="#fff" />
      </TouchableOpacity>
      
      <View style={styles.headerInfo}>
        <Text style={styles.groupName}>{group.name}</Text>
        <Text style={styles.groupDescription} numberOfLines={2}>
          {group.description}
        </Text>
      </View>

      {isMember && (
        <View style={styles.headerActions}>
          {isAdmin ? (
            <TouchableOpacity
              style={[styles.headerActionButton, styles.deleteButton]}
              onPress={handleDeleteGroup}
            >
              <Ionicons name="trash" size={20} color="#fff" />
            </TouchableOpacity>
          ) : (
            <TouchableOpacity
              style={[styles.headerActionButton, styles.leaveButton]}
              onPress={handleLeaveGroup}
            >
              <Ionicons name="exit" size={20} color="#fff" />
            </TouchableOpacity>
          )}
        </View>
      )}
    </View>
  );

  const renderTabs = () => (
    <View style={styles.tabsContainer}>
      <ScrollView horizontal showsHorizontalScrollIndicator={false}>
        {[
          { key: 'overview', label: 'Overview', icon: 'information-circle' },
          { key: 'stories', label: 'Stories', icon: 'newspaper' },
          { key: 'messages', label: 'Messages', icon: 'chatbubbles' },
          { key: 'tasks', label: 'Tasks', icon: 'list' },
          { key: 'cp', label: 'CP', icon: 'trophy' },
          { key: 'members', label: 'Members', icon: 'people' },
        ].map((tab) => (
          <TouchableOpacity
            key={tab.key}
            style={[
              styles.tab,
              activeTab === tab.key && styles.activeTab
            ]}
            onPress={() => handleTabChange(tab.key as TabType)}
          >
            <Ionicons
              name={tab.icon as any}
              size={16}
              color={activeTab === tab.key ? '#667eea' : '#666'}
            />
            <Text style={[
              styles.tabText,
              activeTab === tab.key && styles.activeTabText
            ]}>
              {tab.label}
            </Text>
          </TouchableOpacity>
        ))}
      </ScrollView>
    </View>
  );

  const renderOverview = () => {
    // Get CP totals from context group if available
    const contextGroup = groups.find(g => g.id === id);
    const totalMindCP = contextGroup ? contextGroup.members.reduce((sum, m) => sum + (m.groupCP?.mind || 0), 0) : 0;
    const totalBodyCP = contextGroup ? contextGroup.members.reduce((sum, m) => sum + (m.groupCP?.body || 0), 0) : 0;
    const totalSoulCP = contextGroup ? contextGroup.members.reduce((sum, m) => sum + (m.groupCP?.soul || 0), 0) : 0;

    return (
      <View style={styles.tabContent}>
        {/* Statistics Section */}
        <View style={styles.statsSection}>
          <Text style={styles.sectionTitle}>Statistics</Text>
          <View style={styles.statsRow}>
            <View style={styles.statCircle}>
              <View style={[styles.statDot, { backgroundColor: '#2ecc40' }]} />
              <Text style={styles.statNum}>{totalMindCP}</Text>
            </View>
            <View style={styles.statCircle}>
              <View style={[styles.statDot, { backgroundColor: '#0074d9' }]} />
              <Text style={styles.statNum}>{totalBodyCP}</Text>
            </View>
            <View style={styles.statCircle}>
              <View style={[styles.statDot, { backgroundColor: '#ff4136' }]} />
              <Text style={styles.statNum}>{totalSoulCP}</Text>
            </View>
          </View>
        </View>

        {/* Leader Board Section */}
        <View style={styles.leaderboardSection}>
          <Text style={styles.sectionTitle}>Leader Board</Text>
          <View style={styles.leaderboardRow}>
            {contextGroup && contextGroup.members && contextGroup.members.length > 0 ? (
              contextGroup.members.slice(0, 2).map((member) => (
                <View key={member.id} style={styles.leaderCard}>
                  <View style={styles.leaderAvatar}>
                    <Text style={styles.leaderInitials}>
                      {member.name?.charAt(0) || 'U'}
                    </Text>
                  </View>
                  <Text style={styles.leaderName}>{member.name}</Text>
                  <Text style={styles.leaderCP}>Group CP: {member.groupCP?.mind + member.groupCP?.body + member.groupCP?.soul || 0}</Text>
                </View>
              ))
            ) : (
              <View style={styles.emptyLeaderboard}>
                <Text style={styles.emptyText}>No members yet</Text>
              </View>
            )}
          </View>
        </View>

        {/* Category Cards Section */}
        <View style={styles.categorySection}>
          <TouchableOpacity
            style={[styles.categoryCard, { backgroundColor: '#2ecc40' }]}
            onPress={() => router.push(`/group/${id}/mind`)}
          >
            <Text style={styles.categoryLabel}>Mind</Text>
            <Text style={styles.categoryCP}>Commitment Points: {totalMindCP}</Text>
            <Ionicons name="chevron-forward" size={24} color="#fff" style={styles.categoryArrow} />
          </TouchableOpacity>
          
          <TouchableOpacity
            style={[styles.categoryCard, { backgroundColor: '#0074d9' }]}
            onPress={() => router.push(`/group/${id}/body`)}
          >
            <Text style={styles.categoryLabel}>Body</Text>
            <Text style={styles.categoryCP}>Commitment Points: {totalBodyCP}</Text>
            <Ionicons name="chevron-forward" size={24} color="#fff" style={styles.categoryArrow} />
          </TouchableOpacity>
          
          <TouchableOpacity
            style={[styles.categoryCard, { backgroundColor: '#ff4136' }]}
            onPress={() => router.push(`/group/${id}/soul`)}
          >
            <Text style={styles.categoryLabel}>Soul</Text>
            <Text style={styles.categoryCP}>Commitment Points: {totalSoulCP}</Text>
            <Ionicons name="chevron-forward" size={24} color="#fff" style={styles.categoryArrow} />
          </TouchableOpacity>
        </View>

        {/* Group Information Card */}
        <View style={styles.overviewCard}>
          <Text style={styles.overviewTitle}>Group Information</Text>
          
          <View style={styles.infoRow}>
            <Ionicons name="people" size={20} color="#666" />
            <Text style={styles.infoText}>
              {group.memberCount || group.members?.length || 0} members
            </Text>
          </View>
          
          <View style={styles.infoRow}>
            <Ionicons name="lock-closed" size={20} color="#666" />
            <Text style={styles.infoText}>
              {group.isPrivate ? 'Private Group' : 'Public Group'}
            </Text>
          </View>
          
          <View style={styles.infoRow}>
            <Ionicons name="calendar" size={20} color="#666" />
            <Text style={styles.infoText}>
              Created {new Date(group.createdAt).toLocaleDateString()}
            </Text>
          </View>
          
          {group.category && (
            <View style={styles.infoRow}>
              <Ionicons name="pricetag" size={20} color="#666" />
              <Text style={styles.infoText}>
                Category: {group.category}
              </Text>
            </View>
          )}
        </View>

        {/* Action Buttons */}
        {!isMember && (
          <TouchableOpacity
            style={styles.joinButton}
            onPress={handleJoinGroup}
          >
            <Ionicons name="people" size={20} color="#fff" />
            <Text style={styles.joinButtonText}>Join Group</Text>
          </TouchableOpacity>
        )}

        {isMember && (
          <View style={styles.actionButtons}>
            <TouchableOpacity
              style={styles.actionButton}
              onPress={navigateToCreateStory}
            >
              <Ionicons name="add-circle" size={20} color="#fff" />
              <Text style={styles.actionButtonText}>Share Story</Text>
            </TouchableOpacity>
            
            <TouchableOpacity
              style={styles.actionButton}
              onPress={navigateToCreateTask}
            >
              <Ionicons name="add-circle" size={20} color="#fff" />
              <Text style={styles.actionButtonText}>Create Task</Text>
            </TouchableOpacity>
            
            <TouchableOpacity
              style={styles.actionButton}
              onPress={navigateToChat}
            >
              <Ionicons name="chatbubbles" size={20} color="#fff" />
              <Text style={styles.actionButtonText}>Open Chat</Text>
            </TouchableOpacity>
          </View>
        )}
      </View>
    );
  };

  const renderStories = () => (
    <View style={styles.tabContent}>
      {stories.length > 0 ? (
        stories.map((story) => (
          <View key={story.id} style={styles.storyCard}>
            <View style={styles.storyHeader}>
              <Text style={styles.storyTitle}>{story.title}</Text>
              <View style={styles.storyMeta}>
                <Text style={styles.storyAuthor}>by {story.authorName}</Text>
                <Text style={styles.storyDate}>
                  {new Date(story.createdAt).toLocaleDateString()}
                </Text>
              </View>
            </View>
            <Text style={styles.storyContent} numberOfLines={3}>
              {story.content}
            </Text>
            <View style={styles.storyFooter}>
              <View style={styles.storyStats}>
                <Ionicons name="heart" size={16} color="#666" />
                <Text style={styles.storyStatsText}>{story.likesCount || 0}</Text>
                <Ionicons name="chatbubble" size={16} color="#666" />
                <Text style={styles.storyStatsText}>{story.commentsCount || 0}</Text>
              </View>
              <Text style={styles.storyCategory}>{story.category}</Text>
            </View>
          </View>
        ))
      ) : (
        <View style={styles.emptyState}>
          <Ionicons name="newspaper-outline" size={48} color="#ccc" />
          <Text style={styles.emptyStateText}>No stories yet</Text>
          <Text style={styles.emptyStateSubtext}>
            Be the first to share a story in this group!
          </Text>
        </View>
      )}
    </View>
  );

  const renderMessages = () => (
    <View style={styles.tabContent}>
      {messages.length > 0 ? (
        messages.map((message) => (
          <View key={message.id} style={styles.messageCard}>
            <View style={styles.messageHeader}>
              <Text style={styles.messageAuthor}>{message.senderName}</Text>
              <Text style={styles.messageTime}>
                {new Date(message.createdAt).toLocaleTimeString()}
              </Text>
            </View>
            <Text style={styles.messageContent}>{message.content}</Text>
          </View>
        ))
      ) : (
        <View style={styles.emptyState}>
          <Ionicons name="chatbubbles-outline" size={48} color="#ccc" />
          <Text style={styles.emptyStateText}>No messages yet</Text>
          <Text style={styles.emptyStateSubtext}>
            Start the conversation in this group!
          </Text>
        </View>
      )}
    </View>
  );

  const renderTasks = () => (
    <View style={styles.tabContent}>
      {tasks.length > 0 ? (
        tasks.map((task) => (
          <View key={task.id} style={styles.taskCard}>
            <View style={styles.taskHeader}>
              <Text style={styles.taskTitle}>{task.title}</Text>
              <View style={styles.taskPoints}>
                <Ionicons name="trophy" size={16} color="#FFD700" />
                <Text style={styles.taskPointsText}>{task.points} CP</Text>
              </View>
            </View>
            <Text style={styles.taskDescription}>{task.description}</Text>
            <View style={styles.taskFooter}>
              <Text style={styles.taskCategory}>{task.category}</Text>
              {task.dueDate && (
                <Text style={styles.taskDueDate}>
                  Due: {new Date(task.dueDate).toLocaleDateString()}
                </Text>
              )}
            </View>
          </View>
        ))
      ) : (
        <View style={styles.emptyState}>
          <Ionicons name="list-outline" size={48} color="#ccc" />
          <Text style={styles.emptyStateText}>No tasks yet</Text>
          <Text style={styles.emptyStateSubtext}>
            Create the first task for this group!
          </Text>
        </View>
      )}
    </View>
  );

  const renderCP = () => (
    <View style={styles.tabContent}>
      {cp ? (
        <View style={styles.cpContainer}>
          <View style={styles.cpCard}>
            <Text style={styles.cpTitle}>Total Group CP</Text>
            <Text style={styles.cpTotal}>{cp.totalCP}</Text>
            <Text style={styles.cpSubtitle}>
              From {cp.totalTasks} completed tasks
            </Text>
          </View>
          
          <View style={styles.cpBreakdown}>
            <View style={styles.cpCategory}>
              <Text style={styles.cpCategoryLabel}>Mind</Text>
              <Text style={styles.cpCategoryValue}>{cp.mindCP}</Text>
            </View>
            <View style={styles.cpCategory}>
              <Text style={styles.cpCategoryLabel}>Body</Text>
              <Text style={styles.cpCategoryValue}>{cp.bodyCP}</Text>
            </View>
            <View style={styles.cpCategory}>
              <Text style={styles.cpCategoryLabel}>Soul</Text>
              <Text style={styles.cpCategoryValue}>{cp.soulCP}</Text>
            </View>
          </View>
        </View>
      ) : (
        <View style={styles.emptyState}>
          <Ionicons name="trophy-outline" size={48} color="#ccc" />
          <Text style={styles.emptyStateText}>No CP data yet</Text>
          <Text style={styles.emptyStateSubtext}>
            Complete tasks to start earning CP!
          </Text>
        </View>
      )}
    </View>
  );

  const renderMembers = () => (
    <View style={styles.tabContent}>
      {group.members && group.members.length > 0 ? (
        group.members.map((member) => (
          <View key={member.id} style={styles.memberCard}>
            <View style={styles.memberInfo}>
              <View style={styles.memberAvatar}>
                <Text style={styles.memberInitials}>
                  {member.name?.charAt(0) || 'U'}
                </Text>
              </View>
              <View style={styles.memberDetails}>
                <Text style={styles.memberName}>{member.name}</Text>
                <Text style={styles.memberUsername}>@{member.username}</Text>
              </View>
            </View>
            <View style={styles.memberStatus}>
              {member.role === 'admin' ? (
                <View style={styles.adminBadge}>
                  <Ionicons name="shield" size={12} color="#fff" />
                  <Text style={styles.adminBadgeText}>Admin</Text>
                </View>
              ) : (
                <Text style={styles.memberRole}>Member</Text>
              )}
            </View>
          </View>
        ))
      ) : (
        <View style={styles.emptyState}>
          <Ionicons name="people-outline" size={48} color="#ccc" />
          <Text style={styles.emptyStateText}>No members yet</Text>
          <Text style={styles.emptyStateSubtext}>
            This group is empty. Invite people to join!
          </Text>
        </View>
      )}
    </View>
  );

  const renderTabContent = () => {
    switch (activeTab) {
      case 'overview':
        return renderOverview();
      case 'stories':
        return renderStories();
      case 'messages':
        return renderMessages();
      case 'tasks':
        return renderTasks();
      case 'cp':
        return renderCP();
      case 'members':
        return renderMembers();
      default:
        return renderOverview();
    }
  };

  return (
    <SafeAreaView style={styles.container}>
      <LinearGradient
        colors={['#667eea', '#764ba2']}
        style={styles.gradient}
      >
        {renderHeader()}
        {renderTabs()}
        
        <ScrollView
          style={styles.content}
          contentContainerStyle={styles.contentContainer}
          refreshControl={
            <RefreshControl refreshing={refreshing} onRefresh={onRefresh} />
          }
        >
          {renderTabContent()}
        </ScrollView>
      </LinearGradient>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  gradient: {
    flex: 1,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: 20,
    paddingTop: 10,
  },
  backButton: {
    padding: 8,
    marginRight: 12,
  },
  headerInfo: {
    flex: 1,
  },
  groupName: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#fff',
    marginBottom: 4,
  },
  groupDescription: {
    fontSize: 14,
    color: '#fff',
    opacity: 0.9,
    lineHeight: 20,
  },
  headerActions: {
    flexDirection: 'row',
    gap: 8,
  },
  headerActionButton: {
    padding: 8,
    borderRadius: 8,
  },
  deleteButton: {
    backgroundColor: '#F44336',
  },
  leaveButton: {
    backgroundColor: '#FF5722',
  },
  tabsContainer: {
    backgroundColor: '#fff',
    paddingVertical: 8,
  },
  tab: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingVertical: 12,
    marginHorizontal: 4,
    borderRadius: 20,
    gap: 6,
  },
  activeTab: {
    backgroundColor: '#f0f0ff',
  },
  tabText: {
    fontSize: 14,
    color: '#666',
    fontWeight: '500',
  },
  activeTabText: {
    color: '#667eea',
    fontWeight: '600',
  },
  content: {
    flex: 1,
    backgroundColor: '#f5f5f5',
  },
  contentContainer: {
    padding: 20,
  },
  tabContent: {
    minHeight: 400,
  },
  overviewCard: {
    backgroundColor: '#fff',
    borderRadius: 16,
    padding: 20,
    marginBottom: 20,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 8,
    elevation: 3,
  },
  overviewTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#333',
    marginBottom: 16,
  },
  infoRow: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 12,
    gap: 12,
  },
  infoText: {
    fontSize: 16,
    color: '#666',
  },
  joinButton: {
    backgroundColor: '#4CAF50',
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 16,
    borderRadius: 12,
    gap: 8,
    marginBottom: 20,
  },
  joinButtonText: {
    color: '#fff',
    fontWeight: '600',
    fontSize: 16,
  },
  actionButtons: {
    gap: 12,
  },
  actionButton: {
    backgroundColor: '#2196F3',
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 16,
    borderRadius: 12,
    gap: 8,
  },
  actionButtonText: {
    color: '#fff',
    fontWeight: '600',
    fontSize: 16,
  },
  storyCard: {
    backgroundColor: '#fff',
    borderRadius: 12,
    padding: 16,
    marginBottom: 16,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 2,
  },
  storyHeader: {
    marginBottom: 12,
  },
  storyTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#333',
    marginBottom: 4,
  },
  storyMeta: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  storyAuthor: {
    fontSize: 14,
    color: '#666',
  },
  storyDate: {
    fontSize: 12,
    color: '#999',
  },
  storyContent: {
    fontSize: 14,
    color: '#666',
    lineHeight: 20,
    marginBottom: 12,
  },
  storyFooter: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  storyStats: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  storyStatsText: {
    fontSize: 12,
    color: '#666',
  },
  storyCategory: {
    fontSize: 12,
    color: '#2196F3',
    fontWeight: '600',
    textTransform: 'uppercase',
  },
  messageCard: {
    backgroundColor: '#fff',
    borderRadius: 12,
    padding: 16,
    marginBottom: 16,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 2,
  },
  messageHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 8,
  },
  messageAuthor: {
    fontSize: 14,
    fontWeight: '600',
    color: '#333',
  },
  messageTime: {
    fontSize: 12,
    color: '#999',
  },
  messageContent: {
    fontSize: 14,
    color: '#666',
    lineHeight: 20,
  },
  taskCard: {
    backgroundColor: '#fff',
    borderRadius: 12,
    padding: 16,
    marginBottom: 16,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 2,
  },
  taskHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 8,
  },
  taskTitle: {
    fontSize: 16,
    fontWeight: 'bold',
    color: '#333',
    flex: 1,
  },
  taskPoints: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
  },
  taskPointsText: {
    fontSize: 14,
    fontWeight: '600',
    color: '#FFD700',
  },
  taskDescription: {
    fontSize: 14,
    color: '#666',
    lineHeight: 20,
    marginBottom: 12,
  },
  taskFooter: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  taskCategory: {
    fontSize: 12,
    color: '#2196F3',
    fontWeight: '600',
    textTransform: 'uppercase',
  },
  taskDueDate: {
    fontSize: 12,
    color: '#FF5722',
  },
  cpContainer: {
    gap: 20,
  },
  cpCard: {
    backgroundColor: '#fff',
    borderRadius: 16,
    padding: 24,
    alignItems: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 8,
    elevation: 3,
  },
  cpTitle: {
    fontSize: 18,
    fontWeight: '600',
    color: '#666',
    marginBottom: 8,
  },
  cpTotal: {
    fontSize: 48,
    fontWeight: 'bold',
    color: '#4CAF50',
    marginBottom: 4,
  },
  cpSubtitle: {
    fontSize: 14,
    color: '#999',
  },
  cpBreakdown: {
    backgroundColor: '#fff',
    borderRadius: 16,
    padding: 20,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 8,
    elevation: 3,
  },
  cpCategory: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: 12,
    borderBottomWidth: 1,
    borderBottomColor: '#f0f0f0',
  },
  cpCategoryLabel: {
    fontSize: 16,
    fontWeight: '600',
    color: '#333',
    textTransform: 'capitalize',
  },
  cpCategoryValue: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#2196F3',
  },
  memberCard: {
    backgroundColor: '#fff',
    borderRadius: 12,
    padding: 16,
    marginBottom: 16,
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 2,
  },
  memberInfo: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
  },
  memberAvatar: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: '#667eea',
    alignItems: 'center',
    justifyContent: 'center',
  },
  memberInitials: {
    color: '#fff',
    fontSize: 16,
    fontWeight: 'bold',
  },
  memberDetails: {
    flex: 1,
  },
  memberName: {
    fontSize: 16,
    fontWeight: '600',
    color: '#333',
    marginBottom: 2,
  },
  memberUsername: {
    fontSize: 14,
    color: '#666',
  },
  memberStatus: {
    alignItems: 'flex-end',
  },
  adminBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#9C27B0',
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 12,
    gap: 4,
  },
  adminBadgeText: {
    color: '#fff',
    fontSize: 10,
    fontWeight: '600',
  },
  memberRole: {
    fontSize: 12,
    color: '#666',
  },
  emptyState: {
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 60,
  },
  emptyStateText: {
    fontSize: 18,
    fontWeight: '600',
    color: '#666',
    marginTop: 16,
    marginBottom: 8,
  },
  emptyStateSubtext: {
    fontSize: 14,
    color: '#999',
    textAlign: 'center',
    lineHeight: 20,
  },
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  loadingText: {
    color: '#fff',
    fontSize: 16,
    marginTop: 16,
  },
  errorContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: 20,
  },
  errorTitle: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#fff',
    marginTop: 16,
    marginBottom: 8,
  },
  errorSubtitle: {
    fontSize: 16,
    color: '#fff',
    opacity: 0.9,
    textAlign: 'center',
    lineHeight: 24,
    marginBottom: 24,
  },
  // Dashboard Styles
  statsSection: {
    marginBottom: 24,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#333',
    marginBottom: 16,
  },
  statsRow: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    alignItems: 'center',
  },
  statCircle: {
    alignItems: 'center',
    justifyContent: 'center',
    width: 80,
    height: 80,
    borderRadius: 40,
    backgroundColor: '#f8f9fa',
    borderWidth: 2,
    borderColor: '#e9ecef',
  },
  statDot: {
    width: 8,
    height: 8,
    borderRadius: 4,
    marginBottom: 4,
  },
  statNum: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#333',
  },
  leaderboardSection: {
    marginBottom: 24,
  },
  leaderboardRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    gap: 12,
  },
  leaderCard: {
    flex: 1,
    backgroundColor: '#fff',
    borderRadius: 12,
    padding: 16,
    alignItems: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 2,
  },
  leaderAvatar: {
    width: 48,
    height: 48,
    borderRadius: 24,
    backgroundColor: '#667eea',
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 8,
  },
  leaderInitials: {
    color: '#fff',
    fontSize: 18,
    fontWeight: 'bold',
  },
  leaderName: {
    fontSize: 14,
    fontWeight: '600',
    color: '#333',
    marginBottom: 4,
    textAlign: 'center',
  },
  leaderCP: {
    fontSize: 12,
    color: '#2ecc40',
    fontWeight: '600',
  },
  emptyLeaderboard: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 20,
  },
  emptyText: {
    fontSize: 14,
    color: '#999',
  },
  categorySection: {
    marginBottom: 24,
    gap: 12,
  },
  categoryCard: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    padding: 20,
    borderRadius: 16,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.2,
    shadowRadius: 8,
    elevation: 4,
  },
  categoryLabel: {
    fontSize: 20,
    fontWeight: 'bold',
    color: '#fff',
    marginBottom: 4,
  },
  categoryCP: {
    fontSize: 14,
    color: '#fff',
    opacity: 0.9,
  },
  categoryArrow: {
    position: 'absolute',
    right: 20,
  },
}); 