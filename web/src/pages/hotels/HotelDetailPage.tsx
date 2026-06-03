import { useEffect, useMemo, useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useToast } from '../../context';
import {
  adminService,
  type AdminHotelDetail,
  type AdminHotelRequest,
  type AdminRoom,
  type AdminRoomRequest,
} from '../../services/adminService';
import { getErrorMessage } from '../../utils/http';

const emptyHotelForm: AdminHotelRequest = {
  destinationId: 0,
  name: '',
  address: '',
  starRating: 4,
  description: '',
  isAvailable: true,
};

const emptyRoomForm: AdminRoomRequest = {
  roomType: '',
  capacity: 2,
  pricePerNight: 0,
  commissionRate: 10,
  availableQty: 1,
  imageUrls: [],
};

function formatCurrency(value: number) {
  return `${value.toLocaleString('vi-VN')} VND`;
}

export default function HotelDetailPage({ hotelId }: { hotelId: number }) {
  const navigate = useNavigate();
  const { showToast } = useToast();
  const [hotel, setHotel] = useState<AdminHotelDetail | null>(null);
  const [hotelForm, setHotelForm] = useState<AdminHotelRequest>(emptyHotelForm);
  const [roomForm, setRoomForm] = useState<AdminRoomRequest>(emptyRoomForm);
  const [roomImageUrls, setRoomImageUrls] = useState<string[]>([]);
  const [editingRoom, setEditingRoom] = useState<AdminRoom | null>(null);
  const [loading, setLoading] = useState(true);
  const [savingHotel, setSavingHotel] = useState(false);
  const [savingRoom, setSavingRoom] = useState(false);
  const [uploadingRoomImage, setUploadingRoomImage] = useState(false);

  const loadHotel = async () => {
    const data = await adminService.getHotelDetail(hotelId);
    setHotel(data);
    setHotelForm({
      destinationId: data.destinationId,
      name: data.name,
      address: data.address,
      starRating: data.starRating,
      description: data.description,
      isAvailable: data.isAvailable,
    });
  };

  useEffect(() => {
    const fetchData = async () => {
      try {
        await loadHotel();
      } catch (error) {
        showToast({
          type: 'error',
          title: 'Không thể tải chi tiết khách sạn',
          message: getErrorMessage(error),
        });
        navigate('/hotels');
      } finally {
        setLoading(false);
      }
    };

    void fetchData();
  }, [hotelId]);

  const roomSummary = useMemo(() => {
    if (!hotel) {
      return { sellingCount: 0, pausedCount: 0 };
    }

    return {
      sellingCount: hotel.rooms.filter((room) => room.availableQty > 0).length,
      pausedCount: hotel.rooms.filter((room) => room.availableQty === 0).length,
    };
  }, [hotel]);

  const handleHotelSubmit = async (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    setSavingHotel(true);

    try {
      await adminService.updateHotel(hotelId, hotelForm);
      await loadHotel();
      showToast({
        type: 'success',
        title: 'Đã cập nhật khách sạn',
        message: 'Thông tin tổng quan đã được lưu.',
      });
    } catch (error) {
      showToast({
        type: 'error',
        title: 'Không thể cập nhật khách sạn',
        message: getErrorMessage(error),
      });
    } finally {
      setSavingHotel(false);
    }
  };

  const handleRoomSubmit = async (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    setSavingRoom(true);

    try {
      const roomPayload = {
        ...roomForm,
        imageUrls: roomImageUrls,
      };

      if (editingRoom) {
        await adminService.updateRoom(editingRoom.id, roomPayload);
        showToast({
          type: 'success',
          title: 'Đã cập nhật phòng',
          message: 'Loại phòng đã được điều chỉnh.',
        });
      } else {
        await adminService.createRoom(hotelId, roomPayload);
        showToast({
          type: 'success',
          title: 'Đã thêm phòng',
          message:
            roomForm.availableQty === 0
              ? 'Phòng mới đang tạm dừng bán. Bạn có thể mở lại bất cứ lúc nào.'
              : 'Phòng mới đã sẵn sàng để nhận booking.',
        });
      }

      await loadHotel();
      setEditingRoom(null);
      setRoomForm(emptyRoomForm);
      setRoomImageUrls([]);
    } catch (error) {
      showToast({
        type: 'error',
        title: 'Không thể lưu phòng',
        message: getErrorMessage(error),
      });
    } finally {
      setSavingRoom(false);
    }
  };

  const handleRoomImageUpload = async (event: React.ChangeEvent<HTMLInputElement>) => {
    const selectedFiles = Array.from(event.target.files ?? []);
    if (selectedFiles.length === 0) {
      return;
    }

    const availableSlots = Math.max(12 - roomImageUrls.length, 0);
    const filesToUpload = selectedFiles.slice(0, availableSlots);
    if (filesToUpload.length === 0) {
      showToast({
        type: 'error',
        title: 'Album da du 12 anh',
        message: 'Hay xoa bot anh cu truoc khi tai them anh moi.',
      });
      event.target.value = '';
      return;
    }

    setUploadingRoomImage(true);
    try {
      const uploadedImages = await Promise.all(filesToUpload.map((file) => adminService.uploadRoomImage(file)));
      setRoomImageUrls((current) => [...current, ...uploadedImages.map((image) => image.imageUrl)].slice(0, 12));
      showToast({
        type: 'success',
        title: 'Da tai anh phong',
        message:
          filesToUpload.length < selectedFiles.length
            ? `Da tai ${filesToUpload.length} anh. Album toi da 12 anh.`
            : `Da tai ${filesToUpload.length} anh vao album phong.`,
      });
    } catch (error) {
      showToast({
        type: 'error',
        title: 'Khong the tai anh phong',
        message: getErrorMessage(error),
      });
    } finally {
      setUploadingRoomImage(false);
      event.target.value = '';
    }
  };

  const removeRoomImage = (url: string) => {
    setRoomImageUrls((current) => current.filter((imageUrl) => imageUrl !== url));
  };

  const beginEditRoom = (room: AdminRoom) => {
    setEditingRoom(room);
    setRoomForm({
      roomType: room.roomType,
      capacity: room.capacity,
      pricePerNight: room.pricePerNight,
      commissionRate: room.commissionRate,
      availableQty: room.availableQty,
      imageUrls: room.imageUrls,
    });
    setRoomImageUrls(room.imageUrls);
  };

  if (loading || !hotel) {
    return (
      <div className="flex h-full min-h-[55vh] items-center justify-center">
        <div className="h-12 w-12 animate-spin rounded-full border-b-2 border-primary" />
      </div>
    );
  }

  return (
    <div className="space-y-8">
      <div className="rounded-[2.5rem] bg-[radial-gradient(circle_at_top_left,_rgba(255,255,255,0.28),_transparent_32%),linear-gradient(135deg,_#0f766e_0%,_#155e75_55%,_#1f2937_100%)] p-8 text-white shadow-[0px_24px_80px_rgba(15,118,110,0.22)]">
        <div className="flex flex-col gap-6 xl:flex-row xl:items-start xl:justify-between">
          <div className="max-w-3xl">
            <Link
              to="/hotels"
              className="inline-flex items-center gap-2 rounded-full bg-white/10 px-4 py-2 text-xs font-bold uppercase tracking-[0.18em] text-white/90"
            >
              ← Quay lại danh sách
            </Link>
            <p className="mt-6 text-[11px] font-black uppercase tracking-[0.28em] text-white/65">Hotel Detail</p>
            <h1 className="mt-4 text-4xl font-black leading-tight">{hotel.name}</h1>
            <p className="mt-3 max-w-2xl text-sm leading-7 text-white/75">
              Đây là nơi admin có thể giữ mô tả khách sạn gọn gàng, sau đó vận hành phòng theo cách rất thực tế:
              phòng nào ngừng bán thì đưa <span className="font-bold text-white">availableQty</span> về 0, không xóa cứng.
            </p>
          </div>

          <div className="grid min-w-[280px] gap-4 sm:grid-cols-2 xl:grid-cols-1">
            <div className="rounded-[1.75rem] bg-white/12 p-5 ring-1 ring-white/10">
              <p className="text-[11px] font-black uppercase tracking-[0.2em] text-white/60">Doanh thu khách sạn</p>
              <p className="mt-3 text-2xl font-black">{formatCurrency(hotel.totalRevenue)}</p>
              <p className="mt-1 text-xs text-white/70">Tính trên các booking khách sạn đã thanh toán.</p>
            </div>
            <div className="rounded-[1.75rem] bg-white/12 p-5 ring-1 ring-white/10">
              <p className="text-[11px] font-black uppercase tracking-[0.2em] text-white/60">Đang mở bán</p>
              <p className="mt-3 text-2xl font-black">{hotel.availableRoomQty}</p>
              <p className="mt-1 text-xs text-white/70">Tổng phòng còn có thể đặt ngay lúc này</p>
            </div>
            <div className="rounded-[1.75rem] bg-white/12 p-5 ring-1 ring-white/10">
              <p className="text-[11px] font-black uppercase tracking-[0.2em] text-white/60">Loại phòng</p>
              <p className="mt-3 text-2xl font-black">{hotel.roomCount}</p>
              <p className="mt-1 text-xs text-white/70">
                {roomSummary.sellingCount} đang bán, {roomSummary.pausedCount} tạm dừng
              </p>
            </div>
            <div className="rounded-[1.75rem] bg-white/12 p-5 ring-1 ring-white/10">
              <p className="text-[11px] font-black uppercase tracking-[0.2em] text-white/60">Giá từ</p>
              <p className="mt-3 text-2xl font-black">{formatCurrency(hotel.lowestPrice)}</p>
              <p className="mt-1 text-xs text-white/70">
                {hotel.destinationName} • {hotel.starRating} sao
              </p>
            </div>
          </div>
        </div>
      </div>

      <div className="grid gap-8 xl:grid-cols-[1.05fr_0.95fr]">
        <form
          onSubmit={handleHotelSubmit}
          className="rounded-[2rem] bg-white p-8 shadow-[0px_20px_40px_rgba(21,28,39,0.04)] ring-1 ring-outline-variant/10"
        >
          <div className="flex items-start justify-between gap-4">
            <div>
              <p className="text-[11px] font-black uppercase tracking-[0.22em] text-primary">Tổng quan</p>
              <h2 className="mt-3 text-2xl font-black text-on-surface">Thông tin khách sạn</h2>
              <p className="mt-2 text-sm text-on-surface-variant">
                Không xóa dữ liệu. Nếu cần dừng kinh doanh, hãy tắt trạng thái mở bán của hotel.
              </p>
            </div>
            <span
              className={`rounded-full px-4 py-2 text-xs font-bold ${
                hotel.isAvailable ? 'bg-primary-container/15 text-primary' : 'bg-error-container text-error'
              }`}
            >
              {hotel.isAvailable ? 'Đang mở bán' : 'Tạm dừng'}
            </span>
          </div>

          <div className="mt-8 grid grid-cols-1 gap-4 md:grid-cols-2">
            <div className="rounded-[1.6rem] bg-surface-container-low p-5">
              <p className="text-[11px] font-black uppercase tracking-[0.2em] text-on-surface-variant">Điểm đến</p>
              <p className="mt-3 text-lg font-black text-on-surface">{hotel.destinationName}</p>
              <p className="mt-2 text-sm text-on-surface-variant">
                Điểm đến được khóa tại màn này để tránh đổi nhầm ngữ cảnh sau khi đã tạo room.
              </p>
            </div>
            <div className="rounded-[1.6rem] bg-surface-container-low p-5">
              <p className="text-[11px] font-black uppercase tracking-[0.2em] text-on-surface-variant">Doanh thu hiện tại</p>
              <p className="mt-3 text-lg font-black text-on-surface">{formatCurrency(hotel.totalRevenue)}</p>
              <p className="mt-2 text-sm text-on-surface-variant">
                Giá trị này tự cập nhật từ các booking khách sạn đã thanh toán liên quan tới những room bên dưới.
              </p>
            </div>
            <label className="rounded-[1.6rem] bg-surface-container-low p-5">
              <span className="text-[11px] font-black uppercase tracking-[0.2em] text-on-surface-variant">Tên khách sạn</span>
              <input
                value={hotelForm.name}
                onChange={(event) => setHotelForm((current) => ({ ...current, name: event.target.value }))}
                className="mt-3 w-full bg-transparent text-lg font-black text-on-surface outline-none"
                required
              />
            </label>
            <label className="rounded-[1.6rem] bg-surface-container-low p-5">
              <span className="text-[11px] font-black uppercase tracking-[0.2em] text-on-surface-variant">Địa chỉ</span>
              <input
                value={hotelForm.address}
                onChange={(event) => setHotelForm((current) => ({ ...current, address: event.target.value }))}
                className="mt-3 w-full bg-transparent text-base font-medium text-on-surface outline-none"
                placeholder="Thêm địa chỉ cho khách sạn"
              />
            </label>
            <label className="rounded-[1.6rem] bg-surface-container-low p-5">
              <span className="text-[11px] font-black uppercase tracking-[0.2em] text-on-surface-variant">Số sao</span>
              <input
                value={hotelForm.starRating}
                onChange={(event) => setHotelForm((current) => ({ ...current, starRating: Number(event.target.value) }))}
                type="number"
                min={1}
                max={5}
                className="mt-3 w-full bg-transparent text-base font-medium text-on-surface outline-none"
              />
            </label>
          </div>

          <label className="mt-4 block rounded-[1.6rem] bg-surface-container-low p-5">
            <span className="text-[11px] font-black uppercase tracking-[0.2em] text-on-surface-variant">Mô tả</span>
            <textarea
              value={hotelForm.description}
              onChange={(event) => setHotelForm((current) => ({ ...current, description: event.target.value }))}
              rows={4}
              className="mt-3 w-full resize-none bg-transparent text-sm leading-7 text-on-surface outline-none"
              placeholder="Mô tả ngắn gọn, dễ đọc, dễ ghi nhớ."
            />
          </label>

          <label className="mt-4 inline-flex items-center gap-3 rounded-full bg-surface-container-low px-5 py-3">
            <input
              checked={hotelForm.isAvailable}
              onChange={(event) => setHotelForm((current) => ({ ...current, isAvailable: event.target.checked }))}
              type="checkbox"
              className="h-4 w-4 accent-[#0f766e]"
            />
            <span className="text-sm font-bold text-on-surface">Khách sạn đang mở bán</span>
          </label>

          <div className="mt-6 flex flex-wrap items-center gap-4">
            <button
              type="submit"
              disabled={savingHotel}
              className="rounded-full bg-primary px-7 py-3 text-sm font-bold text-white disabled:opacity-50"
            >
              {savingHotel ? 'Đang lưu...' : 'Lưu thay đổi'}
            </button>
            <p className="text-xs text-on-surface-variant">
              Xóa khách sạn đã bị chặn hoàn toàn. Cách an toàn nhất là tắt mở bán và đưa room về 0 nếu cần.
            </p>
          </div>
        </form>

        <div className="rounded-[2rem] bg-[#f7f6f1] p-8 shadow-[0px_20px_40px_rgba(21,28,39,0.04)] ring-1 ring-black/5">
          <div className="flex items-start justify-between gap-4">
            <div>
              <p className="text-[11px] font-black uppercase tracking-[0.22em] text-[#8a6b31]">Quản lý phòng</p>
              <h2 className="mt-3 text-2xl font-black text-slate-900">
                {editingRoom ? 'Chỉnh sửa phòng' : 'Thêm phòng mới'}
              </h2>
              <p className="mt-2 text-sm text-slate-600">
                Nếu phòng tạm ngừng bán, chỉ cần đưa <span className="font-bold text-slate-900">availableQty</span> về 0.
                Không cần xóa phòng.
              </p>
            </div>
            {editingRoom ? (
              <button
                type="button"
                onClick={() => {
                  setEditingRoom(null);
                  setRoomForm(emptyRoomForm);
                  setRoomImageUrls([]);
                }}
                className="rounded-full bg-white px-4 py-2 text-xs font-bold text-slate-900"
              >
                Tạo phòng mới
              </button>
            ) : null}
          </div>

          <form onSubmit={handleRoomSubmit} className="mt-8 grid grid-cols-1 gap-4 sm:grid-cols-2">
            <label className="rounded-[1.4rem] bg-white px-5 py-4 ring-1 ring-black/5 sm:col-span-2">
              <span className="text-[11px] font-black uppercase tracking-[0.18em] text-slate-500">Loại phòng</span>
              <input
                value={roomForm.roomType}
                onChange={(event) => setRoomForm((current) => ({ ...current, roomType: event.target.value }))}
                className="mt-3 w-full bg-transparent text-base font-bold text-slate-900 outline-none"
                placeholder="Superior, Deluxe, Family..."
                required
              />
            </label>
            <label className="rounded-[1.4rem] bg-white px-5 py-4 ring-1 ring-black/5">
              <span className="text-[11px] font-black uppercase tracking-[0.18em] text-slate-500">Sức chứa</span>
              <input
                value={roomForm.capacity}
                onChange={(event) => setRoomForm((current) => ({ ...current, capacity: Number(event.target.value) }))}
                type="number"
                min={1}
                className="mt-3 w-full bg-transparent text-base font-bold text-slate-900 outline-none"
                required
              />
            </label>
            <label className="rounded-[1.4rem] bg-white px-5 py-4 ring-1 ring-black/5">
              <span className="text-[11px] font-black uppercase tracking-[0.18em] text-slate-500">Available Qty</span>
              <input
                value={roomForm.availableQty}
                onChange={(event) => setRoomForm((current) => ({ ...current, availableQty: Number(event.target.value) }))}
                type="number"
                min={0}
                className="mt-3 w-full bg-transparent text-base font-bold text-slate-900 outline-none"
                required
              />
              <p className="mt-2 text-xs text-slate-500">Đặt 0 nếu muốn tạm ngừng bán phòng này.</p>
            </label>
            <label className="rounded-[1.4rem] bg-white px-5 py-4 ring-1 ring-black/5">
              <span className="text-[11px] font-black uppercase tracking-[0.18em] text-slate-500">Giá mỗi đêm</span>
              <input
                value={roomForm.pricePerNight}
                onChange={(event) => setRoomForm((current) => ({ ...current, pricePerNight: Number(event.target.value) }))}
                type="number"
                min={0}
                className="mt-3 w-full bg-transparent text-base font-bold text-slate-900 outline-none"
                required
              />
            </label>
            <label className="rounded-[1.4rem] bg-white px-5 py-4 ring-1 ring-black/5">
              <span className="text-[11px] font-black uppercase tracking-[0.18em] text-slate-500">Commission %</span>
              <input
                value={roomForm.commissionRate}
                onChange={(event) => setRoomForm((current) => ({ ...current, commissionRate: Number(event.target.value) }))}
                type="number"
                min={0}
                max={100}
                className="mt-3 w-full bg-transparent text-base font-bold text-slate-900 outline-none"
                required
              />
            </label>

            <div className="rounded-[1.4rem] bg-white px-5 py-4 ring-1 ring-black/5 sm:col-span-2">
  <div className="flex flex-wrap items-center justify-between gap-3">
    <div>
      <span className="text-[11px] font-black uppercase tracking-[0.18em] text-slate-500">Album anh phong</span>
      <p className="mt-2 text-xs text-slate-500">Tai len JPG, PNG hoac WEBP. Toi da 12 anh moi phong.</p>
    </div>
    <label
      className={`inline-flex cursor-pointer items-center rounded-full px-5 py-2.5 text-xs font-black ${
        uploadingRoomImage || roomImageUrls.length >= 12
          ? 'bg-slate-100 text-slate-400'
          : 'bg-primary text-white shadow-[0px_12px_24px_rgba(15,118,110,0.18)]'
      }`}
    >
      {uploadingRoomImage ? 'Dang tai...' : roomImageUrls.length >= 12 ? 'Da du anh' : 'Tai anh len'}
      <input
        type="file"
        accept="image/jpeg,image/png,image/webp"
        multiple
        disabled={uploadingRoomImage || roomImageUrls.length >= 12}
        onChange={handleRoomImageUpload}
        className="hidden"
      />
    </label>
  </div>

  {roomImageUrls.length > 0 ? (
    <div className="mt-4 grid grid-cols-2 gap-3 sm:grid-cols-3">
      {roomImageUrls.map((url, index) => (
        <div key={`${url}-${index}`} className="group relative overflow-hidden rounded-2xl bg-slate-100 ring-1 ring-black/10">
          <img src={url} alt="" className="h-28 w-full object-cover" />
          <button
            type="button"
            onClick={() => removeRoomImage(url)}
            className="absolute right-2 top-2 rounded-full bg-white/95 px-2.5 py-1 text-xs font-black text-slate-900 shadow-sm"
          >
            Xoa
          </button>
        </div>
      ))}
    </div>
  ) : (
    <div className="mt-4 rounded-2xl border border-dashed border-slate-200 bg-slate-50 px-5 py-8 text-center text-sm font-bold text-slate-400">
      Chua co anh phong
    </div>
  )}
</div>

            <div className="sm:col-span-2">
              <button
                type="submit"
                disabled={savingRoom}
                className="rounded-full bg-slate-900 px-7 py-3 text-sm font-bold text-white disabled:opacity-50"
              >
                {savingRoom ? 'Đang lưu...' : editingRoom ? 'Lưu phòng' : 'Thêm phòng'}
              </button>
            </div>
          </form>
        </div>
      </div>

      <section className="rounded-[2rem] bg-white shadow-[0px_20px_40px_rgba(21,28,39,0.04)] ring-1 ring-outline-variant/10">
        <div className="flex flex-col gap-4 border-b border-outline-variant/10 px-8 py-6 md:flex-row md:items-end md:justify-between">
          <div>
            <p className="text-[11px] font-black uppercase tracking-[0.22em] text-primary">Danh sách phòng</p>
            <h2 className="mt-3 text-2xl font-black text-on-surface">Vận hành từng loại phòng</h2>
            <p className="mt-2 text-sm text-on-surface-variant">
              Xóa đã bị khóa hoàn toàn. Phòng nào tạm dừng bán thì để tồn kho về 0, lịch sử vẫn được giữ nguyên.
            </p>
          </div>
          <div className="flex flex-wrap gap-3 text-xs font-bold">
            <span className="rounded-full bg-primary-container/10 px-4 py-2 text-primary">
              {roomSummary.sellingCount} phòng đang bán
            </span>
            <span className="rounded-full bg-surface-container-low px-4 py-2 text-on-surface">
              {roomSummary.pausedCount} phòng tạm dừng
            </span>
          </div>
        </div>

        {hotel.rooms.length === 0 ? (
          <div className="px-8 py-14 text-center">
            <div className="mx-auto max-w-xl rounded-[2rem] bg-[linear-gradient(135deg,_rgba(15,118,110,0.08),_rgba(251,191,36,0.10))] px-8 py-10">
              <p className="text-[11px] font-black uppercase tracking-[0.22em] text-primary">Sẵn sàng bước tiếp</p>
              <h3 className="mt-3 text-2xl font-black text-on-surface">Khách sạn đã tạo xong. Bây giờ hãy thêm phòng đầu tiên.</h3>
              <p className="mt-3 text-sm leading-7 text-on-surface-variant">
                Chỉ cần bắt đầu với 1 hoặc 2 loại phòng, sau đó quay lại điều chỉnh tồn kho và giá theo nhu cầu thực tế.
              </p>
            </div>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full border-collapse text-left">
              <thead>
                <tr className="bg-surface-container-low/50">
                  <th className="px-8 py-5 text-[11px] font-black uppercase tracking-widest text-on-surface-variant">Loại phòng</th>
                  <th className="px-8 py-5 text-[11px] font-black uppercase tracking-widest text-on-surface-variant">Sức chứa</th>
                  <th className="px-8 py-5 text-[11px] font-black uppercase tracking-widest text-on-surface-variant">Giá / Đêm</th>
                  <th className="px-8 py-5 text-[11px] font-black uppercase tracking-widest text-on-surface-variant">Commission</th>
                  <th className="px-8 py-5 text-[11px] font-black uppercase tracking-widest text-on-surface-variant">Available Qty</th>
                  <th className="px-8 py-5 text-[11px] font-black uppercase tracking-widest text-on-surface-variant">Album</th>
                  <th className="px-8 py-5 text-[11px] font-black uppercase tracking-widest text-on-surface-variant">Trạng thái</th>
                  <th className="px-8 py-5 text-right text-[11px] font-black uppercase tracking-widest text-on-surface-variant">Hành động</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-outline-variant/10">
                {hotel.rooms.map((room) => (
                  <tr key={room.id}>
                    <td className="px-8 py-6">
                      <p className="text-sm font-bold text-on-surface">{room.roomType}</p>
                      <p className="mt-1 text-xs text-on-surface-variant">Room ID #{room.id}</p>
                    </td>
                    <td className="px-8 py-6 text-sm font-medium text-on-surface">{room.capacity} người</td>
                    <td className="px-8 py-6 text-sm font-medium text-on-surface">{formatCurrency(room.pricePerNight)}</td>
                    <td className="px-8 py-6 text-sm text-on-surface-variant">{room.commissionRate}%</td>
                    <td className="px-8 py-6 text-sm font-bold text-on-surface">{room.availableQty}</td>
                    <td className="px-8 py-6">
                      {room.imageUrls.length > 0 ? (
                        <div>
                          <div className="flex -space-x-2">
                            {room.imageUrls.slice(0, 3).map((url) => (
                              <img
                                key={url}
                                src={url}
                                alt=""
                                className="h-10 w-10 rounded-xl border-2 border-white object-cover"
                              />
                            ))}
                          </div>
                          <p className="mt-2 text-xs font-bold text-on-surface-variant">{room.imageUrls.length} anh</p>
                        </div>
                      ) : (
                        <span className="text-xs font-bold text-on-surface-variant">Chua co anh</span>
                      )}
                    </td>
                    <td className="px-8 py-6">
                      <span
                        className={`rounded-full px-4 py-1.5 text-xs font-bold ${
                          room.availableQty > 0 ? 'bg-primary-container/10 text-primary' : 'bg-surface-container-low text-on-surface-variant'
                        }`}
                      >
                        {room.availableQty > 0 ? 'Đang bán' : 'Tạm dừng'}
                      </span>
                    </td>
                    <td className="px-8 py-6 text-right">
                      <button
                        onClick={() => beginEditRoom(room)}
                        className="rounded-full bg-surface-container-low px-4 py-2 text-xs font-bold text-on-surface"
                      >
                        Chỉnh sửa
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </section>
    </div>
  );
}
