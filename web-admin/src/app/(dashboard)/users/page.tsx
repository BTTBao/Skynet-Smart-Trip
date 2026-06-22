"use client";

import { useEffect, useMemo, useState } from 'react';
import { useAdminSearch } from '@/contexts/AdminSearchContext';
import {
  adminService,
  type AdminCreateUserRequest,
  type AdminUpdateUserRequest,
  type AdminUser,
  type AdminUserStats,
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
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
  DialogFooter,
} from "@/components/ui/dialog";
import { Switch } from "@/components/ui/switch";
import { Label } from "@/components/ui/label";
import {
  Users,
  UserCheck,
  UserX,
  UserPlus,
  Plus,
  Trash2,
  Edit2,
  Download,
  ChevronLeft,
  ChevronRight,
  TrendingUp,
} from 'lucide-react';

const PAGE_SIZE = 6;

const statusConfig = {
  active: {
    label: 'Hoạt động',
    className: 'bg-emerald-500/10 text-emerald-600 dark:text-emerald-400',
  },
  blocked: {
    label: 'Đã khóa',
    className: 'bg-destructive/10 text-destructive',
  },
};

const roleOptions: Array<{ value: AdminUser['role']; label: string }> = [
  { value: 'customer', label: 'Khách hàng (Customer)' },
  { value: 'staff', label: 'Nhân viên (Staff)' },
  { value: 'partner', label: 'Đối tác (Partner)' },
  { value: 'admin', label: 'Quản trị viên (Admin)' },
];

const initialCreateForm: AdminCreateUserRequest = {
  name: '',
  email: '',
  phone: '',
  role: 'customer',
  isActive: true,
};

const initialEditForm: AdminUpdateUserRequest = {
  name: '',
  email: '',
  phone: '',
  role: 'customer',
  isActive: true,
};

export default function UsersAdminPage() {
  const { query } = useAdminSearch();
  const [stats, setStats] = useState<AdminUserStats | null>(null);
  const [loading, setLoading] = useState(true);
  const [statusFilter, setStatusFilter] = useState<'all' | AdminUser['status']>('all');
  const [roleFilter, setRoleFilter] = useState<'all' | AdminUser['role']>('all');
  const [sortOrder, setSortOrder] = useState<'newest' | 'oldest'>('newest');
  const [currentPage, setCurrentPage] = useState(1);
  const [editingUser, setEditingUser] = useState<AdminUser | null>(null);
  const [showCreateForm, setShowCreateForm] = useState(false);
  const [createForm, setCreateForm] = useState<AdminCreateUserRequest>(initialCreateForm);
  const [editForm, setEditForm] = useState<AdminUpdateUserRequest>(initialEditForm);
  const [submitting, setSubmitting] = useState(false);

  const loadUsers = async (search = query) => {
    try {
      const data = await adminService.getUsers({ search: search.trim() || undefined });
      setStats(data);
    } catch (error: any) {
      toast.error('Không thể tải danh sách người dùng: ' + (error?.message || 'Lỗi'));
    }
  };

  useEffect(() => {
    const fetchData = async () => {
      setLoading(true);
      await loadUsers();
      setLoading(false);
    };

    fetchData();
  }, []);

  useEffect(() => {
    const handle = window.setTimeout(async () => {
      try {
        await loadUsers();
      } catch (error: any) {
        toast.error('Tìm kiếm thất bại: ' + (error?.message || 'Lỗi'));
      }
    }, 300);

    return () => window.clearTimeout(handle);
  }, [query]);

  useEffect(() => {
    setCurrentPage(1);
  }, [statusFilter, roleFilter, sortOrder, query]);

  const filteredUsers = useMemo(() => {
    if (!stats) return [];

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
      { key: 'status', header: 'Trạng thái' },
    ]);
    toast.success('Xuất file CSV danh sách người dùng thành công');
  };

  const handleCreateUser = async (e: React.FormEvent) => {
    e.preventDefault();
    if (createForm.name.trim().length === 0 || createForm.email.trim().length === 0) {
      toast.warning('Vui lòng nhập tên và email.');
      return;
    }

    setSubmitting(true);
    try {
      await adminService.createUser(createForm);
      toast.success('Đã tạo tài khoản thành viên mới thành công');
      await loadUsers();
      setShowCreateForm(false);
      setCreateForm(initialCreateForm);
    } catch (error: any) {
      toast.error('Lỗi tạo tài khoản: ' + (error?.message || 'Có lỗi xảy ra'));
    } finally {
      setSubmitting(false);
    }
  };

  const handleEditUser = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!editingUser) return;

    setSubmitting(true);
    try {
      await adminService.updateUser(editingUser.id, editForm);
      toast.success('Đã cập nhật thông tin thành viên thành công');
      await loadUsers();
      setEditingUser(null);
    } catch (error: any) {
      toast.error('Lỗi cập nhật tài khoản: ' + (error?.message || 'Có lỗi xảy ra'));
    } finally {
      setSubmitting(false);
    }
  };

  const startEdit = (user: AdminUser) => {
    setEditingUser(user);
    setEditForm({
      name: user.name,
      email: user.email,
      phone: user.phone === '--' ? '' : user.phone,
      role: user.role,
      isActive: user.status === 'active',
    });
  };

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
          <span className="text-xs font-bold uppercase tracking-wider text-primary">Catalog bảo mật</span>
          <h1 className="text-3xl font-extrabold tracking-tight mt-1">Quản lý người dùng</h1>
          <p className="text-muted-foreground text-sm mt-2">
            Phân quyền quản trị hệ thống, cấp mới tài khoản khách hàng, khóa/mở khóa thành viên vi phạm chính sách.
          </p>
        </div>
        <div className="flex items-center gap-2">
          <Button variant="outline" size="sm" onClick={exportUsers} className="gap-1.5 cursor-pointer">
            <Download className="h-4 w-4" /> Xuất CSV
          </Button>
          <Button size="sm" onClick={() => setShowCreateForm(true)} className="gap-1.5 cursor-pointer">
            <Plus className="h-4 w-4" /> Thêm tài khoản
          </Button>
        </div>
      </div>

      {/* Metrics Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-4 gap-4">
        <MetricCard
          title="Tổng số thành viên"
          value={`${stats.totalUsers.toLocaleString()} thành viên`}
          description="Người dùng đăng ký tài khoản"
          icon={<Users className="h-4 w-4" />}
          theme="muted"
        />

        <MetricCard
          title="Đang hoạt động"
          value={`${stats.activeUsers.toLocaleString()} hoạt động`}
          description="Tài khoản trạng thái khả dụng"
          icon={<UserCheck className="h-4 w-4" />}
          theme="emerald"
        />

        <MetricCard
          title="Tài khoản bị khóa"
          value={`${stats.blockedUsers.toLocaleString()} đã khóa`}
          description="Tài khoản vi phạm quy chế"
          icon={<UserX className="h-4 w-4" />}
          theme="rose"
        />

        <MetricCard
          title="Thành viên mới (tháng này)"
          value={`+${stats.newUsers} đăng ký`}
          description="Tỷ lệ tăng trưởng người dùng"
          icon={<TrendingUp className="h-4 w-4" />}
          theme="sky"
        />
      </div>

      {/* Filter and sorting controls */}
      <div className="flex flex-wrap items-center gap-4 bg-muted/20 border p-4 rounded-xl">
        <div className="grid gap-1.5">
          <Label className="text-xs font-bold">Lọc theo trạng thái</Label>
          <Select
            value={statusFilter}
            onValueChange={(val) => setStatusFilter(val as any)}
          >
            <SelectTrigger className="w-[180px] bg-background h-9 text-xs">
              <SelectValue placeholder="Chọn trạng thái" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">Tất cả trạng thái</SelectItem>
              <SelectItem value="active">Hoạt động</SelectItem>
              <SelectItem value="blocked">Đã khóa</SelectItem>
            </SelectContent>
          </Select>
        </div>

        <div className="grid gap-1.5">
          <Label className="text-xs font-bold">Lọc theo vai trò</Label>
          <Select
            value={roleFilter}
            onValueChange={(val) => setRoleFilter(val as any)}
          >
            <SelectTrigger className="w-[180px] bg-background h-9 text-xs">
              <SelectValue placeholder="Chọn vai trò" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">Tất cả vai trò</SelectItem>
              <SelectItem value="customer">Khách hàng (Customer)</SelectItem>
              <SelectItem value="staff">Nhân viên (Staff)</SelectItem>
              <SelectItem value="partner">Đối tác (Partner)</SelectItem>
              <SelectItem value="admin">Quản trị viên (Admin)</SelectItem>
            </SelectContent>
          </Select>
        </div>

        <div className="grid gap-1.5">
          <Label className="text-xs font-bold">Sắp xếp</Label>
          <Select
            value={sortOrder}
            onValueChange={(val) => setSortOrder(val as any)}
          >
            <SelectTrigger className="w-[180px] bg-background h-9 text-xs">
              <SelectValue placeholder="Chọn thứ tự" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="newest">Ngày tham gia mới nhất</SelectItem>
              <SelectItem value="oldest">Ngày tham gia cũ nhất</SelectItem>
            </SelectContent>
          </Select>
        </div>
      </div>

      {/* Users table */}
      <Card>
        <CardContent className="p-0">
          <div className="overflow-x-auto">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead className="pl-6">Thành viên</TableHead>
                  <TableHead>Địa chỉ Email</TableHead>
                  <TableHead>Hotline / Điện thoại</TableHead>
                  <TableHead>Nhóm quyền</TableHead>
                  <TableHead>Ngày tham gia</TableHead>
                  <TableHead className="text-center">Trạng thái</TableHead>
                  <TableHead className="pr-6 text-right">Thao tác</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {paginatedUsers.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={7} className="text-center py-12 text-sm text-muted-foreground">
                      Không tìm thấy tài khoản thành viên nào phù hợp.
                    </TableCell>
                  </TableRow>
                ) : (
                  paginatedUsers.map((user) => {
                    const status = statusConfig[user.status] || { label: user.status, className: '' };
                    const initials = user.name
                      .split(' ')
                      .filter(Boolean)
                      .slice(0, 2)
                      .map((p) => p[0]?.toUpperCase() ?? '')
                      .join('');

                    return (
                      <TableRow key={user.id} className="hover:bg-muted/30">
                        <TableCell className="pl-6 py-4">
                          <div className="flex items-center gap-2.5">
                            <div className="h-9 w-9 bg-primary/10 rounded-full flex items-center justify-center font-bold text-xs text-primary shrink-0">
                              {initials || 'U'}
                            </div>
                            <div className="min-w-0">
                              <span className="font-bold text-xs block truncate max-w-[180px]">{user.name}</span>
                              <span className="text-[10px] text-muted-foreground font-semibold block mt-0.5">
                                Mã: {user.displayId}
                              </span>
                            </div>
                          </div>
                        </TableCell>
                        <TableCell className="text-xs font-semibold">{user.email}</TableCell>
                        <TableCell className="text-xs font-semibold">{user.phone}</TableCell>
                        <TableCell>
                          <Badge variant="outline" className="text-[10px] uppercase font-bold px-1.5 py-0 capitalize">
                            {user.role}
                          </Badge>
                        </TableCell>
                        <TableCell className="text-xs text-muted-foreground">{user.joinDate}</TableCell>
                        <TableCell className="text-center">
                          <Badge variant="secondary" className={status.className}>
                            {status.label}
                          </Badge>
                        </TableCell>
                        <TableCell className="pr-6 text-right">
                          <Button
                            size="sm"
                            variant="ghost"
                            onClick={() => startEdit(user)}
                            className="h-8 w-8 p-0 cursor-pointer"
                          >
                            <Edit2 className="h-3.5 w-3.5 text-muted-foreground" />
                          </Button>
                        </TableCell>
                      </TableRow>
                    );
                  })
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

      {/* Create Dialog */}
      <Dialog open={showCreateForm} onOpenChange={setShowCreateForm}>
        <DialogContent className="max-w-md">
          <DialogHeader>
            <DialogTitle>Tạo tài khoản thành viên mới</DialogTitle>
            <DialogDescription>Cấp mới thông tin truy cập hệ thống.</DialogDescription>
          </DialogHeader>
          <form onSubmit={handleCreateUser} className="space-y-4">
            <div className="grid gap-2">
              <Label htmlFor="c-name">Họ và tên</Label>
              <Input
                id="c-name"
                value={createForm.name}
                onChange={(e) => setCreateForm((c) => ({ ...c, name: e.target.value }))}
                placeholder="Nguyễn Văn A"
                required
              />
            </div>

            <div className="grid gap-2">
              <Label htmlFor="c-email">Địa chỉ Email</Label>
              <Input
                id="c-email"
                type="email"
                value={createForm.email}
                onChange={(e) => setCreateForm((c) => ({ ...c, email: e.target.value }))}
                placeholder="name@domain.com"
                required
              />
            </div>

            <div className="grid gap-2">
              <Label htmlFor="c-phone">Số điện thoại</Label>
              <Input
                id="c-phone"
                value={createForm.phone}
                onChange={(e) => setCreateForm((c) => ({ ...c, phone: e.target.value }))}
                placeholder="09XXXXXXXX"
              />
            </div>

            <div className="grid gap-2">
              <Label htmlFor="c-role">Nhóm quyền</Label>
              <Select
                value={createForm.role}
                onValueChange={(val) => setCreateForm((c) => ({ ...c, role: val as any }))}
              >
                <SelectTrigger id="c-role">
                  <SelectValue placeholder="Chọn vai trò" />
                </SelectTrigger>
                <SelectContent>
                  {roleOptions.map((role) => (
                    <SelectItem key={role.value} value={role.value}>
                      {role.label}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>

            <div className="flex items-center space-x-2 pt-2">
              <Switch
                id="c-active"
                checked={createForm.isActive}
                onCheckedChange={(checked) => setCreateForm((c) => ({ ...c, isActive: checked }))}
              />
              <Label htmlFor="c-active">Kích hoạt tài khoản</Label>
            </div>

            <DialogFooter className="pt-4 border-t">
              <Button type="button" variant="outline" onClick={() => setShowCreateForm(false)} className="cursor-pointer">
                Đóng
              </Button>
              <Button type="submit" disabled={submitting} className="cursor-pointer">
                {submitting ? 'Đang tạo...' : 'Tạo tài khoản'}
              </Button>
            </DialogFooter>
          </form>
        </DialogContent>
      </Dialog>

      {/* Edit Dialog */}
      <Dialog open={Boolean(editingUser)} onOpenChange={(open) => !open && setEditingUser(null)}>
        {editingUser && (
          <DialogContent className="max-w-md">
            <DialogHeader>
              <DialogTitle>Cập nhật tài khoản: {editingUser.name}</DialogTitle>
              <DialogDescription>Thay đổi thông tin liên lạc và cấu hình phân quyền.</DialogDescription>
            </DialogHeader>
            <form onSubmit={handleEditUser} className="space-y-4">
              <div className="grid gap-2">
                <Label htmlFor="e-name">Họ và tên</Label>
                <Input
                  id="e-name"
                  value={editForm.name}
                  onChange={(e) => setEditForm((c) => ({ ...c, name: e.target.value }))}
                  required
                />
              </div>

              <div className="grid gap-2">
                <Label htmlFor="e-phone">Số điện thoại</Label>
                <Input
                  id="e-phone"
                  value={editForm.phone}
                  onChange={(e) => setEditForm((c) => ({ ...c, phone: e.target.value }))}
                />
              </div>

              <div className="grid gap-2">
                <Label htmlFor="e-role">Nhóm quyền</Label>
                <Select
                  value={editForm.role}
                  onValueChange={(val) => setEditForm((c) => ({ ...c, role: val as any }))}
                >
                  <SelectTrigger id="e-role">
                    <SelectValue placeholder="Chọn vai trò" />
                  </SelectTrigger>
                  <SelectContent>
                    {roleOptions.map((role) => (
                      <SelectItem key={role.value} value={role.value}>
                        {role.label}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>

              <div className="flex items-center space-x-2 pt-2">
                <Switch
                  id="e-active"
                  checked={editForm.isActive}
                  onCheckedChange={(checked) => setEditForm((c) => ({ ...c, isActive: checked }))}
                />
                <Label htmlFor="e-active">Trạng thái kích hoạt (Hoạt động)</Label>
              </div>

              <DialogFooter className="pt-4 border-t">
                <Button type="button" variant="outline" onClick={() => setEditingUser(null)} className="cursor-pointer">
                  Đóng
                </Button>
                <Button type="submit" disabled={submitting} className="cursor-pointer">
                  {submitting ? 'Đang lưu...' : 'Lưu thay đổi'}
                </Button>
              </DialogFooter>
            </form>
          </DialogContent>
        )}
      </Dialog>
    </div>
  );
}
