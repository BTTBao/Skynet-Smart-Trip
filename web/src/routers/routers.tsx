import { createBrowserRouter } from 'react-router-dom';
import { AdminLayout } from '../components/layout';
import AuthGuard from '../components/auth/AuthGuard';
import { LoginPage, ResetPasswordPage } from '../pages/auth';
import { DashboardPage } from '../pages/dashboard';
import { UsersPage } from '../pages/users';
import { DestinationsPage } from '../pages/destinations';
import { HotelsPage } from '../pages/hotels';
import { TransportPage } from '../pages/transport';
import { PromotionsPage } from '../pages/promotions';
import { BookingsPage } from '../pages/bookings';
import { ReportsPage } from '../pages/reports';

const router = createBrowserRouter([
  {
    path: '/login',
    element: <LoginPage />,
  },
  {
    path: '/reset-password',
    element: <ResetPasswordPage />,
  },
  {
    element: <AuthGuard />,
    children: [
      {
        path: '/',
        element: <AdminLayout />,
        children: [
          { index: true, element: <DashboardPage /> },
          { path: 'users', element: <UsersPage /> },
          { path: 'destinations', element: <DestinationsPage /> },
          { path: 'hotels', element: <HotelsPage /> },
          { path: 'transport', element: <TransportPage /> },
          { path: 'promotions', element: <PromotionsPage /> },
          { path: 'bookings', element: <BookingsPage /> },
          { path: 'reports', element: <ReportsPage /> },
        ],
      },
    ],
  },
]);

export default router;
