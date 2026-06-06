import axios from 'axios';
import { authStorage } from './authStorage';

// Lấy URL từ file .env (hoặc mặc định là 5110 theo launchSettings.json)
const BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:5555/api';

const apiClient = axios.create({
  baseURL: BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

interface RefreshTokenResponse {
  accessToken?: string;
  refreshToken?: string;
  AccessToken?: string;
  RefreshToken?: string;
}

apiClient.interceptors.request.use(
  (config) => {
    const token = authStorage.getAccessToken();
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => Promise.reject(error)
);

let refreshPromise: Promise<string | null> | null = null;

apiClient.interceptors.response.use(
  (response) => response,
  async (error) => {
    const originalRequest = error.config as typeof error.config & { _retry?: boolean };

    if (error.response?.status !== 401 || originalRequest?._retry) {
      return Promise.reject(error);
    }

    const refreshToken = authStorage.getRefreshToken();
    if (!refreshToken) {
      authStorage.clear();
      return Promise.reject(error);
    }

    originalRequest._retry = true;

    refreshPromise ??= axios
      .post(`${BASE_URL}/auth/refresh-token`, { refreshToken })
      .then((response) => {
        const payload = response.data as RefreshTokenResponse;
        const accessToken = payload?.accessToken ?? payload?.AccessToken;
        const nextRefreshToken = payload?.refreshToken ?? payload?.RefreshToken;

        if (!accessToken || !nextRefreshToken) {
          authStorage.clear();
          return null;
        }

        authStorage.setTokens(accessToken, nextRefreshToken);
        return accessToken;
      })
      .catch(() => {
        authStorage.clear();
        return null;
      })
      .finally(() => {
        refreshPromise = null;
      });

    const nextAccessToken = await refreshPromise;

    if (!nextAccessToken) {
      return Promise.reject(error);
    }

    originalRequest.headers.Authorization = `Bearer ${nextAccessToken}`;
    return apiClient(originalRequest);
  }
);

export default apiClient;
