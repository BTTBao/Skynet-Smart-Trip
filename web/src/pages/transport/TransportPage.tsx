import { useEffect, useState } from 'react';
import {
  adminService,
  type AdminTransportSchedule,
  type AdminTransportStats,
} from '../../services/adminService';

const formatCompactCurrency = (value: number) =>
  `${new Intl.NumberFormat('en-US', {
    notation: 'compact',
    maximumFractionDigits: 1,
  }).format(value)}đ`;

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
          <span
            className="material-symbols-outlined text-2xl"
            style={{ fontVariationSettings: "'FILL' 1" }}
          >
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

export default function TransportPage() {
  const [stats, setStats] = useState<AdminTransportStats | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchData = async () => {
      try {
        const data = await adminService.getTransportStats();
        setStats(data);
      } catch (error) {
        console.error('Failed to fetch transport stats:', error);
      } finally {
        setLoading(false);
      }
    };

    fetchData();
  }, []);

  if (loading) {
    return (
      <div className="flex items-center justify-center h-full min-h-[50vh]">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary"></div>
      </div>
    );
  }

  if (!stats) {
    return <div className="text-center text-error mt-10">Không thể tải dữ liệu chuyến xe.</div>;
  }

  const chartItems = [
    { label: 'Đang chạy', value: stats.activeSchedules, color: 'bg-primary-container' },
    { label: 'Sắp chạy', value: stats.upcomingSchedules, color: 'bg-secondary-container' },
    { label: 'Hoàn thành', value: stats.completedSchedules, color: 'bg-tertiary' },
  ];
  const maxChartValue = Math.max(...chartItems.map((item) => item.value), 1);

  return (
    <div className="space-y-12">
      <section>
        <div className="flex flex-col lg:flex-row justify-between items-start lg:items-end gap-6 mb-8">
          <div>
            <span className="text-[11px] font-bold text-primary-container tracking-[0.2em] uppercase">
              Báo cáo hệ thống
            </span>
            <h2 className="text-4xl font-black text-on-surface tracking-tight mt-1">
              Lịch Trình Chuyến Xe
            </h2>
            <p className="text-on-surface-variant mt-3 max-w-2xl">
              Theo dõi lịch trình, khả năng lấp đầy ghế và doanh thu affiliate từ các nhà
              xe đang hoạt động trên hệ thống.
            </p>
          </div>
          <div className="flex gap-3">
            <button className="px-6 py-2.5 bg-surface-container-lowest text-on-surface font-bold rounded-full shadow-sm hover:shadow-md transition-all flex items-center gap-2 border border-outline-variant/10">
              <span className="material-symbols-outlined text-lg">filter_list</span>
              <span>Lọc dữ liệu</span>
            </button>
            <button className="px-6 py-2.5 bg-primary-container text-white font-bold rounded-full shadow-lg shadow-primary-container/20 flex items-center gap-2 hover:scale-[0.98] transition-transform">
              <span className="material-symbols-outlined text-lg">download</span>
              <span>Xuất Excel</span>
            </button>
          </div>
        </div>

        <div className="grid grid-cols-1 xl:grid-cols-12 gap-6">
          <div className="xl:col-span-3">
            <MetricCard
              label="Tổng chuyến tháng này"
              value={stats.totalSchedulesThisMonth.toLocaleString()}
              icon="directions_bus"
              iconClass="bg-primary-fixed/30 text-primary"
              accent="text-primary bg-primary-fixed/50"
              helper={`${stats.totalCompanies} nhà xe`}
            />
          </div>
          <div className="xl:col-span-3">
            <MetricCard
              label="Doanh thu dự kiến"
              value={formatCompactCurrency(stats.expectedRevenueThisMonth)}
              icon="payments"
              iconClass="bg-secondary-fixed/50 text-secondary"
              accent="text-secondary bg-secondary-fixed"
              helper={`${stats.averageOccupancyRate.toFixed(1)}% lấp đầy`}
            />
          </div>
          <div className="xl:col-span-6 bg-surface-container-lowest p-8 rounded-xl shadow-sm border border-outline-variant/5 relative overflow-hidden flex items-center">
            <div className="relative z-10">
              <p className="text-outline text-xs font-bold uppercase tracking-wider mb-1">
                Hiệu suất Affiliate
              </p>
              <h3 className="text-3xl font-black text-on-surface tracking-tighter mb-2">
                {formatCompactCurrency(stats.affiliateRevenueThisMonth)}
              </h3>
              <p className="text-sm text-on-surface-variant mb-4">
                Tăng trưởng {stats.affiliateGrowthRate >= 0 ? '+' : ''}
                {stats.affiliateGrowthRate.toFixed(1)}% so với tháng trước.
              </p>
              <div className="flex flex-wrap gap-4">
                <div className="flex items-center gap-2">
                  <div className="w-2 h-2 rounded-full bg-primary-container"></div>
                  <span className="text-xs font-medium text-on-surface-variant">
                    {stats.activeSchedules} chuyến đang chạy
                  </span>
                </div>
                <div className="flex items-center gap-2">
                  <div className="w-2 h-2 rounded-full bg-secondary-container"></div>
                  <span className="text-xs font-medium text-on-surface-variant">
                    {stats.upcomingSchedules} chuyến sắp khởi hành
                  </span>
                </div>
                <div className="flex items-center gap-2">
                  <div className="w-2 h-2 rounded-full bg-tertiary"></div>
                  <span className="text-xs font-medium text-on-surface-variant">
                    {stats.completedSchedules} chuyến đã hoàn thành
                  </span>
                </div>
              </div>
            </div>
            <div className="absolute right-0 bottom-0 top-0 w-1/2 flex items-end justify-end p-4 opacity-20">
              <span className="material-symbols-outlined text-[120px] text-primary-container/40">
                query_stats
              </span>
            </div>
          </div>
        </div>
      </section>

      <section className="bg-surface-container-lowest rounded-xl shadow-sm border border-outline-variant/5 overflow-hidden">
        <div className="px-8 py-6 flex flex-col lg:flex-row justify-between gap-4 lg:items-center border-b border-outline-variant/10">
          <h3 className="text-lg font-bold text-on-surface">Danh sách lịch trình chi tiết</h3>
          <div className="flex items-center gap-3 text-xs text-outline italic">
            <span className="inline-flex items-center px-3 py-1 rounded-full bg-surface-container-low text-on-surface-variant font-semibold not-italic">
              {stats.totalCompanies} nhà xe đồng bộ
            </span>
            <span>Hiển thị lịch trình gần nhất từ cơ sở dữ liệu thật</span>
          </div>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-surface-container-low/50">
                <th className="px-8 py-4 text-[11px] font-black text-outline uppercase tracking-widest">
                  Mã chuyến
                </th>
                <th className="px-8 py-4 text-[11px] font-black text-outline uppercase tracking-widest">
                  Nhà xe / Tuyến đường
                </th>
                <th className="px-8 py-4 text-[11px] font-black text-outline uppercase tracking-widest text-center">
                  Khởi hành
                </th>
                <th className="px-8 py-4 text-[11px] font-black text-outline uppercase tracking-widest text-center">
                  Trạng thái
                </th>
                <th className="px-8 py-4 text-[11px] font-black text-outline uppercase tracking-widest text-right">
                  Giá vé
                </th>
                <th className="px-8 py-4 text-[11px] font-black text-outline uppercase tracking-widest text-right">
                  Lợi nhuận
                </th>
                <th className="px-8 py-4 text-[11px] font-black text-outline uppercase tracking-widest text-center">
                  Ghế
                </th>
              </tr>
            </thead>
            <tbody className="divide-y divide-outline-variant/10">
              {stats.schedules.map((schedule) => {
                const status = transportStatusConfig[schedule.status];

                return (
                  <tr
                    key={schedule.id}
                    className="hover:bg-surface-container-low/30 transition-colors group"
                  >
                    <td className="px-8 py-6">
                      <span className="text-sm font-bold text-on-surface">{schedule.code}</span>
                    </td>
                    <td className="px-8 py-6">
                      <div className="flex items-center gap-4">
                        <div
                          className={`w-10 h-10 rounded-full flex items-center justify-center ${status.iconClass}`}
                        >
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
                      <span
                        className={`px-3 py-1 rounded-full text-[10px] font-black uppercase ${status.badgeClass}`}
                      >
                        {status.label}
                      </span>
                    </td>
                    <td className="px-8 py-6 text-right">
                      <span className="text-sm font-medium text-on-surface">
                        {schedule.ticketPrice}
                      </span>
                    </td>
                    <td className="px-8 py-6 text-right">
                      <span className="text-sm font-bold text-[#10B981]">
                        {schedule.affiliateProfit}
                      </span>
                    </td>
                    <td className="px-8 py-6 text-center">
                      <span className="inline-flex items-center justify-center px-3 py-1 rounded-full bg-surface-container-low text-on-surface text-xs font-bold">
                        {schedule.occupiedSeats}/{schedule.totalSeats}
                      </span>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
        <div className="px-8 py-6 border-t border-outline-variant/10 flex flex-col md:flex-row justify-between gap-4 md:items-center">
          <p className="text-xs text-outline font-medium">
            Hiển thị 1 - {stats.schedules.length} trong tổng số{' '}
            {stats.totalSchedules.toLocaleString()} chuyến xe
          </p>
          <div className="flex items-center gap-2">
            <button className="w-10 h-10 rounded-full border border-outline-variant/20 flex items-center justify-center hover:bg-surface-container-low transition-all">
              <span className="material-symbols-outlined text-lg">chevron_left</span>
            </button>
            <button className="w-10 h-10 rounded-full bg-primary-container text-white flex items-center justify-center font-bold text-sm shadow-md">
              1
            </button>
            <button className="w-10 h-10 rounded-full border border-outline-variant/20 flex items-center justify-center hover:bg-surface-container-low transition-all font-bold text-sm">
              2
            </button>
            <button className="w-10 h-10 rounded-full border border-outline-variant/20 flex items-center justify-center hover:bg-surface-container-low transition-all font-bold text-sm">
              3
            </button>
            <button className="w-10 h-10 rounded-full border border-outline-variant/20 flex items-center justify-center hover:bg-surface-container-low transition-all">
              <span className="material-symbols-outlined text-lg">chevron_right</span>
            </button>
          </div>
        </div>
      </section>

      <section className="grid grid-cols-1 xl:grid-cols-12 gap-8">
        <div className="xl:col-span-8 bg-surface-container-lowest p-8 rounded-xl shadow-sm border border-outline-variant/5">
          <div className="flex justify-between items-center mb-6">
            <h4 className="text-sm font-black text-on-surface uppercase tracking-widest">
              Phân tích vận hành
            </h4>
            <span className="text-xs text-primary font-bold">Cập nhật theo dữ liệu chuyến xe</span>
          </div>
          <div className="h-56 w-full bg-surface-container-low rounded-xl relative flex items-end justify-between p-6 overflow-hidden">
            <div className="absolute inset-0 bg-gradient-to-t from-primary/5 to-transparent"></div>
            {chartItems.map((item) => (
              <div
                key={item.label}
                className="relative z-10 flex h-full w-full flex-col justify-end items-center gap-3"
              >
                <div
                  className={`w-16 rounded-t-2xl ${item.color} shadow-lg shadow-black/5 transition-all`}
                  style={{ height: `${Math.max(20, (item.value / maxChartValue) * 100)}%` }}
                ></div>
                <div className="text-center">
                  <p className="text-sm font-black text-on-surface">{item.value}</p>
                  <p className="text-[10px] uppercase tracking-widest text-outline font-bold">
                    {item.label}
                  </p>
                </div>
              </div>
            ))}
          </div>
        </div>

        <div className="xl:col-span-4 space-y-4">
          <div className="bg-primary-container p-6 rounded-xl text-white shadow-xl shadow-primary-container/20 relative overflow-hidden">
            <div className="relative z-10">
              <p className="text-[10px] font-bold uppercase tracking-[0.2em] opacity-80 mb-2">
                Hiệu quả tháng này
              </p>
              <h4 className="text-lg font-bold mb-3">
                Tỷ lệ lấp đầy trung bình {stats.averageOccupancyRate.toFixed(1)}%
              </h4>
              <p className="text-sm leading-relaxed text-white/85">
                Dữ liệu ghế đang được tổng hợp trực tiếp từ các lịch trình đã đồng bộ cùng
                trạng thái chỗ ngồi.
              </p>
            </div>
            <span className="material-symbols-outlined absolute -right-4 -bottom-4 text-9xl opacity-10">
              support_agent
            </span>
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
