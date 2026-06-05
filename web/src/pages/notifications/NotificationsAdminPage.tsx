import { useEffect, useMemo, useState } from 'react';
import { useAdminSearch, useToast } from '../../context';
import {
  adminService,
  type AdminNotificationStats,
  type AdminSendNotificationRequest,
  type AdminUser,
} from '../../services/adminService';
import { downloadCsv } from '../../utils/adminActions';
import { getErrorMessage } from '../../utils/http';

const initialForm: AdminSendNotificationRequest = {
  recipientMode: 'all',
  userIds: [],
  role: 'customer',
  channels: ['in_app'],
  title: '',
  message: '',
  type: 'system',
  referenceType: '',
  referenceId: null,
  actionUrl: '',
};

const roleOptions: Array<{ value: AdminUser['role']; label: string }> = [
  { value: 'customer', label: 'Customer' },
  { value: 'staff', label: 'Staff' },
  { value: 'partner', label: 'Partner' },
  { value: 'admin', label: 'Admin' },
];

const channelOptions: Array<{ value: AdminSendNotificationRequest['channels'][number]; label: string; icon: string }> = [
  { value: 'in_app', label: 'In-app', icon: 'notifications' },
  { value: 'email', label: 'Email', icon: 'mail' },
  { value: 'fcm', label: 'FCM (Push)', icon: 'send_to_mobile' },
];

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

function StatCard({ label, value, icon }: { label: string; value: string; icon: string }) {
  return (
    <div className="bg-white rounded-2xl p-6 shadow-sm border border-slate-100 flex flex-col gap-4">
      <div className="flex items-center justify-between">
        <span className="material-symbols-outlined rounded-xl bg-primary/10 p-2.5 text-primary text-xl">{icon}</span>
      </div>
      <div>
        <p className="text-xs font-semibold text-slate-500 uppercase tracking-wider">{label}</p>
        <h2 className="mt-1 text-3xl font-black text-on-surface">{value}</h2>
      </div>
    </div>
  );
}

export default function NotificationsAdminPage() {
  const { query } = useAdminSearch();
  const { showToast } = useToast();
  const [stats, setStats] = useState<AdminNotificationStats | null>(null);
  const [users, setUsers] = useState<AdminUser[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [form, setForm] = useState<AdminSendNotificationRequest>(initialForm);
  const [submitting, setSubmitting] = useState(false);
  const [showGuide, setShowGuide] = useState(false);

  const loadNotifications = async (search = query) => {
    const data = await adminService.getNotifications({ search: search.trim() || undefined });
    setStats(data);
  };

  useEffect(() => {
    const fetchData = async () => {
      try {
        const [notificationData, userData] = await Promise.all([
          adminService.getNotifications(),
          adminService.getUsers(),
        ]);
        setStats(notificationData);
        setUsers(userData.users.filter((user) => user.status === 'active'));
        setError(null);
      } catch (err) {
        const message = getErrorMessage(err);
        setError(message);
        showToast({ type: 'error', title: 'Không thể tải thông báo', message });
      } finally {
        setLoading(false);
      }
    };

    fetchData();
  }, []);

  useEffect(() => {
    const handle = window.setTimeout(async () => {
      try {
        await loadNotifications();
        setError(null);
      } catch (err) {
        const message = getErrorMessage(err);
        setError(message);
        showToast({ type: 'error', title: 'Không thể tìm thông báo', message });
      }
    }, 250);

    return () => window.clearTimeout(handle);
  }, [query]);

  const filteredNotifications = useMemo(() => stats?.notifications ?? [], [stats]);

  const validationErrors = useMemo(() => {
    const errors: string[] = [];
    if (form.title.trim().length === 0) errors.push('Tiêu đề không được để trống.');
    if (form.title.trim().length > 200) errors.push('Tiêu đề tối đa 200 ký tự.');
    if (form.message.trim().length === 0) errors.push('Nội dung không được để trống.');
    if (form.channels.length === 0) errors.push('Vui lòng chọn ít nhất một kênh gửi.');
    if (form.recipientMode === 'users' && form.userIds.length === 0) errors.push('Vui lòng chọn ít nhất một người nhận.');
    return errors;
  }, [form]);

  const recipientCount = useMemo(() => {
    if (form.recipientMode === 'users') return form.userIds.length;
    if (form.recipientMode === 'role') return users.filter((user) => user.role === form.role).length;
    return users.length;
  }, [form.recipientMode, form.role, form.userIds.length, users]);

  const toggleChannel = (channel: AdminSendNotificationRequest['channels'][number]) => {
    setForm((current) => {
      const channels = current.channels.includes(channel)
        ? current.channels.filter((item) => item !== channel)
        : [...current.channels, channel];
      return { ...current, channels };
    });
  };

  const toggleUser = (userId: number) => {
    setForm((current) => ({
      ...current,
      userIds: current.userIds.includes(userId)
        ? current.userIds.filter((id) => id !== userId)
        : [...current.userIds, userId],
    }));
  };

  const handleSubmit = async (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    if (validationErrors.length > 0) {
      showToast({ type: 'error', title: 'Dữ liệu thông báo chưa hợp lệ', message: validationErrors[0] });
      return;
    }

    setSubmitting(true);
    try {
      const result = await adminService.sendNotification({
        ...form,
        referenceType: form.referenceType?.trim() || undefined,
        actionUrl: form.actionUrl?.trim() || undefined,
        referenceId: form.referenceId || null,
      });

      await loadNotifications('');
      setForm(initialForm);
      showToast({
        type: result.failed > 0 ? 'info' : 'success',
        title: 'Đã xử lý gửi thông báo',
        message: `${result.targetedUsers} người nhận, ${result.inAppCreated} in-app, ${result.emailSent}/${result.emailAttempted} email, ${result.pushAttempted} FCM.`,
      });
    } catch (err) {
      showToast({ type: 'error', title: 'Không thể gửi thông báo', message: getErrorMessage(err) });
    } finally {
      setSubmitting(false);
    }
  };

  const exportNotifications = () => {
    downloadCsv('notifications.csv', filteredNotifications, [
      { key: 'title', header: 'Tiêu đề' },
      { key: 'message', header: 'Nội dung' },
      { key: 'type', header: 'Loại' },
      { key: 'userName', header: 'Người nhận' },
      { key: 'userEmail', header: 'Email' },
      { key: 'isRead', header: 'Đã đọc' },
      { key: 'createdAt', header: 'Ngày tạo' },
    ]);
    showToast({ type: 'success', title: 'Đã xuất danh sách thông báo' });
  };

  if (loading) {
    return <div className="flex min-h-[50vh] items-center justify-center"><div className="h-12 w-12 animate-spin rounded-full border-b-2 border-primary" /></div>;
  }

  if (error || !stats) {
    return (
      <div className="rounded-2xl bg-white p-10 text-center shadow-sm border border-slate-100">
        <span className="material-symbols-outlined text-5xl text-error">error</span>
        <h1 className="mt-4 text-2xl font-black text-on-surface">Không thể tải thông báo</h1>
        <p className="mt-2 text-sm text-slate-500">{error ?? 'Dữ liệu chưa sẵn sàng.'}</p>
        <button onClick={() => { setLoading(true); loadNotifications().finally(() => setLoading(false)); }} className="mt-6 rounded-full bg-primary px-6 py-2.5 text-sm font-bold text-white">Tải lại</button>
      </div>
    );
  }

  return (
    <div className="space-y-8">
      {/* Header */}
      <div className="flex flex-col xl:flex-row xl:items-start justify-between gap-4">
        <div>
          <p className="text-xs font-bold uppercase tracking-widest text-primary mb-1">Trung tâm thông báo</p>
          <h1 className="text-3xl font-black text-on-surface">Quản lý Thông báo</h1>
          <p className="text-sm text-slate-500 mt-1 max-w-xl">Tạo và theo dõi thông báo hệ thống gửi tới người dùng SmartTrip.</p>
        </div>
        <div className="flex flex-wrap items-center gap-2">
          <button onClick={() => setShowGuide(true)} className="rounded-full bg-amber-500 hover:bg-amber-600 px-5 py-2.5 text-sm font-bold text-white transition-all shadow-sm">
            💡 Hướng dẫn
          </button>
          <button onClick={exportNotifications} className="rounded-full bg-slate-100 text-slate-700 px-5 py-2.5 text-sm font-bold hover:bg-slate-200 transition">Xuất CSV</button>
        </div>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <StatCard label="Tổng thông báo" value={stats.totalNotifications.toLocaleString()} icon="notifications_active" />
        <StatCard label="Chưa đọc" value={stats.unreadNotifications.toLocaleString()} icon="mark_email_unread" />
        <StatCard label="Đã đọc" value={stats.readNotifications.toLocaleString()} icon="drafts" />
        <StatCard label="Người nhận khả dụng" value={stats.targetableUsers.toLocaleString()} icon="group" />
      </div>

      {/* Compose Form */}
      <form onSubmit={handleSubmit} className="bg-white rounded-2xl p-6 shadow-sm border border-slate-100">
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 mb-5">
          <div>
            <h2 className="text-lg font-black text-on-surface">Tạo thông báo mới</h2>
            {validationErrors.length > 0 ? (
              <p className="mt-0.5 text-sm font-semibold text-red-500">{validationErrors[0]}</p>
            ) : (
              <p className="mt-0.5 text-sm text-slate-400">Sẽ gửi tới <strong className="text-on-surface">{recipientCount.toLocaleString()}</strong> người nhận</p>
            )}
          </div>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
          <Field label="Tiêu đề thông báo" required className="lg:col-span-2">
            <input
              value={form.title}
              onChange={(e) => setForm((current) => ({ ...current, title: e.target.value }))}
              placeholder="Nhập tiêu đề thông báo"
              className={inputCls}
              required
            />
          </Field>
          <Field label="Loại thông báo" required>
            <input
              value={form.type}
              onChange={(e) => setForm((current) => ({ ...current, type: e.target.value }))}
              placeholder="system, promo, update..."
              className={inputCls}
              required
            />
          </Field>
          <Field label="Chế độ người nhận" required>
            <select
              value={form.recipientMode}
              onChange={(e) => setForm((current) => ({ ...current, recipientMode: e.target.value as AdminSendNotificationRequest['recipientMode'] }))}
              className={selectCls}
            >
              <option value="all">Tất cả người dùng</option>
              <option value="active">Người dùng đang hoạt động</option>
              <option value="role">Theo nhóm quyền</option>
              <option value="users">Chọn từng người</option>
            </select>
          </Field>
          {form.recipientMode === 'role' ? (
            <Field label="Nhóm quyền người nhận" required>
              <select
                value={form.role}
                onChange={(e) => setForm((current) => ({ ...current, role: e.target.value as AdminUser['role'] }))}
                className={selectCls}
              >
                {roleOptions.map((role) => <option key={role.value} value={role.value}>{role.label}</option>)}
              </select>
            </Field>
          ) : null}
          <Field label="Loại tham chiếu (tùy chọn)">
            <input
              value={form.referenceType ?? ''}
              onChange={(e) => setForm((current) => ({ ...current, referenceType: e.target.value }))}
              placeholder="Booking, Hotel, Trip..."
              className={inputCls}
            />
          </Field>
          <Field label="ID tham chiếu (tùy chọn)">
            <input
              value={form.referenceId ?? ''}
              onChange={(e) => setForm((current) => ({ ...current, referenceId: e.target.value === '' ? null : Number(e.target.value) }))}
              type="number"
              min={1}
              placeholder="Nhập ID số"
              className={inputCls}
            />
          </Field>
          <Field label="Action URL (tùy chọn)" className="sm:col-span-2 lg:col-span-3">
            <input
              value={form.actionUrl ?? ''}
              onChange={(e) => setForm((current) => ({ ...current, actionUrl: e.target.value }))}
              placeholder="Ví dụ: /hotels/1"
              className={inputCls}
            />
          </Field>
        </div>

        <div className="mt-4">
          <Field label="Nội dung thông báo" required>
            <textarea
              value={form.message}
              onChange={(e) => setForm((current) => ({ ...current, message: e.target.value }))}
              placeholder="Nhập nội dung thông báo..."
              rows={3}
              className={`${inputCls} resize-none`}
              required
            />
          </Field>
        </div>

        {/* Channels */}
        <div className="mt-4">
          <p className="text-xs font-semibold text-slate-500 uppercase tracking-wider mb-2">Kênh gửi thông báo *</p>
          <div className="flex flex-wrap gap-2">
            {channelOptions.map((channel) => {
              const active = form.channels.includes(channel.value);
              return (
                <button
                  key={channel.value}
                  type="button"
                  onClick={() => toggleChannel(channel.value)}
                  className={`flex items-center gap-2 rounded-full px-4 py-2 text-sm font-semibold transition-all border ${active ? 'bg-primary text-white border-primary shadow-sm shadow-primary/20' : 'bg-white text-slate-600 border-slate-200 hover:border-primary/30'}`}
                >
                  <span className="material-symbols-outlined text-base">{channel.icon}</span>
                  {channel.label}
                </button>
              );
            })}
          </div>
        </div>

        {/* User picker */}
        {form.recipientMode === 'users' ? (
          <div className="mt-4">
            <p className="text-xs font-semibold text-slate-500 uppercase tracking-wider mb-2">Chọn người nhận *</p>
            <div className="max-h-64 overflow-y-auto rounded-xl bg-slate-50 border border-slate-200 p-3">
              <div className="grid grid-cols-1 gap-2 md:grid-cols-2 xl:grid-cols-3">
                {users.map((user) => (
                  <label key={user.id} className="flex items-center gap-3 rounded-xl bg-white px-4 py-3 border border-slate-100 cursor-pointer hover:border-primary/30 transition">
                    <input
                      checked={form.userIds.includes(user.id)}
                      onChange={() => toggleUser(user.id)}
                      type="checkbox"
                      className="h-4 w-4 accent-emerald-500 shrink-0"
                    />
                    <span className="min-w-0">
                      <span className="block truncate text-sm font-semibold text-on-surface">{user.name}</span>
                      <span className="block truncate text-xs text-slate-400">{user.email}</span>
                    </span>
                  </label>
                ))}
                {users.length === 0 ? <p className="text-sm text-slate-400 col-span-full">Chưa có người dùng khả dụng.</p> : null}
              </div>
            </div>
          </div>
        ) : null}

        <div className="mt-5">
          <button
            type="submit"
            disabled={submitting || validationErrors.length > 0}
            className="px-6 py-2.5 bg-primary text-white text-sm font-bold rounded-full disabled:opacity-50 hover:brightness-110 transition"
          >
            {submitting ? 'Đang gửi...' : 'Gửi thông báo'}
          </button>
        </div>
      </form>

      {/* Notification List */}
      <div className="bg-white rounded-2xl border border-slate-100 overflow-hidden shadow-sm">
        {filteredNotifications.length === 0 ? (
          <div className="p-12 text-center">
            <span className="material-symbols-outlined text-4xl text-slate-300">notifications_off</span>
            <p className="mt-3 text-slate-500 font-medium">Chưa có thông báo</p>
            <p className="mt-1 text-sm text-slate-400">{query.trim() ? 'Không có kết quả phù hợp.' : 'Danh sách hiện đang trống.'}</p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full border-collapse text-left">
              <thead className="bg-slate-50 border-b border-slate-100">
                <tr>
                  <th className="px-6 py-4 text-xs font-bold uppercase tracking-wider text-slate-500">Thông báo</th>
                  <th className="px-6 py-4 text-xs font-bold uppercase tracking-wider text-slate-500">Người nhận</th>
                  <th className="px-6 py-4 text-xs font-bold uppercase tracking-wider text-slate-500">Loại</th>
                  <th className="px-6 py-4 text-xs font-bold uppercase tracking-wider text-slate-500">Trạng thái</th>
                  <th className="px-6 py-4 text-xs font-bold uppercase tracking-wider text-slate-500">Ngày tạo</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-50">
                {filteredNotifications.map((notification) => (
                  <tr key={notification.id} className="hover:bg-slate-50/70 transition-colors">
                    <td className="px-6 py-4">
                      <p className="font-semibold text-on-surface text-sm">{notification.title}</p>
                      <p className="mt-0.5 max-w-sm text-xs text-slate-400 line-clamp-2">{notification.message}</p>
                    </td>
                    <td className="px-6 py-4 min-w-0">
                      <p className="text-sm font-semibold text-on-surface truncate max-w-[160px]">{notification.userName}</p>
                      <p className="mt-0.5 text-xs text-slate-400 truncate max-w-[160px]">{notification.userEmail || '—'}</p>
                    </td>
                    <td className="px-6 py-4">
                      <span className="rounded-full bg-slate-100 px-3 py-1 text-xs font-semibold text-slate-600">{notification.type}</span>
                    </td>
                    <td className="px-6 py-4">
                      <span className={`rounded-full px-3 py-1 text-xs font-semibold ${notification.isRead ? 'bg-emerald-50 text-emerald-700' : 'bg-orange-50 text-orange-600'}`}>
                        {notification.isRead ? 'Đã đọc' : 'Chưa đọc'}
                      </span>
                    </td>
                    <td className="px-6 py-4 text-xs text-slate-400">{notification.createdAt}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* Guide Modal */}
      {showGuide && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-sm p-4">
          <div className="w-full max-w-2xl rounded-3xl bg-white p-8 shadow-2xl ring-1 ring-black/5">
            <div className="flex items-start justify-between border-b border-slate-100 pb-4">
              <div>
                <p className="text-xs font-black uppercase tracking-widest text-amber-600">Hướng dẫn sử dụng</p>
                <h3 className="mt-1 text-xl font-black text-slate-900">Vận hành Gửi thông báo</h3>
              </div>
              <button type="button" onClick={() => setShowGuide(false)} className="rounded-full bg-slate-100 hover:bg-slate-200 px-4 py-2 text-xs font-bold text-slate-900 transition-colors">Đóng</button>
            </div>
            <div className="mt-6 space-y-5 text-sm text-slate-600 leading-relaxed max-h-[55vh] overflow-y-auto pr-1">
              <div className="rounded-2xl bg-amber-50 p-5 border border-amber-100">
                <h4 className="font-bold text-amber-800 text-base">📲 Đa kênh truyền tải (Channels)</h4>
                <ul className="mt-3 list-disc list-inside space-y-2 text-amber-900 font-medium">
                  <li><strong>In-app:</strong> Hiển thị trong danh sách thông báo trên ứng dụng và giao diện web của người dùng.</li>
                  <li><strong>Email:</strong> Kích hoạt email thông báo gửi tự động đến hộp thư đăng ký của người nhận.</li>
                  <li><strong>FCM:</strong> Gửi Push Notification trực tiếp đến điện thoại người dùng qua dịch vụ Firebase Cloud Messaging.</li>
                </ul>
              </div>
              <div>
                <h4 className="font-black text-slate-900 text-base">🔗 Điều hướng hành động (Deep Link)</h4>
                <ul className="mt-2 list-disc list-inside space-y-2">
                  <li><strong>Loại tham chiếu &amp; ID:</strong> Điền tên Model (ví dụ: <code>Booking</code>, <code>Hotel</code>) và ID số tương ứng để app liên kết dữ liệu.</li>
                  <li><strong>Action URL:</strong> Nhập đường dẫn nội bộ (ví dụ: <code>/hotels/15</code>) để khi người dùng click vào thông báo sẽ tự động chuyển hướng màn hình đến đúng dịch vụ.</li>
                </ul>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
