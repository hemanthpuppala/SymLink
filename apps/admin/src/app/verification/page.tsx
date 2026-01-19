'use client';

import { useState, useEffect, useCallback, useRef } from 'react';
import { DashboardLayout } from '@/components/layout/DashboardLayout';
import { CheckIcon, XMarkIcon, EyeIcon, ArrowPathIcon } from '@heroicons/react/24/outline';
import { apiClient } from '@/lib/api';
import { io, Socket } from 'socket.io-client';

interface VerificationRequest {
  id: string;
  status: 'PENDING' | 'APPROVED' | 'REJECTED';
  documents: string[];
  notes: string | null;
  plant: {
    id: string;
    name: string;
    address: string;
    owner: {
      id: string;
      name: string;
      email: string;
    };
  };
  createdAt: string;
}

// Derive WebSocket URL from API base URL (remove /v1 suffix)
const API_BASE = process.env.NEXT_PUBLIC_API_URL || 'http://10.0.0.17:3000/v1';
const API_URL = API_BASE.replace('/v1', '');

export default function VerificationPage() {
  const [requests, setRequests] = useState<VerificationRequest[]>([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState<'all' | 'PENDING' | 'APPROVED' | 'REJECTED'>('PENDING');
  const [isConnected, setIsConnected] = useState(false);
  const socketRef = useRef<Socket | null>(null);

  const loadRequests = useCallback(async () => {
    try {
      const response = await apiClient.get<{ requests: VerificationRequest[]; meta: any }>('/admin/verification-requests');
      if (response.success && response.data) {
        setRequests(response.data.requests || []);
      }
    } catch (error) {
      console.error('Failed to load verification requests:', error);
    } finally {
      setLoading(false);
    }
  }, []);

  // Setup WebSocket connection for real-time updates
  useEffect(() => {
    const token = localStorage.getItem('accessToken');
    if (!token) return;

    const socket = io(`${API_URL}/sync`, {
      auth: { token },
      transports: ['websocket'],
      reconnection: true,
      reconnectionDelay: 1000,
    });

    socketRef.current = socket;

    socket.on('connect', () => {
      console.log('[Admin] Connected to sync server');
      setIsConnected(true);
    });

    socket.on('disconnect', () => {
      console.log('[Admin] Disconnected from sync server');
      setIsConnected(false);
    });

    // Listen for verification events
    socket.on('verification:created', () => {
      console.log('[Admin] New verification request');
      loadRequests();
    });

    socket.on('verification:updated', () => {
      console.log('[Admin] Verification updated');
      loadRequests();
    });

    return () => {
      socket.disconnect();
    };
  }, [loadRequests]);

  // Initial load
  useEffect(() => {
    loadRequests();
  }, [loadRequests]);

  const handleApprove = async (id: string) => {
    try {
      await apiClient.patch(`/admin/verification-requests/${id}`, { status: 'APPROVED' });
      loadRequests();
    } catch (error) {
      console.error('Failed to approve request:', error);
    }
  };

  const handleReject = async (id: string) => {
    try {
      await apiClient.patch(`/admin/verification-requests/${id}`, { status: 'REJECTED' });
      loadRequests();
    } catch (error) {
      console.error('Failed to reject request:', error);
    }
  };

  const filteredRequests = requests.filter(
    (request) => filter === 'all' || request.status === filter
  );

  const getStatusBadge = (status: string) => {
    switch (status) {
      case 'PENDING':
        return 'bg-yellow-100 text-yellow-800';
      case 'APPROVED':
        return 'bg-green-100 text-green-800';
      case 'REJECTED':
        return 'bg-red-100 text-red-800';
      default:
        return 'bg-gray-100 text-gray-800';
    }
  };

  return (
    <DashboardLayout>
      <div className="space-y-6">
        <div className="flex items-center justify-between">
          <h1 className="text-2xl font-bold text-gray-900">Verification Requests</h1>
          <div className="flex items-center gap-4">
            <div className="flex items-center gap-2">
              <span className={`h-2 w-2 rounded-full ${isConnected ? 'bg-green-500' : 'bg-red-500'}`} />
              <span className="text-sm text-gray-500">
                {isConnected ? 'Live updates' : 'Offline'}
              </span>
            </div>
            <button
              onClick={() => loadRequests()}
              className="flex items-center gap-2 rounded-lg bg-gray-100 px-3 py-2 text-sm font-medium text-gray-700 hover:bg-gray-200"
            >
              <ArrowPathIcon className="h-4 w-4" />
              Refresh
            </button>
          </div>
        </div>

        <div className="flex gap-2">
          {(['all', 'PENDING', 'APPROVED', 'REJECTED'] as const).map((status) => (
            <button
              key={status}
              onClick={() => setFilter(status)}
              className={`rounded-lg px-4 py-2 text-sm font-medium ${
                filter === status
                  ? 'bg-blue-600 text-white'
                  : 'bg-white text-gray-700 hover:bg-gray-50'
              }`}
            >
              {status === 'all' ? 'All' : status.charAt(0) + status.slice(1).toLowerCase()}
            </button>
          ))}
        </div>

        <div className="rounded-xl bg-white shadow-sm">
          {loading ? (
            <div className="p-8 text-center text-gray-500">Loading...</div>
          ) : filteredRequests.length === 0 ? (
            <div className="p-8 text-center text-gray-500">No verification requests found.</div>
          ) : (
            <table className="w-full">
              <thead className="border-b border-gray-200 bg-gray-50">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium uppercase text-gray-500">Plant</th>
                  <th className="px-6 py-3 text-left text-xs font-medium uppercase text-gray-500">Owner</th>
                  <th className="px-6 py-3 text-left text-xs font-medium uppercase text-gray-500">Documents</th>
                  <th className="px-6 py-3 text-left text-xs font-medium uppercase text-gray-500">Status</th>
                  <th className="px-6 py-3 text-left text-xs font-medium uppercase text-gray-500">Date</th>
                  <th className="px-6 py-3 text-left text-xs font-medium uppercase text-gray-500">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-200">
                {filteredRequests.map((request) => (
                  <tr key={request.id}>
                    <td className="px-6 py-4">
                      <div className="text-sm font-medium text-gray-900">{request.plant.name}</div>
                      <div className="text-sm text-gray-500">{request.plant.address}</div>
                    </td>
                    <td className="px-6 py-4 text-sm text-gray-500">{request.plant.owner.name}</td>
                    <td className="px-6 py-4 text-sm text-gray-500">{request.documents.length} files</td>
                    <td className="px-6 py-4">
                      <span
                        className={`inline-flex rounded-full px-2 py-1 text-xs font-medium ${getStatusBadge(request.status)}`}
                      >
                        {request.status}
                      </span>
                    </td>
                    <td className="px-6 py-4 text-sm text-gray-500">
                      {new Date(request.createdAt).toLocaleDateString()}
                    </td>
                    <td className="px-6 py-4">
                      <div className="flex items-center gap-2">
                        <button className="rounded p-1 text-gray-500 hover:bg-gray-100 hover:text-gray-700">
                          <EyeIcon className="h-5 w-5" />
                        </button>
                        {request.status === 'PENDING' && (
                          <>
                            <button
                              onClick={() => handleApprove(request.id)}
                              className="rounded p-1 text-green-600 hover:bg-green-50"
                            >
                              <CheckIcon className="h-5 w-5" />
                            </button>
                            <button
                              onClick={() => handleReject(request.id)}
                              className="rounded p-1 text-red-600 hover:bg-red-50"
                            >
                              <XMarkIcon className="h-5 w-5" />
                            </button>
                          </>
                        )}
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>
      </div>
    </DashboardLayout>
  );
}
