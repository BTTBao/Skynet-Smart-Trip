import { useEffect, useMemo, useState } from 'react';
import { useAdminSearch, useToast } from '../../context';
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
} from '../../services/adminService';
import { downloadCsv, getPageNumbers } from '../../utils/adminActions';
import { getErrorMessage } from '../../utils/http';

const PAGE_SIZE = 5;

const transportStatusConfig: Record<
  AdminTransportSchedule['status'],
  { label: string; badgeClass: string; icon: string; iconClass: string }
> = {
  running: {
    label: 'Đang chạy',
    badgeClass: 'bg-primary-fixed text-on-primary-fixed-variant',
    icon: 'directions_bus',
    iconClass: 'bg-primary-fixed/40 text-primary',
  },
  upcoming: {
    label: 'Chờ khởi hành',
    badgeClass: 'bg-surface-container-high text-on-surface-variant',
    icon: 'commute',
    iconClass: 'bg-secondary-fixed text-on-secondary-fixed',
  },
  completed: {
    label: 'Hoàn thành',
    badgeClass: 'bg-tertiary-fixed text-on-tertiary-fixed-variant',
    icon: 'task_alt',
    iconClass: 'bg-tertiary-fixed-dim text-on-tertiary-container',
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
  `${new Intl.NumberFormat('en-US', { notation: 'compact', maximumFractionDigits: 1 }).format(value)}đ`;

function MetricCard({
  label,
  value,
  accent,
  icon,
  iconClass,
  helper,
}: {
  label: string;
  value: string;
  accent: string;
  icon: string;
  iconClass: string;
  helper: string;
}) {
  return (
    <div className="bg-surface-container-lowest p-8 rounded-xl shadow-sm border border-outline-variant/5">
      <div className="flex justify-between items-start mb-4">
        <div className={`w-12 h-12 rounded-2xl flex items-center justify-center ${iconClass}`}>
          <span className="material-symbols-outlined text-2xl" style={{ fontVariationSettings: "'FILL' 1" }}>
            {icon}
          </span>
        </div>
        <span className={`text-[10px] font-bold px-2 py-1 rounded-full ${accent}`}>{helper}</span>
      </div>
      <p className="text-outline text-xs font-bold uppercase tracking-wider mb-1">{label}</p>
      <h3 className="text-3xl font-black text-on-surface tracking-tighter">{value}</h3>
    </div>
  );
}

export default function TransportAdminPage() {
  const { query } = useAdminSearch();
  const { showToast } = useToast();
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

  const loadTransport = async () => {
    const [transportStats, transportCompanies, allDestinations] = await Promise.all([
      adminService.getTransportStats(),
      adminService.getTransportCompanies(),
      adminService.getDestinations(),
    ]);

    setStats(transportStats);
    setCompanies(transportCompanies);
    setDestinations(allDestinations);
  };

  useEffect(() => {
    const fetchData = async () => {
      try {
        await loadTransport();
      } catch (error) {
        showToast({
          type: 'error',
          title: 'Không thể tải dữ liệu vận tải',
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
  }, [query, statusFilter]);

  useEffect(() => {
    if (selectedSchedule) {
      const refreshed = stats?.schedules.find((item) => item.id === selectedSchedule.id);
      if (refreshed) {
        setSelectedSchedule(refreshed);
        setSeatDraft(refreshed.seats);
      }
    }
  }, [stats, selectedSchedule?.id]);

  const filteredSchedules = useMemo(() => {
    if (!stats) {
      return [];
    }

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
        { label: 'Đang chạy', value: stats.activeSchedules, color: 'bg-primary-container' },
        { label: 'Sắp chạy', value: stats.upcomingSchedules, color: 'bg-secondary-container' },
        { label: 'Hoàn thành', value: stats.completedSchedules, color: 'bg-tertiary' },
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

    showToast({
      type: 'success',
      title: 'Đã xuất danh sách lịch trình',
      message: 'File CSV vận tải đã được tải xuống.',
    });
  };

  const resetScheduleForm = () => {
    setEditingScheduleId(null);
    setScheduleForm(emptyScheduleForm);
  };

  const resetCompanyForm = () => {
    setEditingCompanyId(null);
    setCompanyForm(emptyCompanyForm);
  };

  const handleSubmitSchedule = async (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    setSubmitting(true);

    try {
      if (editingScheduleId) {
        await adminService.updateTransportSchedule(editingScheduleId, scheduleForm);
      } else {
        await adminService.createTransportSchedule(scheduleForm);
      }

      await loadTransport();
      resetScheduleForm();

      showToast({
        type: 'success',
        title: editingScheduleId ? 'Đã cập nhật lịch trình' : 'Đã tạo lịch trình mới',
        message: 'Dữ liệu chuyến xe đã được đồng bộ.',
      });
    } catch (error) {
      showToast({
        type: 'error',
        title: 'Không thể lưu lịch trình',
        message: getErrorMessage(error),
      });
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

  const handleDeleteSchedule = async (schedule: AdminTransportSchedule) => {
    try {
      await adminService.deleteTransportSchedule(schedule.id);
      await loadTransport();
      if (selectedSchedule?.id === schedule.id) {
        setSelectedSchedule(null);
      }

      showToast({
        type: 'success',
        title: 'Đã hủy lịch trình',
        message: `${schedule.code} đã được xóa khỏi hệ thống.`,
      });
    } catch (error) {
      showToast({
        type: 'error',
        title: 'Không thể hủy lịch trình',
        message: getErrorMessage(error),
      });
    }
  };

  const handleSubmitCompany = async (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    setSubmitting(true);

    try {
      if (editingCompanyId) {
        await adminService.updateTransportCompany(editingCompanyId, companyForm);
      } else {
        await adminService.createTransportCompany(companyForm);
      }

      await loadTransport();
      resetCompanyForm();

      showToast({
        type: 'success',
        title: editingCompanyId ? 'Đã cập nhật nhà xe' : 'Đã thêm nhà xe',
        message: 'Thông tin đối tác vận tải đã được lưu.',
      });
    } catch (error) {
      showToast({
        type: 'error',
        title: 'Không thể lưu nhà xe',
        message: getErrorMessage(error),
      });
    } finally {
      setSubmitting(false);
    }
  };

  const handleDeleteCompany = async (company: AdminTransportCompany) => {
    try {
      await adminService.deleteTransportCompany(company.id);
      await loadTransport();
      showToast({
        type: 'success',
        title: 'Đã xóa nhà xe',
        message: `${company.name} đã được gỡ khỏi danh sách đối tác.`,
      });
    } catch (error) {
      showToast({
        type: 'error',
        title: 'Không thể xóa nhà xe',
        message: getErrorMessage(error),
      });
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
    if (!selectedSchedule) {
      return;
    }

    try {
      const payload: AdminUpdateSeatRequest[] = seatDraft.map((seat) => ({ id: seat.id, status: seat.status }));
      await adminService.updateSeatMap(selectedSchedule.id, payload);
      await loadTransport();
      showToast({
        type: 'success',
        title: 'Đã cập nhật sơ đồ ghế',
        message: 'Trạng thái từng ghế đã được lưu vào hệ thống.',
      });
    } catch (error) {
      showToast({
        type: 'error',
        title: 'Không thể lưu sơ đồ ghế',
        message: getErrorMessage(error),
      });
    }
  };

  if (loading) {
    return <div className="flex items-center justify-center h-full min-h-[50vh]"><div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary"></div></div>;
  }

  if (!stats) {
    return <div className="text-center text-error mt-10">Không thể tải dữ liệu chuyến xe.</div>;
  }

  return (
    <div className="space-y-12">
      <section className="flex flex-col lg:flex-row justify-between gap-6">
        <div>
          <span className="text-[11px] font-bold text-primary-container tracking-[0.2em] uppercase">Báo cáo hệ thống</span>
          <h1 className="text-4xl font-black text-on-surface tracking-tight mt-1">Lịch trình chuyến xe</h1>
          <p className="text-on-surface-variant mt-3 max-w-2xl">
            Trang này đã hỗ trợ tạo lịch mới, chỉnh giờ khởi hành, cập nhật ghế, hủy lịch trình và quản lý các nhà xe đối tác.
          </p>
        </div>
        <div className="flex gap-3">
          <button onClick={exportSchedules} className="px-6 py-2.5 bg-primary-container text-white font-bold rounded-full shadow-lg shadow-primary-container/20 flex items-center gap-2">
            <span className="material-symbols-outlined text-lg">download</span>
            <span>Xuất CSV</span>
          </button>
        </div>
      </section>

      <section className="grid grid-cols-1 xl:grid-cols-12 gap-6">
        <div className="xl:col-span-3">
          <MetricCard label="Tổng chuyến tháng này" value={stats.totalSchedulesThisMonth.toLocaleString()} icon="directions_bus" iconClass="bg-primary-fixed/30 text-primary" accent="text-primary bg-primary-fixed/50" helper={`${stats.totalCompanies} nhà xe`} />
        </div>
        <div className="xl:col-span-3">
          <MetricCard label="Doanh thu dự kiến" value={formatCompactCurrency(stats.expectedRevenueThisMonth)} icon="payments" iconClass="bg-secondary-fixed/50 text-secondary" accent="text-secondary bg-secondary-fixed" helper={`${stats.averageOccupancyRate.toFixed(1)}% lấp đầy`} />
        </div>
        <div className="xl:col-span-6 bg-surface-container-lowest p-8 rounded-xl shadow-sm border border-outline-variant/5 relative overflow-hidden flex items-center">
          <div className="relative z-10">
            <p className="text-outline text-xs font-bold uppercase tracking-wider mb-1">Hiệu suất Affiliate</p>
            <h3 className="text-3xl font-black text-on-surface tracking-tighter mb-2">{formatCompactCurrency(stats.affiliateRevenueThisMonth)}</h3>
            <p className="text-sm text-on-surface-variant mb-4">Tăng trưởng {stats.affiliateGrowthRate >= 0 ? '+' : ''}{stats.affiliateGrowthRate.toFixed(1)}% so với tháng trước.</p>
            <div className="flex flex-wrap gap-4">
              {chartItems.map((item) => (
                <div key={item.label} className="flex items-center gap-2">
                  <div className={`w-2 h-2 rounded-full ${item.color}`}></div>
                  <span className="text-xs font-medium text-on-surface-variant">{item.value} chuyến {item.label.toLowerCase()}</span>
                </div>
              ))}
            </div>
          </div>
          <div className="absolute right-0 bottom-0 top-0 w-1/2 flex items-end justify-end p-4 opacity-20">
            <span className="material-symbols-outlined text-[120px] text-primary-container/40">query_stats</span>
          </div>
        </div>
      </section>

      <section className="grid grid-cols-1 xl:grid-cols-[1.3fr_0.7fr] gap-8">
        <form onSubmit={handleSubmitSchedule} className="rounded-[2rem] bg-white p-8 shadow-[0px_20px_40px_rgba(21,28,39,0.04)] ring-1 ring-outline-variant/10">
          <div className="flex items-center justify-between gap-4 mb-6">
            <div>
              <h2 className="text-xl font-black text-on-surface">{editingScheduleId ? 'Chỉnh sửa lịch trình' : 'Thêm chuyến xe mới'}</h2>
              <p className="text-sm text-on-surface-variant mt-1">Tạo mới hoặc điều chỉnh lịch trình đang vận hành.</p>
            </div>
            {editingScheduleId ? <button type="button" onClick={resetScheduleForm} className="rounded-full bg-surface-container-low px-5 py-2.5 text-sm font-bold text-on-surface">Hủy sửa</button> : null}
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-4">
            <select value={scheduleForm.companyId} onChange={(event) => setScheduleForm((current) => ({ ...current, companyId: Number(event.target.value) }))} className="rounded-2xl bg-surface-container-low px-5 py-3 outline-none" required>
              <option value={0}>Chọn nhà xe</option>
              {companies.map((company) => <option key={company.id} value={company.id}>{company.name}</option>)}
            </select>
            <select value={scheduleForm.fromDestinationId} onChange={(event) => setScheduleForm((current) => ({ ...current, fromDestinationId: Number(event.target.value) }))} className="rounded-2xl bg-surface-container-low px-5 py-3 outline-none" required>
              <option value={0}>Điểm đi</option>
              {destinations.map((destination) => <option key={destination.id} value={destination.id}>{destination.name}</option>)}
            </select>
            <select value={scheduleForm.toDestinationId} onChange={(event) => setScheduleForm((current) => ({ ...current, toDestinationId: Number(event.target.value) }))} className="rounded-2xl bg-surface-container-low px-5 py-3 outline-none" required>
              <option value={0}>Điểm đến</option>
              {destinations.map((destination) => <option key={destination.id} value={destination.id}>{destination.name}</option>)}
            </select>
            <input value={scheduleForm.departureAt} onChange={(event) => setScheduleForm((current) => ({ ...current, departureAt: event.target.value }))} type="datetime-local" className="rounded-2xl bg-surface-container-low px-5 py-3 outline-none" required />
            <input value={scheduleForm.arrivalAt} onChange={(event) => setScheduleForm((current) => ({ ...current, arrivalAt: event.target.value }))} type="datetime-local" className="rounded-2xl bg-surface-container-low px-5 py-3 outline-none" required />
            <input value={scheduleForm.price} onChange={(event) => setScheduleForm((current) => ({ ...current, price: Number(event.target.value) }))} type="number" min={0} placeholder="Giá vé" className="rounded-2xl bg-surface-container-low px-5 py-3 outline-none" required />
            <input value={scheduleForm.commissionRate} onChange={(event) => setScheduleForm((current) => ({ ...current, commissionRate: Number(event.target.value) }))} type="number" min={0} max={100} placeholder="% affiliate" className="rounded-2xl bg-surface-container-low px-5 py-3 outline-none" required />
            <input value={scheduleForm.totalSeats} onChange={(event) => setScheduleForm((current) => ({ ...current, totalSeats: Number(event.target.value) }))} type="number" min={1} placeholder="Tổng ghế" className="rounded-2xl bg-surface-container-low px-5 py-3 outline-none" required />
          </div>

          <div className="mt-6">
            <button type="submit" disabled={submitting} className="rounded-full bg-primary-container px-8 py-3 text-sm font-bold text-white disabled:opacity-50">
              {submitting ? 'Đang lưu...' : editingScheduleId ? 'Lưu thay đổi' : 'Tạo lịch trình'}
            </button>
          </div>
        </form>

        <form onSubmit={handleSubmitCompany} className="rounded-[2rem] bg-white p-8 shadow-[0px_20px_40px_rgba(21,28,39,0.04)] ring-1 ring-outline-variant/10">
          <div className="flex items-center justify-between gap-4 mb-6">
            <div>
              <h2 className="text-xl font-black text-on-surface">{editingCompanyId ? 'Cập nhật nhà xe' : 'Quản lý đối tác vận tải'}</h2>
              <p className="text-sm text-on-surface-variant mt-1">Thêm mới hoặc cập nhật nhanh thông tin đối tác.</p>
            </div>
            {editingCompanyId ? <button type="button" onClick={resetCompanyForm} className="rounded-full bg-surface-container-low px-5 py-2.5 text-sm font-bold text-on-surface">Hủy sửa</button> : null}
          </div>

          <div className="space-y-3">
            <input value={companyForm.name} onChange={(event) => setCompanyForm((current) => ({ ...current, name: event.target.value }))} placeholder="Tên nhà xe" className="w-full rounded-2xl bg-surface-container-low px-5 py-3 outline-none" required />
            <input value={companyForm.hotline} onChange={(event) => setCompanyForm((current) => ({ ...current, hotline: event.target.value }))} placeholder="Hotline" className="w-full rounded-2xl bg-surface-container-low px-5 py-3 outline-none" />
            <input value={companyForm.logoUrl} onChange={(event) => setCompanyForm((current) => ({ ...current, logoUrl: event.target.value }))} placeholder="Logo URL" className="w-full rounded-2xl bg-surface-container-low px-5 py-3 outline-none" />
          </div>

          <div className="mt-5">
            <button type="submit" disabled={submitting} className="rounded-full bg-primary-container px-6 py-3 text-sm font-bold text-white disabled:opacity-50">
              {editingCompanyId ? 'Lưu nhà xe' : 'Thêm nhà xe'}
            </button>
          </div>

          <div className="mt-8 space-y-3">
            {companies.map((company) => (
              <div key={company.id} className="rounded-[1.5rem] bg-surface-container-low p-4">
                <div className="flex items-start justify-between gap-4">
                  <div>
                    <p className="text-sm font-bold text-on-surface">{company.name}</p>
                    <p className="mt-1 text-xs text-on-surface-variant">{company.hotline} • {company.scheduleCount} lịch • Avg {company.averageCommissionRate}%</p>
                  </div>
                  <div className="flex gap-2">
                    <button type="button" onClick={() => { setEditingCompanyId(company.id); setCompanyForm({ name: company.name, hotline: company.hotline === '--' ? '' : company.hotline, logoUrl: company.logoUrl }); }} className="rounded-full bg-white px-4 py-2 text-xs font-bold text-on-surface">Sửa</button>
                    <button type="button" onClick={() => handleDeleteCompany(company)} className="rounded-full bg-error-container px-4 py-2 text-xs font-bold text-error">Xóa</button>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </form>
      </section>

      <section className="bg-surface-container-lowest rounded-[2rem] shadow-sm border border-outline-variant/5 overflow-hidden">
        <div className="px-8 py-6 flex flex-col lg:flex-row justify-between gap-4 lg:items-center border-b border-outline-variant/10">
          <div>
            <h2 className="text-lg font-black text-on-surface">Danh sách lịch trình chi tiết</h2>
            <p className="text-sm text-on-surface-variant mt-1">Top bar đang hỗ trợ tìm theo mã chuyến, nhà xe và tuyến đường.</p>
          </div>
          <div className="flex items-center gap-3 flex-wrap">
            {[
              { value: 'all', label: 'Tất cả' },
              { value: 'running', label: 'Đang chạy' },
              { value: 'upcoming', label: 'Chờ khởi hành' },
              { value: 'completed', label: 'Hoàn thành' },
            ].map((item) => (
              <button key={item.value} onClick={() => setStatusFilter(item.value as 'all' | AdminTransportSchedule['status'])} className={`rounded-full px-4 py-2 text-sm font-bold transition-all ${statusFilter === item.value ? 'bg-surface-container text-on-surface' : 'text-on-surface-variant hover:bg-surface-container-low'}`}>
                {item.label}
              </button>
            ))}
          </div>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-surface-container-low/50">
                <th className="px-8 py-4 text-[11px] font-black text-outline uppercase tracking-widest">Mã chuyến</th>
                <th className="px-8 py-4 text-[11px] font-black text-outline uppercase tracking-widest">Nhà xe / Tuyến đường</th>
                <th className="px-8 py-4 text-[11px] font-black text-outline uppercase tracking-widest text-center">Khởi hành</th>
                <th className="px-8 py-4 text-[11px] font-black text-outline uppercase tracking-widest text-center">Trạng thái</th>
                <th className="px-8 py-4 text-[11px] font-black text-outline uppercase tracking-widest text-right">Giá vé</th>
                <th className="px-8 py-4 text-[11px] font-black text-outline uppercase tracking-widest text-right">Lợi nhuận</th>
                <th className="px-8 py-4 text-[11px] font-black text-outline uppercase tracking-widest text-center">Ghế</th>
                <th className="px-8 py-4 text-[11px] font-black text-outline uppercase tracking-widest text-right">Hành động</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-outline-variant/10">
              {paginatedSchedules.map((schedule) => {
                const status = transportStatusConfig[schedule.status];

                return (
                  <tr key={schedule.id} className="hover:bg-surface-container-low/30 transition-colors">
                    <td className="px-8 py-6">
                      <span className="text-sm font-bold text-on-surface">{schedule.code}</span>
                    </td>
                    <td className="px-8 py-6">
                      <div className="flex items-center gap-4">
                        <div className={`w-10 h-10 rounded-full flex items-center justify-center ${status.iconClass}`}>
                          <span className="material-symbols-outlined text-xl">{status.icon}</span>
                        </div>
                        <div>
                          <p className="text-sm font-bold text-on-surface">{schedule.companyName}</p>
                          <p className="text-xs text-outline">{schedule.route}</p>
                        </div>
                      </div>
                    </td>
                    <td className="px-8 py-6 text-center">
                      <p className="text-sm font-medium text-on-surface">{schedule.departureTime}</p>
                      <p className="text-[10px] text-outline font-bold">{schedule.departureDate}</p>
                    </td>
                    <td className="px-8 py-6 text-center">
                      <span className={`px-3 py-1 rounded-full text-[10px] font-black uppercase ${status.badgeClass}`}>{status.label}</span>
                    </td>
                    <td className="px-8 py-6 text-right">
                      <span className="text-sm font-medium text-on-surface">{schedule.ticketPrice}</span>
                    </td>
                    <td className="px-8 py-6 text-right">
                      <span className="text-sm font-bold text-[#10B981]">{schedule.affiliateProfit}</span>
                    </td>
                    <td className="px-8 py-6 text-center">
                      <span className="inline-flex items-center justify-center px-3 py-1 rounded-full bg-surface-container-low text-on-surface text-xs font-bold">{schedule.occupiedSeats}/{schedule.totalSeats}</span>
                    </td>
                    <td className="px-8 py-6 text-right">
                      <div className="flex justify-end gap-2">
                        <button onClick={() => { setSelectedSchedule(schedule); setSeatDraft(schedule.seats); }} className="rounded-full bg-surface-container-low px-4 py-2 text-xs font-bold text-on-surface">Seat map</button>
                        <button onClick={() => handleEditSchedule(schedule)} className="rounded-full bg-white px-4 py-2 text-xs font-bold text-on-surface ring-1 ring-outline-variant/15">Sửa</button>
                        <button onClick={() => handleDeleteSchedule(schedule)} className="rounded-full bg-error-container px-4 py-2 text-xs font-bold text-error">Hủy</button>
                      </div>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>

        <div className="px-8 py-6 border-t border-outline-variant/10 flex flex-col md:flex-row justify-between gap-4 md:items-center">
          <p className="text-xs text-outline font-medium">Hiển thị {(currentPageClamped - 1) * PAGE_SIZE + (paginatedSchedules.length ? 1 : 0)} - {(currentPageClamped - 1) * PAGE_SIZE + paginatedSchedules.length} trong tổng số {filteredSchedules.length} chuyến xe</p>
          <div className="flex items-center gap-2">
            <button onClick={() => setCurrentPage((page) => Math.max(1, page - 1))} disabled={currentPageClamped === 1} className="w-10 h-10 rounded-full border border-outline-variant/20 flex items-center justify-center hover:bg-surface-container-low transition-all disabled:opacity-40">
              <span className="material-symbols-outlined text-lg">chevron_left</span>
            </button>
            {pageNumbers.map((page) => (
              <button key={page} onClick={() => setCurrentPage(page)} className={`w-10 h-10 rounded-full flex items-center justify-center font-bold text-sm transition-all ${page === currentPageClamped ? 'bg-primary-container text-white shadow-md' : 'border border-outline-variant/20 hover:bg-surface-container-low'}`}>
                {page}
              </button>
            ))}
            <button onClick={() => setCurrentPage((page) => Math.min(totalPages, page + 1))} disabled={currentPageClamped === totalPages} className="w-10 h-10 rounded-full border border-outline-variant/20 flex items-center justify-center hover:bg-surface-container-low transition-all disabled:opacity-40">
              <span className="material-symbols-outlined text-lg">chevron_right</span>
            </button>
          </div>
        </div>
      </section>

      {selectedSchedule ? (
        <section className="grid grid-cols-1 xl:grid-cols-[1.05fr_0.95fr] gap-8">
          <div className="rounded-[2rem] bg-white p-8 shadow-[0px_20px_40px_rgba(21,28,39,0.04)] ring-1 ring-outline-variant/10">
            <div className="flex items-center justify-between gap-4">
              <div>
                <p className="text-[10px] uppercase tracking-[0.2em] font-bold text-primary mb-2">Chi tiết chuyến xe</p>
                <h2 className="text-2xl font-black text-on-surface">{selectedSchedule.code}</h2>
                <p className="text-on-surface-variant mt-2">{selectedSchedule.companyName} • {selectedSchedule.route}</p>
              </div>
              <button onClick={() => setSelectedSchedule(null)} className="rounded-full bg-on-surface px-5 py-2.5 text-sm font-bold text-white">Đóng</button>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mt-8">
              <div className="bg-surface-container-low rounded-2xl p-5">
                <p className="text-[11px] font-bold uppercase tracking-wider text-outline">Tuyến đường</p>
                <p className="text-sm font-bold text-on-surface mt-2">{selectedSchedule.route}</p>
              </div>
              <div className="bg-surface-container-low rounded-2xl p-5">
                <p className="text-[11px] font-bold uppercase tracking-wider text-outline">Khởi hành</p>
                <p className="text-sm font-bold text-on-surface mt-2">{selectedSchedule.departureTime} • {selectedSchedule.departureDate}</p>
              </div>
              <div className="bg-surface-container-low rounded-2xl p-5">
                <p className="text-[11px] font-bold uppercase tracking-wider text-outline">Giá / affiliate</p>
                <p className="text-sm font-bold text-on-surface mt-2">{selectedSchedule.ticketPrice}</p>
                <p className="text-xs text-on-surface-variant mt-1">Hoa hồng {selectedSchedule.commissionRate}%</p>
              </div>
              <div className="bg-surface-container-low rounded-2xl p-5">
                <p className="text-[11px] font-bold uppercase tracking-wider text-outline">Ghế đã dùng</p>
                <p className="text-sm font-bold text-on-surface mt-2">{selectedSchedule.occupiedSeats}/{selectedSchedule.totalSeats}</p>
              </div>
            </div>
          </div>

          <div className="rounded-[2rem] bg-white p-8 shadow-[0px_20px_40px_rgba(21,28,39,0.04)] ring-1 ring-outline-variant/10">
            <div className="flex items-center justify-between gap-4">
              <div>
                <h2 className="text-xl font-black text-on-surface">Sơ đồ ghế</h2>
                <p className="text-sm text-on-surface-variant mt-1">Nhấn vào từng ghế để đổi trạng thái: trống → giữ chỗ → đã đặt.</p>
              </div>
              <button onClick={saveSeatMap} className="rounded-full bg-primary-container px-6 py-3 text-sm font-bold text-white">Lưu ghế</button>
            </div>
            <div className="mt-6 grid grid-cols-4 sm:grid-cols-6 gap-3">
              {seatDraft.map((seat) => (
                <button key={seat.id} onClick={() => handleSeatToggle(seat)} className={`rounded-2xl px-3 py-4 text-xs font-black transition-all ${seat.status === 'available' ? 'bg-surface-container-low text-on-surface' : seat.status === 'locked' ? 'bg-secondary-container/15 text-secondary-container' : 'bg-primary-container/15 text-primary-container'}`}>
                  <div>{seat.seatNumber}</div>
                  <div className="mt-1 uppercase tracking-widest text-[9px]">{seat.status}</div>
                </button>
              ))}
            </div>
          </div>
        </section>
      ) : null}

      <section className="grid grid-cols-1 xl:grid-cols-12 gap-8">
        <div className="xl:col-span-8 bg-surface-container-lowest p-8 rounded-xl shadow-sm border border-outline-variant/5">
          <div className="flex justify-between items-center mb-6">
            <h2 className="text-sm font-black text-on-surface uppercase tracking-widest">Phân tích vận hành</h2>
            <span className="text-xs text-primary font-bold">Cập nhật theo dữ liệu chuyến xe</span>
          </div>
          <div className="h-56 w-full bg-surface-container-low rounded-xl relative flex items-end justify-between p-6 overflow-hidden">
            <div className="absolute inset-0 bg-gradient-to-t from-primary/5 to-transparent"></div>
            {chartItems.map((item) => (
              <div key={item.label} className="relative z-10 flex h-full w-full flex-col justify-end items-center gap-3">
                <div className={`w-16 rounded-t-2xl ${item.color} shadow-lg shadow-black/5 transition-all`} style={{ height: `${Math.max(20, (item.value / maxChartValue) * 100)}%` }}></div>
                <div className="text-center">
                  <p className="text-sm font-black text-on-surface">{item.value}</p>
                  <p className="text-[10px] uppercase tracking-widest text-outline font-bold">{item.label}</p>
                </div>
              </div>
            ))}
          </div>
        </div>

        <div className="xl:col-span-4 space-y-4">
          <div className="bg-primary-container p-6 rounded-xl text-white shadow-xl shadow-primary-container/20 relative overflow-hidden">
            <div className="relative z-10">
              <p className="text-[10px] font-bold uppercase tracking-[0.2em] opacity-80 mb-2">Hiệu quả tháng này</p>
              <h2 className="text-lg font-bold mb-3">Tỷ lệ lấp đầy trung bình {stats.averageOccupancyRate.toFixed(1)}%</h2>
              <p className="text-sm leading-relaxed text-white/85">Dữ liệu ghế đang được tổng hợp trực tiếp từ seat map chi tiết của từng lịch trình.</p>
            </div>
            <span className="material-symbols-outlined absolute -right-4 -bottom-4 text-9xl opacity-10">support_agent</span>
          </div>
          <div className="bg-on-surface p-6 rounded-xl text-white shadow-sm flex items-center justify-between">
            <div>
              <p className="text-xs text-outline-variant font-medium">Dữ liệu sẵn sàng</p>
              <p className="text-sm font-bold">{stats.totalCompanies} đối tác nhà xe hoạt động</p>
            </div>
            <div className="w-10 h-10 rounded-full border border-white/20 flex items-center justify-center">
              <span className="material-symbols-outlined text-primary-container">bolt</span>
            </div>
          </div>
        </div>
      </section>
    </div>
  );
}
