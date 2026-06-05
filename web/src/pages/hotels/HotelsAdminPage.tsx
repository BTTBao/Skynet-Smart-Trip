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
  commissionRate: 10,
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
  const [showGuide, setShowGuide] = useState(false);

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
      commissionRate: hotel.commissionRate || 10,
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
            Quản lý danh mục khách sạn hệ thống, cấu hình tỉ lệ hoa hồng và điều chỉnh thông tin vận hành.
          </p>
        </div>
        <div className="flex flex-wrap items-center gap-3">
          <button
            onClick={() => setShowGuide(true)}
            className="rounded-full bg-amber-500 hover:bg-amber-600 px-6 py-3 text-sm font-bold text-white transition-all shadow-sm"
          >
            💡 Hướng dẫn vận hành
          </button>
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
              Thiết lập thông tin cơ bản cho khách sạn mới.
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

        <div className="grid grid-cols-1 gap-4 md:grid-cols-2 lg:grid-cols-3">
          <label className="flex flex-col rounded-2xl bg-surface-container-low px-5 py-3">
            <span className="text-[11px] font-black uppercase tracking-[0.2em] text-on-surface-variant">Điểm đến</span>
            <select
              value={form.destinationId}
              onChange={(event) => setForm((current) => ({ ...current, destinationId: Number(event.target.value) }))}
              className="mt-2 w-full bg-transparent text-base font-bold text-on-surface outline-none cursor-pointer"
              required
            >
              <option value={0}>Chọn điểm đến</option>
              {destinations.map((destination) => (
                <option key={destination.id} value={destination.id}>
                  {destination.name}
                </option>
              ))}
            </select>
          </label>
          <label className="flex flex-col rounded-2xl bg-surface-container-low px-5 py-3">
            <span className="text-[11px] font-black uppercase tracking-[0.2em] text-on-surface-variant">Tên khách sạn</span>
            <input
              value={form.name}
              onChange={(event) => setForm((current) => ({ ...current, name: event.target.value }))}
              placeholder="Nhập tên khách sạn"
              className="mt-2 w-full bg-transparent text-base font-bold text-on-surface outline-none"
              required
            />
          </label>
          <label className="flex flex-col rounded-2xl bg-surface-container-low px-5 py-3">
            <span className="text-[11px] font-black uppercase tracking-[0.2em] text-on-surface-variant">Địa chỉ</span>
            <input
              value={form.address}
              onChange={(event) => setForm((current) => ({ ...current, address: event.target.value }))}
              placeholder="Nhập địa chỉ khách sạn"
              className="mt-2 w-full bg-transparent text-base font-bold text-on-surface outline-none"
            />
          </label>
          <label className="flex flex-col rounded-2xl bg-surface-container-low px-5 py-3">
            <span className="text-[11px] font-black uppercase tracking-[0.2em] text-on-surface-variant">Số sao</span>
            <input
              value={form.starRating}
              onChange={(event) => setForm((current) => ({ ...current, starRating: Number(event.target.value) }))}
              type="number"
              min={1}
              max={5}
              placeholder="Từ 1 đến 5 sao"
              className="mt-2 w-full bg-transparent text-base font-bold text-on-surface outline-none"
            />
          </label>
          <label className="flex flex-col rounded-2xl bg-surface-container-low px-5 py-3">
            <span className="text-[11px] font-black uppercase tracking-[0.2em] text-on-surface-variant">Hoa hồng %</span>
            <input
              value={form.commissionRate}
              onChange={(event) => setForm((current) => ({ ...current, commissionRate: Number(event.target.value) }))}
              type="number"
              min={0}
              max={100}
              placeholder="Tỉ lệ phần trăm hoa hồng"
              className="mt-2 w-full bg-transparent text-base font-bold text-on-surface outline-none"
              required
            />
          </label>
          <label className="flex flex-col rounded-2xl bg-surface-container-low px-5 py-3">
            <span className="text-[11px] font-black uppercase tracking-[0.2em] text-on-surface-variant">Mô tả ngắn</span>
            <input
              value={form.description}
              onChange={(event) => setForm((current) => ({ ...current, description: event.target.value }))}
              placeholder="Mô tả tóm tắt khách sạn"
              className="mt-2 w-full bg-transparent text-base font-bold text-on-surface outline-none"
            />
          </label>
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
            className="rounded-full bg-primary px-8 py-3 text-sm font-bold text-white disabled:opacity-50"
          >
            {submitting ? 'Đang lưu...' : editingHotel ? 'Lưu thay đổi' : 'Tạo khách sạn'}
          </button>
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
                  </td>
                  <td className="px-8 py-6 text-sm font-medium text-on-surface">{hotel.destinationName}</td>
                  <td className="px-8 py-6 text-sm text-on-surface-variant">{hotel.address || 'Chưa có địa chỉ'}</td>
                  <td className="px-8 py-6 text-sm font-medium text-on-surface">
                    {hotel.starRating} sao • {hotel.roomCount} loại phòng • {hotel.commissionRate}%
                  </td>
                  <td className="px-8 py-6">
                    <span
                      className={`rounded-full px-4 py-1.5 text-xs font-bold ${
                        hotel.isAvailable ? 'bg-primary-container/10 text-primary-container' : 'bg-error-container text-error'
                      }`}
                    >
                      {hotel.isAvailable ? 'Hoạt động' : 'Tạm dừng'}
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

      {showGuide && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-sm p-4 animate-in fade-in duration-200">
          <div className="w-full max-w-2xl rounded-[2.5rem] bg-white p-8 shadow-2xl ring-1 ring-black/5 animate-in slide-in-from-bottom-8 duration-350">
            <div className="flex items-start justify-between border-b border-slate-100 pb-4">
              <div>
                <p className="text-[11px] font-black uppercase tracking-[0.22em] text-amber-600">Hướng dẫn sử dụng</p>
                <h3 className="mt-1 text-2xl font-black text-slate-900">Vận hành Khách sạn & Phòng</h3>
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
                <h4 className="font-bold text-amber-800 text-base">📌 Nguyên tắc hoạt động cốt lõi</h4>
                <ul className="mt-3 list-disc list-inside space-y-2 text-amber-950 font-medium">
                  <li><strong>Không xóa dữ liệu:</strong> Để đảm bảo tính toàn vẹn của lịch sử đặt phòng (bookings), hệ thống không hỗ trợ xóa khách sạn hoặc phòng.</li>
                  <li><strong>Tạm dừng bán khách sạn:</strong> Tắt checkbox <em>"Hoạt động"</em> hoặc chuyển trạng thái khách sạn sang ngừng bán.</li>
                  <li><strong>Tạm dừng bán loại phòng:</strong> Nhấp vào chi tiết khách sạn và đổi số lượng sẵn có của loại phòng đó về <code>0</code>.</li>
                </ul>
              </div>
              <div>
                <h4 className="font-black text-slate-900 text-base">🏨 Chi tiết cấu hình</h4>
                <ul className="mt-2 list-disc list-inside space-y-2">
                  <li><strong>Điểm đến (Destination):</strong> Điểm đến được liên kết cố định khi tạo khách sạn mới và được khóa để tránh làm sai lệch ngữ cảnh.</li>
                  <li><strong>Hoa hồng khách sạn:</strong> Cấu hình tỷ lệ hoa hồng ở cấp độ khách sạn. Tất cả các phòng sẽ tự động thừa hưởng tỷ lệ này.</li>
                  <li><strong>Doanh thu & Lợi nhuận:</strong> Giá trị doanh thu và lợi nhuận hiển thị tự động tích lũy dựa trên các giao dịch thực tế đã thanh toán thành công (Paid).</li>
                </ul>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
