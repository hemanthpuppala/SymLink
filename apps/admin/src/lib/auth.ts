import { apiClient } from './api';

interface Admin {
  id: string;
  email: string;
  name: string;
  role: 'SUPER_ADMIN' | 'ADMIN' | 'MODERATOR';
  createdAt: string;
  updatedAt: string;
}

interface AuthTokens {
  accessToken: string;
  refreshToken: string;
}

interface LoginCredentials {
  email: string;
  password: string;
}

export async function login(credentials: LoginCredentials): Promise<{ admin: Admin; tokens: AuthTokens }> {
  const response = await apiClient.post<{ admin: Admin; tokens: AuthTokens }>('/admin/auth/login', credentials);

  if (response.success && response.data) {
    apiClient.setAccessToken(response.data.tokens.accessToken);
    if (typeof window !== 'undefined') {
      localStorage.setItem('refreshToken', response.data.tokens.refreshToken);
      localStorage.setItem('admin', JSON.stringify(response.data.admin));
    }
    return response.data;
  }

  throw new Error(response.message || 'Login failed');
}

export async function logout(): Promise<void> {
  try {
    await apiClient.post('/auth/logout');
  } finally {
    apiClient.setAccessToken(null);
    if (typeof window !== 'undefined') {
      localStorage.removeItem('refreshToken');
      localStorage.removeItem('admin');
    }
  }
}

export async function refreshTokens(): Promise<AuthTokens> {
  const refreshToken = typeof window !== 'undefined' ? localStorage.getItem('refreshToken') : null;

  if (!refreshToken) {
    throw new Error('No refresh token available');
  }

  const response = await apiClient.post<AuthTokens>('/admin/auth/refresh', { refreshToken });

  if (response.success && response.data) {
    apiClient.setAccessToken(response.data.accessToken);
    if (typeof window !== 'undefined') {
      localStorage.setItem('refreshToken', response.data.refreshToken);
    }
    return response.data;
  }

  throw new Error('Failed to refresh tokens');
}

export function getCurrentAdmin(): Admin | null {
  if (typeof window === 'undefined') return null;

  const adminStr = localStorage.getItem('admin');
  if (!adminStr) return null;

  try {
    return JSON.parse(adminStr) as Admin;
  } catch {
    return null;
  }
}

export function isAuthenticated(): boolean {
  if (typeof window === 'undefined') return false;
  return !!localStorage.getItem('accessToken');
}

export type { Admin, AuthTokens, LoginCredentials };
