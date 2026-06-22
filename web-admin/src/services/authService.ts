import { fetchClient } from '@/lib/fetchClient';

export interface LoginRequest {
  email: string;
  password: string;
}

export interface LoginResponse {
  accessToken?: string;
  refreshToken?: string;
  expiresIn?: number;
  AccessToken?: string;
  RefreshToken?: string;
  ExpiresIn?: number;
}

export interface AuthProfile {
  userId: string;
  email: string;
  fullName: string;
  role: string;
}

export interface ForgotPasswordRequest {
  email: string;
}

export interface ResetPasswordRequest {
  token: string;
  newPassword: string;
}

export const authService = {
  async login(payload: LoginRequest): Promise<LoginResponse> {
    return fetchClient.post<LoginResponse>('/auth/login', {
      identifier: payload.email,
      password: payload.password,
    });
  },

  async logout(refreshToken: string): Promise<void> {
    await fetchClient.post('/auth/logout', { refreshToken });
  },

  async getProfile(): Promise<AuthProfile> {
    const response = await fetchClient.get<{ success: boolean; data: AuthProfile }>('/auth/me');
    return response.data;
  },

  async forgotPassword(payload: ForgotPasswordRequest): Promise<void> {
    await fetchClient.post('/auth/forgot-password', payload);
  },

  async resetPassword(payload: ResetPasswordRequest): Promise<void> {
    await fetchClient.post('/auth/reset-password', payload);
  },
};
