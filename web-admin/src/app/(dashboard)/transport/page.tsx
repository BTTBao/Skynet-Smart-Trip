"use client";

import { useEffect, useMemo, useState } from 'react';
import { useAdminSearch } from '@/contexts/AdminSearchContext';
import {
  adminService,
  type AdminCreateTransportCompanyRequest,
  type AdminCreateTransportScheduleRequest,
  type AdminDestination,
  type AdminTransportCompany,
  type AdminTransportSchedule,
  type AdminTransportSeat,
  type AdminTransportStats,
  type AdminUpdateSeatRequest,
  type AdminUpdateTransportScheduleRequest,
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
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
  DialogFooter,
} from "@/components/ui/dialog";
import { Label } from "@/components/ui/label";
import {
  Bus,
  Phone,
  Image as ImageIcon,
  Calendar,
  Clock,
  DollarSign,
  Download,
  Plus,
  Trash2,
  Edit2,
  ShieldAlert,
  Award,
  Grid,
  ChevronLeft,
  ChevronRight,
  TrendingUp,
} from 'lucide-react';
import Image from 'next/image';
import { ConfirmDialog } from '@/components/ui/confirm-dialog';

const PAGE_SIZE = 5;

const transportStatusConfig: Record<
  AdminTransportSchedule['status'],
  { label: string; variant: 'default' | 'secondary' | 'outline'; className: string }
> = {
  running: {
    label: 'Đang chạy',
    variant: 'secondary' as const,
    className: 'bg-emerald-500/10 text-emerald-600 dark:text-emerald-400',
  },
  upcoming: {
    label: 'Chờ khởi hành',
    variant: 'secondary' as const,
    className: 'bg-amber-500/10 text-amber-600 dark:text-amber-400',
  },
  completed: {
    label: 'Hoàn thành',
    variant: 'secondary' as const,
    className: 'bg-neutral-500/10 text-neutral-600 dark:text-neutral-400',
  },
};

const emptyScheduleForm: AdminCreateTransportScheduleRequest = {
  companyId: 0,
  fromDestinationId: 0,
  toDestinationId: 0,
  departureAt: '',
  arrivalAt: '',
  price: 0,
  commissionRate: 8,
  totalSeats: 36,
};

const emptyCompanyForm: AdminCreateTransportCompanyRequest = {
  name: '',
  hotline: '',
  logoUrl: '',
};

const toDateTimeLocal = (value: string) => {
  if (!value) return '';
  const date = new Date(value);
  const tz = date.getTimezoneOffset();
  const local = new Date(date.getTime() - tz * 60_000);
  return local.toISOString().slice(0, 16);
};

const formatCompactCurrency = (value: number) =>
  `${new Intl.NumberFormat('vi-VN', { notation: 'compact', maximumFractionDigits: 1 }).format(value)}đ`;

export default function TransportAdminPage() {
  const { query } = useAdminSearch();
  const [stats, setStats] = useState<AdminTransportStats | null>(null);
  const [companies, setCompanies] = useState<AdminTransportCompany[]>([]);
  const [destinations, setDestinations] = useState<AdminDestination[]>([]);
  const [loading, setLoading] = useState(true);
  const [statusFilter, setStatusFilter] = useState<'all' | AdminTransportSchedule['status']>('all');
  const [currentPage, setCurrentPage] = useState(1);
  const [selectedSchedule, setSelectedSchedule] = useState<AdminTransportSchedule | null>(null);
  const [scheduleForm, setScheduleForm] = useState<AdminUpdateTransportScheduleRequest>(emptyScheduleForm);
  const [editingScheduleId, setEditingScheduleId] = useState<number | null>(null);
  const [companyForm, setCompanyForm] = useState<AdminCreateTransportCompanyRequest>(emptyCompanyForm);
  const [editingCompanyId, setEditingCompanyId] = useState<number | null>(null);
  const [seatDraft, setSeatDraft] = useState<AdminTransportSeat[]>([]);
  const [submitting, setSubmitting] = useState(false);
  const [uploadingCompanyLogo, setUploadingCompanyLogo] = useState(false);
  const [deleteScheduleConfirmOpen, setDeleteScheduleConfirmOpen] = useState(false);
  const [scheduleToDelete, setScheduleToDelete] = useState<AdminTransportSchedule | null>(null);
  const [deleteCompanyConfirmOpen, setDeleteCompanyConfirmOpen] = useState(false);
  const [companyToDelete, setCompanyToDelete] = useState<AdminTransportCompany | null>(null);

  const hasCompanyLogoPreview = companyForm.logoUrl.trim().length > 0;

  const loadTransport = async () => {
    try {
      const [transportStats, transportCompanies, allDestinations] = await Promise.all([
        adminService.getTransportStats(),
        adminService.getTransportCompanies(),
        adminService.getDestinations(),
      ]);
      setStats(transportStats);
      setCompanies(transportCompanies);
      setDestinations(allDestinations);
    } catch (error: any) {
      toast.error('Không thể tải dữ liệu vận tải: ' + (error?.message || 'Lỗi kết nối'));
    }
  };

  useEffect(() => {
    const fetchData = async () => {
      setLoading(true);
      await loadTransport();
      setLoading(false);
    };

    fetchData();
  }, []);

  useEffect(() => {
    setCurrentPage(1);
  }, [query, statusFilter]);

  useEffect(() => {
    if (selectedSchedule && stats) {
      const refreshed = stats.schedules.find((item) => item.id === selectedSchedule.id);
      if (refreshed) {
        setSelectedSchedule(refreshed);
        setSeatDraft(refreshed.seats);
      }
    }
  }, [stats, selectedSchedule?.id]);

  const filteredSchedules = useMemo(() => {
    if (!stats) return [];

    const keyword = query.trim().toLowerCase();

    return stats.schedules.filter((schedule) => {
      const matchesStatus = statusFilter === 'all' || schedule.status === statusFilter;
      const matchesKeyword =
        keyword.length === 0 ||
        schedule.code.toLowerCase().includes(keyword) ||
        schedule.companyName.toLowerCase().includes(keyword) ||
        schedule.route.toLowerCase().includes(keyword);

      return matchesStatus && matchesKeyword;
    });
  }, [query, stats, statusFilter]);

  const totalPages = Math.max(1, Math.ceil(filteredSchedules.length / PAGE_SIZE));
  const currentPageClamped = Math.min(currentPage, totalPages);
  const paginatedSchedules = filteredSchedules.slice((currentPageClamped - 1) * PAGE_SIZE, currentPageClamped * PAGE_SIZE);
  const pageNumbers = getPageNumbers(currentPageClamped, totalPages);

  const chartItems = stats
    ? [
        { label: 'Đang chạy', value: stats.activeSchedules, color: 'bg-primary' },
        { label: 'Sắp chạy', value: stats.upcomingSchedules, color: 'bg-amber-500' },
        { label: 'Hoàn thành', value: stats.completedSchedules, color: 'bg-neutral-500' },
      ]
    : [];
  const maxChartValue = Math.max(...chartItems.map((item) => item.value), 1);

  const exportSchedules = () => {
    downloadCsv(`transport-schedules-${statusFilter}.csv`, filteredSchedules, [
      { key: 'code', header: 'Mã chuyến' },
      { key: 'companyName', header: 'Nhà xe' },
      { key: 'route', header: 'Tuyến đường' },
      { key: 'departureDate', header: 'Ngày khởi hành' },
      { key: 'departureTime', header: 'Giờ khởi hành' },
      { key: 'status', header: 'Trạng thái' },
      { key: 'ticketPrice', header: 'Giá vé' },
      { key: 'affiliateProfit', header: 'Lợi nhuận affiliate' },
    ]);

    toast.success('Xuất dữ liệu lịch trình thành công.');
  };

  const resetScheduleForm = () => {
    setEditingScheduleId(null);
    setScheduleForm(emptyScheduleForm);
  };

  const resetCompanyForm = () => {
    setEditingCompanyId(null);
    setCompanyForm(emptyCompanyForm);
  };

  const handleSubmitSchedule = async (e: React.FormEvent) => {
    e.preventDefault();
    if (scheduleForm.companyId === 0 || scheduleForm.fromDestinationId === 0 || scheduleForm.toDestinationId === 0) {
      toast.warning('Vui lòng chọn nhà xe, điểm đi và điểm đến hợp lệ.');
      return;
    }

    setSubmitting(true);

    try {
      if (editingScheduleId) {
        await adminService.updateTransportSchedule(editingScheduleId, scheduleForm);
        toast.success('Đã cập nhật lịch trình chuyến xe thành công');
      } else {
        await adminService.createTransportSchedule(scheduleForm);
        toast.success('Đã tạo lịch trình chuyến xe mới thành công');
      }

      await loadTransport();
      resetScheduleForm();
    } catch (error: any) {
      toast.error('Không thể lưu lịch trình: ' + (error?.message || 'Có lỗi xảy ra'));
    } finally {
      setSubmitting(false);
    }
  };

  const handleEditSchedule = (schedule: AdminTransportSchedule) => {
    setEditingScheduleId(schedule.id);
    setScheduleForm({
      companyId: schedule.companyId,
      fromDestinationId: schedule.fromDestinationId,
      toDestinationId: schedule.toDestinationId,
      departureAt: toDateTimeLocal(schedule.departureAt),
      arrivalAt: toDateTimeLocal(schedule.arrivalAt),
      price: schedule.priceValue,
      commissionRate: schedule.commissionRate,
      totalSeats: schedule.totalSeats,
    });
  };

  const handleDeleteSchedule = (schedule: AdminTransportSchedule) => {
    setScheduleToDelete(schedule);
    setDeleteScheduleConfirmOpen(true);
  };

  const handleConfirmDeleteSchedule = async () => {
    if (!scheduleToDelete) return;
    try {
      await adminService.deleteTransportSchedule(scheduleToDelete.id);
      await loadTransport();
      if (selectedSchedule?.id === scheduleToDelete.id) {
        setSelectedSchedule(null);
      }
      toast.success('Đã hủy lịch trình chuyến xe thành công');
    } catch (error: any) {
      toast.error('Không thể hủy lịch trình: ' + (error?.message || 'Có lỗi xảy ra'));
    } finally {
      setScheduleToDelete(null);
    }
  };

  const handleSubmitCompany = async (e: React.FormEvent) => {
    e.preventDefault();
    setSubmitting(true);

    try {
      if (editingCompanyId) {
        await adminService.updateTransportCompany(editingCompanyId, companyForm);
        toast.success('Đã cập nhật thông tin đối tác thành công');
      } else {
        await adminService.createTransportCompany(companyForm);
        toast.success('Đã thêm nhà xe đối tác mới thành công');
      }

      await loadTransport();
      resetCompanyForm();
    } catch (error: any) {
      toast.error('Không thể lưu thông tin nhà xe: ' + (error?.message || 'Có lỗi xảy ra'));
    } finally {
      setSubmitting(false);
    }
  };

  const handleCompanyLogoUpload = async (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (!file) return;

    setUploadingCompanyLogo(true);
    try {
      const result = await adminService.uploadTransportCompanyLogo(file);
      setCompanyForm((current) => ({ ...current, logoUrl: result.imageUrl }));
      toast.success('Đã tải lên logo đối tác thành công');
    } catch (error: any) {
      toast.error('Không thể tải logo: ' + (error?.message || 'Có lỗi xảy ra'));
    } finally {
      setUploadingCompanyLogo(false);
      event.target.value = '';
    }
  };

  const handleDeleteCompany = (company: AdminTransportCompany) => {
    setCompanyToDelete(company);
    setDeleteCompanyConfirmOpen(true);
  };

  const handleConfirmDeleteCompany = async () => {
    if (!companyToDelete) return;
    try {
      await adminService.deleteTransportCompany(companyToDelete.id);
      await loadTransport();
      toast.success('Đã xóa đối tác nhà xe thành công.');
    } catch (error: any) {
      toast.error('Không thể xóa đối tác nhà xe: ' + (error?.message || 'Có lỗi xảy ra'));
    } finally {
      setCompanyToDelete(null);
    }
  };

  const handleSeatToggle = (seat: AdminTransportSeat) => {
    setSeatDraft((current) =>
      current.map((item) =>
        item.id === seat.id
          ? {
              ...item,
              status:
                item.status === 'available'
                  ? 'locked'
                  : item.status === 'locked'
                    ? 'booked'
                    : 'available',
            }
          : item
      )
    );
  };

  const saveSeatMap = async () => {
    if (!selectedSchedule) return;

    try {
      const payload: AdminUpdateSeatRequest[] = seatDraft.map((seat) => ({ id: seat.id, status: seat.status }));
      await adminService.updateSeatMap(selectedSchedule.id, payload);
      await loadTransport();
      toast.success('Đã cập nhật sơ đồ ghế chuyến xe thành công');
    } catch (error: any) {
      toast.error('Không thể lưu sơ đồ ghế: ' + (error?.message || 'Có lỗi xảy ra'));
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

  return (
    <div className="px-4 lg:px-6 space-y-6">
      <div className="flex justify-between items-center gap-4 flex-wrap">
        <div>
          <span className="text-xs font-bold uppercase tracking-wider text-primary">Vận hành vận tải</span>
          <h1 className="text-3xl font-extrabold tracking-tight mt-1">Lịch trình chuyến xe</h1>
          <p className="text-muted-foreground text-sm mt-2">
            Quản lý tuyến đường đối tác nhà xe, tạo chuyến, đặt chỗ và cấu hình sơ đồ ghế trực tiếp.
          </p>
        </div>
        <Button variant="outline" size="sm" onClick={exportSchedules} className="gap-1.5 cursor-pointer">
          <Download className="h-4 w-4" /> Xuất CSV
        </Button>
      </div>

      {/* Metrics Grid */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <MetricCard
          title="Tổng chuyến tháng này"
          value={`${stats.totalSchedulesThisMonth} chuyến`}
          description={`${stats.totalCompanies} nhà xe đối tác`}
          icon={<Bus className="h-4 w-4" />}
          theme="muted"
        />

        <MetricCard
          title="Doanh thu dự kiến"
          value={formatCompactCurrency(stats.expectedRevenueThisMonth)}
          description={`Tỷ lệ ghế đặt trung bình: ${stats.averageOccupancyRate.toFixed(1)}%`}
          icon={<DollarSign className="h-4 w-4" />}
          theme="emerald"
        />

        <MetricCard
          title="Doanh số Affiliate"
          value={formatCompactCurrency(stats.affiliateRevenueThisMonth)}
          description={`Tăng trưởng ${stats.affiliateGrowthRate >= 0 ? '+' : ''}${stats.affiliateGrowthRate.toFixed(1)}%`}
          icon={<Award className="h-4 w-4" />}
          theme="sky"
        />
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
        {/* Schedule CRUD Form */}
        <div className="lg:col-span-8">
          <Card>
            <CardHeader>
              <CardTitle className="text-lg font-bold">
                {editingScheduleId ? 'Chỉnh sửa lịch trình chuyến xe' : 'Thêm lịch trình chuyến xe mới'}
              </CardTitle>
              <CardDescription>
                Cấu hình thời gian chạy, giá vé, số ghế ngồi và mức chiết khấu hoa hồng đối với chuyến xe du lịch.
              </CardDescription>
            </CardHeader>
            <CardContent>
              <form onSubmit={handleSubmitSchedule} className="space-y-4">
                <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                  <div className="grid gap-2">
                    <Label htmlFor="companyId">Nhà xe đối tác</Label>
                    <Select
                      value={String(scheduleForm.companyId)}
                      onValueChange={(val) => setScheduleForm((c) => ({ ...c, companyId: Number(val) }))}
                    >
                      <SelectTrigger id="companyId">
                        <SelectValue placeholder="Chọn nhà xe" />
                      </SelectTrigger>
                      <SelectContent>
                        {companies.map((company) => (
                          <SelectItem key={company.id} value={String(company.id)}>
                            {company.name}
                          </SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                  </div>

                  <div className="grid gap-2">
                    <Label htmlFor="fromDestinationId">Điểm xuất phát</Label>
                    <Select
                      value={String(scheduleForm.fromDestinationId)}
                      onValueChange={(val) => setScheduleForm((c) => ({ ...c, fromDestinationId: Number(val) }))}
                    >
                      <SelectTrigger id="fromDestinationId">
                        <SelectValue placeholder="Chọn điểm đi" />
                      </SelectTrigger>
                      <SelectContent>
                        {destinations.map((d) => (
                          <SelectItem key={d.id} value={String(d.id)}>
                            {d.name}
                          </SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                  </div>

                  <div className="grid gap-2">
                    <Label htmlFor="toDestinationId">Điểm đến</Label>
                    <Select
                      value={String(scheduleForm.toDestinationId)}
                      onValueChange={(val) => setScheduleForm((c) => ({ ...c, toDestinationId: Number(val) }))}
                    >
                      <SelectTrigger id="toDestinationId">
                        <SelectValue placeholder="Chọn điểm đến" />
                      </SelectTrigger>
                      <SelectContent>
                        {destinations.map((d) => (
                          <SelectItem key={d.id} value={String(d.id)}>
                            {d.name}
                          </SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                  </div>
                </div>

                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div className="grid gap-2">
                    <Label htmlFor="departureAt">Giờ xuất phát</Label>
                    <Input
                      id="departureAt"
                      type="datetime-local"
                      value={scheduleForm.departureAt}
                      onChange={(e) => setScheduleForm((c) => ({ ...c, departureAt: e.target.value }))}
                      required
                    />
                  </div>
                  <div className="grid gap-2">
                    <Label htmlFor="arrivalAt">Giờ dự kiến đến</Label>
                    <Input
                      id="arrivalAt"
                      type="datetime-local"
                      value={scheduleForm.arrivalAt}
                      onChange={(e) => setScheduleForm((c) => ({ ...c, arrivalAt: e.target.value }))}
                      required
                    />
                  </div>
                </div>

                <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                  <div className="grid gap-2">
                    <Label htmlFor="price">Giá vé (VND)</Label>
                    <Input
                      id="price"
                      type="number"
                      min={0}
                      value={scheduleForm.price}
                      onChange={(e) => setScheduleForm((c) => ({ ...c, price: Number(e.target.value) }))}
                      required
                    />
                  </div>
                  <div className="grid gap-2">
                    <Label htmlFor="commissionRate">Chiết khấu (%)</Label>
                    <Input
                      id="commissionRate"
                      type="number"
                      min={0}
                      max={100}
                      value={scheduleForm.commissionRate}
                      onChange={(e) => setScheduleForm((c) => ({ ...c, commissionRate: Number(e.target.value) }))}
                      required
                    />
                  </div>
                  <div className="grid gap-2">
                    <Label htmlFor="totalSeats">Tổng số ghế</Label>
                    <Input
                      id="totalSeats"
                      type="number"
                      min={1}
                      value={scheduleForm.totalSeats}
                      onChange={(e) => setScheduleForm((c) => ({ ...c, totalSeats: Number(e.target.value) }))}
                      required
                    />
                  </div>
                </div>

                <div className="flex justify-end gap-2 pt-2">
                  {editingScheduleId && (
                    <Button type="button" variant="outline" onClick={resetScheduleForm} className="cursor-pointer">
                      Hủy sửa
                    </Button>
                  )}
                  <Button type="submit" disabled={submitting} className="cursor-pointer">
                    {submitting ? 'Đang lưu...' : editingScheduleId ? 'Lưu thay đổi' : 'Tạo lịch trình'}
                  </Button>
                </div>
              </form>
            </CardContent>
          </Card>
        </div>

        {/* Company Manager Form */}
        <div className="lg:col-span-4">
          <Card>
            <CardHeader>
              <CardTitle className="text-lg font-bold">
                {editingCompanyId ? 'Cập nhật đối tác' : 'Nhà xe đối tác'}
              </CardTitle>
              <CardDescription>Quản lý hồ sơ nhà xe liên kết.</CardDescription>
            </CardHeader>
            <CardContent>
              <form onSubmit={handleSubmitCompany} className="space-y-3">
                <div className="grid gap-1.5">
                  <Label htmlFor="comp-name" className="text-xs">Tên nhà xe</Label>
                  <Input
                    id="comp-name"
                    value={companyForm.name}
                    onChange={(e) => setCompanyForm((c) => ({ ...c, name: e.target.value }))}
                    placeholder="Ví dụ: Hoàng Long, Phương Trang..."
                    required
                  />
                </div>
                <div className="grid gap-1.5">
                  <Label htmlFor="comp-phone" className="text-xs">Hotline liên hệ</Label>
                  <Input
                    id="comp-phone"
                    value={companyForm.hotline}
                    onChange={(e) => setCompanyForm((c) => ({ ...c, hotline: e.target.value }))}
                    placeholder="Số điện thoại chăm sóc khách hàng"
                  />
                </div>
                <div className="grid gap-1.5">
                  <Label className="text-xs">Logo đối tác (URL hoặc Upload)</Label>
                  <div className="flex gap-2">
                    <Input
                      value={companyForm.logoUrl}
                      onChange={(e) => setCompanyForm((c) => ({ ...c, logoUrl: e.target.value }))}
                      placeholder="https://..."
                      className="flex-1"
                    />
                    <Label className="cursor-pointer inline-flex items-center justify-center rounded-lg border border-input bg-background px-3 text-xs font-medium shadow-xs hover:bg-accent hover:text-accent-foreground select-none h-9">
                      {uploadingCompanyLogo ? 'Đang tải...' : 'Upload'}
                      <input
                        type="file"
                        accept="image/*"
                        disabled={uploadingCompanyLogo}
                        onChange={handleCompanyLogoUpload}
                        className="hidden"
                      />
                    </Label>
                  </div>
                </div>

                {hasCompanyLogoPreview && (
                  <div className="relative h-20 w-full rounded-lg overflow-hidden border mt-2 flex items-center justify-center bg-white p-2">
                    <Image
                      src={companyForm.logoUrl}
                      alt="Logo Preview"
                      width={64}
                      height={64}
                      className="object-contain"
                    />
                  </div>
                )}

                <div className="pt-2">
                  <Button type="submit" disabled={submitting} size="sm" className="w-full cursor-pointer">
                    {editingCompanyId ? 'Lưu nhà xe' : 'Thêm nhà xe'}
                  </Button>
                </div>
              </form>

              {/* Connected list */}
              <div className="mt-6 space-y-2 max-h-[220px] overflow-y-auto pr-1">
                {companies.map((company) => (
                  <div key={company.id} className="flex items-center justify-between p-2.5 rounded-lg border bg-muted/20 text-xs">
                    <div className="flex items-center gap-2 min-w-0">
                      <div className="relative h-9 w-9 bg-white rounded-md border flex items-center justify-center overflow-hidden shrink-0">
                        {company.logoUrl ? (
                          <Image
                            src={company.logoUrl}
                            alt=""
                            width={32}
                            height={32}
                            className="object-contain"
                          />
                        ) : (
                          <ImageIcon className="h-4 w-4 text-muted-foreground" />
                        )}
                      </div>
                      <div className="min-w-0">
                        <p className="font-bold truncate">{company.name}</p>
                        <p className="text-[10px] text-muted-foreground font-semibold truncate">{company.hotline}</p>
                      </div>
                    </div>
                    <div className="flex gap-1 shrink-0">
                      <Button
                        size="sm"
                        variant="ghost"
                        onClick={() => {
                          setEditingCompanyId(company.id);
                          setCompanyForm({
                            name: company.name,
                            hotline: company.hotline === '--' ? '' : company.hotline,
                            logoUrl: company.logoUrl,
                          });
                        }}
                        className="h-7 w-7 p-0 cursor-pointer"
                      >
                        <Edit2 className="h-3 w-3" />
                      </Button>
                      <Button
                        size="sm"
                        variant="ghost"
                        onClick={() => handleDeleteCompany(company)}
                        className="h-7 w-7 p-0 text-destructive hover:bg-destructive/10 cursor-pointer"
                      >
                        <Trash2 className="h-3 w-3" />
                      </Button>
                    </div>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>
        </div>
      </div>

      {/* Schedules Detail table */}
      <Card>
        <CardHeader className="flex flex-col sm:flex-row sm:items-center justify-between pb-6 gap-4 border-b">
          <div>
            <CardTitle className="text-lg font-bold">Danh sách lịch trình chi tiết</CardTitle>
            <CardDescription>
              Hiển thị chi tiết tất cả các lịch trình xe khách liên tỉnh. Lọc nhanh theo trạng thái.
            </CardDescription>
          </div>
          <div className="flex flex-wrap items-center gap-1.5">
            {[
              { value: 'all', label: 'Tất cả' },
              { value: 'running', label: 'Đang chạy' },
              { value: 'upcoming', label: 'Chờ khởi hành' },
              { value: 'completed', label: 'Hoàn thành' },
            ].map((item) => (
              <Button
                key={item.value}
                size="sm"
                variant={statusFilter === item.value ? 'default' : 'ghost'}
                onClick={() => setStatusFilter(item.value as any)}
                className="h-8 text-xs cursor-pointer rounded-full"
              >
                {item.label}
              </Button>
            ))}
          </div>
        </CardHeader>
        <CardContent className="p-0">
          <div className="overflow-x-auto">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead className="pl-6">Mã chuyến</TableHead>
                  <TableHead>Nhà xe / Tuyến đường</TableHead>
                  <TableHead>Khởi hành</TableHead>
                  <TableHead>Trạng thái</TableHead>
                  <TableHead className="text-right">Giá vé</TableHead>
                  <TableHead className="text-right">Lợi nhuận</TableHead>
                  <TableHead className="text-center">Ghế đặt</TableHead>
                  <TableHead className="pr-6 text-right">Thao tác</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {paginatedSchedules.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={8} className="text-center py-12 text-sm text-muted-foreground">
                      Không tìm thấy chuyến xe nào phù hợp.
                    </TableCell>
                  </TableRow>
                ) : (
                  paginatedSchedules.map((schedule) => {
                    const status = transportStatusConfig[schedule.status] || { label: schedule.status, variant: 'outline', className: '' };

                    return (
                      <TableRow key={schedule.id} className="hover:bg-muted/30">
                        <TableCell className="pl-6 font-bold text-xs">{schedule.code}</TableCell>
                        <TableCell>
                          <div className="space-y-0.5">
                            <p className="text-xs font-bold">{schedule.companyName}</p>
                            <p className="text-[10px] text-muted-foreground font-semibold">{schedule.route}</p>
                          </div>
                        </TableCell>
                        <TableCell>
                          <div className="space-y-0.5 text-xs">
                            <p className="font-semibold">{schedule.departureTime}</p>
                            <p className="text-[10px] text-muted-foreground">{schedule.departureDate}</p>
                          </div>
                        </TableCell>
                        <TableCell>
                          <Badge variant={status.variant} className={status.className}>
                            {status.label}
                          </Badge>
                        </TableCell>
                        <TableCell className="text-right text-xs font-medium">{schedule.ticketPrice}</TableCell>
                        <TableCell className="text-right text-xs font-bold text-emerald-600 dark:text-emerald-400">
                          {schedule.affiliateProfit}
                        </TableCell>
                        <TableCell className="text-center">
                          <Badge variant="outline" className="text-xs font-semibold">
                            {schedule.occupiedSeats}/{schedule.totalSeats}
                          </Badge>
                        </TableCell>
                        <TableCell className="pr-6 text-right">
                          <div className="flex justify-end gap-1">
                            <Button
                              size="sm"
                              variant="ghost"
                              onClick={() => {
                                setSelectedSchedule(schedule);
                                setSeatDraft(schedule.seats);
                              }}
                              className="h-8 text-xs cursor-pointer gap-1"
                            >
                              <Grid className="h-3.5 w-3.5" /> Sơ đồ ghế
                            </Button>
                            <Button
                              size="sm"
                              variant="ghost"
                              onClick={() => handleEditSchedule(schedule)}
                              className="h-8 w-8 p-0 cursor-pointer"
                            >
                              <Edit2 className="h-3.5 w-3.5 text-muted-foreground" />
                            </Button>
                            <Button
                              size="sm"
                              variant="ghost"
                              onClick={() => handleDeleteSchedule(schedule)}
                              className="h-8 w-8 p-0 text-destructive hover:bg-destructive/10 cursor-pointer"
                            >
                              <Trash2 className="h-3.5 w-3.5" />
                            </Button>
                          </div>
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

      {/* Seat Map Details Drawer/Modal */}
      <Dialog open={Boolean(selectedSchedule)} onOpenChange={(open) => !open && setSelectedSchedule(null)}>
        {selectedSchedule && (
          <DialogContent className="max-w-xl">
            <DialogHeader>
              <DialogTitle>Sơ đồ ghế chuyến xe {selectedSchedule.code}</DialogTitle>
              <DialogDescription>
                Nhà xe: {selectedSchedule.companyName} • Tuyến: {selectedSchedule.route}
              </DialogDescription>
            </DialogHeader>
            <div className="space-y-4">
              <div className="flex flex-wrap items-center gap-4 text-xs font-semibold justify-center border-b pb-3">
                <span className="flex items-center gap-1">
                  <span className="w-3.5 h-3.5 rounded bg-muted border" /> Trống
                </span>
                <span className="flex items-center gap-1">
                  <span className="w-3.5 h-3.5 rounded bg-amber-500/10 border border-amber-500" /> Giữ chỗ
                </span>
                <span className="flex items-center gap-1">
                  <span className="w-3.5 h-3.5 rounded bg-primary/10 border border-primary" /> Đã bán
                </span>
              </div>

              <div className="grid grid-cols-4 sm:grid-cols-6 gap-2 max-h-[300px] overflow-y-auto p-1">
                {seatDraft.map((seat) => {
                  let seatClass = "bg-muted border hover:bg-accent";
                  if (seat.status === 'locked') {
                    seatClass = "bg-amber-500/10 border-amber-500 text-amber-600 dark:text-amber-400";
                  } else if (seat.status === 'booked') {
                    seatClass = "bg-primary/10 border-primary text-primary font-bold";
                  }

                  return (
                    <button
                      key={seat.id}
                      onClick={() => handleSeatToggle(seat)}
                      className={`rounded-lg py-2.5 text-center text-xs select-none transition-all cursor-pointer font-bold border ${seatClass}`}
                    >
                      <div>{seat.seatNumber}</div>
                      <div className="text-[8px] uppercase tracking-wider mt-0.5 opacity-85">
                        {seat.status === 'available' ? 'Trống' : seat.status === 'locked' ? 'Giữ' : 'Bán'}
                      </div>
                    </button>
                  );
                })}
              </div>
            </div>
            <DialogFooter className="flex flex-row justify-end gap-2 pt-2 border-t">
              <Button variant="outline" size="sm" onClick={() => setSelectedSchedule(null)} className="cursor-pointer">
                Đóng
              </Button>
              <Button size="sm" onClick={saveSeatMap} className="cursor-pointer">
                Lưu sơ đồ ghế
              </Button>
            </DialogFooter>
          </DialogContent>
        )}
      </Dialog>

      {/* Analytics chart and details */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 pb-6">
        <Card className="lg:col-span-8">
          <CardHeader>
            <CardTitle className="text-sm font-bold flex items-center gap-2">
              <TrendingUp className="h-4 w-4 text-primary" /> Phân tích hiệu suất vận hành chuyến đi
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="flex h-48 items-end justify-around gap-2 bg-muted/20 p-4 rounded-xl border">
              {chartItems.map((item) => (
                <div key={item.label} className="flex flex-col items-center gap-2 h-full justify-end w-20">
                  <div
                    className={`w-12 ${item.color} rounded-t-md hover:opacity-90 transition-all duration-300`}
                    style={{ height: `${Math.max(15, (item.value / maxChartValue) * 100)}%` }}
                  />
                  <span className="text-[10px] font-bold text-muted-foreground">{item.label}</span>
                  <span className="text-[10px] font-black">{item.value} chuyến</span>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>

        <div className="lg:col-span-4 flex flex-col justify-between gap-4">
          <Card className="bg-primary/5 border-primary/20 flex-1 flex flex-col justify-center">
            <CardContent className="py-6 space-y-2">
              <span className="text-[10px] font-bold uppercase tracking-wider text-primary">Tỷ lệ lấp đầy xe</span>
              <div className="text-2xl font-black text-primary">{stats.averageOccupancyRate.toFixed(1)}%</div>
              <p className="text-xs text-muted-foreground">
                Hiệu suất sử dụng ghế ngồi trung bình đối với toàn bộ chuyến xe trong tháng này.
              </p>
            </CardContent>
          </Card>
          <Card className="bg-muted/40 flex-1 flex flex-col justify-center">
            <CardContent className="py-6 space-y-1">
              <span className="text-[10px] font-bold uppercase tracking-wider text-muted-foreground">Trạng thái nhà xe</span>
              <div className="text-lg font-bold">{stats.totalCompanies} doanh nghiệp vận tải</div>
              <p className="text-xs text-muted-foreground font-semibold">
                Đối tác liên kết cung cấp dịch vụ trực tuyến.
              </p>
            </CardContent>
          </Card>
        </div>
      </div>

      <ConfirmDialog
        isOpen={deleteScheduleConfirmOpen}
        title="Xóa lịch trình chuyến xe?"
        description={scheduleToDelete ? `Bạn có chắc chắn muốn xóa/hủy lịch trình ${scheduleToDelete.code}?` : ""}
        onConfirm={handleConfirmDeleteSchedule}
        onClose={() => setDeleteScheduleConfirmOpen(false)}
      />

      <ConfirmDialog
        isOpen={deleteCompanyConfirmOpen}
        title="Xóa đối tác nhà xe?"
        description={companyToDelete ? `Bạn có chắc chắn muốn xóa đối tác nhà xe ${companyToDelete.name}? Các chuyến xe đang hoạt động của nhà xe này sẽ bị ảnh hưởng.` : ""}
        onConfirm={handleConfirmDeleteCompany}
        onClose={() => setDeleteCompanyConfirmOpen(false)}
      />
    </div>
  );
}
