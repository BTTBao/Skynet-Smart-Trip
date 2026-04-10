import { NavLink, useLocation } from 'react-router-dom';

interface NavItem {
  icon: string;
  label: string;
  path: string;
}

const mainNavItems: NavItem[] = [
  { icon: 'dashboard', label: 'Bảng điều khiển', path: '/' },
  { icon: 'group', label: 'Người dùng', path: '/users' },
  { icon: 'explore', label: 'Điểm đến', path: '/destinations' },
  { icon: 'hotel', label: 'Khách sạn & Phòng', path: '/hotels' },
  { icon: 'directions_bus', label: 'Chuyển xe', path: '/transport' },
  { icon: 'sell', label: 'Khuyến mãi', path: '/promotions' },
  { icon: 'confirmation_number', label: 'Đặt chỗ (Chuyến đi)', path: '/bookings' },
  { icon: 'bar_chart', label: 'Báo cáo doanh thu', path: '/reports' },
];

export default function Sidebar() {
  const location = useLocation();

  return (
    <aside className="h-screen w-72 flex flex-col sticky top-0 left-0 bg-surface-container-low py-8 font-body text-sm font-medium shrink-0">
      {/* Logo */}
      <div className="px-8 mb-10 flex items-center gap-3">
        <div className="w-10 h-10 bg-primary-container rounded-xl flex items-center justify-center">
          <span className="material-symbols-outlined text-white">rocket_launch</span>
        </div>
        <div>
          <h1 className="text-xl font-black text-on-surface tracking-tight leading-none">
            Skynet Smart
          </h1>
          <p className="text-[10px] text-on-surface-variant/60 uppercase tracking-widest font-bold mt-1">
            Smart Trip Admin
          </p>
        </div>
      </div>

      {/* Navigation */}
      <nav className="flex-1 flex flex-col gap-1 overflow-y-auto px-4">
        {mainNavItems.map((item) => {
          const isActive = location.pathname === item.path;
          return (
            <NavLink
              key={item.path}
              to={item.path}
              className={`flex items-center gap-4 py-3 transition-all duration-200 rounded-[3rem] ${
                isActive
                  ? 'bg-white text-primary-container shadow-sm font-bold scale-[1.02] ml-4 pr-4'
                  : 'text-[#6B7280] hover:text-primary-container px-8 hover:bg-white/50'
              }`}
            >
              <span
                className={`material-symbols-outlined ${isActive ? 'ml-4' : ''}`}
                style={isActive ? { fontVariationSettings: "'FILL' 1, 'wght' 400, 'GRAD' 0, 'opsz' 24" } : {}}
              >
                {item.icon}
              </span>
              <span>{item.label}</span>
            </NavLink>
          );
        })}
      </nav>

      {/* Bottom Actions */}
      <div className="px-4 mt-auto">
        <button className="w-full bg-primary-container text-white py-4 rounded-xl font-bold flex items-center justify-center gap-2 shadow-lg shadow-primary-container/20 active:scale-95 transition-transform">
          <span className="material-symbols-outlined">add</span>
          <span>Tạo chuyến mới</span>
        </button>
        <div className="mt-6 flex flex-col gap-1">
          <a
            href="#"
            className="text-[#6B7280] px-8 py-3 flex items-center gap-4 hover:text-primary transition-colors"
          >
            <span className="material-symbols-outlined">settings</span>
            <span>Cài đặt</span>
          </a>
          <a
            href="#"
            className="text-[#6B7280] px-8 py-3 flex items-center gap-4 hover:text-error transition-colors"
          >
            <span className="material-symbols-outlined">logout</span>
            <span>Đăng xuất</span>
          </a>
        </div>
      </div>
    </aside>
  );
}
