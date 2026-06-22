"use client";

import { useEffect, useState } from 'react';
import { adminService, type AdminReportSummary } from '@/services/adminService';
import { downloadCsv } from '@/utils/adminActions';
import { toast } from 'sonner';
import {
  Card,
  CardContent,
  CardHeader,
  CardTitle,
  CardDescription,
} from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { MetricCard } from "@/components/ui/metric-card";
import { Progress } from "@/components/ui/progress";
import {
  TrendingUp,
  Award,
  Users,
  Briefcase,
  Calendar,
  Download,
  DollarSign,
  PieChart,
} from 'lucide-react';

const compact = (value: number) =>
  new Intl.NumberFormat('vi-VN', { notation: 'compact', maximumFractionDigits: 1 }).format(value);

export default function ReportsAdminPage() {
  const [report, setReport] = useState<AdminReportSummary | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchData = async () => {
      try {
        setLoading(true);
        const data = await adminService.getReportSummary();
        setReport(data);
      } catch (error: any) {
        toast.error('Không thể tải báo cáo: ' + (error?.message || 'Lỗi kết nối'));
      } finally {
        setLoading(false);
      }
    };

    fetchData();
  }, []);

  if (loading && !report) {
    return (
      <div className="flex items-center justify-center h-full min-h-[50vh]">
        <div className="animate-spin rounded-full h-10 w-10 border-b-2 border-primary"></div>
      </div>
    );
  }

  if (!report) return null;

  const maxTopDestination = Math.max(...report.topDestinations.map((item) => item.value), 1);
  const maxPaymentStatus = Math.max(...report.revenueByPaymentStatus.map((item) => item.value), 1);

  return (
    <div className="px-4 lg:px-6 space-y-6">
      <div className="flex justify-between items-center gap-4 flex-wrap">
        <div>
          <span className="text-xs font-bold uppercase tracking-wider text-primary">Trung tâm báo cáo</span>
          <h1 className="text-3xl font-extrabold tracking-tight mt-1">Báo cáo doanh thu & Hiệu quả kinh doanh</h1>
          <p className="text-muted-foreground text-sm mt-2">
            Tổng quan tình hình tài chính, hiệu suất các điểm đến và phân tích trạng thái thanh toán của khách hàng.
          </p>
        </div>
        <Button variant="outline" size="sm" onClick={() => downloadCsv('report-summary-destinations.csv', report.topDestinations, [{ key: 'label', header: 'Điểm đến' }, { key: 'value', header: 'Doanh thu' }])} className="gap-1.5 cursor-pointer">
          <Download className="h-4 w-4" /> Xuất Breakdown
        </Button>
      </div>

      {/* Overview Cards */}
      <div className="grid grid-cols-2 md:grid-cols-5 gap-4">
        <MetricCard
          title="Doanh thu"
          value={`${compact(report.totalRevenue)}đ`}
          description="Tổng giá trị giao dịch phát sinh"
          icon={<DollarSign className="h-4 w-4" />}
          theme="emerald"
        />

        <MetricCard
          title="Lợi nhuận ròng"
          value={`${compact(report.totalProfit)}đ`}
          description="Doanh thu affiliate/commission"
          icon={<TrendingUp className="h-4 w-4" />}
          theme="sky"
        />

        <MetricCard
          title="Người dùng"
          value={report.totalUsers.toLocaleString()}
          description="Tổng thành viên đã đăng ký"
          icon={<Users className="h-4 w-4" />}
          theme="muted"
        />

        <MetricCard
          title="Booking đặt chỗ"
          value={report.totalBookings.toLocaleString()}
          description="Tổng lượt mua vé/đặt dịch vụ"
          icon={<Briefcase className="h-4 w-4" />}
          theme="muted"
        />

        <MetricCard
          className="col-span-2 md:col-span-1"
          title="Lịch xe khách"
          value={report.totalSchedules.toLocaleString()}
          description="Chuyến xe đang vận hành"
          icon={<Calendar className="h-4 w-4" />}
          theme="muted"
        />
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Top destinations breakdown */}
        <Card>
          <CardHeader>
            <CardTitle className="text-sm font-bold flex items-center gap-1.5">
              <Award className="h-4 w-4 text-primary" /> Top điểm đến theo doanh thu booking
            </CardTitle>
            <CardDescription>Những điểm đến mang lại giá trị cao nhất trong tháng này.</CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            {report.topDestinations.map((item) => (
              <div key={item.label} className="space-y-2">
                <div className="flex items-center justify-between gap-4 text-xs font-semibold">
                  <span>{item.label}</span>
                  <span className="font-bold">{item.value.toLocaleString()}đ</span>
                </div>
                <Progress value={Math.max(10, (item.value / maxTopDestination) * 100)} className="h-2" />
              </div>
            ))}
          </CardContent>
        </Card>

        {/* Payment status split */}
        <Card>
          <CardHeader>
            <CardTitle className="text-sm font-bold flex items-center gap-1.5">
              <PieChart className="h-4 w-4 text-primary" /> Doanh thu theo trạng thái thanh toán
            </CardTitle>
            <CardDescription>Biểu đồ cơ cấu doanh thu phân chia theo hình thức quyết toán.</CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            {report.revenueByPaymentStatus.map((item) => (
              <div key={item.label} className="p-3 bg-muted/20 border rounded-lg space-y-2">
                <div className="flex justify-between items-center text-xs font-semibold">
                  <div>
                    <span className="font-bold block">{item.label}</span>
                    <span className="text-[10px] text-muted-foreground font-medium block">Doanh số quyết toán</span>
                  </div>
                  <span className="font-bold text-sm">{item.value.toLocaleString()}đ</span>
                </div>
                <Progress value={Math.max(10, (item.value / maxPaymentStatus) * 100)} className="h-1.5" />
              </div>
            ))}
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
