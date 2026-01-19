'use client';

import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { DashboardLayout } from '@/components/layout/DashboardLayout';
import { MagnifyingGlassIcon, ChevronLeftIcon, ChevronRightIcon } from '@heroicons/react/24/outline';
import { apiClient } from '@/lib/api';

interface Plant {
  id: string;
  name: string;
  address: string;
  operatingHours: string | null;
  tdsReading: number | null;
  pricePerLiter: number | null;
  verificationStatus: string;
  isOpen: boolean;
  viewCount: number;
  createdAt: string;
  owner: {
    id: string;
    name: string;
    phone: string;
    email: string | null;
  };
}

interface PlantsResponse {
  data: Plant[];
  meta: {
    page: number;
    limit: number;
    total: number;
    totalPages: number;
  };
}

export default function PlantsPage() {
  const [search, setSearch] = useState('');
  const [page, setPage] = useState(1);
  const [statusFilter, setStatusFilter] = useState('');
  const [verifiedFilter, setVerifiedFilter] = useState('');

  const { data, isLoading, error } = useQuery({
    queryKey: ['admin-plants', page, search, statusFilter, verifiedFilter],
    queryFn: async () => {
      const params = new URLSearchParams();
      params.set('page', String(page));
      params.set('limit', '20');
      if (search) params.set('search', search);
      if (statusFilter) params.set('status', statusFilter);
      if (verifiedFilter) params.set('verified', verifiedFilter);

      const response = await apiClient.get<PlantsResponse>(`/admin/plants?${params.toString()}`);
      if (response.success && response.data) {
        return response.data;
      }
      throw new Error('Failed to fetch plants');
    },
  });

  const getStatusBadge = (status: string, isOpen: boolean) => {
    if (status === 'verified') {
      return (
        <span className="inline-flex rounded-full bg-green-100 px-2 py-1 text-xs font-medium text-green-800">
          Verified
        </span>
      );
    }
    if (status === 'pending') {
      return (
        <span className="inline-flex rounded-full bg-yellow-100 px-2 py-1 text-xs font-medium text-yellow-800">
          Pending
        </span>
      );
    }
    if (status === 'rejected') {
      return (
        <span className="inline-flex rounded-full bg-red-100 px-2 py-1 text-xs font-medium text-red-800">
          Rejected
        </span>
      );
    }
    return (
      <span className="inline-flex rounded-full bg-gray-100 px-2 py-1 text-xs font-medium text-gray-800">
        Unverified
      </span>
    );
  };

  return (
    <DashboardLayout>
      <div className="space-y-6">
        <div className="flex items-center justify-between">
          <h1 className="text-2xl font-bold text-gray-900">Plants</h1>
          <div className="text-sm text-gray-500">
            {data?.meta.total || 0} total plants
          </div>
        </div>

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
              placeholder="Search plants by name or address..."
              className="w-full rounded-lg border border-gray-300 py-2 pl-10 pr-4 text-gray-900 focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
            />
          </div>
          <select
            value={statusFilter}
            onChange={(e) => {
              setStatusFilter(e.target.value);
              setPage(1);
            }}
            className="rounded-lg border border-gray-300 px-3 py-2 text-sm text-gray-900 focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
          >
            <option value="">All Status</option>
            <option value="open">Open</option>
            <option value="closed">Closed</option>
          </select>
          <select
            value={verifiedFilter}
            onChange={(e) => {
              setVerifiedFilter(e.target.value);
              setPage(1);
            }}
            className="rounded-lg border border-gray-300 px-3 py-2 text-sm text-gray-900 focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
          >
            <option value="">All Verification</option>
            <option value="verified">Verified</option>
            <option value="pending">Pending</option>
            <option value="unverified">Unverified</option>
          </select>
        </div>

        <div className="rounded-xl bg-white shadow-sm">
          {isLoading ? (
            <div className="p-8 text-center text-gray-500">Loading...</div>
          ) : error ? (
            <div className="p-8 text-center text-red-500">Failed to load plants</div>
          ) : !data?.data.length ? (
            <div className="p-8 text-center text-gray-500">No plants found.</div>
          ) : (
            <>
              <div className="overflow-x-auto">
                <table className="w-full">
                  <thead className="border-b border-gray-200 bg-gray-50">
                    <tr>
                      <th className="px-6 py-3 text-left text-xs font-medium uppercase text-gray-500">Name</th>
                      <th className="px-6 py-3 text-left text-xs font-medium uppercase text-gray-500">Address</th>
                      <th className="px-6 py-3 text-left text-xs font-medium uppercase text-gray-500">Owner</th>
                      <th className="px-6 py-3 text-left text-xs font-medium uppercase text-gray-500">TDS</th>
                      <th className="px-6 py-3 text-left text-xs font-medium uppercase text-gray-500">Price</th>
                      <th className="px-6 py-3 text-left text-xs font-medium uppercase text-gray-500">Views</th>
                      <th className="px-6 py-3 text-left text-xs font-medium uppercase text-gray-500">Status</th>
                      <th className="px-6 py-3 text-left text-xs font-medium uppercase text-gray-500">Open</th>
                      <th className="px-6 py-3 text-left text-xs font-medium uppercase text-gray-500">Actions</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-gray-200">
                    {data.data.map((plant) => (
                      <tr key={plant.id} className="hover:bg-gray-50">
                        <td className="px-6 py-4 text-sm font-medium text-gray-900">{plant.name}</td>
                        <td className="max-w-xs truncate px-6 py-4 text-sm text-gray-500" title={plant.address}>
                          {plant.address}
                        </td>
                        <td className="px-6 py-4 text-sm text-gray-500">
                          <div>{plant.owner.name}</div>
                          <div className="text-xs text-gray-400">{plant.owner.phone}</div>
                        </td>
                        <td className="px-6 py-4 text-sm text-gray-500">
                          {plant.tdsReading ? `${plant.tdsReading} ppm` : '-'}
                        </td>
                        <td className="px-6 py-4 text-sm text-gray-500">
                          {plant.pricePerLiter ? `Rs. ${plant.pricePerLiter}/L` : '-'}
                        </td>
                        <td className="px-6 py-4 text-sm text-gray-500">{plant.viewCount}</td>
                        <td className="px-6 py-4">
                          {getStatusBadge(plant.verificationStatus, plant.isOpen)}
                        </td>
                        <td className="px-6 py-4">
                          <span
                            className={`inline-flex rounded-full px-2 py-1 text-xs font-medium ${
                              plant.isOpen
                                ? 'bg-green-100 text-green-800'
                                : 'bg-gray-100 text-gray-800'
                            }`}
                          >
                            {plant.isOpen ? 'Open' : 'Closed'}
                          </span>
                        </td>
                        <td className="px-6 py-4 text-sm">
                          <button
                            onClick={() => window.location.href = `/plants/${plant.id}`}
                            className="text-blue-600 hover:text-blue-800"
                          >
                            View
                          </button>
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
