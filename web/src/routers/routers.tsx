import { createBrowserRouter } from 'react-router-dom';
import { AdminLayout } from '../components/layout';
import { DashboardPage } from '../pages/dashboard';
import { UsersPage } from '../pages/users';
import PlaceholderPage from '../pages/PlaceholderPage';

const router = createBrowserRouter([
  {
    path: '/',
    element: <AdminLayout />,
    children: [
      { index: true, element: <DashboardPage /> },
      { path: 'users', element: <UsersPage /> },
      // Placeholder routes
      { path: 'destinations', element: <PlaceholderPage /> },
      { path: 'hotels', element: <PlaceholderPage /> },
      { path: 'transport', element: <PlaceholderPage /> },
      { path: 'promotions', element: <PlaceholderPage /> },
      { path: 'bookings', element: <PlaceholderPage /> },
      { path: 'reports', element: <PlaceholderPage /> },
    ],
  },
]);

export default router;
