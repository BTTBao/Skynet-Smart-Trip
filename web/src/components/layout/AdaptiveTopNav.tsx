import { useEffect } from 'react';
import { useLocation } from 'react-router-dom';
import { useAdminSearch, useAuth } from '../../context';

interface AdaptiveTopNavProps {
  searchPlaceholder?: string;
}

const placeholderByPath: Record<string, string> = {
  '/': 'Tìm kiếm báo cáo, người dùng, giao dịch...',
  '/users': 'Tìm kiếm người dùng, email, số điện thoại...',
  '/transport': 'Tìm kiếm lịch trình, mã chuyến, nhà xe...',
  '/bookings': 'Tìm kiếm booking, khách hàng, điểm đến...',
};

export default function AdaptiveTopNav({ searchPlaceholder }: AdaptiveTopNavProps) {
  const location = useLocation();
  const { query, setQuery, clearQuery } = useAdminSearch();
  const { user } = useAuth();
  const resolvedPlaceholder =
    searchPlaceholder ??
    placeholderByPath[location.pathname] ??
    'Tìm kiếm giao dịch, người dùng...';

  useEffect(() => {
    clearQuery();
  }, [clearQuery, location.pathname]);

  return (
    <header className="sticky top-0 z-40 w-full bg-white/70 backdrop-blur-xl flex justify-between items-center px-10 py-4 shadow-[0px_20px_40px_rgba(21,28,39,0.06)]">
      <div className="flex items-center flex-1 max-w-xl">
        <div className="relative w-full">
          <span className="material-symbols-outlined absolute left-4 top-1/2 -translate-y-1/2 text-on-surface-variant/50">
            search
          </span>
          <input
            type="text"
            className="w-full pl-12 pr-4 py-3 bg-surface-container-low border-none rounded-full text-sm focus:ring-2 focus:ring-primary-container/20 focus:outline-none transition-all"
            placeholder={resolvedPlaceholder}
            value={query}
            onChange={(event) => setQuery(event.target.value)}
          />
        </div>
      </div>

      <div className="flex items-center gap-6">
        <div className="flex items-center gap-2">
          <button className="w-10 h-10 flex items-center justify-center rounded-full hover:bg-surface-container-high transition-all text-on-surface-variant">
            <span className="material-symbols-outlined">notifications</span>
          </button>
          <button className="w-10 h-10 flex items-center justify-center rounded-full hover:bg-surface-container-high transition-all text-on-surface-variant">
            <span className="material-symbols-outlined">settings</span>
          </button>
        </div>

        <div className="h-8 w-[1px] bg-outline-variant/30" />

        <div className="flex items-center gap-3 cursor-pointer group">
          <div className="text-right hidden sm:block">
            <p className="text-sm font-bold text-on-surface leading-none">{user?.fullName ?? 'Admin Profile'}</p>
            <p className="text-[10px] text-on-surface-variant font-medium mt-1">{user?.role ?? 'Super Admin'}</p>
          </div>
          <div className="w-10 h-10 rounded-full bg-primary-container/20 flex items-center justify-center ring-2 ring-primary-container/20 group-hover:ring-primary-container transition-all">
            <span className="material-symbols-outlined text-primary-container">shield_person</span>
          </div>
        </div>
      </div>
    </header>
  );
}
