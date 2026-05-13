import { useEffect, useMemo, useState } from 'react';
import { useAdminSearch, useToast } from '../../context';
import {
  adminService,
  type AdminDestination,
  type AdminHotel,
  type AdminHotelRequest,
} from '../../services/adminService';
import { downloadCsv } from '../../utils/adminActions';
import { getErrorMessage } from '../../utils/http';

const initialForm: AdminHotelRequest = {
  destinationId: 0,
  name: '',
  address: '',
  starRating: 4,
  description: '',
  isAvailable: true,
};

export default function HotelsAdminPage() {
  const { query } = useAdminSearch();
  const { showToast } = useToast();
  const [hotels, setHotels] = useState<AdminHotel[]>([]);
  const [destinations, setDestinations] = useState<AdminDestination[]>([]);
  const [loading, setLoading] = useState(true);
  const [editingHotel, setEditingHotel] = useState<AdminHotel | null>(null);
  const [form, setForm] = useState<AdminHotelRequest>(initialForm);
  const [submitting, setSubmitting] = useState(false);

  const loadHotels = async () => {
    const [hotelData, destinationData] = await Promise.all([
      adminService.getHotels(),
      adminService.getDestinations(),
    ]);

    setHotels(hotelData);
    setDestinations(destinationData);
  };

  useEffect(() => {
    const fetchData = async () => {
      try {
        await loadHotels();
      } catch (error) {
        showToast({ type: 'error', title: 'Không thể tải khách sạn', message: getErrorMessage(error) });
      } finally {
        setLoading(false);
      }
    };

    fetchData();
  }, []);

  const filteredHotels = useMemo(() => {
    const keyword = query.trim().toLowerCase();
    return hotels.filter((hotel) =>
      keyword.length === 0 ||
      hotel.name.toLowerCase().includes(keyword) ||
      hotel.destinationName.toLowerCase().includes(keyword) ||
      hotel.address.toLowerCase().includes(keyword)
    );
  }, [hotels, query]);

  const handleSubmit = async (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    setSubmitting(true);

    try {
      if (editingHotel) {
        await adminService.updateHotel(editingHotel.id, form);
      } else {
        await adminService.createHotel(form);
      }

      await loadHotels();
      setEditingHotel(null);
      setForm(initialForm);
      showToast({ type: 'success', title: editingHotel ? 'Đã cập nhật khách sạn' : 'Đã tạo khách sạn' });
    } catch (error) {
      showToast({ type: 'error', title: 'Không thể lưu khách sạn', message: getErrorMessage(error) });
    } finally {
      setSubmitting(false);
    }
  };

  const handleDelete = async (hotel: AdminHotel) => {
    try {
      await adminService.deleteHotel(hotel.id);
      await loadHotels();
      showToast({ type: 'success', title: 'Đã xóa khách sạn', message: hotel.name });
    } catch (error) {
      showToast({ type: 'error', title: 'Không thể xóa khách sạn', message: getErrorMessage(error) });
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
          <h1 className="mt-3 text-4xl font-black text-on-surface">Khách sạn & phòng</h1>
          <p className="mt-3 max-w-3xl text-sm text-on-surface-variant">Trang khách sạn đã có dữ liệu thật để quản lý danh sách khách sạn thay vì placeholder.</p>
        </div>
        <button onClick={() => downloadCsv('hotels.csv', filteredHotels, [{ key: 'name', header: 'Khách sạn' }, { key: 'destinationName', header: 'Điểm đến' }, { key: 'address', header: 'Địa chỉ' }, { key: 'starRating', header: 'Sao' }, { key: 'roomCount', header: 'Số phòng' }])} className="rounded-full bg-primary-container px-6 py-3 text-sm font-bold text-white">Xuất CSV</button>
      </div>

      <form onSubmit={handleSubmit} className="rounded-[2rem] bg-white p-8 shadow-[0px_20px_40px_rgba(21,28,39,0.04)] ring-1 ring-outline-variant/10">
        <div className="flex items-center justify-between gap-4 mb-6">
          <div>
            <h2 className="text-xl font-black text-on-surface">{editingHotel ? 'Cập nhật khách sạn' : 'Tạo khách sạn mới'}</h2>
            <p className="mt-1 text-sm text-on-surface-variant">Top bar đang hỗ trợ tìm theo tên khách sạn, điểm đến hoặc địa chỉ.</p>
          </div>
          {editingHotel ? <button type="button" onClick={() => { setEditingHotel(null); setForm(initialForm); }} className="rounded-full bg-surface-container-low px-5 py-2.5 text-sm font-bold text-on-surface">Hủy sửa</button> : null}
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 xl:grid-cols-6 gap-4">
          <select value={form.destinationId} onChange={(event) => setForm((current) => ({ ...current, destinationId: Number(event.target.value) }))} className="rounded-2xl bg-surface-container-low px-5 py-3 outline-none" required>
            <option value={0}>Điểm đến</option>
            {destinations.map((destination) => <option key={destination.id} value={destination.id}>{destination.name}</option>)}
          </select>
          <input value={form.name} onChange={(event) => setForm((current) => ({ ...current, name: event.target.value }))} placeholder="Tên khách sạn" className="rounded-2xl bg-surface-container-low px-5 py-3 outline-none" required />
          <input value={form.address} onChange={(event) => setForm((current) => ({ ...current, address: event.target.value }))} placeholder="Địa chỉ" className="rounded-2xl bg-surface-container-low px-5 py-3 outline-none" />
          <input value={form.starRating} onChange={(event) => setForm((current) => ({ ...current, starRating: Number(event.target.value) }))} type="number" min={1} max={5} placeholder="Số sao" className="rounded-2xl bg-surface-container-low px-5 py-3 outline-none" />
          <input value={form.description} onChange={(event) => setForm((current) => ({ ...current, description: event.target.value }))} placeholder="Mô tả" className="rounded-2xl bg-surface-container-low px-5 py-3 outline-none xl:col-span-2" />
        </div>

        <label className="mt-4 inline-flex items-center gap-3 rounded-full bg-surface-container-low px-5 py-3">
          <input checked={form.isAvailable} onChange={(event) => setForm((current) => ({ ...current, isAvailable: event.target.checked }))} type="checkbox" className="h-4 w-4 accent-[#10B981]" />
          <span className="text-sm font-bold text-on-surface">Đang mở bán</span>
        </label>

        <div className="mt-6">
          <button type="submit" disabled={submitting} className="rounded-full bg-primary-container px-8 py-3 text-sm font-bold text-white disabled:opacity-50">
            {submitting ? 'Đang lưu...' : editingHotel ? 'Lưu thay đổi' : 'Tạo khách sạn'}
          </button>
        </div>
      </form>

      <div className="rounded-[2rem] bg-white shadow-[0px_20px_40px_rgba(21,28,39,0.04)] overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-surface-container-low/50">
                <th className="px-8 py-5 text-[11px] font-black uppercase tracking-widest text-on-surface-variant">Khách sạn</th>
                <th className="px-8 py-5 text-[11px] font-black uppercase tracking-widest text-on-surface-variant">Điểm đến</th>
                <th className="px-8 py-5 text-[11px] font-black uppercase tracking-widest text-on-surface-variant">Địa chỉ</th>
                <th className="px-8 py-5 text-[11px] font-black uppercase tracking-widest text-on-surface-variant">Sao / Phòng</th>
                <th className="px-8 py-5 text-[11px] font-black uppercase tracking-widest text-on-surface-variant">Trạng thái</th>
                <th className="px-8 py-5 text-[11px] font-black uppercase tracking-widest text-on-surface-variant text-right">Hành động</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-outline-variant/10">
              {filteredHotels.map((hotel) => (
                <tr key={hotel.id}>
                  <td className="px-8 py-6">
                    <p className="text-sm font-bold text-on-surface">{hotel.name}</p>
                    <p className="text-xs text-on-surface-variant mt-1">{hotel.description || 'Chưa có mô tả'}</p>
                  </td>
                  <td className="px-8 py-6 text-sm font-medium text-on-surface">{hotel.destinationName}</td>
                  <td className="px-8 py-6 text-sm text-on-surface-variant">{hotel.address || 'Chưa có địa chỉ'}</td>
                  <td className="px-8 py-6 text-sm font-medium text-on-surface">{hotel.starRating} sao • {hotel.roomCount} phòng</td>
                  <td className="px-8 py-6">
                    <span className={`rounded-full px-4 py-1.5 text-xs font-bold ${hotel.isAvailable ? 'bg-primary-container/10 text-primary-container' : 'bg-error-container text-error'}`}>{hotel.isAvailable ? 'Available' : 'Closed'}</span>
                  </td>
                  <td className="px-8 py-6 text-right">
                    <div className="flex justify-end gap-2">
                      <button onClick={() => { setEditingHotel(hotel); setForm({ destinationId: hotel.destinationId, name: hotel.name, address: hotel.address, starRating: hotel.starRating, description: hotel.description, isAvailable: hotel.isAvailable }); }} className="rounded-full bg-surface-container-low px-4 py-2 text-xs font-bold text-on-surface">Sửa</button>
                      <button onClick={() => handleDelete(hotel)} className="rounded-full bg-error-container px-4 py-2 text-xs font-bold text-error">Xóa</button>
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
