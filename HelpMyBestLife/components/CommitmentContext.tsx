import React, { createContext, useContext, useState, ReactNode, useEffect } from 'react';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { useUser } from './UserContext';

export type Category = 'mind' | 'body' | 'soul';
export type Task = { id: number; text: string; cp: number };

interface CommitmentState {
  completed: {
    mind: number[];
    body: number[];
    soul: number[];
  };
  lastResetDate: string;
  lifetimeCP: {
    mind: number;
    body: number;
    soul: number;
  };
  completeTask: (category: Category, taskId: number) => void;
  uncompleteTask: (category: Category, taskId: number) => void;
  getCP: (category: Category) => number;
  getLifetimeCP: (category: Category) => number;
  loading: boolean;
}

const CommitmentContext = createContext<CommitmentState | undefined>(undefined);

export function useCommitment() {
  const ctx = useContext(CommitmentContext);
  if (!ctx) throw new Error('useCommitment must be used within CommitmentProvider');
  return ctx;
}

function getTodayString() {
  const now = new Date();
  return now.toISOString().slice(0, 10); // YYYY-MM-DD
}

function getDaysSinceStart(startDate: string): number {
  const start = new Date(startDate);
  const today = new Date();
  const diffTime = Math.abs(today.getTime() - start.getTime());
  const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
  return diffDays;
}

const COMPLETED_KEY = 'commitment_completed';
const RESET_DATE_KEY = 'commitment_lastResetDate';
const LIFETIME_CP_KEY = 'commitment_lifetimeCP';
const START_DATE_KEY = 'commitment_startDate';

export function CommitmentProvider({ children }: { children: ReactNode }) {
  const [completed, setCompleted] = useState({
    mind: [] as number[],
    body: [] as number[],
    soul: [] as number[],
  });
  const [lastResetDate, setLastResetDate] = useState(getTodayString());
  const [lifetimeCP, setLifetimeCP] = useState({ mind: 0, body: 0, soul: 0 });
  const [startDate, setStartDate] = useState(getTodayString());
  const [loaded, setLoaded] = useState(false);
  const { updateCPData, user } = useUser();

  // Get user-specific storage keys
  const getStorageKeys = () => {
    const userId = user?.id || 'anonymous';
    return {
      completed: `${COMPLETED_KEY}_${userId}`,
      resetDate: `${RESET_DATE_KEY}_${userId}`,
      lifetimeCP: `${LIFETIME_CP_KEY}_${userId}`,
      startDate: `${START_DATE_KEY}_${userId}`,
    };
  };

  // Load from AsyncStorage on mount and when user changes
  useEffect(() => {
    (async () => {
      try {
        const keys = getStorageKeys();
        const [completedStr, resetDateStr, lifetimeCPStr, startDateStr] = await Promise.all([
          AsyncStorage.getItem(keys.completed),
          AsyncStorage.getItem(keys.resetDate),
          AsyncStorage.getItem(keys.lifetimeCP),
          AsyncStorage.getItem(keys.startDate),
        ]);
        
        if (completedStr) setCompleted(JSON.parse(completedStr));
        if (resetDateStr) setLastResetDate(resetDateStr);
        if (lifetimeCPStr) setLifetimeCP(JSON.parse(lifetimeCPStr));
        if (startDateStr) setStartDate(startDateStr);
      } catch (e) {
        console.error('Error loading commitment data:', e);
      } finally {
        setLoaded(true);
      }
    })();
  }, [user?.id]); // Reload when user changes

  // Save to AsyncStorage on change
  useEffect(() => {
    if (!loaded) return;
    
    const saveData = async () => {
      try {
        const keys = getStorageKeys();
        await AsyncStorage.setItem(keys.completed, JSON.stringify(completed));
      } catch (error) {
        console.error('Error saving completed data:', error);
      }
    };
    
    saveData();
  }, [completed, loaded]);
  
  useEffect(() => {
    if (!loaded) return;
    
    const saveData = async () => {
      try {
        const keys = getStorageKeys();
        await AsyncStorage.setItem(keys.resetDate, lastResetDate);
      } catch (error) {
        console.error('Error saving reset date:', error);
      }
    };
    
    saveData();
  }, [lastResetDate, loaded]);
  
  useEffect(() => {
    if (!loaded) return;
    
    const saveData = async () => {
      try {
        const keys = getStorageKeys();
        await AsyncStorage.setItem(keys.lifetimeCP, JSON.stringify(lifetimeCP));
      } catch (error) {
        console.error('Error saving lifetime CP:', error);
      }
    };
    
    saveData();
  }, [lifetimeCP, loaded]);

  useEffect(() => {
    if (!loaded) return;
    
    const saveData = async () => {
      try {
        const keys = getStorageKeys();
        await AsyncStorage.setItem(keys.startDate, startDate);
      } catch (error) {
        console.error('Error saving start date:', error);
      }
    };
    
    saveData();
  }, [startDate, loaded]);

  // Sync with UserContext when CP data changes
  useEffect(() => {
    if (!loaded) return;
    
    const mindCP = completed.mind.length;
    const bodyCP = completed.body.length;
    const soulCP = completed.soul.length;
    const totalDailyCP = mindCP + bodyCP + soulCP;
    
    const totalLifetimeCP = lifetimeCP.mind + lifetimeCP.body + lifetimeCP.soul;
    
    // Only update if there's an actual change to avoid infinite loops
    const currentUserCP = {
      mind: lifetimeCP.mind,
      body: lifetimeCP.body,
      soul: lifetimeCP.soul,
    };
    
    updateCPData(totalDailyCP, totalLifetimeCP, currentUserCP);
  }, [completed, lifetimeCP, loaded]); // Removed updateCPData from dependencies

  // Daily reset logic - check every minute for midnight reset
  useEffect(() => {
    if (!loaded) return;
    
    const checkForReset = () => {
      const today = getTodayString();
      if (lastResetDate !== today) {
        console.log('Resetting tasks for new day:', today);
        // Reset completed tasks
        setCompleted({ mind: [], body: [], soul: [] });
        // Update reset date
        setLastResetDate(today);
      }
    };

    // Check immediately
    checkForReset();
    
    // Check every minute
    const interval = setInterval(checkForReset, 60000);
    
    return () => {
      clearInterval(interval);
    };
  }, [lastResetDate, loaded]);

  const completeTask = (category: Category, taskId: number) => {
    setCompleted((prev) => {
      if (prev[category].includes(taskId)) return prev;
      
      // Update lifetime CP
      setLifetimeCP((cp) => ({ ...cp, [category]: cp[category] + 1 }));
      
      return {
        ...prev,
        [category]: [...prev[category], taskId],
      };
    });
  };

  const uncompleteTask = (category: Category, taskId: number) => {
    setCompleted((prev) => ({
      ...prev,
      [category]: prev[category].filter((id) => id !== taskId),
    }));
    // Note: Lifetime CP does not decrease when uncompleting
  };

  const getCP = (category: Category) => completed[category].length;
  const getLifetimeCP = (category: Category) => lifetimeCP[category];

  if (!loaded) return null;

  return (
    <CommitmentContext.Provider value={{ 
      completed, 
      lastResetDate, 
      lifetimeCP, 
      completeTask, 
      uncompleteTask, 
      getCP, 
      getLifetimeCP, 
      loading: !loaded 
    }}>
      {children}
    </CommitmentContext.Provider>
  );
} 