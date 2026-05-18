import { useEffect, useState } from 'react';
import StatCard from './StatCard';
import RevenueChart from './RevenueChart';
import PartnerCTA from './PartnerCTA';
import RecentBookings from './RecentBookings';
import { adminService, type AdminDashboardStats } from '../../services/adminService';

// Format numbers (e.g., 4200000 -> 4.2M, 12000 -> 12K)
const formatCompactNumber = (number: number) => {
  return new Intl.NumberFormat('en-US', {
    notation: "compact",
    maximumFractionDigits: 1
  }).format(number);
};

export default function DashboardPage() {
  const [stats, setStats] = useState<AdminDashboardStats | null>(null);
  const [loading, setLoading] = useState(true);

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

  if (loading) {
    return <div className="flex items-center justify-center h-full min-h-[50vh]"><div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary"></div></div>;
  }

  if (!stats) {
    return <div className="text-center text-error mt-10">Không thể tải dữ liệu dashboard</div>;
  }

  return (
    <>
      {/* Hero Metrics */}
      <section className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <StatCard
          label="Tổng Doanh thu"
          value={formatCompactNumber(stats.totalRevenue) + '₫'}
          icon="payments"
          iconBgClass="bg-tertiary-fixed"
          iconTextClass="text-on-tertiary-container"
          valueClass="text-[#10B981]"
          footer={
            <>
              <span className="text-[11px] text-on-surface-variant/50">Toàn thời gian</span>
            </>
          }
        />
        <StatCard
          label="Tổng Lợi nhuận (Affiliate)"
          value={formatCompactNumber(stats.totalProfit) + '₫'}
          icon="account_balance_wallet"
          iconBgClass="bg-primary-container/10"
          iconTextClass="text-primary-container"
          valueClass="text-[#10B981]"
          footer={
            <>
              <span className="text-[11px] text-on-surface-variant/50">Từ các đặt phòng và chuyến đi</span>
            </>
          }
        />
        <StatCard
          label="Tổng Người dùng"
          value={stats.totalUsers.toLocaleString()}
          icon="group"
          iconBgClass="bg-surface-container"
          iconTextClass="text-on-surface"
          valueClass="text-on-surface"
          footer={
            <>
              <span className="text-secondary text-xs font-bold flex items-center gap-0.5">
                <span className="material-symbols-outlined text-[14px]">person_add</span>
                +{stats.newUsersToday}
              </span>
              <span className="text-[11px] text-on-surface-variant/50">mới trong hôm nay</span>
            </>
          }
        />
        <StatCard
          label="Chuyến đi đang diễn ra"
          value={stats.activeTrips.toString()}
          icon="travel_explore"
          iconBgClass="bg-secondary-fixed"
          iconTextClass="text-secondary"
          valueClass="text-on-surface"
          footer={
            <>
              <span className="text-[11px] text-on-surface-variant font-medium">
                Dữ liệu thực tế từ hệ thống
              </span>
            </>
          }
        />
      </section>

      {/* Chart & CTA Bento */}
      <section className="grid grid-cols-1 lg:grid-cols-3 gap-10">
        <RevenueChart />
        <PartnerCTA />
      </section>

      {/* Recent Bookings */}
      <RecentBookings bookings={stats.recentBookings} />
    </>
  );
}
