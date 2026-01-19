'use client';

/**
 * REAL-TIME SYNC SERVICE - WebSocket-based updates
 *
 * IMPORTANT: Auto-refresh should ALWAYS use WebSocket (push-based), NOT polling.
 *
 * WHY WebSocket over Polling:
 * - Instant updates: Data appears immediately when events occur
 * - Efficient: No unnecessary network requests when nothing changed
 * - Scalable: Server pushes only when needed, not on fixed intervals
 * - Battery-friendly: No constant polling draining device resources
 *
 * HOW TO USE:
 * 1. Import the appropriate hook (useSync, useSyncRefresh, or useChatSync)
 * 2. Pass handlers for events you want to listen to
 * 3. In handlers, invalidate React Query cache to trigger re-fetch
 *
 * EXAMPLE:
 * ```tsx
 * const queryClient = useQueryClient();
 * const refreshData = useCallback(() => {
 *   queryClient.invalidateQueries({ queryKey: ['my-data'] });
 * }, [queryClient]);
 *
 * useChatSync({
 *   onNewMessage: refreshData,
 *   onConversationUpdated: refreshData,
 * });
 * ```
 *
 * DO NOT use refetchInterval for auto-refresh - that's polling!
 * ALWAYS prefer WebSocket events for real-time updates.
 */

import { useEffect, useRef } from 'react';
import { io, Socket } from 'socket.io-client';

type SyncEventType =
  | 'verification:created'
  | 'verification:updated'
  | 'plant:created'
  | 'plant:updated'
  | 'plant:deleted'
  | 'chat:message'
  | 'chat:created'
  | 'chat:updated'
  | 'chat:read'
  | 'data:refresh';

type SyncHandler = (data: unknown) => void;

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000';

export function useSync(events: { event: SyncEventType; handler: SyncHandler }[]) {
  const socketRef = useRef<Socket | null>(null);

  useEffect(() => {
    const token = localStorage.getItem('accessToken');
    if (!token) return;

    // Connect to sync namespace
    const socket = io(`${API_URL.replace('/v1', '')}/sync`, {
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

// Hook for auto-refreshing data via WebSocket
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

// Hook specifically for chat real-time updates
export function useChatSync(handlers: {
  onNewMessage?: (data: unknown) => void;
  onConversationCreated?: (data: unknown) => void;
  onConversationUpdated?: (data: unknown) => void;
  onMessagesRead?: (data: unknown) => void;
}) {
  const events: { event: SyncEventType; handler: SyncHandler }[] = [];

  if (handlers.onNewMessage) {
    events.push({ event: 'chat:message', handler: handlers.onNewMessage });
  }
  if (handlers.onConversationCreated) {
    events.push({ event: 'chat:created', handler: handlers.onConversationCreated });
  }
  if (handlers.onConversationUpdated) {
    events.push({ event: 'chat:updated', handler: handlers.onConversationUpdated });
  }
  if (handlers.onMessagesRead) {
    events.push({ event: 'chat:read', handler: handlers.onMessagesRead });
  }

  useSync(events);
}
