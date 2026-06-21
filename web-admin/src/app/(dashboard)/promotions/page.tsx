"use client";

import { useEffect, useMemo, useState } from 'react';
import { useAdminSearch } from '@/contexts/AdminSearchContext';
import {
  adminService,
  type AdminPromotion,
  type AdminPromotionRequest,
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
import { Label } from "@/components/ui/label";
import {
  Ticket,
  Percent,
  Calendar,
  Layers,
  Download,
  Plus,
  Trash2,
  Edit2,
  BadgeAlert,
  ChevronLeft,
  ChevronRight,
} from 'lucide-react';
import { ConfirmDialog } from '@/components/ui/confirm-dialog';

const initialForm: AdminPromotionRequest = {
  code: '',
  discountPercent: 10,
  maxDiscountAmount: 100000,
  validUntil: new Date().toISOString().slice(0, 10),
  usageLimit: 100,
};

export default function PromotionsAdminPage() {
  const { query } = useAdminSearch();
  const PAGE_SIZE = 6;
  const [promotions, setPromotions] = useState<AdminPromotion[]>([]);
  const [loading, setLoading] = useState(true);
  const [currentPage, setCurrentPage] = useState(1);
  const [editingPromotion, setEditingPromotion] = useState<AdminPromotion | null>(null);
  const [form, setForm] = useState<AdminPromotionRequest>(initialForm);
  const [submitting, setSubmitting] = useState(false);
  const [deleteConfirmOpen, setDeleteConfirmOpen] = useState(false);
  const [promotionToDelete, setPromotionToDelete] = useState<AdminPromotion | null>(null);

  const loadPromotions = async () => {
    try {
      const data = await adminService.getPromotions();
      setPromotions(data);
    } catch (error: any) {
      toast.error('Không thể tải khuyến mãi: ' + (error?.message || 'Lỗi kết nối'));
    }
  };

  useEffect(() => {
    const fetchData = async () => {
      setLoading(true);
      await loadPromotions();
      setLoading(false);
    };

    fetchData();
  }, []);

  const filteredPromotions = useMemo(() => {
    const keyword = query.trim().toLowerCase();
    return promotions.filter((promotion) =>
      keyword.length === 0 || promotion.code.toLowerCase().includes(keyword)
    );
  }, [promotions, query]);

  useEffect(() => {
    setCurrentPage(1);
  }, [query]);

  const totalPages = Math.max(1, Math.ceil(filteredPromotions.length / PAGE_SIZE));
  const currentPageClamped = Math.min(currentPage, totalPages);
  const paginatedPromotions = filteredPromotions.slice((currentPageClamped - 1) * PAGE_SIZE, currentPageClamped * PAGE_SIZE);
  const pageNumbers = getPageNumbers(currentPageClamped, totalPages);

  const activeCount = promotions.filter((promotion) => promotion.isActive).length;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (form.code.trim().length === 0) {
      toast.warning('Vui lòng điền mã giảm giá.');
      return;
    }

    setSubmitting(true);

    try {
      const payload = {
        ...form,
        validUntil: `${form.validUntil}T23:59:59`,
      };

      if (editingPromotion) {
        await adminService.updatePromotion(editingPromotion.id, payload);
        toast.success('Cập nhật mã khuyến mãi thành công');
      } else {
        await adminService.createPromotion(payload);
        toast.success('Tạo mã khuyến mãi mới thành công');
      }

      await loadPromotions();
      setEditingPromotion(null);
      setForm(initialForm);
    } catch (error: any) {
      toast.error('Không thể lưu khuyến mãi: ' + (error?.message || 'Có lỗi xảy ra'));
    } finally {
      setSubmitting(false);
    }
  };

  const handleDelete = (promotion: AdminPromotion) => {
    setPromotionToDelete(promotion);
    setDeleteConfirmOpen(true);
  };

  const handleConfirmDelete = async () => {
    if (!promotionToDelete) return;
    try {
      await adminService.deletePromotion(promotionToDelete.id);
      await loadPromotions();
      toast.success('Đã xóa mã khuyến mãi thành công');
    } catch (error: any) {
      toast.error('Không thể xóa khuyến mãi: ' + (error?.message || 'Có lỗi xảy ra'));
    } finally {
      setPromotionToDelete(null);
    }
  };

  const startEdit = (promotion: AdminPromotion) => {
    setEditingPromotion(promotion);
    setForm({
      code: promotion.code,
      discountPercent: promotion.discountPercent,
      maxDiscountAmount: promotion.maxDiscountAmount,
      validUntil: promotion.validUntil,
      usageLimit: promotion.usageLimit,
    });
  };

  const exportPromotions = () => {
    downloadCsv('promotions.csv', filteredPromotions, [
      { key: 'code', header: 'Mã giảm giá' },
      { key: 'discountPercent', header: 'Tỉ lệ giảm (%)' },
      { key: 'maxDiscountAmount', header: 'Giảm tối đa' },
      { key: 'validUntil', header: 'Ngày hết hạn' },
      { key: 'usageLimit', header: 'Giới hạn dùng' },
      { key: 'usedCount', header: 'Đã dùng' },
    ]);
    toast.success('Xuất file CSV khuyến mãi thành công');
  };

  if (loading && promotions.length === 0) {
    return (
      <div className="flex items-center justify-center h-full min-h-[50vh]">
        <div className="animate-spin rounded-full h-10 w-10 border-b-2 border-primary"></div>
      </div>
    );
  }

  return (
    <div className="px-4 lg:px-6 space-y-6">
      <div className="flex justify-between items-center gap-4 flex-wrap">
        <div>
          <span className="text-xs font-bold uppercase tracking-wider text-primary">Catalog quản trị</span>
          <h1 className="text-3xl font-extrabold tracking-tight mt-1">Khuyến mãi & Vouchers</h1>
          <p className="text-muted-foreground text-sm mt-2">
            Phát hành phiếu mua hàng (coupons), thiết lập % giảm giá và giới hạn sử dụng voucher.
          </p>
        </div>
        <Button variant="outline" size="sm" onClick={exportPromotions} className="gap-1.5 cursor-pointer">
          <Download className="h-4 w-4" /> Xuất CSV
        </Button>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <MetricCard
          title="Tổng số voucher"
          value={`${promotions.length} mã`}
          description="Vouchers đã phát hành trên hệ thống"
          icon={<Ticket className="h-4 w-4" />}
          theme="muted"
        />

        <MetricCard
          title="Mã còn hiệu lực"
          value={`${activeCount} mã`}
          description="Chưa hết hạn và còn lượt sử dụng"
          icon={<Layers className="h-4 w-4" />}
          theme="emerald"
        />

        <MetricCard
          title="Vouchers khớp tìm kiếm"
          value={`${filteredPromotions.length} mã`}
          description="Theo bộ lọc tìm kiếm hiện tại"
          icon={<BadgeAlert className="h-4 w-4" />}
          theme="sky"
        />
      </div>

      {/* CRUD Form */}
      <Card>
        <CardHeader className="flex flex-row items-center justify-between">
          <div>
            <CardTitle className="text-lg font-bold">
              {editingPromotion ? 'Cập nhật mã khuyến mãi' : 'Tạo mới mã khuyến mãi'}
            </CardTitle>
            <CardDescription>Thiết lập tỉ lệ chiết khấu, số tiền tối đa được trừ và số lượt cho phép áp dụng.</CardDescription>
          </div>
          {editingPromotion && (
            <Button
              variant="outline"
              size="sm"
              onClick={() => {
                setEditingPromotion(null);
                setForm(initialForm);
              }}
              className="cursor-pointer"
            >
              Hủy sửa
            </Button>
          )}
        </CardHeader>
        <CardContent>
          <form onSubmit={handleSubmit} className="space-y-4">
            <div className="grid grid-cols-1 md:grid-cols-5 gap-4">
              <div className="grid gap-2">
                <Label htmlFor="promo-code">Mã coupon</Label>
                <Input
                  id="promo-code"
                  value={form.code}
                  onChange={(e) => setForm((c) => ({ ...c, code: e.target.value.toUpperCase() }))}
                  placeholder="Ví dụ: SUMMER50, TRIP100"
                  required
                />
              </div>

              <div className="grid gap-2">
                <Label htmlFor="promo-pct">Tỉ lệ giảm (%)</Label>
                <Input
                  id="promo-pct"
                  type="number"
                  min={0}
                  max={100}
                  value={form.discountPercent}
                  onChange={(e) => setForm((c) => ({ ...c, discountPercent: Number(e.target.value) }))}
                  required
                />
              </div>

              <div className="grid gap-2">
                <Label htmlFor="promo-max">Giảm tối đa (VND)</Label>
                <Input
                  id="promo-max"
                  type="number"
                  min={0}
                  value={form.maxDiscountAmount}
                  onChange={(e) => setForm((c) => ({ ...c, maxDiscountAmount: Number(e.target.value) }))}
                  required
                />
              </div>

              <div className="grid gap-2">
                <Label htmlFor="promo-valid">Có hiệu lực đến</Label>
                <Input
                  id="promo-valid"
                  type="date"
                  value={form.validUntil}
                  onChange={(e) => setForm((c) => ({ ...c, validUntil: e.target.value }))}
                  required
                />
              </div>

              <div className="grid gap-2">
                <Label htmlFor="promo-limit">Giới hạn sử dụng</Label>
                <Input
                  id="promo-limit"
                  type="number"
                  min={1}
                  value={form.usageLimit}
                  onChange={(e) => setForm((c) => ({ ...c, usageLimit: Number(e.target.value) }))}
                  required
                />
              </div>
            </div>

            <div className="flex justify-end gap-2 pt-2 border-t">
              <Button type="submit" disabled={submitting} className="cursor-pointer">
                {submitting ? 'Đang lưu...' : editingPromotion ? 'Lưu thay đổi' : 'Tạo voucher'}
              </Button>
            </div>
          </form>
        </CardContent>
      </Card>

      {/* Promotions Table */}
      <Card>
        <CardContent className="p-0">
          <div className="overflow-x-auto">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead className="pl-6">Mã giảm giá (Code)</TableHead>
                  <TableHead>Chính sách ưu đãi</TableHead>
                  <TableHead>Hạn sử dụng</TableHead>
                  <TableHead>Lượt đã dùng</TableHead>
                  <TableHead>Trạng thái</TableHead>
                  <TableHead className="pr-6 text-right">Thao tác</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {filteredPromotions.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={6} className="text-center py-12 text-sm text-muted-foreground">
                      Không có mã khuyến mãi nào phù hợp với tìm kiếm.
                    </TableCell>
                  </TableRow>
                ) : (
                  paginatedPromotions.map((p) => (
                    <TableRow key={p.id} className="hover:bg-muted/30">
                      <TableCell className="pl-6 py-4 font-black text-xs text-primary tracking-wide">
                        {p.code}
                      </TableCell>
                      <TableCell className="text-xs font-semibold">
                        Giảm {p.discountPercent}% (Tối đa {p.maxDiscountAmount.toLocaleString('vi-VN')} VND)
                      </TableCell>
                      <TableCell className="text-xs text-muted-foreground">
                        {p.validUntil}
                      </TableCell>
                      <TableCell className="text-xs font-semibold">
                        {p.usedCount} / {p.usageLimit} lượt
                      </TableCell>
                      <TableCell>
                        {p.isActive ? (
                          <Badge variant="secondary" className="bg-emerald-500/10 text-emerald-600 dark:text-emerald-400">
                            Đang hoạt động
                          </Badge>
                        ) : p.usedCount >= p.usageLimit ? (
                          <Badge variant="outline" className="text-muted-foreground border-slate-300">
                            Hết lượt
                          </Badge>
                        ) : (
                          <Badge variant="destructive" className="bg-destructive/10 text-destructive border-none">
                            Hết hạn
                          </Badge>
                        )}
                      </TableCell>
                      <TableCell className="pr-6 text-right">
                        <div className="flex justify-end gap-1.5">
                          <Button
                            size="sm"
                            variant="ghost"
                            onClick={() => startEdit(p)}
                            className="h-8 w-8 p-0 cursor-pointer"
                          >
                            <Edit2 className="h-3.5 w-3.5 text-muted-foreground" />
                          </Button>
                          <Button
                            size="sm"
                            variant="ghost"
                            onClick={() => handleDelete(p)}
                            className="h-8 w-8 p-0 text-destructive hover:bg-destructive/10 cursor-pointer"
                          >
                            <Trash2 className="h-3.5 w-3.5" />
                          </Button>
                        </div>
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

      <ConfirmDialog
        isOpen={deleteConfirmOpen}
        title="Xóa mã khuyến mãi?"
        description={promotionToDelete ? `Bạn có chắc muốn xóa mã khuyến mãi ${promotionToDelete.code}?` : ""}
        onConfirm={handleConfirmDelete}
        onClose={() => setDeleteConfirmOpen(false)}
      />
    </div>
  );
}
