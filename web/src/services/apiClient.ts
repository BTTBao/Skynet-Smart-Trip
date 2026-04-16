import axios from 'axios';
import { authStorage } from './authStorage';

// Lấy URL từ file .env (hoặc mặc định là 5110 theo launchSettings.json)
const BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:5110/api';

const apiClient = axios.create({
  baseURL: BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

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
        const payload = response.data as { accessToken: string; refreshToken: string };
        authStorage.setTokens(payload.accessToken, payload.refreshToken);
        return payload.accessToken;
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
