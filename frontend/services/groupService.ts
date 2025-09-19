import AsyncStorage from '@react-native-async-storage/async-storage';

import { API_BASE_URL } from '@/constants/api';

export interface Group {
  id: string;
  name: string;
  description: string;
  category?: string; // Added to match backend
  isPrivate: boolean;
  maxMembers: number;
  createdBy: string; // Changed from creatorId to match backend
  creatorName?: string;
  memberCount?: number;
  isAdmin?: boolean;
  joinedAt?: string;
  createdAt: string;
  updatedAt: string;
  members?: GroupMember[];
}

export interface GroupMember {
  id: string;
  groupId: string;
  userId: string;
  role: string; // Changed from isAdmin to role to match backend
  joinedAt: string;
  name?: string;
  username?: string;
  profilePic?: string;
  email?: string;
}

export interface GroupStory {
  id: string;
  title: string;
  content: string;
  category: 'mind' | 'body' | 'soul';
  groupId: string;
  authorId: string;
  authorName?: string;
  authorUsername?: string;
  likesCount?: number;
  commentsCount?: number;
  createdAt: string;
  updatedAt: string;
}

export interface GroupMessage {
  id: string;
  content: string;
  groupId: string;
  senderId: string;
  senderName?: string;
  senderUsername?: string;
  senderPic?: string;
  reactionsCount?: number;
  createdAt: string;
  updatedAt: string;
}

export interface GroupTask {
  id: string;
  title: string;
  description: string;
  category: 'mind' | 'body' | 'soul';
  points: number;
  dueDate?: string;
  completed: boolean;
  groupId: string;
  creatorId: string;
  creatorName?: string;
  creatorUsername?: string;
  createdAt: string;
  updatedAt: string;
}

export interface GroupCP {
  mindCP: number;
  bodyCP: number;
  soulCP: number;
  totalCP: number;
  totalTasks: number;
}

export interface CreateGroupData {
  name: string;
  description: string;
  category?: string; // Added to match backend
  isPrivate?: boolean;
  maxMembers?: number;
}

export interface CreateGroupStoryData {
  title: string;
  content: string;
  category: 'mind' | 'body' | 'soul';
}

export interface CreateGroupTaskData {
  title: string;
  description: string;
  category: 'mind' | 'body' | 'soul';
  points: number;
  dueDate?: string;
}

class GroupService {
  private async getAuthToken(): Promise<string | null> {
    try {
      return await AsyncStorage.getItem('auth_token');
    } catch (error) {
      console.error('Error getting auth token:', error);
      return null;
    }
  }

  private getAuthHeaders(): HeadersInit {
    const token = this.getAuthToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${token}`,
    };
  }

  // ===== GROUP MANAGEMENT =====

  async getAllGroups(): Promise<Group[]> {
    try {
      const response = await fetch(`${API_BASE_URL}/groups`);
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }
      return await response.json();
    } catch (error) {
      console.error('Error fetching groups:', error);
      throw error;
    }
  }

  async getUserGroups(): Promise<Group[]> {
    try {
      const token = await this.getAuthToken();
      if (!token) {
        throw new Error('No auth token available');
      }

      const response = await fetch(`${API_BASE_URL}/groups/my`, {
        headers: {
          'Authorization': `Bearer ${token}`,
        },
      });

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      return await response.json();
    } catch (error) {
      console.error('Error fetching user groups:', error);
      throw error;
    }
  }

  async getGroupById(groupId: string): Promise<Group> {
    try {
      const response = await fetch(`${API_BASE_URL}/groups/${groupId}`);
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }
      return await response.json();
    } catch (error) {
      console.error('Error fetching group:', error);
      throw error;
    }
  }

  async createGroup(groupData: CreateGroupData): Promise<Group> {
    try {
      const token = await this.getAuthToken();
      if (!token) {
        throw new Error('No auth token available');
      }

      const response = await fetch(`${API_BASE_URL}/groups`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`,
        },
        body: JSON.stringify(groupData),
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.error || `HTTP error! status: ${response.status}`);
      }

      return await response.json();
    } catch (error) {
      console.error('Error creating group:', error);
      throw error;
    }
  }

  async joinGroup(groupId: string): Promise<{ message: string }> {
    try {
      const token = await this.getAuthToken();
      if (!token) {
        throw new Error('No auth token available');
      }

      const response = await fetch(`${API_BASE_URL}/groups/${groupId}/join`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${token}`,
        },
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.error || `HTTP error! status: ${response.status}`);
      }

      return await response.json();
    } catch (error) {
      console.error('Error joining group:', error);
      throw error;
    }
  }

  async leaveGroup(groupId: string): Promise<{ message: string }> {
    try {
      const token = await this.getAuthToken();
      if (!token) {
        throw new Error('No auth token available');
      }

      const response = await fetch(`${API_BASE_URL}/groups/${groupId}/leave`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${token}`,
        },
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.error || `HTTP error! status: ${response.status}`);
      }

      return await response.json();
    } catch (error) {
      console.error('Error leaving group:', error);
      throw error;
    }
  }

  async deleteGroup(groupId: string): Promise<{ message: string }> {
    try {
      const token = await this.getAuthToken();
      if (!token) {
        throw new Error('No auth token available');
      }

      const response = await fetch(`${API_BASE_URL}/groups/${groupId}`, {
        method: 'DELETE',
        headers: {
          'Authorization': `Bearer ${token}`,
        },
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.error || `HTTP error! status: ${response.status}`);
      }

      return await response.json();
    } catch (error) {
      console.error('Error deleting group:', error);
      throw error;
    }
  }

  // ===== GROUP STORIES =====

  async getGroupStories(groupId: string): Promise<GroupStory[]> {
    try {
      const response = await fetch(`${API_BASE_URL}/groups/${groupId}/stories`);
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }
      return await response.json();
    } catch (error) {
      console.error('Error fetching group stories:', error);
      throw error;
    }
  }

  async createGroupStory(groupId: string, storyData: CreateGroupStoryData): Promise<GroupStory> {
    try {
      const token = await this.getAuthToken();
      if (!token) {
        throw new Error('No auth token available');
      }

      const response = await fetch(`${API_BASE_URL}/groups/${groupId}/stories`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`,
        },
        body: JSON.stringify(storyData),
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.error || `HTTP error! status: ${response.status}`);
      }

      return await response.json();
    } catch (error) {
      console.error('Error creating group story:', error);
      throw error;
    }
  }

  // ===== GROUP MESSAGES =====

  async getGroupMessages(groupId: string): Promise<GroupMessage[]> {
    try {
      const token = await this.getAuthToken();
      if (!token) {
        throw new Error('No auth token available');
      }

      const response = await fetch(`${API_BASE_URL}/groups/${groupId}/messages`, {
        headers: {
          'Authorization': `Bearer ${token}`,
        },
      });

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      return await response.json();
    } catch (error) {
      console.error('Error fetching group messages:', error);
      throw error;
    }
  }

  async sendGroupMessage(groupId: string, content: string): Promise<GroupMessage> {
    try {
      const token = await this.getAuthToken();
      if (!token) {
        throw new Error('No auth token available');
      }

      const response = await fetch(`${API_BASE_URL}/groups/${groupId}/messages`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`,
        },
        body: JSON.stringify({ content }),
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.error || `HTTP error! status: ${response.status}`);
      }

      return await response.json();
    } catch (error) {
      console.error('Error sending group message:', error);
      throw error;
    }
  }

  // ===== GROUP TASKS =====

  async getGroupTasks(groupId: string): Promise<GroupTask[]> {
    try {
      const token = await this.getAuthToken();
      if (!token) {
        throw new Error('No auth token available');
      }

      const response = await fetch(`${API_BASE_URL}/groups/${groupId}/tasks`, {
        headers: {
          'Authorization': `Bearer ${token}`,
        },
      });

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      return await response.json();
    } catch (error) {
      console.error('Error fetching group tasks:', error);
      throw error;
    }
  }

  async createGroupTask(groupId: string, taskData: CreateGroupTaskData): Promise<GroupTask> {
    try {
      const token = await this.getAuthToken();
      if (!token) {
        throw new Error('No auth token available');
      }

      const response = await fetch(`${API_BASE_URL}/groups/${groupId}/tasks`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`,
        },
        body: JSON.stringify(taskData),
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.error || `HTTP error! status: ${response.status}`);
      }

      return await response.json();
    } catch (error) {
      console.error('Error creating group task:', error);
      throw error;
    }
  }

  // ===== GROUP CP TRACKING =====

  async getGroupCP(groupId: string): Promise<GroupCP> {
    try {
      const token = await this.getAuthToken();
      if (!token) {
        throw new Error('No auth token available');
      }

      const response = await fetch(`${API_BASE_URL}/groups/${groupId}/cp`, {
        headers: {
          'Authorization': `Bearer ${token}`,
        },
      });

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      return await response.json();
    } catch (error) {
      console.error('Error fetching group CP:', error);
      throw error;
    }
  }

  // ===== ADMIN CONTROLS =====

  async getGroupMembers(groupId: string): Promise<GroupMember[]> {
    try {
      const token = await this.getAuthToken();
      if (!token) {
        throw new Error('No auth token available');
      }

      const response = await fetch(`${API_BASE_URL}/groups/${groupId}/members`, {
        headers: {
          'Authorization': `Bearer ${token}`,
        },
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.error || `HTTP error! status: ${response.status}`);
      }

      return await response.json();
    } catch (error) {
      console.error('Error fetching group members:', error);
      throw error;
    }
  }

  async updateMemberRole(groupId: string, userId: string, isAdmin: boolean): Promise<{ message: string }> {
    try {
      const token = await this.getAuthToken();
      if (!token) {
        throw new Error('No auth token available');
      }

      const response = await fetch(`${API_BASE_URL}/groups/${groupId}/members/${userId}/role`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`,
        },
        body: JSON.stringify({ isAdmin }),
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.error || `HTTP error! status: ${response.status}`);
      }

      return await response.json();
    } catch (error) {
      console.error('Error updating member role:', error);
      throw error;
    }
  }

  async removeMember(groupId: string, userId: string): Promise<{ message: string }> {
    try {
      const token = await this.getAuthToken();
      if (!token) {
        throw new Error('No auth token available');
      }

      const response = await fetch(`${API_BASE_URL}/groups/${groupId}/members/${userId}`, {
        method: 'DELETE',
        headers: {
          'Authorization': `Bearer ${token}`,
        },
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.error || `HTTP error! status: ${response.status}`);
      }

      return await response.json();
    } catch (error) {
      console.error('Error removing member:', error);
      throw error;
    }
  }

  // ===== LOCAL STORAGE =====

  async saveGroupsToStorage(groups: Group[]): Promise<void> {
    try {
      await AsyncStorage.setItem('userGroups', JSON.stringify(groups));
    } catch (error) {
      console.error('Error saving groups to storage:', error);
    }
  }

  async loadGroupsFromStorage(): Promise<Group[]> {
    try {
      const groupsData = await AsyncStorage.getItem('userGroups');
      return groupsData ? JSON.parse(groupsData) : [];
    } catch (error) {
      console.error('Error loading groups from storage:', error);
      return [];
    }
  }

  async saveGroupStoriesToStorage(groupId: string, stories: GroupStory[]): Promise<void> {
    try {
      const key = `groupStories_${groupId}`;
      await AsyncStorage.setItem(key, JSON.stringify(stories));
    } catch (error) {
      console.error('Error saving group stories to storage:', error);
    }
  }

  async loadGroupStoriesFromStorage(groupId: string): Promise<GroupStory[]> {
    try {
      const key = `groupStories_${groupId}`;
      const storiesData = await AsyncStorage.getItem(key);
      return storiesData ? JSON.parse(storiesData) : [];
    } catch (error) {
      console.error('Error loading group stories from storage:', error);
      return [];
    }
  }

  async saveGroupMessagesToStorage(groupId: string, messages: GroupMessage[]): Promise<void> {
    try {
      const key = `groupMessages_${groupId}`;
      await AsyncStorage.setItem(key, JSON.stringify(messages));
    } catch (error) {
      console.error('Error saving group messages to storage:', error);
    }
  }

  async loadGroupMessagesFromStorage(groupId: string): Promise<GroupMessage[]> {
    try {
      const key = `groupMessages_${groupId}`;
      const messagesData = await AsyncStorage.getItem(key);
      return messagesData ? JSON.parse(messagesData) : [];
    } catch (error) {
      console.error('Error loading group messages from storage:', error);
      return [];
    }
  }

  async saveGroupTasksToStorage(groupId: string, tasks: GroupTask[]): Promise<void> {
    try {
      const key = `groupTasks_${groupId}`;
      await AsyncStorage.setItem(key, JSON.stringify(tasks));
    } catch (error) {
      console.error('Error saving group tasks to storage:', error);
    }
  }

  async loadGroupTasksFromStorage(groupId: string): Promise<GroupTask[]> {
    try {
      const key = `groupTasks_${groupId}`;
      const tasksData = await AsyncStorage.getItem(key);
      return tasksData ? JSON.parse(tasksData) : [];
    } catch (error) {
      console.error('Error loading group tasks from storage:', error);
      return [];
    }
  }
}

export const groupService = new GroupService();
export default groupService;
