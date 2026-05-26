import { useEffect, useMemo, useState } from 'react';
import { adminService, type AdminCreateUserRequest, type AdminUser, type AdminUserStats } from '../../services/adminService';
import { downloadCsv, getPageNumbers } from '../../utils/adminActions';

const PAGE_SIZE = 6;

const statusConfig = {
  active: {
    label: 'Hoạt động',
    bgClass: 'bg-primary-container/10',
    textClass: 'text-primary-container',
    avatarClass: 'bg-primary-container/20 text-primary',
  },
  blocked: {
    label: 'Đã khóa',
    bgClass: 'bg-error-container/20',
    textClass: 'text-error',
    avatarClass: 'bg-error-container/20 text-error',
  },
};

const initialForm: AdminCreateUserRequest = {
  name: '',
  email: '',
  phone: '',
  role: 'customer',
  isActive: true,
};

function UserStatCard({
  label,
  value,
  icon,
  badge,
  iconClass,
}: {
  label: string;
  value: string;
  icon: string;
  badge: string;
  iconClass: string;
}) {
  return (
    <div className="bg-white p-8 rounded-xl shadow-[0px_20px_40px_rgba(21,28,39,0.03)] border border-surface-container-high/50">
      <div className="flex items-center justify-between mb-5">
        <span className={`material-symbols-outlined p-3 rounded-2xl ${iconClass}`} style={{ fontVariationSettings: "'FILL' 1" }}>
          {icon}
        </span>
        <span className="text-[10px] font-bold uppercase tracking-widest text-on-surface-variant">{badge}</span>
      </div>
      <p className="text-[11px] font-bold text-on-surface-variant uppercase tracking-wider">{label}</p>
      <h3 className="text-3xl font-black text-on-surface mt-2">{value}</h3>
    </div>
  );
}

export default function UsersInteractivePage() {
  const [stats, setStats] = useState<AdminUserStats | null>(null);
  const [loading, setLoading] = useState(true);
  const [statusFilter, setStatusFilter] = useState<'all' | AdminUser['status']>('all');
  const [sortOrder, setSortOrder] = useState<'newest' | 'oldest'>('newest');
  const [currentPage, setCurrentPage] = useState(1);
  const [selectedUser, setSelectedUser] = useState<AdminUser | null>(null);
  const [showCreateForm, setShowCreateForm] = useState(false);
  const [createForm, setCreateForm] = useState<AdminCreateUserRequest>(initialForm);
  const [submitting, setSubmitting] = useState(false);

  const loadUsers = async () => {
    const data = await adminService.getUsers();
    setStats(data);
  };

  useEffect(() => {
    const fetchData = async () => {
      try {
        await loadUsers();
      } catch (error) {
        console.error('Failed to fetch user stats:', error);
      } finally {
        setLoading(false);
      }
    };

    fetchData();
  }, []);

  useEffect(() => {
    setCurrentPage(1);
  }, [statusFilter, sortOrder]);

  const filteredUsers = useMemo(() => {
    if (!stats) {
      return [];
    }

    return stats.users
      .filter((user) => statusFilter === 'all' || user.status === statusFilter)
      .sort((first, second) => {
        const firstValue = first.joinDate.split('/').reverse().join('');
        const secondValue = second.joinDate.split('/').reverse().join('');
        return sortOrder === 'newest'
          ? secondValue.localeCompare(firstValue)
          : firstValue.localeCompare(secondValue);
      });
  }, [stats, sortOrder, statusFilter]);

  const totalPages = Math.max(1, Math.ceil(filteredUsers.length / PAGE_SIZE));
  const currentPageClamped = Math.min(currentPage, totalPages);
  const paginatedUsers = filteredUsers.slice((currentPageClamped - 1) * PAGE_SIZE, currentPageClamped * PAGE_SIZE);
  const pageNumbers = getPageNumbers(currentPageClamped, totalPages);

  const exportUsers = () => {
    downloadCsv(`users-${statusFilter}-${sortOrder}.csv`, filteredUsers, [
      { key: 'displayId', header: 'Mã người dùng' },
      { key: 'name', header: 'Tên' },
      { key: 'email', header: 'Email' },
      { key: 'phone', header: 'Số điện thoại' },
      { key: 'joinDate', header: 'Ngày tham gia' },
      { key: 'status', header: 'Trạng thái' },
    ]);
  };

  const handleToggleStatus = async (user: AdminUser) => {
    try {
      const updated = await adminService.updateUserStatus(user.id, user.status !== 'active');
      await loadUsers();
      if (selectedUser?.id === user.id) {
        setSelectedUser(updated);
      }
    } catch (error) {
      console.error('Failed to update user status:', error);
      window.alert('Không thể cập nhật trạng thái người dùng.');
    }
  };

  const handleCreateUser = async (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    setSubmitting(true);

    try {
      await adminService.createUser(createForm);
      setCreateForm(initialForm);
      setShowCreateForm(false);
      await loadUsers();
    } catch (error) {
      console.error('Failed to create user:', error);
      window.alert('Không thể tạo thành viên mới. Vui lòng kiểm tra email có bị trùng không.');
    } finally {
      setSubmitting(false);
    }
  };

  if (loading) {
    return <div className="flex items-center justify-center h-full min-h-[50vh]"><div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary"></div></div>;
  }

  if (!stats) {
    return <div className="text-center text-error mt-10">Không thể tải dữ liệu người dùng.</div>;
  }

  return (
    <div className="space-y-12">
      <div className="flex justify-between items-end gap-6 flex-wrap">
        <div>
          <h2 className="text-[3.5rem] font-bold tracking-tight text-on-surface leading-none mb-2">
            Quản lý Người dùng
          </h2>
          <p className="text-on-surface-variant font-medium">
            Theo dõi, tạo mới và cập nhật trạng thái thành viên hệ thống Skynet Smart Trip.
          </p>
        </div>
        <div className="flex gap-4">
          <button
            onClick={exportUsers}
            className="px-8 py-3 bg-surface-container-high text-on-surface font-bold rounded-full hover:brightness-95 transition-all cursor-pointer"
          >
            Xuất báo cáo
          </button>
          <button
            onClick={() => setShowCreateForm((value) => !value)}
            className="px-8 py-3 bg-primary-container text-white font-bold rounded-full hover:brightness-110 transition-all shadow-lg shadow-primary-container/30 cursor-pointer"
          >
            {showCreateForm ? 'Ẩn biểu mẫu' : 'Thêm thành viên'}
          </button>
        </div>
      </div>

      {showCreateForm && (
        <form onSubmit={handleCreateUser} className="bg-white rounded-xl p-8 shadow-[0px_20px_40px_rgba(21,28,39,0.03)] border border-surface-container-high/50">
          <div className="flex items-center justify-between gap-4 mb-6">
            <div>
              <h3 className="text-xl font-bold text-on-surface">Tạo thành viên mới</h3>
              <p className="text-sm text-on-surface-variant mt-1">Tạo nhanh tài khoản admin quản lý được ngay từ trang này.</p>
            </div>
            <button
              type="button"
              onClick={() => {
                setShowCreateForm(false);
                setCreateForm(initialForm);
              }}
              className="px-5 py-2.5 rounded-full bg-surface-container-low text-on-surface font-bold hover:bg-surface-container transition-all"
            >
              Hủy
            </button>
          </div>
          <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
            <input value={createForm.name} onChange={(event) => setCreateForm((form) => ({ ...form, name: event.target.value }))} placeholder="Họ tên" className="px-5 py-3 rounded-2xl bg-surface-container-low border border-transparent focus:border-primary-container focus:outline-none" required />
            <input value={createForm.email} onChange={(event) => setCreateForm((form) => ({ ...form, email: event.target.value }))} placeholder="Email" type="email" className="px-5 py-3 rounded-2xl bg-surface-container-low border border-transparent focus:border-primary-container focus:outline-none" required />
            <input value={createForm.phone} onChange={(event) => setCreateForm((form) => ({ ...form, phone: event.target.value }))} placeholder="Số điện thoại" className="px-5 py-3 rounded-2xl bg-surface-container-low border border-transparent focus:border-primary-container focus:outline-none" />
            <label className="flex items-center justify-between px-5 py-3 rounded-2xl bg-surface-container-low">
              <span className="text-sm font-semibold text-on-surface">Kích hoạt ngay</span>
              <input checked={createForm.isActive} onChange={(event) => setCreateForm((form) => ({ ...form, isActive: event.target.checked }))} type="checkbox" className="w-4 h-4 accent-[#10B981]" />
            </label>
          </div>
          <div className="mt-6">
            <button type="submit" disabled={submitting} className="px-8 py-3 bg-primary-container text-white font-bold rounded-full hover:brightness-110 transition-all disabled:opacity-50 disabled:cursor-not-allowed">
              {submitting ? 'Đang tạo...' : 'Tạo thành viên'}
            </button>
          </div>
        </form>
      )}

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <UserStatCard label="Tổng người dùng" value={stats.totalUsers.toLocaleString()} icon="groups" badge="Khách hàng" iconClass="bg-surface-container text-on-surface" />
        <UserStatCard label="Đang hoạt động" value={stats.activeUsers.toLocaleString()} icon="person_check" badge="Khả dụng" iconClass="bg-primary-container/10 text-primary-container" />
        <UserStatCard label="Thành viên mới" value={stats.newUsers.toLocaleString()} icon="person_add" badge="Tháng này" iconClass="bg-tertiary-container/10 text-tertiary" />
        <UserStatCard label="Tài khoản bị khóa" value={stats.blockedUsers.toLocaleString()} icon="block" badge="Cần chú ý" iconClass="bg-secondary-container/10 text-secondary-container" />
      </div>

      <div className="flex flex-wrap gap-4 items-center justify-between bg-surface-container-low p-6 rounded-xl">
        <div className="flex gap-4 items-center">
          <div className="relative">
            <select value={statusFilter} onChange={(event) => setStatusFilter(event.target.value as 'all' | AdminUser['status'])} className="appearance-none bg-surface-container-lowest border-none py-3 pl-6 pr-12 rounded-full text-sm font-bold text-on-surface focus:ring-2 focus:ring-primary-container focus:outline-none cursor-pointer">
              <option value="all">Tất cả trạng thái</option>
              <option value="active">Đang hoạt động</option>
              <option value="blocked">Ngừng hoạt động</option>
            </select>
            <span className="material-symbols-outlined absolute right-4 top-1/2 -translate-y-1/2 pointer-events-none text-on-surface-variant">expand_more</span>
          </div>
          <div className="relative">
            <select value={sortOrder} onChange={(event) => setSortOrder(event.target.value as 'newest' | 'oldest')} className="appearance-none bg-surface-container-lowest border-none py-3 pl-6 pr-12 rounded-full text-sm font-bold text-on-surface focus:ring-2 focus:ring-primary-container focus:outline-none cursor-pointer">
              <option value="newest">Mới nhất</option>
              <option value="oldest">Cũ nhất</option>
            </select>
            <span className="material-symbols-outlined absolute right-4 top-1/2 -translate-y-1/2 pointer-events-none text-on-surface-variant">calendar_month</span>
          </div>
        </div>
        <div className="text-on-surface-variant text-sm font-medium">
          Hiển thị {paginatedUsers.length} trên {filteredUsers.length} kết quả
        </div>
      </div>

      <div className="bg-surface-container-lowest rounded-xl overflow-hidden shadow-sm">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead className="bg-surface-container-low">
              <tr>
                <th className="px-8 py-6 text-[10px] font-black uppercase tracking-widest text-on-surface-variant">Thành viên</th>
                <th className="px-8 py-6 text-[10px] font-black uppercase tracking-widest text-on-surface-variant">Email</th>
                <th className="px-8 py-6 text-[10px] font-black uppercase tracking-widest text-on-surface-variant">Số điện thoại</th>
                <th className="px-8 py-6 text-[10px] font-black uppercase tracking-widest text-on-surface-variant">Ngày tham gia</th>
                <th className="px-8 py-6 text-[10px] font-black uppercase tracking-widest text-on-surface-variant">Trạng thái</th>
                <th className="px-8 py-6 text-right text-[10px] font-black uppercase tracking-widest text-on-surface-variant">Hành động</th>
              </tr>
            </thead>
            <tbody>
              {paginatedUsers.map((user) => {
                const status = statusConfig[user.status];

                return (
                  <tr key={user.id} className="hover:bg-surface-container-low/50 transition-colors group">
                    <td className="px-8 py-6">
                      <div className="flex items-center gap-4">
                        <div className={`w-12 h-12 rounded-full ${status.avatarClass} flex items-center justify-center group-hover:scale-110 transition-transform`}>
                          <span className="material-symbols-outlined font-bold text-[20px]">person</span>
                        </div>
                        <div>
                          <p className="font-bold text-on-surface">{user.name}</p>
                          <p className="text-[10px] text-on-surface-variant">ID: {user.displayId}</p>
                        </div>
                      </div>
                    </td>
                    <td className="px-8 py-6 text-sm text-on-surface-variant font-medium">{user.email}</td>
                    <td className="px-8 py-6 text-sm text-on-surface-variant font-medium">{user.phone}</td>
                    <td className="px-8 py-6 text-sm text-on-surface-variant font-medium">{user.joinDate}</td>
                    <td className="px-8 py-6">
                      <span className={`inline-flex items-center px-4 py-1.5 ${status.bgClass} ${status.textClass} text-xs font-bold rounded-full`}>
                        {status.label}
                      </span>
                    </td>
                    <td className="px-8 py-6 text-right">
                      <div className="flex items-center justify-end gap-2">
                        <button onClick={() => handleToggleStatus(user)} className={`px-4 py-2 rounded-full text-xs font-bold transition-all ${
                          user.status === 'active'
                            ? 'bg-error-container/60 text-error hover:bg-error-container'
                            : 'bg-primary-container/10 text-primary-container hover:bg-primary-container/20'
                        }`}>
                          {user.status === 'active' ? 'Khóa' : 'Mở khóa'}
                        </button>
                        <button onClick={() => setSelectedUser(user)} className="p-2 hover:bg-surface-container rounded-full transition-all cursor-pointer">
                          <span className="material-symbols-outlined">more_vert</span>
                        </button>
                      </div>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      </div>

      {selectedUser && (
        <div className="bg-white rounded-xl shadow-[0px_20px_40px_rgba(21,28,39,0.03)] border border-surface-container-high/50 p-8">
          <div className="flex flex-col md:flex-row justify-between gap-6">
            <div>
              <p className="text-[10px] uppercase tracking-[0.2em] font-bold text-primary mb-2">Chi tiết thành viên</p>
              <h3 className="text-2xl font-black text-on-surface">{selectedUser.name}</h3>
              <p className="text-on-surface-variant mt-2">{selectedUser.displayId}</p>
            </div>
            <div className="flex gap-3">
              <button onClick={() => handleToggleStatus(selectedUser)} className={`px-5 py-2.5 rounded-full font-bold transition-all ${
                selectedUser.status === 'active'
                  ? 'bg-error-container text-error'
                  : 'bg-primary-container text-white'
              }`}>
                {selectedUser.status === 'active' ? 'Khóa tài khoản' : 'Mở khóa tài khoản'}
              </button>
              <button onClick={() => setSelectedUser(null)} className="px-5 py-2.5 rounded-full bg-surface-container-low text-on-surface font-bold hover:bg-surface-container transition-all">
                Đóng
              </button>
            </div>
          </div>
          <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mt-8">
            <div className="bg-surface-container-low rounded-2xl p-5">
              <p className="text-[11px] font-bold uppercase tracking-wider text-on-surface-variant">Email</p>
              <p className="text-sm font-bold text-on-surface mt-2">{selectedUser.email}</p>
            </div>
            <div className="bg-surface-container-low rounded-2xl p-5">
              <p className="text-[11px] font-bold uppercase tracking-wider text-on-surface-variant">Điện thoại</p>
              <p className="text-sm font-bold text-on-surface mt-2">{selectedUser.phone}</p>
            </div>
            <div className="bg-surface-container-low rounded-2xl p-5">
              <p className="text-[11px] font-bold uppercase tracking-wider text-on-surface-variant">Ngày tham gia</p>
              <p className="text-sm font-bold text-on-surface mt-2">{selectedUser.joinDate}</p>
            </div>
            <div className="bg-surface-container-low rounded-2xl p-5">
              <p className="text-[11px] font-bold uppercase tracking-wider text-on-surface-variant">Trạng thái</p>
              <p className="text-sm font-bold text-on-surface mt-2">{statusConfig[selectedUser.status].label}</p>
            </div>
          </div>
        </div>
      )}

      <div className="flex items-center justify-between pb-10">
        <button onClick={() => setCurrentPage((page) => Math.max(1, page - 1))} disabled={currentPageClamped === 1} className="flex items-center gap-2 px-6 py-3 bg-surface-container-low rounded-full font-bold text-on-surface hover:bg-surface-container transition-all cursor-pointer disabled:opacity-40 disabled:cursor-not-allowed">
          <span className="material-symbols-outlined text-sm">arrow_back</span>
          Trước
        </button>
        <div className="flex items-center gap-2">
          {pageNumbers.map((page) => (
            <button key={page} onClick={() => setCurrentPage(page)} className={`w-10 h-10 flex items-center justify-center rounded-full font-medium transition-all cursor-pointer ${
              currentPageClamped === page
                ? 'bg-primary-container text-white font-bold'
                : 'hover:bg-surface-container'
            }`}>
              {page}
            </button>
          ))}
        </div>
        <button onClick={() => setCurrentPage((page) => Math.min(totalPages, page + 1))} disabled={currentPageClamped === totalPages} className="flex items-center gap-2 px-6 py-3 bg-surface-container-low rounded-full font-bold text-on-surface hover:bg-surface-container transition-all cursor-pointer disabled:opacity-40 disabled:cursor-not-allowed">
          Sau
          <span className="material-symbols-outlined text-sm">arrow_forward</span>
        </button>
      </div>
    </div>
  );
}
