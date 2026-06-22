import { useEffect, useMemo, useState } from 'react';
import { useAdminSearch, useToast } from '../../context';
import {
  adminService,
  type AdminPromotion,
  type AdminPromotionRequest,
} from '../../services/adminService';
import { downloadCsv } from '../../utils/adminActions';
import { getErrorMessage } from '../../utils/http';

const initialForm: AdminPromotionRequest = {
  code: '',
  discountPercent: 10,
  maxDiscountAmount: 100000,
  validUntil: new Date().toISOString().slice(0, 10),
  usageLimit: 100,
};

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

function StatCard({ label, value, icon }: { label: string; value: string | number; icon: string }) {
  return (
    <div className="bg-white rounded-2xl p-6 shadow-sm border border-slate-100 flex flex-col gap-4">
      <div className="flex items-center justify-between">
        <span className="material-symbols-outlined rounded-xl bg-primary/10 p-2.5 text-primary text-xl" style={{ fontVariationSettings: "'FILL' 1" }}>{icon}</span>
      </div>
      <div>
        <p className="text-xs font-semibold text-slate-500 uppercase tracking-wider">{label}</p>
        <h2 className="mt-1 text-3xl font-black text-on-surface">{value}</h2>
      </div>
    </div>
  );
}

export default function PromotionsAdminPage() {
  const { query } = useAdminSearch();
  const { showToast } = useToast();
  const [promotions, setPromotions] = useState<AdminPromotion[]>([]);
  const [loading, setLoading] = useState(true);
  const [editingPromotion, setEditingPromotion] = useState<AdminPromotion | null>(null);
  const [form, setForm] = useState<AdminPromotionRequest>(initialForm);
  const [submitting, setSubmitting] = useState(false);
  const [showGuide, setShowGuide] = useState(false);

  const loadPromotions = async () => {
    const data = await adminService.getPromotions();
    setPromotions(data);
  };

  useEffect(() => {
    const fetchData = async () => {
      try {
        await loadPromotions();
      } catch (error) {
        showToast({ type: 'error', title: 'Không thể tải khuyến mãi', message: getErrorMessage(error) });
      } finally {
        setLoading(false);
      }
    };

    fetchData();
  }, []);

  const filteredPromotions = useMemo(() => {
    const keyword = query.trim().toLowerCase();
    return promotions.filter((promotion) =>
      keyword.length === 0 || promotion.code.toLowerCase().includes(keyword)
    );
  }, [promotions, query]);

  const activeCount = promotions.filter((promotion) => promotion.isActive).length;

  const handleSubmit = async (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    setSubmitting(true);

    try {
      const payload = {
        ...form,
        validUntil: `${form.validUntil}T23:59:59`,
      };

      if (editingPromotion) {
        await adminService.updatePromotion(editingPromotion.id, payload);
      } else {
        await adminService.createPromotion(payload);
      }

      await loadPromotions();
      setEditingPromotion(null);
      setForm(initialForm);
      showToast({ type: 'success', title: editingPromotion ? 'Đã cập nhật khuyến mãi' : 'Đã tạo khuyến mãi' });
    } catch (error) {
      showToast({ type: 'error', title: 'Không thể lưu khuyến mãi', message: getErrorMessage(error) });
    } finally {
      setSubmitting(false);
    }
  };

  const handleDelete = async (promotion: AdminPromotion) => {
    try {
      await adminService.deletePromotion(promotion.id);
      await loadPromotions();
      showToast({ type: 'success', title: 'Đã xóa khuyến mãi', message: promotion.code });
    } catch (error) {
      showToast({ type: 'error', title: 'Không thể xóa khuyến mãi', message: getErrorMessage(error) });
    }
  };

  if (loading) {
    return <div className="flex items-center justify-center h-full min-h-[50vh]"><div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary"></div></div>;
  }

  return (
    <div className="space-y-8">
      {/* Header */}
      <div className="flex flex-col xl:flex-row xl:items-start justify-between gap-4">
        <div>
          <p className="text-xs font-bold uppercase tracking-widest text-primary mb-1">Catalog quản trị</p>
          <h1 className="text-3xl font-black text-on-surface">Khuyến mãi</h1>
          <p className="text-sm text-slate-500 mt-1 max-w-xl">
            Quản lý mã giảm giá, cấu hình phần trăm giảm, thời hạn sử dụng và số lượng lượt dùng tối đa.
          </p>
        </div>
        <div className="flex flex-wrap items-center gap-2">
          <button
            onClick={() => setShowGuide(true)}
            className="rounded-full bg-amber-500 hover:bg-amber-600 px-5 py-2.5 text-sm font-bold text-white transition-all shadow-sm"
          >
            💡 Hướng dẫn
          </button>
          <button
            onClick={() => downloadCsv('promotions.csv', filteredPromotions, [
              { key: 'code', header: 'Mã giảm giá' },
              { key: 'discountPercent', header: 'Phần trăm giảm' },
              { key: 'maxDiscountAmount', header: 'Giảm tối đa' },
              { key: 'validUntil', header: 'Hạn dùng' },
              { key: 'usageLimit', header: 'Giới hạn dùng' },
              { key: 'usedCount', header: 'Đã dùng' },
            ])}
            className="rounded-full bg-slate-100 text-slate-700 px-5 py-2.5 text-sm font-bold hover:bg-slate-200 transition"
          >
            Xuất CSV
          </button>
        </div>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
        <StatCard label="Tổng mã" value={promotions.length} icon="local_offer" />
        <StatCard label="Mã còn hiệu lực" value={activeCount} icon="check_circle" />
        <StatCard label="Kết quả lọc" value={filteredPromotions.length} icon="filter_list" />
      </div>

      {/* Form */}
      <form onSubmit={handleSubmit} className="bg-white rounded-2xl p-6 shadow-sm border border-slate-100">
        <div className="flex items-center justify-between gap-4 mb-5">
          <div>
            <h2 className="text-lg font-black text-on-surface">{editingPromotion ? 'Cập nhật mã khuyến mãi' : 'Tạo mã khuyến mãi mới'}</h2>
            <p className="text-sm text-slate-500 mt-0.5">Thiết lập các điều kiện áp dụng mã giảm giá.</p>
          </div>
          {editingPromotion ? (
            <button
              type="button"
              onClick={() => { setEditingPromotion(null); setForm(initialForm); }}
              className="rounded-full bg-slate-100 px-4 py-2 text-sm font-semibold text-slate-600 hover:bg-slate-200 transition"
            >
              Hủy sửa
            </button>
          ) : null}
        </div>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
          <Field label="Mã giảm giá" required>
            <input
              value={form.code}
              onChange={(e) => setForm((current) => ({ ...current, code: e.target.value.toUpperCase() }))}
              placeholder="Ví dụ: SUMMER20"
              className={inputCls}
              required
            />
          </Field>
          <Field label="Phần trăm giảm (%)" required>
            <input
              value={form.discountPercent}
              onChange={(e) => setForm((current) => ({ ...current, discountPercent: Number(e.target.value) }))}
              type="number"
              min={0}
              max={100}
              placeholder="0 – 100%"
              className={inputCls}
              required
            />
          </Field>
          <Field label="Số tiền giảm tối đa (đ)" required>
            <input
              value={form.maxDiscountAmount}
              onChange={(e) => setForm((current) => ({ ...current, maxDiscountAmount: Number(e.target.value) }))}
              type="number"
              min={0}
              placeholder="Ví dụ: 100000"
              className={inputCls}
              required
            />
          </Field>
          <Field label="Hạn sử dụng" required>
            <input
              value={form.validUntil}
              onChange={(e) => setForm((current) => ({ ...current, validUntil: e.target.value }))}
              type="date"
              className={inputCls}
              required
            />
          </Field>
          <Field label="Giới hạn lượt dùng" required>
            <input
              value={form.usageLimit}
              onChange={(e) => setForm((current) => ({ ...current, usageLimit: Number(e.target.value) }))}
              type="number"
              min={1}
              placeholder="Số lượt tối đa"
              className={inputCls}
              required
            />
          </Field>
        </div>
        <div className="mt-5">
          <button type="submit" disabled={submitting} className="px-6 py-2.5 bg-primary text-white text-sm font-bold rounded-full disabled:opacity-50 hover:brightness-110 transition">
            {submitting ? 'Đang lưu...' : editingPromotion ? 'Lưu thay đổi' : 'Tạo khuyến mãi'}
          </button>
        </div>
      </form>

      {/* Table */}
      <div className="bg-white rounded-2xl border border-slate-100 overflow-hidden shadow-sm">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead className="bg-slate-50 border-b border-slate-100">
              <tr>
                <th className="px-6 py-4 text-xs font-bold uppercase tracking-wider text-slate-500">Mã code</th>
                <th className="px-6 py-4 text-xs font-bold uppercase tracking-wider text-slate-500">Ưu đãi</th>
                <th className="px-6 py-4 text-xs font-bold uppercase tracking-wider text-slate-500">Hạn dùng</th>
                <th className="px-6 py-4 text-xs font-bold uppercase tracking-wider text-slate-500">Đã dùng</th>
                <th className="px-6 py-4 text-xs font-bold uppercase tracking-wider text-slate-500">Trạng thái</th>
                <th className="px-6 py-4 text-right text-xs font-bold uppercase tracking-wider text-slate-500">Hành động</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-50">
              {filteredPromotions.map((promotion) => (
                <tr key={promotion.id} className="hover:bg-slate-50/70 transition-colors">
                  <td className="px-6 py-4">
                    <span className="font-black text-on-surface tracking-widest bg-slate-100 px-3 py-1 rounded-lg text-sm">{promotion.code}</span>
                  </td>
                  <td className="px-6 py-4">
                    <p className="text-sm font-semibold text-on-surface">{promotion.discountPercent}% giảm</p>
                    <p className="text-xs text-slate-400 mt-0.5">Tối đa {promotion.maxDiscountAmount.toLocaleString()}đ</p>
                  </td>
                  <td className="px-6 py-4 text-sm text-slate-500">{promotion.validUntil}</td>
                  <td className="px-6 py-4">
                    <div className="flex items-center gap-2">
                      <div className="flex-1 max-w-[80px] bg-slate-100 rounded-full h-1.5 overflow-hidden">
                        <div
                          className="h-full bg-primary rounded-full"
                          style={{ width: `${Math.min(100, (promotion.usedCount / promotion.usageLimit) * 100)}%` }}
                        />
                      </div>
                      <span className="text-xs text-slate-500 tabular-nums">{promotion.usedCount}/{promotion.usageLimit}</span>
                    </div>
                  </td>
                  <td className="px-6 py-4">
                    <span className={`rounded-full px-3 py-1 text-xs font-semibold ${
                      promotion.isActive
                        ? 'bg-emerald-50 text-emerald-700'
                        : promotion.usedCount >= promotion.usageLimit
                          ? 'bg-slate-100 text-slate-500'
                          : 'bg-red-50 text-red-600'
                    }`}>
                      {promotion.isActive
                        ? 'Đang chạy'
                        : promotion.usedCount >= promotion.usageLimit
                          ? 'Hết lượt'
                          : 'Hết hạn'}
                    </span>
                  </td>
                  <td className="px-6 py-4 text-right">
                    <div className="flex justify-end gap-2">
                      <button
                        onClick={() => {
                          setEditingPromotion(promotion);
                          setForm({
                            code: promotion.code,
                            discountPercent: promotion.discountPercent,
                            maxDiscountAmount: promotion.maxDiscountAmount,
                            validUntil: promotion.validUntil,
                            usageLimit: promotion.usageLimit,
                          });
                        }}
                        className="rounded-full bg-slate-100 px-3 py-1.5 text-xs font-semibold text-slate-700 hover:bg-slate-200 transition"
                      >
                        Sửa
                      </button>
                      <button
                        onClick={() => handleDelete(promotion)}
                        className="rounded-full bg-red-50 px-3 py-1.5 text-xs font-semibold text-red-600 hover:bg-red-100 transition"
                      >
                        Xóa
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
        {filteredPromotions.length === 0 && (
          <div className="py-12 text-center">
            <span className="material-symbols-outlined text-4xl text-slate-300">local_offer</span>
            <p className="mt-3 text-slate-500 font-medium">Chưa có mã khuyến mãi nào</p>
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
                <h3 className="mt-1 text-xl font-black text-slate-900">Quản lý Khuyến mãi</h3>
              </div>
              <button type="button" onClick={() => setShowGuide(false)} className="rounded-full bg-slate-100 hover:bg-slate-200 px-4 py-2 text-xs font-bold text-slate-900 transition-colors">Đóng</button>
            </div>
            <div className="mt-6 space-y-5 text-sm text-slate-600 leading-relaxed max-h-[55vh] overflow-y-auto pr-1">
              <div className="rounded-2xl bg-amber-50 p-5 border border-amber-100">
                <h4 className="font-bold text-amber-800 text-base">📌 Chính sách chịu chi phí khuyến mãi</h4>
                <ul className="mt-3 list-disc list-inside space-y-2 text-amber-900 font-medium">
                  <li><strong>Nền tảng chịu 100%:</strong> Các coupon hệ thống phát hành sẽ do SmartTrip chịu 100% kinh phí.</li>
                  <li><strong>Doanh thu đối tác không đổi:</strong> Doanh thu chuyển cho Khách sạn/Nhà xe vẫn tính theo giá gốc trừ đi hoa hồng thỏa thuận ban đầu, không bị giảm trừ do khuyến mãi.</li>
                </ul>
              </div>
              <div>
                <h4 className="font-black text-slate-900 text-base">⚙️ Cách thiết lập mã giảm giá</h4>
                <ul className="mt-2 list-disc list-inside space-y-2">
                  <li><strong>Giới hạn lượt dùng:</strong> Khi số lượt sử dụng thực tế đạt giới hạn thiết lập, trạng thái mã tự động chuyển sang <em>"Hết lượt"</em>.</li>
                  <li><strong>Hạn dùng (Valid Until):</strong> Khi vượt quá ngày hết hạn thiết lập, trạng thái mã tự động chuyển sang <em>"Hết hạn"</em>.</li>
                </ul>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
