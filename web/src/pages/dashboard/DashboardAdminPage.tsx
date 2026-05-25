import { useEffect, useMemo, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAdminSearch, useToast } from '../../context';
import {
  adminService,
  type AdminDashboardStats,
  type AdminRecentBooking,
} from '../../services/adminService';
import { downloadCsv } from '../../utils/adminActions';
import { getErrorMessage } from '../../utils/http';

const statusConfig = {
  paid: { label: 'Đã thanh toán', bgClass: 'bg-[#10B981]/10', textClass: 'text-[#10B981]' },
  pending: { label: 'Chờ thanh toán', bgClass: 'bg-[#F97316]/10', textClass: 'text-[#F97316]' },
  cancelled: { label: 'Đã hủy', bgClass: 'bg-[#6B7280]/10', textClass: 'text-[#6B7280]' },
};

const formatCompactNumber = (number: number) =>
  new Intl.NumberFormat('en-US', { notation: 'compact', maximumFractionDigits: 1 }).format(number);

const formatDateInput = (date: Date) => date.toISOString().slice(0, 10);

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

export default function DashboardAdminPage() {
  const navigate = useNavigate();
  const { query } = useAdminSearch();
  const { showToast } = useToast();
  const [stats, setStats] = useState<AdminDashboardStats | null>(null);
  const [loading, setLoading] = useState(true);
  const [recentStatus, setRecentStatus] = useState<'all' | AdminRecentBooking['status']>('all');
  const [selectedBooking, setSelectedBooking] = useState<AdminRecentBooking | null>(null);
  const [range, setRange] = useState(() => {
    const today = new Date();
    const start = new Date(today);
    start.setMonth(today.getMonth() - 5);
    return {
      startDate: formatDateInput(start),
      endDate: formatDateInput(today),
    };
  });

  const loadDashboard = async (params = range) => {
    const data = await adminService.getDashboardStats(params);
    setStats(data);
  };

  useEffect(() => {
    const fetchData = async () => {
      try {
        await loadDashboard();
      } catch (error) {
        showToast({
          type: 'error',
          title: 'Không thể tải dashboard',
          message: getErrorMessage(error),
        });
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

    const keyword = query.trim().toLowerCase();

    return stats.recentBookings.filter((booking) => {
      const matchesStatus = recentStatus === 'all' || booking.status === recentStatus;
      const matchesKeyword =
        keyword.length === 0 ||
        booking.id.toLowerCase().includes(keyword) ||
        booking.name.toLowerCase().includes(keyword) ||
        booking.destination.toLowerCase().includes(keyword);

      return matchesStatus && matchesKeyword;
    });
  }, [query, recentStatus, stats]);

  const exportRecentBookings = () => {
    downloadCsv(`dashboard-recent-bookings-${recentStatus}.csv`, filteredBookings, [
      { key: 'id', header: 'Mã đặt chỗ' },
      { key: 'name', header: 'Khách hàng' },
      { key: 'destination', header: 'Điểm đến' },
      { key: 'amount', header: 'Tổng tiền' },
      { key: 'status', header: 'Trạng thái' },
    ]);

    showToast({
      type: 'success',
      title: 'Đã xuất dữ liệu',
      message: 'Danh sách booking gần đây đã được tải xuống dạng CSV.',
    });
  };

  const handleApplyRange = async () => {
    try {
      setLoading(true);
      await loadDashboard(range);
      showToast({
        type: 'success',
        title: 'Đã áp dụng khoảng thời gian',
        message: `Dữ liệu từ ${range.startDate} đến ${range.endDate} đã được đồng bộ.`,
      });
    } catch (error) {
      showToast({
        type: 'error',
        title: 'Không thể lọc dashboard',
        message: getErrorMessage(error),
      });
    } finally {
      setLoading(false);
    }
  };

  const setQuickRange = async (months: number) => {
    const endDate = new Date();
    const startDate = new Date(endDate);
    startDate.setMonth(endDate.getMonth() - months);
    const nextRange = {
      startDate: formatDateInput(startDate),
      endDate: formatDateInput(endDate),
    };
    setRange(nextRange);

    try {
      setLoading(true);
      await loadDashboard(nextRange);
    } catch (error) {
      showToast({
        type: 'error',
        title: 'Không thể đổi khoảng thời gian',
        message: getErrorMessage(error),
      });
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return <div className="flex items-center justify-center h-full min-h-[50vh]"><div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary"></div></div>;
  }

  if (!stats) {
    return <div className="text-center text-error mt-10">Không thể tải dữ liệu dashboard.</div>;
  }

  const maxChartValue = Math.max(
    ...stats.chartSeries.flatMap((item) => [item.revenue, item.profit]),
    1
  );

  return (
    <div className="space-y-10">
      <section className="flex flex-col xl:flex-row xl:items-end justify-between gap-6">
        <div>
          <p className="text-[11px] font-black uppercase tracking-[0.25em] text-primary">Dashboard vận hành</p>
          <h1 className="mt-3 text-5xl font-black tracking-tight text-on-surface">Bảng điều khiển tổng hợp</h1>
          <p className="mt-4 max-w-3xl text-sm leading-7 text-on-surface-variant">
            Theo dõi doanh thu, lợi nhuận, booking mới và dòng hoạt động mới nhất trên toàn bộ hệ thống admin.
          </p>
        </div>

        <div className="rounded-[2rem] bg-white p-4 shadow-[0px_20px_40px_rgba(21,28,39,0.04)] ring-1 ring-outline-variant/10">
          <div className="grid grid-cols-1 gap-3 md:grid-cols-[1fr_1fr_auto]">
            <input
              type="date"
              value={range.startDate}
              onChange={(event) => setRange((current) => ({ ...current, startDate: event.target.value }))}
              className="rounded-full bg-surface-container-low px-5 py-3 text-sm font-medium outline-none"
            />
            <input
              type="date"
              value={range.endDate}
              onChange={(event) => setRange((current) => ({ ...current, endDate: event.target.value }))}
              className="rounded-full bg-surface-container-low px-5 py-3 text-sm font-medium outline-none"
            />
            <button
              onClick={handleApplyRange}
              className="rounded-full bg-primary-container px-6 py-3 text-sm font-bold text-white transition-all hover:brightness-110"
            >
              Áp dụng
            </button>
          </div>
          <div className="mt-3 flex flex-wrap gap-2">
            <button onClick={() => setQuickRange(2)} className="rounded-full bg-surface-container-low px-4 py-2 text-xs font-bold text-on-surface hover:bg-surface-container">3 tháng</button>
            <button onClick={() => setQuickRange(5)} className="rounded-full bg-surface-container-low px-4 py-2 text-xs font-bold text-on-surface hover:bg-surface-container">6 tháng</button>
            <span className="rounded-full bg-primary-container/10 px-4 py-2 text-xs font-bold text-primary">
              API: {stats.startDate} → {stats.endDate}
            </span>
          </div>
        </div>
      </section>

      <section className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-6">
        <MetricCard label="Doanh thu trong kỳ" value={`${formatCompactNumber(stats.totalRevenue)}đ`} helper="Đi tới Booking để kiểm tra từng giao dịch chi tiết." icon="payments" iconClass="bg-tertiary-fixed text-on-tertiary-container" onClick={() => navigate('/bookings')} />
        <MetricCard label="Lợi nhuận trong kỳ" value={`${formatCompactNumber(stats.totalProfit)}đ`} helper="Đi tới Vận tải để kiểm tra hiệu suất affiliate theo lịch." icon="account_balance_wallet" iconClass="bg-primary-container/10 text-primary-container" onClick={() => navigate('/transport')} />
        <MetricCard label="Tổng người dùng" value={stats.totalUsers.toLocaleString()} helper={`+${stats.newUsersToday} người dùng mới hôm nay.`} icon="group" iconClass="bg-surface-container text-on-surface" onClick={() => navigate('/users')} />
        <MetricCard label="Chuyến đi đang xử lý" value={stats.activeTrips.toString()} helper="Booking pending/paid đang cần theo dõi vận hành." icon="travel_explore" iconClass="bg-secondary-fixed text-secondary" onClick={() => navigate('/bookings')} />
      </section>

      <section className="grid grid-cols-1 xl:grid-cols-[1.65fr_0.85fr] gap-8">
        <div className="rounded-[2rem] bg-white p-8 shadow-[0px_20px_40px_rgba(21,28,39,0.04)] ring-1 ring-outline-variant/10">
          <div className="flex flex-col md:flex-row md:items-end justify-between gap-4 mb-8">
            <div>
              <h2 className="text-2xl font-black text-on-surface">Biểu đồ doanh thu động</h2>
              <p className="mt-2 text-sm text-on-surface-variant">Chart đang lấy trực tiếp từ API admin theo khoảng ngày bạn chọn.</p>
            </div>
            <div className="flex items-center gap-3 text-xs font-bold">
              <span className="inline-flex items-center gap-2 rounded-full bg-surface-container-low px-4 py-2 text-on-surface-variant">
                <span className="h-2 w-2 rounded-full bg-tertiary"></span> Doanh thu
              </span>
              <span className="inline-flex items-center gap-2 rounded-full bg-surface-container-low px-4 py-2 text-on-surface-variant">
                <span className="h-2 w-2 rounded-full bg-primary-container"></span> Lợi nhuận
              </span>
            </div>
          </div>

          <div className="flex min-h-[320px] items-end gap-3 overflow-x-auto rounded-[1.75rem] bg-surface-container-low px-6 py-8">
            {stats.chartSeries.map((point) => (
              <div key={point.label} className="min-w-[72px] flex-1 text-center">
                <div className="mx-auto flex h-56 items-end justify-center gap-2">
                  <div className="w-5 rounded-t-2xl bg-tertiary/70 transition-all" style={{ height: `${Math.max(10, (point.revenue / maxChartValue) * 100)}%` }}></div>
                  <div className="w-5 rounded-t-2xl bg-primary-container transition-all" style={{ height: `${Math.max(10, (point.profit / maxChartValue) * 100)}%` }}></div>
                </div>
                <p className="mt-3 text-[10px] font-black uppercase tracking-widest text-on-surface-variant">{point.label}</p>
                <p className="mt-2 text-xs font-semibold text-on-surface">{point.bookings} booking</p>
              </div>
            ))}
          </div>
        </div>

        <div className="rounded-[2rem] bg-on-surface p-8 text-white shadow-[0px_20px_40px_rgba(21,28,39,0.14)]">
          <div className="flex items-center justify-between gap-4">
            <div>
              <p className="text-[11px] font-black uppercase tracking-[0.25em] text-primary-fixed">Activity Feed</p>
              <h2 className="mt-3 text-2xl font-black">Luồng hoạt động mới nhất</h2>
            </div>
            <span className="material-symbols-outlined rounded-2xl bg-white/10 p-3 text-primary-fixed">event_upcoming</span>
          </div>

          <div className="mt-8 space-y-4">
            {stats.activityFeed.length === 0 ? (
              <p className="text-sm text-white/70">Chưa có hoạt động mới trong khoảng thời gian đã chọn.</p>
            ) : (
              stats.activityFeed.map((item) => (
                <div key={item.id} className="rounded-[1.5rem] bg-white/5 p-4 ring-1 ring-white/10">
                  <div className="flex items-start gap-3">
                    <span className="material-symbols-outlined rounded-2xl bg-white/10 p-2 text-primary-fixed">
                      {item.type === 'user' ? 'person_add' : item.type === 'booking' ? 'confirmation_number' : 'payments'}
                    </span>
                    <div>
                      <p className="text-sm font-bold">{item.title}</p>
                      <p className="mt-1 text-xs leading-6 text-white/70">{item.description}</p>
                      <p className="mt-2 text-[10px] font-black uppercase tracking-[0.2em] text-white/45">{item.occurredAt}</p>
                    </div>
                  </div>
                </div>
              ))
            )}
          </div>
        </div>
      </section>

      <section className="rounded-[2rem] bg-white shadow-[0px_20px_40px_rgba(21,28,39,0.04)] ring-1 ring-outline-variant/10 overflow-hidden">
        <div className="flex flex-col lg:flex-row justify-between gap-4 px-8 py-8">
          <div>
            <h2 className="text-2xl font-black text-on-surface">Booking gần đây</h2>
            <p className="mt-2 text-sm text-on-surface-variant">Tìm theo mã, tên khách hoặc điểm đến ngay từ ô search trên top bar.</p>
          </div>
          <div className="flex flex-wrap items-center gap-3">
            {[
              { value: 'all', label: 'Tất cả' },
              { value: 'paid', label: 'Đã thanh toán' },
              { value: 'pending', label: 'Chờ thanh toán' },
              { value: 'cancelled', label: 'Đã hủy' },
            ].map((item) => (
              <button
                key={item.value}
                onClick={() => setRecentStatus(item.value as 'all' | AdminRecentBooking['status'])}
                className={`rounded-full px-4 py-2 text-sm font-bold transition-all ${
                  recentStatus === item.value ? 'bg-surface-container text-on-surface' : 'text-on-surface-variant hover:bg-surface-container-low'
                }`}
              >
                {item.label}
              </button>
            ))}
            <button onClick={exportRecentBookings} className="rounded-full bg-primary-container px-5 py-2.5 text-sm font-bold text-white">Xuất CSV</button>
          </div>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-surface-container-low/50">
                <th className="px-8 py-5 text-[11px] font-black uppercase tracking-widest text-on-surface-variant">Mã đặt chỗ</th>
                <th className="px-6 py-5 text-[11px] font-black uppercase tracking-widest text-on-surface-variant">Khách hàng</th>
                <th className="px-6 py-5 text-[11px] font-black uppercase tracking-widest text-on-surface-variant">Điểm đến</th>
                <th className="px-6 py-5 text-[11px] font-black uppercase tracking-widest text-on-surface-variant">Tổng tiền</th>
                <th className="px-6 py-5 text-[11px] font-black uppercase tracking-widest text-on-surface-variant">Thanh toán</th>
                <th className="px-8 py-5 text-[11px] font-black uppercase tracking-widest text-on-surface-variant text-right">Hành động</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-outline-variant/10">
              {filteredBookings.map((booking) => {
                const status = statusConfig[booking.status];
                return (
                  <tr key={booking.id} className="hover:bg-surface-container-low/30 transition-colors">
                    <td className="px-8 py-6 text-sm font-bold text-on-surface">{booking.id}</td>
                    <td className="px-6 py-6">
                      <div className="flex items-center gap-3">
                        <div className="flex h-9 w-9 items-center justify-center rounded-full bg-surface-container-high text-xs font-black text-on-surface">
                          {booking.initials}
                        </div>
                        <span className="text-sm font-medium text-on-surface">{booking.name}</span>
                      </div>
                    </td>
                    <td className="px-6 py-6 text-sm text-on-surface-variant">{booking.destination}</td>
                    <td className="px-6 py-6 text-sm font-bold text-on-surface">{booking.amount}</td>
                    <td className="px-6 py-6">
                      <span className={`inline-flex rounded-full px-4 py-1.5 text-xs font-bold ${status.bgClass} ${status.textClass}`}>{status.label}</span>
                    </td>
                    <td className="px-8 py-6 text-right">
                      <button onClick={() => setSelectedBooking(booking)} className="rounded-full bg-surface-container-low px-4 py-2 text-xs font-bold text-on-surface transition-all hover:bg-surface-container">
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

      {selectedBooking ? (
        <section className="rounded-[2rem] bg-white p-8 shadow-[0px_20px_40px_rgba(21,28,39,0.04)] ring-1 ring-outline-variant/10">
          <div className="flex flex-col md:flex-row justify-between gap-6">
            <div>
              <p className="text-[11px] font-black uppercase tracking-[0.25em] text-primary">Booking được chọn</p>
              <h2 className="mt-3 text-3xl font-black text-on-surface">{selectedBooking.id}</h2>
              <p className="mt-2 text-sm text-on-surface-variant">{selectedBooking.name} • {selectedBooking.destination}</p>
            </div>
            <div className="flex gap-3">
              <button onClick={() => navigate('/bookings')} className="rounded-full bg-primary-container px-6 py-3 text-sm font-bold text-white">Mở trang booking</button>
              <button onClick={() => setSelectedBooking(null)} className="rounded-full bg-surface-container-low px-6 py-3 text-sm font-bold text-on-surface">Đóng</button>
            </div>
          </div>
        </section>
      ) : null}
    </div>
  );
}
