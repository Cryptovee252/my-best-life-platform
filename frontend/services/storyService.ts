import AsyncStorage from '@react-native-async-storage/async-storage';

const API_BASE_URL = 'http://localhost:3000/api';

export interface Story {
  id: string;
  title: string;
  author: string;
  avatarUrl?: string;
  cp: number;
  date: string;
  time: string;
  imageUrl?: string;
  description: string;
  commentsCount: number;
  liked: boolean;
  caption?: string;
  category?: 'mind' | 'body' | 'soul';
  userId: string;
  createdAt: string;
  updatedAt: string;
}

export interface Comment {
  id: string;
  content: string;
  author: string;
  avatarUrl?: string;
  storyId: string;
  userId: string;
  createdAt: string;
  updatedAt: string;
}

export interface CreateStoryData {
  title: string;
  description: string;
  category?: 'mind' | 'body' | 'soul';
  caption?: string;
  imageUrl?: string;
}

export interface UpdateStoryData {
  title?: string;
  description?: string;
  category?: 'mind' | 'body' | 'soul';
  caption?: string;
  imageUrl?: string;
}

class StoryService {
  private async getAuthToken(): Promise<string | null> {
    try {
      return await AsyncStorage.getItem('auth_token');
    } catch (error) {
      console.error('Error getting auth token:', error);
      return null;
    }
  }

  private getAuthHeaders(): HeadersInit {
    const headers: HeadersInit = {
      'Content-Type': 'application/json',
    };
    
    return headers;
  }

  // Get all stories (public)
  async getAllStories(): Promise<Story[]> {
    try {
      const response = await fetch(`${API_BASE_URL}/stories`, {
        method: 'GET',
        headers: this.getAuthHeaders(),
      });

      if (!response.ok) {
        throw new Error(`Failed to fetch stories: ${response.status}`);
      }

      const data = await response.json();
      return data.stories || [];
    } catch (error) {
      console.error('Error fetching all stories:', error);
      throw error;
    }
  }

  // Get stories by user
  async getUserStories(userId: string): Promise<Story[]> {
    try {
      const token = await this.getAuthToken();
      if (!token) {
        throw new Error('Authentication required');
      }

      const response = await fetch(`${API_BASE_URL}/stories/user/${userId}`, {
        method: 'GET',
        headers: {
          ...this.getAuthHeaders(),
          'Authorization': `Bearer ${token}`,
        },
      });

      if (!response.ok) {
        throw new Error(`Failed to fetch user stories: ${response.status}`);
      }

      const data = await response.json();
      return data.stories || [];
    } catch (error) {
      console.error('Error fetching user stories:', error);
      throw error;
    }
  }

  // Create a new story
  async createStory(storyData: CreateStoryData): Promise<Story> {
    try {
      const token = await this.getAuthToken();
      if (!token) {
        throw new Error('Authentication required');
      }

      const response = await fetch(`${API_BASE_URL}/stories`, {
        method: 'POST',
        headers: {
          ...this.getAuthHeaders(),
          'Authorization': `Bearer ${token}`,
        },
        body: JSON.stringify(storyData),
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.error || `Failed to create story: ${response.status}`);
      }

      const data = await response.json();
      return data.story;
    } catch (error) {
      console.error('Error creating story:', error);
      throw error;
    }
  }

  // Update a story
  async updateStory(storyId: string, storyData: UpdateStoryData): Promise<Story> {
    try {
      const token = await this.getAuthToken();
      if (!token) {
        throw new Error('Authentication required');
      }

      const response = await fetch(`${API_BASE_URL}/stories/${storyId}`, {
        method: 'PUT',
        headers: {
          ...this.getAuthHeaders(),
          'Authorization': `Bearer ${token}`,
        },
        body: JSON.stringify(storyData),
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.error || `Failed to update story: ${response.status}`);
      }

      const data = await response.json();
      return data.story;
    } catch (error) {
      console.error('Error updating story:', error);
      throw error;
    }
  }

  // Delete a story
  async deleteStory(storyId: string): Promise<void> {
    try {
      const token = await this.getAuthToken();
      if (!token) {
        throw new Error('Authentication required');
      }

      const response = await fetch(`${API_BASE_URL}/stories/${storyId}`, {
        method: 'DELETE',
        headers: {
          ...this.getAuthHeaders(),
          'Authorization': `Bearer ${token}`,
        },
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.error || `Failed to delete story: ${response.status}`);
      }
    } catch (error) {
      console.error('Error deleting story:', error);
      throw error;
    }
  }

  // Toggle like on a story
  async toggleStoryLike(storyId: string): Promise<boolean> {
    try {
      const token = await this.getAuthToken();
      if (!token) {
        throw new Error('Authentication required');
      }

      const response = await fetch(`${API_BASE_URL}/stories/${storyId}/like`, {
        method: 'POST',
        headers: {
          ...this.getAuthHeaders(),
          'Authorization': `Bearer ${token}`,
        },
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.error || `Failed to toggle story like: ${response.status}`);
      }

      const data = await response.json();
      return data.liked;
    } catch (error) {
      console.error('Error toggling story like:', error);
      throw error;
    }
  }

  // Load stories from local storage (fallback)
  async loadStoriesFromStorage(): Promise<Story[]> {
    try {
      const savedStories = await AsyncStorage.getItem('user_stories');
      if (savedStories) {
        const parsedStories = JSON.parse(savedStories);
        if (Array.isArray(parsedStories)) {
          return parsedStories;
        }
      }
      return [];
    } catch (error) {
      console.error('Error loading stories from storage:', error);
      return [];
    }
  }

  // Save stories to local storage (fallback)
  async saveStoriesToStorage(stories: Story[]): Promise<void> {
    try {
      if (Array.isArray(stories) && stories.length > 0) {
        await AsyncStorage.setItem('user_stories', JSON.stringify(stories));
      }
    } catch (error) {
      console.error('Error saving stories to storage:', error);
    }
  }

  // Sync local stories with backend (for migration)
  async syncLocalStoriesWithBackend(): Promise<void> {
    try {
      const localStories = await this.loadStoriesFromStorage();
      if (localStories.length === 0) return;

      const token = await this.getAuthToken();
      if (!token) {
        console.warn('No auth token, skipping sync');
        return;
      }

      // Get user ID from token
      const tokenData = JSON.parse(atob(token.split('.')[1]));
      const userId = tokenData.userId;

      // Upload each local story to backend
      for (const story of localStories) {
        try {
          await this.createStory({
            title: story.title,
            description: story.description,
            category: story.category,
            caption: story.caption,
            imageUrl: story.imageUrl,
          });
        } catch (error) {
          console.error(`Failed to sync story ${story.id}:`, error);
        }
      }

      // Clear local storage after successful sync
      await AsyncStorage.removeItem('user_stories');
      console.log('Successfully synced local stories with backend');
    } catch (error) {
      console.error('Error syncing local stories:', error);
    }
  }

  // Get comments for a story
  async getStoryComments(storyId: string): Promise<Comment[]> {
    try {
      const response = await fetch(`${API_BASE_URL}/stories/${storyId}/comments`, {
        method: 'GET',
        headers: this.getAuthHeaders(),
      });

      if (!response.ok) {
        throw new Error(`Failed to fetch comments: ${response.status}`);
      }

      const data = await response.json();
      return data.comments || [];
    } catch (error) {
      console.error('Error fetching comments:', error);
      throw error;
    }
  }

  // Add comment to a story
  async addComment(storyId: string, content: string): Promise<Comment> {
    try {
      const token = await this.getAuthToken();
      if (!token) {
        throw new Error('Authentication required');
      }

      const response = await fetch(`${API_BASE_URL}/stories/${storyId}/comments`, {
        method: 'POST',
        headers: {
          ...this.getAuthHeaders(),
          'Authorization': `Bearer ${token}`,
        },
        body: JSON.stringify({ content }),
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.error || `Failed to add comment: ${response.status}`);
      }

      const data = await response.json();
      return data.comment;
    } catch (error) {
      console.error('Error adding comment:', error);
      throw error;
    }
  }

  // Delete comment
  async deleteComment(storyId: string, commentId: string): Promise<void> {
    try {
      const token = await this.getAuthToken();
      if (!token) {
        throw new Error('Authentication required');
      }

      const response = await fetch(`${API_BASE_URL}/stories/${storyId}/comments/${commentId}`, {
        method: 'DELETE',
        headers: {
          ...this.getAuthHeaders(),
          'Authorization': `Bearer ${token}`,
        },
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.error || `Failed to delete comment: ${response.status}`);
      }
    } catch (error) {
      console.error('Error deleting comment:', error);
      throw error;
    }
  }
}

export const storyService = new StoryService();
export default storyService;
