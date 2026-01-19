'use client';

import { useParams, useRouter } from 'next/navigation';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { DashboardLayout } from '@/components/layout/DashboardLayout';
import { ArrowLeftIcon, MapPinIcon, PhoneIcon, EnvelopeIcon, ClockIcon } from '@heroicons/react/24/outline';
import { apiClient } from '@/lib/api';

interface PlantDetails {
  id: string;
  name: string;
  address: string;
  operatingHours: string | null;
  tdsReading: number | null;
  pricePerLiter: number | null;
  description: string | null;
  photos: string[];
  verificationStatus: string;
  isOpen: boolean;
  viewCount: number;
  createdAt: string;
  updatedAt: string;
  owner: {
    id: string;
    name: string;
    phone: string;
    email: string | null;
    createdAt: string;
  };
  verificationRequest: {
    id: string;
    status: string;
    submittedAt: string;
    decidedAt: string | null;
    rejectionReason: string | null;
  } | null;
  conversationCount: number;
  analytics: {
    totalViews: number;
    weeklyViews: number;
  };
}

export default function PlantDetailPage() {
  const params = useParams();
  const router = useRouter();
  const queryClient = useQueryClient();
  const plantId = params.id as string;

  const { data: plant, isLoading, error } = useQuery({
    queryKey: ['admin-plant', plantId],
    queryFn: async () => {
      const response = await apiClient.get<PlantDetails>(`/admin/plants/${plantId}`);
      if (response.success && response.data) {
        return response.data;
      }
      throw new Error('Failed to fetch plant details');
    },
  });

  const toggleOpenMutation = useMutation({
    mutationFn: async (isActive: boolean) => {
      const response = await apiClient.patch(`/admin/plants/${plantId}`, { isActive });
      if (!response.success) {
        throw new Error('Failed to update plant');
      }
      return response.data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin-plant', plantId] });
    },
  });

  const getStatusBadge = (status: string) => {
    switch (status) {
      case 'verified':
        return <span className="inline-flex rounded-full bg-green-100 px-3 py-1 text-sm font-medium text-green-800">Verified</span>;
      case 'pending':
        return <span className="inline-flex rounded-full bg-yellow-100 px-3 py-1 text-sm font-medium text-yellow-800">Pending</span>;
      case 'rejected':
        return <span className="inline-flex rounded-full bg-red-100 px-3 py-1 text-sm font-medium text-red-800">Rejected</span>;
      default:
        return <span className="inline-flex rounded-full bg-gray-100 px-3 py-1 text-sm font-medium text-gray-800">Unverified</span>;
    }
  };

  if (isLoading) {
    return (
      <DashboardLayout>
        <div className="flex h-64 items-center justify-center">
          <div className="text-gray-500">Loading...</div>
        </div>
      </DashboardLayout>
    );
  }

  if (error || !plant) {
    return (
      <DashboardLayout>
        <div className="flex h-64 items-center justify-center">
          <div className="text-red-500">Failed to load plant details</div>
        </div>
      </DashboardLayout>
    );
  }

  return (
    <DashboardLayout>
      <div className="space-y-6">
        {/* Header */}
        <div className="flex items-center gap-4">
          <button
            onClick={() => router.push('/plants')}
            className="rounded-lg border border-gray-300 p-2 hover:bg-gray-50"
          >
            <ArrowLeftIcon className="h-5 w-5 text-gray-600" />
          </button>
          <div className="flex-1">
            <h1 className="text-2xl font-bold text-gray-900">{plant.name}</h1>
            <p className="text-sm text-gray-500">Plant ID: {plant.id}</p>
          </div>
          <div className="flex items-center gap-3">
            {getStatusBadge(plant.verificationStatus)}
            <button
              onClick={() => toggleOpenMutation.mutate(!plant.isOpen)}
              disabled={toggleOpenMutation.isPending}
              className={`rounded-lg px-4 py-2 text-sm font-medium ${
                plant.isOpen
                  ? 'bg-red-100 text-red-700 hover:bg-red-200'
                  : 'bg-green-100 text-green-700 hover:bg-green-200'
              }`}
            >
              {toggleOpenMutation.isPending ? 'Updating...' : plant.isOpen ? 'Mark Closed' : 'Mark Open'}
            </button>
          </div>
        </div>

        <div className="grid gap-6 lg:grid-cols-3">
          {/* Main Info */}
          <div className="lg:col-span-2 space-y-6">
            {/* Basic Info Card */}
            <div className="rounded-xl bg-white p-6 shadow-sm">
              <h2 className="mb-4 text-lg font-semibold text-gray-900">Plant Information</h2>
              <div className="grid gap-4 sm:grid-cols-2">
                <div className="flex items-start gap-3">
                  <MapPinIcon className="h-5 w-5 text-gray-400" />
                  <div>
                    <p className="text-sm font-medium text-gray-500">Address</p>
                    <p className="text-gray-900">{plant.address}</p>
                  </div>
                </div>
                {plant.operatingHours && (
                  <div className="flex items-start gap-3">
                    <ClockIcon className="h-5 w-5 text-gray-400" />
                    <div>
                      <p className="text-sm font-medium text-gray-500">Operating Hours</p>
                      <p className="text-gray-900">{plant.operatingHours}</p>
                    </div>
                  </div>
                )}
                <div>
                  <p className="text-sm font-medium text-gray-500">TDS Reading</p>
                  <p className="text-gray-900">{plant.tdsReading ? `${plant.tdsReading} ppm` : 'Not specified'}</p>
                </div>
                <div>
                  <p className="text-sm font-medium text-gray-500">Price per Liter</p>
                  <p className="text-gray-900">{plant.pricePerLiter ? `Rs. ${plant.pricePerLiter}` : 'Not specified'}</p>
                </div>
                <div>
                  <p className="text-sm font-medium text-gray-500">Status</p>
                  <p className={plant.isOpen ? 'text-green-600' : 'text-red-600'}>
                    {plant.isOpen ? 'Open' : 'Closed'}
                  </p>
                </div>
                <div>
                  <p className="text-sm font-medium text-gray-500">Listed Since</p>
                  <p className="text-gray-900">{new Date(plant.createdAt).toLocaleDateString()}</p>
                </div>
              </div>
              {plant.description && (
                <div className="mt-4">
                  <p className="text-sm font-medium text-gray-500">Description</p>
                  <p className="mt-1 text-gray-900">{plant.description}</p>
                </div>
              )}
            </div>

            {/* Photos */}
            {plant.photos.length > 0 && (
              <div className="rounded-xl bg-white p-6 shadow-sm">
                <h2 className="mb-4 text-lg font-semibold text-gray-900">Photos</h2>
                <div className="grid grid-cols-2 gap-4 sm:grid-cols-3">
                  {plant.photos.map((photo, idx) => (
                    <div key={idx} className="aspect-square overflow-hidden rounded-lg bg-gray-100">
                      <img src={photo} alt={`Plant photo ${idx + 1}`} className="h-full w-full object-cover" />
                    </div>
                  ))}
                </div>
              </div>
            )}

            {/* Verification Request */}
            {plant.verificationRequest && (
              <div className="rounded-xl bg-white p-6 shadow-sm">
                <h2 className="mb-4 text-lg font-semibold text-gray-900">Verification Request</h2>
                <div className="space-y-3">
                  <div className="flex items-center justify-between">
                    <span className="text-gray-500">Status</span>
                    {getStatusBadge(plant.verificationRequest.status)}
                  </div>
                  <div className="flex items-center justify-between">
                    <span className="text-gray-500">Submitted</span>
                    <span className="text-gray-900">
                      {new Date(plant.verificationRequest.submittedAt).toLocaleString()}
                    </span>
                  </div>
                  {plant.verificationRequest.decidedAt && (
                    <div className="flex items-center justify-between">
                      <span className="text-gray-500">Decided</span>
                      <span className="text-gray-900">
                        {new Date(plant.verificationRequest.decidedAt).toLocaleString()}
                      </span>
                    </div>
                  )}
                  {plant.verificationRequest.rejectionReason && (
                    <div>
                      <p className="text-sm font-medium text-gray-500">Rejection Reason</p>
                      <p className="mt-1 text-red-600">{plant.verificationRequest.rejectionReason}</p>
                    </div>
                  )}
                </div>
              </div>
            )}
          </div>

          {/* Sidebar */}
          <div className="space-y-6">
            {/* Owner Info */}
            <div className="rounded-xl bg-white p-6 shadow-sm">
              <h2 className="mb-4 text-lg font-semibold text-gray-900">Owner</h2>
              <div className="space-y-3">
                <p className="text-lg font-medium text-gray-900">{plant.owner.name}</p>
                <div className="flex items-center gap-2 text-gray-600">
                  <PhoneIcon className="h-4 w-4" />
                  <span>{plant.owner.phone}</span>
                </div>
                {plant.owner.email && (
                  <div className="flex items-center gap-2 text-gray-600">
                    <EnvelopeIcon className="h-4 w-4" />
                    <span>{plant.owner.email}</span>
                  </div>
                )}
                <p className="text-sm text-gray-500">
                  Member since {new Date(plant.owner.createdAt).toLocaleDateString()}
                </p>
              </div>
            </div>

            {/* Analytics */}
            <div className="rounded-xl bg-white p-6 shadow-sm">
              <h2 className="mb-4 text-lg font-semibold text-gray-900">Analytics</h2>
              <div className="grid grid-cols-2 gap-4">
                <div className="rounded-lg bg-gray-50 p-4 text-center">
                  <p className="text-2xl font-bold text-gray-900">{plant.analytics.totalViews}</p>
                  <p className="text-sm text-gray-500">Total Views</p>
                </div>
                <div className="rounded-lg bg-gray-50 p-4 text-center">
                  <p className="text-2xl font-bold text-gray-900">{plant.analytics.weeklyViews}</p>
                  <p className="text-sm text-gray-500">This Week</p>
                </div>
                <div className="rounded-lg bg-gray-50 p-4 text-center">
                  <p className="text-2xl font-bold text-gray-900">{plant.conversationCount}</p>
                  <p className="text-sm text-gray-500">Conversations</p>
                </div>
                <div className="rounded-lg bg-gray-50 p-4 text-center">
                  <p className="text-2xl font-bold text-gray-900">{plant.viewCount}</p>
                  <p className="text-sm text-gray-500">Profile Views</p>
                </div>
              </div>
            </div>

            {/* Timestamps */}
            <div className="rounded-xl bg-white p-6 shadow-sm">
              <h2 className="mb-4 text-lg font-semibold text-gray-900">Activity</h2>
              <div className="space-y-2 text-sm">
                <div className="flex justify-between">
                  <span className="text-gray-500">Created</span>
                  <span className="text-gray-900">{new Date(plant.createdAt).toLocaleString()}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-gray-500">Last Updated</span>
                  <span className="text-gray-900">{new Date(plant.updatedAt).toLocaleString()}</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </DashboardLayout>
  );
}
