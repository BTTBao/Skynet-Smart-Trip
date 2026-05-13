import { useEffect, useMemo, useState } from 'react';
import { useAdminSearch, useToast } from '../../context';
import {
  adminService,
  type AdminCreateUserRequest,
  type AdminUpdateUserRequest,
  type AdminUser,
  type AdminUserStats,
} from '../../services/adminService';
import { downloadCsv, getPageNumbers } from '../../utils/adminActions';
import { getErrorMessage } from '../../utils/http';

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
    bgClass: 'bg-error-container/30',
    textClass: 'text-error',
    avatarClass: 'bg-error-container/30 text-error',
  },
};

const roleOptions: Array<{ value: AdminUser['role']; label: string }> = [
  { value: 'customer', label: 'Customer' },
  { value: 'staff', label: 'Staff' },
  { value: 'partner', label: 'Partner' },
  { value: 'admin', label: 'Admin' },
];

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

export default function UsersAdminPage() {
  const { query } = useAdminSearch();
  const { showToast } = useToast();
  const [stats, setStats] = useState<AdminUserStats | null>(null);
  const [loading, setLoading] = useState(true);
  const [statusFilter, setStatusFilter] = useState<'all' | AdminUser['status']>('all');
  const [roleFilter, setRoleFilter] = useState<'all' | AdminUser['role']>('all');
  const [sortOrder, setSortOrder] = useState<'newest' | 'oldest'>('newest');
  const [currentPage, setCurrentPage] = useState(1);
  const [selectedUser, setSelectedUser] = useState<AdminUser | null>(null);
  const [editingUser, setEditingUser] = useState<AdminUser | null>(null);
  const [showCreateForm, setShowCreateForm] = useState(false);
  const [createForm, setCreateForm] = useState<AdminCreateUserRequest>(initialForm);
  const [editForm, setEditForm] = useState<AdminUpdateUserRequest>(initialForm);
  const [submitting, setSubmitting] = useState(false);

  const loadUsers = async (search = query) => {
    const data = await adminService.getUsers({ search: search.trim() || undefined });
    setStats(data);
  };

  useEffect(() => {
    const fetchData = async () => {
      try {
        await loadUsers();
      } catch (error) {
        showToast({
          type: 'error',
          title: 'Không thể tải dữ liệu người dùng',
          message: getErrorMessage(error),
        });
      } finally {
        setLoading(false);
      }
    };

    fetchData();
  }, []);

  useEffect(() => {
    const handle = window.setTimeout(async () => {
      try {
        await loadUsers();
      } catch (error) {
        showToast({
          type: 'error',
          title: 'Không thể tìm kiếm người dùng',
          message: getErrorMessage(error),
        });
      }
    }, 250);

    return () => window.clearTimeout(handle);
  }, [query]);

  useEffect(() => {
    setCurrentPage(1);
  }, [statusFilter, roleFilter, sortOrder, query]);

  const filteredUsers = useMemo(() => {
    if (!stats) {
      return [];
    }

    return stats.users
      .filter((user) => statusFilter === 'all' || user.status === statusFilter)
      .filter((user) => roleFilter === 'all' || user.role === roleFilter)
      .sort((first, second) => {
        const firstValue = first.joinDate.split('/').reverse().join('');
        const secondValue = second.joinDate.split('/').reverse().join('');
        return sortOrder === 'newest'
          ? secondValue.localeCompare(firstValue)
          : firstValue.localeCompare(secondValue);
      });
  }, [roleFilter, sortOrder, stats, statusFilter]);

  const totalPages = Math.max(1, Math.ceil(filteredUsers.length / PAGE_SIZE));
  const currentPageClamped = Math.min(currentPage, totalPages);
  const paginatedUsers = filteredUsers.slice((currentPageClamped - 1) * PAGE_SIZE, currentPageClamped * PAGE_SIZE);
  const pageNumbers = getPageNumbers(currentPageClamped, totalPages);

  const exportUsers = () => {
    downloadCsv(`users-${statusFilter}-${roleFilter}.csv`, filteredUsers, [
      { key: 'displayId', header: 'Mã người dùng' },
      { key: 'name', header: 'Tên' },
      { key: 'email', header: 'Email' },
      { key: 'phone', header: 'Số điện thoại' },
      { key: 'role', header: 'Phân quyền' },
      { key: 'joinDate', header: 'Ngày tham gia' },
      { key: 'lastLoginAt', header: 'Lần đăng nhập gần nhất' },
      { key: 'status', header: 'Trạng thái' },
    ]);

    showToast({
      type: 'success',
      title: 'Đã xuất danh sách người dùng',
      message: 'File CSV đã được tải xuống thành công.',
    });
  };

  const handleToggleStatus = async (user: AdminUser) => {
    try {
      const updated = await adminService.updateUserStatus(user.id, user.status !== 'active');
      await loadUsers();
      if (selectedUser?.id === user.id) {
        setSelectedUser(updated);
      }

      showToast({
        type: 'success',
        title: updated.status === 'active' ? 'Đã mở khóa tài khoản' : 'Đã khóa tài khoản',
        message: `${updated.name} đã được cập nhật trạng thái.`,
      });
    } catch (error) {
      showToast({
        type: 'error',
        title: 'Không thể cập nhật trạng thái',
        message: getErrorMessage(error),
      });
    }
  };

  const handleCreateUser = async (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    setSubmitting(true);

    try {
      const created = await adminService.createUser(createForm);
      setCreateForm(initialForm);
      setShowCreateForm(false);
      await loadUsers('');

      showToast({
        type: 'success',
        title: 'Đã tạo thành viên mới',
        message: `${created.name} được khởi tạo với quyền ${created.role}.`,
      });
    } catch (error) {
      showToast({
        type: 'error',
        title: 'Không thể tạo thành viên',
        message: getErrorMessage(error),
      });
    } finally {
      setSubmitting(false);
    }
  };

  const handleSaveUser = async (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    if (!editingUser) {
      return;
    }

    setSubmitting(true);

    try {
      const updated = await adminService.updateUser(editingUser.id, editForm);
      setEditingUser(null);
      await loadUsers();

      if (selectedUser?.id === updated.id) {
        setSelectedUser(updated);
      }

      showToast({
        type: 'success',
        title: 'Đã cập nhật người dùng',
        message: `${updated.name} đã được lưu thay đổi.`,
      });
    } catch (error) {
      showToast({
        type: 'error',
        title: 'Không thể cập nhật người dùng',
        message: getErrorMessage(error),
      });
    } finally {
      setSubmitting(false);
    }
  };

  const handleDeleteUser = async (user: AdminUser) => {
    try {
      await adminService.deleteUser(user.id);
      await loadUsers();
      if (selectedUser?.id === user.id) {
        setSelectedUser(null);
      }

      showToast({
        type: 'success',
        title: 'Đã xóa mềm tài khoản',
        message: `${user.name} đã được chuyển sang trạng thái ngừng hoạt động.`,
      });
    } catch (error) {
      showToast({
        type: 'error',
        title: 'Không thể xóa tài khoản',
        message: getErrorMessage(error),
      });
    }
  };

  const handleResetPassword = async (user: AdminUser) => {
    try {
      const payload = await adminService.resetUserPassword(user.id);
      await navigator.clipboard.writeText(payload.resetLink);
      showToast({
        type: 'success',
        title: 'Đã tạo link reset mật khẩu',
        message: payload.emailSent
          ? 'Link đã được gửi email và cũng được sao chép vào clipboard.'
          : 'Link reset đã được sao chép vào clipboard để bạn gửi thủ công.',
      });
    } catch (error) {
      showToast({
        type: 'error',
        title: 'Không thể reset mật khẩu',
        message: getErrorMessage(error),
      });
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
          <h1 className="text-[3.5rem] font-bold tracking-tight text-on-surface leading-none mb-2">Quản lý người dùng</h1>
          <p className="text-on-surface-variant font-medium">
            Quản trị tài khoản khách hàng, staff, partner và admin nội bộ. Ô tìm kiếm trên top bar đang lọc theo tên, email, điện thoại và mã người dùng.
          </p>
        </div>
        <div className="flex gap-4">
          <button onClick={exportUsers} className="px-8 py-3 bg-surface-container-high text-on-surface font-bold rounded-full hover:brightness-95 transition-all">Xuất CSV</button>
          <button onClick={() => setShowCreateForm((value) => !value)} className="px-8 py-3 bg-primary-container text-white font-bold rounded-full hover:brightness-110 transition-all shadow-lg shadow-primary-container/30">
            {showCreateForm ? 'Ẩn biểu mẫu' : 'Thêm thành viên'}
          </button>
        </div>
      </div>

      {showCreateForm ? (
        <form onSubmit={handleCreateUser} className="bg-white rounded-[2rem] p-8 shadow-[0px_20px_40px_rgba(21,28,39,0.03)] border border-surface-container-high/50">
          <div className="flex items-center justify-between gap-4 mb-6">
            <div>
              <h2 className="text-xl font-black text-on-surface">Tạo thành viên mới</h2>
              <p className="text-sm text-on-surface-variant mt-1">Admin có thể cấp quyền trực tiếp khi tạo tài khoản.</p>
            </div>
            <button type="button" onClick={() => { setShowCreateForm(false); setCreateForm(initialForm); }} className="px-5 py-2.5 rounded-full bg-surface-container-low text-on-surface font-bold">Hủy</button>
          </div>
          <div className="grid grid-cols-1 md:grid-cols-5 gap-4">
            <input value={createForm.name} onChange={(event) => setCreateForm((form) => ({ ...form, name: event.target.value }))} placeholder="Họ tên" className="px-5 py-3 rounded-2xl bg-surface-container-low outline-none" required />
            <input value={createForm.email} onChange={(event) => setCreateForm((form) => ({ ...form, email: event.target.value }))} placeholder="Email" type="email" className="px-5 py-3 rounded-2xl bg-surface-container-low outline-none" required />
            <input value={createForm.phone} onChange={(event) => setCreateForm((form) => ({ ...form, phone: event.target.value }))} placeholder="Số điện thoại" className="px-5 py-3 rounded-2xl bg-surface-container-low outline-none" />
            <select value={createForm.role} onChange={(event) => setCreateForm((form) => ({ ...form, role: event.target.value as AdminUser['role'] }))} className="px-5 py-3 rounded-2xl bg-surface-container-low outline-none">
              {roleOptions.map((role) => <option key={role.value} value={role.value}>{role.label}</option>)}
            </select>
            <label className="flex items-center justify-between px-5 py-3 rounded-2xl bg-surface-container-low">
              <span className="text-sm font-semibold text-on-surface">Kích hoạt ngay</span>
              <input checked={createForm.isActive} onChange={(event) => setCreateForm((form) => ({ ...form, isActive: event.target.checked }))} type="checkbox" className="w-4 h-4 accent-[#10B981]" />
            </label>
          </div>
          <div className="mt-6">
            <button type="submit" disabled={submitting} className="px-8 py-3 bg-primary-container text-white font-bold rounded-full disabled:opacity-50">
              {submitting ? 'Đang tạo...' : 'Tạo thành viên'}
            </button>
          </div>
        </form>
      ) : null}

      <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-6">
        <UserStatCard label="Tổng người dùng" value={stats.totalUsers.toLocaleString()} icon="groups" badge="Toàn hệ thống" iconClass="bg-surface-container text-on-surface" />
        <UserStatCard label="Đang hoạt động" value={stats.activeUsers.toLocaleString()} icon="person_check" badge="Khả dụng" iconClass="bg-primary-container/10 text-primary-container" />
        <UserStatCard label="Thành viên mới" value={stats.newUsers.toLocaleString()} icon="person_add" badge="Tháng này" iconClass="bg-tertiary-container/10 text-tertiary" />
        <UserStatCard label="Tài khoản bị khóa" value={stats.blockedUsers.toLocaleString()} icon="block" badge="Cần chú ý" iconClass="bg-secondary-container/10 text-secondary-container" />
      </div>

      <div className="flex flex-wrap gap-4 items-center justify-between bg-surface-container-low p-6 rounded-[2rem]">
        <div className="flex gap-4 items-center flex-wrap">
          <select value={statusFilter} onChange={(event) => setStatusFilter(event.target.value as 'all' | AdminUser['status'])} className="bg-white rounded-full px-5 py-3 text-sm font-bold outline-none">
            <option value="all">Tất cả trạng thái</option>
            <option value="active">Đang hoạt động</option>
            <option value="blocked">Đã khóa</option>
          </select>
          <select value={roleFilter} onChange={(event) => setRoleFilter(event.target.value as 'all' | AdminUser['role'])} className="bg-white rounded-full px-5 py-3 text-sm font-bold outline-none">
            <option value="all">Tất cả quyền</option>
            {roleOptions.map((role) => <option key={role.value} value={role.value}>{role.label}</option>)}
          </select>
          <select value={sortOrder} onChange={(event) => setSortOrder(event.target.value as 'newest' | 'oldest')} className="bg-white rounded-full px-5 py-3 text-sm font-bold outline-none">
            <option value="newest">Mới nhất</option>
            <option value="oldest">Cũ nhất</option>
          </select>
        </div>
        <div className="text-sm font-medium text-on-surface-variant">
          Hiển thị {filteredUsers.length} kết quả{query.trim() ? ` cho "${query}"` : ''}
        </div>
      </div>

      <div className="bg-surface-container-lowest rounded-[2rem] overflow-hidden shadow-sm">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead className="bg-surface-container-low">
              <tr>
                <th className="px-8 py-6 text-[10px] font-black uppercase tracking-widest text-on-surface-variant">Thành viên</th>
                <th className="px-8 py-6 text-[10px] font-black uppercase tracking-widest text-on-surface-variant">Liên hệ</th>
                <th className="px-8 py-6 text-[10px] font-black uppercase tracking-widest text-on-surface-variant">Quyền</th>
                <th className="px-8 py-6 text-[10px] font-black uppercase tracking-widest text-on-surface-variant">Lần đăng nhập</th>
                <th className="px-8 py-6 text-[10px] font-black uppercase tracking-widest text-on-surface-variant">Trạng thái</th>
                <th className="px-8 py-6 text-right text-[10px] font-black uppercase tracking-widest text-on-surface-variant">Hành động</th>
              </tr>
            </thead>
            <tbody>
              {paginatedUsers.map((user) => {
                const status = statusConfig[user.status];
                return (
                  <tr key={user.id} className="hover:bg-surface-container-low/50 transition-colors">
                    <td className="px-8 py-6">
                      <div className="flex items-center gap-4">
                        <div className={`w-12 h-12 rounded-full ${status.avatarClass} flex items-center justify-center`}>
                          <span className="material-symbols-outlined text-[20px]">person</span>
                        </div>
                        <div>
                          <p className="font-bold text-on-surface">{user.name}</p>
                          <p className="text-[10px] text-on-surface-variant">ID: {user.displayId}</p>
                        </div>
                      </div>
                    </td>
                    <td className="px-8 py-6">
                      <p className="text-sm font-medium text-on-surface">{user.email}</p>
                      <p className="text-xs text-on-surface-variant mt-1">{user.phone || 'Chưa cập nhật số điện thoại'}</p>
                    </td>
                    <td className="px-8 py-6">
                      <span className="inline-flex rounded-full bg-surface-container-low px-4 py-2 text-xs font-bold uppercase tracking-wider text-on-surface">{user.role}</span>
                      <p className="mt-2 text-xs text-on-surface-variant">Tham gia {user.joinDate}</p>
                    </td>
                    <td className="px-8 py-6 text-sm font-medium text-on-surface-variant">{user.lastLoginAt}</td>
                    <td className="px-8 py-6">
                      <span className={`inline-flex items-center px-4 py-1.5 ${status.bgClass} ${status.textClass} text-xs font-bold rounded-full`}>{status.label}</span>
                    </td>
                    <td className="px-8 py-6 text-right">
                      <div className="flex items-center justify-end gap-2">
                        <button onClick={() => handleToggleStatus(user)} className={`px-4 py-2 rounded-full text-xs font-bold transition-all ${user.status === 'active' ? 'bg-error-container text-error' : 'bg-primary-container/10 text-primary-container'}`}>
                          {user.status === 'active' ? 'Khóa' : 'Mở khóa'}
                        </button>
                        <button onClick={() => { setEditingUser(user); setEditForm({ name: user.name, email: user.email, phone: user.phone === 'No Phone' ? '' : user.phone, role: user.role, isActive: user.status === 'active' }); }} className="px-4 py-2 rounded-full bg-surface-container-low text-xs font-bold text-on-surface">Sửa</button>
                        <button onClick={() => setSelectedUser(user)} className="p-2 hover:bg-surface-container rounded-full transition-all">
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

      {selectedUser ? (
        <div className="bg-white rounded-[2rem] shadow-[0px_20px_40px_rgba(21,28,39,0.03)] border border-surface-container-high/50 p-8">
          <div className="flex flex-col md:flex-row justify-between gap-6">
            <div>
              <p className="text-[10px] uppercase tracking-[0.2em] font-bold text-primary mb-2">Chi tiết thành viên</p>
              <h2 className="text-2xl font-black text-on-surface">{selectedUser.name}</h2>
              <p className="text-on-surface-variant mt-2">{selectedUser.displayId} • {selectedUser.role}</p>
            </div>
            <div className="flex gap-3 flex-wrap">
              <button onClick={() => handleResetPassword(selectedUser)} className="px-5 py-2.5 rounded-full bg-surface-container-low text-on-surface font-bold">Reset mật khẩu</button>
              <button onClick={() => handleDeleteUser(selectedUser)} className="px-5 py-2.5 rounded-full bg-error-container text-error font-bold">Xóa mềm</button>
              <button onClick={() => setSelectedUser(null)} className="px-5 py-2.5 rounded-full bg-primary-container text-white font-bold">Đóng</button>
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
              <p className="text-[11px] font-bold uppercase tracking-wider text-on-surface-variant">Lần đăng nhập</p>
              <p className="text-sm font-bold text-on-surface mt-2">{selectedUser.lastLoginAt}</p>
            </div>
            <div className="bg-surface-container-low rounded-2xl p-5">
              <p className="text-[11px] font-bold uppercase tracking-wider text-on-surface-variant">Trạng thái</p>
              <p className="text-sm font-bold text-on-surface mt-2">{statusConfig[selectedUser.status].label}</p>
            </div>
          </div>
        </div>
      ) : null}

      {editingUser ? (
        <form onSubmit={handleSaveUser} className="bg-white rounded-[2rem] border border-surface-container-high/50 p-8 shadow-[0px_20px_40px_rgba(21,28,39,0.03)]">
          <div className="flex items-center justify-between gap-4 mb-6">
            <div>
              <h2 className="text-xl font-black text-on-surface">Chỉnh sửa người dùng</h2>
              <p className="text-sm text-on-surface-variant mt-1">Cập nhật thông tin và phân quyền cho {editingUser.name}.</p>
            </div>
            <button type="button" onClick={() => setEditingUser(null)} className="px-5 py-2.5 rounded-full bg-surface-container-low text-on-surface font-bold">Đóng</button>
          </div>
          <div className="grid grid-cols-1 md:grid-cols-5 gap-4">
            <input value={editForm.name} onChange={(event) => setEditForm((form) => ({ ...form, name: event.target.value }))} className="px-5 py-3 rounded-2xl bg-surface-container-low outline-none" required />
            <input value={editForm.email} onChange={(event) => setEditForm((form) => ({ ...form, email: event.target.value }))} type="email" className="px-5 py-3 rounded-2xl bg-surface-container-low outline-none" required />
            <input value={editForm.phone} onChange={(event) => setEditForm((form) => ({ ...form, phone: event.target.value }))} className="px-5 py-3 rounded-2xl bg-surface-container-low outline-none" />
            <select value={editForm.role} onChange={(event) => setEditForm((form) => ({ ...form, role: event.target.value as AdminUser['role'] }))} className="px-5 py-3 rounded-2xl bg-surface-container-low outline-none">
              {roleOptions.map((role) => <option key={role.value} value={role.value}>{role.label}</option>)}
            </select>
            <label className="flex items-center justify-between px-5 py-3 rounded-2xl bg-surface-container-low">
              <span className="text-sm font-semibold text-on-surface">Kích hoạt</span>
              <input checked={editForm.isActive} onChange={(event) => setEditForm((form) => ({ ...form, isActive: event.target.checked }))} type="checkbox" className="w-4 h-4 accent-[#10B981]" />
            </label>
          </div>
          <div className="mt-6">
            <button type="submit" disabled={submitting} className="px-8 py-3 bg-primary-container text-white font-bold rounded-full disabled:opacity-50">
              {submitting ? 'Đang lưu...' : 'Lưu thay đổi'}
            </button>
          </div>
        </form>
      ) : null}

      <div className="flex items-center justify-between pb-10">
        <button onClick={() => setCurrentPage((page) => Math.max(1, page - 1))} disabled={currentPageClamped === 1} className="flex items-center gap-2 px-6 py-3 bg-surface-container-low rounded-full font-bold text-on-surface disabled:opacity-40">
          <span className="material-symbols-outlined text-sm">arrow_back</span>
          Trước
        </button>
        <div className="flex items-center gap-2">
          {pageNumbers.map((page) => (
            <button key={page} onClick={() => setCurrentPage(page)} className={`w-10 h-10 flex items-center justify-center rounded-full font-medium transition-all ${currentPageClamped === page ? 'bg-primary-container text-white font-bold' : 'hover:bg-surface-container'}`}>
              {page}
            </button>
          ))}
        </div>
        <button onClick={() => setCurrentPage((page) => Math.min(totalPages, page + 1))} disabled={currentPageClamped === totalPages} className="flex items-center gap-2 px-6 py-3 bg-surface-container-low rounded-full font-bold text-on-surface disabled:opacity-40">
          Sau
          <span className="material-symbols-outlined text-sm">arrow_forward</span>
        </button>
      </div>
    </div>
  );
}
