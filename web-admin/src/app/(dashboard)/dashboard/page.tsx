"use client";

import { useEffect, useMemo, useState } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { useAdminSearch } from '@/contexts/AdminSearchContext';
import {
  adminService,
  type AdminDashboardStats,
  type AdminRecentBooking,
} from '@/services/adminService';
import { downloadCsv } from '@/utils/adminActions';
import { toast } from 'sonner';
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
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
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
  DialogFooter,
} from "@/components/ui/dialog";
import {
  CreditCard,
  Wallet,
  Users,
  Map,
  ArrowRight,
  TrendingUp,
  UserPlus,
  Ticket,
  Calendar,
  Download,
  AlertCircle,
  Clock,
} from 'lucide-react';

const statusConfig = {
  paid: { label: 'Đã thanh toán', variant: 'secondary' as const, className: 'bg-emerald-500/10 text-emerald-600 dark:text-emerald-400' },
  pending: { label: 'Chờ thanh toán', variant: 'secondary' as const, className: 'bg-amber-500/10 text-amber-600 dark:text-amber-400' },
  cancelled: { label: 'Đã hủy', variant: 'secondary' as const, className: 'bg-neutral-500/10 text-neutral-600 dark:text-neutral-400' },
};

const formatCompactNumber = (number: number) =>
  new Intl.NumberFormat('vi-VN', { notation: 'compact', maximumFractionDigits: 1 }).format(number);

const formatDateInput = (date: Date) => date.toISOString().slice(0, 10);

export default function DashboardPage() {
  const router = useRouter();
  const { query } = useAdminSearch();
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
    try {
      const data = await adminService.getDashboardStats(params);
      setStats(data);
    } catch (error: any) {
      toast.error('Không thể tải dashboard: ' + (error?.message || 'Lỗi kết nối'));
    }
  };

  useEffect(() => {
    const fetchData = async () => {
      setLoading(true);
      await loadDashboard();
      setLoading(false);
    };

    fetchData();
  }, []);

  const filteredBookings = useMemo(() => {
    if (!stats) return [];

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
    downloadCsv(`recent-bookings-${recentStatus}.csv`, filteredBookings, [
      { key: 'id', header: 'Mã đặt chỗ' },
      { key: 'name', header: 'Khách hàng' },
      { key: 'destination', header: 'Điểm đến' },
      { key: 'amount', header: 'Tổng tiền' },
      { key: 'status', header: 'Trạng thái' },
    ]);

    toast.success('Xuất dữ liệu thành công', {
      description: 'Danh sách đặt chỗ gần đây đã được tải xuống dạng CSV.',
    });
  };

  const handleApplyRange = async () => {
    setLoading(true);
    await loadDashboard(range);
    setLoading(false);
    toast.success('Đã áp dụng khoảng thời gian', {
      description: `Dữ liệu từ ${range.startDate} đến ${range.endDate} đã được cập nhật.`,
    });
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

    setLoading(true);
    await loadDashboard(nextRange);
    setLoading(false);
  };

  if (loading && !stats) {
    return (
      <div className="flex items-center justify-center h-full min-h-[50vh]">
        <div className="animate-spin rounded-full h-10 w-10 border-b-2 border-primary"></div>
      </div>
    );
  }

  if (!stats) {
    return (
      <div className="flex flex-col items-center justify-center min-h-[50vh] text-center p-6">
        <AlertCircle className="h-10 w-10 text-destructive mb-3" />
        <h3 className="text-lg font-bold">Không thể tải dữ liệu dashboard</h3>
        <p className="text-muted-foreground mt-1 max-w-sm">
          Đã có lỗi xảy ra khi gọi API từ Server. Vui lòng kiểm tra trạng thái Backend ở cổng 5110.
        </p>
        <Button onClick={() => loadDashboard()} className="mt-4">Thử lại</Button>
      </div>
    );
  }

  const maxChartValue = Math.max(
    ...stats.chartSeries.flatMap((item) => [item.revenue, item.profit]),
    1
  );

  return (
    <div className="px-4 lg:px-6 space-y-6">
      {/* Header section with Date range picker */}
      <div className="flex flex-col xl:flex-row xl:items-center justify-between gap-6">
        <div>
          <span className="text-xs font-bold uppercase tracking-wider text-primary">Dashboard vận hành</span>
          <h1 className="text-3xl font-extrabold tracking-tight mt-1">Bảng điều khiển tổng hợp</h1>
          <p className="text-muted-foreground text-sm mt-2 max-w-2xl">
            Theo dõi tổng quan tài chính, doanh thu, lợi nhuận và tình hình vận hành các chuyến đi thực tế trên hệ thống.
          </p>
        </div>

        <div className="flex flex-col sm:flex-row items-stretch sm:items-center gap-3 bg-card p-3 rounded-xl border shadow-sm">
          <div className="flex items-center gap-2">
            <Input
              type="date"
              value={range.startDate}
              onChange={(e) => setRange((prev) => ({ ...prev, startDate: e.target.value }))}
              className="h-9 w-36 text-xs bg-muted/40 border-none rounded-lg"
            />
            <span className="text-xs text-muted-foreground">đến</span>
            <Input
              type="date"
              value={range.endDate}
              onChange={(e) => setRange((prev) => ({ ...prev, endDate: e.target.value }))}
              className="h-9 w-36 text-xs bg-muted/40 border-none rounded-lg"
            />
          </div>
          <div className="flex items-center gap-2">
            <Button size="sm" onClick={handleApplyRange} className="h-9 cursor-pointer">
              Áp dụng
            </Button>
            <div className="h-5 w-[1px] bg-border mx-1" />
            <Button size="sm" variant="ghost" onClick={() => setQuickRange(2)} className="h-9 text-xs px-2 cursor-pointer">
              3 tháng
            </Button>
            <Button size="sm" variant="ghost" onClick={() => setQuickRange(5)} className="h-9 text-xs px-2 cursor-pointer">
              6 tháng
            </Button>
          </div>
        </div>
      </div>

      {/* Metric Cards Grid */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <MetricCard
          title="Doanh thu trong kỳ"
          value={`${formatCompactNumber(stats.totalRevenue)}đ`}
          description="Tổng giá trị giao dịch phát sinh"
          icon={<CreditCard className="h-4 w-4" />}
          theme="emerald"
          footerAction={
            <Link href="/bookings" className="flex items-center gap-1">
              Xem chi tiết <ArrowRight className="h-3 w-3" />
            </Link>
          }
        />

        <MetricCard
          title="Lợi nhuận trong kỳ"
          value={`${formatCompactNumber(stats.totalProfit)}đ`}
          description="Doanh thu từ phí hoa hồng/affiliate"
          icon={<Wallet className="h-4 w-4" />}
          theme="sky"
          footerAction={
            <Link href="/transport" className="flex items-center gap-1">
              Quản lý vận tải <ArrowRight className="h-3 w-3" />
            </Link>
          }
        />

        <MetricCard
          title="Tổng người dùng"
          value={stats.totalUsers.toLocaleString()}
          description={`+${stats.newUsersToday} thành viên mới hôm nay`}
          icon={<Users className="h-4 w-4" />}
          theme="amber"
          footerAction={
            <Link href="/users" className="flex items-center gap-1">
              Danh sách User <ArrowRight className="h-3 w-3" />
            </Link>
          }
        />

        <MetricCard
          title="Chuyến đi hoạt động"
          value={stats.activeTrips.toLocaleString()}
          description="Chuyến đi đã thanh toán/đang xử lý"
          icon={<Map className="h-4 w-4" />}
          theme="indigo"
          footerAction={
            <Link href="/bookings" className="flex items-center gap-1">
              Theo dõi vận hành <ArrowRight className="h-3 w-3" />
            </Link>
          }
        />
      </div>

      {/* Chart and Activity Feed Section */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Dynamic Financial Chart */}
        <Card className="lg:col-span-2">
          <CardHeader className="flex flex-row items-end justify-between pb-6">
            <div>
              <CardTitle className="text-lg font-bold flex items-center gap-2">
                <TrendingUp className="h-5 w-5 text-primary" /> Biểu đồ tài chính
              </CardTitle>
              <CardDescription>
                So sánh sự tăng trưởng doanh thu và lợi nhuận hoa hồng thực tế qua từng tháng.
              </CardDescription>
            </div>
            <div className="flex gap-4 text-xs font-semibold">
              <span className="flex items-center gap-1.5 text-muted-foreground">
                <span className="h-2.5 w-2.5 rounded-full bg-primary" /> Doanh thu
              </span>
              <span className="flex items-center gap-1.5 text-muted-foreground">
                <span className="h-2.5 w-2.5 rounded-full bg-emerald-500" /> Lợi nhuận
              </span>
            </div>
          </CardHeader>
          <CardContent>
            <div className="flex h-[280px] items-end justify-between gap-2 bg-muted/20 p-4 rounded-xl border border-muted">
              {stats.chartSeries.map((point) => (
                <div key={point.label} className="flex-1 flex flex-col items-center gap-2 h-full justify-end group">
                  <div className="w-full flex justify-center items-end gap-1.5 h-44">
                    <div
                      className="w-4 sm:w-5 bg-primary/80 rounded-t-sm hover:bg-primary transition-all duration-300"
                      style={{ height: `${Math.max(10, (point.revenue / maxChartValue) * 100)}%` }}
                    />
                    <div
                      className="w-4 sm:w-5 bg-emerald-500/80 rounded-t-sm hover:bg-emerald-500 transition-all duration-300"
                      style={{ height: `${Math.max(10, (point.profit / maxChartValue) * 100)}%` }}
                    />
                  </div>
                  <span className="text-[10px] font-bold text-muted-foreground uppercase">{point.label}</span>
                  <span className="text-[10px] font-medium text-neutral-400 group-hover:text-foreground transition-colors">
                    {point.bookings} b.
                  </span>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>

        {/* Activity Feed */}
        <Card className="flex flex-col">
          <CardHeader>
            <CardTitle className="text-lg font-bold flex items-center gap-2">
              <Clock className="h-5 w-5 text-primary" /> Hoạt động mới nhất
            </CardTitle>
            <CardDescription>
              Các tương tác, đăng ký và đặt phòng mới nhất trên nền tảng.
            </CardDescription>
          </CardHeader>
          <CardContent className="flex-1 overflow-y-auto max-h-[300px] pr-2 space-y-4">
            {stats.activityFeed.length === 0 ? (
              <p className="text-sm text-muted-foreground text-center py-8">Chưa có hoạt động mới nào.</p>
            ) : (
              stats.activityFeed.map((item) => (
                <div key={item.id} className="flex items-start gap-3 p-3 rounded-lg border bg-muted/10">
                  <div className="p-2 rounded-lg bg-muted text-foreground flex items-center justify-center">
                    {item.type === 'user' ? (
                      <UserPlus className="h-4 w-4" />
                    ) : item.type === 'booking' ? (
                      <Ticket className="h-4 w-4" />
                    ) : (
                      <CreditCard className="h-4 w-4" />
                    )}
                  </div>
                  <div className="min-w-0 flex-1">
                    <p className="text-xs font-bold leading-none">{item.title}</p>
                    <p className="text-[11px] text-muted-foreground leading-snug mt-1">{item.description}</p>
                    <p className="text-[9px] text-neutral-400 font-bold uppercase tracking-wider mt-1.5">{item.occurredAt}</p>
                  </div>
                </div>
              ))
            )}
          </CardContent>
        </Card>
      </div>

      {/* Recent Bookings Section */}
      <Card>
        <CardHeader className="flex flex-col lg:flex-row lg:items-center justify-between pb-6 gap-4">
          <div>
            <CardTitle className="text-lg font-bold">Đặt chỗ gần đây</CardTitle>
            <CardDescription>
              Danh sách các booking đang thực hiện. Lọc trạng thái hoặc tìm kiếm ở thanh top.
            </CardDescription>
          </div>
          <div className="flex flex-wrap items-center gap-2">
            {[
              { value: 'all', label: 'Tất cả' },
              { value: 'paid', label: 'Đã thanh toán' },
              { value: 'pending', label: 'Chờ thanh toán' },
              { value: 'cancelled', label: 'Đã hủy' },
            ].map((item) => (
              <Button
                key={item.value}
                size="sm"
                variant={recentStatus === item.value ? 'default' : 'outline'}
                onClick={() => setRecentStatus(item.value as any)}
                className="h-8 text-xs cursor-pointer rounded-full"
              >
                {item.label}
              </Button>
            ))}
            <Button size="sm" variant="outline" onClick={exportRecentBookings} className="h-8 text-xs cursor-pointer gap-1.5 rounded-full">
              <Download className="h-3 w-3" /> Xuất CSV
            </Button>
          </div>
        </CardHeader>
        <CardContent className="p-0">
          <div className="overflow-x-auto border-t">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead className="pl-6">Mã đặt chỗ</TableHead>
                  <TableHead>Khách hàng</TableHead>
                  <TableHead>Điểm đến</TableHead>
                  <TableHead>Tổng tiền</TableHead>
                  <TableHead>Trạng thái</TableHead>
                  <TableHead className="pr-6 text-right">Thao tác</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {filteredBookings.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={6} className="text-center py-8 text-muted-foreground text-sm">
                      Không tìm thấy đặt chỗ nào phù hợp.
                    </TableCell>
                  </TableRow>
                ) : (
                  filteredBookings.map((booking) => {
                    const status = statusConfig[booking.status] || { label: booking.status, variant: 'outline', className: '' };
                    return (
                      <TableRow key={booking.id} className="hover:bg-muted/30">
                        <TableCell className="pl-6 font-bold text-xs">{booking.id}</TableCell>
                        <TableCell>
                          <div className="flex items-center gap-2.5">
                            <div className="h-8 w-8 rounded-full bg-muted flex items-center justify-center text-xs font-bold text-muted-foreground">
                              {booking.initials}
                            </div>
                            <span className="text-xs font-semibold">{booking.name}</span>
                          </div>
                        </TableCell>
                        <TableCell className="text-xs">{booking.destination}</TableCell>
                        <TableCell className="text-xs font-bold">{booking.amount}</TableCell>
                        <TableCell>
                          <Badge variant={status.variant} className={status.className}>
                            {status.label}
                          </Badge>
                        </TableCell>
                        <TableCell className="pr-6 text-right">
                          <Button size="sm" variant="ghost" onClick={() => setSelectedBooking(booking)} className="h-8 text-xs cursor-pointer">
                            Chi tiết
                          </Button>
                        </TableCell>
                      </TableRow>
                    );
                  })
                )}
              </TableBody>
            </Table>
          </div>
        </CardContent>
      </Card>

      {/* Booking Quick Details Modal */}
      <Dialog open={Boolean(selectedBooking)} onOpenChange={(open) => !open && setSelectedBooking(null)}>
        {selectedBooking && (
          <DialogContent className="max-w-md">
            <DialogHeader>
              <DialogTitle>Chi tiết đặt chỗ</DialogTitle>
              <DialogDescription>Mã giao dịch: {selectedBooking.id}</DialogDescription>
            </DialogHeader>
            <div className="space-y-4 py-2 text-xs">
              <div className="grid grid-cols-3 border-b pb-2">
                <span className="text-muted-foreground font-semibold">Khách hàng:</span>
                <span className="col-span-2 font-bold">{selectedBooking.name}</span>
              </div>
              <div className="grid grid-cols-3 border-b pb-2">
                <span className="text-muted-foreground font-semibold">Điểm đến:</span>
                <span className="col-span-2 font-bold">{selectedBooking.destination}</span>
              </div>
              <div className="grid grid-cols-3 border-b pb-2">
                <span className="text-muted-foreground font-semibold">Tổng tiền:</span>
                <span className="col-span-2 font-bold text-emerald-600 dark:text-emerald-400">{selectedBooking.amount}</span>
              </div>
              <div className="grid grid-cols-3 border-b pb-2">
                <span className="text-muted-foreground font-semibold">Trạng thái:</span>
                <span className="col-span-2">
                  <Badge variant={statusConfig[selectedBooking.status]?.variant} className={statusConfig[selectedBooking.status]?.className}>
                    {statusConfig[selectedBooking.status]?.label}
                  </Badge>
                </span>
              </div>
            </div>
            <DialogFooter className="flex flex-row justify-end gap-2">
              <Button variant="outline" size="sm" onClick={() => setSelectedBooking(null)} className="cursor-pointer">
                Đóng
              </Button>
              <Button size="sm" onClick={() => router.push(`/bookings`)} className="cursor-pointer">
                Đi tới quản lý Booking
              </Button>
            </DialogFooter>
          </DialogContent>
        )}
      </Dialog>
    </div>
  );
}
