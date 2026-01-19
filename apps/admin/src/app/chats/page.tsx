'use client';

import { useState, useCallback, useMemo } from 'react';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import { DashboardLayout } from '@/components/layout/DashboardLayout';
import {
  MagnifyingGlassIcon,
  ChevronLeftIcon,
  ChevronRightIcon,
  ChatBubbleLeftRightIcon,
  EyeIcon,
  SignalIcon,
} from '@heroicons/react/24/outline';
import { apiClient } from '@/lib/api';
import { useChatSync } from '@/lib/useSync';
import Link from 'next/link';

interface Conversation {
  id: string;
  createdAt: string;
  lastMessageAt: string | null;
  plant: {
    id: string;
    name: string;
    address: string;
  };
  owner: {
    id: string;
    name: string;
    email: string;
  };
  consumer: {
    id: string;
    name: string;
    email: string;
    displayName: string;
  };
  messageCount: number;
  unreadFromConsumer: number;
  unreadFromOwner: number;
  lastMessage: {
    content: string;
    senderType: string;
    sentAt: string;
    deliveredAt: string | null;
    readAt: string | null;
  } | null;
}

interface ChatStats {
  totalConversations: number;
  totalMessages: number;
  messagesLast24h: number;
  messagesLast7d: number;
  unreadMessages: number;
  deliveredMessages: number;
  readMessages: number;
  deliveryRate: number;
  readRate: number;
}

interface ConversationsResponse {
  conversations: Conversation[];
  meta: {
    page: number;
    limit: number;
    total: number;
    totalPages: number;
  };
}

export default function ChatsPage() {
  const [search, setSearch] = useState('');
  const [page, setPage] = useState(1);
  const queryClient = useQueryClient();

  // Real-time WebSocket updates
  const refreshData = useCallback(() => {
    queryClient.invalidateQueries({ queryKey: ['admin-chats'] });
    queryClient.invalidateQueries({ queryKey: ['chat-stats'] });
  }, [queryClient]);

  // Memoize handlers to prevent useEffect loop
  const syncHandlers = useMemo(() => ({
    onNewMessage: refreshData,
    onConversationCreated: refreshData,
    onConversationUpdated: refreshData,
    onMessagesRead: refreshData,
  }), [refreshData]);

  useChatSync(syncHandlers);

  const { data: stats } = useQuery({
    queryKey: ['chat-stats'],
    queryFn: async () => {
      const response = await apiClient.get<ChatStats>('/admin/chat/stats');
      if (response.success && response.data) {
        return response.data;
      }
      throw new Error('Failed to fetch chat stats');
    },
  });

  const { data, isLoading, error } = useQuery({
    queryKey: ['admin-chats', page, search],
    queryFn: async () => {
      const params = new URLSearchParams();
      params.set('page', String(page));
      params.set('limit', '20');
      if (search) params.set('search', search);

      const response = await apiClient.get<ConversationsResponse>(`/admin/chat/conversations?${params.toString()}`);
      if (response.success && response.data) {
        return response.data;
      }
      throw new Error('Failed to fetch conversations');
    },
  });

  const formatDate = (dateStr: string | null) => {
    if (!dateStr) return '-';
    const date = new Date(dateStr);
    const now = new Date();
    const diffMs = now.getTime() - date.getTime();
    const diffDays = Math.floor(diffMs / (1000 * 60 * 60 * 24));

    if (diffDays === 0) {
      return date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
    } else if (diffDays === 1) {
      return 'Yesterday';
    } else if (diffDays < 7) {
      return date.toLocaleDateString([], { weekday: 'short' });
    }
    return date.toLocaleDateString([], { month: 'short', day: 'numeric' });
  };

  const truncateMessage = (msg: string, maxLen = 50) => {
    if (msg.length <= maxLen) return msg;
    return msg.substring(0, maxLen) + '...';
  };

  return (
    <DashboardLayout>
      <div className="space-y-6">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-3">
            <h1 className="text-2xl font-bold text-gray-900">Chats</h1>
            <span className="flex items-center gap-1 rounded-full bg-green-100 px-2 py-0.5 text-xs font-medium text-green-700">
              <SignalIcon className="h-3 w-3" />
              Live
            </span>
          </div>
          <div className="text-sm text-gray-500">
            {data?.meta.total || 0} total conversations
          </div>
        </div>

        {/* Stats Cards */}
        {stats && (
          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
            <div className="rounded-xl bg-white p-4 shadow-sm">
              <div className="flex items-center gap-3">
                <div className="rounded-lg bg-blue-100 p-2">
                  <ChatBubbleLeftRightIcon className="h-5 w-5 text-blue-600" />
                </div>
                <div>
                  <p className="text-sm text-gray-500">Total Messages</p>
                  <p className="text-xl font-bold text-gray-900">{stats.totalMessages.toLocaleString()}</p>
                </div>
              </div>
            </div>
            <div className="rounded-xl bg-white p-4 shadow-sm">
              <div className="flex items-center gap-3">
                <div className="rounded-lg bg-green-100 p-2">
                  <ChatBubbleLeftRightIcon className="h-5 w-5 text-green-600" />
                </div>
                <div>
                  <p className="text-sm text-gray-500">Last 24 Hours</p>
                  <p className="text-xl font-bold text-gray-900">{stats.messagesLast24h.toLocaleString()}</p>
                </div>
              </div>
            </div>
            <div className="rounded-xl bg-white p-4 shadow-sm">
              <div className="flex items-center gap-3">
                <div className="rounded-lg bg-purple-100 p-2">
                  <EyeIcon className="h-5 w-5 text-purple-600" />
                </div>
                <div>
                  <p className="text-sm text-gray-500">Read Rate</p>
                  <p className="text-xl font-bold text-gray-900">{stats.readRate}%</p>
                </div>
              </div>
            </div>
            <div className="rounded-xl bg-white p-4 shadow-sm">
              <div className="flex items-center gap-3">
                <div className="rounded-lg bg-yellow-100 p-2">
                  <ChatBubbleLeftRightIcon className="h-5 w-5 text-yellow-600" />
                </div>
                <div>
                  <p className="text-sm text-gray-500">Unread</p>
                  <p className="text-xl font-bold text-gray-900">{stats.unreadMessages.toLocaleString()}</p>
                </div>
              </div>
            </div>
          </div>
        )}

        {/* Search */}
        <div className="flex flex-col gap-4 sm:flex-row sm:items-center">
          <div className="relative flex-1">
            <MagnifyingGlassIcon className="absolute left-3 top-1/2 h-5 w-5 -translate-y-1/2 text-gray-400" />
            <input
              type="text"
              value={search}
              onChange={(e) => {
                setSearch(e.target.value);
                setPage(1);
              }}
              placeholder="Search by plant, owner, or consumer name..."
              className="w-full rounded-lg border border-gray-300 py-2 pl-10 pr-4 text-gray-900 focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
            />
          </div>
        </div>

        {/* Conversations List */}
        <div className="rounded-xl bg-white shadow-sm">
          {isLoading ? (
            <div className="p-8 text-center text-gray-500">Loading...</div>
          ) : error ? (
            <div className="p-8 text-center text-red-500">Failed to load conversations</div>
          ) : !data?.conversations.length ? (
            <div className="p-8 text-center text-gray-500">No conversations found.</div>
          ) : (
            <>
              <div className="overflow-x-auto">
                <table className="w-full">
                  <thead className="border-b border-gray-200 bg-gray-50">
                    <tr>
                      <th className="px-6 py-3 text-left text-xs font-medium uppercase text-gray-500">Plant</th>
                      <th className="px-6 py-3 text-left text-xs font-medium uppercase text-gray-500">Owner</th>
                      <th className="px-6 py-3 text-left text-xs font-medium uppercase text-gray-500">Consumer</th>
                      <th className="px-6 py-3 text-left text-xs font-medium uppercase text-gray-500">Messages</th>
                      <th className="px-6 py-3 text-left text-xs font-medium uppercase text-gray-500">Last Message</th>
                      <th className="px-6 py-3 text-left text-xs font-medium uppercase text-gray-500">Unread</th>
                      <th className="px-6 py-3 text-left text-xs font-medium uppercase text-gray-500">Last Activity</th>
                      <th className="px-6 py-3 text-left text-xs font-medium uppercase text-gray-500">Actions</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-gray-200">
                    {data.conversations.map((conv) => (
                      <tr key={conv.id} className="hover:bg-gray-50">
                        <td className="px-6 py-4">
                          <div className="text-sm font-medium text-gray-900">{conv.plant.name}</div>
                          <div className="max-w-xs truncate text-xs text-gray-500" title={conv.plant.address}>
                            {conv.plant.address}
                          </div>
                        </td>
                        <td className="px-6 py-4">
                          <div className="text-sm text-gray-900">{conv.owner.name}</div>
                          <div className="text-xs text-gray-500">{conv.owner.email}</div>
                        </td>
                        <td className="px-6 py-4">
                          <div className="text-sm text-gray-900">{conv.consumer.displayName}</div>
                          <div className="text-xs text-gray-500">{conv.consumer.email}</div>
                        </td>
                        <td className="px-6 py-4 text-sm text-gray-900">
                          {conv.messageCount}
                        </td>
                        <td className="max-w-xs px-6 py-4">
                          {conv.lastMessage ? (
                            <div>
                              <span className={`text-xs font-medium ${
                                conv.lastMessage.senderType === 'consumer' ? 'text-teal-600' : 'text-indigo-600'
                              }`}>
                                {conv.lastMessage.senderType === 'consumer' ? 'Consumer' : 'Owner'}:
                              </span>
                              <div className="text-sm text-gray-600">
                                {truncateMessage(conv.lastMessage.content)}
                              </div>
                              <div className="mt-1 flex items-center gap-2 text-xs text-gray-400">
                                {conv.lastMessage.readAt ? (
                                  <span className="text-blue-500">Read</span>
                                ) : conv.lastMessage.deliveredAt ? (
                                  <span className="text-gray-500">Delivered</span>
                                ) : (
                                  <span className="text-gray-400">Sent</span>
                                )}
                              </div>
                            </div>
                          ) : (
                            <span className="text-sm text-gray-400">No messages</span>
                          )}
                        </td>
                        <td className="px-6 py-4">
                          <div className="flex flex-col gap-1">
                            {conv.unreadFromConsumer > 0 && (
                              <span className="inline-flex items-center rounded-full bg-teal-100 px-2 py-0.5 text-xs font-medium text-teal-800">
                                {conv.unreadFromConsumer} from consumer
                              </span>
                            )}
                            {conv.unreadFromOwner > 0 && (
                              <span className="inline-flex items-center rounded-full bg-indigo-100 px-2 py-0.5 text-xs font-medium text-indigo-800">
                                {conv.unreadFromOwner} from owner
                              </span>
                            )}
                            {conv.unreadFromConsumer === 0 && conv.unreadFromOwner === 0 && (
                              <span className="text-sm text-gray-400">-</span>
                            )}
                          </div>
                        </td>
                        <td className="whitespace-nowrap px-6 py-4 text-sm text-gray-500">
                          {formatDate(conv.lastMessageAt)}
                        </td>
                        <td className="px-6 py-4 text-sm">
                          <Link
                            href={`/chats/${conv.id}`}
                            className="text-blue-600 hover:text-blue-800"
                          >
                            View
                          </Link>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>

              {/* Pagination */}
              {data.meta.totalPages > 1 && (
                <div className="flex items-center justify-between border-t border-gray-200 px-6 py-4">
                  <div className="text-sm text-gray-500">
                    Page {data.meta.page} of {data.meta.totalPages}
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
                      onClick={() => setPage((p) => Math.min(data.meta.totalPages, p + 1))}
                      disabled={page === data.meta.totalPages}
                      className="flex items-center gap-1 rounded-lg border border-gray-300 px-3 py-1.5 text-sm font-medium text-gray-700 hover:bg-gray-50 disabled:cursor-not-allowed disabled:opacity-50"
                    >
                      Next
                      <ChevronRightIcon className="h-4 w-4" />
                    </button>
                  </div>
                </div>
              )}
            </>
          )}
        </div>
      </div>
    </DashboardLayout>
  );
}
