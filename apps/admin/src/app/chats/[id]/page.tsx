'use client';

import { useParams } from 'next/navigation';
import { useState, useCallback, useMemo } from 'react';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import { DashboardLayout } from '@/components/layout/DashboardLayout';
import {
  ArrowLeftIcon,
  ChevronLeftIcon,
  ChevronRightIcon,
  CheckIcon,
  CheckCircleIcon,
  ArrowDownTrayIcon,
  SignalIcon,
} from '@heroicons/react/24/outline';
import { apiClient } from '@/lib/api';
import { useChatSync } from '@/lib/useSync';
import Link from 'next/link';

interface Message {
  id: string;
  senderType: 'consumer' | 'owner';
  senderId: string;
  content: string;
  sentAt: string;
  deliveredAt: string | null;
  readAt: string | null;
  deliveryDelayMs: number | null;
  readDelayMs: number | null;
}

interface ConversationDetail {
  conversation: {
    id: string;
    createdAt: string;
    lastMessageAt: string | null;
    plant: {
      id: string;
      name: string;
      address: string;
      isVerified: boolean;
    };
    owner: {
      id: string;
      name: string;
      email: string;
      phone: string;
    };
    consumer: {
      id: string;
      name: string;
      email: string;
      phone: string;
      displayName: string;
    };
  };
  statistics: {
    totalMessages: number;
    totalFromConsumer: number;
    totalFromOwner: number;
    deliveredCount: number;
    readCount: number;
    deliveryRate: number;
    readRate: number;
  };
  messages: Message[];
  meta: {
    page: number;
    limit: number;
    total: number;
    totalPages: number;
  };
}

export default function ChatDetailPage() {
  const params = useParams();
  const conversationId = params.id as string;
  const [page, setPage] = useState(1);
  const queryClient = useQueryClient();

  // Real-time WebSocket updates
  const refreshData = useCallback(() => {
    queryClient.invalidateQueries({ queryKey: ['conversation-detail', conversationId] });
  }, [queryClient, conversationId]);

  // Memoize handlers to prevent useEffect loop
  const syncHandlers = useMemo(() => ({
    onNewMessage: (data: unknown) => {
      const msgData = data as { conversationId?: string };
      if (msgData.conversationId === conversationId) {
        refreshData();
      }
    },
    onConversationUpdated: (data: unknown) => {
      const convData = data as { id?: string };
      if (convData.id === conversationId) {
        refreshData();
      }
    },
    onMessagesRead: (data: unknown) => {
      const readData = data as { conversationId?: string };
      if (readData.conversationId === conversationId) {
        refreshData();
      }
    },
  }), [conversationId, refreshData]);

  useChatSync(syncHandlers);

  const { data, isLoading, error } = useQuery({
    queryKey: ['conversation-detail', conversationId, page],
    queryFn: async () => {
      const response = await apiClient.get<ConversationDetail>(
        `/admin/chat/conversations/${conversationId}?page=${page}&limit=100`
      );
      if (response.success && response.data) {
        return response.data;
      }
      throw new Error('Failed to fetch conversation');
    },
  });

  const formatDateTime = (dateStr: string) => {
    const date = new Date(dateStr);
    return date.toLocaleString([], {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit',
    });
  };

  const formatTime = (dateStr: string) => {
    const date = new Date(dateStr);
    return date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
  };

  const formatDelay = (ms: number | null) => {
    if (ms === null) return '-';
    if (ms < 1000) return `${ms}ms`;
    if (ms < 60000) return `${(ms / 1000).toFixed(1)}s`;
    if (ms < 3600000) return `${Math.round(ms / 60000)}m`;
    return `${(ms / 3600000).toFixed(1)}h`;
  };

  const handleExport = async () => {
    try {
      const response = await apiClient.get<unknown>(`/admin/chat/conversations/${conversationId}/export`);
      if (response.success && response.data) {
        const blob = new Blob([JSON.stringify(response.data, null, 2)], { type: 'application/json' });
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `conversation-${conversationId}-export.json`;
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        URL.revokeObjectURL(url);
      }
    } catch (err) {
      console.error('Export failed:', err);
    }
  };

  const getMessageStatus = (msg: Message) => {
    if (msg.readAt) {
      return (
        <span className="flex items-center gap-1 text-xs text-blue-500">
          <CheckCircleIcon className="h-4 w-4" />
          Read
        </span>
      );
    }
    if (msg.deliveredAt) {
      return (
        <span className="flex items-center gap-1 text-xs text-gray-500">
          <CheckIcon className="h-4 w-4" />
          <CheckIcon className="-ml-3 h-4 w-4" />
          Delivered
        </span>
      );
    }
    return (
      <span className="flex items-center gap-1 text-xs text-gray-400">
        <CheckIcon className="h-4 w-4" />
        Sent
      </span>
    );
  };

  if (isLoading) {
    return (
      <DashboardLayout>
        <div className="flex h-96 items-center justify-center">
          <div className="text-gray-500">Loading conversation...</div>
        </div>
      </DashboardLayout>
    );
  }

  if (error || !data) {
    return (
      <DashboardLayout>
        <div className="flex h-96 flex-col items-center justify-center gap-4">
          <div className="text-red-500">Failed to load conversation</div>
          <Link href="/chats" className="text-blue-600 hover:text-blue-800">
            Back to Chats
          </Link>
        </div>
      </DashboardLayout>
    );
  }

  const { conversation, statistics, messages, meta } = data;

  return (
    <DashboardLayout>
      <div className="space-y-6">
        {/* Header */}
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-4">
            <Link
              href="/chats"
              className="rounded-lg p-2 text-gray-500 hover:bg-gray-100"
            >
              <ArrowLeftIcon className="h-5 w-5" />
            </Link>
            <div>
              <div className="flex items-center gap-3">
                <h1 className="text-2xl font-bold text-gray-900">Conversation Detail</h1>
                <span className="flex items-center gap-1 rounded-full bg-green-100 px-2 py-0.5 text-xs font-medium text-green-700">
                  <SignalIcon className="h-3 w-3" />
                  Live
                </span>
              </div>
              <p className="text-sm text-gray-500">
                {conversation.plant.name} - {conversation.consumer.displayName}
              </p>
            </div>
          </div>
          <button
            onClick={handleExport}
            className="flex items-center gap-2 rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50"
          >
            <ArrowDownTrayIcon className="h-4 w-4" />
            Export
          </button>
        </div>

        {/* Info Cards */}
        <div className="grid gap-6 lg:grid-cols-3">
          {/* Plant Info */}
          <div className="rounded-xl bg-white p-6 shadow-sm">
            <h3 className="mb-4 font-semibold text-gray-900">Plant</h3>
            <div className="space-y-2">
              <div>
                <span className="text-sm text-gray-500">Name:</span>
                <p className="font-medium text-gray-900">{conversation.plant.name}</p>
              </div>
              <div>
                <span className="text-sm text-gray-500">Address:</span>
                <p className="text-sm text-gray-700">{conversation.plant.address}</p>
              </div>
              <div>
                <span className="text-sm text-gray-500">Status:</span>
                <p>
                  {conversation.plant.isVerified ? (
                    <span className="inline-flex rounded-full bg-green-100 px-2 py-0.5 text-xs font-medium text-green-800">
                      Verified
                    </span>
                  ) : (
                    <span className="inline-flex rounded-full bg-gray-100 px-2 py-0.5 text-xs font-medium text-gray-800">
                      Unverified
                    </span>
                  )}
                </p>
              </div>
            </div>
          </div>

          {/* Owner Info */}
          <div className="rounded-xl bg-white p-6 shadow-sm">
            <h3 className="mb-4 font-semibold text-gray-900">
              Owner - {conversation.owner.name}, {conversation.plant.name}
            </h3>
            <div className="space-y-2">
              <div>
                <span className="text-sm text-gray-500">Name:</span>
                <p className="font-medium text-gray-900">{conversation.owner.name}</p>
              </div>
              <div>
                <span className="text-sm text-gray-500">Shop/Plant:</span>
                <p className="font-medium text-gray-900">{conversation.plant.name}</p>
              </div>
              <div>
                <span className="text-sm text-gray-500">Email:</span>
                <p className="text-sm text-gray-700">{conversation.owner.email}</p>
              </div>
              <div>
                <span className="text-sm text-gray-500">Phone:</span>
                <p className="text-sm text-gray-700">{conversation.owner.phone || '-'}</p>
              </div>
            </div>
          </div>

          {/* Consumer Info */}
          <div className="rounded-xl bg-white p-6 shadow-sm">
            <h3 className="mb-4 font-semibold text-gray-900">
              Consumer - {conversation.consumer.name} ({conversation.consumer.displayName})
            </h3>
            <div className="space-y-2">
              <div>
                <span className="text-sm text-gray-500">Real Name:</span>
                <p className="font-medium text-gray-900">{conversation.consumer.name}</p>
              </div>
              <div>
                <span className="text-sm text-gray-500">Display Name:</span>
                <p className="font-medium text-gray-900">{conversation.consumer.displayName}</p>
              </div>
              <div>
                <span className="text-sm text-gray-500">Email:</span>
                <p className="text-sm text-gray-700">{conversation.consumer.email}</p>
              </div>
              <div>
                <span className="text-sm text-gray-500">Phone:</span>
                <p className="text-sm text-gray-700">{conversation.consumer.phone || '-'}</p>
              </div>
            </div>
          </div>
        </div>

        {/* Statistics */}
        <div className="rounded-xl bg-white p-6 shadow-sm">
          <h3 className="mb-4 font-semibold text-gray-900">Statistics</h3>
          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
            <div className="rounded-lg bg-gray-50 p-4">
              <p className="text-sm text-gray-500">Total Messages</p>
              <p className="text-2xl font-bold text-gray-900">{statistics.totalMessages}</p>
              <p className="text-xs text-gray-400">
                {statistics.totalFromConsumer} from consumer, {statistics.totalFromOwner} from owner
              </p>
            </div>
            <div className="rounded-lg bg-gray-50 p-4">
              <p className="text-sm text-gray-500">Delivered</p>
              <p className="text-2xl font-bold text-gray-900">{statistics.deliveredCount}</p>
              <p className="text-xs text-gray-400">{statistics.deliveryRate}% delivery rate</p>
            </div>
            <div className="rounded-lg bg-gray-50 p-4">
              <p className="text-sm text-gray-500">Read</p>
              <p className="text-2xl font-bold text-gray-900">{statistics.readCount}</p>
              <p className="text-xs text-gray-400">{statistics.readRate}% read rate</p>
            </div>
            <div className="rounded-lg bg-gray-50 p-4">
              <p className="text-sm text-gray-500">Started</p>
              <p className="text-sm font-medium text-gray-900">
                {formatDateTime(conversation.createdAt)}
              </p>
              <p className="text-xs text-gray-400">
                Last: {conversation.lastMessageAt ? formatDateTime(conversation.lastMessageAt) : '-'}
              </p>
            </div>
          </div>
        </div>

        {/* Messages */}
        <div className="rounded-xl bg-white shadow-sm">
          <div className="border-b border-gray-200 px-6 py-4">
            <h3 className="font-semibold text-gray-900">Messages ({meta.total})</h3>
          </div>

          <div className="max-h-[600px] overflow-y-auto p-6">
            <div className="space-y-4">
              {messages.map((msg, idx) => {
                const isConsumer = msg.senderType === 'consumer';
                const showDateHeader = idx === 0 ||
                  new Date(messages[idx - 1].sentAt).toDateString() !== new Date(msg.sentAt).toDateString();

                return (
                  <div key={msg.id}>
                    {showDateHeader && (
                      <div className="my-4 flex items-center justify-center">
                        <span className="rounded-full bg-gray-100 px-3 py-1 text-xs text-gray-500">
                          {new Date(msg.sentAt).toLocaleDateString([], {
                            weekday: 'long',
                            year: 'numeric',
                            month: 'long',
                            day: 'numeric',
                          })}
                        </span>
                      </div>
                    )}
                    <div className={`flex ${isConsumer ? 'justify-start' : 'justify-end'}`}>
                      <div
                        className={`max-w-[70%] rounded-2xl px-4 py-2 ${
                          isConsumer
                            ? 'bg-teal-100 text-teal-900'
                            : 'bg-indigo-100 text-indigo-900'
                        }`}
                      >
                        <div className="flex items-center gap-2 mb-1">
                          <span className={`text-xs font-medium ${
                            isConsumer ? 'text-teal-700' : 'text-indigo-700'
                          }`}>
                            {isConsumer ? 'Consumer' : 'Owner'}
                          </span>
                        </div>
                        <p className="text-sm">{msg.content}</p>
                        <div className="mt-1 flex items-center justify-between gap-4">
                          <span className="text-xs opacity-60">
                            {formatTime(msg.sentAt)}
                          </span>
                          {getMessageStatus(msg)}
                        </div>
                        {/* Metadata */}
                        <div className="mt-2 border-t border-black/10 pt-2 text-xs opacity-50">
                          <div className="grid grid-cols-2 gap-x-4 gap-y-1">
                            <span>Sent:</span>
                            <span>{formatDateTime(msg.sentAt)}</span>
                            <span>Delivered:</span>
                            <span>
                              {msg.deliveredAt ? formatDateTime(msg.deliveredAt) : '-'}
                              {msg.deliveryDelayMs !== null && (
                                <span className="ml-1 text-gray-500">
                                  (+{formatDelay(msg.deliveryDelayMs)})
                                </span>
                              )}
                            </span>
                            <span>Read:</span>
                            <span>
                              {msg.readAt ? formatDateTime(msg.readAt) : '-'}
                              {msg.readDelayMs !== null && (
                                <span className="ml-1 text-gray-500">
                                  (+{formatDelay(msg.readDelayMs)})
                                </span>
                              )}
                            </span>
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>
          </div>

          {/* Pagination */}
          {meta.totalPages > 1 && (
            <div className="flex items-center justify-between border-t border-gray-200 px-6 py-4">
              <div className="text-sm text-gray-500">
                Page {meta.page} of {meta.totalPages}
              </div>
              <div className="flex gap-2">
                <button
                  onClick={() => setPage((p) => Math.max(1, p - 1))}
                  disabled={page === 1}
                  className="flex items-center gap-1 rounded-lg border border-gray-300 px-3 py-1.5 text-sm font-medium text-gray-700 hover:bg-gray-50 disabled:cursor-not-allowed disabled:opacity-50"
                >
                  <ChevronLeftIcon className="h-4 w-4" />
                  Previous
                </button>
                <button
                  onClick={() => setPage((p) => Math.min(meta.totalPages, p + 1))}
                  disabled={page === meta.totalPages}
                  className="flex items-center gap-1 rounded-lg border border-gray-300 px-3 py-1.5 text-sm font-medium text-gray-700 hover:bg-gray-50 disabled:cursor-not-allowed disabled:opacity-50"
                >
                  Next
                  <ChevronRightIcon className="h-4 w-4" />
                </button>
              </div>
            </div>
          )}
        </div>
      </div>
    </DashboardLayout>
  );
}
