import React, { useState } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, ScrollView } from 'react-native';
import { useLocalSearchParams, useRouter } from 'expo-router';
import { useGroup } from '@/components/GroupContext';
import { useUser } from '@/components/UserContext';

export default function GroupCategoryTasks() {
  const { id, category } = useLocalSearchParams();
  const { groups, completeGroupTask } = useGroup();
  const { user } = useUser();
  const router = useRouter();
  const group = groups.find((g) => g.id === id);

  const tasks = group?.tasks.filter((t) => t.category === category) || [];
  const [completed, setCompleted] = useState<number[]>([]);

  const handleToggle = (taskId: number) => {
    const task = tasks.find(t => t.id === taskId);
    if (!task) return;
    if (task.completedBy.includes(user.id)) {
      // Optionally implement uncomplete logic
    } else {
      completeGroupTask(group!.id, user.id, taskId, category as 'mind' | 'body' | 'soul');
    }
  };

  if (!group) return <Text>Group not found</Text>;

  return (
    <View style={{ flex: 1, backgroundColor: '#111' }}>
      <View style={styles.header}>
        <TouchableOpacity onPress={() => router.back()} style={styles.backBtn}>
          <Text style={{ color: '#fff', fontSize: 22 }}>{'<'}</Text>
        </TouchableOpacity>
        <Text style={styles.headerTitle}>{group.name} - {String(category).toUpperCase()}</Text>
      </View>
      <ScrollView contentContainerStyle={{ padding: 16 }}>
        {tasks.length === 0 && <Text style={{ color: '#fff' }}>No tasks for this category.</Text>}
        {tasks.map((task) => (
          <TouchableOpacity
            key={task.id}
            style={styles.taskCard}
            onPress={() => handleToggle(task.id)}
            activeOpacity={0.7}
          >
            <View style={styles.checkbox}>
              {task.completedBy.includes(user.id) ? (
                <Text style={{ color: '#2ecc40', fontSize: 22 }}>✔</Text>
              ) : (
                <Text style={{ color: '#fff', fontSize: 22 }}>□</Text>
              )}
            </View>
            <Text style={styles.taskText}>{task.text}</Text>
            <View style={styles.cpBadge}>
              <Text style={styles.cpText}>{task.cp} CP</Text>
            </View>
            <View style={{ flexDirection: 'row', marginLeft: 8 }}>
              {task.completedBy.map(mid => {
                const member = group.members.find(m => m.id === mid);
                return member ? (
                  <View key={mid} style={{ width: 20, height: 20, borderRadius: 10, backgroundColor: '#444', alignItems: 'center', justifyContent: 'center', marginLeft: -6, borderWidth: 2, borderColor: '#111' }}>
                    <Text style={{ color: '#fff', fontSize: 12 }}>{member.name[0]}</Text>
                  </View>
                ) : null;
              })}
            </View>
          </TouchableOpacity>
        ))}
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#222',
    paddingTop: 48,
    paddingBottom: 16,
    paddingHorizontal: 16,
  },
  backBtn: {
    marginRight: 16,
  },
  headerTitle: {
    color: '#fff',
    fontSize: 20,
    fontWeight: 'bold',
  },
  taskCard: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#222',
    borderRadius: 12,
    padding: 16,
    marginBottom: 12,
  },
  checkbox: {
    marginRight: 16,
  },
  taskText: {
    color: '#fff',
    fontSize: 16,
    flex: 1,
  },
  cpBadge: {
    backgroundColor: '#2ecc40',
    borderRadius: 8,
    paddingHorizontal: 12,
    paddingVertical: 4,
    marginLeft: 12,
  },
  cpText: {
    color: '#fff',
    fontWeight: 'bold',
    fontSize: 14,
  },
}); 