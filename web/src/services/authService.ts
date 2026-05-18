import apiClient from './apiClient';

export interface LoginRequest {
  email: string;
  password: string;
}

export interface LoginResponse {
  accessToken: string;
  refreshToken: string;
  expiresIn: number;
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
    const response = await apiClient.post<LoginResponse>('/auth/login', payload);
    return response.data;
  },

  async logout(refreshToken: string) {
    await apiClient.post('/auth/logout', { refreshToken });
  },

  async getProfile(): Promise<AuthProfile> {
    const response = await apiClient.get<{ success: boolean; data: AuthProfile }>('/auth/me');
    return response.data.data;
  },

  async forgotPassword(payload: ForgotPasswordRequest) {
    await apiClient.post('/auth/forgot-password', payload);
  },

  async resetPassword(payload: ResetPasswordRequest) {
    await apiClient.post('/auth/reset-password', payload);
  },
};
