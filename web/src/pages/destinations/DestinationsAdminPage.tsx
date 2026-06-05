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
        showToast({ type: 'error', title: 'Khong the tai diem den', message: getErrorMessage(error) });
      } finally {
        setLoading(false);
      }
    };

    void fetchData();
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

  const resetForm = () => {
    setEditingDestination(null);
    setForm(initialForm);
  };

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
      resetForm();
      showToast({ type: 'success', title: editingDestination ? 'Da cap nhat diem den' : 'Da tao diem den' });
    } catch (error) {
      showToast({ type: 'error', title: 'Khong the luu diem den', message: getErrorMessage(error) });
    } finally {
      setSubmitting(false);
    }
  };

  const handleDelete = async (destination: AdminDestination) => {
    try {
      await adminService.deleteDestination(destination.id);
      await loadDestinations();
      showToast({ type: 'success', title: 'Da xoa diem den', message: destination.name });
    } catch (error) {
      showToast({ type: 'error', title: 'Khong the xoa diem den', message: getErrorMessage(error) });
    }
  };

  const handleCoverUpload = async (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (!file) return;

    setUploadingCover(true);
    try {
      const result = await adminService.uploadDestinationCoverImage(file);
      setForm((current) => ({ ...current, coverImageUrl: result.imageUrl }));
      showToast({ type: 'success', title: 'Da tai anh cover' });
    } catch (error) {
      showToast({ type: 'error', title: 'Khong the tai anh cover', message: getErrorMessage(error) });
    } finally {
      setUploadingCover(false);
      event.target.value = '';
    }
  };

  const startEdit = (destination: AdminDestination) => {
    setEditingDestination(destination);
    setForm({
      name: destination.name,
      description: destination.description,
      coverImageUrl: destination.coverImageUrl,
      isHot: destination.isHot,
    });
  };

  const exportDestinations = () => {
    downloadCsv('destinations.csv', filteredDestinations, [
      { key: 'name', header: 'Diem den' },
      { key: 'description', header: 'Mo ta' },
      { key: 'hotelCount', header: 'Khach san' },
      { key: 'tripCount', header: 'Chuyen di' },
      { key: 'isHot', header: 'Hot' },
    ]);
    showToast({ type: 'success', title: 'Da xuat danh sach diem den' });
  };

  if (loading) {
    return <div className="flex h-full min-h-[50vh] items-center justify-center"><div className="h-12 w-12 animate-spin rounded-full border-b-2 border-primary" /></div>;
  }

  return (
    <div className="space-y-8">
      <div className="flex flex-col justify-between gap-4 xl:flex-row xl:items-start">
        <div>
          <p className="mb-1 text-xs font-bold uppercase tracking-widest text-primary">Catalog quan tri</p>
          <h1 className="text-3xl font-black text-on-surface">Diem den</h1>
          <p className="mt-1 max-w-xl text-sm text-slate-500">
            Quan ly danh muc diem den dung cho khach san, tuyen xe va bai viet explore.
          </p>
        </div>
        <div className="flex flex-wrap items-center gap-2">
          <button onClick={() => setShowGuide(true)} className="rounded-full bg-amber-500 px-5 py-2.5 text-sm font-bold text-white shadow-sm transition hover:bg-amber-600">
            Huong dan
          </button>
          <button onClick={exportDestinations} className="rounded-full bg-slate-100 px-5 py-2.5 text-sm font-bold text-slate-700 transition hover:bg-slate-200">
            Xuat CSV
          </button>
        </div>
      </div>

      <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
        <StatCard label="Tong diem den" value={destinations.length.toLocaleString()} />
        <StatCard label="Diem den noi bat" value={hotCount.toLocaleString()} />
        <StatCard label="Ket qua loc" value={filteredDestinations.length.toLocaleString()} />
      </div>

      <form onSubmit={handleSubmit} className="rounded-2xl border border-slate-100 bg-white p-6 shadow-sm">
        <div className="mb-5 flex items-center justify-between gap-4">
          <div>
            <h2 className="text-lg font-black text-on-surface">{editingDestination ? 'Cap nhat diem den' : 'Tao diem den moi'}</h2>
            <p className="mt-0.5 text-sm text-slate-500">Nhap thong tin va upload anh cover neu co.</p>
          </div>
          {editingDestination ? (
            <button type="button" onClick={resetForm} className="rounded-full bg-slate-100 px-4 py-2 text-sm font-semibold text-slate-600 transition hover:bg-slate-200">
              Huy sua
            </button>
          ) : null}
        </div>

        <div className="grid grid-cols-1 gap-4 md:grid-cols-4">
          <input value={form.name} onChange={(event) => setForm((current) => ({ ...current, name: event.target.value }))} placeholder="Ten diem den" className="rounded-2xl bg-surface-container-low px-5 py-3 outline-none" required />
          <div className="flex gap-2">
            <input value={form.coverImageUrl} onChange={(event) => setForm((current) => ({ ...current, coverImageUrl: event.target.value }))} placeholder="Anh cover URL" className="min-w-0 flex-1 rounded-2xl bg-surface-container-low px-5 py-3 outline-none" />
            <label className="cursor-pointer rounded-2xl bg-surface-container-low px-4 py-3 text-sm font-bold text-on-surface">
              {uploadingCover ? 'Dang tai' : 'Upload'}
              <input type="file" accept="image/jpeg,image/png,image/webp" disabled={uploadingCover} onChange={handleCoverUpload} className="hidden" />
            </label>
          </div>
          <input value={form.description} onChange={(event) => setForm((current) => ({ ...current, description: event.target.value }))} placeholder="Mo ta ngan" className="rounded-2xl bg-surface-container-low px-5 py-3 outline-none md:col-span-2" />
        </div>

        <div className="mt-4">
          {hasCoverPreview ? (
            <div className="overflow-hidden rounded-[1.5rem] border border-outline-variant/15 bg-surface-container-low">
              <div className="flex items-center justify-between border-b border-outline-variant/10 px-5 py-3">
                <div>
                  <p className="text-[11px] font-black uppercase tracking-[0.2em] text-on-surface-variant">Preview cover</p>
                  <p className="mt-1 text-xs text-on-surface-variant">Anh se hien tren the diem den sau khi luu.</p>
                </div>
                <button type="button" onClick={() => setForm((current) => ({ ...current, coverImageUrl: '' }))} className="rounded-full bg-white px-4 py-2 text-xs font-bold text-on-surface">
                  Xoa anh
                </button>
              </div>
              <div className="aspect-[21/9] w-full bg-surface-container">
                <img src={form.coverImageUrl} alt="Destination cover preview" className="h-full w-full object-cover" />
              </div>
            </div>
          ) : (
            <div className="rounded-[1.5rem] border border-dashed border-outline-variant/20 bg-surface-container-low px-5 py-8 text-center text-sm font-bold text-on-surface-variant">
              Upload anh cover de xem preview tai day
            </div>
          )}
        </div>

        <label className="mt-4 inline-flex items-center gap-3 rounded-full bg-surface-container-low px-5 py-3">
          <input checked={form.isHot} onChange={(event) => setForm((current) => ({ ...current, isHot: event.target.checked }))} type="checkbox" className="h-4 w-4 accent-[#10B981]" />
          <span className="text-sm font-bold text-on-surface">Danh dau diem den noi bat</span>
        </label>

        <div className="mt-5">
          <button type="submit" disabled={submitting} className="rounded-full bg-primary px-8 py-3 text-sm font-bold text-white disabled:opacity-50">
            {submitting ? 'Dang luu...' : editingDestination ? 'Luu thay doi' : 'Tao diem den'}
          </button>
        </div>
      </form>

      <div className="overflow-hidden rounded-2xl border border-slate-100 bg-white shadow-sm">
        <div className="overflow-x-auto">
          <table className="w-full border-collapse text-left">
            <thead className="border-b border-slate-100 bg-slate-50">
              <tr>
                <th className="px-6 py-4 text-xs font-bold uppercase tracking-wider text-slate-500">Diem den</th>
                <th className="px-6 py-4 text-xs font-bold uppercase tracking-wider text-slate-500">Mo ta</th>
                <th className="px-6 py-4 text-xs font-bold uppercase tracking-wider text-slate-500">Khach san / Chuyen</th>
                <th className="px-6 py-4 text-xs font-bold uppercase tracking-wider text-slate-500">Noi bat</th>
                <th className="px-6 py-4 text-right text-xs font-bold uppercase tracking-wider text-slate-500">Hanh dong</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-50">
              {filteredDestinations.map((destination) => (
                <tr key={destination.id} className="transition-colors hover:bg-slate-50/70">
                  <td className="px-6 py-4">
                    <div className="flex items-center gap-4">
                      <div className="h-16 w-24 overflow-hidden rounded-2xl bg-surface-container-low">
                        {destination.coverImageUrl ? <img src={destination.coverImageUrl} alt="" className="h-full w-full object-cover" /> : null}
                      </div>
                      <div>
                        <p className="text-sm font-bold text-on-surface">{destination.name}</p>
                        <p className="mt-1 max-w-[220px] truncate text-xs text-on-surface-variant">{destination.coverImageUrl || 'Chua co anh cover'}</p>
                      </div>
                    </div>
                  </td>
                  <td className="max-w-[220px] px-6 py-4 text-sm text-slate-500">
                    <p className="truncate">{destination.description || '-'}</p>
                  </td>
                  <td className="px-6 py-4">
                    <span className="text-sm font-medium text-on-surface">{destination.hotelCount} khach san</span>
                    <span className="mx-1 text-slate-400">.</span>
                    <span className="text-sm text-slate-500">{destination.tripCount} chuyen</span>
                  </td>
                  <td className="px-6 py-4">
                    <span className={`rounded-full px-3 py-1 text-xs font-semibold ${destination.isHot ? 'bg-amber-50 text-amber-700' : 'bg-slate-100 text-slate-500'}`}>
                      {destination.isHot ? 'Noi bat' : 'Thuong'}
                    </span>
                  </td>
                  <td className="px-6 py-4 text-right">
                    <div className="flex justify-end gap-2">
                      <button onClick={() => startEdit(destination)} className="rounded-full bg-slate-100 px-3 py-1.5 text-xs font-semibold text-slate-700 transition hover:bg-slate-200">Sua</button>
                      <button onClick={() => handleDelete(destination)} className="rounded-full bg-red-50 px-3 py-1.5 text-xs font-semibold text-red-600 transition hover:bg-red-100">Xoa</button>
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
            <p className="mt-3 font-medium text-slate-500">Chua co diem den nao</p>
          </div>
        )}
      </div>

      {showGuide && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 p-4 backdrop-blur-sm">
          <div className="w-full max-w-2xl rounded-3xl bg-white p-8 shadow-2xl ring-1 ring-black/5">
            <div className="flex items-start justify-between border-b border-slate-100 pb-4">
              <div>
                <p className="text-xs font-black uppercase tracking-widest text-amber-600">Huong dan su dung</p>
                <h3 className="mt-1 text-xl font-black text-slate-900">Van hanh diem den</h3>
              </div>
              <button type="button" onClick={() => setShowGuide(false)} className="rounded-full bg-slate-100 px-4 py-2 text-xs font-bold text-slate-900 transition-colors hover:bg-slate-200">
                Dong
              </button>
            </div>
            <div className="mt-6 max-h-[55vh] space-y-5 overflow-y-auto pr-1 text-sm leading-relaxed text-slate-600">
              <div className="rounded-2xl border border-amber-100 bg-amber-50 p-5">
                <h4 className="text-base font-bold text-amber-800">Lien ket du lieu he thong</h4>
                <ul className="mt-3 list-inside list-disc space-y-2 font-medium text-amber-900">
                  <li>Diem den la goc de gan khach san, tuyen xe va bai explore.</li>
                  <li>Chi xoa diem den khi khong con du lieu phu thuoc.</li>
                  <li>Diem den noi bat se uu tien hien thi tren mobile.</li>
                </ul>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

function StatCard({ label, value }: { label: string; value: string }) {
  return (
    <div className="rounded-2xl border border-slate-100 bg-white p-6 shadow-sm">
      <p className="text-xs font-semibold uppercase tracking-wider text-slate-500">{label}</p>
      <h2 className="mt-2 text-3xl font-black text-on-surface">{value}</h2>
    </div>
  );
}
