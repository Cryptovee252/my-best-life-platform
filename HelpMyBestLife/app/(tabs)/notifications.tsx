import React from 'react';
import { View, Text, StyleSheet, FlatList, TouchableOpacity } from 'react-native';
import { useNotification } from '@/components/NotificationContext';
import { useRouter } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';

export default function NotificationsScreen() {
  const { notifications, clearAll } = useNotification();
  const router = useRouter();

  return (
    <View style={styles.container}>
      <View style={styles.headerRow}>
        <Text style={styles.header}>Notifications</Text>
        <TouchableOpacity onPress={clearAll}>
          <Text style={styles.clear}>Clear</Text>
        </TouchableOpacity>
      </View>
      <FlatList
        data={notifications}
        keyExtractor={item => item.id}
        contentContainerStyle={{ paddingBottom: 24 }}
        renderItem={({ item }) => (
          <TouchableOpacity
            style={styles.notification}
            onPress={() => item.link && router.push(item.link)}
            activeOpacity={item.link ? 0.7 : 1}
          >
            <Ionicons name="notifications" size={32} color="#fff" style={{ marginRight: 16 }} />
            <View style={{ flex: 1 }}>
              <Text style={styles.title}>{item.message}</Text>
              <Text style={styles.date}>{new Date(item.timestamp).toLocaleString()}</Text>
            </View>
            <Ionicons name="chevron-forward" size={20} color="#fff" />
          </TouchableOpacity>
        )}
        ListEmptyComponent={<Text style={{ color: '#aaa', textAlign: 'center', marginTop: 32 }}>No notifications yet.</Text>}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#111',
    paddingTop: 32,
  },
  headerRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 20,
    marginBottom: 12,
  },
  header: {
    color: '#fff',
    fontSize: 28,
    fontWeight: 'bold',
  },
  clear: {
    color: '#fff',
    fontSize: 16,
    opacity: 0.7,
  },
  notification: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#181818',
    borderRadius: 12,
    padding: 16,
    marginHorizontal: 16,
    marginBottom: 12,
  },
  title: {
    color: '#fff',
    fontSize: 16,
    fontWeight: 'bold',
    marginBottom: 2,
  },
  date: {
    color: '#aaa',
    fontSize: 13,
  },
}); 