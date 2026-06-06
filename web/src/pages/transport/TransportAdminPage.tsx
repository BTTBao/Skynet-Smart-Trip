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
const DEFAULT_TRIP_DURATION_HOURS = 6;

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
  commissionRate: 8,
};

const transportStatusConfig: Record<AdminTransportSchedule['status'], { label: string; badgeClass: string; icon: string; iconClass: string }> = {
  running: { label: 'Dang chay', badgeClass: 'bg-primary-fixed text-on-primary-fixed-variant', icon: 'directions_bus', iconClass: 'bg-primary-fixed/40 text-primary' },
  upcoming: { label: 'Cho khoi hanh', badgeClass: 'bg-surface-container-high text-on-surface-variant', icon: 'commute', iconClass: 'bg-secondary-fixed text-on-secondary-fixed' },
  completed: { label: 'Hoan thanh', badgeClass: 'bg-tertiary-fixed text-on-tertiary-fixed-variant', icon: 'task_alt', iconClass: 'bg-tertiary-fixed-dim text-on-tertiary-container' },
};

const toDateTimeLocal = (value: string) => {
  if (!value) return '';
  const date = new Date(value);
  const tz = date.getTimezoneOffset();
  const local = new Date(date.getTime() - tz * 60_000);
  return local.toISOString().slice(0, 16);
};

const addHoursToDateTimeLocal = (value: string, hours: number) => {
  if (!value) return '';
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return '';
  const adjusted = new Date(date.getTime() + Math.max(hours, 0) * 60 * 60 * 1000);
  return toDateTimeLocal(adjusted.toISOString());
};

const getDurationHoursBetween = (departureAt: string, arrivalAt: string) => {
  if (!departureAt || !arrivalAt) return DEFAULT_TRIP_DURATION_HOURS;
  const departure = new Date(departureAt);
  const arrival = new Date(arrivalAt);
  if (Number.isNaN(departure.getTime()) || Number.isNaN(arrival.getTime())) {
    return DEFAULT_TRIP_DURATION_HOURS;
  }

  const diffHours = (arrival.getTime() - departure.getTime()) / (60 * 60 * 1000);
  return diffHours > 0 ? Math.round(diffHours * 10) / 10 : DEFAULT_TRIP_DURATION_HOURS;
};

const formatDateTimePreview = (value: string) => {
  if (!value) return '--';
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return '--';
  return new Intl.DateTimeFormat('vi-VN', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  }).format(date);
};

const formatCompactCurrency = (value: number) =>
  `${new Intl.NumberFormat('en-US', { notation: 'compact', maximumFractionDigits: 1 }).format(value)}d`;

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
  const [estimatedDurationHours, setEstimatedDurationHours] = useState(DEFAULT_TRIP_DURATION_HOURS);
  const [editingScheduleId, setEditingScheduleId] = useState<number | null>(null);
  const [companyForm, setCompanyForm] = useState<AdminCreateTransportCompanyRequest>(emptyCompanyForm);
  const [editingCompanyId, setEditingCompanyId] = useState<number | null>(null);
  const [seatDraft, setSeatDraft] = useState<AdminTransportSeat[]>([]);
  const [submitting, setSubmitting] = useState(false);
  const [uploadingCompanyLogo, setUploadingCompanyLogo] = useState(false);
  const [showGuide, setShowGuide] = useState(false);

  const hasCompanyLogoPreview = companyForm.logoUrl.trim().length > 0;

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
        showToast({ type: 'error', title: 'Khong the tai du lieu van tai', message: getErrorMessage(error) });
      } finally {
        setLoading(false);
      }
    };

    void fetchData();
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

  useEffect(() => {
    const nextArrivalAt = addHoursToDateTimeLocal(scheduleForm.departureAt, estimatedDurationHours);
    setScheduleForm((current) => (current.arrivalAt === nextArrivalAt ? current : { ...current, arrivalAt: nextArrivalAt }));
  }, [estimatedDurationHours, scheduleForm.departureAt]);

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

  const exportSchedules = () => {
    downloadCsv(`transport-schedules-${statusFilter}.csv`, filteredSchedules, [
      { key: 'code', header: 'Ma chuyen' },
      { key: 'companyName', header: 'Nha xe' },
      { key: 'route', header: 'Tuyen duong' },
      { key: 'departureDate', header: 'Ngay khoi hanh' },
      { key: 'departureTime', header: 'Gio khoi hanh' },
      { key: 'status', header: 'Trang thai' },
      { key: 'ticketPrice', header: 'Gia ve' },
      { key: 'affiliateProfit', header: 'Loi nhuan affiliate' },
    ]);
    showToast({ type: 'success', title: 'Da xuat danh sach lich trinh' });
  };

  const resetScheduleForm = () => {
    setEditingScheduleId(null);
    setScheduleForm(emptyScheduleForm);
    setEstimatedDurationHours(DEFAULT_TRIP_DURATION_HOURS);
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
      showToast({ type: 'success', title: editingScheduleId ? 'Da cap nhat lich trinh' : 'Da tao lich trinh moi' });
    } catch (error) {
      showToast({ type: 'error', title: 'Khong the luu lich trinh', message: getErrorMessage(error) });
    } finally {
      setSubmitting(false);
    }
  };

  const handleEditSchedule = (schedule: AdminTransportSchedule) => {
    setEditingScheduleId(schedule.id);
    setEstimatedDurationHours(getDurationHoursBetween(schedule.departureAt, schedule.arrivalAt));
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
      showToast({ type: 'success', title: 'Da huy lich trinh', message: schedule.code });
    } catch (error) {
      showToast({ type: 'error', title: 'Khong the huy lich trinh', message: getErrorMessage(error) });
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
      showToast({ type: 'success', title: editingCompanyId ? 'Da cap nhat nha xe' : 'Da them nha xe' });
    } catch (error) {
      showToast({ type: 'error', title: 'Khong the luu nha xe', message: getErrorMessage(error) });
    } finally {
      setSubmitting(false);
    }
  };

  const handleEditCompany = (company: AdminTransportCompany) => {
    setEditingCompanyId(company.id);
    setCompanyForm({
      name: company.name,
      hotline: company.hotline === '--' ? '' : company.hotline,
      logoUrl: company.logoUrl,
      commissionRate: company.commissionRate,
    });
  };

  const handleScheduleCompanyChange = (companyId: number) => {
    const company = companies.find((item) => item.id === companyId);
    setScheduleForm((current) => ({
      ...current,
      companyId,
      commissionRate: company ? company.commissionRate : current.commissionRate,
    }));
  };

  const handleDeleteCompany = async (company: AdminTransportCompany) => {
    try {
      await adminService.deleteTransportCompany(company.id);
      await loadTransport();
      showToast({ type: 'success', title: 'Da xoa nha xe', message: company.name });
    } catch (error) {
      showToast({ type: 'error', title: 'Khong the xoa nha xe', message: getErrorMessage(error) });
    }
  };

  const handleCompanyLogoUpload = async (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (!file) return;

    setUploadingCompanyLogo(true);
    try {
      const result = await adminService.uploadTransportCompanyLogo(file);
      setCompanyForm((current) => ({ ...current, logoUrl: result.imageUrl }));
      showToast({ type: 'success', title: 'Da tai logo nha xe' });
    } catch (error) {
      showToast({ type: 'error', title: 'Khong the tai logo', message: getErrorMessage(error) });
    } finally {
      setUploadingCompanyLogo(false);
      event.target.value = '';
    }
  };

  const handleSeatToggle = (seat: AdminTransportSeat) => {
    setSeatDraft((current) =>
      current.map((item) =>
        item.id === seat.id
          ? { ...item, status: item.status === 'available' ? 'locked' : item.status === 'locked' ? 'booked' : 'available' }
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
      showToast({ type: 'success', title: 'Da luu so do ghe' });
    } catch (error) {
      showToast({ type: 'error', title: 'Khong the luu so do ghe', message: getErrorMessage(error) });
    }
  };

  if (loading) {
    return <div className="flex min-h-[50vh] items-center justify-center"><div className="h-12 w-12 animate-spin rounded-full border-b-2 border-primary" /></div>;
  }

  if (!stats) {
    return <div className="mt-10 text-center text-error">Khong the tai du lieu van tai.</div>;
  }

  const chartItems = [
    { label: 'Dang chay', value: stats.activeSchedules, color: 'bg-primary-container' },
    { label: 'Sap chay', value: stats.upcomingSchedules, color: 'bg-secondary-container' },
    { label: 'Hoan thanh', value: stats.completedSchedules, color: 'bg-tertiary' },
  ];
  const maxChartValue = Math.max(...chartItems.map((item) => item.value), 1);

  return (
    <div className="space-y-8">
      <div className="flex flex-col justify-between gap-4 xl:flex-row xl:items-start">
        <div>
          <p className="mb-1 text-xs font-bold uppercase tracking-widest text-primary">Van tai</p>
          <h1 className="text-3xl font-black text-on-surface">Quan ly tuyen xe</h1>
          <p className="mt-1 max-w-xl text-sm text-on-surface-variant">Tao lich trinh, quan ly nha xe, loi nhuan chot va seat map.</p>
        </div>
        <div className="flex flex-wrap gap-2">
          <button onClick={() => setShowGuide(true)} className="rounded-full bg-amber-500 px-5 py-2.5 text-sm font-bold text-white transition hover:bg-amber-600">Huong dan</button>
          <button onClick={exportSchedules} className="rounded-full bg-slate-100 px-5 py-2.5 text-sm font-bold text-slate-700 transition hover:bg-slate-200">Xuat CSV</button>
        </div>
      </div>

      <div className="grid grid-cols-1 gap-4 md:grid-cols-4">
        <MetricCard label="Tong lich trinh" value={stats.totalSchedules.toLocaleString()} helper={`${stats.totalSchedulesThisMonth} thang nay`} icon="route" />
        <MetricCard label="Doanh thu du kien" value={formatCompactCurrency(stats.expectedRevenueThisMonth)} helper="Thang nay" icon="payments" />
        <MetricCard label="Loi nhuan affiliate" value={formatCompactCurrency(stats.affiliateRevenueThisMonth)} helper={`${stats.affiliateGrowthRate.toFixed(1)}%`} icon="account_balance_wallet" />
        <MetricCard label="Ty le lap day" value={`${stats.averageOccupancyRate.toFixed(1)}%`} helper={`${stats.totalCompanies} nha xe`} icon="event_seat" />
      </div>

      <section className="grid grid-cols-1 gap-8 xl:grid-cols-[1.3fr_0.7fr]">
        <form onSubmit={handleSubmitSchedule} className="rounded-[2rem] bg-white p-8 shadow-[0px_20px_40px_rgba(21,28,39,0.04)] ring-1 ring-outline-variant/10">
          <div className="mb-6 flex items-center justify-between gap-4">
            <div>
              <h2 className="text-xl font-black text-on-surface">{editingScheduleId ? 'Chinh sua lich trinh' : 'Them chuyen xe moi'}</h2>
              <p className="mt-1 text-sm text-on-surface-variant">Chot gia ve, gio chay va ty le loi nhuan.</p>
            </div>
            {editingScheduleId ? <button type="button" onClick={resetScheduleForm} className="rounded-full bg-surface-container-low px-5 py-2.5 text-sm font-bold text-on-surface">Huy sua</button> : null}
          </div>

          <div className="grid grid-cols-1 gap-4 md:grid-cols-2 xl:grid-cols-4">
            <div className="space-y-2">
              <FieldLabel htmlFor="transport-company">Nha xe</FieldLabel>
              <select id="transport-company" value={scheduleForm.companyId} onChange={(event) => handleScheduleCompanyChange(Number(event.target.value))} className={inputCls} required>
                <option value={0}>Chon nha xe</option>
                {companies.map((company) => <option key={company.id} value={company.id}>{company.name}</option>)}
              </select>
            </div>
            <div className="space-y-2">
              <FieldLabel htmlFor="transport-from">Diem di</FieldLabel>
              <select id="transport-from" value={scheduleForm.fromDestinationId} onChange={(event) => setScheduleForm((current) => ({ ...current, fromDestinationId: Number(event.target.value) }))} className={inputCls} required>
                <option value={0}>Chon diem di</option>
                {destinations.map((destination) => <option key={destination.id} value={destination.id}>{destination.name}</option>)}
              </select>
            </div>
            <div className="space-y-2">
              <FieldLabel htmlFor="transport-to">Diem den</FieldLabel>
              <select id="transport-to" value={scheduleForm.toDestinationId} onChange={(event) => setScheduleForm((current) => ({ ...current, toDestinationId: Number(event.target.value) }))} className={inputCls} required>
                <option value={0}>Chon diem den</option>
                {destinations.map((destination) => <option key={destination.id} value={destination.id}>{destination.name}</option>)}
              </select>
            </div>
            <div className="space-y-2">
              <FieldLabel htmlFor="transport-departure">Khoi hanh luc</FieldLabel>
              <input id="transport-departure" value={scheduleForm.departureAt} onChange={(event) => setScheduleForm((current) => ({ ...current, departureAt: event.target.value }))} type="datetime-local" className={inputCls} required />
            </div>
            <div className="space-y-2">
              <FieldLabel htmlFor="transport-duration">Thoi gian du kien (gio)</FieldLabel>
              <input id="transport-duration" value={estimatedDurationHours} onChange={(event) => setEstimatedDurationHours(Number(event.target.value))} type="number" min={0.5} step={0.5} className={inputCls} required />
            </div>
            <div className="space-y-2">
              <FieldLabel htmlFor="transport-price">Gia ve (VND)</FieldLabel>
              <input id="transport-price" value={scheduleForm.price} onChange={(event) => setScheduleForm((current) => ({ ...current, price: Number(event.target.value) }))} type="number" min={0} placeholder="Nhap gia ve" className={inputCls} required />
            </div>
            <div className="space-y-2">
              <FieldLabel htmlFor="transport-commission">Loi nhuan chot (%)</FieldLabel>
              <input id="transport-commission" value={scheduleForm.commissionRate} onChange={(event) => setScheduleForm((current) => ({ ...current, commissionRate: Number(event.target.value) }))} type="number" min={0} max={100} placeholder="Vi du 8" className={inputCls} required />
            </div>
            <div className="space-y-2">
              <FieldLabel htmlFor="transport-seats">Tong so ghe</FieldLabel>
              <input id="transport-seats" value={scheduleForm.totalSeats} onChange={(event) => setScheduleForm((current) => ({ ...current, totalSeats: Number(event.target.value) }))} type="number" min={1} placeholder="Vi du 36" className={inputCls} required />
            </div>
          </div>

          <div className="mt-4 rounded-[1.5rem] bg-surface-container-low px-5 py-4 text-sm text-on-surface-variant">
            <p className="font-bold text-on-surface">Gio den du kien</p>
            <p className="mt-1">{formatDateTimePreview(scheduleForm.arrivalAt)}</p>
          </div>

          <button type="submit" disabled={submitting} className="mt-6 rounded-full bg-primary px-8 py-3 text-sm font-bold text-white disabled:opacity-50">
            {submitting ? 'Dang luu...' : editingScheduleId ? 'Luu thay doi' : 'Tao lich trinh'}
          </button>
        </form>

        <form onSubmit={handleSubmitCompany} className="rounded-[2rem] bg-white p-8 shadow-[0px_20px_40px_rgba(21,28,39,0.04)] ring-1 ring-outline-variant/10">
          <div className="mb-6 flex items-center justify-between gap-4">
            <div>
              <h2 className="text-xl font-black text-on-surface">{editingCompanyId ? 'Cap nhat nha xe' : 'Quan ly doi tac van tai'}</h2>
              <p className="mt-1 text-sm text-on-surface-variant">Them moi hoac cap nhat nha xe.</p>
            </div>
            {editingCompanyId ? <button type="button" onClick={resetCompanyForm} className="rounded-full bg-surface-container-low px-5 py-2.5 text-sm font-bold text-on-surface">Huy sua</button> : null}
          </div>

          <div className="space-y-3">
            <div className="space-y-2">
              <FieldLabel htmlFor="company-name">Ten nha xe</FieldLabel>
              <input id="company-name" value={companyForm.name} onChange={(event) => setCompanyForm((current) => ({ ...current, name: event.target.value }))} placeholder="Nhap ten nha xe" className={inputCls} required />
            </div>
            <div className="space-y-2">
              <FieldLabel htmlFor="company-hotline">Hotline</FieldLabel>
              <input id="company-hotline" value={companyForm.hotline} onChange={(event) => setCompanyForm((current) => ({ ...current, hotline: event.target.value }))} placeholder="Nhap hotline" className={inputCls} />
            </div>
            <div className="space-y-2">
              <FieldLabel htmlFor="company-commission">Affiliate mac dinh (%)</FieldLabel>
              <input id="company-commission" value={companyForm.commissionRate} onChange={(event) => setCompanyForm((current) => ({ ...current, commissionRate: Number(event.target.value) }))} type="number" min={0} max={100} placeholder="Vi du 8" className={inputCls} required />
            </div>
            <div className="space-y-2">
              <FieldLabel htmlFor="company-logo">Logo nha xe</FieldLabel>
              <div className="flex gap-2">
                <input id="company-logo" value={companyForm.logoUrl} onChange={(event) => setCompanyForm((current) => ({ ...current, logoUrl: event.target.value }))} placeholder="Duong dan logo sau khi tai len" className={`${inputCls} min-w-0 flex-1`} />
                <label className="cursor-pointer rounded-2xl bg-surface-container-low px-4 py-3 text-sm font-bold text-on-surface">
                {uploadingCompanyLogo ? 'Dang tai' : 'Upload'}
                <input type="file" accept="image/jpeg,image/png,image/webp" disabled={uploadingCompanyLogo} onChange={handleCompanyLogoUpload} className="hidden" />
                </label>
              </div>
            </div>
            {hasCompanyLogoPreview ? (
              <div className="overflow-hidden rounded-[1.5rem] border border-outline-variant/10 bg-surface-container-low">
                <div className="flex items-center justify-between px-4 py-3">
                  <p className="text-xs font-bold text-on-surface-variant">Preview logo nha xe</p>
                  <button type="button" onClick={() => setCompanyForm((current) => ({ ...current, logoUrl: '' }))} className="rounded-full bg-white px-3 py-1.5 text-xs font-bold text-on-surface">Xoa anh</button>
                </div>
                <div className="flex items-center justify-center bg-white px-6 py-6">
                  <img src={companyForm.logoUrl} alt="Company logo preview" className="h-24 w-24 rounded-3xl object-cover ring-1 ring-outline-variant/10" />
                </div>
              </div>
            ) : (
              <div className="rounded-[1.5rem] border border-dashed border-outline-variant/20 bg-surface-container-low px-5 py-6 text-center text-sm font-bold text-on-surface-variant">Upload logo de xem preview tai day</div>
            )}
          </div>

          <button type="submit" disabled={submitting} className="mt-5 rounded-full bg-primary px-6 py-3 text-sm font-bold text-white disabled:opacity-50">
            {editingCompanyId ? 'Luu nha xe' : 'Them nha xe'}
          </button>

          <div className="mt-8 space-y-3">
            {companies.map((company) => (
              <div key={company.id} className="rounded-[1.5rem] bg-surface-container-low p-4">
                <div className="flex items-start justify-between gap-4">
                  <div className="flex items-center gap-4">
                    <div className="flex h-14 w-14 items-center justify-center overflow-hidden rounded-2xl bg-white ring-1 ring-outline-variant/10">
                      {company.logoUrl ? <img src={company.logoUrl} alt="" className="h-full w-full object-cover" /> : <span className="material-symbols-outlined text-on-surface-variant">image</span>}
                    </div>
                    <div>
                      <p className="text-sm font-bold text-on-surface">{company.name}</p>
                      <p className="mt-1 text-xs text-on-surface-variant">{company.hotline} . {company.scheduleCount} lich . Mac dinh {company.commissionRate}% . Avg {company.averageCommissionRate}%</p>
                    </div>
                  </div>
                  <div className="flex gap-2">
                    <button type="button" onClick={() => handleEditCompany(company)} className="rounded-full bg-white px-4 py-2 text-xs font-bold text-on-surface">Sua</button>
                    <button type="button" onClick={() => handleDeleteCompany(company)} className="rounded-full bg-error-container px-4 py-2 text-xs font-bold text-error">Xoa</button>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </form>
      </section>

      <section className="overflow-hidden rounded-[2rem] border border-outline-variant/5 bg-surface-container-lowest shadow-sm">
        <div className="flex flex-col justify-between gap-4 border-b border-outline-variant/10 px-8 py-6 lg:flex-row lg:items-center">
          <div>
            <h2 className="text-lg font-black text-on-surface">Danh sach lich trinh chi tiet</h2>
            <p className="mt-1 text-sm text-on-surface-variant">Tim theo ma chuyen, nha xe va tuyen duong.</p>
          </div>
          <div className="flex flex-wrap items-center gap-3">
            {[
              { value: 'all', label: 'Tat ca' },
              { value: 'running', label: 'Dang chay' },
              { value: 'upcoming', label: 'Cho khoi hanh' },
              { value: 'completed', label: 'Hoan thanh' },
            ].map((item) => (
              <button key={item.value} onClick={() => setStatusFilter(item.value as 'all' | AdminTransportSchedule['status'])} className={`rounded-full px-4 py-2 text-sm font-bold transition-all ${statusFilter === item.value ? 'bg-surface-container text-on-surface' : 'text-on-surface-variant hover:bg-surface-container-low'}`}>
                {item.label}
              </button>
            ))}
          </div>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full border-collapse text-left">
            <thead>
              <tr className="bg-surface-container-low/50">
                <th className="px-8 py-4 text-[11px] font-black uppercase tracking-widest text-outline">Ma chuyen</th>
                <th className="px-8 py-4 text-[11px] font-black uppercase tracking-widest text-outline">Nha xe / Tuyen duong</th>
                <th className="px-8 py-4 text-center text-[11px] font-black uppercase tracking-widest text-outline">Khoi hanh</th>
                <th className="px-8 py-4 text-center text-[11px] font-black uppercase tracking-widest text-outline">Trang thai</th>
                <th className="px-8 py-4 text-right text-[11px] font-black uppercase tracking-widest text-outline">Gia ve</th>
                <th className="px-8 py-4 text-right text-[11px] font-black uppercase tracking-widest text-outline">Loi nhuan</th>
                <th className="px-8 py-4 text-center text-[11px] font-black uppercase tracking-widest text-outline">Ghe</th>
                <th className="px-8 py-4 text-right text-[11px] font-black uppercase tracking-widest text-outline">Hanh dong</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-outline-variant/10">
              {paginatedSchedules.map((schedule) => {
                const status = transportStatusConfig[schedule.status];
                return (
                  <tr key={schedule.id} className="transition-colors hover:bg-surface-container-low/30">
                    <td className="px-8 py-6"><span className="text-sm font-bold text-on-surface">{schedule.code}</span></td>
                    <td className="px-8 py-6">
                      <div className="flex items-center gap-4">
                        <div className={`flex h-10 w-10 items-center justify-center rounded-full ${status.iconClass}`}><span className="material-symbols-outlined text-xl">{status.icon}</span></div>
                        <div>
                          <p className="text-sm font-bold text-on-surface">{schedule.companyName}</p>
                          <p className="text-xs text-outline">{schedule.route}</p>
                        </div>
                      </div>
                    </td>
                    <td className="px-8 py-6 text-center"><p className="text-sm font-medium text-on-surface">{schedule.departureTime}</p><p className="text-[10px] font-bold text-outline">{schedule.departureDate}</p></td>
                    <td className="px-8 py-6 text-center"><span className={`rounded-full px-3 py-1 text-[10px] font-black uppercase ${status.badgeClass}`}>{status.label}</span></td>
                    <td className="px-8 py-6 text-right"><span className="text-sm font-medium text-on-surface">{schedule.ticketPrice}</span></td>
                    <td className="px-8 py-6 text-right"><span className="text-sm font-bold text-[#10B981]">{schedule.affiliateProfit}</span></td>
                    <td className="px-8 py-6 text-center"><span className="inline-flex items-center justify-center rounded-full bg-surface-container-low px-3 py-1 text-xs font-bold text-on-surface">{schedule.occupiedSeats}/{schedule.totalSeats}</span></td>
                    <td className="px-8 py-6 text-right">
                      <div className="flex justify-end gap-2">
                        <button onClick={() => { setSelectedSchedule(schedule); setSeatDraft(schedule.seats); }} className="rounded-full bg-surface-container-low px-4 py-2 text-xs font-bold text-on-surface">Seat map</button>
                        <button onClick={() => handleEditSchedule(schedule)} className="rounded-full bg-white px-4 py-2 text-xs font-bold text-on-surface ring-1 ring-outline-variant/15">Sua</button>
                        <button onClick={() => handleDeleteSchedule(schedule)} className="rounded-full bg-error-container px-4 py-2 text-xs font-bold text-error">Huy</button>
                      </div>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>

        <div className="flex flex-col justify-between gap-4 border-t border-outline-variant/10 px-8 py-6 md:flex-row md:items-center">
          <p className="text-xs font-medium text-outline">Hien thi {(currentPageClamped - 1) * PAGE_SIZE + (paginatedSchedules.length ? 1 : 0)} - {(currentPageClamped - 1) * PAGE_SIZE + paginatedSchedules.length} / {filteredSchedules.length}</p>
          <div className="flex items-center gap-2">
            {pageNumbers.map((page) => (
              <button key={page} onClick={() => setCurrentPage(page)} className={`flex h-10 w-10 items-center justify-center rounded-full text-sm font-bold transition-all ${page === currentPageClamped ? 'bg-primary-container text-white shadow-md' : 'border border-outline-variant/20 hover:bg-surface-container-low'}`}>{page}</button>
            ))}
          </div>
        </div>
      </section>

      {selectedSchedule ? (
        <section className="grid grid-cols-1 gap-8 xl:grid-cols-[1.05fr_0.95fr]">
          <div className="rounded-[2rem] bg-white p-8 shadow-[0px_20px_40px_rgba(21,28,39,0.04)] ring-1 ring-outline-variant/10">
            <div className="flex items-center justify-between gap-4">
              <div>
                <p className="mb-2 text-[10px] font-bold uppercase tracking-[0.2em] text-primary">Chi tiet chuyen xe</p>
                <h2 className="text-2xl font-black text-on-surface">{selectedSchedule.code}</h2>
                <p className="mt-2 text-on-surface-variant">{selectedSchedule.companyName} . {selectedSchedule.route}</p>
              </div>
              <button onClick={() => setSelectedSchedule(null)} className="rounded-full bg-on-surface px-5 py-2.5 text-sm font-bold text-white">Dong</button>
            </div>
            <div className="mt-8 grid grid-cols-1 gap-4 md:grid-cols-4">
              <DetailCard label="Tuyen duong" value={selectedSchedule.route} />
              <DetailCard label="Khoi hanh" value={`${selectedSchedule.departureTime} . ${selectedSchedule.departureDate}`} />
              <DetailCard label="Gia / affiliate" value={`${selectedSchedule.ticketPrice} / ${selectedSchedule.commissionRate}%`} />
              <DetailCard label="Ghe da dung" value={`${selectedSchedule.occupiedSeats}/${selectedSchedule.totalSeats}`} />
            </div>
          </div>

          <div className="rounded-[2rem] bg-white p-8 shadow-[0px_20px_40px_rgba(21,28,39,0.04)] ring-1 ring-outline-variant/10">
            <div className="flex items-center justify-between gap-4">
              <div>
                <h2 className="text-xl font-black text-on-surface">So do ghe</h2>
                <p className="mt-1 text-sm text-on-surface-variant">Nhan vao ghe de doi trang thai.</p>
              </div>
              <button onClick={saveSeatMap} className="rounded-full bg-primary-container px-6 py-3 text-sm font-bold text-white">Luu ghe</button>
            </div>
            <div className="mt-6 grid grid-cols-4 gap-3 sm:grid-cols-6">
              {seatDraft.map((seat) => (
                <button key={seat.id} onClick={() => handleSeatToggle(seat)} className={`rounded-2xl px-3 py-4 text-xs font-black transition-all ${seat.status === 'available' ? 'bg-surface-container-low text-on-surface' : seat.status === 'locked' ? 'bg-secondary-container/15 text-secondary-container' : 'bg-primary-container/15 text-primary-container'}`}>
                  <div>{seat.seatNumber}</div>
                  <div className="mt-1 text-[9px] uppercase tracking-widest">{seat.status === 'available' ? 'Trong' : seat.status === 'locked' ? 'Giu cho' : 'Da dat'}</div>
                </button>
              ))}
            </div>
          </div>
        </section>
      ) : null}

      <section className="grid grid-cols-1 gap-8 xl:grid-cols-12">
        <div className="rounded-xl border border-outline-variant/5 bg-surface-container-lowest p-8 shadow-sm xl:col-span-8">
          <div className="mb-6 flex items-center justify-between">
            <h2 className="text-sm font-black uppercase tracking-widest text-on-surface">Phan tich van hanh</h2>
            <span className="text-xs font-bold text-primary">Theo du lieu chuyen xe</span>
          </div>
          <div className="relative flex h-56 w-full items-end justify-between overflow-hidden rounded-xl bg-surface-container-low p-6">
            {chartItems.map((item) => (
              <div key={item.label} className="relative z-10 flex h-full w-full flex-col items-center justify-end gap-3">
                <div className={`w-16 rounded-t-2xl ${item.color} shadow-lg shadow-black/5`} style={{ height: `${Math.max(20, (item.value / maxChartValue) * 100)}%` }} />
                <div className="text-center"><p className="text-sm font-black text-on-surface">{item.value}</p><p className="text-[10px] font-bold uppercase tracking-widest text-outline">{item.label}</p></div>
              </div>
            ))}
          </div>
        </div>
        <div className="space-y-4 xl:col-span-4">
          <div className="relative overflow-hidden rounded-xl bg-primary-container p-6 text-white shadow-xl shadow-primary-container/20">
            <p className="mb-2 text-[10px] font-bold uppercase tracking-[0.2em] opacity-80">Hieu qua thang nay</p>
            <h2 className="mb-3 text-lg font-bold">Ty le lap day trung binh {stats.averageOccupancyRate.toFixed(1)}%</h2>
            <p className="text-sm leading-relaxed text-white/85">Du lieu ghe tong hop tu seat map cua tung lich trinh.</p>
          </div>
        </div>
      </section>

      {showGuide && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 p-4 backdrop-blur-sm">
          <div className="w-full max-w-2xl rounded-[2.5rem] bg-white p-8 shadow-2xl ring-1 ring-black/5">
            <div className="flex items-start justify-between border-b border-slate-100 pb-4">
              <div>
                <p className="text-[11px] font-black uppercase tracking-[0.22em] text-amber-600">Huong dan su dung</p>
                <h3 className="mt-1 text-2xl font-black text-slate-900">Van hanh lich trinh chuyen xe</h3>
              </div>
              <button type="button" onClick={() => setShowGuide(false)} className="rounded-full bg-slate-100 px-4 py-2 text-xs font-bold text-slate-900 transition-colors hover:bg-slate-200">Dong</button>
            </div>
            <div className="mt-6 max-h-[50vh] space-y-6 overflow-y-auto pr-2 text-sm leading-relaxed text-slate-600">
              <div className="rounded-[1.4rem] border border-amber-500/10 bg-amber-500/5 p-5">
                <h4 className="text-base font-bold text-amber-800">Seat map va hoa hong</h4>
                <ul className="mt-3 list-inside list-disc space-y-2 font-medium text-amber-950">
                  <li>Seat map doi theo vong: trong, giu cho, da dat.</li>
                  <li>Loi nhuan affiliate tinh theo gia ve va ty le hoa hong da chot.</li>
                  <li>Khi tao chuyen moi, can chon dung nha xe, diem di, diem den, gio chay va thoi gian du kien.</li>
                </ul>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

const inputCls = 'w-full rounded-2xl bg-surface-container-low px-5 py-3 outline-none';

function FieldLabel({ htmlFor, children }: { htmlFor: string; children: string }) {
  return <label htmlFor={htmlFor} className="block text-xs font-bold uppercase tracking-wider text-outline">{children}</label>;
}

function MetricCard({ label, value, helper, icon }: { label: string; value: string; helper: string; icon: string }) {
  return (
    <div className="rounded-xl border border-outline-variant/5 bg-surface-container-lowest p-6 shadow-sm">
      <div className="mb-4 flex items-start justify-between">
        <div className="flex h-12 w-12 items-center justify-center rounded-2xl bg-primary/10 text-primary">
          <span className="material-symbols-outlined text-2xl" style={{ fontVariationSettings: "'FILL' 1" }}>{icon}</span>
        </div>
        <span className="rounded-full bg-surface-container px-2 py-1 text-[10px] font-bold text-on-surface-variant">{helper}</span>
      </div>
      <p className="mb-1 text-xs font-bold uppercase tracking-wider text-outline">{label}</p>
      <h3 className="text-3xl font-black tracking-tighter text-on-surface">{value}</h3>
    </div>
  );
}

function DetailCard({ label, value }: { label: string; value: string }) {
  return (
    <div className="rounded-2xl bg-surface-container-low p-5">
      <p className="text-[11px] font-bold uppercase tracking-wider text-outline">{label}</p>
      <p className="mt-2 text-sm font-bold text-on-surface">{value}</p>
    </div>
  );
}
