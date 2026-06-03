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
  { value: 'fcm', label: 'FCM', icon: 'send_to_mobile' },
];

function StatCard({ label, value, icon }: { label: string; value: string; icon: string }) {
  return (
    <div className="rounded-[2rem] bg-white p-8 shadow-[0px_20px_40px_rgba(21,28,39,0.04)]">
      <div className="flex items-center justify-between">
        <p className="text-[11px] font-black uppercase tracking-wider text-on-surface-variant">{label}</p>
        <span className="material-symbols-outlined rounded-2xl bg-primary-container/10 p-3 text-primary-container">{icon}</span>
      </div>
      <h2 className="mt-4 text-4xl font-black text-on-surface">{value}</h2>
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
      <div className="rounded-[2rem] bg-white p-10 text-center shadow-[0px_20px_40px_rgba(21,28,39,0.04)]">
        <span className="material-symbols-outlined text-5xl text-error">error</span>
        <h1 className="mt-4 text-2xl font-black text-on-surface">Không thể tải thông báo</h1>
        <p className="mt-2 text-sm text-on-surface-variant">{error ?? 'Dữ liệu chưa sẵn sàng.'}</p>
        <button onClick={() => { setLoading(true); loadNotifications().finally(() => setLoading(false)); }} className="mt-6 rounded-full bg-primary-container px-6 py-3 text-sm font-bold text-white">Tải lại</button>
      </div>
    );
  }

  return (
    <div className="space-y-10">
      <div className="flex flex-col gap-6 xl:flex-row xl:items-end xl:justify-between">
        <div>
          <p className="text-[10px] font-black uppercase tracking-[0.2em] text-primary">Trung tâm thông báo</p>
          <h1 className="mt-3 text-4xl font-black text-on-surface">Quản lý Notification</h1>
          <p className="mt-3 max-w-3xl text-sm text-on-surface-variant">Tạo và theo dõi thông báo hệ thống gửi tới người dùng SmartTrip.</p>
        </div>
        <button onClick={exportNotifications} className="rounded-full bg-primary-container px-6 py-3 text-sm font-bold text-white">Xuất CSV</button>
      </div>

      <div className="grid grid-cols-1 gap-6 md:grid-cols-4">
        <StatCard label="Thông báo" value={stats.totalNotifications.toLocaleString()} icon="notifications_active" />
        <StatCard label="Chưa đọc" value={stats.unreadNotifications.toLocaleString()} icon="mark_email_unread" />
        <StatCard label="Đã đọc" value={stats.readNotifications.toLocaleString()} icon="drafts" />
        <StatCard label="Người nhận" value={stats.targetableUsers.toLocaleString()} icon="group" />
      </div>

      <form onSubmit={handleSubmit} className="rounded-[2rem] bg-white p-8 shadow-[0px_20px_40px_rgba(21,28,39,0.04)] ring-1 ring-outline-variant/10">
        <div className="mb-6 flex flex-col gap-4 lg:flex-row lg:items-center lg:justify-between">
          <div>
            <h2 className="text-xl font-black text-on-surface">Tạo thông báo mới</h2>
            {validationErrors.length > 0 ? <p className="mt-1 text-sm font-semibold text-error">{validationErrors[0]}</p> : null}
          </div>
          <div className="rounded-full bg-surface-container-low px-5 py-2 text-sm font-bold text-on-surface">{recipientCount.toLocaleString()} người nhận</div>
        </div>

        <div className="grid grid-cols-1 gap-4 xl:grid-cols-4">
          <input value={form.title} onChange={(event) => setForm((current) => ({ ...current, title: event.target.value }))} placeholder="Tiêu đề" className="rounded-2xl bg-surface-container-low px-5 py-3 outline-none xl:col-span-2" required />
          <input value={form.type} onChange={(event) => setForm((current) => ({ ...current, type: event.target.value }))} placeholder="Loại thông báo" className="rounded-2xl bg-surface-container-low px-5 py-3 outline-none" required />
          <select value={form.recipientMode} onChange={(event) => setForm((current) => ({ ...current, recipientMode: event.target.value as AdminSendNotificationRequest['recipientMode'] }))} className="rounded-2xl bg-surface-container-low px-5 py-3 outline-none">
            <option value="all">Tất cả người dùng</option>
            <option value="active">Người dùng đang hoạt động</option>
            <option value="role">Theo nhóm quyền</option>
            <option value="users">Chọn từng người</option>
          </select>
          {form.recipientMode === 'role' ? (
            <select value={form.role} onChange={(event) => setForm((current) => ({ ...current, role: event.target.value as AdminUser['role'] }))} className="rounded-2xl bg-surface-container-low px-5 py-3 outline-none">
              {roleOptions.map((role) => <option key={role.value} value={role.value}>{role.label}</option>)}
            </select>
          ) : null}
          <input value={form.referenceType ?? ''} onChange={(event) => setForm((current) => ({ ...current, referenceType: event.target.value }))} placeholder="Reference type" className="rounded-2xl bg-surface-container-low px-5 py-3 outline-none" />
          <input value={form.referenceId ?? ''} onChange={(event) => setForm((current) => ({ ...current, referenceId: event.target.value === '' ? null : Number(event.target.value) }))} type="number" min={1} placeholder="Reference ID" className="rounded-2xl bg-surface-container-low px-5 py-3 outline-none" />
          <input value={form.actionUrl ?? ''} onChange={(event) => setForm((current) => ({ ...current, actionUrl: event.target.value }))} placeholder="Action URL" className="rounded-2xl bg-surface-container-low px-5 py-3 outline-none xl:col-span-2" />
        </div>

        <textarea value={form.message} onChange={(event) => setForm((current) => ({ ...current, message: event.target.value }))} placeholder="Nội dung" rows={5} className="mt-4 w-full rounded-2xl bg-surface-container-low px-5 py-4 outline-none" required />

        <div className="mt-4 flex flex-wrap gap-3">
          {channelOptions.map((channel) => {
            const active = form.channels.includes(channel.value);
            return (
              <button key={channel.value} type="button" onClick={() => toggleChannel(channel.value)} className={`flex items-center gap-2 rounded-full px-5 py-3 text-sm font-bold transition-all ${active ? 'bg-primary-container text-white' : 'bg-surface-container-low text-on-surface'}`}>
                <span className="material-symbols-outlined text-base">{channel.icon}</span>
                {channel.label}
              </button>
            );
          })}
        </div>

        {form.recipientMode === 'users' ? (
          <div className="mt-5 max-h-72 overflow-y-auto rounded-2xl bg-surface-container-low p-4">
            <div className="grid grid-cols-1 gap-3 md:grid-cols-2 xl:grid-cols-3">
              {users.map((user) => (
                <label key={user.id} className="flex items-center gap-3 rounded-2xl bg-white px-4 py-3">
                  <input checked={form.userIds.includes(user.id)} onChange={() => toggleUser(user.id)} type="checkbox" className="h-4 w-4 accent-[#10B981]" />
                  <span className="min-w-0">
                    <span className="block truncate text-sm font-bold text-on-surface">{user.name}</span>
                    <span className="block truncate text-xs text-on-surface-variant">{user.email}</span>
                  </span>
                </label>
              ))}
              {users.length === 0 ? <p className="text-sm text-on-surface-variant">Chưa có người dùng khả dụng.</p> : null}
            </div>
          </div>
        ) : null}

        <div className="mt-6">
          <button type="submit" disabled={submitting || validationErrors.length > 0} className="rounded-full bg-primary-container px-8 py-3 text-sm font-bold text-white disabled:opacity-50">
            {submitting ? 'Đang gửi...' : 'Gửi thông báo'}
          </button>
        </div>
      </form>

      <div className="overflow-hidden rounded-[2rem] bg-white shadow-[0px_20px_40px_rgba(21,28,39,0.04)]">
        {filteredNotifications.length === 0 ? (
          <div className="p-12 text-center">
            <span className="material-symbols-outlined text-5xl text-on-surface-variant">notifications_off</span>
            <p className="mt-4 text-lg font-black text-on-surface">Chưa có thông báo</p>
            <p className="mt-2 text-sm text-on-surface-variant">{query.trim() ? 'Không có kết quả phù hợp.' : 'Danh sách hiện đang trống.'}</p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full border-collapse text-left">
              <thead>
                <tr className="bg-surface-container-low/50">
                  <th className="px-8 py-5 text-[11px] font-black uppercase tracking-widest text-on-surface-variant">Thông báo</th>
                  <th className="px-8 py-5 text-[11px] font-black uppercase tracking-widest text-on-surface-variant">Người nhận</th>
                  <th className="px-8 py-5 text-[11px] font-black uppercase tracking-widest text-on-surface-variant">Loại</th>
                  <th className="px-8 py-5 text-[11px] font-black uppercase tracking-widest text-on-surface-variant">Trạng thái</th>
                  <th className="px-8 py-5 text-[11px] font-black uppercase tracking-widest text-on-surface-variant">Ngày tạo</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-outline-variant/10">
                {filteredNotifications.map((notification) => (
                  <tr key={notification.id}>
                    <td className="px-8 py-6">
                      <p className="font-bold text-on-surface">{notification.title}</p>
                      <p className="mt-1 max-w-xl text-sm text-on-surface-variant">{notification.message}</p>
                    </td>
                    <td className="px-8 py-6">
                      <p className="text-sm font-bold text-on-surface">{notification.userName}</p>
                      <p className="mt-1 text-xs text-on-surface-variant">{notification.userEmail || 'Không có email'}</p>
                    </td>
                    <td className="px-8 py-6">
                      <span className="rounded-full bg-surface-container-low px-4 py-1.5 text-xs font-bold text-on-surface">{notification.type}</span>
                    </td>
                    <td className="px-8 py-6">
                      <span className={`rounded-full px-4 py-1.5 text-xs font-bold ${notification.isRead ? 'bg-primary-container/10 text-primary-container' : 'bg-error-container text-error'}`}>{notification.isRead ? 'Đã đọc' : 'Chưa đọc'}</span>
                    </td>
                    <td className="px-8 py-6 text-sm font-medium text-on-surface-variant">{notification.createdAt}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  );
}
