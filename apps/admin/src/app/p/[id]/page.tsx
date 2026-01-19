'use client';

import { useState, useEffect } from 'react';
import Image from 'next/image';
import {
  MapPinIcon,
  PhoneIcon,
  ClockIcon,
  BeakerIcon,
  CurrencyRupeeIcon,
  CheckBadgeIcon,
} from '@heroicons/react/24/outline';

interface PublicPlant {
  id: string;
  name: string;
  address: string;
  latitude: number;
  longitude: number;
  phone: string | null;
  description: string | null;
  tdsLevel: number | null;
  pricePerLiter: number | null;
  operatingHours: string | null;
  photos: string[];
  isVerified: boolean;
  isOpen: boolean;
  ownerName: string;
}

// Derive API URL from environment
const API_BASE = process.env.NEXT_PUBLIC_API_URL || 'http://10.0.0.17:3000/v1';

export default function PublicProfilePage({ params }: { params: { id: string } }) {
  const [plant, setPlant] = useState<PublicPlant | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [selectedPhoto, setSelectedPhoto] = useState(0);

  useEffect(() => {
    loadPlant();
  }, [params.id]);

  const loadPlant = async () => {
    try {
      setLoading(true);
      setError(null);

      const response = await fetch(`${API_BASE}/consumer/plants/share/${params.id}`);
      const result = await response.json();

      if (!response.ok) {
        throw new Error(result.message || 'Failed to load plant');
      }

      setPlant(result.data);
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to load plant');
    } finally {
      setLoading(false);
    }
  };

  const openDirections = () => {
    if (!plant) return;
    const url = `https://www.google.com/maps/dir/?api=1&destination=${plant.latitude},${plant.longitude}`;
    window.open(url, '_blank');
  };

  const callPhone = () => {
    if (!plant?.phone) return;
    window.location.href = `tel:${plant.phone}`;
  };

  if (loading) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-gray-50">
        <div className="text-gray-500">Loading...</div>
      </div>
    );
  }

  if (error || !plant) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-gray-50">
        <div className="text-center">
          <div className="text-6xl mb-4">🚰</div>
          <h1 className="text-xl font-semibold text-gray-900">Plant not found</h1>
          <p className="text-gray-500 mt-2">{error || 'The plant you are looking for does not exist.'}</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <header className="bg-white shadow-sm">
        <div className="mx-auto max-w-lg px-4 py-4">
          <div className="flex items-center gap-2">
            <span className="text-2xl">💧</span>
            <span className="font-semibold text-gray-900">FlowGrid</span>
          </div>
        </div>
      </header>

      <main className="mx-auto max-w-lg">
        {/* Photo Gallery */}
        {plant.photos.length > 0 && (
          <div className="relative aspect-video bg-gray-200">
            <img
              src={plant.photos[selectedPhoto]}
              alt={plant.name}
              className="h-full w-full object-cover"
            />
            {plant.photos.length > 1 && (
              <div className="absolute bottom-4 left-1/2 -translate-x-1/2 flex gap-2">
                {plant.photos.map((_, index) => (
                  <button
                    key={index}
                    onClick={() => setSelectedPhoto(index)}
                    className={`h-2 w-2 rounded-full transition-colors ${
                      index === selectedPhoto ? 'bg-white' : 'bg-white/50'
                    }`}
                  />
                ))}
              </div>
            )}
          </div>
        )}

        {/* Plant Info */}
        <div className="bg-white p-4">
          <div className="flex items-start justify-between">
            <div>
              <div className="flex items-center gap-2">
                <h1 className="text-xl font-bold text-gray-900">{plant.name}</h1>
                {plant.isVerified && (
                  <CheckBadgeIcon className="h-5 w-5 text-blue-500" title="Verified" />
                )}
              </div>
              <p className="text-sm text-gray-500">by {plant.ownerName}</p>
            </div>
            <span
              className={`rounded-full px-3 py-1 text-sm font-medium ${
                plant.isOpen
                  ? 'bg-green-100 text-green-800'
                  : 'bg-red-100 text-red-800'
              }`}
            >
              {plant.isOpen ? 'Open' : 'Closed'}
            </span>
          </div>

          {plant.description && (
            <p className="mt-4 text-gray-600">{plant.description}</p>
          )}

          {/* Details */}
          <div className="mt-6 space-y-4">
            <div className="flex items-start gap-3">
              <MapPinIcon className="h-5 w-5 text-gray-400 mt-0.5" />
              <div>
                <p className="text-sm font-medium text-gray-900">Address</p>
                <p className="text-sm text-gray-600">{plant.address}</p>
              </div>
            </div>

            {plant.phone && (
              <div className="flex items-start gap-3">
                <PhoneIcon className="h-5 w-5 text-gray-400 mt-0.5" />
                <div>
                  <p className="text-sm font-medium text-gray-900">Phone</p>
                  <p className="text-sm text-gray-600">{plant.phone}</p>
                </div>
              </div>
            )}

            {plant.operatingHours && (
              <div className="flex items-start gap-3">
                <ClockIcon className="h-5 w-5 text-gray-400 mt-0.5" />
                <div>
                  <p className="text-sm font-medium text-gray-900">Hours</p>
                  <p className="text-sm text-gray-600">{plant.operatingHours}</p>
                </div>
              </div>
            )}

            {plant.tdsLevel && (
              <div className="flex items-start gap-3">
                <BeakerIcon className="h-5 w-5 text-gray-400 mt-0.5" />
                <div>
                  <p className="text-sm font-medium text-gray-900">TDS Level</p>
                  <p className="text-sm text-gray-600">{plant.tdsLevel} ppm</p>
                </div>
              </div>
            )}

            {plant.pricePerLiter && (
              <div className="flex items-start gap-3">
                <CurrencyRupeeIcon className="h-5 w-5 text-gray-400 mt-0.5" />
                <div>
                  <p className="text-sm font-medium text-gray-900">Price</p>
                  <p className="text-sm text-gray-600">₹{plant.pricePerLiter} per liter</p>
                </div>
              </div>
            )}
          </div>

          {/* Actions */}
          <div className="mt-8 grid grid-cols-2 gap-4">
            <button
              onClick={openDirections}
              className="flex items-center justify-center gap-2 rounded-lg border border-gray-300 px-4 py-3 text-sm font-medium text-gray-700 hover:bg-gray-50"
            >
              <MapPinIcon className="h-5 w-5" />
              Get Directions
            </button>
            {plant.phone && (
              <button
                onClick={callPhone}
                className="flex items-center justify-center gap-2 rounded-lg bg-blue-600 px-4 py-3 text-sm font-medium text-white hover:bg-blue-700"
              >
                <PhoneIcon className="h-5 w-5" />
                Call Now
              </button>
            )}
          </div>
        </div>

        {/* App Download Banner */}
        <div className="bg-gradient-to-r from-blue-600 to-blue-700 p-4 mt-4 mb-8 rounded-lg mx-4">
          <div className="text-white">
            <h2 className="font-semibold">Get the FlowGrid App</h2>
            <p className="text-sm text-blue-100 mt-1">
              Find water plants near you, compare prices, and chat with owners.
            </p>
            <div className="mt-4 flex gap-2">
              <button className="rounded-lg bg-white px-4 py-2 text-sm font-medium text-blue-600 hover:bg-blue-50">
                Download App
              </button>
            </div>
          </div>
        </div>
      </main>
    </div>
  );
}
