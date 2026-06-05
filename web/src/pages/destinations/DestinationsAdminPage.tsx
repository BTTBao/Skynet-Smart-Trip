import { useEffect, useMemo, useState } from 'react';
import { useAdminSearch, useToast } from '../../context';
import {
  adminService,
  type AdminDestination,
  type AdminDestinationRequest,
} from '../../services/adminService';
import { downloadCsv } from '../../utils/adminActions';
import { getErrorMessage } from '../../utils/http';

const initialForm: AdminDestinationRequest = {
  name: '',
  description: '',
  coverImageUrl: '',
  isHot: false,
};

export default function DestinationsAdminPage() {
  const { query } = useAdminSearch();
  const { showToast } = useToast();
  const [destinations, setDestinations] = useState<AdminDestination[]>([]);
  const [loading, setLoading] = useState(true);
  const [editingDestination, setEditingDestination] = useState<AdminDestination | null>(null);
  const [form, setForm] = useState<AdminDestinationRequest>(initialForm);
  const [submitting, setSubmitting] = useState(false);
  const [showGuide, setShowGuide] = useState(false);

  const loadDestinations = async () => {
    const data = await adminService.getDestinations();
    setDestinations(data);
  };

  useEffect(() => {
    const fetchData = async () => {
      try {
        await loadDestinations();
      } catch (error) {
        showToast({ type: 'error', title: 'Không thể tải điểm đến', message: getErrorMessage(error) });
      } finally {
        setLoading(false);
      }
    };

    fetchData();
  }, []);

  const filteredDestinations = useMemo(() => {
    const keyword = query.trim().toLowerCase();
    return destinations.filter((destination) =>
      keyword.length === 0 ||
      destination.name.toLowerCase().includes(keyword) ||
      destination.description.toLowerCase().includes(keyword)
    );
  }, [destinations, query]);

  const hotCount = destinations.filter((destination) => destination.isHot).length;

  const handleSubmit = async (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    setSubmitting(true);

    try {
      if (editingDestination) {
        await adminService.updateDestination(editingDestination.id, form);
      } else {
        await adminService.createDestination(form);
      }

      await loadDestinations();
      setEditingDestination(null);
      setForm(initialForm);

      showToast({
        type: 'success',
        title: editingDestination ? 'Đã cập nhật điểm đến' : 'Đã tạo điểm đến',
        message: 'Dữ liệu điểm đến đã được đồng bộ.',
      });
    } catch (error) {
      showToast({
        type: 'error',
        title: 'Không thể lưu điểm đến',
        message: getErrorMessage(error),
      });
    } finally {
      setSubmitting(false);
    }
  };

  const handleDelete = async (destination: AdminDestination) => {
    try {
      await adminService.deleteDestination(destination.id);
      await loadDestinations();
      showToast({
        type: 'success',
        title: 'Đã xóa điểm đến',
        message: `${destination.name} đã được gỡ khỏi hệ thống.`,
      });
    } catch (error) {
      showToast({
        type: 'error',
        title: 'Không thể xóa điểm đến',
        message: getErrorMessage(error),
      });
    }
  };

  const exportDestinations = () => {
    downloadCsv('destinations.csv', filteredDestinations, [
      { key: 'name', header: 'Điểm đến' },
      { key: 'description', header: 'Mô tả' },
      { key: 'hotelCount', header: 'Khách sạn' },
      { key: 'tripCount', header: 'Chuyến đi' },
      { key: 'isHot', header: 'Hot' },
    ]);
    showToast({ type: 'success', title: 'Đã xuất danh sách điểm đến' });
  };

  if (loading) {
    return <div className="flex items-center justify-center h-full min-h-[50vh]"><div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary"></div></div>;
  }

  const inputCls = 'w-full rounded-xl border border-slate-200 bg-white px-4 py-2.5 text-sm font-medium text-on-surface outline-none transition focus:border-primary focus:ring-2 focus:ring-primary/20 placeholder:text-slate-400 min-w-0';

  return (
    <div className="space-y-8">
      <div className="flex flex-col xl:flex-row xl:items-start justify-between gap-4">
        <div>
          <p className="text-xs font-bold uppercase tracking-widest text-primary mb-1">Catalog quản trị</p>
          <h1 className="text-3xl font-black text-on-surface">Điểm đến</h1>
          <p className="text-sm text-slate-500 mt-1 max-w-xl">
            Quản lý danh mục các địa điểm du lịch, điểm đến của các chuyến đi, khách sạn và dịch vụ trên toàn hệ thống.
          </p>
        </div>
        <div className="flex flex-wrap items-center gap-2">
          <button
            onClick={() => setShowGuide(true)}
            className="rounded-full bg-amber-500 hover:bg-amber-600 px-5 py-2.5 text-sm font-bold text-white transition-all shadow-sm"
          >
            💡 Hướng dẫn
          </button>
          <button onClick={exportDestinations} className="rounded-full bg-slate-100 text-slate-700 px-5 py-2.5 text-sm font-bold hover:bg-slate-200 transition">Xuất CSV</button>
        </div>
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
        <div className="bg-white rounded-2xl p-6 shadow-sm border border-slate-100">
          <p className="text-xs font-semibold text-slate-500 uppercase tracking-wider">Tổng điểm đến</p>
          <h2 className="mt-2 text-3xl font-black text-on-surface">{destinations.length}</h2>
        </div>
        <div className="bg-white rounded-2xl p-6 shadow-sm border border-slate-100">
          <p className="text-xs font-semibold text-slate-500 uppercase tracking-wider">Điểm đến nổi bật</p>
          <h2 className="mt-2 text-3xl font-black text-on-surface">{hotCount}</h2>
        </div>
        <div className="bg-white rounded-2xl p-6 shadow-sm border border-slate-100">
          <p className="text-xs font-semibold text-slate-500 uppercase tracking-wider">Kết quả lọc</p>
          <h2 className="mt-2 text-3xl font-black text-on-surface">{filteredDestinations.length}</h2>
        </div>
      </div>

      <form onSubmit={handleSubmit} className="bg-white rounded-2xl p-6 shadow-sm border border-slate-100">
        <div className="flex items-center justify-between gap-4 mb-5">
          <div>
            <h2 className="text-lg font-black text-on-surface">{editingDestination ? 'Cập nhật điểm đến' : 'Tạo điểm đến mới'}</h2>
            <p className="text-sm text-slate-500 mt-0.5">Điền đầy đủ thông tin chi tiết bên dưới để thiết lập điểm đến.</p>
          </div>
          {editingDestination ? <button type="button" onClick={() => { setEditingDestination(null); setForm(initialForm); }} className="rounded-full bg-slate-100 px-4 py-2 text-sm font-semibold text-slate-600 hover:bg-slate-200 transition">Hủy sửa</button> : null}
        </div>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
          <div className="flex flex-col gap-1.5">
            <span className="text-xs font-semibold text-slate-500 uppercase tracking-wider">Tên điểm đến <span className="text-red-400">*</span></span>
            <input
              value={form.name}
              onChange={(event) => setForm((current) => ({ ...current, name: event.target.value }))}
              placeholder="Ví dụ: Đà Nẵng"
              className={inputCls}
              required
            />
          </div>
          <div className="flex flex-col gap-1.5">
            <span className="text-xs font-semibold text-slate-500 uppercase tracking-wider">Ảnh bìa (URL)</span>
            <input
              value={form.coverImageUrl}
              onChange={(event) => setForm((current) => ({ ...current, coverImageUrl: event.target.value }))}
              placeholder="https://example.com/image.jpg"
              className={inputCls}
            />
          </div>
          <div className="flex flex-col gap-1.5">
            <span className="text-xs font-semibold text-slate-500 uppercase tracking-wider">Mô tả ngắn</span>
            <input
              value={form.description}
              onChange={(event) => setForm((current) => ({ ...current, description: event.target.value }))}
              placeholder="Mô tả tóm tắt điểm đến"
              className={inputCls}
            />
          </div>
        </div>
        <label className="mt-4 inline-flex items-center gap-3 rounded-xl border border-slate-200 bg-white px-4 py-3 cursor-pointer hover:bg-slate-50 transition">
          <input checked={form.isHot} onChange={(event) => setForm((current) => ({ ...current, isHot: event.target.checked }))} type="checkbox" className="h-4 w-4 accent-emerald-500" />
          <span className="text-sm font-medium text-on-surface">Đánh dấu điểm đến nổi bật (hiển thị đầu trang chủ Mobile)</span>
        </label>
        <div className="mt-5">
          <button type="submit" disabled={submitting} className="rounded-full bg-primary px-8 py-3 text-sm font-bold text-white disabled:opacity-50">
            {submitting ? 'Đang lưu...' : editingDestination ? 'Lưu thay đổi' : 'Tạo điểm đến'}
          </button>
        </div>
      </form>

      <div className="bg-white rounded-2xl border border-slate-100 overflow-hidden shadow-sm">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead className="bg-slate-50 border-b border-slate-100">
              <tr>
                <th className="px-6 py-4 text-xs font-bold uppercase tracking-wider text-slate-500">Điểm đến</th>
                <th className="px-6 py-4 text-xs font-bold uppercase tracking-wider text-slate-500">Mô tả</th>
                <th className="px-6 py-4 text-xs font-bold uppercase tracking-wider text-slate-500">Khách sạn / Chuyến</th>
                <th className="px-6 py-4 text-xs font-bold uppercase tracking-wider text-slate-500">Nổi bật</th>
                <th className="px-6 py-4 text-right text-xs font-bold uppercase tracking-wider text-slate-500">Hành động</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-50">
              {filteredDestinations.map((destination) => (
                <tr key={destination.id} className="hover:bg-slate-50/70 transition-colors">
                  <td className="px-6 py-4">
                    <p className="text-sm font-semibold text-on-surface">{destination.name}</p>
                    <p className="text-xs text-slate-400 mt-0.5 truncate max-w-[200px]">{destination.coverImageUrl || 'Chưa có ảnh cover'}</p>
                  </td>
                  <td className="px-6 py-4 text-sm text-slate-500 max-w-[220px]">
                    <p className="truncate">{destination.description || '—'}</p>
                  </td>
                  <td className="px-6 py-4">
                    <span className="text-sm font-medium text-on-surface">{destination.hotelCount} khách sạn</span>
                    <span className="text-slate-400 mx-1">·</span>
                    <span className="text-sm text-slate-500">{destination.tripCount} chuyến</span>
                  </td>
                  <td className="px-6 py-4">
                    <span className={`rounded-full px-3 py-1 text-xs font-semibold ${destination.isHot ? 'bg-amber-50 text-amber-700' : 'bg-slate-100 text-slate-500'}`}>
                      {destination.isHot ? '🔥 Nổi bật' : 'Thường'}
                    </span>
                  </td>
                  <td className="px-6 py-4 text-right">
                    <div className="flex justify-end gap-2">
                      <button onClick={() => { setEditingDestination(destination); setForm({ name: destination.name, description: destination.description, coverImageUrl: destination.coverImageUrl, isHot: destination.isHot }); }} className="rounded-full bg-slate-100 px-3 py-1.5 text-xs font-semibold text-slate-700 hover:bg-slate-200 transition">Sửa</button>
                      <button onClick={() => handleDelete(destination)} className="rounded-full bg-red-50 px-3 py-1.5 text-xs font-semibold text-red-600 hover:bg-red-100 transition">Xóa</button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
        {filteredDestinations.length === 0 && (
          <div className="py-12 text-center">
            <span className="material-symbols-outlined text-4xl text-slate-300">place</span>
            <p className="mt-3 text-slate-500 font-medium">Chưa có điểm đến nào</p>
          </div>
        )}
      </div>

      {showGuide && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-sm p-4">
          <div className="w-full max-w-2xl rounded-3xl bg-white p-8 shadow-2xl ring-1 ring-black/5">
            <div className="flex items-start justify-between border-b border-slate-100 pb-4">
              <div>
                <p className="text-xs font-black uppercase tracking-widest text-amber-600">Hướng dẫn sử dụng</p>
                <h3 className="mt-1 text-xl font-black text-slate-900">Vận hành Điểm đến (Catalog)</h3>
              </div>
              <button type="button" onClick={() => setShowGuide(false)} className="rounded-full bg-slate-100 hover:bg-slate-200 px-4 py-2 text-xs font-bold text-slate-900 transition-colors">Đóng</button>
            </div>
            <div className="mt-6 space-y-5 text-sm text-slate-600 leading-relaxed max-h-[55vh] overflow-y-auto pr-1">
              <div className="rounded-2xl bg-amber-50 p-5 border border-amber-100">
                <h4 className="font-bold text-amber-800 text-base">📌 Liên kết dữ liệu hệ thống</h4>
                <ul className="mt-3 list-disc list-inside space-y-2 text-amber-900 font-medium">
                  <li><strong>Điểm đến là gốc:</strong> Được sử dụng để phân loại và làm bộ lọc chính cho Khách sạn, Chuyến xe (Lịch trình) và các bài viết Khám phá (Explore).</li>
                  <li><strong>Xóa điểm đến:</strong> Chỉ thực hiện được khi không có bất kỳ Khách sạn, Chuyến xe hay bài viết Khám phá nào đang tham chiếu đến điểm đến này.</li>
                </ul>
              </div>
              <div>
                <h4 className="font-black text-slate-900 text-base">🌐 Quy tắc cấu hình</h4>
                <ul className="mt-2 list-disc list-inside space-y-2">
                  <li><strong>Điểm đến nổi bật (Is Hot):</strong> Các địa điểm được đánh dấu là nổi bật sẽ xuất hiện đầu tiên trên trang chủ ứng dụng di động để thu hút lượt click của người dùng.</li>
                  <li><strong>Ảnh bìa:</strong> Nên sử dụng ảnh phong cảnh chất lượng cao (tỉ lệ 16:9) đại diện cho điểm đến để tối ưu hiển thị trên ứng dụng.</li>
                </ul>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
