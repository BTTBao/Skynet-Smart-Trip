import { authStorage } from '../services/authStorage';

const BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:5110/api';

interface RequestOptions extends RequestInit {
  params?: Record<string, string | number | boolean | undefined>;
}

let refreshPromise: Promise<string | null> | null = null;

async function executeRefresh(): Promise<string | null> {
  const refreshToken = authStorage.getRefreshToken();
  if (!refreshToken) {
    authStorage.clear();
    return null;
  }

  try {
    const response = await fetch(`${BASE_URL}/auth/refresh-token`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ refreshToken }),
    });

    if (!response.ok) {
      throw new Error('Refresh token request failed');
    }

    const payload = await response.json();
    const accessToken = payload?.accessToken ?? payload?.AccessToken;
    const nextRefreshToken = payload?.refreshToken ?? payload?.RefreshToken;

    if (!accessToken || !nextRefreshToken) {
      authStorage.clear();
      return null;
    }

    authStorage.setTokens(accessToken, nextRefreshToken);
    return accessToken;
  } catch (error) {
    authStorage.clear();
    return null;
  }
}

async function request<T>(path: string, options: RequestOptions = {}): Promise<T> {
  const { params, headers, ...restOptions } = options;

  // Build URL with query params
  let url = `${BASE_URL}${path}`;
  if (params) {
    const searchParams = new URLSearchParams();
    Object.entries(params).forEach(([key, val]) => {
      if (val !== undefined && val !== null) {
        searchParams.append(key, String(val));
      }
    });
    const queryString = searchParams.toString();
    if (queryString) {
      url += `?${queryString}`;
    }
  }

  // Build Headers
  const requestHeaders = new Headers(headers);
  
  // Set Content-Type default unless it is FormData
  if (!(restOptions.body instanceof FormData) && !requestHeaders.has('Content-Type')) {
    requestHeaders.set('Content-Type', 'application/json');
  }

  // Add Bearer Token
  const token = authStorage.getAccessToken();
  if (token) {
    requestHeaders.set('Authorization', `Bearer ${token}`);
  }

  const finalOptions: RequestInit = {
    ...restOptions,
    headers: requestHeaders,
  };

  let response = await fetch(url, finalOptions);

  if (response.status === 401 && !path.includes('/auth/login') && !path.includes('/auth/refresh-token')) {
    // Attempt Token Refresh
    if (!refreshPromise) {
      refreshPromise = executeRefresh().finally(() => {
        refreshPromise = null;
      });
    }

    const nextAccessToken = await refreshPromise;
    if (nextAccessToken) {
      // Retry with new token
      requestHeaders.set('Authorization', `Bearer ${nextAccessToken}`);
      response = await fetch(url, {
        ...finalOptions,
        headers: requestHeaders,
      });
    } else {
      // Clear token and force redirect to login
      authStorage.clear();
      if (typeof window !== 'undefined') {
        window.location.href = '/sign-in';
      }
      throw new Error('Unauthorized');
    }
  }

  if (!response.ok) {
    let errorMessage = `HTTP error! status: ${response.status}`;
    try {
      const errorData = await response.json();
      errorMessage = errorData?.message || errorData?.Message || errorMessage;
    } catch (_) {
      // Ignore parse failure and use default error message
    }
    throw new Error(errorMessage);
  }

  // Handle empty responses
  const contentType = response.headers.get('content-type');
  if (contentType && contentType.includes('application/json')) {
    return response.json() as Promise<T>;
  }

  return null as T;
}

export const fetchClient = {
  get<T>(path: string, options?: RequestOptions): Promise<T> {
    return request<T>(path, { ...options, method: 'GET' });
  },
  post<T>(path: string, body?: any, options?: RequestOptions): Promise<T> {
    return request<T>(path, {
      ...options,
      method: 'POST',
      body: body instanceof FormData ? body : JSON.stringify(body),
    });
  },
  put<T>(path: string, body?: any, options?: RequestOptions): Promise<T> {
    return request<T>(path, {
      ...options,
      method: 'PUT',
      body: body instanceof FormData ? body : JSON.stringify(body),
    });
  },
  patch<T>(path: string, body?: any, options?: RequestOptions): Promise<T> {
    return request<T>(path, {
      ...options,
      method: 'PATCH',
      body: body instanceof FormData ? body : JSON.stringify(body),
    });
  },
  delete<T>(path: string, options?: RequestOptions): Promise<T> {
    return request<T>(path, { ...options, method: 'DELETE' });
  },
};
