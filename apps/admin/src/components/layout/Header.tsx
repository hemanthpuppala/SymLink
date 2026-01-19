'use client';

import { useEffect, useState } from 'react';
import { BellIcon, UserCircleIcon } from '@heroicons/react/24/outline';
import { getCurrentAdmin, type Admin } from '@/lib/auth';

export function Header() {
  const [admin, setAdmin] = useState<Admin | null>(null);

  useEffect(() => {
    setAdmin(getCurrentAdmin());
  }, []);

  return (
    <header className="flex h-16 items-center justify-between border-b border-gray-200 bg-white px-6">
      <div className="flex items-center gap-4">
        <h2 className="text-lg font-semibold text-gray-900">
          Welcome back{admin ? `, ${admin.name}` : ''}
        </h2>
      </div>

      <div className="flex items-center gap-4">
        <button className="relative rounded-full p-2 text-gray-500 hover:bg-gray-100 hover:text-gray-700">
          <BellIcon className="h-6 w-6" />
          <span className="absolute right-1 top-1 h-2 w-2 rounded-full bg-red-500" />
        </button>

        <div className="flex items-center gap-2">
          <UserCircleIcon className="h-8 w-8 text-gray-400" />
          <div className="text-sm">
            <p className="font-medium text-gray-900">{admin?.name || 'Admin'}</p>
            <p className="text-gray-500">{admin?.role || 'Role'}</p>
          </div>
        </div>
      </div>
    </header>
  );
}
