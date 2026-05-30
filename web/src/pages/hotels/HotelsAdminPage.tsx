import { useEffect, useMemo, useState } from 'react';
import { useNavigate } from 'react-router-dom';
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

const formatCurrency = (value: number) => `${value.toLocaleString('vi-VN')} VND`;

export default function HotelsAdminPage() {
  const navigate = useNavigate();
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
        showToast({
          type: 'error',
          title: 'Không thể tải khách sạn',
          message: getErrorMessage(error),
        });
      } finally {
        setLoading(false);
      }
    };

    void fetchData();
  }, []);

  const filteredHotels = useMemo(() => {
    const keyword = query.trim().toLowerCase();
    return hotels.filter((hotel) =>
      keyword.length === 0 ||
      hotel.name.toLowerCase().includes(keyword) ||
      hotel.destinationName.toLowerCase().includes(keyword) ||
      hotel.address.toLowerCase().includes(keyword),
    );
  }, [hotels, query]);

  const totalHotelRevenue = useMemo(
    () => filteredHotels.reduce((sum, hotel) => sum + hotel.totalRevenue, 0),
    [filteredHotels],
  );

  const handleSubmit = async (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    setSubmitting(true);

    try {
      if (editingHotel) {
        await adminService.updateHotel(editingHotel.id, form);
        await loadHotels();
        setEditingHotel(null);
        setForm(initialForm);
        showToast({ type: 'success', title: 'Đã cập nhật khách sạn' });
      } else {
        const createdHotel = await adminService.createHotel(form);
        showToast({
          type: 'success',
          title: 'Đã tạo khách sạn',
          message: 'Tiếp tục cấu hình phòng cho khách sạn mới.',
        });
        navigate(`/hotels/${createdHotel.id}`);
      }
    } catch (error) {
      showToast({
        type: 'error',
        title: 'Không thể lưu khách sạn',
        message: getErrorMessage(error),
      });
    } finally {
      setSubmitting(false);
    }
  };

  const startEditing = (hotel: AdminHotel) => {
    setEditingHotel(hotel);
    setForm({
      destinationId: hotel.destinationId,
      name: hotel.name,
      address: hotel.address,
      starRating: hotel.starRating,
      description: hotel.description,
      isAvailable: hotel.isAvailable,
    });
  };

  if (loading) {
    return (
      <div className="flex h-full min-h-[50vh] items-center justify-center">
        <div className="h-12 w-12 animate-spin rounded-full border-b-2 border-primary" />
      </div>
    );
  }

  return (
    <div className="space-y-10">
      <div className="flex flex-col justify-between gap-6 xl:flex-row xl:items-end">
        <div>
          <p className="text-[10px] font-black uppercase tracking-[0.2em] text-primary">Catalog quản trị</p>
          <h1 className="mt-3 text-4xl font-black text-on-surface">Khách sạn</h1>
          <p className="mt-3 max-w-3xl text-sm text-on-surface-variant">
            Tạo khách sạn trước, sau đó đi thẳng vào màn hình chi tiết để thêm từng loại phòng và điều chỉnh số lượng còn bán thật tự nhiên.
          </p>
        </div>
        <button
          onClick={() =>
            downloadCsv('hotels.csv', filteredHotels, [
              { key: 'name', header: 'Khách sạn' },
              { key: 'destinationName', header: 'Điểm đến' },
              { key: 'address', header: 'Địa chỉ' },
              { key: 'starRating', header: 'Sao' },
              { key: 'roomCount', header: 'Loại phòng' },
              { key: 'availableRoomQty', header: 'Còn bán' },
              { key: 'totalRevenue', header: 'Doanh thu' },
            ])
          }
          className="rounded-full bg-primary-container px-6 py-3 text-sm font-bold text-white"
        >
          Xuất CSV
        </button>
      </div>

      <div className="grid gap-4 lg:grid-cols-[1.3fr_0.7fr]">
        <div className="rounded-[2rem] bg-[linear-gradient(135deg,_#fef3c7,_#fff7ed_55%,_#ffffff)] p-6 shadow-[0px_20px_40px_rgba(21,28,39,0.04)] ring-1 ring-amber-200/60">
          <p className="text-[11px] font-black uppercase tracking-[0.22em] text-amber-700">Tổng doanh thu khách sạn</p>
          <p className="mt-3 text-4xl font-black text-slate-900">{formatCurrency(totalHotelRevenue)}</p>
          <p className="mt-2 text-sm text-slate-600">
            Tổng hợp từ các booking khách sạn đã thanh toán trong danh sách đang hiển thị.
          </p>
        </div>
        <div className="rounded-[2rem] bg-white p-6 shadow-[0px_20px_40px_rgba(21,28,39,0.04)] ring-1 ring-outline-variant/10">
          <p className="text-[11px] font-black uppercase tracking-[0.22em] text-primary">Tình hình hiện tại</p>
          <p className="mt-3 text-2xl font-black text-on-surface">{filteredHotels.length} khách sạn</p>
          <p className="mt-2 text-sm text-on-surface-variant">
            {filteredHotels.filter((hotel) => hotel.isAvailable).length} hoạt động,{' '}
            {filteredHotels.filter((hotel) => !hotel.isAvailable).length} tạm dừng.
          </p>
        </div>
      </div>

      <form
        onSubmit={handleSubmit}
        className="rounded-[2rem] bg-white p-8 shadow-[0px_20px_40px_rgba(21,28,39,0.04)] ring-1 ring-outline-variant/10"
      >
        <div className="mb-6 flex items-center justify-between gap-4">
          <div>
            <h2 className="text-xl font-black text-on-surface">
              {editingHotel ? 'Cập nhật khách sạn' : 'Tạo khách sạn mới'}
            </h2>
            <p className="mt-1 text-sm text-on-surface-variant">
              Sau khi tạo xong, hệ thống sẽ đưa bạn sang màn hình chi tiết để thêm phòng ngay.
            </p>
          </div>
          {editingHotel ? (
            <button
              type="button"
              onClick={() => {
                setEditingHotel(null);
                setForm(initialForm);
              }}
              className="rounded-full bg-surface-container-low px-5 py-2.5 text-sm font-bold text-on-surface"
            >
              Hủy sửa
            </button>
          ) : null}
        </div>

        <div className="grid grid-cols-1 gap-4 md:grid-cols-3 xl:grid-cols-6">
          <select
            value={form.destinationId}
            onChange={(event) => setForm((current) => ({ ...current, destinationId: Number(event.target.value) }))}
            className="rounded-2xl bg-surface-container-low px-5 py-3 outline-none"
            required
          >
            <option value={0}>Điểm đến</option>
            {destinations.map((destination) => (
              <option key={destination.id} value={destination.id}>
                {destination.name}
              </option>
            ))}
          </select>
          <input
            value={form.name}
            onChange={(event) => setForm((current) => ({ ...current, name: event.target.value }))}
            placeholder="Tên khách sạn"
            className="rounded-2xl bg-surface-container-low px-5 py-3 outline-none"
            required
          />
          <input
            value={form.address}
            onChange={(event) => setForm((current) => ({ ...current, address: event.target.value }))}
            placeholder="Địa chỉ"
            className="rounded-2xl bg-surface-container-low px-5 py-3 outline-none"
          />
          <input
            value={form.starRating}
            onChange={(event) => setForm((current) => ({ ...current, starRating: Number(event.target.value) }))}
            type="number"
            min={1}
            max={5}
            placeholder="Số sao"
            className="rounded-2xl bg-surface-container-low px-5 py-3 outline-none"
          />
          <input
            value={form.description}
            onChange={(event) => setForm((current) => ({ ...current, description: event.target.value }))}
            placeholder="Mô tả"
            className="rounded-2xl bg-surface-container-low px-5 py-3 outline-none xl:col-span-2"
          />
        </div>

        <label className="mt-4 inline-flex items-center gap-3 rounded-full bg-surface-container-low px-5 py-3">
          <input
            checked={form.isAvailable}
            onChange={(event) => setForm((current) => ({ ...current, isAvailable: event.target.checked }))}
            type="checkbox"
            className="h-4 w-4 accent-[#10B981]"
          />
          <span className="text-sm font-bold text-on-surface">Hoạt động</span>
        </label>

        <div className="mt-6 flex flex-wrap items-center gap-4">
          <button
            type="submit"
            disabled={submitting}
            className="rounded-full bg-primary-container px-8 py-3 text-sm font-bold text-white disabled:opacity-50"
          >
            {submitting ? 'Đang lưu...' : editingHotel ? 'Lưu thay đổi' : 'Tạo khách sạn'}
          </button>
          <p className="text-xs text-on-surface-variant">
            Xóa khách sạn đã bị khóa hoàn toàn. Nếu cần dừng bán, hãy sửa trạng thái trong màn hình chi tiết.
          </p>
        </div>
      </form>

      <div className="overflow-hidden rounded-[2rem] bg-white shadow-[0px_20px_40px_rgba(21,28,39,0.04)]">
        <div className="overflow-x-auto">
          <table className="w-full border-collapse text-left">
            <thead>
              <tr className="bg-surface-container-low/50">
                <th className="px-8 py-5 text-[11px] font-black uppercase tracking-widest text-on-surface-variant">Khách sạn</th>
                <th className="px-8 py-5 text-[11px] font-black uppercase tracking-widest text-on-surface-variant">Điểm đến</th>
                <th className="px-8 py-5 text-[11px] font-black uppercase tracking-widest text-on-surface-variant">Địa chỉ</th>
                <th className="px-8 py-5 text-[11px] font-black uppercase tracking-widest text-on-surface-variant">Sao / Room</th>
                <th className="px-8 py-5 text-[11px] font-black uppercase tracking-widest text-on-surface-variant">Trạng thái</th>
                <th className="px-8 py-5 text-[11px] font-black uppercase tracking-widest text-on-surface-variant">Tồn / Giá từ</th>
                <th className="px-8 py-5 text-[11px] font-black uppercase tracking-widest text-on-surface-variant">Doanh thu</th>
                <th className="px-8 py-5 text-right text-[11px] font-black uppercase tracking-widest text-on-surface-variant">Hành động</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-outline-variant/10">
              {filteredHotels.map((hotel) => (
                <tr key={hotel.id}>
                  <td className="px-8 py-6">
                    <p className="text-sm font-bold text-on-surface">{hotel.name}</p>
                    <p className="mt-1 text-xs text-on-surface-variant">{hotel.description || 'Chưa có mô tả'}</p>
                  </td>
                  <td className="px-8 py-6 text-sm font-medium text-on-surface">{hotel.destinationName}</td>
                  <td className="px-8 py-6 text-sm text-on-surface-variant">{hotel.address || 'Chưa có địa chỉ'}</td>
                  <td className="px-8 py-6 text-sm font-medium text-on-surface">
                    {hotel.starRating} sao • {hotel.roomCount} loại phòng
                  </td>
                  <td className="px-8 py-6">
                    <span
                      className={`rounded-full px-4 py-1.5 text-xs font-bold ${
                        hotel.isAvailable ? 'bg-primary-container/10 text-primary-container' : 'bg-error-container text-error'
                      }`}
                    >
                      {hotel.isAvailable ? 'Hoạt_động' : 'Tạm_dừng'}
                    </span>
                  </td>
                  <td className="px-8 py-6 text-sm text-on-surface-variant">
                    <p>{hotel.availableRoomQty} phòng còn bán</p>
                    <p className="mt-1 font-medium text-on-surface">Từ {formatCurrency(hotel.lowestPrice)}</p>
                  </td>
                  <td className="px-8 py-6 text-sm font-bold text-on-surface">
                    {formatCurrency(hotel.totalRevenue)}
                  </td>
                  <td className="px-8 py-6 text-right">
                    <div className="flex justify-end gap-2">
                      <button
                        onClick={() => navigate(`/hotels/${hotel.id}`)}
                        className="rounded-full bg-primary-container px-4 py-2 text-xs font-bold text-white"
                      >
                        Chi tiết
                      </button>
                      <button
                        onClick={() => startEditing(hotel)}
                        className="rounded-full bg-surface-container-low px-4 py-2 text-xs font-bold text-on-surface"
                      >
                        Sửa nhanh
                      </button>
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
