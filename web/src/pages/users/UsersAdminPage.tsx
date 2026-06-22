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
    bgClass: 'bg-emerald-50',
    textClass: 'text-emerald-700',
    avatarClass: 'bg-emerald-100 text-emerald-700',
    dotClass: 'bg-emerald-500',
  },
  blocked: {
    label: 'Đã khóa',
    bgClass: 'bg-red-50',
    textClass: 'text-red-600',
    avatarClass: 'bg-red-100 text-red-600',
    dotClass: 'bg-red-500',
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

/** Reusable styled form field */
function Field({
  label,
  required,
  children,
  className = '',
}: {
  label: string;
  required?: boolean;
  children: React.ReactNode;
  className?: string;
}) {
  return (
    <div className={`flex flex-col gap-1.5 min-w-0 ${className}`}>
      <span className="text-xs font-semibold text-slate-500 uppercase tracking-wider select-none">
        {label}
        {required && <span className="text-red-400 ml-0.5">*</span>}
      </span>
      {children}
    </div>
  );
}

const inputCls =
  'w-full rounded-xl border border-slate-200 bg-white px-4 py-2.5 text-sm font-medium text-on-surface outline-none transition focus:border-primary focus:ring-2 focus:ring-primary/20 placeholder:text-slate-400 min-w-0';
const selectCls =
  'w-full rounded-xl border border-slate-200 bg-white px-4 py-2.5 text-sm font-medium text-on-surface outline-none transition focus:border-primary focus:ring-2 focus:ring-primary/20 cursor-pointer min-w-0';

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
    <div className="bg-white p-6 rounded-2xl shadow-sm border border-slate-100 flex flex-col gap-4">
      <div className="flex items-center justify-between">
        <span
          className={`material-symbols-outlined p-2.5 rounded-xl text-xl ${iconClass}`}
          style={{ fontVariationSettings: "'FILL' 1" }}
        >
          {icon}
        </span>
        <span className="text-[10px] font-bold uppercase tracking-widest text-slate-400 bg-slate-50 px-2.5 py-1 rounded-full">
          {badge}
        </span>
      </div>
      <div>
        <p className="text-xs font-semibold text-slate-500 uppercase tracking-wider">{label}</p>
        <h3 className="text-3xl font-black text-on-surface mt-1">{value}</h3>
      </div>
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
  const [showGuide, setShowGuide] = useState(false);

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
    <div className="space-y-8">
      {/* Header */}
      <div className="flex justify-between items-start gap-4 flex-wrap">
        <div>
          <p className="text-xs font-bold uppercase tracking-widest text-primary mb-1">Quản trị hệ thống</p>
          <h1 className="text-3xl font-black text-on-surface">Quản lý người dùng</h1>
          <p className="text-sm text-slate-500 mt-1 max-w-xl">
            Quản trị tài khoản khách hàng, staff, partner và admin nội bộ.
          </p>
        </div>
        <div className="flex flex-wrap items-center gap-2">
          <button
            onClick={() => setShowGuide(true)}
            className="rounded-full bg-amber-500 hover:bg-amber-600 px-5 py-2.5 text-sm font-bold text-white transition-all shadow-sm"
          >
            💡 Hướng dẫn
          </button>
          <button onClick={exportUsers} className="px-5 py-2.5 bg-slate-100 text-slate-700 text-sm font-bold rounded-full hover:bg-slate-200 transition-all">
            Xuất CSV
          </button>
          <button
            onClick={() => setShowCreateForm((value) => !value)}
            className="px-5 py-2.5 bg-primary text-white text-sm font-bold rounded-full hover:brightness-110 transition-all shadow-lg shadow-primary/25"
          >
            {showCreateForm ? 'Ẩn biểu mẫu' : '+ Thêm thành viên'}
          </button>
        </div>
      </div>

      {/* Create Form */}
      {showCreateForm ? (
        <form onSubmit={handleCreateUser} className="bg-white rounded-2xl p-6 shadow-sm border border-slate-100">
          <div className="flex items-center justify-between gap-4 mb-5">
            <div>
              <h2 className="text-lg font-black text-on-surface">Tạo thành viên mới</h2>
              <p className="text-sm text-slate-500 mt-0.5">Cấp quyền trực tiếp khi tạo tài khoản.</p>
            </div>
            <button
              type="button"
              onClick={() => { setShowCreateForm(false); setCreateForm(initialForm); }}
              className="px-4 py-2 rounded-full bg-slate-100 text-slate-600 text-sm font-semibold hover:bg-slate-200 transition"
            >
              Hủy
            </button>
          </div>
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
            <Field label="Họ và tên" required>
              <input
                value={createForm.name}
                onChange={(e) => setCreateForm((f) => ({ ...f, name: e.target.value }))}
                placeholder="Nhập họ tên"
                className={inputCls}
                required
              />
            </Field>
            <Field label="Địa chỉ Email" required>
              <input
                value={createForm.email}
                onChange={(e) => setCreateForm((f) => ({ ...f, email: e.target.value }))}
                placeholder="email@vi-du.com"
                type="email"
                className={inputCls}
                required
              />
            </Field>
            <Field label="Số điện thoại">
              <input
                value={createForm.phone}
                onChange={(e) => setCreateForm((f) => ({ ...f, phone: e.target.value }))}
                placeholder="Nhập số điện thoại"
                className={inputCls}
              />
            </Field>
            <Field label="Phân quyền vai trò" required>
              <select
                value={createForm.role}
                onChange={(e) => setCreateForm((f) => ({ ...f, role: e.target.value as AdminUser['role'] }))}
                className={selectCls}
              >
                {roleOptions.map((role) => <option key={role.value} value={role.value}>{role.label}</option>)}
              </select>
            </Field>
            <Field label="Trạng thái">
              <label className="flex items-center gap-3 rounded-xl border border-slate-200 bg-white px-4 py-2.5 cursor-pointer hover:bg-slate-50 transition">
                <input
                  checked={createForm.isActive}
                  onChange={(e) => setCreateForm((f) => ({ ...f, isActive: e.target.checked }))}
                  type="checkbox"
                  className="w-4 h-4 accent-emerald-500"
                />
                <span className="text-sm font-medium text-on-surface">Kích hoạt ngay</span>
              </label>
            </Field>
          </div>
          <div className="mt-5 flex gap-3">
            <button type="submit" disabled={submitting} className="px-6 py-2.5 bg-primary text-white text-sm font-bold rounded-full disabled:opacity-50 hover:brightness-110 transition">
              {submitting ? 'Đang tạo...' : 'Tạo thành viên'}
            </button>
          </div>
        </form>
      ) : null}

      {/* Stats */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <UserStatCard label="Tổng người dùng" value={stats.totalUsers.toLocaleString()} icon="groups" badge="Toàn hệ thống" iconClass="bg-slate-100 text-slate-600" />
        <UserStatCard label="Đang hoạt động" value={stats.activeUsers.toLocaleString()} icon="person_check" badge="Khả dụng" iconClass="bg-emerald-100 text-emerald-700" />
        <UserStatCard label="Thành viên mới" value={stats.newUsers.toLocaleString()} icon="person_add" badge="Tháng này" iconClass="bg-blue-100 text-blue-700" />
        <UserStatCard label="Tài khoản bị khóa" value={stats.blockedUsers.toLocaleString()} icon="block" badge="Cần chú ý" iconClass="bg-red-100 text-red-600" />
      </div>

      {/* Filters */}
      <div className="flex flex-wrap gap-3 items-center justify-between bg-slate-50 p-4 rounded-2xl border border-slate-100">
        <div className="flex gap-3 items-center flex-wrap">
          <select
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value as 'all' | AdminUser['status'])}
            className="bg-white rounded-full px-4 py-2 text-sm font-semibold outline-none border border-slate-200 focus:border-primary transition"
          >
            <option value="all">Tất cả trạng thái</option>
            <option value="active">Đang hoạt động</option>
            <option value="blocked">Đã khóa</option>
          </select>
          <select
            value={roleFilter}
            onChange={(e) => setRoleFilter(e.target.value as 'all' | AdminUser['role'])}
            className="bg-white rounded-full px-4 py-2 text-sm font-semibold outline-none border border-slate-200 focus:border-primary transition"
          >
            <option value="all">Tất cả quyền</option>
            {roleOptions.map((role) => <option key={role.value} value={role.value}>{role.label}</option>)}
          </select>
          <select
            value={sortOrder}
            onChange={(e) => setSortOrder(e.target.value as 'newest' | 'oldest')}
            className="bg-white rounded-full px-4 py-2 text-sm font-semibold outline-none border border-slate-200 focus:border-primary transition"
          >
            <option value="newest">Mới nhất</option>
            <option value="oldest">Cũ nhất</option>
          </select>
        </div>
        <div className="text-sm font-medium text-slate-500">
          {filteredUsers.length} kết quả{query.trim() ? ` · "${query}"` : ''}
        </div>
      </div>

      {/* Table */}
      <div className="bg-white rounded-2xl border border-slate-100 overflow-hidden shadow-sm">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead className="bg-slate-50 border-b border-slate-100">
              <tr>
                <th className="px-6 py-4 text-xs font-bold uppercase tracking-wider text-slate-500">Thành viên</th>
                <th className="px-6 py-4 text-xs font-bold uppercase tracking-wider text-slate-500">Liên hệ</th>
                <th className="px-6 py-4 text-xs font-bold uppercase tracking-wider text-slate-500">Quyền</th>
                <th className="px-6 py-4 text-xs font-bold uppercase tracking-wider text-slate-500">Đăng nhập gần nhất</th>
                <th className="px-6 py-4 text-xs font-bold uppercase tracking-wider text-slate-500">Trạng thái</th>
                <th className="px-6 py-4 text-right text-xs font-bold uppercase tracking-wider text-slate-500">Hành động</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-50">
              {paginatedUsers.map((user) => {
                const status = statusConfig[user.status];
                return (
                  <tr key={user.id} className="hover:bg-slate-50/70 transition-colors">
                    <td className="px-6 py-4">
                      <div className="flex items-center gap-3">
                        <div className={`w-9 h-9 rounded-full ${status.avatarClass} flex items-center justify-center shrink-0`}>
                          <span className="material-symbols-outlined text-[16px]">person</span>
                        </div>
                        <div className="min-w-0">
                          <p className="font-semibold text-on-surface text-sm truncate">{user.name}</p>
                          <p className="text-[11px] text-slate-400 truncate">ID: {user.displayId}</p>
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-4 min-w-0">
                      <p className="text-sm text-on-surface truncate max-w-[200px]">{user.email}</p>
                      <p className="text-xs text-slate-400 mt-0.5">{user.phone || 'Chưa có SĐT'}</p>
                    </td>
                    <td className="px-6 py-4">
                      <span className="inline-flex rounded-full bg-slate-100 px-3 py-1 text-xs font-bold uppercase text-slate-600">{user.role}</span>
                      <p className="mt-1.5 text-xs text-slate-400">Tham gia {user.joinDate}</p>
                    </td>
                    <td className="px-6 py-4 text-sm text-slate-500">{user.lastLoginAt}</td>
                    <td className="px-6 py-4">
                      <span className={`inline-flex items-center gap-1.5 px-3 py-1 ${status.bgClass} ${status.textClass} text-xs font-semibold rounded-full`}>
                        <span className={`w-1.5 h-1.5 rounded-full ${status.dotClass}`} />
                        {status.label}
                      </span>
                    </td>
                    <td className="px-6 py-4 text-right">
                      <div className="flex items-center justify-end gap-2">
                        <button
                          onClick={() => handleToggleStatus(user)}
                          className={`px-3 py-1.5 rounded-full text-xs font-semibold transition-all ${user.status === 'active' ? 'bg-red-50 text-red-600 hover:bg-red-100' : 'bg-emerald-50 text-emerald-700 hover:bg-emerald-100'}`}
                        >
                          {user.status === 'active' ? 'Khóa' : 'Mở khóa'}
                        </button>
                        <button
                          onClick={() => {
                            setEditingUser(user);
                            setEditForm({ name: user.name, email: user.email, phone: user.phone === 'No Phone' ? '' : user.phone, role: user.role, isActive: user.status === 'active' });
                          }}
                          className="px-3 py-1.5 rounded-full bg-slate-100 text-xs font-semibold text-slate-700 hover:bg-slate-200 transition"
                        >
                          Sửa
                        </button>
                        <button
                          onClick={() => setSelectedUser(user)}
                          className="p-1.5 hover:bg-slate-100 rounded-full transition-all"
                        >
                          <span className="material-symbols-outlined text-base text-slate-500">more_vert</span>
                        </button>
                      </div>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
        {paginatedUsers.length === 0 && (
          <div className="py-12 text-center">
            <span className="material-symbols-outlined text-4xl text-slate-300">group_off</span>
            <p className="mt-3 text-slate-500 font-medium">Không có kết quả phù hợp</p>
          </div>
        )}
      </div>

      {/* User Detail Panel */}
      {selectedUser ? (
        <div className="bg-white rounded-2xl border border-slate-100 shadow-sm p-6">
          <div className="flex flex-col sm:flex-row justify-between gap-4 mb-6">
            <div>
              <p className="text-[10px] uppercase tracking-widest font-bold text-primary mb-1">Chi tiết thành viên</p>
              <h2 className="text-xl font-black text-on-surface">{selectedUser.name}</h2>
              <p className="text-slate-500 text-sm mt-0.5">{selectedUser.displayId} · {selectedUser.role}</p>
            </div>
            <div className="flex gap-2 flex-wrap">
              <button onClick={() => handleResetPassword(selectedUser)} className="px-4 py-2 rounded-full bg-slate-100 text-slate-700 text-sm font-semibold hover:bg-slate-200 transition">Reset mật khẩu</button>
              <button onClick={() => handleDeleteUser(selectedUser)} className="px-4 py-2 rounded-full bg-red-50 text-red-600 text-sm font-semibold hover:bg-red-100 transition">Xóa mềm</button>
              <button onClick={() => setSelectedUser(null)} className="px-4 py-2 rounded-full bg-primary text-white text-sm font-semibold hover:brightness-110 transition">Đóng</button>
            </div>
          </div>
          <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
            {[
              { label: 'Email', value: selectedUser.email },
              { label: 'Điện thoại', value: selectedUser.phone },
              { label: 'Lần đăng nhập', value: selectedUser.lastLoginAt },
              { label: 'Trạng thái', value: statusConfig[selectedUser.status].label },
            ].map((item) => (
              <div key={item.label} className="bg-slate-50 rounded-xl p-4 min-w-0">
                <p className="text-xs font-semibold text-slate-400 uppercase tracking-wider">{item.label}</p>
                <p className="text-sm font-semibold text-on-surface mt-1 truncate">{item.value}</p>
              </div>
            ))}
          </div>
        </div>
      ) : null}

      {/* Edit Form */}
      {editingUser ? (
        <form onSubmit={handleSaveUser} className="bg-white rounded-2xl border border-slate-100 shadow-sm p-6">
          <div className="flex items-center justify-between gap-4 mb-5">
            <div>
              <h2 className="text-lg font-black text-on-surface">Chỉnh sửa người dùng</h2>
              <p className="text-sm text-slate-500 mt-0.5">Cập nhật thông tin cho {editingUser.name}.</p>
            </div>
            <button type="button" onClick={() => setEditingUser(null)} className="px-4 py-2 rounded-full bg-slate-100 text-slate-600 text-sm font-semibold hover:bg-slate-200 transition">Đóng</button>
          </div>
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
            <Field label="Họ và tên" required>
              <input value={editForm.name} onChange={(e) => setEditForm((f) => ({ ...f, name: e.target.value }))} className={inputCls} required />
            </Field>
            <Field label="Địa chỉ Email" required>
              <input value={editForm.email} onChange={(e) => setEditForm((f) => ({ ...f, email: e.target.value }))} type="email" className={inputCls} required />
            </Field>
            <Field label="Số điện thoại">
              <input value={editForm.phone} onChange={(e) => setEditForm((f) => ({ ...f, phone: e.target.value }))} className={inputCls} />
            </Field>
            <Field label="Phân quyền vai trò" required>
              <select value={editForm.role} onChange={(e) => setEditForm((f) => ({ ...f, role: e.target.value as AdminUser['role'] }))} className={selectCls}>
                {roleOptions.map((role) => <option key={role.value} value={role.value}>{role.label}</option>)}
              </select>
            </Field>
            <Field label="Trạng thái">
              <label className="flex items-center gap-3 rounded-xl border border-slate-200 bg-white px-4 py-2.5 cursor-pointer hover:bg-slate-50 transition">
                <input checked={editForm.isActive} onChange={(e) => setEditForm((f) => ({ ...f, isActive: e.target.checked }))} type="checkbox" className="w-4 h-4 accent-emerald-500" />
                <span className="text-sm font-medium text-on-surface">Kích hoạt</span>
              </label>
            </Field>
          </div>
          <div className="mt-5">
            <button type="submit" disabled={submitting} className="px-6 py-2.5 bg-primary text-white text-sm font-bold rounded-full disabled:opacity-50 hover:brightness-110 transition">
              {submitting ? 'Đang lưu...' : 'Lưu thay đổi'}
            </button>
          </div>
        </form>
      ) : null}

      {/* Pagination */}
      <div className="flex items-center justify-between pb-6">
        <button
          onClick={() => setCurrentPage((page) => Math.max(1, page - 1))}
          disabled={currentPageClamped === 1}
          className="flex items-center gap-2 px-5 py-2.5 bg-slate-100 rounded-full text-sm font-semibold text-slate-700 disabled:opacity-40 hover:bg-slate-200 transition"
        >
          <span className="material-symbols-outlined text-sm">arrow_back</span>
          Trước
        </button>
        <div className="flex items-center gap-1.5">
          {pageNumbers.map((page) => (
            <button
              key={page}
              onClick={() => setCurrentPage(page)}
              className={`w-9 h-9 flex items-center justify-center rounded-full text-sm font-semibold transition-all ${currentPageClamped === page ? 'bg-primary text-white shadow-sm' : 'hover:bg-slate-100 text-slate-600'}`}
            >
              {page}
            </button>
          ))}
        </div>
        <button
          onClick={() => setCurrentPage((page) => Math.min(totalPages, page + 1))}
          disabled={currentPageClamped === totalPages}
          className="flex items-center gap-2 px-5 py-2.5 bg-slate-100 rounded-full text-sm font-semibold text-slate-700 disabled:opacity-40 hover:bg-slate-200 transition"
        >
          Sau
          <span className="material-symbols-outlined text-sm">arrow_forward</span>
        </button>
      </div>

      {/* Guide Modal */}
      {showGuide && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-sm p-4">
          <div className="w-full max-w-2xl rounded-3xl bg-white p-8 shadow-2xl ring-1 ring-black/5">
            <div className="flex items-start justify-between border-b border-slate-100 pb-4">
              <div>
                <p className="text-xs font-black uppercase tracking-widest text-amber-600">Hướng dẫn sử dụng</p>
                <h3 className="mt-1 text-xl font-black text-slate-900">Vận hành Quản lý người dùng</h3>
              </div>
              <button type="button" onClick={() => setShowGuide(false)} className="rounded-full bg-slate-100 hover:bg-slate-200 px-4 py-2 text-xs font-bold text-slate-900 transition-colors">
                Đóng
              </button>
            </div>
            <div className="mt-6 space-y-5 text-sm text-slate-600 leading-relaxed max-h-[55vh] overflow-y-auto pr-1">
              <div className="rounded-2xl bg-amber-50 p-5 border border-amber-100">
                <h4 className="font-bold text-amber-800 text-base">👥 Phân quyền vai trò (Roles)</h4>
                <ul className="mt-3 list-disc list-inside space-y-2 text-amber-900 font-medium">
                  <li><strong>Customer:</strong> Khách hàng sử dụng app di động để tìm kiếm và đặt dịch vụ.</li>
                  <li><strong>Partner:</strong> Đối tác cung cấp khách sạn/xe, có quyền quản trị dịch vụ được phân công.</li>
                  <li><strong>Staff:</strong> Nhân viên vận hành, phê duyệt booking, cập nhật bài viết, trả lời khách hàng.</li>
                  <li><strong>Admin:</strong> Quản trị viên hệ thống toàn quyền truy cập toàn bộ chức năng.</li>
                </ul>
              </div>
              <div>
                <h4 className="font-black text-slate-900 text-base">🛡️ Nghiệp vụ Quản trị thành viên</h4>
                <ul className="mt-2 list-disc list-inside space-y-2">
                  <li><strong>Khóa tài khoản:</strong> Ngay lập tức chặn quyền đăng nhập và thực hiện thao tác của thành viên trên cả Web và Mobile.</li>
                  <li><strong>Reset mật khẩu:</strong> Tạo liên kết đặt lại mật khẩu ngẫu nhiên để cung cấp cho người dùng hoặc tự động gửi email nếu hệ thống đã cấu hình.</li>
                  <li><strong>Xóa mềm:</strong> Ẩn tài khoản khỏi danh sách hoạt động mà không làm mất lịch sử các giao dịch/booking cũ liên quan.</li>
                </ul>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
