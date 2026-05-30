import { useEffect, useMemo, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { adminService, type AdminDashboardStats, type AdminRecentBooking } from '../../services/adminService';
import { downloadCsv } from '../../utils/adminActions';

const statusConfig = {
  paid: { label: 'Đã thanh toán', bgClass: 'bg-[#10B981]/10', textClass: 'text-[#10B981]' },
  pending: { label: 'Chờ thanh toán', bgClass: 'bg-[#F97316]/10', textClass: 'text-[#F97316]' },
  cancelled: { label: 'Đã hủy', bgClass: 'bg-[#6B7280]/10', textClass: 'text-[#6B7280]' },
};

const chartSeries = {
  '3m': {
    months: ['APR', 'MAY', 'JUN'],
    revenue: [68, 90, 82],
    profit: [28, 40, 36],
  },
  '6m': {
    months: ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN'],
    revenue: [74, 66, 90, 80, 100, 86],
    profit: [24, 20, 32, 25, 40, 35],
  },
};

const formatCompactNumber = (number: number) =>
  new Intl.NumberFormat('en-US', { notation: 'compact', maximumFractionDigits: 1 }).format(number);

function MetricCard({
  label,
  value,
  helper,
  icon,
  iconClass,
  onClick,
}: {
  label: string;
  value: string;
  helper: string;
  icon: string;
  iconClass: string;
  onClick: () => void;
}) {
  return (
    <button
      onClick={onClick}
      className="text-left bg-surface-container-lowest p-8 rounded-xl shadow-sm border border-outline-variant/5 hover:-translate-y-1 hover:shadow-lg transition-all"
    >
      <div className="flex justify-between items-start mb-5">
        <span className={`material-symbols-outlined p-3 rounded-2xl ${iconClass}`} style={{ fontVariationSettings: "'FILL' 1" }}>
          {icon}
        </span>
        <span className="text-[11px] font-bold text-primary">Mở trang</span>
      </div>
      <p className="text-[11px] font-bold text-on-surface-variant uppercase tracking-wider">{label}</p>
      <h3 className="text-3xl font-black text-on-surface mt-2">{value}</h3>
      <p className="text-sm text-on-surface-variant mt-3">{helper}</p>
    </button>
  );
}

export default function DashboardInteractivePage() {
  const [stats, setStats] = useState<AdminDashboardStats | null>(null);
  const [loading, setLoading] = useState(true);
  const [period, setPeriod] = useState<'3m' | '6m'>('6m');
  const [recentStatus, setRecentStatus] = useState<'all' | AdminRecentBooking['status']>('all');
  const [selectedBooking, setSelectedBooking] = useState<AdminRecentBooking | null>(null);
  const navigate = useNavigate();

  useEffect(() => {
    const fetchData = async () => {
      try {
        const data = await adminService.getDashboardStats();
        setStats(data);
      } catch (error) {
        console.error('Failed to fetch dashboard stats:', error);
      } finally {
        setLoading(false);
      }
    };

    fetchData();
  }, []);

  const filteredBookings = useMemo(() => {
    if (!stats) {
      return [];
    }

    return stats.recentBookings.filter((booking) => recentStatus === 'all' || booking.status === recentStatus);
  }, [recentStatus, stats]);

  const exportRecentBookings = () => {
    downloadCsv(`dashboard-recent-bookings-${recentStatus}.csv`, filteredBookings, [
      { key: 'id', header: 'Mã đặt chỗ' },
      { key: 'name', header: 'Khách hàng' },
      { key: 'destination', header: 'Điểm đến' },
      { key: 'amount', header: 'Tổng tiền' },
      { key: 'status', header: 'Trạng thái' },
    ]);
  };

  if (loading) {
    return <div className="flex items-center justify-center h-full min-h-[50vh]"><div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary"></div></div>;
  }

  if (!stats) {
    return <div className="text-center text-error mt-10">Không thể tải dữ liệu dashboard.</div>;
  }

  const currentChart = chartSeries[period];

  return (
    <div className="space-y-10">
      <section className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <MetricCard label="Tổng doanh thu" value={`${formatCompactNumber(stats.totalRevenue)}đ`} helper="Đi tới danh sách đặt chỗ để xem giao dịch chi tiết." icon="payments" iconClass="bg-tertiary-fixed text-on-tertiary-container" onClick={() => navigate('/bookings')} />
        <MetricCard label="Tổng lợi nhuận" value={`${formatCompactNumber(stats.totalProfit)}đ`} helper="Đi tới chuyến xe để theo dõi doanh thu affiliate." icon="account_balance_wallet" iconClass="bg-primary-container/10 text-primary-container" onClick={() => navigate('/transport')} />
        <MetricCard label="Tổng người dùng" value={stats.totalUsers.toLocaleString()} helper={`+${stats.newUsersToday} người dùng mới hôm nay.`} icon="group" iconClass="bg-surface-container text-on-surface" onClick={() => navigate('/users')} />
        <MetricCard label="Chuyến đi đang diễn ra" value={stats.activeTrips.toString()} helper="Theo dõi trạng thái booking đang được xử lý." icon="travel_explore" iconClass="bg-secondary-fixed text-secondary" onClick={() => navigate('/bookings')} />
      </section>

      <section className="grid grid-cols-1 lg:grid-cols-3 gap-10">
        <div className="lg:col-span-2 bg-surface-container-lowest p-10 rounded-xl shadow-[0px_20px_40px_rgba(21,28,39,0.03)] flex flex-col">
          <div className="flex justify-between items-end mb-10">
            <div>
              <h3 className="text-xl font-bold text-on-surface">Phân tích tài chính</h3>
              <p className="text-sm text-on-surface-variant mt-1">So sánh doanh thu và lợi nhuận theo mốc thời gian gần đây</p>
            </div>
            <div className="flex items-center gap-3 bg-surface-container-low p-1.5 rounded-full">
              <button onClick={() => setPeriod('3m')} className={`px-4 py-2 rounded-full text-sm font-bold ${period === '3m' ? 'bg-white shadow-sm text-on-surface' : 'text-on-surface-variant'}`}>3M</button>
              <button onClick={() => setPeriod('6m')} className={`px-4 py-2 rounded-full text-sm font-bold ${period === '6m' ? 'bg-white shadow-sm text-on-surface' : 'text-on-surface-variant'}`}>6M</button>
            </div>
          </div>

          <div className="flex-1 min-h-[300px] flex items-end justify-between gap-4 px-4 border-b border-outline-variant/10">
            {currentChart.months.map((month, index) => (
              <div key={month} className="flex-1 flex flex-col items-center gap-2 group">
                <div className="w-full flex justify-center items-end gap-1 h-48">
                  <div className="w-6 bg-tertiary-container/30 rounded-t-lg group-hover:brightness-110 transition-all duration-500" style={{ height: `${currentChart.revenue[index]}%` }} />
                  <div className="w-6 bg-primary-container rounded-t-lg group-hover:brightness-110 transition-all duration-500" style={{ height: `${currentChart.profit[index]}%` }} />
                </div>
                <span className="text-[10px] font-bold text-on-surface-variant">{month}</span>
              </div>
            ))}
          </div>
        </div>

        <div className="bg-primary-container rounded-xl p-10 text-white flex flex-col justify-between relative overflow-hidden shadow-xl shadow-primary-container/20">
          <div className="relative z-10">
            <h3 className="text-2xl font-black mb-4 leading-tight">Mở rộng mạng lưới đối tác</h3>
            <p className="text-white/80 text-sm leading-relaxed mb-8">Tăng thêm 25% lợi nhuận Affiliate bằng cách kích hoạt gói đối tác Kim Cương ngay hôm nay.</p>
            <div className="flex gap-3 flex-wrap">
              <button onClick={() => window.location.assign('mailto:partners@skynetsmarttrip.local?subject=Yeu%20cau%20nang%20cap%20goi%20doi%20tac')} className="bg-white text-primary-container px-6 py-3 rounded-full font-bold text-sm shadow-lg hover:scale-105 transition-transform active:scale-95 cursor-pointer">
                Nâng cấp ngay
              </button>
              <button onClick={() => navigator.clipboard.writeText('partners@skynetsmarttrip.local')} className="bg-white/10 text-white px-6 py-3 rounded-full font-bold text-sm hover:bg-white/20 transition-all">
                Sao chép email
              </button>
            </div>
          </div>

          <div className="absolute -right-10 -bottom-10 w-48 h-48 bg-white/10 rounded-full blur-3xl" />
          <div className="absolute -left-10 top-0 w-32 h-32 bg-white/5 rounded-full blur-2xl" />
          <span className="material-symbols-outlined absolute right-8 top-8 text-white/10 text-8xl rotate-12">auto_awesome</span>
        </div>
      </section>

      <section className="bg-white rounded-xl shadow-[0px_20px_40px_rgba(21,28,39,0.03)] overflow-hidden">
        <div className="p-10 flex flex-col lg:flex-row justify-between gap-4 lg:items-center">
          <div>
            <h3 className="text-xl font-bold text-on-surface">Đặt chỗ gần đây</h3>
            <p className="text-sm text-on-surface-variant mt-1">Theo dõi nhanh booking mới phát sinh từ dashboard</p>
          </div>
          <div className="flex items-center gap-3 flex-wrap">
            {[
              { value: 'all', label: 'Tất cả' },
              { value: 'paid', label: 'Đã thanh toán' },
              { value: 'pending', label: 'Chờ thanh toán' },
              { value: 'cancelled', label: 'Đã hủy' },
            ].map((item) => (
              <button key={item.value} onClick={() => setRecentStatus(item.value as 'all' | AdminRecentBooking['status'])} className={`px-4 py-2 rounded-full text-sm font-bold transition-all ${
                recentStatus === item.value
                  ? 'bg-surface-container text-on-surface'
                  : 'text-on-surface-variant hover:bg-surface-container-low'
              }`}>
                {item.label}
              </button>
            ))}
            <button onClick={exportRecentBookings} className="text-sm font-bold text-primary hover:underline cursor-pointer">Xuất CSV</button>
            <button onClick={() => navigate('/bookings')} className="text-sm font-bold text-primary flex items-center gap-1 hover:underline cursor-pointer">
              Xem tất cả
              <span className="material-symbols-outlined text-[18px]">arrow_right_alt</span>
            </button>
          </div>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-surface-container-low/50">
                <th className="px-10 py-5 text-[11px] font-black uppercase tracking-wider text-on-surface-variant/70">Mã đặt chỗ</th>
                <th className="px-6 py-5 text-[11px] font-black uppercase tracking-wider text-on-surface-variant/70">Tên khách hàng</th>
                <th className="px-6 py-5 text-[11px] font-black uppercase tracking-wider text-on-surface-variant/70">Điểm đến</th>
                <th className="px-6 py-5 text-[11px] font-black uppercase tracking-wider text-on-surface-variant/70">Tổng tiền</th>
                <th className="px-10 py-5 text-[11px] font-black uppercase tracking-wider text-on-surface-variant/70">Trạng thái thanh toán</th>
                <th className="px-10 py-5 text-[11px] font-black uppercase tracking-wider text-on-surface-variant/70 text-right">Hành động</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-outline-variant/10">
              {filteredBookings.map((booking) => {
                const status = statusConfig[booking.status];
                return (
                  <tr key={booking.id} className="hover:bg-surface-container-low/30 transition-colors group">
                    <td className="px-10 py-6 text-sm font-bold text-on-surface">{booking.id}</td>
                    <td className="px-6 py-6">
                      <div className="flex items-center gap-3">
                        <div className="w-8 h-8 rounded-full bg-surface-container-high flex items-center justify-center text-[10px] font-bold">
                          {booking.initials}
                        </div>
                        <span className="text-sm font-medium text-on-surface">{booking.name}</span>
                      </div>
                    </td>
                    <td className="px-6 py-6 text-sm text-on-surface-variant">{booking.destination}</td>
                    <td className="px-6 py-6 text-sm font-bold text-on-surface">{booking.amount}</td>
                    <td className="px-10 py-6">
                      <span className={`inline-flex items-center px-4 py-1 rounded-full text-[10px] font-black uppercase ${status.bgClass} ${status.textClass}`}>
                        {status.label}
                      </span>
                    </td>
                    <td className="px-10 py-6 text-right">
                      <button onClick={() => setSelectedBooking(booking)} className="px-4 py-2 rounded-full bg-surface-container-low text-on-surface text-xs font-bold hover:bg-surface-container transition-all">
                        Chi tiết
                      </button>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      </section>

      {selectedBooking && (
        <div className="bg-white rounded-xl shadow-[0px_20px_40px_rgba(21,28,39,0.03)] border border-surface-container-high/50 p-8">
          <div className="flex flex-col md:flex-row justify-between gap-6">
            <div>
              <p className="text-[10px] uppercase tracking-[0.2em] font-bold text-primary mb-2">Chi tiết booking gần đây</p>
              <h3 className="text-2xl font-black text-on-surface">{selectedBooking.id}</h3>
              <p className="text-on-surface-variant mt-2">{selectedBooking.name} • {selectedBooking.destination}</p>
            </div>
            <div className="flex gap-3">
              <button onClick={() => navigate('/bookings')} className="px-5 py-2.5 rounded-full bg-primary-container text-white font-bold hover:brightness-105 transition-all">
                Mở trang booking
              </button>
              <button onClick={() => setSelectedBooking(null)} className="px-5 py-2.5 rounded-full bg-surface-container-low text-on-surface font-bold hover:bg-surface-container transition-all">
                Đóng
              </button>
            </div>
          </div>
          <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mt-8">
            <div className="bg-surface-container-low rounded-2xl p-5">
              <p className="text-[11px] font-bold uppercase tracking-wider text-on-surface-variant">Khách hàng</p>
              <p className="text-sm font-bold text-on-surface mt-2">{selectedBooking.name}</p>
            </div>
            <div className="bg-surface-container-low rounded-2xl p-5">
              <p className="text-[11px] font-bold uppercase tracking-wider text-on-surface-variant">Điểm đến</p>
              <p className="text-sm font-bold text-on-surface mt-2">{selectedBooking.destination}</p>
            </div>
            <div className="bg-surface-container-low rounded-2xl p-5">
              <p className="text-[11px] font-bold uppercase tracking-wider text-on-surface-variant">Tổng tiền</p>
              <p className="text-sm font-bold text-on-surface mt-2">{selectedBooking.amount}</p>
            </div>
            <div className="bg-surface-container-low rounded-2xl p-5">
              <p className="text-[11px] font-bold uppercase tracking-wider text-on-surface-variant">Thanh toán</p>
              <p className="text-sm font-bold text-on-surface mt-2">{statusConfig[selectedBooking.status].label}</p>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
