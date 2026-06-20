"use client";

import { useEffect, useMemo, useState } from 'react';
import { useAdminSearch } from '@/contexts/AdminSearchContext';
import {
  adminService,
  type AdminBooking,
  type AdminBookingDetail,
  type AdminBookingStats,
  type AdminUpdateBookingStatusRequest,
} from '@/services/adminService';
import { downloadCsv, getPageNumbers } from '@/utils/adminActions';
import { toast } from 'sonner';
import {
  Card,
  CardContent,
  CardHeader,
  CardTitle,
  CardDescription,
} from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { MetricCard } from "@/components/ui/metric-card";
import { Badge } from "@/components/ui/badge";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import {
  ChevronLeft,
  ChevronRight,
  Download,
  MapPin,
  TrendingUp,
  CreditCard,
  Briefcase,
  DollarSign,
  User,
  Info,
  Calendar,
  Clock,
  ExternalLink,
} from 'lucide-react';

const PAGE_SIZE = 6;

const paymentStatusConfig: Record<
  AdminBooking['paymentStatus'],
  { label: string; className: string }
> = {
  paid: {
    label: 'Đã thanh toán',
    className: 'bg-emerald-500/10 text-emerald-600 dark:text-emerald-400',
  },
  pending: {
    label: 'Chờ xử lý',
    className: 'bg-amber-500/10 text-amber-600 dark:text-amber-400',
  },
  cancelled: {
    label: 'Đã hủy',
    className: 'bg-neutral-500/10 text-neutral-600 dark:text-neutral-400',
  },
};

const formatCompactCurrency = (value: number) =>
  `${new Intl.NumberFormat('vi-VN', { notation: 'compact', maximumFractionDigits: 1 }).format(value)}đ`;

export default function BookingsAdminPage() {
  const { query } = useAdminSearch();
  const [stats, setStats] = useState<AdminBookingStats | null>(null);
  const [loading, setLoading] = useState(true);
  const [statusTab, setStatusTab] = useState<'all' | AdminBooking['paymentStatus']>('all');
  const [currentPage, setCurrentPage] = useState(1);
  const [selectedBooking, setSelectedBooking] = useState<AdminBooking | null>(null);
  const [detail, setDetail] = useState<AdminBookingDetail | null>(null);
  const [detailLoading, setDetailLoading] = useState(false);
  const [actionLoading, setActionLoading] = useState(false);

  const loadBookings = async () => {
    try {
      const data = await adminService.getBookingStats();
      setStats(data);
    } catch (error: any) {
      toast.error('Không thể tải dữ liệu bookings: ' + (error?.message || 'Lỗi kết nối'));
    }
  };

  useEffect(() => {
    const fetchData = async () => {
      setLoading(true);
      await loadBookings();
      setLoading(false);
    };

    fetchData();
  }, []);

  useEffect(() => {
    setCurrentPage(1);
  }, [statusTab, query]);

  const filteredBookings = useMemo(() => {
    if (!stats) return [];

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
      { key: 'totalProfit', header: 'Lợi nhuận' },
      { key: 'summary', header: 'Tóm tắt' },
      { key: 'paymentStatus', header: 'Thanh toán' },
      { key: 'tripStatus', header: 'Trạng thái chuyến' },
      { key: 'createdAt', header: 'Tạo lúc' },
    ]);

    toast.success('Đã xuất danh sách giao dịch booking thành công');
  };

  const openBooking = async (booking: AdminBooking) => {
    setSelectedBooking(booking);
    setDetail(null);
    setDetailLoading(true);

    try {
      const payload = await adminService.getBookingDetail(booking.id);
      setDetail(payload);
    } catch (error: any) {
      toast.error('Không thể tải chi tiết booking: ' + (error?.message || 'Lỗi'));
    } finally {
      setDetailLoading(false);
    }
  };

  const updateStatus = async (payload: AdminUpdateBookingStatusRequest) => {
    if (!selectedBooking) return;

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

      toast.success('Đã cập nhật trạng thái đặt chỗ thành công');
    } catch (error: any) {
      toast.error('Không thể cập nhật trạng thái: ' + (error?.message || 'Lỗi'));
    } finally {
      setActionLoading(false);
    }
  };

  if (loading && !stats) {
    return (
      <div className="flex items-center justify-center h-full min-h-[50vh]">
        <div className="animate-spin rounded-full h-10 w-10 border-b-2 border-primary"></div>
      </div>
    );
  }

  if (!stats) return null;

  const paidRatio = stats.totalBookings === 0 ? 0 : Math.round((stats.paidBookings / stats.totalBookings) * 100);
  const pendingRatio = stats.totalBookings === 0 ? 0 : Math.round((stats.pendingBookings / stats.totalBookings) * 100);

  return (
    <div className="px-4 lg:px-6 space-y-6">
      <div className="flex justify-between items-center gap-4 flex-wrap">
        <div>
          <span className="text-xs font-bold uppercase tracking-wider text-primary">Hệ thống đặt chỗ</span>
          <h1 className="text-3xl font-extrabold tracking-tight mt-1">Danh sách đặt chỗ (Bookings)</h1>
          <p className="text-muted-foreground text-sm mt-2">
            Xem lịch trình chi tiết, quản lý giao dịch thanh toán và can thiệp trạng thái vé/đặt phòng thủ công.
          </p>
        </div>
        <Button variant="outline" size="sm" onClick={exportBookings} className="gap-1.5 cursor-pointer">
          <Download className="h-4 w-4" /> Xuất CSV
        </Button>
      </div>

      {/* Metrics Grid */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <MetricCard
          title="Tổng doanh thu"
          value={formatCompactCurrency(stats.totalRevenue)}
          description={`Tỷ lệ thanh toán thành công: ${paidRatio}%`}
          icon={<DollarSign className="h-4 w-4" />}
          theme="emerald"
        />

        <MetricCard
          title="Tổng lợi nhuận"
          value={formatCompactCurrency(stats.totalProfit)}
          description="Đã bao gồm chiết khấu đối tác"
          icon={<TrendingUp className="h-4 w-4" />}
          theme="sky"
        />

        <MetricCard
          title="Tổng lượt đặt chỗ"
          value={`${stats.totalBookings.toLocaleString()} Booking`}
          description={`Đang chờ xử lý: ${stats.pendingBookings} đơn`}
          icon={<Briefcase className="h-4 w-4" />}
          theme="muted"
        />
      </div>

      {/* Filter Tabs */}
      <div className="flex flex-wrap items-center gap-1.5 border-b pb-4">
        {[
          { value: 'all', label: `Tất cả (${stats.totalBookings})` },
          { value: 'paid', label: `Đã thanh toán (${stats.paidBookings})` },
          { value: 'pending', label: `Chờ xử lý (${stats.pendingBookings})` },
          { value: 'cancelled', label: `Đã hủy (${stats.cancelledBookings})` },
        ].map((item) => (
          <Button
            key={item.value}
            variant={statusTab === item.value ? 'default' : 'ghost'}
            size="sm"
            onClick={() => setStatusTab(item.value as any)}
            className="h-8 text-xs cursor-pointer rounded-full"
          >
            {item.label}
          </Button>
        ))}
      </div>

      {/* Bookings Table */}
      <Card>
        <CardContent className="p-0">
          <div className="overflow-x-auto">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead className="pl-6">Khách hàng / Mã Booking</TableHead>
                  <TableHead>Địa điểm du lịch</TableHead>
                  <TableHead className="text-right">Tổng thanh toán</TableHead>
                  <TableHead className="text-right">Lợi nhuận</TableHead>
                  <TableHead className="text-center">Trạng thái thanh toán</TableHead>
                  <TableHead className="pr-6 text-right">Thao tác</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {paginatedBookings.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={6} className="text-center py-12 text-sm text-muted-foreground">
                      Không có booking đặt chỗ nào phù hợp.
                    </TableCell>
                  </TableRow>
                ) : (
                  paginatedBookings.map((booking) => {
                    const status = paymentStatusConfig[booking.paymentStatus] || { label: booking.paymentStatus, className: '' };

                    return (
                      <TableRow key={booking.id} className="hover:bg-muted/30">
                        <TableCell className="pl-6 py-4">
                          <div className="flex items-center gap-2.5">
                            <div className="h-9 w-9 bg-primary/10 rounded-full flex items-center justify-center font-bold text-xs text-primary shrink-0">
                              <User className="h-4 w-4" />
                            </div>
                            <div className="min-w-0">
                              <span className="font-bold text-xs block truncate max-w-[200px]">{booking.userName}</span>
                              <span className="text-[10px] text-muted-foreground font-semibold block mt-0.5">
                                Mã: {booking.displayId} • {booking.userCode}
                              </span>
                            </div>
                          </div>
                        </TableCell>
                        <TableCell>
                          <div>
                            <span className="text-xs font-bold flex items-center gap-1">
                              <MapPin className="h-3 w-3 text-primary shrink-0" /> {booking.destination}
                            </span>
                            <span className="text-[9px] text-muted-foreground font-semibold block mt-0.5">{booking.createdAt}</span>
                          </div>
                        </TableCell>
                        <TableCell className="text-right text-xs">
                          <span className="font-bold block">{booking.totalAmount}</span>
                          <span className="text-[9px] text-muted-foreground">{booking.summary}</span>
                        </TableCell>
                        <TableCell className="text-right text-xs font-bold text-emerald-600 dark:text-emerald-400">
                          {booking.totalProfit}
                        </TableCell>
                        <TableCell className="text-center">
                          <Badge variant="secondary" className={status.className}>
                            {status.label}
                          </Badge>
                        </TableCell>
                        <TableCell className="pr-6 text-right">
                          <Button
                            size="sm"
                            variant="outline"
                            onClick={() => openBooking(booking)}
                            className="h-8 text-xs cursor-pointer"
                          >
                            Xem chi tiết
                          </Button>
                        </TableCell>
                      </TableRow>
                    );
                  })
                )}
              </TableBody>
            </Table>
          </div>

          {/* Pagination Footer */}
          <div className="flex items-center justify-between px-6 py-4 border-t">
            <Button
              size="sm"
              variant="outline"
              onClick={() => setCurrentPage((page) => Math.max(1, page - 1))}
              disabled={currentPageClamped === 1}
              className="gap-1 cursor-pointer h-8 text-xs"
            >
              <ChevronLeft className="h-3.5 w-3.5" /> Trước
            </Button>
            <div className="flex items-center gap-1.5">
              {pageNumbers.map((page) => (
                <Button
                  key={page}
                  size="sm"
                  variant={currentPageClamped === page ? 'default' : 'ghost'}
                  onClick={() => setCurrentPage(page)}
                  className="w-8 h-8 p-0 text-xs cursor-pointer"
                >
                  {page}
                </Button>
              ))}
            </div>
            <Button
              size="sm"
              variant="outline"
              onClick={() => setCurrentPage((page) => Math.min(totalPages, page + 1))}
              disabled={currentPageClamped === totalPages}
              className="gap-1 cursor-pointer h-8 text-xs"
            >
              Sau <ChevronRight className="h-3.5 w-3.5" />
            </Button>
          </div>
        </CardContent>
      </Card>

      {/* Selected booking details view */}
      {selectedBooking && (
        <Card className="border-primary/20 bg-primary/5">
          <CardHeader className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4 pb-6 border-b">
            <div>
              <span className="text-[10px] uppercase font-bold tracking-wider text-primary">Thông tin chi tiết đơn đặt hàng</span>
              <CardTitle className="text-xl font-bold mt-1">Mã đơn: {selectedBooking.displayId}</CardTitle>
              <CardDescription>
                Khách hàng: {selectedBooking.userName} • Tuyến: {selectedBooking.destination}
              </CardDescription>
            </div>
            <div className="flex flex-wrap gap-1.5">
              <Button
                size="sm"
                onClick={() => updateStatus({ paymentStatus: 'paid', tripStatus: 'paid' })}
                disabled={actionLoading}
                className="cursor-pointer text-xs"
              >
                Đã thanh toán
              </Button>
              <Button
                size="sm"
                variant="secondary"
                onClick={() => updateStatus({ paymentStatus: 'pending', tripStatus: 'pending' })}
                disabled={actionLoading}
                className="cursor-pointer text-xs"
              >
                Chờ xử lý
              </Button>
              <Button
                size="sm"
                variant="destructive"
                onClick={() => updateStatus({ paymentStatus: 'cancelled', tripStatus: 'cancelled' })}
                disabled={actionLoading}
                className="cursor-pointer text-xs"
              >
                Hủy đơn
              </Button>
              <Button
                size="sm"
                variant="outline"
                onClick={() => updateStatus({ paymentStatus: 'refunded', tripStatus: 'cancelled' })}
                disabled={actionLoading}
                className="cursor-pointer text-xs"
              >
                Hoàn tiền
              </Button>
              <Button
                size="sm"
                variant="ghost"
                onClick={() => {
                  setSelectedBooking(null);
                  setDetail(null);
                }}
                className="cursor-pointer text-xs"
              >
                Đóng
              </Button>
            </div>
          </CardHeader>
          <CardContent className="pt-6">
            {detailLoading ? (
              <div className="flex items-center justify-center py-10">
                <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary"></div>
              </div>
            ) : detail ? (
              <div className="space-y-6">
                {/* Meta properties */}
                <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                  <div className="p-3 bg-background rounded-lg border">
                    <span className="text-[10px] text-muted-foreground uppercase font-bold block">Khách hàng</span>
                    <span className="text-xs font-bold block mt-1">{detail.userName}</span>
                    <span className="text-[10px] text-muted-foreground block mt-0.5">{detail.userCode}</span>
                  </div>

                  <div className="p-3 bg-background rounded-lg border">
                    <span className="text-[10px] text-muted-foreground uppercase font-bold block">Thời gian chuyến đi</span>
                    <span className="text-xs font-bold block mt-1 truncate">{detail.tripTitle}</span>
                    <span className="text-[10px] text-muted-foreground block mt-0.5">{detail.travelWindow}</span>
                  </div>

                  <div className="p-3 bg-background rounded-lg border">
                    <span className="text-[10px] text-muted-foreground uppercase font-bold block">Trạng thái thanh toán</span>
                    <span className="text-xs font-bold block mt-1">{detail.paymentStatus}</span>
                    <span className="text-[10px] text-muted-foreground block mt-0.5">Hành trình: {detail.tripStatus}</span>
                  </div>

                  <div className="p-3 bg-background rounded-lg border">
                    <span className="text-[10px] text-muted-foreground uppercase font-bold block">Chi phí & Lợi nhuận</span>
                    <span className="text-xs font-bold block mt-1">{detail.totalAmount}</span>
                    <span className="text-[10px] text-emerald-600 dark:text-emerald-400 font-bold block mt-0.5">
                      Lợi nhuận: {detail.totalProfit}
                    </span>
                  </div>
                </div>

                <div className="grid grid-cols-1 xl:grid-cols-2 gap-6">
                  {/* Service Itinerary */}
                  <div className="space-y-3">
                    <div className="flex items-center gap-1.5">
                      <Briefcase className="h-4 w-4 text-primary" />
                      <span className="text-xs font-bold text-muted-foreground">Lịch trình khách sạn & dịch vụ xe khách</span>
                    </div>

                    <div className="space-y-2 max-h-[300px] overflow-y-auto pr-1">
                      {detail.itinerary.length === 0 ? (
                        <div className="text-center py-10 text-xs text-muted-foreground border rounded-lg bg-background">
                          Đơn hàng này không đi kèm dịch vụ bổ sung.
                        </div>
                      ) : (
                        detail.itinerary.map((item, idx) => (
                          <div key={item.serviceName + idx} className="p-3 bg-background rounded-lg border flex justify-between items-start gap-4">
                            <div>
                              <Badge variant="outline" className="text-[9px] py-0">
                                Ngày {item.dayNumber}
                              </Badge>
                              <p className="text-xs font-bold mt-1.5">{item.serviceName}</p>
                              <p className="text-[10px] text-muted-foreground mt-0.5">
                                Loại: {item.serviceType} • Số lượng: {item.quantity}
                              </p>
                            </div>
                            <span className="text-xs font-bold shrink-0">{item.amount.toLocaleString()}đ</span>
                          </div>
                        ))
                      )}
                    </div>
                  </div>

                  {/* Payment gateway transactions */}
                  <div className="space-y-3">
                    <div className="flex items-center gap-1.5">
                      <CreditCard className="h-4 w-4 text-primary" />
                      <span className="text-xs font-bold text-muted-foreground">Lịch sử thanh toán & Hoàn tiền cổng thanh toán</span>
                    </div>

                    <div className="space-y-2 max-h-[300px] overflow-y-auto pr-1">
                      {detail.paymentHistory.length === 0 ? (
                        <div className="text-center py-10 text-xs text-muted-foreground border rounded-lg bg-background">
                          Chưa ghi nhận giao dịch thanh toán nào qua cổng.
                        </div>
                      ) : (
                        detail.paymentHistory.map((pmt) => (
                          <div key={pmt.transactionId} className="p-3 bg-background rounded-lg border flex justify-between items-start gap-4">
                            <div>
                              <p className="text-xs font-bold">{pmt.transactionId}</p>
                              <p className="text-[10px] text-muted-foreground mt-0.5">
                                {pmt.paymentMethod} • {pmt.paidAt}
                              </p>
                            </div>
                            <div className="text-right shrink-0">
                              <span className="text-xs font-bold block">{pmt.amount.toLocaleString()}đ</span>
                              <Badge variant="secondary" className="text-[9px] py-0 mt-1 capitalize">
                                {pmt.status}
                              </Badge>
                            </div>
                          </div>
                        ))
                      )}
                    </div>
                  </div>
                </div>
              </div>
            ) : (
              <div className="text-center py-6 text-xs text-muted-foreground">
                Không thể hiển thị thông tin chi tiết.
              </div>
            )}
          </CardContent>
        </Card>
      )}
    </div>
  );
}
