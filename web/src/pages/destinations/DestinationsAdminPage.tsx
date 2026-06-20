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
  const [uploadingCover, setUploadingCover] = useState(false);

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
  const hasCoverPreview = form.coverImageUrl.trim().length > 0;

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

  const handleCoverUpload = async (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (!file) return;

    setUploadingCover(true);
    try {
      const result = await adminService.uploadDestinationCoverImage(file);
      setForm((current) => ({ ...current, coverImageUrl: result.imageUrl }));
      showToast({ type: 'success', title: 'Đã tải ảnh cover' });
    } catch (error) {
      showToast({ type: 'error', title: 'Không thể tải ảnh cover', message: getErrorMessage(error) });
    } finally {
      setUploadingCover(false);
      event.target.value = '';
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

  return (
    <div className="space-y-10">
      <div className="flex flex-col xl:flex-row xl:items-end justify-between gap-6">
        <div>
          <p className="text-[10px] font-black uppercase tracking-[0.2em] text-primary">Catalog quản trị</p>
          <h1 className="mt-3 text-4xl font-black text-on-surface">Điểm đến</h1>
          <p className="mt-3 max-w-3xl text-sm text-on-surface-variant">Trang này thay thế placeholder và hiện đã hỗ trợ CRUD điểm đến phục vụ booking, transport và hotel.</p>
        </div>
        <button onClick={exportDestinations} className="rounded-full bg-primary-container px-6 py-3 text-sm font-bold text-white">Xuất CSV</button>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div className="rounded-[2rem] bg-white p-8 shadow-[0px_20px_40px_rgba(21,28,39,0.04)]">
          <p className="text-[11px] font-black uppercase tracking-wider text-on-surface-variant">Tổng điểm đến</p>
          <h2 className="mt-3 text-4xl font-black text-on-surface">{destinations.length}</h2>
        </div>
        <div className="rounded-[2rem] bg-white p-8 shadow-[0px_20px_40px_rgba(21,28,39,0.04)]">
          <p className="text-[11px] font-black uppercase tracking-wider text-on-surface-variant">Điểm đến nổi bật</p>
          <h2 className="mt-3 text-4xl font-black text-on-surface">{hotCount}</h2>
        </div>
        <div className="rounded-[2rem] bg-white p-8 shadow-[0px_20px_40px_rgba(21,28,39,0.04)]">
          <p className="text-[11px] font-black uppercase tracking-wider text-on-surface-variant">Kết quả lọc</p>
          <h2 className="mt-3 text-4xl font-black text-on-surface">{filteredDestinations.length}</h2>
        </div>
      </div>

      <form onSubmit={handleSubmit} className="rounded-[2rem] bg-white p-8 shadow-[0px_20px_40px_rgba(21,28,39,0.04)] ring-1 ring-outline-variant/10">
        <div className="flex items-center justify-between gap-4 mb-6">
          <div>
            <h2 className="text-xl font-black text-on-surface">{editingDestination ? 'Cập nhật điểm đến' : 'Tạo điểm đến mới'}</h2>
            <p className="mt-1 text-sm text-on-surface-variant">Top bar đang hỗ trợ tìm theo tên hoặc mô tả điểm đến.</p>
          </div>
          {editingDestination ? <button type="button" onClick={() => { setEditingDestination(null); setForm(initialForm); }} className="rounded-full bg-surface-container-low px-5 py-2.5 text-sm font-bold text-on-surface">Hủy sửa</button> : null}
        </div>
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
          <input value={form.name} onChange={(event) => setForm((current) => ({ ...current, name: event.target.value }))} placeholder="Tên điểm đến" className="rounded-2xl bg-surface-container-low px-5 py-3 outline-none" required />
          <div className="flex gap-2">
            <input value={form.coverImageUrl} onChange={(event) => setForm((current) => ({ ...current, coverImageUrl: event.target.value }))} placeholder="Ảnh cover URL" className="min-w-0 flex-1 rounded-2xl bg-surface-container-low px-5 py-3 outline-none" />
            <label className="cursor-pointer rounded-2xl bg-surface-container-low px-4 py-3 text-sm font-bold text-on-surface">
              {uploadingCover ? 'Đang tải' : 'Upload'}
              <input type="file" accept="image/jpeg,image/png,image/webp" disabled={uploadingCover} onChange={handleCoverUpload} className="hidden" />
            </label>
          </div>
          <input value={form.description} onChange={(event) => setForm((current) => ({ ...current, description: event.target.value }))} placeholder="Mô tả ngắn" className="rounded-2xl bg-surface-container-low px-5 py-3 outline-none md:col-span-2" />
        </div>
        <div className="mt-4">
          {hasCoverPreview ? (
            <div className="overflow-hidden rounded-[1.5rem] border border-outline-variant/15 bg-surface-container-low">
              <div className="flex items-center justify-between border-b border-outline-variant/10 px-5 py-3">
                <div>
                  <p className="text-[11px] font-black uppercase tracking-[0.2em] text-on-surface-variant">Preview cover</p>
                  <p className="mt-1 text-xs text-on-surface-variant">Ảnh sẽ hiện ngay trên thẻ điểm đến sau khi lưu.</p>
                </div>
                <button
                  type="button"
                  onClick={() => setForm((current) => ({ ...current, coverImageUrl: '' }))}
                  className="rounded-full bg-white px-4 py-2 text-xs font-bold text-on-surface"
                >
                  Xóa ảnh
                </button>
              </div>
              <div className="aspect-[21/9] w-full bg-surface-container">
                <img src={form.coverImageUrl} alt="Destination cover preview" className="h-full w-full object-cover" />
              </div>
            </div>
          ) : (
            <div className="rounded-[1.5rem] border border-dashed border-outline-variant/20 bg-surface-container-low px-5 py-8 text-center text-sm font-bold text-on-surface-variant">
              Upload ảnh cover để xem preview tại đây
            </div>
          )}
        </div>
        <label className="mt-4 inline-flex items-center gap-3 rounded-full bg-surface-container-low px-5 py-3">
          <input checked={form.isHot} onChange={(event) => setForm((current) => ({ ...current, isHot: event.target.checked }))} type="checkbox" className="h-4 w-4 accent-[#10B981]" />
          <span className="text-sm font-bold text-on-surface">Đánh dấu điểm đến nổi bật</span>
        </label>
        <div className="mt-6">
          <button type="submit" disabled={submitting} className="rounded-full bg-primary-container px-8 py-3 text-sm font-bold text-white disabled:opacity-50">
            {submitting ? 'Đang lưu...' : editingDestination ? 'Lưu thay đổi' : 'Tạo điểm đến'}
          </button>
        </div>
      </form>

      <div className="rounded-[2rem] bg-white shadow-[0px_20px_40px_rgba(21,28,39,0.04)] overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-surface-container-low/50">
                <th className="px-8 py-5 text-[11px] font-black uppercase tracking-widest text-on-surface-variant">Điểm đến</th>
                <th className="px-8 py-5 text-[11px] font-black uppercase tracking-widest text-on-surface-variant">Mô tả</th>
                <th className="px-8 py-5 text-[11px] font-black uppercase tracking-widest text-on-surface-variant">Hotel / Trip</th>
                <th className="px-8 py-5 text-[11px] font-black uppercase tracking-widest text-on-surface-variant">Hot</th>
                <th className="px-8 py-5 text-[11px] font-black uppercase tracking-widest text-on-surface-variant text-right">Hành động</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-outline-variant/10">
              {filteredDestinations.map((destination) => (
                <tr key={destination.id}>
                  <td className="px-8 py-6">
                    <div className="flex items-center gap-4">
                      <div className="h-16 w-24 overflow-hidden rounded-2xl bg-surface-container-low">
                        {destination.coverImageUrl ? <img src={destination.coverImageUrl} alt="" className="h-full w-full object-cover" /> : null}
                      </div>
                      <div>
                    <p className="text-sm font-bold text-on-surface">{destination.name}</p>
                    <p className="text-xs text-on-surface-variant mt-1">{destination.coverImageUrl || 'Chưa có ảnh cover'}</p>
                      </div>
                    </div>
                  </td>
                  <td className="px-8 py-6 text-sm text-on-surface-variant">{destination.description || 'Chưa có mô tả'}</td>
                  <td className="px-8 py-6 text-sm font-medium text-on-surface">{destination.hotelCount} hotel • {destination.tripCount} trip</td>
                  <td className="px-8 py-6">
                    <span className={`rounded-full px-4 py-1.5 text-xs font-bold ${destination.isHot ? 'bg-primary-container/10 text-primary-container' : 'bg-surface-container-low text-on-surface-variant'}`}>{destination.isHot ? 'Hot' : 'Normal'}</span>
                  </td>
                  <td className="px-8 py-6 text-right">
                    <div className="flex justify-end gap-2">
                      <button onClick={() => { setEditingDestination(destination); setForm({ name: destination.name, description: destination.description, coverImageUrl: destination.coverImageUrl, isHot: destination.isHot }); }} className="rounded-full bg-surface-container-low px-4 py-2 text-xs font-bold text-on-surface">Sửa</button>
                      <button onClick={() => handleDelete(destination)} className="rounded-full bg-error-container px-4 py-2 text-xs font-bold text-error">Xóa</button>
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
