import {
  createContext,
  useContext,
  useEffect,
  useState,
  type PropsWithChildren,
} from 'react';
import { authService, type AuthProfile, type LoginRequest } from '../services/authService';
import { authStorage } from '../services/authStorage';

interface AuthContextValue {
  isAuthenticated: boolean;
  isLoading: boolean;
  user: AuthProfile | null;
  login: (payload: LoginRequest) => Promise<void>;
  logout: () => Promise<void>;
  refreshProfile: () => Promise<void>;
}

const AuthContext = createContext<AuthContextValue | null>(null);

export function AuthProvider({ children }: PropsWithChildren) {
  const [user, setUser] = useState<AuthProfile | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  const refreshProfile = async () => {
    const accessToken = authStorage.getAccessToken();
    if (!accessToken) {
      setUser(null);
      return;
    }

    try {
      const profile = await authService.getProfile();
      setUser(profile);
    } catch {
      authStorage.clear();
      setUser(null);
    }
  };

  useEffect(() => {
    const bootstrap = async () => {
      await refreshProfile();
      setIsLoading(false);
    };

    bootstrap();
  }, []);

  const login = async (payload: LoginRequest) => {
    const response = await authService.login(payload);
    authStorage.setTokens(response.accessToken, response.refreshToken);
    const profile = await authService.getProfile();
    setUser(profile);
  };

  const logout = async () => {
    const refreshToken = authStorage.getRefreshToken();

    try {
      if (refreshToken) {
        await authService.logout(refreshToken);
      }
    } finally {
      authStorage.clear();
      setUser(null);
    }
  };

  return (
    <AuthContext.Provider
      value={{
        isAuthenticated: Boolean(user),
        isLoading,
        user,
        login,
        logout,
        refreshProfile,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const context = useContext(AuthContext);

  if (!context) {
    throw new Error('useAuth must be used within AuthProvider');
  }

  return context;
}
