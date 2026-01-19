'use client';

import { useState, useEffect } from 'react';
import { useParams, useRouter } from 'next/navigation';
import { DashboardLayout } from '@/components/layout/DashboardLayout';
import {
  ArrowLeftIcon,
  CheckIcon,
  XMarkIcon,
  DocumentIcon,
  PhotoIcon,
  ArrowDownTrayIcon,
  MagnifyingGlassPlusIcon,
  MagnifyingGlassMinusIcon,
} from '@heroicons/react/24/outline';
import { apiClient } from '@/lib/api';

interface VerificationRequest {
  id: string;
  status: 'PENDING' | 'APPROVED' | 'REJECTED';
  documents: string[];
  notes: string | null;
  rejectionReason: string | null;
  submittedAt: string;
  reviewedAt: string | null;
  plant: {
    id: string;
    name: string;
    address: string;
    phone: string | null;
    photos: string[];
    owner: {
      id: string;
      name: string;
      email: string;
      phone: string | null;
    };
  };
  createdAt: string;
}

export default function VerificationDetailPage() {
  const params = useParams();
  const router = useRouter();
  const [request, setRequest] = useState<VerificationRequest | null>(null);
  const [loading, setLoading] = useState(true);
  const [selectedDocument, setSelectedDocument] = useState<string | null>(null);
  const [rejectionReason, setRejectionReason] = useState('');
  const [showRejectModal, setShowRejectModal] = useState(false);
  const [actionLoading, setActionLoading] = useState(false);
  const [zoomLevel, setZoomLevel] = useState(1);

  useEffect(() => {
    loadRequest();
  }, [params.id]);

  const loadRequest = async () => {
    try {
      const response = await apiClient.get<VerificationRequest>(`/admin/verification-requests/${params.id}`);
      if (response.success && response.data) {
        setRequest(response.data);
        if (response.data.documents.length > 0) {
          setSelectedDocument(response.data.documents[0]);
        }
      }
    } catch (error) {
      console.error('Failed to load verification request:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleApprove = async () => {
    if (!request) return;
    setActionLoading(true);
    try {
      await apiClient.patch(`/admin/verification-requests/${request.id}`, { status: 'APPROVED' });
      await loadRequest();
    } catch (error) {
      console.error('Failed to approve request:', error);
    } finally {
      setActionLoading(false);
    }
  };

  const handleReject = async () => {
    if (!request) return;
    setActionLoading(true);
    try {
      await apiClient.patch(`/admin/verification-requests/${request.id}`, {
        status: 'REJECTED',
        rejectionReason: rejectionReason || 'Documents did not meet verification requirements',
      });
      setShowRejectModal(false);
      await loadRequest();
    } catch (error) {
      console.error('Failed to reject request:', error);
    } finally {
      setActionLoading(false);
    }
  };

  const getFileIcon = (url: string) => {
    const ext = url.split('.').pop()?.toLowerCase();
    if (['jpg', 'jpeg', 'png', 'gif', 'webp'].includes(ext || '')) {
      return <PhotoIcon className="h-5 w-5" />;
    }
    return <DocumentIcon className="h-5 w-5" />;
  };

  const getFileName = (url: string) => {
    return url.split('/').pop() || 'Document';
  };

  const isImage = (url: string) => {
    const ext = url.split('.').pop()?.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'webp'].includes(ext || '');
  };

  const isPdf = (url: string) => {
    return url.toLowerCase().endsWith('.pdf');
  };

  const getStatusBadge = (status: string) => {
    switch (status) {
      case 'PENDING':
        return 'bg-yellow-100 text-yellow-800 border-yellow-200';
      case 'APPROVED':
        return 'bg-green-100 text-green-800 border-green-200';
      case 'REJECTED':
        return 'bg-red-100 text-red-800 border-red-200';
      default:
        return 'bg-gray-100 text-gray-800 border-gray-200';
    }
  };

  if (loading) {
    return (
      <DashboardLayout>
        <div className="flex h-96 items-center justify-center">
          <div className="text-gray-500">Loading...</div>
        </div>
      </DashboardLayout>
    );
  }

  if (!request) {
    return (
      <DashboardLayout>
        <div className="flex h-96 items-center justify-center">
          <div className="text-gray-500">Verification request not found</div>
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
            onClick={() => router.push('/verification')}
            className="rounded-lg p-2 hover:bg-gray-100"
          >
            <ArrowLeftIcon className="h-5 w-5" />
          </button>
          <div className="flex-1">
            <h1 className="text-2xl font-bold text-gray-900">Verification Request</h1>
            <p className="text-gray-500">{request.plant.name}</p>
          </div>
          <span
            className={`rounded-full border px-3 py-1 text-sm font-medium ${getStatusBadge(request.status)}`}
          >
            {request.status}
          </span>
        </div>

        <div className="grid grid-cols-1 gap-6 lg:grid-cols-3">
          {/* Document List */}
          <div className="space-y-4">
            <div className="rounded-xl bg-white p-4 shadow-sm">
              <h2 className="mb-4 text-lg font-semibold">Documents ({request.documents.length})</h2>
              <div className="space-y-2">
                {request.documents.map((doc, index) => (
                  <button
                    key={index}
                    onClick={() => setSelectedDocument(doc)}
                    className={`flex w-full items-center gap-3 rounded-lg p-3 text-left transition-colors ${
                      selectedDocument === doc
                        ? 'bg-blue-50 text-blue-700'
                        : 'hover:bg-gray-50'
                    }`}
                  >
                    {getFileIcon(doc)}
                    <span className="flex-1 truncate text-sm">{getFileName(doc)}</span>
                  </button>
                ))}
              </div>
            </div>

            {/* Plant Info */}
            <div className="rounded-xl bg-white p-4 shadow-sm">
              <h2 className="mb-4 text-lg font-semibold">Plant Information</h2>
              <dl className="space-y-3 text-sm">
                <div>
                  <dt className="text-gray-500">Name</dt>
                  <dd className="font-medium">{request.plant.name}</dd>
                </div>
                <div>
                  <dt className="text-gray-500">Address</dt>
                  <dd className="font-medium">{request.plant.address}</dd>
                </div>
                {request.plant.phone && (
                  <div>
                    <dt className="text-gray-500">Phone</dt>
                    <dd className="font-medium">{request.plant.phone}</dd>
                  </div>
                )}
              </dl>
            </div>

            {/* Owner Info */}
            <div className="rounded-xl bg-white p-4 shadow-sm">
              <h2 className="mb-4 text-lg font-semibold">Owner Information</h2>
              <dl className="space-y-3 text-sm">
                <div>
                  <dt className="text-gray-500">Name</dt>
                  <dd className="font-medium">{request.plant.owner.name}</dd>
                </div>
                <div>
                  <dt className="text-gray-500">Email</dt>
                  <dd className="font-medium">{request.plant.owner.email}</dd>
                </div>
                {request.plant.owner.phone && (
                  <div>
                    <dt className="text-gray-500">Phone</dt>
                    <dd className="font-medium">{request.plant.owner.phone}</dd>
                  </div>
                )}
              </dl>
            </div>

            {/* Actions */}
            {request.status === 'PENDING' && (
              <div className="rounded-xl bg-white p-4 shadow-sm">
                <h2 className="mb-4 text-lg font-semibold">Actions</h2>
                <div className="flex gap-3">
                  <button
                    onClick={handleApprove}
                    disabled={actionLoading}
                    className="flex flex-1 items-center justify-center gap-2 rounded-lg bg-green-600 px-4 py-2 text-white hover:bg-green-700 disabled:opacity-50"
                  >
                    <CheckIcon className="h-5 w-5" />
                    Approve
                  </button>
                  <button
                    onClick={() => setShowRejectModal(true)}
                    disabled={actionLoading}
                    className="flex flex-1 items-center justify-center gap-2 rounded-lg bg-red-600 px-4 py-2 text-white hover:bg-red-700 disabled:opacity-50"
                  >
                    <XMarkIcon className="h-5 w-5" />
                    Reject
                  </button>
                </div>
              </div>
            )}

            {/* Rejection Reason */}
            {request.status === 'REJECTED' && request.rejectionReason && (
              <div className="rounded-xl bg-red-50 p-4">
                <h3 className="mb-2 font-semibold text-red-800">Rejection Reason</h3>
                <p className="text-sm text-red-700">{request.rejectionReason}</p>
              </div>
            )}
          </div>

          {/* Document Viewer */}
          <div className="lg:col-span-2">
            <div className="rounded-xl bg-white shadow-sm">
              <div className="flex items-center justify-between border-b p-4">
                <h2 className="font-semibold">Document Viewer</h2>
                <div className="flex items-center gap-2">
                  <button
                    onClick={() => setZoomLevel(Math.max(0.5, zoomLevel - 0.25))}
                    className="rounded p-1 hover:bg-gray-100"
                  >
                    <MagnifyingGlassMinusIcon className="h-5 w-5" />
                  </button>
                  <span className="text-sm text-gray-500">{Math.round(zoomLevel * 100)}%</span>
                  <button
                    onClick={() => setZoomLevel(Math.min(2, zoomLevel + 0.25))}
                    className="rounded p-1 hover:bg-gray-100"
                  >
                    <MagnifyingGlassPlusIcon className="h-5 w-5" />
                  </button>
                  {selectedDocument && (
                    <a
                      href={selectedDocument}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="ml-2 rounded p-1 hover:bg-gray-100"
                      title="Download"
                    >
                      <ArrowDownTrayIcon className="h-5 w-5" />
                    </a>
                  )}
                </div>
              </div>
              <div className="relative min-h-[500px] overflow-auto bg-gray-100 p-4">
                {selectedDocument ? (
                  isImage(selectedDocument) ? (
                    <div className="flex items-center justify-center">
                      <img
                        src={selectedDocument}
                        alt="Document"
                        style={{ transform: `scale(${zoomLevel})` }}
                        className="max-w-full transition-transform"
                      />
                    </div>
                  ) : isPdf(selectedDocument) ? (
                    <iframe
                      src={selectedDocument}
                      className="h-[600px] w-full rounded border"
                      title="PDF Viewer"
                    />
                  ) : (
                    <div className="flex flex-col items-center justify-center py-16">
                      <DocumentIcon className="mb-4 h-16 w-16 text-gray-400" />
                      <p className="mb-4 text-gray-500">Preview not available</p>
                      <a
                        href={selectedDocument}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="rounded-lg bg-blue-600 px-4 py-2 text-white hover:bg-blue-700"
                      >
                        Download to view
                      </a>
                    </div>
                  )
                ) : (
                  <div className="flex items-center justify-center py-16">
                    <p className="text-gray-500">Select a document to view</p>
                  </div>
                )}
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Reject Modal */}
      {showRejectModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
          <div className="w-full max-w-md rounded-xl bg-white p-6">
            <h3 className="mb-4 text-lg font-semibold">Reject Verification</h3>
            <p className="mb-4 text-sm text-gray-500">
              Please provide a reason for rejecting this verification request. This will be sent to
              the plant owner.
            </p>
            <textarea
              value={rejectionReason}
              onChange={(e) => setRejectionReason(e.target.value)}
              placeholder="Enter rejection reason..."
              className="mb-4 w-full rounded-lg border p-3 text-sm focus:border-blue-500 focus:outline-none"
              rows={4}
            />
            <div className="flex gap-3">
              <button
                onClick={() => setShowRejectModal(false)}
                className="flex-1 rounded-lg border px-4 py-2 hover:bg-gray-50"
              >
                Cancel
              </button>
              <button
                onClick={handleReject}
                disabled={actionLoading}
                className="flex-1 rounded-lg bg-red-600 px-4 py-2 text-white hover:bg-red-700 disabled:opacity-50"
              >
                {actionLoading ? 'Rejecting...' : 'Reject'}
              </button>
            </div>
          </div>
        </div>
      )}
    </DashboardLayout>
  );
}
