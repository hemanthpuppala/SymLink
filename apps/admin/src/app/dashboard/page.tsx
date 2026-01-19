'use client';

import { DashboardLayout } from '@/components/layout/DashboardLayout';
import {
  BuildingOffice2Icon,
  UserGroupIcon,
  ShieldCheckIcon,
  ChartBarIcon
} from '@heroicons/react/24/outline';

const stats = [
  { name: 'Total Plants', value: '0', icon: BuildingOffice2Icon, color: 'bg-blue-500' },
  { name: 'Total Owners', value: '0', icon: UserGroupIcon, color: 'bg-green-500' },
  { name: 'Pending Verifications', value: '0', icon: ShieldCheckIcon, color: 'bg-yellow-500' },
  { name: 'Total Consumers', value: '0', icon: ChartBarIcon, color: 'bg-purple-500' },
];

export default function DashboardPage() {
  return (
    <DashboardLayout>
      <div className="space-y-6">
        <h1 className="text-2xl font-bold text-gray-900">Dashboard</h1>

        <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-4">
          {stats.map((stat) => (
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
                  <p className="text-2xl font-bold text-gray-900">{stat.value}</p>
                </div>
              </div>
            </div>
          ))}
        </div>

        <div className="grid gap-6 lg:grid-cols-2">
          <div className="rounded-xl bg-white p-6 shadow-sm">
            <h2 className="text-lg font-semibold text-gray-900">Recent Plants</h2>
            <p className="mt-4 text-gray-500">No plants registered yet.</p>
          </div>

          <div className="rounded-xl bg-white p-6 shadow-sm">
            <h2 className="text-lg font-semibold text-gray-900">Pending Verifications</h2>
            <p className="mt-4 text-gray-500">No pending verification requests.</p>
          </div>
        </div>
      </div>
    </DashboardLayout>
  );
}
