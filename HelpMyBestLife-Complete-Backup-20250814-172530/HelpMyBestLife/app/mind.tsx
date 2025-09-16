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

const MIND_TASKS = [
  {
    id: 1,
    title: 'Read for 30 minutes',
    description: 'Expand your knowledge through reading',
    icon: 'book-open',
    cp: 1,
    category: 'mind',
  },
  {
    id: 2,
    title: 'Learn a new skill',
    description: 'Take an online course or tutorial',
    icon: 'graduation-cap',
    cp: 1,
    category: 'mind',
  },
  {
    id: 3,
    title: 'Solve a puzzle',
    description: 'Crossword, Sudoku, or brain teaser',
    icon: 'puzzle-piece',
    cp: 1,
    category: 'mind',
  },
  {
    id: 4,
    title: 'Write in journal',
    description: 'Reflect on your thoughts and experiences',
    icon: 'pen',
    cp: 1,
    category: 'mind',
  },
  {
    id: 5,
    title: 'Practice meditation',
    description: 'Mindfulness and mental clarity',
    icon: 'brain',
    cp: 1,
    category: 'mind',
  },
  {
    id: 6,
    title: 'Study a language',
    description: 'Learn new words or practice conversation',
    icon: 'language',
    cp: 1,
    category: 'mind',
  },
  {
    id: 7,
    title: 'Research a topic',
    description: 'Deep dive into something that interests you',
    icon: 'search',
    cp: 1,
    category: 'mind',
  },
  {
    id: 8,
    title: 'Practice critical thinking',
    description: 'Analyze a problem from multiple angles',
    icon: 'lightbulb',
    cp: 1,
    category: 'mind',
  },
  {
    id: 9,
    title: 'Memory training',
    description: 'Work on improving your memory skills',
    icon: 'brain',
    cp: 1,
    category: 'mind',
  },
  {
    id: 10,
    title: 'Creative problem solving',
    description: 'Find innovative solutions to challenges',
    icon: 'magic',
    cp: 1,
    category: 'mind',
  },
];

export default function MindScreen() {
  const insets = useSafeAreaInsets();
  const router = useRouter();
  const { getCP, getLifetimeCP, completeTask, uncompleteTask, completed } = useCommitment();
  const { user } = useUser();
  const { addNotification } = useNotification();
  
  const [fadeAnim] = useState(new Animated.Value(0));
  const [slideAnim] = useState(new Animated.Value(50));
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

  const handleTaskToggle = (taskId: number) => {
    if (completed.mind.includes(taskId)) {
      uncompleteTask('mind', taskId);
      addNotification('Task uncompleted', 'info');
    } else {
      completeTask('mind', taskId);
      addNotification('Mind task completed! +1 CP', 'success');
    }
  };

  const dailyCP = getCP('mind');
  const lifetimeCP = getLifetimeCP('mind');
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
              <FontAwesome5 name="brain" size={24} color="#2ecc40" />
            </View>
            <Text style={styles.headerTitle}>Mind</Text>
            <Text style={styles.headerSubtitle}>Expand your knowledge and mental capacity</Text>
          </View>
        </View>

        <ScrollView showsVerticalScrollIndicator={false} style={styles.scrollView}>
          {/* Progress Section */}
          <View style={styles.progressSection}>
            <LinearGradient
              colors={['#2ecc40', '#27ae60']}
              style={styles.progressCard}
            >
              <View style={styles.progressHeader}>
                <Text style={styles.progressTitle}>Today's Progress</Text>
                <Text style={styles.progressSubtitle}>Keep your mind sharp</Text>
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
                        backgroundColor: '#2ecc40',
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
            <Text style={styles.sectionTitle}>Daily Mind Tasks</Text>
            <Text style={styles.sectionSubtitle}>Complete tasks to earn commitment points</Text>
            
            {MIND_TASKS.map((task) => {
              const isCompleted = completed.mind.includes(task.id);
              return (
                <TouchableOpacity
                  key={task.id}
                  style={[styles.taskCard, isCompleted && styles.taskCardCompleted]}
                  onPress={() => handleTaskToggle(task.id)}
                >
                  <LinearGradient
                    colors={isCompleted ? ['#2ecc40', '#27ae60'] : ['#222', '#1a1a1a']}
                    style={styles.taskGradient}
                  >
                    <View style={styles.taskIcon}>
                      <FontAwesome5 
                        name={task.icon as any} 
                        size={20} 
                        color={isCompleted ? '#fff' : '#2ecc40'} 
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
                          color={isCompleted ? '#fff' : '#2ecc40'} 
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
              <Text style={styles.enhancementTitle}>🧠 Mind Enhancement Tips</Text>
              <Ionicons 
                name={showEnhancementTips ? "chevron-up" : "chevron-down"} 
                size={20} 
                color="#2ecc40" 
              />
            </TouchableOpacity>
            
            {showEnhancementTips && (
              <View style={styles.enhancementTips}>
                <Text style={styles.enhancementTip}>• Take regular breaks to maintain focus and prevent mental fatigue</Text>
                <Text style={styles.enhancementTip}>• Practice active recall by testing yourself on what you've learned</Text>
                <Text style={styles.enhancementTip}>• Use the Pomodoro Technique: 25 minutes of focused work, then 5-minute breaks</Text>
                <Text style={styles.enhancementTip}>• Connect new information to things you already know for better retention</Text>
                <Text style={styles.enhancementTip}>• Get adequate sleep - it's crucial for memory consolidation and learning</Text>
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
    paddingHorizontal: 16,
  },
  scrollView: {
    flex: 1,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 24,
  },
  backButton: {
    padding: 8,
    marginRight: 16,
  },
  headerContent: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  categoryIcon: {
    backgroundColor: '#2ecc40',
    borderRadius: 12,
    padding: 8,
    marginRight: 12,
  },
  headerTitle: {
    color: '#fff',
    fontSize: 28,
    fontWeight: 'bold',
  },
  headerSubtitle: {
    color: '#ccc',
    fontSize: 16,
    marginTop: 4,
  },
  progressSection: {
    marginBottom: 24,
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
  },
  progressSubtitle: {
    color: '#ccc',
    fontSize: 16,
    marginTop: 4,
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
    fontSize: 14,
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
    marginBottom: 24,
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
    backgroundColor: '#2ecc40',
    borderRadius: 10,
    paddingHorizontal: 12,
    paddingVertical: 6,
    marginRight: 12,
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
    padding: 8,
  },
  completionIndicatorCompleted: {
    backgroundColor: '#2ecc40',
    borderRadius: 15,
  },
  enhancementSection: {
    marginBottom: 32,
    padding: 15,
    backgroundColor: 'rgba(46, 204, 64, 0.1)',
    borderRadius: 15,
    borderWidth: 1,
    borderColor: '#2ecc40',
  },
  enhancementHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 10,
  },
  enhancementTitle: {
    color: '#2ecc40',
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