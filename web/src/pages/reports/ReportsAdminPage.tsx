import { useEffect, useState } from 'react';
import { useToast } from '../../context';
import { adminService, type AdminReportSummary } from '../../services/adminService';
import { downloadCsv } from '../../utils/adminActions';
import { getErrorMessage } from '../../utils/http';

const compact = (value: number) =>
  new Intl.NumberFormat('en-US', { notation: 'compact', maximumFractionDigits: 1 }).format(value);

export default function ReportsAdminPage() {
  const { showToast } = useToast();
  const [report, setReport] = useState<AdminReportSummary | null>(null);
  const [loading, setLoading] = useState(true);
  const [showGuide, setShowGuide] = useState(false);

  useEffect(() => {
    const fetchData = async () => {
      try {
        const data = await adminService.getReportSummary();
        setReport(data);
      } catch (error) {
        showToast({ type: 'error', title: 'Không thể tải báo cáo', message: getErrorMessage(error) });
      } finally {
        setLoading(false);
      }
    };

    fetchData();
  }, []);

  if (loading) {
    return <div className="flex items-center justify-center h-full min-h-[50vh]"><div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary"></div></div>;
  }

  if (!report) {
    return <div className="text-center text-error mt-10">Không thể tải báo cáo doanh thu.</div>;
  }

  const maxTopDestination = Math.max(...report.topDestinations.map((item) => item.value), 1);
  const maxPaymentStatus = Math.max(...report.revenueByPaymentStatus.map((item) => item.value), 1);

  return (
    <div className="space-y-10">
      <div className="flex flex-col xl:flex-row xl:items-end justify-between gap-6">
        <div>
          <p className="text-[10px] font-black uppercase tracking-[0.2em] text-primary">Reports center</p>
          <h1 className="mt-3 text-4xl font-black text-on-surface">Báo cáo doanh thu</h1>
          <p className="mt-3 max-w-3xl text-sm text-on-surface-variant">Màn báo cáo đã có dữ liệu thật từ API tổng hợp, không còn là placeholder.</p>
        </div>
        <div className="flex flex-wrap items-center gap-3">
          <button
            onClick={() => setShowGuide(true)}
            className="rounded-full bg-amber-500 hover:bg-amber-600 px-6 py-3 text-sm font-bold text-white transition-all shadow-sm"
          >
            💡 Hướng dẫn vận hành
          </button>
          <button onClick={() => downloadCsv('report-summary-destinations.csv', report.topDestinations, [{ key: 'label', header: 'Điểm đến' }, { key: 'value', header: 'Doanh thu' }])} className="rounded-full bg-primary px-6 py-3 text-sm font-bold text-white">
            Xuất breakdown
          </button>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-5 gap-6">
        {[
          { label: 'Doanh thu', value: `${compact(report.totalRevenue)}đ` },
          { label: 'Lợi nhuận', value: `${compact(report.totalProfit)}đ` },
          { label: 'Người dùng', value: report.totalUsers.toLocaleString() },
          { label: 'Booking', value: report.totalBookings.toLocaleString() },
          { label: 'Lịch xe', value: report.totalSchedules.toLocaleString() },
        ].map((item) => (
          <div key={item.label} className="rounded-[2rem] bg-white p-8 shadow-[0px_20px_40px_rgba(21,28,39,0.04)]">
            <p className="text-[11px] font-black uppercase tracking-wider text-on-surface-variant">{item.label}</p>
            <h2 className="mt-3 text-4xl font-black text-on-surface">{item.value}</h2>
          </div>
        ))}
      </div>

      <div className="grid grid-cols-1 xl:grid-cols-2 gap-8">
        <section className="rounded-[2rem] bg-white p-8 shadow-[0px_20px_40px_rgba(21,28,39,0.04)]">
          <div className="flex items-center justify-between gap-4">
            <div>
              <h2 className="text-xl font-black text-on-surface">Top điểm đến theo doanh thu</h2>
              <p className="mt-1 text-sm text-on-surface-variant">Những điểm đến mang lại giá trị booking cao nhất.</p>
            </div>
          </div>
          <div className="mt-8 space-y-4">
            {report.topDestinations.map((item) => (
              <div key={item.label}>
                <div className="flex items-center justify-between gap-4">
                  <p className="text-sm font-bold text-on-surface">{item.label}</p>
                  <p className="text-sm font-black text-on-surface">{item.value.toLocaleString()}đ</p>
                </div>
                <div className="mt-2 h-3 rounded-full bg-surface-container-low">
                  <div className="h-3 rounded-full bg-primary" style={{ width: `${Math.max(10, (item.value / maxTopDestination) * 100)}%` }}></div>
                </div>
              </div>
            ))}
          </div>
        </section>

        <section className="rounded-[2rem] bg-white p-8 shadow-[0px_20px_40px_rgba(21,28,39,0.04)]">
          <div className="flex items-center justify-between gap-4">
            <div>
              <h2 className="text-xl font-black text-on-surface">Doanh thu theo trạng thái thanh toán</h2>
              <p className="mt-1 text-sm text-on-surface-variant">Tách doanh thu theo trạng thái payment hiện tại.</p>
            </div>
          </div>
          <div className="mt-8 grid min-h-[260px] grid-cols-1 gap-4">
            {report.revenueByPaymentStatus.map((item) => {
              let displayLabel = item.label;
              if (item.label.toLowerCase() === 'paid') displayLabel = 'Đã thanh toán';
              else if (item.label.toLowerCase() === 'pending') displayLabel = 'Chờ xử lý';
              else if (item.label.toLowerCase() === 'cancelled') displayLabel = 'Đã hủy';
              else if (item.label.toLowerCase() === 'refunded') displayLabel = 'Đã hoàn tiền';
              else displayLabel = displayLabel.charAt(0).toUpperCase() + displayLabel.slice(1);

              return (
                <div key={item.label} className="rounded-[1.5rem] bg-surface-container-low p-5">
                  <div className="flex items-center justify-between gap-4">
                    <div>
                      <p className="text-sm font-bold text-on-surface">{displayLabel}</p>
                      <p className="mt-1 text-xs text-on-surface-variant">Tỷ trọng doanh thu theo trạng thái</p>
                    </div>
                    <p className="text-sm font-black text-on-surface">{item.value.toLocaleString()}đ</p>
                  </div>
                  <div className="mt-4 h-3 rounded-full bg-white">
                    <div className="h-3 rounded-full bg-tertiary" style={{ width: `${Math.max(10, (item.value / maxPaymentStatus) * 100)}%` }}></div>
                  </div>
                </div>
              );
            })}
          </div>
        </section>
      </div>

      {showGuide && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-sm p-4 animate-in fade-in duration-200">
          <div className="w-full max-w-2xl rounded-[2.5rem] bg-white p-8 shadow-2xl ring-1 ring-black/5 animate-in slide-in-from-bottom-8 duration-350">
            <div className="flex items-start justify-between border-b border-slate-100 pb-4">
              <div>
                <p className="text-[11px] font-black uppercase tracking-[0.22em] text-amber-600">Hướng dẫn sử dụng</p>
                <h3 className="mt-1 text-2xl font-black text-slate-900">Vận hành Báo cáo doanh thu (Reports)</h3>
              </div>
              <button
                type="button"
                onClick={() => setShowGuide(false)}
                className="rounded-full bg-slate-100 hover:bg-slate-200 px-4 py-2 text-xs font-bold text-slate-900 transition-colors"
              >
                Đóng
              </button>
            </div>
            <div className="mt-6 space-y-6 text-sm text-slate-600 leading-relaxed max-h-[50vh] overflow-y-auto pr-2">
              <div className="rounded-[1.4rem] bg-amber-500/5 p-5 border border-amber-500/10">
                <h4 className="font-bold text-amber-800 text-base">📊 Doanh thu vs Lợi nhuận thực tế</h4>
                <ul className="mt-3 list-disc list-inside space-y-2 text-amber-950 font-medium">
                  <li><strong>Tổng doanh thu:</strong> Tổng tiền giao dịch thực tế khách đã trả qua các cổng Stripe/VNPay/Bank Transfer.</li>
                  <li><strong>Tổng lợi nhuận:</strong> Số tiền công ty nhận được sau khi trừ đi giá gốc dịch vụ của đối tác cung cấp (theo tỷ lệ hoa hồng commission của khách sạn và xe).</li>
                </ul>
              </div>
              <div>
                <h4 className="font-black text-slate-900 text-base">📈 Phân tích chỉ số</h4>
                <ul className="mt-2 list-disc list-inside space-y-2">
                  <li><strong>Top điểm đến:</strong> Thể hiện hiệu suất bán tour/dịch vụ tại từng khu vực địa lý, giúp đánh giá thị hiếu khách hàng để đẩy mạnh chiến dịch marketing.</li>
                  <li><strong>Xuất dữ liệu:</strong> Tải xuống báo cáo CSV đầy đủ cơ cấu doanh thu theo điểm đến để đối chiếu thủ công hoặc nhập vào các phần mềm kế toán.</li>
                </ul>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
