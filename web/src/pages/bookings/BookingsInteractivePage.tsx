import { useEffect, useMemo, useState } from 'react';
import { adminService, type AdminBooking, type AdminBookingStats } from '../../services/adminService';
import { downloadCsv, getPageNumbers } from '../../utils/adminActions';

const PAGE_SIZE = 4;

const formatCompactCurrency = (value: number) =>
  `${new Intl.NumberFormat('en-US', {
    notation: 'compact',
    maximumFractionDigits: 1,
  }).format(value)}đ`;

const paymentStatusConfig: Record<
  AdminBooking['paymentStatus'],
  { label: string; className: string; dotClass: string }
> = {
  paid: {
    label: 'Paid',
    className: 'bg-[#10B981]/10 text-[#10B981]',
    dotClass: 'bg-[#10B981]',
  },
  pending: {
    label: 'Pending',
    className: 'bg-[#F97316]/10 text-[#F97316]',
    dotClass: 'bg-[#F97316]',
  },
  cancelled: {
    label: 'Cancelled',
    className: 'bg-[#6B7280]/10 text-[#6B7280]',
    dotClass: 'bg-[#6B7280]',
  },
};

function SummaryCard({
  icon,
  iconClass,
  trend,
  label,
  value,
}: {
  icon: string;
  iconClass: string;
  trend: string;
  label: string;
  value: string;
}) {
  return (
    <div className="bg-white p-8 rounded-xl shadow-[0px_20px_40px_rgba(21,28,39,0.03)] flex flex-col gap-4 border border-surface-container-high/50">
      <div className="flex items-center justify-between">
        <span
          className={`material-symbols-outlined p-3 rounded-2xl ${iconClass}`}
          style={{ fontVariationSettings: "'FILL' 1" }}
        >
          {icon}
        </span>
        <span className="text-xs font-bold text-primary flex items-center gap-1">
          <span className="material-symbols-outlined text-sm">trending_up</span> {trend}
        </span>
      </div>
      <div>
        <p className="text-[11px] font-bold text-on-surface-variant uppercase tracking-wider">
          {label}
        </p>
        <h3 className="text-3xl font-black text-on-surface mt-1">{value}</h3>
      </div>
    </div>
  );
}

export default function BookingsInteractivePage() {
  const [stats, setStats] = useState<AdminBookingStats | null>(null);
  const [loading, setLoading] = useState(true);
  const [statusTab, setStatusTab] = useState<'all' | AdminBooking['paymentStatus']>('all');
  const [currentPage, setCurrentPage] = useState(1);
  const [selectedBooking, setSelectedBooking] = useState<AdminBooking | null>(null);

  useEffect(() => {
    const fetchData = async () => {
      try {
        const data = await adminService.getBookingStats();
        setStats(data);
      } catch (error) {
        console.error('Failed to fetch booking stats:', error);
      } finally {
        setLoading(false);
      }
    };

    fetchData();
  }, []);

  useEffect(() => {
    setCurrentPage(1);
  }, [statusTab]);

  const filteredBookings = useMemo(() => {
    if (!stats) {
      return [];
    }

    return stats.bookings.filter((booking) => statusTab === 'all' || booking.paymentStatus === statusTab);
  }, [stats, statusTab]);

  const totalPages = Math.max(1, Math.ceil(filteredBookings.length / PAGE_SIZE));
  const currentPageClamped = Math.min(currentPage, totalPages);
  const paginatedBookings = filteredBookings.slice(
    (currentPageClamped - 1) * PAGE_SIZE,
    currentPageClamped * PAGE_SIZE
  );
  const pageNumbers = getPageNumbers(currentPageClamped, totalPages);

  const exportBookings = () => {
    downloadCsv(
      `bookings-${statusTab}.csv`,
      filteredBookings,
      [
        { key: 'displayId', header: 'Mã booking' },
        { key: 'userName', header: 'Khách hàng' },
        { key: 'userCode', header: 'Mã người dùng' },
        { key: 'destination', header: 'Điểm đến' },
        { key: 'totalAmount', header: 'Tổng tiền' },
        { key: 'summary', header: 'Tóm tắt' },
        {
          key: 'paymentStatus',
          header: 'Thanh toán',
          accessor: (booking) => paymentStatusConfig[booking.paymentStatus].label,
        },
        { key: 'tripStatus', header: 'Trạng thái chuyến' },
        { key: 'createdAt', header: 'Tạo lúc' },
      ]
    );
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-full min-h-[50vh]">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary"></div>
      </div>
    );
  }

  if (!stats) {
    return <div className="text-center text-error mt-10">Không thể tải dữ liệu đặt chỗ.</div>;
  }

  const paidRatio =
    stats.totalBookings === 0 ? 0 : Math.round((stats.paidBookings / stats.totalBookings) * 100);
  const pendingRatio =
    stats.totalBookings === 0 ? 0 : Math.round((stats.pendingBookings / stats.totalBookings) * 100);

  return (
    <div className="space-y-10">
      <div className="flex flex-col md:flex-row md:items-end justify-between gap-6">
        <div>
          <span className="text-[10px] font-bold uppercase tracking-[0.2em] text-primary mb-2 block">
            Hệ thống quản lý
          </span>
          <h2 className="text-4xl font-black text-on-surface tracking-tight">Danh sách Đặt chỗ</h2>
          <p className="text-on-surface-variant mt-3 max-w-2xl">
            Theo dõi giao dịch chuyến đi, tình trạng thanh toán và tốc độ tăng trưởng khách hàng mới trên toàn hệ thống.
          </p>
        </div>
        <div className="flex items-center gap-3 bg-surface-container-low p-1.5 rounded-full flex-wrap">
          {[
            { value: 'all', label: `Tất cả (${stats.totalBookings})` },
            { value: 'paid', label: `Đã thanh toán (${stats.paidBookings})` },
            { value: 'pending', label: `Chờ xử lý (${stats.pendingBookings})` },
            { value: 'cancelled', label: `Đã hủy (${stats.cancelledBookings})` },
          ].map((item) => (
            <button
              key={item.value}
              onClick={() => setStatusTab(item.value as 'all' | AdminBooking['paymentStatus'])}
              className={`px-6 py-2.5 rounded-full text-sm transition-all ${
                statusTab === item.value
                  ? 'bg-white shadow-sm font-bold text-on-surface'
                  : 'hover:bg-white/50 font-medium text-on-surface-variant'
              }`}
            >
              {item.label}
            </button>
          ))}
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <SummaryCard
          icon="payments"
          iconClass="bg-primary/10 text-primary"
          trend={`${paidRatio}%`}
          label="Tổng doanh thu"
          value={formatCompactCurrency(stats.totalRevenue)}
        />
        <SummaryCard
          icon="confirmation_number"
          iconClass="bg-secondary-container/10 text-secondary-container"
          trend={`${stats.pendingBookings} chờ`}
          label="Tổng lượt đặt"
          value={`${stats.totalBookings.toLocaleString()} Chuyến`}
        />
        <SummaryCard
          icon="group"
          iconClass="bg-tertiary/10 text-tertiary"
          trend={`+${stats.newCustomers}`}
          label="Khách hàng mới"
          value={`${stats.newCustomers.toLocaleString()} Thành viên`}
        />
      </div>

      <div className="bg-white rounded-xl shadow-[0px_40px_80px_rgba(21,28,39,0.04)] overflow-hidden border border-surface-container-high/40">
        <div className="px-10 py-8 border-b border-surface-container flex items-center justify-between">
          <div>
            <h4 className="text-lg font-bold text-on-surface">Lịch sử giao dịch</h4>
            <p className="text-sm text-on-surface-variant mt-1">
              Hiển thị {filteredBookings.length} booking phù hợp bộ lọc đang chọn
            </p>
          </div>
          <button
            onClick={exportBookings}
            className="flex items-center gap-2 text-sm font-bold text-primary hover:underline"
          >
            Xuất báo cáo <span className="material-symbols-outlined text-base">download</span>
          </button>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-surface-container-low/50">
                <th className="px-10 py-5 text-[11px] font-bold text-on-surface-variant uppercase tracking-widest">Tên người dùng</th>
                <th className="px-10 py-5 text-[11px] font-bold text-on-surface-variant uppercase tracking-widest">Điểm đến</th>
                <th className="px-10 py-5 text-[11px] font-bold text-on-surface-variant uppercase tracking-widest text-right">Tổng tiền</th>
                <th className="px-10 py-5 text-[11px] font-bold text-on-surface-variant uppercase tracking-widest text-center">Trạng thái thanh toán</th>
                <th className="px-10 py-5 text-[11px] font-bold text-on-surface-variant uppercase tracking-widest text-center">Hành động</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-surface-container-high/30">
              {paginatedBookings.map((booking) => {
                const status = paymentStatusConfig[booking.paymentStatus];
                const initials = booking.userName
                  .split(' ')
                  .filter(Boolean)
                  .slice(0, 2)
                  .map((part) => part[0]?.toUpperCase() ?? '')
                  .join('');

                return (
                  <tr key={booking.id} className="hover:bg-surface-container-low/30 transition-all">
                    <td className="px-10 py-6">
                      <div className="flex items-center gap-4">
                        <div className="w-10 h-10 rounded-full bg-primary-container/15 text-primary flex items-center justify-center font-bold text-sm">
                          {initials || 'U'}
                        </div>
                        <div>
                          <p className="font-bold text-on-surface">{booking.userName}</p>
                          <p className="text-[10px] text-on-surface-variant tracking-wider">
                            {booking.userCode}
                          </p>
                        </div>
                      </div>
                    </td>
                    <td className="px-10 py-6">
                      <div className="flex items-start gap-2">
                        <span className="material-symbols-outlined text-primary text-lg">
                          location_on
                        </span>
                        <div>
                          <span className="font-medium text-on-surface">{booking.destination}</span>
                          <p className="text-[10px] text-on-surface-variant mt-1">{booking.createdAt}</p>
                        </div>
                      </div>
                    </td>
                    <td className="px-10 py-6 text-right">
                      <p className="font-bold text-on-surface">{booking.totalAmount}</p>
                      <p className="text-[10px] text-on-surface-variant">{booking.summary}</p>
                    </td>
                    <td className="px-10 py-6 text-center">
                      <span className={`inline-flex items-center px-4 py-1.5 rounded-full text-[11px] font-bold tracking-wide ${status.className}`}>
                        <span className={`w-1.5 h-1.5 rounded-full mr-2 ${status.dotClass}`}></span>
                        {status.label}
                      </span>
                    </td>
                    <td className="px-10 py-6 text-center">
                      <button
                        onClick={() => setSelectedBooking(booking)}
                        className="p-2 hover:bg-surface-container rounded-full transition-all text-on-surface-variant"
                      >
                        <span className="material-symbols-outlined">more_horiz</span>
                      </button>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
        <div className="px-10 py-8 bg-surface-container-low/20 flex items-center justify-between">
          <p className="text-xs text-on-surface-variant font-medium">
            Hiển thị <span className="text-on-surface font-bold">{paginatedBookings.length}</span> trên <span className="text-on-surface font-bold">{filteredBookings.length}</span> giao dịch
          </p>
          <div className="flex items-center gap-2">
            <button
              onClick={() => setCurrentPage((page) => Math.max(1, page - 1))}
              disabled={currentPageClamped === 1}
              className="w-10 h-10 rounded-full border border-surface-container flex items-center justify-center hover:bg-white transition-all disabled:opacity-40 disabled:cursor-not-allowed"
            >
              <span className="material-symbols-outlined text-sm">chevron_left</span>
            </button>
            {pageNumbers.map((page) => (
              <button
                key={page}
                onClick={() => setCurrentPage(page)}
                className={`w-10 h-10 rounded-full flex items-center justify-center font-bold text-xs transition-all ${
                  page === currentPageClamped
                    ? 'bg-primary text-white shadow-md shadow-primary/20'
                    : 'border border-surface-container hover:bg-white'
                }`}
              >
                {page}
              </button>
            ))}
            <button
              onClick={() => setCurrentPage((page) => Math.min(totalPages, page + 1))}
              disabled={currentPageClamped === totalPages}
              className="w-10 h-10 rounded-full border border-surface-container flex items-center justify-center hover:bg-white transition-all disabled:opacity-40 disabled:cursor-not-allowed"
            >
              <span className="material-symbols-outlined text-sm">chevron_right</span>
            </button>
          </div>
        </div>
      </div>

      {selectedBooking && (
        <div className="bg-white rounded-xl shadow-[0px_20px_40px_rgba(21,28,39,0.04)] border border-surface-container-high/40 p-8">
          <div className="flex flex-col md:flex-row justify-between gap-6">
            <div>
              <p className="text-[10px] uppercase font-black tracking-[0.2em] text-primary mb-2">
                Chi tiết booking
              </p>
              <h4 className="text-2xl font-black text-on-surface">{selectedBooking.displayId}</h4>
              <p className="text-on-surface-variant mt-2">
                {selectedBooking.userName} • {selectedBooking.destination}
              </p>
            </div>
            <button
              onClick={() => setSelectedBooking(null)}
              className="px-5 py-2.5 rounded-full bg-primary text-white font-bold hover:brightness-105 transition-all self-start"
            >
              Đóng
            </button>
          </div>
          <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mt-8">
            <div className="bg-surface-container-low rounded-2xl p-5">
              <p className="text-[11px] font-bold uppercase tracking-wider text-on-surface-variant">Khách hàng</p>
              <p className="text-sm font-bold text-on-surface mt-2">{selectedBooking.userName}</p>
              <p className="text-xs text-on-surface-variant mt-1">{selectedBooking.userCode}</p>
            </div>
            <div className="bg-surface-container-low rounded-2xl p-5">
              <p className="text-[11px] font-bold uppercase tracking-wider text-on-surface-variant">Thanh toán</p>
              <p className="text-sm font-bold text-on-surface mt-2">{paymentStatusConfig[selectedBooking.paymentStatus].label}</p>
              <p className="text-xs text-on-surface-variant mt-1">Trip: {selectedBooking.tripStatus}</p>
            </div>
            <div className="bg-surface-container-low rounded-2xl p-5">
              <p className="text-[11px] font-bold uppercase tracking-wider text-on-surface-variant">Giá trị</p>
              <p className="text-sm font-bold text-on-surface mt-2">{selectedBooking.totalAmount}</p>
              <p className="text-xs text-on-surface-variant mt-1">{selectedBooking.summary}</p>
            </div>
            <div className="bg-surface-container-low rounded-2xl p-5">
              <p className="text-[11px] font-bold uppercase tracking-wider text-on-surface-variant">Khởi tạo</p>
              <p className="text-sm font-bold text-on-surface mt-2">{selectedBooking.createdAt}</p>
              <p className="text-xs text-on-surface-variant mt-1">{selectedBooking.destination}</p>
            </div>
          </div>
        </div>
      )}

      <div className="flex flex-col md:flex-row justify-between items-center gap-10 mt-10 opacity-70">
        <div className="text-left">
          <p className="text-[10px] uppercase font-black tracking-widest text-on-surface mb-2">
            Hệ thống booking Skynet
          </p>
          <p className="text-xs max-w-xs leading-relaxed">
            Dữ liệu thanh toán được đồng bộ theo thời gian thực từ giao dịch chuyến đi và trạng thái xử lý booking của khách hàng.
          </p>
        </div>
        <div className="flex gap-8">
          <div className="text-center">
            <p className="text-2xl font-black text-on-surface">{paidRatio}%</p>
            <p className="text-[9px] uppercase tracking-tighter font-bold">Tỉ lệ đã thanh toán</p>
          </div>
          <div className="text-center border-l border-surface-container-high pl-8">
            <p className="text-2xl font-black text-on-surface">{pendingRatio}%</p>
            <p className="text-[9px] uppercase tracking-tighter font-bold">Booking chờ xử lý</p>
          </div>
          <div className="text-center border-l border-surface-container-high pl-8">
            <p className="text-2xl font-black text-on-surface">{stats.cancelledBookings}</p>
            <p className="text-[9px] uppercase tracking-tighter font-bold">Đã hủy / thất bại</p>
          </div>
        </div>
      </div>
    </div>
  );
}
