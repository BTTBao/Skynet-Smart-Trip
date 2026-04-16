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

export default function PromotionsAdminPage() {
  const { query } = useAdminSearch();
  const { showToast } = useToast();
  const [promotions, setPromotions] = useState<AdminPromotion[]>([]);
  const [loading, setLoading] = useState(true);
  const [editingPromotion, setEditingPromotion] = useState<AdminPromotion | null>(null);
  const [form, setForm] = useState<AdminPromotionRequest>(initialForm);
  const [submitting, setSubmitting] = useState(false);

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
        validUntil: `${form.validUntil}T00:00:00`,
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
    <div className="space-y-10">
      <div className="flex flex-col xl:flex-row xl:items-end justify-between gap-6">
        <div>
          <p className="text-[10px] font-black uppercase tracking-[0.2em] text-primary">Catalog quản trị</p>
          <h1 className="mt-3 text-4xl font-black text-on-surface">Khuyến mãi</h1>
          <p className="mt-3 max-w-3xl text-sm text-on-surface-variant">Màn khuyến mãi đã thay placeholder bằng CRUD coupon thật cho admin.</p>
        </div>
        <button onClick={() => downloadCsv('promotions.csv', filteredPromotions, [{ key: 'code', header: 'Code' }, { key: 'discountPercent', header: 'Discount %' }, { key: 'maxDiscountAmount', header: 'Max Discount' }, { key: 'validUntil', header: 'Valid Until' }, { key: 'usageLimit', header: 'Usage Limit' }, { key: 'usedCount', header: 'Used' }])} className="rounded-full bg-primary-container px-6 py-3 text-sm font-bold text-white">Xuất CSV</button>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div className="rounded-[2rem] bg-white p-8 shadow-[0px_20px_40px_rgba(21,28,39,0.04)]">
          <p className="text-[11px] font-black uppercase tracking-wider text-on-surface-variant">Tổng mã</p>
          <h2 className="mt-3 text-4xl font-black text-on-surface">{promotions.length}</h2>
        </div>
        <div className="rounded-[2rem] bg-white p-8 shadow-[0px_20px_40px_rgba(21,28,39,0.04)]">
          <p className="text-[11px] font-black uppercase tracking-wider text-on-surface-variant">Mã còn hiệu lực</p>
          <h2 className="mt-3 text-4xl font-black text-on-surface">{activeCount}</h2>
        </div>
        <div className="rounded-[2rem] bg-white p-8 shadow-[0px_20px_40px_rgba(21,28,39,0.04)]">
          <p className="text-[11px] font-black uppercase tracking-wider text-on-surface-variant">Kết quả lọc</p>
          <h2 className="mt-3 text-4xl font-black text-on-surface">{filteredPromotions.length}</h2>
        </div>
      </div>

      <form onSubmit={handleSubmit} className="rounded-[2rem] bg-white p-8 shadow-[0px_20px_40px_rgba(21,28,39,0.04)] ring-1 ring-outline-variant/10">
        <div className="flex items-center justify-between gap-4 mb-6">
          <div>
            <h2 className="text-xl font-black text-on-surface">{editingPromotion ? 'Cập nhật mã khuyến mãi' : 'Tạo mã khuyến mãi mới'}</h2>
            <p className="mt-1 text-sm text-on-surface-variant">Top bar đang hỗ trợ tìm nhanh theo code.</p>
          </div>
          {editingPromotion ? <button type="button" onClick={() => { setEditingPromotion(null); setForm(initialForm); }} className="rounded-full bg-surface-container-low px-5 py-2.5 text-sm font-bold text-on-surface">Hủy sửa</button> : null}
        </div>
        <div className="grid grid-cols-1 md:grid-cols-5 gap-4">
          <input value={form.code} onChange={(event) => setForm((current) => ({ ...current, code: event.target.value.toUpperCase() }))} placeholder="Mã giảm giá" className="rounded-2xl bg-surface-container-low px-5 py-3 outline-none" required />
          <input value={form.discountPercent} onChange={(event) => setForm((current) => ({ ...current, discountPercent: Number(event.target.value) }))} type="number" min={0} max={100} placeholder="% giảm" className="rounded-2xl bg-surface-container-low px-5 py-3 outline-none" required />
          <input value={form.maxDiscountAmount} onChange={(event) => setForm((current) => ({ ...current, maxDiscountAmount: Number(event.target.value) }))} type="number" min={0} placeholder="Giảm tối đa" className="rounded-2xl bg-surface-container-low px-5 py-3 outline-none" required />
          <input value={form.validUntil} onChange={(event) => setForm((current) => ({ ...current, validUntil: event.target.value }))} type="date" className="rounded-2xl bg-surface-container-low px-5 py-3 outline-none" required />
          <input value={form.usageLimit} onChange={(event) => setForm((current) => ({ ...current, usageLimit: Number(event.target.value) }))} type="number" min={1} placeholder="Giới hạn lượt dùng" className="rounded-2xl bg-surface-container-low px-5 py-3 outline-none" required />
        </div>
        <div className="mt-6">
          <button type="submit" disabled={submitting} className="rounded-full bg-primary-container px-8 py-3 text-sm font-bold text-white disabled:opacity-50">
            {submitting ? 'Đang lưu...' : editingPromotion ? 'Lưu thay đổi' : 'Tạo khuyến mãi'}
          </button>
        </div>
      </form>

      <div className="rounded-[2rem] bg-white shadow-[0px_20px_40px_rgba(21,28,39,0.04)] overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-surface-container-low/50">
                <th className="px-8 py-5 text-[11px] font-black uppercase tracking-widest text-on-surface-variant">Code</th>
                <th className="px-8 py-5 text-[11px] font-black uppercase tracking-widest text-on-surface-variant">Ưu đãi</th>
                <th className="px-8 py-5 text-[11px] font-black uppercase tracking-widest text-on-surface-variant">Hạn dùng</th>
                <th className="px-8 py-5 text-[11px] font-black uppercase tracking-widest text-on-surface-variant">Đã dùng</th>
                <th className="px-8 py-5 text-[11px] font-black uppercase tracking-widest text-on-surface-variant">Trạng thái</th>
                <th className="px-8 py-5 text-[11px] font-black uppercase tracking-widest text-on-surface-variant text-right">Hành động</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-outline-variant/10">
              {filteredPromotions.map((promotion) => (
                <tr key={promotion.id}>
                  <td className="px-8 py-6 text-sm font-black text-on-surface">{promotion.code}</td>
                  <td className="px-8 py-6 text-sm text-on-surface">{promotion.discountPercent}% • max {promotion.maxDiscountAmount.toLocaleString()}đ</td>
                  <td className="px-8 py-6 text-sm text-on-surface-variant">{promotion.validUntil}</td>
                  <td className="px-8 py-6 text-sm text-on-surface">{promotion.usedCount}/{promotion.usageLimit}</td>
                  <td className="px-8 py-6">
                    <span className={`rounded-full px-4 py-1.5 text-xs font-bold ${promotion.isActive ? 'bg-primary-container/10 text-primary-container' : 'bg-error-container text-error'}`}>{promotion.isActive ? 'Active' : 'Expired'}</span>
                  </td>
                  <td className="px-8 py-6 text-right">
                    <div className="flex justify-end gap-2">
                      <button onClick={() => { setEditingPromotion(promotion); setForm({ code: promotion.code, discountPercent: promotion.discountPercent, maxDiscountAmount: promotion.maxDiscountAmount, validUntil: promotion.validUntil, usageLimit: promotion.usageLimit }); }} className="rounded-full bg-surface-container-low px-4 py-2 text-xs font-bold text-on-surface">Sửa</button>
                      <button onClick={() => handleDelete(promotion)} className="rounded-full bg-error-container px-4 py-2 text-xs font-bold text-error">Xóa</button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
