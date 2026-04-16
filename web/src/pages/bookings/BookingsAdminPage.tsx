import { useEffect, useMemo, useState } from 'react';
import { useAdminSearch, useToast } from '../../context';
import {
  adminService,
  type AdminBooking,
  type AdminBookingDetail,
  type AdminBookingStats,
  type AdminUpdateBookingStatusRequest,
} from '../../services/adminService';
import { downloadCsv, getPageNumbers } from '../../utils/adminActions';
import { getErrorMessage } from '../../utils/http';

const PAGE_SIZE = 6;

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

const formatCompactCurrency = (value: number) =>
  `${new Intl.NumberFormat('en-US', { notation: 'compact', maximumFractionDigits: 1 }).format(value)}đ`;

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
        <span className={`material-symbols-outlined p-3 rounded-2xl ${iconClass}`} style={{ fontVariationSettings: "'FILL' 1" }}>
          {icon}
        </span>
        <span className="text-xs font-bold text-primary flex items-center gap-1">
          <span className="material-symbols-outlined text-sm">trending_up</span> {trend}
        </span>
      </div>
      <div>
        <p className="text-[11px] font-bold text-on-surface-variant uppercase tracking-wider">{label}</p>
        <h3 className="text-3xl font-black text-on-surface mt-1">{value}</h3>
      </div>
    </div>
  );
}

export default function BookingsAdminPage() {
  const { query } = useAdminSearch();
  const { showToast } = useToast();
  const [stats, setStats] = useState<AdminBookingStats | null>(null);
  const [loading, setLoading] = useState(true);
  const [statusTab, setStatusTab] = useState<'all' | AdminBooking['paymentStatus']>('all');
  const [currentPage, setCurrentPage] = useState(1);
  const [selectedBooking, setSelectedBooking] = useState<AdminBooking | null>(null);
  const [detail, setDetail] = useState<AdminBookingDetail | null>(null);
  const [detailLoading, setDetailLoading] = useState(false);
  const [actionLoading, setActionLoading] = useState(false);

  const loadBookings = async () => {
    const data = await adminService.getBookingStats();
    setStats(data);
  };

  useEffect(() => {
    const fetchData = async () => {
      try {
        await loadBookings();
      } catch (error) {
        showToast({
          type: 'error',
          title: 'Không thể tải dữ liệu booking',
          message: getErrorMessage(error),
        });
      } finally {
        setLoading(false);
      }
    };

    fetchData();
  }, []);

  useEffect(() => {
    setCurrentPage(1);
  }, [statusTab, query]);

  const filteredBookings = useMemo(() => {
    if (!stats) {
      return [];
    }

    const keyword = query.trim().toLowerCase();

    return stats.bookings.filter((booking) => {
      const matchesStatus = statusTab === 'all' || booking.paymentStatus === statusTab;
      const matchesKeyword =
        keyword.length === 0 ||
        booking.displayId.toLowerCase().includes(keyword) ||
        booking.userName.toLowerCase().includes(keyword) ||
        booking.userCode.toLowerCase().includes(keyword) ||
        booking.destination.toLowerCase().includes(keyword);

      return matchesStatus && matchesKeyword;
    });
  }, [query, stats, statusTab]);

  const totalPages = Math.max(1, Math.ceil(filteredBookings.length / PAGE_SIZE));
  const currentPageClamped = Math.min(currentPage, totalPages);
  const paginatedBookings = filteredBookings.slice((currentPageClamped - 1) * PAGE_SIZE, currentPageClamped * PAGE_SIZE);
  const pageNumbers = getPageNumbers(currentPageClamped, totalPages);

  const exportBookings = () => {
    downloadCsv(`bookings-${statusTab}.csv`, filteredBookings, [
      { key: 'displayId', header: 'Mã booking' },
      { key: 'userName', header: 'Khách hàng' },
      { key: 'userCode', header: 'Mã người dùng' },
      { key: 'destination', header: 'Điểm đến' },
      { key: 'totalAmount', header: 'Tổng tiền' },
      { key: 'summary', header: 'Tóm tắt' },
      { key: 'paymentStatus', header: 'Thanh toán' },
      { key: 'tripStatus', header: 'Trạng thái chuyến' },
      { key: 'createdAt', header: 'Tạo lúc' },
    ]);

    showToast({
      type: 'success',
      title: 'Đã xuất báo cáo booking',
      message: 'Dữ liệu booking đã được tải xuống dạng CSV.',
    });
  };

  const openBooking = async (booking: AdminBooking) => {
    setSelectedBooking(booking);
    setDetail(null);
    setDetailLoading(true);

    try {
      const payload = await adminService.getBookingDetail(booking.id);
      setDetail(payload);
    } catch (error) {
      showToast({
        type: 'error',
        title: 'Không thể tải chi tiết booking',
        message: getErrorMessage(error),
      });
    } finally {
      setDetailLoading(false);
    }
  };

  const updateStatus = async (payload: AdminUpdateBookingStatusRequest) => {
    if (!selectedBooking) {
      return;
    }

    setActionLoading(true);
    try {
      await adminService.updateBookingStatus(selectedBooking.id, payload);
      await loadBookings();
      const refreshedDetail = await adminService.getBookingDetail(selectedBooking.id);
      setDetail(refreshedDetail);
      setSelectedBooking((current) =>
        current
          ? {
              ...current,
              paymentStatus: refreshedDetail.paymentStatus,
              tripStatus: refreshedDetail.tripStatus,
            }
          : current
      );

      showToast({
        type: 'success',
        title: 'Đã cập nhật booking',
        message: 'Trạng thái booking và thanh toán đã được đồng bộ.',
      });
    } catch (error) {
      showToast({
        type: 'error',
        title: 'Không thể cập nhật trạng thái',
        message: getErrorMessage(error),
      });
    } finally {
      setActionLoading(false);
    }
  };

  if (loading) {
    return <div className="flex items-center justify-center h-full min-h-[50vh]"><div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary"></div></div>;
  }

  if (!stats) {
    return <div className="text-center text-error mt-10">Không thể tải dữ liệu đặt chỗ.</div>;
  }

  const paidRatio = stats.totalBookings === 0 ? 0 : Math.round((stats.paidBookings / stats.totalBookings) * 100);
  const pendingRatio = stats.totalBookings === 0 ? 0 : Math.round((stats.pendingBookings / stats.totalBookings) * 100);

  return (
    <div className="space-y-10">
      <div className="flex flex-col xl:flex-row xl:items-end justify-between gap-6">
        <div>
          <span className="text-[10px] font-bold uppercase tracking-[0.2em] text-primary mb-2 block">Hệ thống quản lý</span>
          <h1 className="text-4xl font-black text-on-surface tracking-tight">Danh sách đặt chỗ</h1>
          <p className="text-on-surface-variant mt-3 max-w-3xl">
            Tìm kiếm theo mã booking từ ô search trên top bar, đổi trạng thái thanh toán, hoàn tiền và xem sâu lịch trình, dịch vụ, lịch sử gateway.
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
        <SummaryCard icon="payments" iconClass="bg-primary/10 text-primary" trend={`${paidRatio}%`} label="Tổng doanh thu" value={formatCompactCurrency(stats.totalRevenue)} />
        <SummaryCard icon="confirmation_number" iconClass="bg-secondary-container/10 text-secondary-container" trend={`${stats.pendingBookings} chờ`} label="Tổng lượt đặt" value={`${stats.totalBookings.toLocaleString()} Booking`} />
        <SummaryCard icon="group" iconClass="bg-tertiary/10 text-tertiary" trend={`+${stats.newCustomers}`} label="Khách hàng mới" value={`${stats.newCustomers.toLocaleString()} Thành viên`} />
      </div>

      <div className="bg-white rounded-[2rem] shadow-[0px_40px_80px_rgba(21,28,39,0.04)] overflow-hidden border border-surface-container-high/40">
        <div className="px-10 py-8 border-b border-surface-container flex items-center justify-between">
          <div>
            <h2 className="text-lg font-black text-on-surface">Lịch sử giao dịch</h2>
            <p className="text-sm text-on-surface-variant mt-1">Hiển thị {filteredBookings.length} booking phù hợp bộ lọc hiện tại.</p>
          </div>
          <button onClick={exportBookings} className="flex items-center gap-2 text-sm font-bold text-primary hover:underline">
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
                          <p className="text-[10px] text-on-surface-variant tracking-wider">{booking.displayId} • {booking.userCode}</p>
                        </div>
                      </div>
                    </td>
                    <td className="px-10 py-6">
                      <div className="flex items-start gap-2">
                        <span className="material-symbols-outlined text-primary text-lg">location_on</span>
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
                      <button onClick={() => openBooking(booking)} className="p-2 hover:bg-surface-container rounded-full transition-all text-on-surface-variant">
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
          <p className="text-xs text-on-surface-variant font-medium">Hiển thị <span className="text-on-surface font-bold">{paginatedBookings.length}</span> trên <span className="text-on-surface font-bold">{filteredBookings.length}</span> giao dịch</p>
          <div className="flex items-center gap-2">
            <button onClick={() => setCurrentPage((page) => Math.max(1, page - 1))} disabled={currentPageClamped === 1} className="w-10 h-10 rounded-full border border-surface-container flex items-center justify-center hover:bg-white transition-all disabled:opacity-40">
              <span className="material-symbols-outlined text-sm">chevron_left</span>
            </button>
            {pageNumbers.map((page) => (
              <button key={page} onClick={() => setCurrentPage(page)} className={`w-10 h-10 rounded-full flex items-center justify-center font-bold text-xs transition-all ${page === currentPageClamped ? 'bg-primary text-white shadow-md shadow-primary/20' : 'border border-surface-container hover:bg-white'}`}>
                {page}
              </button>
            ))}
            <button onClick={() => setCurrentPage((page) => Math.min(totalPages, page + 1))} disabled={currentPageClamped === totalPages} className="w-10 h-10 rounded-full border border-surface-container flex items-center justify-center hover:bg-white transition-all disabled:opacity-40">
              <span className="material-symbols-outlined text-sm">chevron_right</span>
            </button>
          </div>
        </div>
      </div>

      {selectedBooking ? (
        <section className="bg-white rounded-[2rem] shadow-[0px_20px_40px_rgba(21,28,39,0.04)] border border-surface-container-high/40 p-8">
          <div className="flex flex-col xl:flex-row justify-between gap-6">
            <div>
              <p className="text-[10px] uppercase font-black tracking-[0.2em] text-primary mb-2">Chi tiết booking</p>
              <h2 className="text-2xl font-black text-on-surface">{selectedBooking.displayId}</h2>
              <p className="text-on-surface-variant mt-2">{selectedBooking.userName} • {selectedBooking.destination}</p>
            </div>
            <div className="flex flex-wrap gap-3">
              <button onClick={() => updateStatus({ paymentStatus: 'paid', tripStatus: 'paid' })} disabled={actionLoading} className="rounded-full bg-primary-container px-5 py-2.5 text-sm font-bold text-white disabled:opacity-50">Đánh dấu Paid</button>
              <button onClick={() => updateStatus({ paymentStatus: 'pending', tripStatus: 'pending' })} disabled={actionLoading} className="rounded-full bg-surface-container-low px-5 py-2.5 text-sm font-bold text-on-surface disabled:opacity-50">Đưa về Pending</button>
              <button onClick={() => updateStatus({ paymentStatus: 'cancelled', tripStatus: 'cancelled' })} disabled={actionLoading} className="rounded-full bg-error-container px-5 py-2.5 text-sm font-bold text-error disabled:opacity-50">Hủy booking</button>
              <button onClick={() => updateStatus({ paymentStatus: 'refunded', tripStatus: 'cancelled' })} disabled={actionLoading} className="rounded-full bg-tertiary-container/20 px-5 py-2.5 text-sm font-bold text-tertiary disabled:opacity-50">Hoàn tiền</button>
              <button onClick={() => { setSelectedBooking(null); setDetail(null); }} className="rounded-full bg-on-surface px-5 py-2.5 text-sm font-bold text-white">Đóng</button>
            </div>
          </div>

          {detailLoading ? (
            <div className="flex items-center justify-center py-14">
              <div className="h-10 w-10 animate-spin rounded-full border-b-2 border-primary-container"></div>
            </div>
          ) : detail ? (
            <div className="space-y-8 mt-8">
              <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
                <div className="bg-surface-container-low rounded-2xl p-5">
                  <p className="text-[11px] font-bold uppercase tracking-wider text-on-surface-variant">Khách hàng</p>
                  <p className="text-sm font-bold text-on-surface mt-2">{detail.userName}</p>
                  <p className="text-xs text-on-surface-variant mt-1">{detail.userCode}</p>
                </div>
                <div className="bg-surface-container-low rounded-2xl p-5">
                  <p className="text-[11px] font-bold uppercase tracking-wider text-on-surface-variant">Hành trình</p>
                  <p className="text-sm font-bold text-on-surface mt-2">{detail.tripTitle}</p>
                  <p className="text-xs text-on-surface-variant mt-1">{detail.travelWindow}</p>
                </div>
                <div className="bg-surface-container-low rounded-2xl p-5">
                  <p className="text-[11px] font-bold uppercase tracking-wider text-on-surface-variant">Thanh toán</p>
                  <p className="text-sm font-bold text-on-surface mt-2">{detail.paymentStatus}</p>
                  <p className="text-xs text-on-surface-variant mt-1">Trip: {detail.tripStatus}</p>
                </div>
                <div className="bg-surface-container-low rounded-2xl p-5">
                  <p className="text-[11px] font-bold uppercase tracking-wider text-on-surface-variant">Giá trị</p>
                  <p className="text-sm font-bold text-on-surface mt-2">{detail.totalAmount}</p>
                  <p className="text-xs text-on-surface-variant mt-1">{detail.summary}</p>
                </div>
              </div>

              <div className="grid grid-cols-1 xl:grid-cols-[1.1fr_0.9fr] gap-6">
                <div className="rounded-[1.75rem] bg-surface-container-low p-6">
                  <div className="flex items-center justify-between gap-4">
                    <div>
                      <h3 className="text-lg font-black text-on-surface">Lịch trình dịch vụ</h3>
                      <p className="mt-1 text-sm text-on-surface-variant">Các khách sạn, chuyến xe hoặc dịch vụ đã gắn với booking.</p>
                    </div>
                  </div>
                  <div className="mt-6 space-y-3">
                    {detail.itinerary.length === 0 ? (
                      <p className="text-sm text-on-surface-variant">Booking này chưa có itinerary chi tiết.</p>
                    ) : (
                      detail.itinerary.map((item, index) => (
                        <div key={`${item.serviceName}-${index}`} className="rounded-[1.5rem] bg-white p-4">
                          <div className="flex items-start justify-between gap-4">
                            <div>
                              <p className="text-xs font-black uppercase tracking-[0.2em] text-primary">Day {item.dayNumber}</p>
                              <p className="mt-2 text-sm font-bold text-on-surface">{item.serviceName}</p>
                              <p className="mt-1 text-xs text-on-surface-variant">{item.serviceType} • SL: {item.quantity}</p>
                            </div>
                            <p className="text-sm font-black text-on-surface">{item.amount.toLocaleString()}đ</p>
                          </div>
                        </div>
                      ))
                    )}
                  </div>
                </div>

                <div className="rounded-[1.75rem] bg-surface-container-low p-6">
                  <h3 className="text-lg font-black text-on-surface">Lịch sử thanh toán gateway</h3>
                  <p className="mt-1 text-sm text-on-surface-variant">Các giao dịch đã phát sinh trên booking này.</p>
                  <div className="mt-6 space-y-3">
                    {detail.paymentHistory.length === 0 ? (
                      <p className="text-sm text-on-surface-variant">Chưa có giao dịch thanh toán nào.</p>
                    ) : (
                      detail.paymentHistory.map((payment) => (
                        <div key={payment.transactionId} className="rounded-[1.5rem] bg-white p-4">
                          <div className="flex items-start justify-between gap-4">
                            <div>
                              <p className="text-sm font-bold text-on-surface">{payment.transactionId}</p>
                              <p className="mt-1 text-xs text-on-surface-variant">{payment.paymentMethod} • {payment.paidAt}</p>
                            </div>
                            <div className="text-right">
                              <p className="text-sm font-black text-on-surface">{payment.amount.toLocaleString()}đ</p>
                              <p className="mt-1 text-xs font-bold uppercase tracking-wider text-primary">{payment.status}</p>
                            </div>
                          </div>
                        </div>
                      ))
                    )}
                  </div>
                </div>
              </div>
            </div>
          ) : null}
        </section>
      ) : null}

      <div className="flex flex-col md:flex-row justify-between items-center gap-10 mt-10 opacity-70">
        <div className="text-left">
          <p className="text-[10px] uppercase font-black tracking-widest text-on-surface mb-2">Hệ thống booking Skynet</p>
          <p className="text-xs max-w-xs leading-relaxed">
            Trạng thái booking đang được quản trị trực tiếp từ dashboard admin với cơ chế can thiệp thủ công cho các trường hợp lỗi cổng thanh toán hoặc hoàn tiền.
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
