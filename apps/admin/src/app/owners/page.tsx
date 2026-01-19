'use client';

import { useState, useEffect } from 'react';
import { DashboardLayout } from '@/components/layout/DashboardLayout';
import { MagnifyingGlassIcon } from '@heroicons/react/24/outline';
import { apiClient } from '@/lib/api';

interface Owner {
  id: string;
  name: string;
  email: string;
  phone: string;
  _count: {
    plants: number;
  };
  createdAt: string;
}

export default function OwnersPage() {
  const [owners, setOwners] = useState<Owner[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');

  useEffect(() => {
    loadOwners();
  }, []);

  const loadOwners = async () => {
    try {
      const response = await apiClient.get<Owner[]>('/admin/owners');
      if (response.success && response.data) {
        setOwners(response.data);
      }
    } catch (error) {
      console.error('Failed to load owners:', error);
    } finally {
      setLoading(false);
    }
  };

  const filteredOwners = owners.filter(
    (owner) =>
      owner.name.toLowerCase().includes(search.toLowerCase()) ||
      owner.email.toLowerCase().includes(search.toLowerCase())
  );

  return (
    <DashboardLayout>
      <div className="space-y-6">
        <h1 className="text-2xl font-bold text-gray-900">Owners</h1>

        <div className="relative">
          <MagnifyingGlassIcon className="absolute left-3 top-1/2 h-5 w-5 -translate-y-1/2 text-gray-400" />
          <input
            type="text"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Search owners..."
            className="w-full rounded-lg border border-gray-300 py-2 pl-10 pr-4 text-gray-900 focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
          />
        </div>

        <div className="rounded-xl bg-white shadow-sm">
          {loading ? (
            <div className="p-8 text-center text-gray-500">Loading...</div>
          ) : filteredOwners.length === 0 ? (
            <div className="p-8 text-center text-gray-500">No owners found.</div>
          ) : (
            <table className="w-full">
              <thead className="border-b border-gray-200 bg-gray-50">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium uppercase text-gray-500">Name</th>
                  <th className="px-6 py-3 text-left text-xs font-medium uppercase text-gray-500">Email</th>
                  <th className="px-6 py-3 text-left text-xs font-medium uppercase text-gray-500">Phone</th>
                  <th className="px-6 py-3 text-left text-xs font-medium uppercase text-gray-500">Plants</th>
                  <th className="px-6 py-3 text-left text-xs font-medium uppercase text-gray-500">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-200">
                {filteredOwners.map((owner) => (
                  <tr key={owner.id}>
                    <td className="px-6 py-4 text-sm font-medium text-gray-900">{owner.name}</td>
                    <td className="px-6 py-4 text-sm text-gray-500">{owner.email}</td>
                    <td className="px-6 py-4 text-sm text-gray-500">{owner.phone}</td>
                    <td className="px-6 py-4 text-sm text-gray-500">{owner._count.plants}</td>
                    <td className="px-6 py-4 text-sm">
                      <button className="text-blue-600 hover:text-blue-800">View</button>
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
