import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  Alert,
  Modal,
  TextInput,
  ActivityIndicator,
  RefreshControl,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { LinearGradient } from 'expo-linear-gradient';
import { Ionicons } from '@expo/vector-icons';
import { router } from 'expo-router';
import groupService, { Group, CreateGroupData } from '../../services/groupService';
import { useUser } from '../../components/UserContext';

export default function GroupsScreen() {
  const { user } = useUser();
  const [groups, setGroups] = useState<Group[]>([]);
  const [publicGroups, setPublicGroups] = useState<Group[]>([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [showJoinModal, setShowJoinModal] = useState(false);
  const [createForm, setCreateForm] = useState<CreateGroupData>({
    name: '',
    description: '',
    category: 'mixed',
    isPrivate: false,
    maxMembers: 50,
  });
  const [joinGroupId, setJoinGroupId] = useState('');
  const [submitting, setSubmitting] = useState(false);

  useEffect(() => {
    loadGroups();
  }, []);

  const loadGroups = async () => {
    try {
      setLoading(true);
      
      // Load user's groups
      const userGroups = await groupService.getUserGroups();
      setGroups(userGroups);
      await groupService.saveGroupsToStorage(userGroups);
      
      // Load public groups
      const allPublicGroups = await groupService.getAllGroups();
      setPublicGroups(allPublicGroups);
      
    } catch (error) {
      console.error('Error loading groups:', error);
      // Fallback to local storage
      const localGroups = await groupService.loadGroupsFromStorage();
      setGroups(localGroups);
    } finally {
      setLoading(false);
    }
  };

  const onRefresh = async () => {
    setRefreshing(true);
    await loadGroups();
    setRefreshing(false);
  };

  const handleCreateGroup = async () => {
    if (!createForm.name.trim() || !createForm.description.trim()) {
      Alert.alert('Error', 'Please fill in all required fields');
      return;
    }

    try {
      setSubmitting(true);
      const newGroup = await groupService.createGroup(createForm);
      
      setGroups(prev => [newGroup, ...prev]);
      await groupService.saveGroupsToStorage([newGroup, ...groups]);
      
      setShowCreateModal(false);
      setCreateForm({ name: '', description: '', category: 'mixed', isPrivate: false, maxMembers: 50 });
      
      Alert.alert('Success', 'Group created successfully!');
    } catch (error) {
      console.error('Error creating group:', error);
      Alert.alert('Error', error instanceof Error ? error.message : 'Failed to create group');
    } finally {
      setSubmitting(false);
    }
  };

  const handleJoinGroup = async () => {
    if (!joinGroupId.trim()) {
      Alert.alert('Error', 'Please enter a group ID');
      return;
    }

    try {
      setSubmitting(true);
      await groupService.joinGroup(joinGroupId.trim());
      
      // Refresh groups to show newly joined group
      await loadGroups();
      
      setShowJoinModal(false);
      setJoinGroupId('');
      
      Alert.alert('Success', 'Successfully joined the group!');
    } catch (error) {
      console.error('Error joining group:', error);
      Alert.alert('Error', error instanceof Error ? error.message : 'Failed to join group');
    } finally {
      setSubmitting(false);
    }
  };

  const handleLeaveGroup = async (groupId: string, groupName: string) => {
    Alert.alert(
      'Leave Group',
      `Are you sure you want to leave "${groupName}"?`,
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Leave',
          style: 'destructive',
          onPress: async () => {
            try {
              await groupService.leaveGroup(groupId);
              
              setGroups(prev => prev.filter(g => g.id !== groupId));
              await groupService.saveGroupsToStorage(groups.filter(g => g.id !== groupId));
              
              Alert.alert('Success', 'Successfully left the group');
            } catch (error) {
              console.error('Error leaving group:', error);
              Alert.alert('Error', error instanceof Error ? error.message : 'Failed to leave group');
            }
          },
        },
      ]
    );
  };

  const handleDeleteGroup = async (groupId: string, groupName: string) => {
    Alert.alert(
      'Delete Group',
      `Are you sure you want to delete "${groupName}"? This action cannot be undone.`,
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Delete',
          style: 'destructive',
          onPress: async () => {
            try {
              await groupService.deleteGroup(groupId);
              
              setGroups(prev => prev.filter(g => g.id !== groupId));
              await groupService.saveGroupsToStorage(groups.filter(g => g.id !== groupId));
              
              Alert.alert('Success', 'Group deleted successfully');
            } catch (error) {
              console.error('Error deleting group:', error);
              Alert.alert('Error', error instanceof Error ? error.message : 'Failed to delete group');
            }
          },
        },
      ]
    );
  };

  const navigateToGroup = (groupId: string) => {
    router.push(`/group/${groupId}`);
  };

  const renderGroupCard = (group: Group, isUserGroup: boolean = true) => (
    <TouchableOpacity
      key={group.id}
      style={styles.groupCard}
      onPress={() => navigateToGroup(group.id)}
    >
      <View style={styles.groupHeader}>
        <View style={styles.groupInfo}>
          <Text style={styles.groupName}>{group.name}</Text>
          {group.isPrivate && (
            <View style={styles.privateBadge}>
              <Ionicons name="lock-closed" size={12} color="#fff" />
              <Text style={styles.privateText}>Private</Text>
            </View>
          )}
        </View>
        {isUserGroup && group.isAdmin && (
          <View style={styles.adminBadge}>
            <Ionicons name="shield" size={12} color="#fff" />
            <Text style={styles.adminText}>Admin</Text>
          </View>
        )}
      </View>
      
      <Text style={styles.groupDescription} numberOfLines={2}>
        {group.description}
      </Text>
      
      <View style={styles.groupFooter}>
        <View style={styles.groupStats}>
          <Ionicons name="people" size={16} color="#666" />
          <Text style={styles.groupStatsText}>
            {group.memberCount || 0} members
          </Text>
        </View>
        
        {isUserGroup && (
          <View style={styles.groupActions}>
            {group.isAdmin ? (
              <TouchableOpacity
                style={[styles.actionButton, styles.deleteButton]}
                onPress={() => handleDeleteGroup(group.id, group.name)}
              >
                <Ionicons name="trash" size={16} color="#fff" />
                <Text style={styles.actionButtonText}>Delete</Text>
              </TouchableOpacity>
            ) : (
              <TouchableOpacity
                style={[styles.actionButton, styles.leaveButton]}
                onPress={() => handleLeaveGroup(group.id, group.name)}
              >
                <Ionicons name="exit" size={16} color="#fff" />
                <Text style={styles.actionButtonText}>Leave</Text>
              </TouchableOpacity>
            )}
          </View>
        )}
      </View>
    </TouchableOpacity>
  );

  const renderCreateGroupModal = () => (
    <Modal
      visible={showCreateModal}
      animationType="slide"
      transparent={true}
      onRequestClose={() => setShowCreateModal(false)}
    >
      <View style={styles.modalOverlay}>
        <View style={styles.modalContent}>
          <Text style={styles.modalTitle}>Create New Group</Text>
          
          <TextInput
            style={styles.input}
            placeholder="Group Name"
            value={createForm.name}
            onChangeText={(text) => setCreateForm(prev => ({ ...prev, name: text }))}
            maxLength={50}
          />
          
          <TextInput
            style={[styles.input, styles.textArea]}
            placeholder="Group Description"
            value={createForm.description}
            onChangeText={(text) => setCreateForm(prev => ({ ...prev, description: text }))}
            multiline
            numberOfLines={3}
            maxLength={200}
          />
          
          <View style={styles.categorySection}>
            <Text style={styles.formLabel}>Category:</Text>
            <View style={styles.categoryButtons}>
              {['mind', 'body', 'soul', 'mixed'].map((cat) => (
                <TouchableOpacity
                  key={cat}
                  style={[
                    styles.categoryButton,
                    createForm.category === cat && styles.categoryButtonActive
                  ]}
                  onPress={() => setCreateForm(prev => ({ ...prev, category: cat }))}
                >
                  <Text style={[
                    styles.categoryButtonText,
                    createForm.category === cat && styles.categoryButtonTextActive
                  ]}>
                    {cat.charAt(0).toUpperCase() + cat.slice(1)}
                  </Text>
                </TouchableOpacity>
              ))}
            </View>
          </View>
          
          <View style={styles.formRow}>
            <TouchableOpacity
              style={[
                styles.toggleButton,
                createForm.isPrivate && styles.toggleButtonActive
              ]}
              onPress={() => setCreateForm(prev => ({ ...prev, isPrivate: !prev.isPrivate }))}
            >
              <Ionicons 
                name={createForm.isPrivate ? "lock-closed" : "lock-open"} 
                size={16} 
                color={createForm.isPrivate ? "#fff" : "#666"} 
              />
              <Text style={[
                styles.toggleButtonText,
                createForm.isPrivate && styles.toggleButtonTextActive
              ]}>
                {createForm.isPrivate ? 'Private' : 'Public'}
              </Text>
            </TouchableOpacity>
            
            <TextInput
              style={[styles.input, styles.numberInput]}
              placeholder="Max Members"
              value={createForm.maxMembers.toString()}
              onChangeText={(text) => setCreateForm(prev => ({ ...prev, maxMembers: parseInt(text) || 50 }))}
              keyboardType="numeric"
              maxLength={3}
            />
          </View>
          
          <View style={styles.modalActions}>
            <TouchableOpacity
              style={[styles.modalButton, styles.cancelButton]}
              onPress={() => setShowCreateModal(false)}
            >
              <Text style={styles.cancelButtonText}>Cancel</Text>
            </TouchableOpacity>
            
            <TouchableOpacity
              style={[styles.modalButton, styles.createButton]}
              onPress={handleCreateGroup}
              disabled={submitting}
            >
              {submitting ? (
                <ActivityIndicator size="small" color="#fff" />
              ) : (
                <Text style={styles.createButtonText}>Create Group</Text>
              )}
            </TouchableOpacity>
          </View>
        </View>
      </View>
    </Modal>
  );

  const renderJoinGroupModal = () => (
    <Modal
      visible={showJoinModal}
      animationType="slide"
      transparent={true}
      onRequestClose={() => setShowJoinModal(false)}
    >
      <View style={styles.modalOverlay}>
        <View style={styles.modalContent}>
          <Text style={styles.modalTitle}>Join a Group</Text>
          
          <Text style={styles.modalSubtitle}>
            Enter the group ID to join. You can find this ID in the group details or ask a group member.
          </Text>
          
          <TextInput
            style={styles.input}
            placeholder="Group ID"
            value={joinGroupId}
            onChangeText={setJoinGroupId}
            autoCapitalize="none"
            autoCorrect={false}
          />
          
          <View style={styles.modalActions}>
            <TouchableOpacity
              style={[styles.modalButton, styles.cancelButton]}
              onPress={() => setShowJoinModal(false)}
            >
              <Text style={styles.cancelButtonText}>Cancel</Text>
            </TouchableOpacity>
            
            <TouchableOpacity
              style={[styles.modalButton, styles.joinButton]}
              onPress={handleJoinGroup}
              disabled={submitting}
            >
              {submitting ? (
                <ActivityIndicator size="small" color="#fff" />
              ) : (
                <Text style={styles.joinButtonText}>Join Group</Text>
              )}
            </TouchableOpacity>
          </View>
        </View>
      </View>
    </Modal>
  );

  if (loading) {
    return (
      <SafeAreaView style={styles.container}>
        <LinearGradient
          colors={['#667eea', '#764ba2']}
          style={styles.gradient}
        >
          <View style={styles.loadingContainer}>
            <ActivityIndicator size="large" color="#fff" />
            <Text style={styles.loadingText}>Loading groups...</Text>
          </View>
        </LinearGradient>
      </SafeAreaView>
    );
  }

  return (
    <SafeAreaView style={styles.container}>
      <LinearGradient
        colors={['#667eea', '#764ba2']}
        style={styles.gradient}
      >
        <View style={styles.header}>
          <Text style={styles.title}>Groups</Text>
          <Text style={styles.subtitle}>Connect, collaborate, and grow together</Text>
        </View>

        <View style={styles.actionButtons}>
          <TouchableOpacity
            style={[styles.actionButton, styles.createButton]}
            onPress={() => setShowCreateModal(true)}
          >
            <Ionicons name="add" size={20} color="#fff" />
            <Text style={styles.actionButtonText}>Create Group</Text>
          </TouchableOpacity>
          
          <TouchableOpacity
            style={[styles.actionButton, styles.joinButton]}
            onPress={() => setShowJoinModal(true)}
          >
            <Ionicons name="people" size={20} color="#fff" />
            <Text style={styles.actionButtonText}>Join Group</Text>
          </TouchableOpacity>
        </View>

        <ScrollView
          style={styles.content}
          contentContainerStyle={styles.contentContainer}
          refreshControl={
            <RefreshControl refreshing={refreshing} onRefresh={onRefresh} />
          }
        >
          {groups.length > 0 && (
            <View style={styles.section}>
              <Text style={styles.sectionTitle}>My Groups</Text>
              {groups.map(group => renderGroupCard(group, true))}
            </View>
          )}

          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Public Groups</Text>
            {publicGroups.length > 0 ? (
              publicGroups
                .filter(group => !groups.some(ug => ug.id === group.id))
                .map(group => renderGroupCard(group, false))
            ) : (
              <Text style={styles.emptyText}>No public groups available</Text>
            )}
          </View>

          {groups.length === 0 && publicGroups.length === 0 && (
            <View style={styles.emptyContainer}>
              <Ionicons name="people-outline" size={64} color="#666" />
              <Text style={styles.emptyTitle}>No Groups Yet</Text>
              <Text style={styles.emptySubtitle}>
                Create your first group or join an existing one to get started!
              </Text>
            </View>
          )}
        </ScrollView>

        {renderCreateGroupModal()}
        {renderJoinGroupModal()}
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
    padding: 20,
    paddingTop: 10,
  },
  title: {
    fontSize: 32,
    fontWeight: 'bold',
    color: '#fff',
    marginBottom: 8,
  },
  subtitle: {
    fontSize: 16,
    color: '#fff',
    opacity: 0.9,
  },
  actionButtons: {
    flexDirection: 'row',
    paddingHorizontal: 20,
    marginBottom: 20,
    gap: 12,
  },
  actionButton: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 12,
    paddingHorizontal: 16,
    borderRadius: 12,
    gap: 8,
  },
  createButton: {
    backgroundColor: '#4CAF50',
  },
  joinButton: {
    backgroundColor: '#2196F3',
  },
  actionButtonText: {
    color: '#fff',
    fontWeight: '600',
    fontSize: 14,
  },
  content: {
    flex: 1,
    backgroundColor: '#f5f5f5',
  },
  contentContainer: {
    padding: 20,
  },
  section: {
    marginBottom: 24,
  },
  sectionTitle: {
    fontSize: 20,
    fontWeight: 'bold',
    color: '#333',
    marginBottom: 16,
  },
  groupCard: {
    backgroundColor: '#fff',
    borderRadius: 16,
    padding: 20,
    marginBottom: 16,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 8,
    elevation: 3,
  },
  groupHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    marginBottom: 12,
  },
  groupInfo: {
    flex: 1,
  },
  groupName: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#333',
    marginBottom: 4,
  },
  privateBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#FF9800',
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 12,
    alignSelf: 'flex-start',
    gap: 4,
  },
  privateText: {
    color: '#fff',
    fontSize: 10,
    fontWeight: '600',
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
  adminText: {
    color: '#fff',
    fontSize: 10,
    fontWeight: '600',
  },
  groupDescription: {
    fontSize: 14,
    color: '#666',
    lineHeight: 20,
    marginBottom: 16,
  },
  groupFooter: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  groupStats: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
  },
  groupStatsText: {
    fontSize: 14,
    color: '#666',
  },
  groupActions: {
    flexDirection: 'row',
    gap: 8,
  },
  leaveButton: {
    backgroundColor: '#FF5722',
  },
  deleteButton: {
    backgroundColor: '#F44336',
  },
  emptyContainer: {
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 60,
  },
  emptyTitle: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#666',
    marginTop: 16,
    marginBottom: 8,
  },
  emptySubtitle: {
    fontSize: 16,
    color: '#999',
    textAlign: 'center',
    lineHeight: 24,
  },
  emptyText: {
    fontSize: 16,
    color: '#999',
    textAlign: 'center',
    fontStyle: 'italic',
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
  modalOverlay: {
    flex: 1,
    backgroundColor: 'rgba(0, 0, 0, 0.5)',
    justifyContent: 'center',
    alignItems: 'center',
  },
  modalContent: {
    backgroundColor: '#fff',
    borderRadius: 20,
    padding: 24,
    width: '90%',
    maxWidth: 400,
  },
  modalTitle: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#333',
    marginBottom: 16,
    textAlign: 'center',
  },
  modalSubtitle: {
    fontSize: 14,
    color: '#666',
    textAlign: 'center',
    marginBottom: 20,
    lineHeight: 20,
  },
  input: {
    borderWidth: 1,
    borderColor: '#ddd',
    borderRadius: 12,
    padding: 16,
    fontSize: 16,
    marginBottom: 16,
    backgroundColor: '#f9f9f9',
  },
  textArea: {
    height: 80,
    textAlignVertical: 'top',
  },
  numberInput: {
    width: 120,
  },
  formRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 24,
  },
  formLabel: {
    fontSize: 16,
    fontWeight: '600',
    color: '#333',
    marginBottom: 12,
  },
  categoryButtons: {
    flexDirection: 'row',
    gap: 8,
  },
  categoryButton: {
    paddingHorizontal: 16,
    paddingVertical: 8,
    borderRadius: 20,
    borderWidth: 1,
    borderColor: '#ddd',
    backgroundColor: '#f9f9f9',
  },
  categoryButtonActive: {
    backgroundColor: '#2196F3',
    borderColor: '#2196F3',
  },
  categoryButtonText: {
    fontSize: 14,
    color: '#666',
    fontWeight: '500',
  },
  categoryButtonTextActive: {
    color: '#fff',
    fontWeight: '600',
  },
  categorySection: {
    marginBottom: 24,
  },
  toggleButton: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingVertical: 12,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: '#ddd',
    backgroundColor: '#f9f9f9',
    gap: 8,
  },
  toggleButtonActive: {
    backgroundColor: '#2196F3',
    borderColor: '#2196F3',
  },
  toggleButtonText: {
    fontSize: 14,
    color: '#666',
    fontWeight: '600',
  },
  toggleButtonTextActive: {
    color: '#fff',
  },
  modalActions: {
    flexDirection: 'row',
    gap: 12,
  },
  modalButton: {
    flex: 1,
    paddingVertical: 16,
    borderRadius: 12,
    alignItems: 'center',
  },
  cancelButton: {
    backgroundColor: '#f5f5f5',
  },
  cancelButtonText: {
    color: '#666',
    fontWeight: '600',
    fontSize: 16,
  },
  createButtonText: {
    color: '#fff',
    fontWeight: '600',
    fontSize: 16,
  },
  joinButtonText: {
    color: '#fff',
    fontWeight: '600',
    fontSize: 16,
  },
});
