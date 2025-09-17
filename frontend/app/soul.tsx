import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  Image,
  Dimensions,
  Animated,
  Alert,
} from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { LinearGradient } from 'expo-linear-gradient';
import { Ionicons, MaterialCommunityIcons, FontAwesome5 } from '@expo/vector-icons';
import { useRouter } from 'expo-router';
import { useCommitment } from '@/components/CommitmentContext';
import { useUser } from '@/components/UserContext';
import { useNotification } from '@/components/NotificationContext';

const { width, height } = Dimensions.get('window');

const SOUL_TASKS = [
  {
    id: 1,
    title: 'Practice Meditation',
    description: 'Setup or use your mantra and visualization',
    icon: 'pray',
    cp: 1,
    category: 'soul',
  },
  {
    id: 2,
    title: 'Express Faith or Love',
    description: 'Do something that shows your spiritual side',
    icon: 'heart',
    cp: 1,
    category: 'soul',
  },
  {
    id: 3,
    title: 'Stay Positive',
    description: 'Express optimism even in difficult times',
    icon: 'smile',
    cp: 1,
    category: 'soul',
  },
  {
    id: 4,
    title: 'Connect with Passion',
    description: 'Find someone who shares your commitment',
    icon: 'users',
    cp: 1,
    category: 'soul',
  },
  {
    id: 5,
    title: 'Show Humility',
    description: 'Practice openness, vulnerability, and trust',
    icon: 'user-friends',
    cp: 1,
    category: 'soul',
  },
  {
    id: 6,
    title: 'Express Gratitude',
    description: 'Show appreciation and recognition',
    icon: 'hands-helping',
    cp: 1,
    category: 'soul',
  },
  {
    id: 7,
    title: 'Deepen Relationships',
    description: 'Build new or strengthen existing connections',
    icon: 'user-plus',
    cp: 1,
    category: 'soul',
  },
  {
    id: 8,
    title: 'Practice Forgiveness',
    description: 'Let go of grudges and practice letting go',
    icon: 'peace',
    cp: 1,
    category: 'soul',
  },
  {
    id: 9,
    title: 'Spiritual Activity',
    description: 'Engage in soulful or spiritual practices',
    icon: 'star',
    cp: 1,
    category: 'soul',
  },
  {
    id: 10,
    title: 'Reflect on Purpose',
    description: 'Think about your values and life purpose',
    icon: 'lightbulb',
    cp: 1,
    category: 'soul',
  },
];

export default function SoulScreen() {
  const insets = useSafeAreaInsets();
  const router = useRouter();
  const { getCP, getLifetimeCP, completeTask, uncompleteTask, completed } = useCommitment();
  const { user } = useUser();
  const { addNotification } = useNotification();
  
  const [fadeAnim] = useState(new Animated.Value(0));
  const [slideAnim] = useState(new Animated.Value(50));
  const [completedTasks, setCompletedTasks] = useState<number[]>([]);
  const [showEnhancementTips, setShowEnhancementTips] = useState(true);

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

  // Load completed tasks from context
  useEffect(() => {
    setCompletedTasks(completed.soul);
  }, [completed.soul]);

  const handleTaskToggle = (taskId: number) => {
    if (completedTasks.includes(taskId)) {
      uncompleteTask('soul', taskId);
      setCompletedTasks(prev => prev.filter(id => id !== taskId));
      addNotification('Task uncompleted', 'info');
    } else {
      completeTask('soul', taskId);
      setCompletedTasks(prev => [...prev, taskId]);
      addNotification('Soul task completed! +1 CP', 'success');
    }
  };

  const dailyCP = getCP('soul');
  const lifetimeCP = getLifetimeCP('soul');
  const progress = (dailyCP / 10) * 100; // Assuming 10 is max daily CP

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
          <TouchableOpacity
            style={styles.backButton}
            onPress={() => router.back()}
          >
            <Ionicons name="arrow-back" size={24} color="#fff" />
          </TouchableOpacity>
          
          <View style={styles.headerContent}>
            <View style={styles.categoryIcon}>
              <FontAwesome5 name="heart" size={24} color="#ff4136" />
            </View>
            <Text style={styles.headerTitle}>Soul</Text>
            <Text style={styles.headerSubtitle}>Nurture your spiritual and emotional well-being</Text>
          </View>
        </View>

        <ScrollView showsVerticalScrollIndicator={false} style={styles.scrollView}>
          {/* Progress Section */}
          <View style={styles.progressSection}>
            <LinearGradient
              colors={['#ff4136', '#c0392b']}
              style={styles.progressCard}
            >
              <View style={styles.progressHeader}>
                <Text style={styles.progressTitle}>Today's Progress</Text>
                <Text style={styles.progressSubtitle}>Keep your soul nourished</Text>
              </View>
              
              <View style={styles.progressStats}>
                <View style={styles.statItem}>
                  <Text style={styles.statValue}>{dailyCP}</Text>
                  <Text style={styles.statLabel}>Daily CP</Text>
                </View>
                <View style={styles.statDivider} />
                <View style={styles.statItem}>
                  <Text style={styles.statValue}>{lifetimeCP}</Text>
                  <Text style={styles.statLabel}>Lifetime CP</Text>
                </View>
              </View>
              
              <View style={styles.progressBar}>
                <View style={styles.progressBarBackground}>
                  <Animated.View
                    style={[
                      styles.progressBarFill,
                      {
                        width: `${progress}%`,
                        backgroundColor: '#ff4136',
                      },
                    ]}
                  />
                </View>
                <Text style={styles.progressText}>{Math.round(progress)}% Complete</Text>
              </View>
            </LinearGradient>
          </View>

          {/* Tasks Section */}
          <View style={styles.tasksSection}>
            <Text style={styles.sectionTitle}>Daily Soul Tasks</Text>
            <Text style={styles.sectionSubtitle}>Complete tasks to earn commitment points</Text>
            
            {SOUL_TASKS.map((task) => {
              const isCompleted = completedTasks.includes(task.id);
              return (
                <TouchableOpacity
                  key={task.id}
                  style={[styles.taskCard, isCompleted && styles.taskCardCompleted]}
                  onPress={() => handleTaskToggle(task.id)}
                >
                  <LinearGradient
                    colors={isCompleted ? ['#ff4136', '#c0392b'] : ['#222', '#1a1a1a']}
                    style={styles.taskGradient}
                  >
                    <View style={styles.taskIcon}>
                      <FontAwesome5 
                        name={task.icon as any} 
                        size={20} 
                        color={isCompleted ? '#fff' : '#ff4136'} 
                      />
                    </View>
                    
                    <View style={styles.taskContent}>
                      <Text style={[styles.taskTitle, isCompleted && styles.taskTitleCompleted]}>
                        {task.title}
                      </Text>
                      <Text style={[styles.taskDescription, isCompleted && styles.taskDescriptionCompleted]}>
                        {task.description}
                      </Text>
                    </View>
                    
                    <View style={styles.taskActions}>
                      <View style={[styles.cpBadge, isCompleted && styles.cpBadgeCompleted]}>
                        <Text style={[styles.cpText, isCompleted && styles.cpTextCompleted]}>
                          +{task.cp} CP
                        </Text>
                      </View>
                      
                      <View style={[styles.completionIndicator, isCompleted && styles.completionIndicatorCompleted]}>
                        <Ionicons 
                          name={isCompleted ? "checkmark-circle" : "ellipse-outline"} 
                          size={24} 
                          color={isCompleted ? '#fff' : '#ff4136'} 
                        />
                      </View>
                    </View>
                  </LinearGradient>
                </TouchableOpacity>
              );
            })}
          </View>
          
          {/* Enhancement Tips Section */}
          <View style={styles.enhancementSection}>
            <TouchableOpacity 
              style={styles.enhancementHeader}
              onPress={() => setShowEnhancementTips(!showEnhancementTips)}
            >
              <Text style={styles.enhancementTitle}>❤️ Soul Enhancement Tips</Text>
              <Ionicons 
                name={showEnhancementTips ? "chevron-up" : "chevron-down"} 
                size={20} 
                color="#ff4136" 
              />
            </TouchableOpacity>
            
            {showEnhancementTips && (
              <View style={styles.enhancementTips}>
                <Text style={styles.enhancementTip}>• Practice daily gratitude by writing down 3 things you're thankful for</Text>
                <Text style={styles.enhancementTip}>• Take time for self-reflection and journaling</Text>
                <Text style={styles.enhancementTip}>• Connect with nature regularly to ground yourself</Text>
                <Text style={styles.enhancementTip}>• Practice random acts of kindness throughout your day</Text>
                <Text style={styles.enhancementTip}>• Set boundaries to protect your emotional well-being</Text>
              </View>
            )}
          </View>
        </ScrollView>
      </Animated.View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#111',
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
    paddingHorizontal: 16,
  },
  scrollView: {
    flex: 1,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 20,
  },
  backButton: {
    marginRight: 16,
  },
  headerContent: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  categoryIcon: {
    marginRight: 12,
  },
  headerTitle: {
    color: '#fff',
    fontSize: 28,
    fontWeight: 'bold',
  },
  headerSubtitle: {
    color: '#ccc',
    fontSize: 14,
    marginTop: 4,
  },
  progressSection: {
    marginBottom: 20,
  },
  progressCard: {
    borderRadius: 20,
    padding: 24,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.3,
    shadowRadius: 8,
    elevation: 5,
  },
  progressHeader: {
    marginBottom: 16,
  },
  progressTitle: {
    color: '#fff',
    fontSize: 22,
    fontWeight: 'bold',
    marginBottom: 4,
  },
  progressSubtitle: {
    color: '#ccc',
    fontSize: 14,
  },
  progressStats: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    marginBottom: 16,
  },
  statItem: {
    alignItems: 'center',
  },
  statValue: {
    color: '#fff',
    fontSize: 24,
    fontWeight: 'bold',
  },
  statLabel: {
    color: '#ccc',
    fontSize: 12,
    marginTop: 4,
  },
  statDivider: {
    width: 1,
    height: '100%',
    backgroundColor: '#333',
  },
  progressBar: {
    alignItems: 'center',
  },
  progressBarBackground: {
    width: '100%',
    height: 10,
    backgroundColor: '#333',
    borderRadius: 5,
    overflow: 'hidden',
  },
  progressBarFill: {
    height: '100%',
    borderRadius: 5,
  },
  progressText: {
    color: '#fff',
    fontSize: 16,
    marginTop: 8,
  },
  tasksSection: {
    marginBottom: 20,
  },
  sectionTitle: {
    color: '#fff',
    fontSize: 22,
    fontWeight: 'bold',
    marginBottom: 8,
  },
  sectionSubtitle: {
    color: '#ccc',
    fontSize: 16,
    marginBottom: 16,
  },
  taskCard: {
    borderRadius: 15,
    padding: 18,
    marginBottom: 12,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.3,
    shadowRadius: 8,
    elevation: 5,
  },
  taskCardCompleted: {
    opacity: 0.7,
  },
  taskGradient: {
    flexDirection: 'row',
    alignItems: 'center',
    borderRadius: 15,
    padding: 12,
  },
  taskIcon: {
    backgroundColor: '#222',
    borderRadius: 10,
    padding: 10,
    marginRight: 12,
  },
  taskContent: {
    flex: 1,
  },
  taskTitle: {
    color: '#fff',
    fontSize: 18,
    fontWeight: 'bold',
  },
  taskTitleCompleted: {
    textDecorationLine: 'line-through',
    color: '#ccc',
  },
  taskDescription: {
    color: '#ccc',
    fontSize: 14,
    marginTop: 4,
  },
  taskDescriptionCompleted: {
    textDecorationLine: 'line-through',
    color: '#999',
  },
  taskActions: {
    flexDirection: 'row',
    alignItems: 'center',
    marginTop: 12,
  },
  cpBadge: {
    backgroundColor: '#ff4136',
    borderRadius: 10,
    paddingHorizontal: 15,
    paddingVertical: 6,
  },
  cpBadgeCompleted: {
    backgroundColor: '#333',
  },
  cpText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: 'bold',
  },
  cpTextCompleted: {
    color: '#999',
  },
  completionIndicator: {
    marginLeft: 15,
  },
  completionIndicatorCompleted: {
    opacity: 0.7,
  },
  enhancementSection: {
    marginTop: 20,
    marginBottom: 32,
    padding: 15,
    backgroundColor: 'rgba(255, 65, 54, 0.1)',
    borderRadius: 15,
    borderWidth: 1,
    borderColor: '#ff4136',
  },
  enhancementHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 10,
  },
  enhancementTitle: {
    color: '#ff4136',
    fontSize: 16,
    fontWeight: 'bold',
  },
  enhancementTips: {
    marginLeft: 10,
  },
  enhancementTip: {
    color: '#fff',
    fontSize: 12,
    marginBottom: 5,
    lineHeight: 16,
  },
}); 