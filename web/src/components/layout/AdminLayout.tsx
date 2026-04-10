import { Outlet } from 'react-router-dom';
import Sidebar from './Sidebar';
import TopNav from './TopNav';

export default function AdminLayout() {
  return (
    <div className="bg-surface text-on-surface antialiased flex min-h-screen">
      <Sidebar />
      <main className="flex-1 flex flex-col min-w-0">
        <TopNav />
        <div className="flex-1 overflow-y-auto p-10 space-y-10">
          <Outlet />
        </div>
      </main>
    </div>
  );
}
