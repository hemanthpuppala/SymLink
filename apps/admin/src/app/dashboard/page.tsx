'use client';

import { useQuery } from '@tanstack/react-query';
import { DashboardLayout } from '@/components/layout/DashboardLayout';
import {
  BuildingOffice2Icon,
  UserGroupIcon,
  ShieldCheckIcon,
  UsersIcon,
  ChatBubbleLeftRightIcon,
  EnvelopeIcon,
} from '@heroicons/react/24/outline';
import { apiClient } from '@/lib/api';
import Link from 'next/link';

interface DashboardStats {
  totalPlants: number;
  verifiedPlants: number;
  unverifiedPlants: number;
  totalOwners: number;
  totalConsumers: number;
  pendingVerifications: number;
  chat: {
    totalConversations: number;
    totalMessages: number;
    messagesLast24h: number;
    unreadMessages: number;
  };
}

export default function DashboardPage() {
  const { data: stats, isLoading, error } = useQuery({
    queryKey: ['dashboard-stats'],
    queryFn: async () => {
      const response = await apiClient.get<DashboardStats>('/admin/dashboard/stats');
      if (response.success && response.data) {
        return response.data;
      }
      throw new Error('Failed to fetch stats');
    },
    refetchInterval: 30000, // Refresh every 30 seconds
  });

  const mainStats = [
    {
      name: 'Total Plants',
      value: stats?.totalPlants || 0,
      subtext: `${stats?.verifiedPlants || 0} verified`,
      icon: BuildingOffice2Icon,
      color: 'bg-blue-500',
      href: '/plants',
    },
    {
      name: 'Total Owners',
      value: stats?.totalOwners || 0,
      icon: UserGroupIcon,
      color: 'bg-green-500',
      href: '/owners',
    },
    {
      name: 'Pending Verifications',
      value: stats?.pendingVerifications || 0,
      icon: ShieldCheckIcon,
      color: 'bg-yellow-500',
      href: '/verification',
    },
    {
      name: 'Total Consumers',
      value: stats?.totalConsumers || 0,
      icon: UsersIcon,
      color: 'bg-purple-500',
    },
  ];

  const chatStats = [
    {
      name: 'Conversations',
      value: stats?.chat?.totalConversations || 0,
      icon: ChatBubbleLeftRightIcon,
      color: 'bg-teal-500',
    },
    {
      name: 'Total Messages',
      value: stats?.chat?.totalMessages || 0,
      icon: EnvelopeIcon,
      color: 'bg-indigo-500',
    },
    {
      name: 'Messages (24h)',
      value: stats?.chat?.messagesLast24h || 0,
      icon: EnvelopeIcon,
      color: 'bg-cyan-500',
    },
    {
      name: 'Unread Messages',
      value: stats?.chat?.unreadMessages || 0,
      icon: EnvelopeIcon,
      color: 'bg-orange-500',
    },
  ];

  return (
    <DashboardLayout>
      <div className="space-y-6">
        <h1 className="text-2xl font-bold text-gray-900">Dashboard</h1>

        {isLoading ? (
          <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-4">
            {[...Array(4)].map((_, i) => (
              <div key={i} className="animate-pulse rounded-xl bg-white p-6 shadow-sm">
                <div className="flex items-center gap-4">
                  <div className="h-12 w-12 rounded-lg bg-gray-200" />
                  <div className="flex-1">
                    <div className="h-4 w-24 rounded bg-gray-200" />
                    <div className="mt-2 h-6 w-16 rounded bg-gray-200" />
                  </div>
                </div>
              </div>
            ))}
          </div>
        ) : error ? (
          <div className="rounded-xl bg-red-50 p-6 text-red-600">
            Failed to load dashboard statistics
          </div>
        ) : (
          <>
            {/* Main Stats */}
            <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-4">
              {mainStats.map((stat) => (
                <Link
                  key={stat.name}
                  href={stat.href || '#'}
                  className={`rounded-xl bg-white p-6 shadow-sm transition-shadow hover:shadow-md ${
                    stat.href ? 'cursor-pointer' : 'cursor-default'
                  }`}
                >
                  <div className="flex items-center gap-4">
                    <div className={`rounded-lg ${stat.color} p-3`}>
                      <stat.icon className="h-6 w-6 text-white" />
                    </div>
                    <div>
                      <p className="text-sm text-gray-500">{stat.name}</p>
                      <p className="text-2xl font-bold text-gray-900">
                        {stat.value.toLocaleString()}
                      </p>
                      {stat.subtext && (
                        <p className="text-xs text-gray-400">{stat.subtext}</p>
                      )}
                    </div>
                  </div>
                </Link>
              ))}
            </div>

            {/* Chat Stats */}
            <div>
              <div className="mb-4 flex items-center justify-between">
                <h2 className="text-lg font-semibold text-gray-900">Chat Activity</h2>
                <Link href="/chats" className="text-sm text-blue-600 hover:text-blue-800">
                  View all chats
                </Link>
              </div>
              <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-4">
                {chatStats.map((stat) => (
                  <div
                    key={stat.name}
                    className="rounded-xl bg-white p-6 shadow-sm"
                  >
                    <div className="flex items-center gap-4">
                      <div className={`rounded-lg ${stat.color} p-3`}>
                        <stat.icon className="h-6 w-6 text-white" />
                      </div>
                      <div>
                        <p className="text-sm text-gray-500">{stat.name}</p>
                        <p className="text-2xl font-bold text-gray-900">
                          {stat.value.toLocaleString()}
                        </p>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </>
        )}

        <div className="grid gap-6 lg:grid-cols-2">
          <div className="rounded-xl bg-white p-6 shadow-sm">
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-lg font-semibold text-gray-900">Recent Plants</h2>
              <Link href="/plants" className="text-sm text-blue-600 hover:text-blue-800">
                View all
              </Link>
            </div>
            {stats?.totalPlants === 0 ? (
              <p className="text-gray-500">No plants registered yet.</p>
            ) : (
              <p className="text-gray-500">
                {stats?.totalPlants} plants registered, {stats?.verifiedPlants} verified.
              </p>
            )}
          </div>

          <div className="rounded-xl bg-white p-6 shadow-sm">
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-lg font-semibold text-gray-900">Pending Verifications</h2>
              <Link href="/verification" className="text-sm text-blue-600 hover:text-blue-800">
                View all
              </Link>
            </div>
            {stats?.pendingVerifications === 0 ? (
              <p className="text-gray-500">No pending verification requests.</p>
            ) : (
              <p className="text-amber-600 font-medium">
                {stats?.pendingVerifications} verification request(s) pending review.
              </p>
            )}
          </div>
        </div>
      </div>
    </DashboardLayout>
  );
}
