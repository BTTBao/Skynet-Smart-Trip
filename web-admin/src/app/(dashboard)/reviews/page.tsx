"use client";

import { useEffect, useMemo, useState } from 'react';
import { useAdminSearch } from '@/contexts/AdminSearchContext';
import { adminService, type AdminReview } from '@/services/adminService';
import { getPageNumbers } from '@/utils/adminActions';
import { toast } from 'sonner';
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { MetricCard } from "@/components/ui/metric-card";
import { Badge } from "@/components/ui/badge";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Star, Trash2, MessageSquare, ShieldAlert, ChevronLeft, ChevronRight } from 'lucide-react';
import { ConfirmDialog } from '@/components/ui/confirm-dialog';

export default function ReviewsAdminPage() {
  const { query } = useAdminSearch();
  const PAGE_SIZE = 8;
  const [reviews, setReviews] = useState<AdminReview[]>([]);
  const [loading, setLoading] = useState(true);
  const [currentPage, setCurrentPage] = useState(1);
  const [deleteConfirmOpen, setDeleteConfirmOpen] = useState(false);
  const [reviewToDelete, setReviewToDelete] = useState<AdminReview | null>(null);

  const loadReviews = async () => {
    try {
      const data = await adminService.getReviews();
      setReviews(data);
    } catch (error: any) {
      toast.error('Không thể tải danh sách đánh giá: ' + (error?.message || 'Lỗi kết nối'));
    }
  };

  useEffect(() => {
    const fetchData = async () => {
      setLoading(true);
      await loadReviews();
      setLoading(false);
    };
    fetchData();
  }, []);

  const filteredReviews = useMemo(() => {
    const keyword = query.trim().toLowerCase();
    return reviews.filter((item) =>
      keyword.length === 0 ||
      item.userName.toLowerCase().includes(keyword) ||
      item.userEmail.toLowerCase().includes(keyword) ||
      item.targetName.toLowerCase().includes(keyword) ||
      item.comment.toLowerCase().includes(keyword) ||
      item.targetType.toLowerCase().includes(keyword)
    );
  }, [reviews, query]);

  useEffect(() => {
    setCurrentPage(1);
  }, [query]);

  const totalPages = Math.max(1, Math.ceil(filteredReviews.length / PAGE_SIZE));
  const currentPageClamped = Math.min(currentPage, totalPages);
  const paginatedReviews = filteredReviews.slice((currentPageClamped - 1) * PAGE_SIZE, currentPageClamped * PAGE_SIZE);
  const pageNumbers = getPageNumbers(currentPageClamped, totalPages);

  // Stats calculation
  const averageRating = useMemo(() => {
    if (reviews.length === 0) return 0;
    const sum = reviews.reduce((s, item) => s + item.rating, 0);
    return Math.round((sum / reviews.length) * 10) / 10;
  }, [reviews]);

  const negativeReviewsCount = useMemo(() => {
    return reviews.filter((item) => item.rating <= 2).length;
  }, [reviews]);

  const handleDelete = (review: AdminReview) => {
    setReviewToDelete(review);
    setDeleteConfirmOpen(true);
  };

  const handleConfirmDelete = async () => {
    if (!reviewToDelete) return;
    try {
      await adminService.deleteReview(reviewToDelete.reviewId);
      await loadReviews();
      toast.success('Đã xóa/gỡ đánh giá thành công');
    } catch (error: any) {
      toast.error('Không thể xóa đánh giá: ' + (error?.message || 'Có lỗi xảy ra'));
    } finally {
      setReviewToDelete(null);
      setDeleteConfirmOpen(false);
    }
  };

  if (loading && reviews.length === 0) {
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
          <span className="text-xs font-bold uppercase tracking-wider text-primary">Kiểm duyệt nội dung</span>
          <h1 className="text-3xl font-extrabold tracking-tight mt-1">Quản lý đánh giá (Reviews)</h1>
          <p className="text-muted-foreground text-sm mt-2">
            Xem, kiểm duyệt và xóa các đánh giá không phù hợp của khách hàng dành cho Khách sạn, Nhà xe.
          </p>
        </div>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <MetricCard
          title="Tổng số đánh giá"
          value={`${reviews.length} đánh giá`}
          description="Đánh giá đã được viết"
          icon={<MessageSquare className="h-4 w-4" />}
          theme="muted"
        />

        <MetricCard
          title="Điểm đánh giá trung bình"
          value={`${averageRating} / 5`}
          description="Điểm trung bình toàn hệ thống"
          icon={<Star className="h-4 w-4 fill-amber-400 text-amber-400" />}
          theme="amber"
        />

        <MetricCard
          title="Đánh giá tiêu cực (1-2★)"
          value={`${negativeReviewsCount} đánh giá`}
          description="Cần chú ý kiểm duyệt hoặc khắc phục"
          icon={<ShieldAlert className="h-4 w-4 text-rose-500" />}
          theme="rose"
        />
      </div>

      {/* Table */}
      <Card>
        <CardContent className="p-0">
          <div className="overflow-x-auto">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead className="pl-6">ID</TableHead>
                  <TableHead>Khách hàng</TableHead>
                  <TableHead>Điểm số</TableHead>
                  <TableHead>Nội dung nhận xét</TableHead>
                  <TableHead>Đối tượng được đánh giá</TableHead>
                  <TableHead>Thời gian</TableHead>
                  <TableHead className="pr-6 text-right">Thao tác</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {filteredReviews.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={7} className="text-center py-12 text-sm text-muted-foreground">
                      Không tìm thấy đánh giá nào phù hợp.
                    </TableCell>
                  </TableRow>
                ) : (
                  paginatedReviews.map((r) => (
                    <TableRow key={r.reviewId} className="hover:bg-muted/30">
                      <TableCell className="pl-6 py-4 font-black text-xs text-muted-foreground">
                        #{r.reviewId}
                      </TableCell>
                      <TableCell>
                        <div className="flex flex-col">
                          <span className="font-semibold text-sm">{r.userName}</span>
                          <span className="text-xs text-muted-foreground">{r.userEmail}</span>
                        </div>
                      </TableCell>
                      <TableCell>
                        <div className="flex items-center gap-1 font-bold text-sm">
                          {r.rating} <Star className="h-3.5 w-3.5 fill-amber-400 text-amber-400" />
                        </div>
                      </TableCell>
                      <TableCell className="text-xs max-w-[280px] break-words">
                        {r.comment || <em className="text-muted-foreground">Không có nội dung</em>}
                      </TableCell>
                      <TableCell>
                        <div className="flex flex-col">
                          <span className="font-semibold text-xs text-primary uppercase">{r.targetType}</span>
                          <span className="text-xs text-muted-foreground">{r.targetName}</span>
                        </div>
                      </TableCell>
                      <TableCell className="text-xs text-muted-foreground">
                        {r.createdAt ? new Date(r.createdAt).toLocaleString('vi-VN') : '-'}
                      </TableCell>
                      <TableCell className="pr-6 text-right">
                        <Button
                          size="sm"
                          variant="ghost"
                          onClick={() => handleDelete(r)}
                          className="h-8 w-8 p-0 text-destructive hover:bg-destructive/10 cursor-pointer"
                          title="Xóa đánh giá này"
                        >
                          <Trash2 className="h-4 w-4" />
                        </Button>
                      </TableCell>
                    </TableRow>
                  ))
                )}
              </TableBody>
            </Table>
          </div>

          {/* Pagination */}
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
        title="Xóa đánh giá này?"
        description={reviewToDelete ? `Bạn có chắc muốn xóa đánh giá của người dùng ${reviewToDelete.userName}? Nhận xét này sẽ bị gỡ bỏ vĩnh viễn khỏi trang dịch vụ.` : ""}
        onConfirm={handleConfirmDelete}
        onClose={() => setDeleteConfirmOpen(false)}
      />
    </div>
  );
}
