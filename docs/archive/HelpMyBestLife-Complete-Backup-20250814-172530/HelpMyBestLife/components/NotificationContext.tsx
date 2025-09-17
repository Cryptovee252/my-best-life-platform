import React, { createContext, useContext, useState, useEffect, ReactNode, useRef, useMemo } from 'react';
import AsyncStorage from '@react-native-async-storage/async-storage';

export type Notification = {
  id: string;
  message: string;
  type?: 'info' | 'success' | 'warning' | 'error';
  read?: boolean;
  timestamp: number;
  link?: string;
};

type NotificationContextType = {
  notifications: Notification[];
  addNotification: (message: string, type?: Notification['type']) => void;
  markAsRead: (id: string) => void;
  clearAll: () => void;
};

const NotificationContext = createContext<NotificationContextType | undefined>(undefined);

export const NotificationProvider = ({ children }: { children: ReactNode }) => {
  const [notifications, setNotifications] = useState<Notification[]>([]);
  const saveTimeoutRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  useEffect(() => {
    AsyncStorage.getItem('notifications').then((data) => {
      if (data) setNotifications(JSON.parse(data));
    });
  }, []);

  // Debounced save to prevent rapid successive saves
  const debouncedSave = (data: Notification[]) => {
    if (saveTimeoutRef.current) {
      clearTimeout(saveTimeoutRef.current);
    }
    saveTimeoutRef.current = setTimeout(async () => {
      try {
        await AsyncStorage.setItem('notifications', JSON.stringify(data));
      } catch (error) {
        console.error('Error saving notifications:', error);
      }
    }, 100);
  };

  useEffect(() => {
    debouncedSave(notifications);

    // Cleanup function to clear timeout on unmount
    return () => {
      if (saveTimeoutRef.current) {
        clearTimeout(saveTimeoutRef.current);
      }
    };
  }, [notifications]);

  const addNotification = (message: string, type: Notification['type'] = 'info') => {
    setNotifications((prev) => [
      {
        id: Date.now().toString(),
        message,
        type,
        read: false,
        timestamp: Date.now(),
      },
      ...prev,
    ]);
  };

  const markAsRead = (id: string) => {
    setNotifications((prev) => prev.map((n) => (n.id === id ? { ...n, read: true } : n)));
  };

  const clearAll = () => setNotifications([]);

  const contextValue = useMemo(() => ({
    notifications,
    addNotification,
    markAsRead,
    clearAll,
  }), [notifications]);

  return (
    <NotificationContext.Provider value={contextValue}>
      {children}
    </NotificationContext.Provider>
  );
};

export const useNotification = () => {
  const ctx = useContext(NotificationContext);
  if (!ctx) throw new Error('useNotification must be used within NotificationProvider');
  return ctx;
}; 