"use client";

import { use, useEffect, useMemo, useState } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import {
  adminService,
  type AdminHotelDetail,
  type AdminHotelRequest,
  type AdminRoom,
  type AdminRoomRequest,
} from '@/services/adminService';
import { toast } from 'sonner';
import {
  Card,
  CardContent,
  CardHeader,
  CardTitle,
  CardDescription,
} from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { Switch } from "@/components/ui/switch";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import {
  ArrowLeft,
  DollarSign,
  Hotel,
  Grid,
  Percent,
  Plus,
  Trash2,
  Upload,
  Image as ImageIcon,
  Edit2,
} from 'lucide-react';
import Image from 'next/image';

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
  return `${new Intl.NumberFormat('vi-VN', { notation: 'compact', maximumFractionDigits: 1 }).format(value)}đ`;
}

interface PageProps {
  params: Promise<{ id: string }>;
}

export default function HotelDetailPage({ params }: PageProps) {
  const resolvedParams = use(params);
  const hotelId = Number(resolvedParams.id);

  const router = useRouter();
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
    try {
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
    } catch (error: any) {
      toast.error('Không thể tải chi tiết khách sạn: ' + (error?.message || 'Lỗi kết nối'));
      router.push('/hotels');
    }
  };

  useEffect(() => {
    const fetchData = async () => {
      setLoading(true);
      await loadHotel();
      setLoading(false);
    };

    fetchData();
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

  const handleHotelSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setSavingHotel(true);

    try {
      await adminService.updateHotel(hotelId, hotelForm);
      await loadHotel();
      toast.success('Đã cập nhật thông tin khách sạn thành công');
    } catch (error: any) {
      toast.error('Không thể cập nhật khách sạn: ' + (error?.message || 'Có lỗi xảy ra'));
    } finally {
      setSavingHotel(false);
    }
  };

  const handleRoomSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setSavingRoom(true);

    try {
      const roomPayload = {
        ...roomForm,
        imageUrls: roomImageUrls,
      };

      if (editingRoom) {
        await adminService.updateRoom(editingRoom.id, roomPayload);
        toast.success('Đã cập nhật phòng thành công');
      } else {
        await adminService.createRoom(hotelId, roomPayload);
        toast.success('Đã thêm loại phòng mới thành công');
      }

      await loadHotel();
      setEditingRoom(null);
      setRoomForm(emptyRoomForm);
      setRoomImageUrls([]);
    } catch (error: any) {
      toast.error('Không thể lưu phòng: ' + (error?.message || 'Có lỗi xảy ra'));
    } finally {
      setSavingRoom(false);
    }
  };

  const handleRoomImageUpload = async (event: React.ChangeEvent<HTMLInputElement>) => {
    const selectedFiles = Array.from(event.target.files ?? []);
    if (selectedFiles.length === 0) return;

    const availableSlots = Math.max(12 - roomImageUrls.length, 0);
    const filesToUpload = selectedFiles.slice(0, availableSlots);
    if (filesToUpload.length === 0) {
      toast.warning('Album đã đủ 12 ảnh.');
      event.target.value = '';
      return;
    }

    setUploadingRoomImage(true);
    try {
      const uploadedImages = await Promise.all(
        filesToUpload.map((file) => adminService.uploadRoomImage(file))
      );
      setRoomImageUrls((current) =>
        [...current, ...uploadedImages.map((img) => img.imageUrl)].slice(0, 12)
      );
      toast.success(`Đã tải lên ${filesToUpload.length} ảnh`);
    } catch (error: any) {
      toast.error('Không thể tải lên ảnh: ' + (error?.message || 'Có lỗi xảy ra'));
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

  if (loading && !hotel) {
    return (
      <div className="flex items-center justify-center h-full min-h-[55vh]">
        <div className="animate-spin rounded-full h-10 w-10 border-b-2 border-primary"></div>
      </div>
    );
  }

  if (!hotel) return null;

  return (
    <div className="px-4 lg:px-6 space-y-6">
      {/* Detail header banner */}
      <div className="rounded-2xl bg-slate-900 dark:bg-slate-950 p-6 text-white shadow-xl relative overflow-hidden">
        <div className="relative z-10 flex flex-col md:flex-row md:items-start justify-between gap-6">
          <div className="space-y-4">
            <Button variant="secondary" size="sm" asChild className="text-xs font-bold gap-1 cursor-pointer bg-white/10 hover:bg-white/20 text-white border-none">
              <Link href="/hotels">
                <ArrowLeft className="h-3.5 w-3.5" /> Quay lại danh sách
              </Link>
            </Button>
            <div>
              <span className="text-[10px] font-black uppercase tracking-[0.2em] text-cyan-400">Chi tiết đối tác</span>
              <h1 className="text-3xl font-extrabold tracking-tight mt-1">{hotel.name}</h1>
              <p className="text-slate-300 text-xs mt-2 max-w-xl">
                Quản lý thông tin chung, địa chỉ khách sạn và cấu hình phòng/tồn kho thực tế.
              </p>
            </div>
          </div>

          <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 min-w-[280px]">
            <div className="rounded-xl bg-white/5 p-4 border border-white/10">
              <span className="text-[10px] text-slate-400 block font-semibold uppercase tracking-wider">Doanh thu phòng</span>
              <span className="text-lg font-black block mt-1">{formatCurrency(hotel.totalRevenue)}</span>
            </div>
            <div className="rounded-xl bg-white/5 p-4 border border-white/10">
              <span className="text-[10px] text-slate-400 block font-semibold uppercase tracking-wider">Lợi nhuận</span>
              <span className="text-lg font-black block mt-1">{formatCurrency(hotel.totalProfit)}</span>
            </div>
            <div className="rounded-xl bg-white/5 p-4 border border-white/10">
              <span className="text-[10px] text-slate-400 block font-semibold uppercase tracking-wider">Đã đặt</span>
              <span className="text-lg font-black block mt-1">{hotel.bookedRoomQty} phòng</span>
            </div>
            <div className="rounded-xl bg-white/5 p-4 border border-white/10">
              <span className="text-[10px] text-slate-400 block font-semibold uppercase tracking-wider">Tổng còn bán</span>
              <span className="text-lg font-black block mt-1">{hotel.availableRoomQty} phòng</span>
            </div>
          </div>
        </div>
      </div>

      <div className="grid gap-6 grid-cols-1 lg:grid-cols-12">
        {/* General Hotel Info form */}
        <div className="lg:col-span-7">
          <Card>
            <CardHeader className="flex flex-row items-center justify-between pb-6">
              <div>
                <CardTitle className="text-lg font-bold">Thông tin khách sạn</CardTitle>
                <CardDescription>Cập nhật mô tả, địa chỉ, xếp hạng sao của đối tác.</CardDescription>
              </div>
              <Badge variant={hotel.isAvailable ? 'secondary' : 'outline'} className={hotel.isAvailable ? 'bg-emerald-500/10 text-emerald-600' : ''}>
                {hotel.isAvailable ? 'Đang mở bán' : 'Tạm dừng bán'}
              </Badge>
            </CardHeader>
            <CardContent>
              <form onSubmit={handleHotelSubmit} className="space-y-4">
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div className="grid gap-2">
                    <Label htmlFor="hotel-detail-name">Tên khách sạn</Label>
                    <Input
                      id="hotel-detail-name"
                      value={hotelForm.name}
                      onChange={(e) => setHotelForm((c) => ({ ...c, name: e.target.value }))}
                      required
                    />
                  </div>
                  <div className="grid gap-2">
                    <Label htmlFor="hotel-detail-star">Số sao (1-5)</Label>
                    <Input
                      id="hotel-detail-star"
                      type="number"
                      min={1}
                      max={5}
                      value={hotelForm.starRating}
                      onChange={(e) => setHotelForm((c) => ({ ...c, starRating: Number(e.target.value) }))}
                      required
                    />
                  </div>
                </div>

                <div className="grid gap-2">
                  <Label htmlFor="hotel-detail-address">Địa chỉ</Label>
                  <Input
                    id="hotel-detail-address"
                    value={hotelForm.address}
                    onChange={(e) => setHotelForm((c) => ({ ...c, address: e.target.value }))}
                    required
                  />
                </div>

                <div className="grid gap-2">
                  <Label htmlFor="hotel-detail-desc">Mô tả chi tiết</Label>
                  <Textarea
                    id="hotel-detail-desc"
                    value={hotelForm.description}
                    onChange={(e) => setHotelForm((c) => ({ ...c, description: e.target.value }))}
                    rows={4}
                  />
                </div>

                <div className="flex items-center space-x-2 pt-2">
                  <Switch
                    id="hotel-detail-avail"
                    checked={hotelForm.isAvailable}
                    onCheckedChange={(checked) => setHotelForm((c) => ({ ...c, isAvailable: checked }))}
                  />
                  <Label htmlFor="hotel-detail-avail">Khách sạn đang mở bán trên hệ thống</Label>
                </div>

                <div className="flex justify-end gap-2 pt-2">
                  <Button type="submit" disabled={savingHotel} className="cursor-pointer">
                    {savingHotel ? 'Đang lưu...' : 'Lưu thông tin'}
                  </Button>
                </div>
              </form>
            </CardContent>
          </Card>
        </div>

        {/* Room Add/Edit Form */}
        <div className="lg:col-span-5">
          <Card className="bg-muted/30">
            <CardHeader className="flex flex-row items-center justify-between pb-6">
              <div>
                <CardTitle className="text-lg font-bold">
                  {editingRoom ? 'Chỉnh sửa loại phòng' : 'Thêm loại phòng mới'}
                </CardTitle>
                <CardDescription>
                  Cập nhật giá cả, sức chứa, tỷ lệ hoa hồng chiết khấu.
                </CardDescription>
              </div>
              {editingRoom && (
                <Button
                  size="sm"
                  variant="outline"
                  onClick={() => {
                    setEditingRoom(null);
                    setRoomForm(emptyRoomForm);
                    setRoomImageUrls([]);
                  }}
                  className="cursor-pointer h-8 text-xs"
                >
                  Tạo mới
                </Button>
              )}
            </CardHeader>
            <CardContent>
              <form onSubmit={handleRoomSubmit} className="space-y-4">
                <div className="grid gap-2">
                  <Label htmlFor="room-type">Tên loại phòng</Label>
                  <Input
                    id="room-type"
                    value={roomForm.roomType}
                    onChange={(e) => setRoomForm((c) => ({ ...c, roomType: e.target.value }))}
                    placeholder="Superior, Deluxe, Suite, Family..."
                    required
                  />
                </div>

                <div className="grid grid-cols-2 gap-4">
                  <div className="grid gap-2">
                    <Label htmlFor="room-capacity">Sức chứa (người)</Label>
                    <Input
                      id="room-capacity"
                      type="number"
                      min={1}
                      value={roomForm.capacity}
                      onChange={(e) => setRoomForm((c) => ({ ...c, capacity: Number(e.target.value) }))}
                      required
                    />
                  </div>
                  <div className="grid gap-2">
                    <Label htmlFor="room-qty">Số phòng còn bán</Label>
                    <Input
                      id="room-qty"
                      type="number"
                      min={0}
                      value={roomForm.availableQty}
                      onChange={(e) => setRoomForm((c) => ({ ...c, availableQty: Number(e.target.value) }))}
                      required
                    />
                  </div>
                </div>

                <div className="grid grid-cols-2 gap-4">
                  <div className="grid gap-2">
                    <Label htmlFor="room-price">Giá mỗi đêm (VND)</Label>
                    <Input
                      id="room-price"
                      type="number"
                      min={0}
                      value={roomForm.pricePerNight}
                      onChange={(e) => setRoomForm((c) => ({ ...c, pricePerNight: Number(e.target.value) }))}
                      required
                    />
                  </div>
                  <div className="grid gap-2">
                    <Label htmlFor="room-commission">Chiết khấu hoa hồng (%)</Label>
                    <Input
                      id="room-commission"
                      type="number"
                      min={0}
                      max={100}
                      value={roomForm.commissionRate}
                      onChange={(e) => setRoomForm((c) => ({ ...c, commissionRate: Number(e.target.value) }))}
                      required
                    />
                  </div>
                </div>

                {/* Room Images upload */}
                <div className="space-y-3 pt-2">
                  <div className="flex items-center justify-between">
                    <span className="text-xs font-bold text-muted-foreground">Album ảnh phòng (tối đa 12)</span>
                    <Label className="cursor-pointer inline-flex items-center justify-center rounded-lg border border-input bg-background px-3 h-8 text-xs font-semibold shadow-xs hover:bg-accent hover:text-accent-foreground select-none">
                      <Upload className="h-3 w-3 mr-1" /> {uploadingRoomImage ? 'Tải ảnh...' : 'Thêm ảnh'}
                      <input
                        type="file"
                        accept="image/*"
                        multiple
                        disabled={uploadingRoomImage || roomImageUrls.length >= 12}
                        onChange={handleRoomImageUpload}
                        className="hidden"
                      />
                    </Label>
                  </div>

                  {roomImageUrls.length > 0 ? (
                    <div className="grid grid-cols-3 gap-2">
                      {roomImageUrls.map((url, idx) => (
                        <div key={url} className="relative aspect-video rounded-md overflow-hidden bg-muted group border">
                          <Image
                            src={url}
                            alt=""
                            fill
                            sizes="120px"
                            className="object-cover"
                          />
                          <button
                            type="button"
                            onClick={() => removeRoomImage(url)}
                            className="absolute right-1 top-1 bg-black/60 text-white rounded-full p-1 opacity-0 group-hover:opacity-100 transition-opacity"
                          >
                            <Trash2 className="h-3 w-3" />
                          </button>
                        </div>
                      ))}
                    </div>
                  ) : (
                    <div className="rounded-lg border border-dashed p-4 text-center text-xs text-muted-foreground">
                      Chưa có hình ảnh nào cho loại phòng này
                    </div>
                  )}
                </div>

                <div className="flex justify-end gap-2 pt-2">
                  <Button type="submit" disabled={savingRoom} className="cursor-pointer w-full md:w-auto">
                    {savingRoom ? 'Đang lưu...' : editingRoom ? 'Lưu phòng' : 'Thêm loại phòng'}
                  </Button>
                </div>
              </form>
            </CardContent>
          </Card>
        </div>
      </div>

      {/* Rooms List Section */}
      <Card>
        <CardHeader className="flex flex-col sm:flex-row sm:items-center justify-between pb-6 gap-4">
          <div>
            <CardTitle className="text-lg font-bold">Vận hành các loại phòng</CardTitle>
            <CardDescription>
              Danh sách chi tiết phòng đang được kinh doanh của khách sạn.
            </CardDescription>
          </div>
          <div className="flex gap-2">
            <Badge variant="secondary" className="bg-emerald-500/10 text-emerald-600 dark:text-emerald-400">
              {roomSummary.sellingCount} đang bán
            </Badge>
            <Badge variant="outline">
              {roomSummary.pausedCount} tạm dừng
            </Badge>
          </div>
        </CardHeader>
        <CardContent className="p-0">
          <div className="overflow-x-auto">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead className="pl-6">Loại phòng</TableHead>
                  <TableHead>Sức chứa</TableHead>
                  <TableHead>Giá phòng / đêm</TableHead>
                  <TableHead>Chiết khấu</TableHead>
                  <TableHead>Đã đặt</TableHead>
                  <TableHead>Doanh thu</TableHead>
                  <TableHead>Lợi nhuận</TableHead>
                  <TableHead>Còn bán (Qty)</TableHead>
                  <TableHead>Hình ảnh</TableHead>
                  <TableHead>Trạng thái</TableHead>
                  <TableHead className="pr-6 text-right">Thao tác</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {hotel.rooms.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={11} className="text-center py-12 text-sm text-muted-foreground">
                      Khách sạn này chưa được cấu hình loại phòng nào.
                    </TableCell>
                  </TableRow>
                ) : (
                  hotel.rooms.map((room) => (
                    <TableRow key={room.id} className="hover:bg-muted/30">
                      <TableCell className="pl-6">
                        <div>
                          <span className="font-bold text-xs block">{room.roomType}</span>
                          <span className="text-[10px] text-muted-foreground font-semibold">Mã phòng: #{room.id}</span>
                        </div>
                      </TableCell>
                      <TableCell className="text-xs font-semibold">{room.capacity} khách</TableCell>
                      <TableCell className="text-xs font-bold">{formatCurrency(room.pricePerNight)}</TableCell>
                      <TableCell className="text-xs">{room.commissionRate}%</TableCell>
                      <TableCell className="text-xs">
                        <p className="font-bold">{room.bookedRoomQty} phòng</p>
                        <p className="text-[10px] text-muted-foreground">{room.bookingCount} lượt đặt</p>
                      </TableCell>
                      <TableCell className="text-xs font-bold">{formatCurrency(room.totalRevenue)}</TableCell>
                      <TableCell className="text-xs font-bold text-emerald-600 dark:text-emerald-400">
                        {formatCurrency(room.totalProfit)}
                      </TableCell>
                      <TableCell className="text-xs font-bold">{room.availableQty} phòng</TableCell>
                      <TableCell>
                        {room.imageUrls.length > 0 ? (
                          <div className="flex items-center gap-1">
                            <div className="flex -space-x-2">
                              {room.imageUrls.slice(0, 3).map((url, i) => (
                                <div key={url + i} className="relative h-8 w-8 rounded-full border-2 border-background overflow-hidden bg-muted">
                                  <Image
                                    src={url}
                                    alt=""
                                    fill
                                    sizes="32px"
                                    className="object-cover"
                                  />
                                </div>
                              ))}
                            </div>
                            <span className="text-[10px] text-muted-foreground font-bold pl-1">{room.imageUrls.length} ảnh</span>
                          </div>
                        ) : (
                          <span className="text-[10px] text-muted-foreground font-semibold">Chưa có</span>
                        )}
                      </TableCell>
                      <TableCell>
                        {room.availableQty > 0 ? (
                          <Badge variant="secondary" className="bg-emerald-500/10 text-emerald-600 dark:text-emerald-400">
                            Đang bán
                          </Badge>
                        ) : (
                          <Badge variant="outline">Tạm dừng</Badge>
                        )}
                      </TableCell>
                      <TableCell className="pr-6 text-right">
                        <Button
                          size="sm"
                          variant="ghost"
                          onClick={() => beginEditRoom(room)}
                          className="h-8 text-xs cursor-pointer gap-1"
                        >
                          <Edit2 className="h-3.5 w-3.5" /> Chỉnh sửa
                        </Button>
                      </TableCell>
                    </TableRow>
                  ))
                )}
              </TableBody>
            </Table>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
