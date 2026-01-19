'use client';

import { useEffect, useRef, useCallback } from 'react';
import { io, Socket } from 'socket.io-client';

type SyncEventType =
  | 'verification:created'
  | 'verification:updated'
  | 'plant:created'
  | 'plant:updated'
  | 'plant:deleted'
  | 'data:refresh';

type SyncHandler = (data: any) => void;

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000';

export function useSync(events: { event: SyncEventType; handler: SyncHandler }[]) {
  const socketRef = useRef<Socket | null>(null);

  useEffect(() => {
    const token = localStorage.getItem('accessToken');
    if (!token) return;

    // Connect to sync namespace
    const socket = io(`${API_URL}/sync`, {
      auth: { token },
      transports: ['websocket'],
      reconnection: true,
      reconnectionDelay: 1000,
      reconnectionDelayMax: 5000,
    });

    socketRef.current = socket;

    socket.on('connect', () => {
      console.log('[Admin Sync] Connected to sync server');
    });

    socket.on('disconnect', () => {
      console.log('[Admin Sync] Disconnected from sync server');
    });

    socket.on('error', (error) => {
      console.error('[Admin Sync] Error:', error);
    });

    // Register event handlers
    events.forEach(({ event, handler }) => {
      socket.on(event, handler);
    });

    return () => {
      events.forEach(({ event, handler }) => {
        socket.off(event, handler);
      });
      socket.disconnect();
    };
  }, [events]);

  return socketRef.current;
}

// Hook for auto-refreshing data
export function useSyncRefresh(onRefresh: () => void, eventTypes: SyncEventType[]) {
  const events = eventTypes.map(event => ({
    event,
    handler: () => {
      console.log(`[Admin Sync] Received ${event}, refreshing...`);
      onRefresh();
    },
  }));

  useSync(events);
}
