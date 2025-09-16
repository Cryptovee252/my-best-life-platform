import React, { useState } from 'react';
import { View, Text, StyleSheet, Image, TouchableOpacity, Modal, TextInput, Platform, ScrollView } from 'react-native';
import * as ImagePicker from 'expo-image-picker';
import { Ionicons } from '@expo/vector-icons';
import { useUser } from '@/components/UserContext';

export default function ProfileScreen() {
  const { user, updateUser } = useUser();
  const [editModal, setEditModal] = useState(false);
  const [editData, setEditData] = useState(user);
  const [uploading, setUploading] = useState(false);

  // Pick new profile picture
  const pickImage = async () => {
    let result = await ImagePicker.launchImageLibraryAsync({
      mediaTypes: ImagePicker.MediaTypeOptions.Images,
      allowsEditing: true,
      aspect: [1, 1],
      quality: 0.7,
    });
    if (!result.canceled && result.assets && result.assets[0].uri) {
      setEditData({ ...editData, profilePic: result.assets[0].uri });
    }
  };

  // Save profile changes
  const handleSave = () => {
    updateUser(editData);
    setEditModal(false);
  };

  // Render commitment trend (simple bar chart)
  const renderTrend = () => (
    <View style={styles.trendRow}>
      {user.trends.map((v, i) => (
        <View key={i} style={[styles.trendBar, { height: 16 + v * 12 }]} />
      ))}
    </View>
  );

  return (
    <ScrollView style={{ flex: 1, backgroundColor: '#111' }} contentContainerStyle={{ paddingBottom: 40 }}>
      <View style={styles.header}>
        <TouchableOpacity onPress={() => setEditModal(true)}>
          <Image source={user.profilePic ? (typeof user.profilePic === 'string' ? { uri: user.profilePic } : user.profilePic) : require('@/assets/images/icon.png')} style={styles.avatar} />
          <View style={styles.editIcon}><Ionicons name="camera" size={18} color="#fff" /></View>
        </TouchableOpacity>
        <Text style={styles.name}>{user.name}</Text>
        <Text style={styles.username}>@{user.username}</Text>
      </View>
      <View style={styles.detailsBox}>
        <Text style={styles.detailLabel}>Email</Text>
        <Text style={styles.detailValue}>{user.email}</Text>
        <Text style={styles.detailLabel}>Phone</Text>
        <Text style={styles.detailValue}>{user.phone}</Text>
        <Text style={styles.detailLabel}>Days Active</Text>
        <Text style={styles.detailValue}>{user.daysActive}</Text>
      </View>
      <View style={styles.statsBox}>
        <Text style={styles.statsTitle}>Commitment Points</Text>
        <View style={styles.statsRow}>
          <View style={styles.statItem}><Text style={styles.statNum}>{user.dailyCP}</Text><Text style={styles.statLabel}>Daily</Text></View>
          <View style={styles.statItem}><Text style={styles.statNum}>{user.lifetimeCP}</Text><Text style={styles.statLabel}>Lifetime</Text></View>
        </View>
        <View style={styles.statsRow}>
          <View style={styles.statItem}><Text style={[styles.statNum, { color: '#2ecc40' }]}>{user.cpByCategory.mind}</Text><Text style={styles.statLabel}>Mind</Text></View>
          <View style={styles.statItem}><Text style={[styles.statNum, { color: '#0074d9' }]}>{user.cpByCategory.body}</Text><Text style={styles.statLabel}>Body</Text></View>
          <View style={styles.statItem}><Text style={[styles.statNum, { color: '#ff4136' }]}>{user.cpByCategory.soul}</Text><Text style={styles.statLabel}>Soul</Text></View>
        </View>
      </View>
      <View style={styles.trendBox}>
        <Text style={styles.statsTitle}>Commitment Trend (7 days)</Text>
        {renderTrend()}
      </View>
      {/* Edit Profile Modal */}
      <Modal visible={editModal} animationType="slide" transparent onRequestClose={() => setEditModal(false)}>
        <View style={styles.modalOverlay}>
          <View style={styles.modalContent}>
            <Text style={styles.modalTitle}>Edit Profile</Text>
            <TouchableOpacity onPress={pickImage} style={{ alignSelf: 'center' }}>
              <Image source={editData.profilePic ? (typeof editData.profilePic === 'string' ? { uri: editData.profilePic } : editData.profilePic) : require('@/assets/images/icon.png')} style={styles.avatarLarge} />
              <View style={styles.editIconLarge}><Ionicons name="camera" size={22} color="#fff" /></View>
            </TouchableOpacity>
            <TextInput
              style={styles.input}
              placeholder="Name"
              placeholderTextColor="#aaa"
              value={editData.name}
              onChangeText={v => setEditData({ ...editData, name: v })}
            />
            <TextInput
              style={styles.input}
              placeholder="Username"
              placeholderTextColor="#aaa"
              value={editData.username}
              onChangeText={v => setEditData({ ...editData, username: v })}
            />
            <TextInput
              style={styles.input}
              placeholder="Email"
              placeholderTextColor="#aaa"
              value={editData.email}
              onChangeText={v => setEditData({ ...editData, email: v })}
              keyboardType="email-address"
            />
            <TextInput
              style={styles.input}
              placeholder="Phone"
              placeholderTextColor="#aaa"
              value={editData.phone}
              onChangeText={v => setEditData({ ...editData, phone: v })}
              keyboardType="phone-pad"
            />
            <View style={{ flexDirection: 'row', justifyContent: 'flex-end', marginTop: 16 }}>
              <TouchableOpacity onPress={() => setEditModal(false)} style={styles.modalBtn}>
                <Text style={{ color: '#fff' }}>Cancel</Text>
              </TouchableOpacity>
              <TouchableOpacity onPress={handleSave} style={[styles.modalBtn, { backgroundColor: '#2ecc40', marginLeft: 12 }]}> 
                <Text style={{ color: '#fff', fontWeight: 'bold' }}>Save</Text>
              </TouchableOpacity>
            </View>
          </View>
        </View>
      </Modal>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  header: {
    alignItems: 'center',
    paddingTop: 36,
    paddingBottom: 16,
    backgroundColor: '#181818',
  },
  avatar: {
    width: 90,
    height: 90,
    borderRadius: 45,
    borderWidth: 3,
    borderColor: '#2ecc40',
    marginBottom: 10,
  },
  editIcon: {
    position: 'absolute',
    right: 6,
    bottom: 6,
    backgroundColor: '#2ecc40',
    borderRadius: 12,
    padding: 3,
    borderWidth: 2,
    borderColor: '#fff',
  },
  name: {
    color: '#fff',
    fontSize: 22,
    fontWeight: 'bold',
    marginTop: 2,
  },
  username: {
    color: '#aaa',
    fontSize: 16,
    marginBottom: 8,
  },
  detailsBox: {
    backgroundColor: '#222',
    borderRadius: 12,
    margin: 18,
    padding: 16,
  },
  detailLabel: {
    color: '#aaa',
    fontSize: 13,
    marginTop: 6,
  },
  detailValue: {
    color: '#fff',
    fontSize: 15,
    marginBottom: 2,
  },
  statsBox: {
    backgroundColor: '#181818',
    borderRadius: 12,
    marginHorizontal: 18,
    marginBottom: 18,
    padding: 16,
  },
  statsTitle: {
    color: '#fff',
    fontSize: 17,
    fontWeight: 'bold',
    marginBottom: 8,
  },
  statsRow: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    marginBottom: 8,
  },
  statItem: {
    alignItems: 'center',
    flex: 1,
  },
  statNum: {
    color: '#FFD700',
    fontSize: 20,
    fontWeight: 'bold',
  },
  statLabel: {
    color: '#aaa',
    fontSize: 13,
    marginTop: 2,
  },
  trendBox: {
    backgroundColor: '#222',
    borderRadius: 12,
    marginHorizontal: 18,
    marginBottom: 18,
    padding: 16,
  },
  trendRow: {
    flexDirection: 'row',
    alignItems: 'flex-end',
    justifyContent: 'space-between',
    marginTop: 10,
    height: 60,
  },
  trendBar: {
    width: 18,
    backgroundColor: '#2ecc40',
    borderRadius: 6,
    marginHorizontal: 3,
  },
  avatarLarge: {
    width: 120,
    height: 120,
    borderRadius: 60,
    borderWidth: 3,
    borderColor: '#2ecc40',
    marginBottom: 10,
    alignSelf: 'center',
  },
  editIconLarge: {
    position: 'absolute',
    right: 12,
    bottom: 12,
    backgroundColor: '#2ecc40',
    borderRadius: 16,
    padding: 4,
    borderWidth: 2,
    borderColor: '#fff',
  },
  modalOverlay: {
    flex: 1,
    backgroundColor: 'rgba(0,0,0,0.7)',
    justifyContent: 'center',
    alignItems: 'center',
  },
  modalContent: {
    backgroundColor: '#181818',
    borderRadius: 16,
    padding: 24,
    width: '90%',
    maxWidth: 400,
  },
  modalTitle: {
    color: '#fff',
    fontSize: 20,
    fontWeight: 'bold',
    marginBottom: 18,
    alignSelf: 'center',
  },
  input: {
    backgroundColor: '#222',
    color: '#fff',
    borderRadius: 8,
    padding: 12,
    fontSize: 16,
    marginBottom: 12,
  },
  modalBtn: {
    backgroundColor: '#333',
    borderRadius: 8,
    paddingVertical: 10,
    paddingHorizontal: 22,
  },
}); 