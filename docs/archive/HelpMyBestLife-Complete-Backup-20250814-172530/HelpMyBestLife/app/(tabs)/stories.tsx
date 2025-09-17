import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  FlatList,
  TouchableOpacity,
  Modal,
  TextInput,
  Image,
  Dimensions,
  Animated,
  Alert,
  ScrollView,
} from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { LinearGradient } from 'expo-linear-gradient';
import { Ionicons, MaterialCommunityIcons, FontAwesome5 } from '@expo/vector-icons';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { useUser } from '@/components/UserContext';
import { useNotification } from '@/components/NotificationContext';
import storyService, { Story, Comment } from '@/services/storyService';

const { width, height } = Dimensions.get('window');

// Story type is now imported from storyService

const STORIES_KEY = 'user_stories';

const MOCK_STORIES: Story[] = [
  {
    id: '1',
    title: 'Good Karma',
    author: 'Malorie Faidley',
    avatarUrl: require('@/assets/images/avatar_women_44.jpg'),
    cp: 948,
    date: '2019-10-21',
    time: '10:14 PM',
    imageUrl: require('@/assets/images/story_karma.png'),
    description: 'Good Karma\n~ Note to Self ~\n\n"What is my purpose in life?" I asked the void.\n\nThe void replied, "To be kind, to be compassionate, to be understanding."\n\nI smiled and said, "That sounds simple enough."\n\nThe void smiled back and said, "Simple, but not easy."',
    commentsCount: 2,
    liked: true,
    caption: 'Do kind acts with no strings attached.',
    category: 'soul',
    userId: 'mock-user-1',
    createdAt: '2019-10-21T10:14:00.000Z',
    updatedAt: '2019-10-21T10:14:00.000Z',
  },
  {
    id: '2',
    title: 'Mommy & Daughter!',
    author: 'Malorie Faidley',
    avatarUrl: require('@/assets/images/avatar_women_44.jpg'),
    cp: 948,
    date: '2019-10-21',
    time: '03:14 PM',
    imageUrl: require('@/assets/images/story_mommy.jpg'),
    description: 'Spending quality time with my daughter today. These moments are precious and remind me of what truly matters in life.',
    commentsCount: 0,
    liked: false,
    caption: 'Family time is the best time.',
    category: 'soul',
    userId: 'mock-user-2',
    createdAt: '2019-10-21T15:14:00.000Z',
    updatedAt: '2019-10-21T15:14:00.000Z',
  },
];

export default function StoriesScreen() {
  const insets = useSafeAreaInsets();
  const { user } = useUser();
  const { addNotification } = useNotification();
  
  const [stories, setStories] = useState<Story[]>(MOCK_STORIES);
  const [modalVisible, setModalVisible] = useState(false);
  const [newTitle, setNewTitle] = useState('');
  const [newDescription, setNewDescription] = useState('');
  const [newCategory, setNewCategory] = useState<'mind' | 'body' | 'soul'>('mind');
  const [fadeAnim] = useState(new Animated.Value(0));
  const [slideAnim] = useState(new Animated.Value(50));
  
  // Comment states
  const [comments, setComments] = useState<{ [storyId: string]: Comment[] }>({});
  const [showComments, setShowComments] = useState<{ [storyId: string]: boolean }>({});
  const [newComment, setNewComment] = useState<{ [storyId: string]: string }>({});
  const [commentingStoryId, setCommentingStoryId] = useState<string | null>(null);

  useEffect(() => {
    loadStories();
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

  const loadStories = async () => {
    try {
      // Always try to load from backend first
      try {
        const backendStories = await storyService.getAllStories();
        if (backendStories && backendStories.length > 0) {
          setStories(backendStories);
          // Load comments for each story
          for (const story of backendStories) {
            try {
              const storyComments = await storyService.getStoryComments(story.id);
              setComments(prev => ({ ...prev, [story.id]: storyComments }));
            } catch (error) {
              console.warn(`Failed to load comments for story ${story.id}:`, error);
            }
          }
          return;
        }
      } catch (error) {
        console.warn('Failed to load from backend, falling back to local storage:', error);
      }

      // Fallback to local storage
      const savedStories = await AsyncStorage.getItem(STORIES_KEY);
      if (savedStories) {
        const parsedStories = JSON.parse(savedStories);
        if (Array.isArray(parsedStories)) {
          const existingIds = new Set(MOCK_STORIES.map(s => s.id));
          const newStories = parsedStories.filter((story: Story) => !existingIds.has(story.id));
          setStories([...MOCK_STORIES, ...newStories]);
        } else {
          setStories(MOCK_STORIES);
        }
      } else {
        setStories(MOCK_STORIES);
      }
    } catch (error) {
      console.error('Error loading stories:', error);
      setStories(MOCK_STORIES);
    }
  };

  const saveStories = async (newStories: Story[]) => {
    try {
      // Ensure we have valid stories to save
      if (Array.isArray(newStories) && newStories.length > 0) {
        await AsyncStorage.setItem(STORIES_KEY, JSON.stringify(newStories));
      }
    } catch (error) {
      console.error('Error saving stories:', error);
    }
  };

  const handleAddStory = async () => {
    if (!newTitle.trim() || !newDescription.trim()) {
      Alert.alert('Error', 'Please fill in both title and description');
      return;
    }

    try {
      // Create story in backend
      const newStory = await storyService.createStory({
        title: newTitle,
        description: newDescription,
        category: newCategory,
        caption: '',
        imageUrl: '',
      });

      // Add to local state
      const updatedStories = [newStory, ...stories];
      setStories(updatedStories);
      
      // Also save to local storage as backup
      saveStories(updatedStories);
      
      setNewTitle('');
      setNewDescription('');
      setNewCategory('mind');
      setModalVisible(false);
      
      addNotification('Story added successfully!', 'success');
    } catch (error) {
      console.error('Error creating story:', error);
      addNotification('Failed to create story. Please try again.', 'error');
    }
  };

  const handleToggleLike = async (id: string) => {
    try {
      // Toggle like in backend
      const newLiked = await storyService.toggleStoryLike(id);
      
      // Update local state
      const updatedStories = stories.map((story) =>
        story.id === id ? { ...story, liked: newLiked } : story
      );
      setStories(updatedStories);
      saveStories(updatedStories);
    } catch (error) {
      console.error('Error toggling story like:', error);
      addNotification('Failed to update story like. Please try again.', 'error');
    }
  };

  const toggleComments = (storyId: string) => {
    setShowComments(prev => ({ ...prev, [storyId]: !prev[storyId] }));
  };

  const handleAddComment = async (storyId: string) => {
    const commentContent = newComment[storyId]?.trim();
    if (!commentContent) return;

    try {
      const newCommentObj = await storyService.addComment(storyId, commentContent);
      
      // Update comments state
      setComments(prev => ({
        ...prev,
        [storyId]: [...(prev[storyId] || []), newCommentObj]
      }));

      // Update story comment count
      const updatedStories = stories.map(story =>
        story.id === storyId 
          ? { ...story, commentsCount: story.commentsCount + 1 }
          : story
      );
      setStories(updatedStories);

      // Clear comment input
      setNewComment(prev => ({ ...prev, [storyId]: '' }));
      setCommentingStoryId(null);
      
      addNotification('Comment added successfully!', 'success');
    } catch (error) {
      console.error('Error adding comment:', error);
      addNotification('Failed to add comment. Please try again.', 'error');
    }
  };

  const handleDeleteComment = async (storyId: string, commentId: string) => {
    try {
      await storyService.deleteComment(storyId, commentId);
      
      // Remove comment from state
      setComments(prev => ({
        ...prev,
        [storyId]: (prev[storyId] || []).filter(c => c.id !== commentId)
      }));

      // Update story comment count
      const updatedStories = stories.map(story =>
        story.id === storyId 
          ? { ...story, commentsCount: Math.max(0, story.commentsCount - 1) }
          : story
      );
      setStories(updatedStories);
      
      addNotification('Comment deleted successfully', 'success');
    } catch (error) {
      console.error('Error deleting comment:', error);
      addNotification('Failed to delete comment. Please try again.', 'error');
    }
  };

  const handleDeleteStory = (id: string) => {
    Alert.alert(
      'Delete Story',
      'Are you sure you want to delete this story?',
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Delete',
          style: 'destructive',
          onPress: async () => {
            try {
              // Delete from backend
              await storyService.deleteStory(id);
              
              // Remove from local state
              const updatedStories = stories.filter(story => story.id !== id);
              setStories(updatedStories);
              saveStories(updatedStories);
              
              addNotification('Story deleted successfully', 'success');
            } catch (error) {
              console.error('Error deleting story:', error);
              addNotification('Failed to delete story. Please try again.', 'error');
            }
          },
        },
      ]
    );
  };

  const renderStory = ({ item }: { item: Story }) => (
    <Animated.View style={[styles.storyCard, { opacity: fadeAnim }]}>
      <LinearGradient
        colors={['#222', '#1a1a1a']}
        style={styles.cardGradient}
      >
        {/* Header */}
        <View style={styles.storyHeader}>
          <Image 
            source={item.avatarUrl ? (typeof item.avatarUrl === 'string' ? { uri: item.avatarUrl } : item.avatarUrl) : require('@/assets/images/MBL_Logo.webp')} 
            style={styles.avatar} 
          />
          <View style={styles.authorInfo}>
            <Text style={styles.author}>{item.author}</Text>
            <Text style={styles.cp}>CP: <Text style={styles.cpValue}>{item.cp}</Text></Text>
          </View>
          <View style={styles.headerRight}>
            <Text style={styles.date}>{formatDateTime(item.date, item.time)}</Text>
            {item.author === user.name && (
              <TouchableOpacity
                style={styles.deleteButton}
                onPress={() => handleDeleteStory(item.id)}
              >
                <Ionicons name="trash-outline" size={16} color="#ff4136" />
              </TouchableOpacity>
            )}
          </View>
        </View>

        {/* Content */}
        <View style={styles.storyContent}>
          <Text style={styles.storyTitle}>{item.title}</Text>
          {item.description && (
            <Text style={styles.storyDescription}>{item.description}</Text>
          )}
          {item.imageUrl && (
            <Image 
              source={typeof item.imageUrl === 'string' ? { uri: item.imageUrl } : item.imageUrl} 
              style={styles.storyImage}
              resizeMode="cover"
            />
          )}
          {item.caption && (
            <Text style={styles.storyCaption}>{item.caption}</Text>
          )}
        </View>

        {/* Footer */}
        <View style={styles.storyFooter}>
          <TouchableOpacity
            style={styles.likeButton}
            onPress={() => handleToggleLike(item.id)}
          >
            <Ionicons 
              name={item.liked ? "heart" : "heart-outline"} 
              size={20} 
              color={item.liked ? "#ff4136" : "#aaa"} 
            />
            <Text style={[styles.likeText, { color: item.liked ? "#ff4136" : "#aaa" }]}>
              {item.liked ? 'Liked' : 'Like'}
            </Text>
          </TouchableOpacity>
          
          <TouchableOpacity 
            style={styles.commentButton}
            onPress={() => toggleComments(item.id)}
          >
            <Ionicons name="chatbubble-outline" size={20} color="#aaa" />
            <Text style={styles.commentText}>{item.commentsCount} Comments</Text>
          </TouchableOpacity>

          {item.category && (
            <View style={[styles.categoryBadge, { backgroundColor: getCategoryColor(item.category) }]}>
              <Text style={styles.categoryText}>{item.category.toUpperCase()}</Text>
            </View>
          )}
        </View>

        {/* Comments Section */}
        {showComments[item.id] && (
          <View style={styles.commentsSection}>
            {/* Comment Input */}
            <View style={styles.commentInputContainer}>
              <TextInput
                style={styles.commentInput}
                placeholder="Add a comment..."
                placeholderTextColor="#666"
                value={newComment[item.id] || ''}
                onChangeText={(text) => setNewComment(prev => ({ ...prev, [item.id]: text }))}
                multiline
                maxLength={500}
              />
              <TouchableOpacity
                style={styles.commentSubmitButton}
                onPress={() => handleAddComment(item.id)}
              >
                <Ionicons name="send" size={16} color="#fff" />
              </TouchableOpacity>
            </View>

            {/* Comments List */}
            <View style={styles.commentsList}>
              {comments[item.id]?.map((comment) => (
                <View key={comment.id} style={styles.commentItem}>
                  <View style={styles.commentHeader}>
                    <Text style={styles.commentAuthor}>{comment.author}</Text>
                    <Text style={styles.commentDate}>
                      {new Date(comment.createdAt).toLocaleDateString()}
                    </Text>
                    {comment.userId === user?.id && (
                      <TouchableOpacity
                        style={styles.deleteCommentButton}
                        onPress={() => handleDeleteComment(item.id, comment.id)}
                      >
                        <Ionicons name="trash-outline" size={12} color="#ff4136" />
                      </TouchableOpacity>
                    )}
                  </View>
                  <Text style={styles.commentContent}>{comment.content}</Text>
                </View>
              ))}
              {(!comments[item.id] || comments[item.id].length === 0) && (
                <Text style={styles.noCommentsText}>No comments yet. Be the first to comment!</Text>
              )}
            </View>
          </View>
        )}
      </LinearGradient>
    </Animated.View>
  );

  const getCategoryColor = (category: 'mind' | 'body' | 'soul') => {
    switch (category) {
      case 'mind': return '#2ecc40';
      case 'body': return '#0074d9';
      case 'soul': return '#ff4136';
      default: return '#aaa';
    }
  };

  const formatDateTime = (date: string, time: string) => {
    const dateObj = new Date(date);
    const today = new Date();
    const yesterday = new Date(today);
    yesterday.setDate(yesterday.getDate() - 1);

    if (dateObj.toDateString() === today.toDateString()) {
      return `Today at ${time}`;
    } else if (dateObj.toDateString() === yesterday.toDateString()) {
      return `Yesterday at ${time}`;
    } else {
      return `${dateObj.toLocaleDateString()} at ${time}`;
    }
  };

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
          <Text style={styles.headerTitle}>Stories</Text>
          <Text style={styles.headerSubtitle}>Share your journey and inspire others</Text>
          <TouchableOpacity
            style={styles.addButton}
            onPress={() => setModalVisible(true)}
          >
            <Ionicons name="add" size={24} color="#fff" />
            <Text style={styles.addButtonText}>Add Story</Text>
          </TouchableOpacity>
        </View>

        {/* Stories List */}
        <FlatList
          data={stories}
          renderItem={renderStory}
          keyExtractor={(item) => item.id}
          showsVerticalScrollIndicator={false}
          contentContainerStyle={styles.storiesList}
          ItemSeparatorComponent={() => <View style={styles.separator} />}
        />
      </Animated.View>

      {/* Add Story Modal */}
      <Modal visible={modalVisible} transparent animationType="slide">
        <View style={styles.modalOverlay}>
          <View style={styles.modalContent}>
            <Text style={styles.modalTitle}>Share Your Story</Text>
            
            <TextInput
              style={styles.modalInput}
              placeholder="Story Title"
              placeholderTextColor="#aaa"
              value={newTitle}
              onChangeText={setNewTitle}
            />
            
            <TextInput
              style={[styles.modalInput, styles.textArea]}
              placeholder="Share your story, experience, or inspiration..."
              placeholderTextColor="#aaa"
              value={newDescription}
              onChangeText={setNewDescription}
              multiline
              numberOfLines={4}
            />

            <View style={styles.categorySelector}>
              <Text style={styles.categoryLabel}>Category:</Text>
              <View style={styles.categoryButtons}>
                {(['mind', 'body', 'soul'] as const).map((category) => (
                  <TouchableOpacity
                    key={category}
                    style={[
                      styles.categoryButton,
                      newCategory === category && { backgroundColor: getCategoryColor(category) }
                    ]}
                    onPress={() => setNewCategory(category)}
                  >
                    <Text style={[
                      styles.categoryButtonText,
                      newCategory === category && { color: '#fff' }
                    ]}>
                      {category.toUpperCase()}
                    </Text>
                  </TouchableOpacity>
                ))}
              </View>
            </View>

            <View style={styles.modalButtons}>
              <TouchableOpacity
                style={[styles.modalButton, styles.cancelButton]}
                onPress={() => {
                  setModalVisible(false);
                  setNewTitle('');
                  setNewDescription('');
                  setNewCategory('mind');
                }}
              >
                <Text style={styles.cancelButtonText}>Cancel</Text>
              </TouchableOpacity>
              <TouchableOpacity
                style={[styles.modalButton, styles.confirmButton]}
                onPress={handleAddStory}
              >
                <Text style={styles.confirmButtonText}>Share Story</Text>
              </TouchableOpacity>
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
  },
  content: {
    flex: 1,
    paddingHorizontal: 20,
  },
  header: {
    paddingVertical: 20,
    alignItems: 'center',
  },
  headerTitle: {
    color: '#fff',
    fontSize: 28,
    fontWeight: 'bold',
    marginBottom: 5,
  },
  headerSubtitle: {
    color: '#aaa',
    fontSize: 16,
    marginBottom: 20,
  },
  addButton: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#2ecc40',
    paddingHorizontal: 20,
    paddingVertical: 12,
    borderRadius: 25,
  },
  addButtonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: 'bold',
    marginLeft: 8,
  },
  storiesList: {
    paddingBottom: 20,
  },
  storyCard: {
    marginBottom: 15,
    borderRadius: 15,
    overflow: 'hidden',
  },
  cardGradient: {
    padding: 15,
  },
  storyHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 15,
  },
  avatar: {
    width: 40,
    height: 40,
    borderRadius: 20,
    marginRight: 12,
  },
  authorInfo: {
    flex: 1,
  },
  author: {
    color: '#fff',
    fontSize: 16,
    fontWeight: 'bold',
  },
  cp: {
    color: '#aaa',
    fontSize: 12,
  },
  cpValue: {
    color: '#FFD700',
    fontWeight: 'bold',
  },
  headerRight: {
    alignItems: 'flex-end',
  },
  date: {
    color: '#aaa',
    fontSize: 12,
  },
  deleteButton: {
    marginTop: 5,
  },
  storyContent: {
    marginBottom: 15,
  },
  storyTitle: {
    color: '#fff',
    fontSize: 18,
    fontWeight: 'bold',
    marginBottom: 8,
  },
  storyDescription: {
    color: '#fff',
    fontSize: 14,
    lineHeight: 20,
    marginBottom: 10,
  },
  storyImage: {
    width: '100%',
    height: 200,
    borderRadius: 10,
    marginBottom: 10,
  },
  storyCaption: {
    color: '#aaa',
    fontSize: 12,
    fontStyle: 'italic',
  },
  storyFooter: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  likeButton: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  likeText: {
    marginLeft: 5,
    fontSize: 14,
  },
  commentButton: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  commentText: {
    color: '#aaa',
    marginLeft: 5,
    fontSize: 14,
  },
  commentsSection: {
    borderTopWidth: 1,
    borderTopColor: '#333',
    paddingTop: 15,
    marginTop: 15,
  },
  commentInputContainer: {
    flexDirection: 'row',
    alignItems: 'flex-end',
    marginBottom: 15,
  },
  commentInput: {
    flex: 1,
    backgroundColor: '#333',
    color: '#fff',
    borderRadius: 20,
    paddingHorizontal: 15,
    paddingVertical: 10,
    marginRight: 10,
    fontSize: 14,
    maxHeight: 80,
  },
  commentSubmitButton: {
    backgroundColor: '#2ecc40',
    width: 36,
    height: 36,
    borderRadius: 18,
    justifyContent: 'center',
    alignItems: 'center',
  },
  commentsList: {
    maxHeight: 200,
  },
  commentItem: {
    backgroundColor: '#333',
    borderRadius: 10,
    padding: 12,
    marginBottom: 8,
  },
  commentHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 8,
  },
  commentAuthor: {
    color: '#fff',
    fontSize: 14,
    fontWeight: 'bold',
    marginRight: 10,
  },
  commentDate: {
    color: '#aaa',
    fontSize: 12,
    flex: 1,
  },
  deleteCommentButton: {
    padding: 4,
  },
  commentContent: {
    color: '#fff',
    fontSize: 14,
    lineHeight: 18,
  },
  noCommentsText: {
    color: '#666',
    fontSize: 14,
    textAlign: 'center',
    fontStyle: 'italic',
    paddingVertical: 20,
  },
  categoryBadge: {
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 12,
  },
  categoryText: {
    color: '#fff',
    fontSize: 10,
    fontWeight: 'bold',
  },
  separator: {
    height: 1,
    backgroundColor: '#333',
    marginVertical: 10,
  },
  modalOverlay: {
    flex: 1,
    backgroundColor: 'rgba(0,0,0,0.7)',
    justifyContent: 'center',
    alignItems: 'center',
  },
  modalContent: {
    backgroundColor: '#222',
    borderRadius: 20,
    padding: 25,
    width: width * 0.9,
    maxHeight: height * 0.8,
  },
  modalTitle: {
    color: '#fff',
    fontSize: 24,
    fontWeight: 'bold',
    textAlign: 'center',
    marginBottom: 20,
  },
  modalInput: {
    backgroundColor: '#333',
    color: '#fff',
    borderRadius: 10,
    padding: 15,
    marginBottom: 15,
    fontSize: 16,
  },
  textArea: {
    height: 100,
    textAlignVertical: 'top',
  },
  categorySelector: {
    marginBottom: 20,
  },
  categoryLabel: {
    color: '#fff',
    fontSize: 16,
    marginBottom: 10,
  },
  categoryButtons: {
    flexDirection: 'row',
    justifyContent: 'space-around',
  },
  categoryButton: {
    paddingHorizontal: 15,
    paddingVertical: 8,
    borderRadius: 15,
    borderWidth: 1,
    borderColor: '#444',
  },
  categoryButtonText: {
    color: '#aaa',
    fontSize: 12,
    fontWeight: 'bold',
  },
  modalButtons: {
    flexDirection: 'row',
    justifyContent: 'space-around',
  },
  modalButton: {
    paddingVertical: 12,
    paddingHorizontal: 25,
    borderRadius: 10,
  },
  cancelButton: {
    backgroundColor: '#444',
  },
  cancelButtonText: {
    color: '#aaa',
    fontSize: 16,
    fontWeight: 'bold',
  },
  confirmButton: {
    backgroundColor: '#2ecc40',
  },
  confirmButtonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: 'bold',
  },
}); 