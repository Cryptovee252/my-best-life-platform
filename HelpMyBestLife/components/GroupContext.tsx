import React, { createContext, useContext, useState, ReactNode, useEffect } from 'react';
import AsyncStorage from '@react-native-async-storage/async-storage';
import groupService from '../services/groupService';

export type GroupMember = {
  id: string;
  name: string;
  avatarUrl?: string;
  groupCP: {
    mind: number;
    body: number;
    soul: number;
  };
};

export type GroupMessage = {
  id: string;
  userId: string;
  userName: string;
  text: string;
  timestamp: number;
};

export type GroupTask = {
  id: number;
  text: string;
  cp: number;
  category: 'mind' | 'body' | 'soul';
  completedBy: string[];
};

export type Group = {
  id: string;
  name: string;
  iconUrl?: string;
  adminId: string;
  members: GroupMember[];
  tasks: GroupTask[];
  messages: GroupMessage[];
};

interface GroupState {
  groups: Group[];
  currentGroupId: string | null;
  isLoading: boolean;
  createGroup: (groupId: string, name: string, adminId: string, member: GroupMember) => void;
  joinGroup: (groupId: string, member: GroupMember) => void;
  leaveGroup: (groupId: string, memberId: string) => void;
  completeGroupTask: (groupId: string, memberId: string, taskId: number, category: 'mind' | 'body' | 'soul') => void;
  getGroupCP: (groupId: string, memberId: string, category: 'mind' | 'body' | 'soul') => number;
  setCurrentGroup: (groupId: string | null) => void;
  getCurrentGroup: () => Group | null;
  sendMessage: (groupId: string, userId: string, userName: string, text: string) => void;
  clearAllGroups: () => void;
  deleteGroup: (groupId: string) => void;
  refreshGroupsFromStorage: () => Promise<void>;
  syncBackendGroups: () => Promise<void>;
}

const GroupContext = createContext<GroupState | undefined>(undefined);

export function useGroup() {
  const ctx = useContext(GroupContext);
  if (!ctx) throw new Error('useGroup must be used within GroupProvider');
  return ctx;
}

const DEMO_GROUP: Group = {
  id: '1',
  name: 'TEST GROUP',
  iconUrl: undefined,
  adminId: '1',
  members: [
    { id: '1', name: 'HelpMyBestLife', groupCP: { mind: 0, body: 0, soul: 0 } },
    { id: '2', name: 'Shawn Vee.', avatarUrl: undefined, groupCP: { mind: 0, body: 0, soul: 0 } },
  ],
  tasks: [
    { id: 1, text: 'Group Mind Task', cp: 1, category: 'mind', completedBy: [] },
    { id: 2, text: 'Group Body Task', cp: 1, category: 'body', completedBy: [] },
    { id: 3, text: 'Group Soul Task', cp: 1, category: 'soul', completedBy: [] },
  ],
  messages: [],
};

export function GroupProvider({ children }: { children: ReactNode }) {
  const [groups, setGroups] = useState<Group[]>([DEMO_GROUP]);
  const [currentGroupId, setCurrentGroupId] = useState<string | null>('1');
  const [isLoading, setIsLoading] = useState(true);

  // Load groups from AsyncStorage on mount
  useEffect(() => {
    loadGroupsFromStorage();
    // Also sync with backend groups
    syncBackendGroups();
  }, []);

  const loadGroupsFromStorage = async () => {
    try {
      const storedGroups = await AsyncStorage.getItem('groups');
      if (storedGroups) {
        const parsedGroups = JSON.parse(storedGroups);
        setGroups(parsedGroups);
      } else {
        // If no stored groups, save the default DEMO_GROUP to storage
        saveGroupsToStorage([DEMO_GROUP]);
      }
    } catch (error) {
      console.error('Error loading groups from storage:', error);
      // Fallback to default groups if storage fails
      setGroups([DEMO_GROUP]);
    } finally {
      setIsLoading(false);
    }
  };

  const saveGroupsToStorage = async (groupsToSave: Group[]) => {
    try {
      await AsyncStorage.setItem('groups', JSON.stringify(groupsToSave));
    } catch (error) {
      console.error('Error saving groups to storage:', error);
    }
  };

  const createGroup = (groupId: string, name: string, adminId: string, member: GroupMember) => {
    const newGroup: Group = {
      id: groupId,
      name: name,
      iconUrl: undefined,
      adminId: adminId,
      members: [member],
      tasks: [
        { id: 1, text: 'Group Mind Task', cp: 1, category: 'mind', completedBy: [] },
        { id: 2, text: 'Group Body Task', cp: 1, category: 'body', completedBy: [] },
        { id: 3, text: 'Group Soul Task', cp: 1, category: 'soul', completedBy: [] },
      ],
      messages: [],
    };
    setGroups((prev) => {
      const updatedGroups = [...prev, newGroup];
      saveGroupsToStorage(updatedGroups);
      return updatedGroups;
    });
  };

  const joinGroup = (groupId: string, member: GroupMember) => {
    setGroups((prev) => {
      const updatedGroups = prev.map((g) =>
        g.id === groupId && !g.members.find((m) => m.id === member.id)
          ? { ...g, members: [...g.members, member] }
          : g
      );
      saveGroupsToStorage(updatedGroups);
      return updatedGroups;
    });
  };

  const leaveGroup = (groupId: string, memberId: string) => {
    setGroups((prev) => {
      const updatedGroups = prev.map((g) =>
        g.id === groupId
          ? { ...g, members: g.members.filter((m) => m.id !== memberId) }
          : g
      );
      saveGroupsToStorage(updatedGroups);
      return updatedGroups;
    });
  };

  const completeGroupTask = (groupId: string, memberId: string, taskId: number, category: 'mind' | 'body' | 'soul') => {
    setGroups((prev) => {
      const updatedGroups = prev.map((g) =>
        g.id === groupId
          ? {
              ...g,
              tasks: g.tasks.map((t) =>
                t.id === taskId && !t.completedBy.includes(memberId)
                  ? { ...t, completedBy: [...t.completedBy, memberId] }
                  : t
              ),
              members: g.members.map((m) =>
                m.id === memberId
                  ? { ...m, groupCP: { ...m.groupCP, [category]: m.groupCP[category] + 1 } }
                  : m
              ),
            }
          : g
      );
      saveGroupsToStorage(updatedGroups);
      return updatedGroups;
    });
  };

  const getGroupCP = (groupId: string, memberId: string, category: 'mind' | 'body' | 'soul'): number => {
    const group = groups.find((g) => g.id === groupId);
    const member = group?.members.find((m) => m.id === memberId);
    return member?.groupCP[category] || 0;
  };

  const setCurrentGroup = (groupId: string | null) => setCurrentGroupId(groupId);
  const getCurrentGroup = () => groups.find((g) => g.id === currentGroupId) || null;

  const sendMessage = (groupId: string, userId: string, userName: string, text: string) => {
    setGroups((prev) => {
      const updatedGroups = prev.map((g) =>
        g.id === groupId
          ? {
              ...g,
              messages: [
                ...g.messages,
                {
                  id: Date.now().toString(),
                  userId,
                  userName,
                  text,
                  timestamp: Date.now(),
                },
              ],
            }
          : g
      );
      saveGroupsToStorage(updatedGroups);
      return updatedGroups;
    });
  };

  const clearAllGroups = () => {
    setGroups([DEMO_GROUP]);
    saveGroupsToStorage([DEMO_GROUP]);
  };

  const deleteGroup = (groupId: string) => {
    setGroups((prev) => {
      const updatedGroups = prev.filter(g => g.id !== groupId);
      saveGroupsToStorage(updatedGroups);
      return updatedGroups;
    });
  };

  const refreshGroupsFromStorage = async () => {
    await loadGroupsFromStorage();
  };

  const syncBackendGroups = async () => {
    try {
      // Load groups from backend and merge with local context
      const backendGroups = await groupService.getUserGroups();
      
      // Merge backend groups with local context groups
      const mergedGroups = [...groups];
      
      backendGroups.forEach((backendGroup: any) => {
        const existingGroup = mergedGroups.find(g => g.id === backendGroup.id);
        if (!existingGroup) {
          // Convert backend group to context format
          const contextGroup: Group = {
            id: backendGroup.id,
            name: backendGroup.name,
            iconUrl: undefined,
            adminId: backendGroup.createdBy,
            members: [{
              id: backendGroup.createdBy,
              name: 'User', // This should be the actual user name
              groupCP: { mind: 0, body: 0, soul: 0 }
            }],
            tasks: [
              { id: 1, text: 'Group Mind Task', cp: 1, category: 'mind', completedBy: [] },
              { id: 2, text: 'Group Body Task', cp: 1, category: 'body', completedBy: [] },
              { id: 3, text: 'Group Soul Task', cp: 1, category: 'soul', completedBy: [] },
            ],
            messages: [],
          };
          mergedGroups.push(contextGroup);
        }
      });
      
      setGroups(mergedGroups);
      saveGroupsToStorage(mergedGroups);
    } catch (error) {
      console.error('Error syncing backend groups:', error);
    }
  };

  return (
    <GroupContext.Provider
      value={{
        groups,
        currentGroupId,
        isLoading,
        createGroup,
        joinGroup,
        leaveGroup,
        completeGroupTask,
        getGroupCP,
        setCurrentGroup,
        getCurrentGroup,
        sendMessage,
        clearAllGroups,
        deleteGroup,
        refreshGroupsFromStorage,
        syncBackendGroups,
      }}
    >
      {children}
    </GroupContext.Provider>
  );
}

export { GroupContext }; 