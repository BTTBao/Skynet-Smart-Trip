"use client";

import { useEffect, useMemo, useState } from 'react';
import { useAdminSearch } from '@/contexts/AdminSearchContext';
import { adminService, type AdminPaymentHistoryItem } from '@/services/adminService';
import { downloadCsv, getPageNumbers } from '@/utils/adminActions';
import { toast } from 'sonner';
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { MetricCard } from "@/components/ui/metric-card";
import { Badge } from "@/components/ui/badge";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Wallet, Download, ArrowUpRight, ArrowDownLeft, ChevronLeft, ChevronRight } from 'lucide-react';

export default function PaymentsAdminPage() {
  const { query } = useAdminSearch();
  const PAGE_SIZE = 10;
  const [payments, setPayments] = useState<AdminPaymentHistoryItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [currentPage, setCurrentPage] = useState(1);

  const loadPayments = async () => {
    try {
      const data = await adminService.getPayments();
      setPayments(data);
    } catch (error: any) {
      toast.error('Không thể tải lịch sử giao dịch: ' + (error?.message || 'Lỗi kết nối'));
    }
  };

  useEffect(() => {
    const fetchData = async () => {
      setLoading(true);
      await loadPayments();
      setLoading(false);
    };
    fetchData();
  }, []);

  const filteredPayments = useMemo(() => {
    const keyword = query.trim().toLowerCase();
    return payments.filter((item) =>
      keyword.length === 0 ||
      item.userName.toLowerCase().includes(keyword) ||
      item.userEmail.toLowerCase().includes(keyword) ||
      (item.transactionId && item.transactionId.toLowerCase().includes(keyword)) ||
      item.paymentMethod.toLowerCase().includes(keyword) ||
      item.description.toLowerCase().includes(keyword)
    );
  }, [payments, query]);

  useEffect(() => {
    setCurrentPage(1);
  }, [query]);

  const totalPages = Math.max(1, Math.ceil(filteredPayments.length / PAGE_SIZE));
  const currentPageClamped = Math.min(currentPage, totalPages);
  const paginatedPayments = filteredPayments.slice((currentPageClamped - 1) * PAGE_SIZE, currentPageClamped * PAGE_SIZE);
  const pageNumbers = getPageNumbers(currentPageClamped, totalPages);

  // Stats calculation
  const totalAmountInFlow = useMemo(() => {
    return payments.reduce((sum, item) => sum + (item.amount > 0 ? item.amount : 0), 0);
  }, [payments]);

  const totalAmountOutFlow = useMemo(() => {
    return payments.reduce((sum, item) => sum + (item.amount < 0 ? Math.abs(item.amount) : 0), 0);
  }, [payments]);

  const exportPayments = () => {
    downloadCsv('payments.csv', filteredPayments, [
      { key: 'paymentId', header: 'Mã ID' },
      { key: 'userName', header: 'Tên người dùng' },
      { key: 'userEmail', header: 'Email' },
      { key: 'amount', header: 'Số tiền (VND)' },
      { key: 'paymentMethod', header: 'Phương thức' },
      { key: 'status', header: 'Trạng thái' },
      { key: 'transactionId', header: 'Mã giao dịch' },
      { key: 'description', header: 'Mô tả' },
      { key: 'createdAt', header: 'Thời gian tạo' },
    ]);
    toast.success('Xuất file CSV giao dịch thành công');
  };

  if (loading && payments.length === 0) {
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
          <span className="text-xs font-bold uppercase tracking-wider text-primary">Quản trị ví</span>
          <h1 className="text-3xl font-extrabold tracking-tight mt-1">Lịch sử giao dịch & Ví</h1>
          <p className="text-muted-foreground text-sm mt-2">
            Theo dõi tất cả hoạt động nạp tiền, rút tiền và thanh toán của khách hàng trên hệ thống.
          </p>
        </div>
        <Button variant="outline" size="sm" onClick={exportPayments} className="gap-1.5 cursor-pointer">
          <Download className="h-4 w-4" /> Xuất CSV
        </Button>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <MetricCard
          title="Tổng tiền nạp"
          value={`${totalAmountInFlow.toLocaleString('vi-VN')} đ`}
          description="Dòng tiền nạp vào hệ thống"
          icon={<ArrowUpRight className="h-4 w-4 text-emerald-500" />}
          theme="emerald"
        />

        <MetricCard
          title="Tổng tiền rút"
          value={`${totalAmountOutFlow.toLocaleString('vi-VN')} đ`}
          description="Dòng tiền rút ra/payouts"
          icon={<ArrowDownLeft className="h-4 w-4 text-rose-500" />}
          theme="rose"
        />

        <MetricCard
          title="Tổng số giao dịch"
          value={`${payments.length} lượt`}
          description="Tất cả các loại giao dịch ví"
          icon={<Wallet className="h-4 w-4" />}
          theme="sky"
        />
      </div>

      {/* Table */}
      <Card>
        <CardContent className="p-0">
          <div className="overflow-x-auto">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead className="pl-6">Giao dịch</TableHead>
                  <TableHead>Khách hàng</TableHead>
                  <TableHead>Số tiền</TableHead>
                  <TableHead>Phương thức</TableHead>
                  <TableHead>Mô tả</TableHead>
                  <TableHead>Mã giao dịch</TableHead>
                  <TableHead>Trạng thái</TableHead>
                  <TableHead className="pr-6">Thời gian</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {filteredPayments.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={8} className="text-center py-12 text-sm text-muted-foreground">
                      Không tìm thấy giao dịch nào phù hợp.
                    </TableCell>
                  </TableRow>
                ) : (
                  paginatedPayments.map((p) => {
                    const isPositive = p.amount > 0;
                    return (
                      <TableRow key={p.paymentId} className="hover:bg-muted/30">
                        <TableCell className="pl-6 py-4 font-black text-xs text-muted-foreground">
                          #{p.paymentId}
                        </TableCell>
                        <TableCell>
                          <div className="flex flex-col">
                            <span className="font-semibold text-sm">{p.userName}</span>
                            <span className="text-xs text-muted-foreground">{p.userEmail}</span>
                          </div>
                        </TableCell>
                        <TableCell className={`font-bold text-sm ${isPositive ? 'text-emerald-600' : 'text-rose-600'}`}>
                          {isPositive ? '+' : ''}{p.amount.toLocaleString('vi-VN')} đ
                        </TableCell>
                        <TableCell className="text-xs font-semibold uppercase">{p.paymentMethod}</TableCell>
                        <TableCell className="text-xs max-w-[200px] truncate" title={p.description}>
                          {p.description}
                        </TableCell>
                        <TableCell className="text-xs font-mono select-all">
                          {p.transactionId || '-'}
                        </TableCell>
                        <TableCell>
                          {p.status === 'Paid' || p.status === 'success' || p.status === 'paid' ? (
                            <Badge variant="secondary" className="bg-emerald-500/10 text-emerald-600 border-none">
                              Thành công
                            </Badge>
                          ) : p.status === 'Pending' || p.status === 'pending' ? (
                            <Badge variant="outline" className="text-amber-600 border-amber-300 bg-amber-50">
                              Chờ xử lý
                            </Badge>
                          ) : (
                            <Badge variant="destructive" className="bg-destructive/10 text-destructive border-none">
                              {p.status || 'Thất bại'}
                            </Badge>
                          )}
                        </TableCell>
                        <TableCell className="pr-6 text-xs text-muted-foreground">
                          {p.createdAt ? new Date(p.createdAt).toLocaleString('vi-VN') : '-'}
                        </TableCell>
                      </TableRow>
                    );
                  })
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
    </div>
  );
}
