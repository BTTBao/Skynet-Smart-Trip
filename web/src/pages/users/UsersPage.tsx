import { useEffect, useState } from 'react';
import UserStatCard from './UserStatCard';
import UserTable from './UserTable';
import { adminService, type AdminUserStats } from '../../services/adminService';

export default function UsersPage() {
  const [stats, setStats] = useState<AdminUserStats | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchData = async () => {
      try {
        const data = await adminService.getUsers();
        setStats(data);
      } catch (error) {
        console.error('Failed to fetch user stats:', error);
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
    return <div className="text-center text-error mt-10">Không thể tải dữ liệu người dùng</div>;
  }

  return (
    <div className="space-y-12">
      {/* Header */}
      <div className="flex justify-between items-end">
        <div>
          <h2 className="text-[3.5rem] font-bold tracking-tight text-on-surface leading-none mb-2">
            Quản lý Người dùng
          </h2>
          <p className="text-on-surface-variant font-medium">
            Theo dõi và quản lý danh sách thành viên hệ thống Skynet Smart Trip.
          </p>
        </div>
        <div className="flex gap-4">
          <button className="px-8 py-3 bg-surface-container-high text-on-surface font-bold rounded-full hover:brightness-95 transition-all cursor-pointer">
            Xuất báo cáo
          </button>
          <button className="px-8 py-3 bg-primary-container text-white font-bold rounded-full hover:brightness-110 transition-all shadow-lg shadow-primary-container/30 cursor-pointer">
            Thêm thành viên
          </button>
        </div>
      </div>

      {/* Stats Bento Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <UserStatCard
          icon="groups"
          iconBgClass="bg-surface-container"
          iconTextClass="text-on-surface"
          label="Tổng người dùng"
          value={stats.totalUsers.toLocaleString()}
          badge={
            <span className="text-[10px] font-bold uppercase tracking-widest text-on-surface-variant">
              Khách hàng
            </span>
          }
        />
        <UserStatCard
          icon="person_check"
          iconBgClass="bg-primary-container/10"
          iconTextClass="text-primary-container"
          iconFilled
          label="Đang hoạt động"
          value={stats.activeUsers.toLocaleString()}
          borderClass="border-b-4 border-primary-container"
          badge={
            <span className="px-2 py-1 bg-primary-container/10 text-primary-container text-[10px] font-bold rounded-full">
              Khả dụng
            </span>
          }
        />
        <UserStatCard
          icon="person_add"
          iconBgClass="bg-tertiary-container/10"
          iconTextClass="text-tertiary"
          label="Thành viên mới"
          value={stats.newUsers.toLocaleString()}
          badge={
            <span className="text-on-surface-variant text-[10px] font-bold">THÁNG NÀY</span>
          }
        />
        <UserStatCard
          icon="block"
          iconBgClass="bg-secondary-container/10"
          iconTextClass="text-secondary-container"
          label="Tài khoản bị khóa"
          value={stats.blockedUsers.toLocaleString()}
          borderClass="border-b-4 border-secondary-container"
          badge={
            <span className="material-symbols-outlined text-secondary-container text-sm">
              warning
            </span>
          }
        />
      </div>

      {/* User Table with Controls & Pagination */}
      <UserTable users={stats.users} total={stats.totalUsers} />
    </div>
  );
}
