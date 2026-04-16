import { Navigate, Outlet, useLocation } from 'react-router-dom';
import { useAuth } from '../../context';

const allowedRoles = new Set(['Admin', 'Staff']);

export default function AuthGuard() {
  const { isAuthenticated, isLoading, user } = useAuth();
  const location = useLocation();

  if (isLoading) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-surface">
        <div className="h-12 w-12 animate-spin rounded-full border-b-2 border-primary-container"></div>
      </div>
    );
  }

  if (!isAuthenticated) {
    return <Navigate to="/login" replace state={{ from: location }} />;
  }

  if (user && !allowedRoles.has(user.role)) {
    return <Navigate to="/login" replace state={{ from: location }} />;
  }

  return <Outlet />;
}
