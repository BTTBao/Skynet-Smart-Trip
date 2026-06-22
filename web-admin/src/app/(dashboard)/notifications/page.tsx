"use client";

import { useEffect, useMemo, useState } from 'react';
import { useAdminSearch } from '@/contexts/AdminSearchContext';
import {
  adminService,
  type AdminNotificationStats,
  type AdminSendNotificationRequest,
  type AdminUser,
} from '@/services/adminService';
import { downloadCsv, getPageNumbers } from '@/utils/adminActions';
import { toast } from 'sonner';
import {
  Card,
  CardContent,
  CardHeader,
  CardTitle,
  CardDescription,
} from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { MetricCard } from "@/components/ui/metric-card";
import { Badge } from "@/components/ui/badge";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Checkbox } from "@/components/ui/checkbox";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import {
  Bell,
  Mail,
  Smartphone,
  Send,
  Users,
  Search,
  Download,
  Info,
  ChevronLeft,
  ChevronRight,
} from 'lucide-react';

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
  { value: 'customer', label: 'Khách hàng' },
  { value: 'staff', label: 'Nhân viên' },
  { value: 'partner', label: 'Đối tác' },
  { value: 'admin', label: 'Quản trị viên' },
];

const channelOptions: Array<{ value: AdminSendNotificationRequest['channels'][number]; label: string; icon: any }> = [
  { value: 'in_app', label: 'Ứng dụng (In-app)', icon: Bell },
  { value: 'email', label: 'Thư điện tử (Email)', icon: Mail },
  { value: 'fcm', label: 'Đẩy (Push/FCM)', icon: Smartphone },
];

const getFriendlyNotificationType = (type: string) => {
  const typeMap: Record<string, string> = {
    'booking.bus_paid': 'Vé xe đã thanh toán',
    'booking.hotel_paid': 'Khách sạn đã thanh toán',
    'payment.succeeded': 'Thanh toán thành công',
    'trip.created': 'Chuyến đi đã tạo',
    'system': 'Hệ thống',
    'promotion': 'Khuyến mãi',
    'transaction': 'Giao dịch',
  };
  return typeMap[type] || type.split('.').map(part => part.split('_').map(word => word.charAt(0).toUpperCase() + word.slice(1)).join(' ')).join(' - ');
};

export default function NotificationsAdminPage() {
  const { query } = useAdminSearch();
  const [stats, setStats] = useState<AdminNotificationStats | null>(null);
  const [users, setUsers] = useState<AdminUser[]>([]);
  const [loading, setLoading] = useState(true);
  const PAGE_SIZE = 6;
  const [currentPage, setCurrentPage] = useState(1);
  const [error, setError] = useState<string | null>(null);
  const [form, setForm] = useState<AdminSendNotificationRequest>(initialForm);
  const [submitting, setSubmitting] = useState(false);

  // local search inside user selection list
  const [userSearchText, setUserSearchText] = useState('');

  const loadNotifications = async (search = query) => {
    const data = await adminService.getNotifications({ search: search.trim() || undefined });
    setStats(data);
  };

  useEffect(() => {
    const fetchData = async () => {
      try {
        setLoading(true);
        const [notificationData, userData] = await Promise.all([
          adminService.getNotifications(),
          adminService.getUsers(),
        ]);
        setStats(notificationData);
        setUsers(userData.users.filter((user) => user.status === 'active'));
        setError(null);
      } catch (err: any) {
        const msg = err?.message || 'Lỗi kết nối';
        setError(msg);
        toast.error('Không thể tải dữ liệu thông báo: ' + msg);
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
      } catch (err: any) {
        toast.error('Tìm kiếm thất bại: ' + (err?.message || 'Có lỗi xảy ra'));
      }
    }, 300);

    return () => window.clearTimeout(handle);
  }, [query]);

  useEffect(() => {
    setCurrentPage(1);
  }, [query]);

  const filteredNotifications = useMemo(() => stats?.notifications ?? [], [stats]);

  const totalPages = Math.max(1, Math.ceil(filteredNotifications.length / PAGE_SIZE));
  const currentPageClamped = Math.min(currentPage, totalPages);
  const paginatedNotifications = filteredNotifications.slice((currentPageClamped - 1) * PAGE_SIZE, currentPageClamped * PAGE_SIZE);
  const pageNumbers = getPageNumbers(currentPageClamped, totalPages);

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

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (validationErrors.length > 0) {
      toast.warning(validationErrors[0]);
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
      toast.success('Đã gửi thông báo thành công', {
        description: `Gửi đến ${result.targetedUsers} người nhận. Kênh in-app: ${result.inAppCreated}, Email: ${result.emailSent}/${result.emailAttempted}, FCM: ${result.pushAttempted}.`,
      });
    } catch (err: any) {
      toast.error('Gửi thông báo thất bại: ' + (err?.message || 'Có lỗi xảy ra'));
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
    toast.success('Đã xuất danh sách lịch sử thông báo');
  };

  const filteredUserList = useMemo(() => {
    const s = userSearchText.trim().toLowerCase();
    if (!s) return users;
    return users.filter(u => u.name.toLowerCase().includes(s) || u.email.toLowerCase().includes(s));
  }, [users, userSearchText]);

  if (loading && !stats) {
    return (
      <div className="flex items-center justify-center h-full min-h-[50vh]">
        <div className="animate-spin rounded-full h-10 w-10 border-b-2 border-primary"></div>
      </div>
    );
  }

  if (!stats) return null;

  return (
    <div className="px-4 lg:px-6 space-y-6">
      <div className="flex justify-between items-center gap-4 flex-wrap">
        <div>
          <span className="text-xs font-bold uppercase tracking-wider text-primary">Trung tâm liên lạc</span>
          <h1 className="text-3xl font-extrabold tracking-tight mt-1">Thông báo & Sự kiện</h1>
          <p className="text-muted-foreground text-sm mt-2">
            Gửi tin nhắn thông báo đẩy (FCM), thư điện tử (Email) hoặc bản tin in-app hàng loạt tới khách hàng và đối tác.
          </p>
        </div>
        <Button variant="outline" size="sm" onClick={exportNotifications} className="gap-1.5 cursor-pointer">
          <Download className="h-4 w-4" /> Xuất CSV
        </Button>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <MetricCard
          title="Tổng tin đã gửi"
          value={stats.totalNotifications.toLocaleString()}
          description="Thông báo đẩy & Email gửi đi"
          icon={<Send className="h-4 w-4" />}
          theme="muted"
        />

        <MetricCard
          title="Chưa đọc"
          value={stats.unreadNotifications.toLocaleString()}
          description="Chờ người dùng mở đọc"
          icon={<Bell className="h-4 w-4" />}
          theme="rose"
        />

        <MetricCard
          title="Đã đọc"
          value={stats.readNotifications.toLocaleString()}
          description="Người dùng đã xem nội dung"
          icon={<Mail className="h-4 w-4" />}
          theme="emerald"
        />

        <MetricCard
          title="Khán giả khả dụng"
          value={stats.targetableUsers.toLocaleString()}
          description="Thành viên nhận thông báo"
          icon={<Users className="h-4 w-4" />}
          theme="sky"
        />
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
        {/* Create Broadcast form */}
        <div className="lg:col-span-7">
          <Card>
            <CardHeader className="flex flex-row items-center justify-between pb-6">
              <div>
                <CardTitle className="text-lg font-bold">Gửi thông báo mới</CardTitle>
                <CardDescription>Bắt đầu viết tiêu đề, phân nhóm đối tượng mục tiêu.</CardDescription>
              </div>
              <Badge variant="secondary" className="font-bold">
                {recipientCount} người nhận
              </Badge>
            </CardHeader>
            <CardContent>
              <form onSubmit={handleSubmit} className="space-y-4">
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div className="grid gap-2">
                    <Label htmlFor="notif-title">Tiêu đề thông báo</Label>
                    <Input
                      id="notif-title"
                      value={form.title}
                      onChange={(e) => setForm((c) => ({ ...c, title: e.target.value }))}
                      placeholder="Ưu đãi vé xe, nâng cấp tài khoản..."
                      required
                    />
                  </div>

                  <div className="grid gap-2">
                    <Label htmlFor="notif-type">Loại thông báo (nhãn)</Label>
                    <Input
                      id="notif-type"
                      value={form.type}
                      onChange={(e) => setForm((c) => ({ ...c, type: e.target.value }))}
                      placeholder="system, promotion, transaction..."
                      required
                    />
                  </div>
                </div>

                <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                  <div className="grid gap-2">
                    <Label htmlFor="recipientMode">Chế độ người nhận</Label>
                    <Select
                      value={form.recipientMode}
                      onValueChange={(val) => setForm((c) => ({ ...c, recipientMode: val as any }))}
                    >
                      <SelectTrigger id="recipientMode">
                        <SelectValue placeholder="Chọn người nhận" />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="all">Tất cả thành viên</SelectItem>
                        <SelectItem value="active">Thành viên đang hoạt động</SelectItem>
                        <SelectItem value="role">Theo phân quyền nhóm</SelectItem>
                        <SelectItem value="users">Tự chọn người nhận</SelectItem>
                      </SelectContent>
                    </Select>
                  </div>

                  {form.recipientMode === 'role' && (
                    <div className="grid gap-2">
                      <Label htmlFor="notif-role">Nhóm quyền</Label>
                      <Select
                        value={form.role}
                        onValueChange={(val) => setForm((c) => ({ ...c, role: val as any }))}
                      >
                        <SelectTrigger id="notif-role">
                          <SelectValue placeholder="Chọn nhóm quyền" />
                        </SelectTrigger>
                        <SelectContent>
                          {roleOptions.map((r) => (
                            <SelectItem key={r.value} value={r.value}>
                              {r.label}
                            </SelectItem>
                          ))}
                        </SelectContent>
                      </Select>
                    </div>
                  )}

                  <div className="grid gap-2">
                    <Label htmlFor="ref-type">Mã loại tham chiếu</Label>
                    <Input
                      id="ref-type"
                      value={form.referenceType ?? ''}
                      onChange={(e) => setForm((c) => ({ ...c, referenceType: e.target.value }))}
                      placeholder="Ví dụ: promotion, booking"
                    />
                  </div>

                  <div className="grid gap-2">
                    <Label htmlFor="ref-id">ID tham chiếu</Label>
                    <Input
                      id="ref-id"
                      type="number"
                      value={form.referenceId ?? ''}
                      onChange={(e) => setForm((c) => ({ ...c, referenceId: e.target.value === '' ? null : Number(e.target.value) }))}
                      placeholder="Mã số ID"
                    />
                  </div>
                </div>

                <div className="grid gap-2">
                  <Label htmlFor="actionUrl">Đường dẫn chuyển hướng (URL)</Label>
                  <Input
                    id="actionUrl"
                    value={form.actionUrl ?? ''}
                    onChange={(e) => setForm((c) => ({ ...c, actionUrl: e.target.value }))}
                    placeholder="https://..."
                  />
                </div>

                <div className="grid gap-2">
                  <Label htmlFor="notif-msg">Nội dung chi tiết thông điệp</Label>
                  <Textarea
                    id="notif-msg"
                    value={form.message}
                    onChange={(e) => setForm((c) => ({ ...c, message: e.target.value }))}
                    placeholder="Viết nội dung ngắn gọn để hiển thị đẹp nhất trên điện thoại di động..."
                    rows={4}
                    required
                  />
                </div>

                {/* Send channels check */}
                <div className="space-y-3 pt-2">
                  <Label className="text-xs font-bold text-muted-foreground block">Các kênh truyền tải thông điệp</Label>
                  <div className="flex flex-wrap gap-4">
                    {channelOptions.map((c) => {
                      const active = form.channels.includes(c.value);
                      const Icon = c.icon;
                      return (
                        <Button
                          key={c.value}
                          type="button"
                          variant={active ? 'default' : 'outline'}
                          size="sm"
                          onClick={() => toggleChannel(c.value)}
                          className="gap-1.5 cursor-pointer h-9 text-xs"
                        >
                          <Icon className="h-4 w-4" /> {c.label}
                        </Button>
                      );
                    })}
                  </div>
                </div>

                <div className="flex justify-end gap-2 pt-4 border-t">
                  <Button type="submit" disabled={submitting || validationErrors.length > 0} className="cursor-pointer gap-1.5 w-full md:w-auto">
                    <Send className="h-3.5 w-3.5" /> {submitting ? 'Đang gửi...' : 'Phát sóng thông báo'}
                  </Button>
                </div>
              </form>
            </CardContent>
          </Card>
        </div>

        {/* User Picker details */}
        <div className="lg:col-span-5">
          {form.recipientMode === 'users' ? (
            <Card className="h-full flex flex-col">
              <CardHeader className="pb-3">
                <CardTitle className="text-sm font-bold flex items-center gap-1.5">
                  <Users className="h-4 w-4 text-primary" /> Chọn người nhận riêng lẻ ({form.userIds.length})
                </CardTitle>
                <CardDescription>Tìm kiếm và đánh dấu người nhận cụ thể bên dưới.</CardDescription>
              </CardHeader>
              <CardContent className="flex-1 flex flex-col min-h-0 space-y-4">
                <div className="relative">
                  <Search className="absolute left-2.5 top-2.5 h-3.5 w-3.5 text-muted-foreground" />
                  <Input
                    placeholder="Tìm tên hoặc địa chỉ email..."
                    value={userSearchText}
                    onChange={(e) => setUserSearchText(e.target.value)}
                    className="pl-8 h-9 text-xs"
                  />
                </div>

                <div className="flex-1 max-h-[350px] overflow-y-auto border rounded-lg p-2 divide-y bg-muted/10">
                  {filteredUserList.length === 0 ? (
                    <div className="text-center py-8 text-xs text-muted-foreground">
                      Không tìm thấy người dùng phù hợp.
                    </div>
                  ) : (
                    filteredUserList.map((user) => {
                      const checked = form.userIds.includes(user.id);
                      return (
                        <div
                          key={user.id}
                          className="flex items-center space-x-3 py-2 px-1 hover:bg-muted/30 select-none cursor-pointer"
                          onClick={() => toggleUser(user.id)}
                        >
                          <Checkbox id={`u-chk-${user.id}`} checked={checked} onCheckedChange={() => {}} />
                          <div className="min-w-0 flex-1 text-xs">
                            <Label htmlFor={`u-chk-${user.id}`} className="font-bold block truncate pointer-events-none">{user.name}</Label>
                            <span className="text-[10px] text-muted-foreground block truncate pointer-events-none">{user.email}</span>
                          </div>
                        </div>
                      );
                    })
                  )}
                </div>
              </CardContent>
            </Card>
          ) : (
            <Card className="h-full bg-muted/20 border-dashed flex flex-col justify-center items-center p-8 text-center min-h-[300px]">
              <CardContent className="space-y-3">
                <div className="w-12 h-12 rounded-full bg-muted border flex items-center justify-center mx-auto">
                  <Info className="h-6 w-6 text-muted-foreground" />
                </div>
                <div>
                  <h3 className="font-bold text-sm">Gửi theo nhóm</h3>
                  <p className="text-xs text-muted-foreground mt-1 max-w-[240px] mx-auto">
                    Hiện tại bạn đang cấu hình thông điệp gửi tự động hàng loạt. Hãy chuyển chế độ &ldquo;Tự chọn người nhận&rdquo; nếu muốn gửi đơn lẻ.
                  </p>
                </div>
              </CardContent>
            </Card>
          )}
        </div>
      </div>

      {/* Notifications history */}
      <Card>
        <CardHeader>
          <CardTitle className="text-lg font-bold">Lịch sử thông báo đã gửi</CardTitle>
          <CardDescription>Bảng nhật ký giám sát hoạt động thông báo hệ thống.</CardDescription>
        </CardHeader>
        <CardContent className="p-0">
          <div className="overflow-x-auto">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead className="pl-6">Thông điệp</TableHead>
                  <TableHead>Người nhận</TableHead>
                  <TableHead>Chủ đề / Nhãn</TableHead>
                  <TableHead>Trạng thái đọc</TableHead>
                  <TableHead className="pr-6 text-right">Ngày gửi</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {filteredNotifications.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={5} className="text-center py-12 text-sm text-muted-foreground">
                      Không tìm thấy lịch sử thông báo nào.
                    </TableCell>
                  </TableRow>
                ) : (
                  paginatedNotifications.map((notif) => (
                    <TableRow key={notif.id} className="hover:bg-muted/30">
                      <TableCell className="pl-6 py-4">
                        <div>
                          <span className="font-bold text-xs block">{notif.title}</span>
                          <span className="text-[10px] text-muted-foreground font-semibold block mt-0.5 max-w-[400px] truncate">
                            {notif.message}
                          </span>
                        </div>
                      </TableCell>
                      <TableCell>
                        <div>
                          <p className="text-xs font-bold">{notif.userName}</p>
                          <p className="text-[10px] text-muted-foreground">{notif.userEmail || 'Không có'}</p>
                        </div>
                      </TableCell>
                      <TableCell>
                        <Badge variant="outline" className="text-[10px] font-bold">
                          {getFriendlyNotificationType(notif.type)}
                        </Badge>
                      </TableCell>
                      <TableCell>
                        {notif.isRead ? (
                          <Badge variant="secondary" className="bg-emerald-500/10 text-emerald-600 dark:text-emerald-400">
                            Đã đọc
                          </Badge>
                        ) : (
                          <Badge variant="outline">Chưa đọc</Badge>
                        )}
                      </TableCell>
                      <TableCell className="pr-6 text-right text-xs font-semibold text-muted-foreground">
                        {notif.createdAt}
                      </TableCell>
                    </TableRow>
                  ))
                )}
              </TableBody>
            </Table>
          </div>
          {/* Pagination Footer */}
          <div className="flex items-center justify-between px-6 py-4 border-t">
            <Button
              size="sm"
              variant="outline"
              onClick={() => setCurrentPage((page) => Math.max(1, page - 1))}
              disabled={currentPageClamped === 1}
              className="gap-1 cursor-pointer h-8 text-xs"
            >
              <ChevronLeft className="h-3.5 w-3.5" /> Trước
            </Button>
            <div className="flex items-center gap-1.5">
              {pageNumbers.map((page) => (
                <Button
                  key={page}
                  size="sm"
                  variant={currentPageClamped === page ? 'default' : 'ghost'}
                  onClick={() => setCurrentPage(page)}
                  className="w-8 h-8 p-0 text-xs cursor-pointer"
                >
                  {page}
                </Button>
              ))}
            </div>
            <Button
              size="sm"
              variant="outline"
              onClick={() => setCurrentPage((page) => Math.min(totalPages, page + 1))}
              disabled={currentPageClamped === totalPages}
              className="gap-1 cursor-pointer h-8 text-xs"
            >
              Sau <ChevronRight className="h-3.5 w-3.5" />
            </Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
