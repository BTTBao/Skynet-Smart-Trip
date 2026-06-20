"use client";

import { useEffect, useMemo, useState } from 'react';
import { useRouter } from 'next/navigation';
import { useAdminSearch } from '@/contexts/AdminSearchContext';
import {
  adminService,
  type AdminDestination,
  type AdminHotel,
  type AdminHotelRequest,
} from '@/services/adminService';
import { downloadCsv } from '@/utils/adminActions';
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
import { MetricCard } from "@/components/ui/metric-card";
import { Badge } from "@/components/ui/badge";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Switch } from "@/components/ui/switch";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import {
  Hotel,
  MapPin,
  Download,
  Plus,
  Edit2,
  Eye,
  Star,
  DollarSign,
  Briefcase,
} from 'lucide-react';

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
  const router = useRouter();
  const { query } = useAdminSearch();
  const [hotels, setHotels] = useState<AdminHotel[]>([]);
  const [destinations, setDestinations] = useState<AdminDestination[]>([]);
  const [loading, setLoading] = useState(true);
  const [editingHotel, setEditingHotel] = useState<AdminHotel | null>(null);
  const [form, setForm] = useState<AdminHotelRequest>(initialForm);
  const [submitting, setSubmitting] = useState(false);

  const loadHotels = async () => {
    try {
      const [hotelData, destinationData] = await Promise.all([
        adminService.getHotels(),
        adminService.getDestinations(),
      ]);
      setHotels(hotelData);
      setDestinations(destinationData);
    } catch (error: any) {
      toast.error('Không thể tải dữ liệu khách sạn: ' + (error?.message || 'Lỗi kết nối'));
    }
  };

  useEffect(() => {
    const fetchData = async () => {
      setLoading(true);
      await loadHotels();
      setLoading(false);
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

  const totalHotelRevenue = useMemo(
    () => filteredHotels.reduce((sum, hotel) => sum + hotel.totalRevenue, 0),
    [filteredHotels]
  );

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (form.destinationId === 0) {
      toast.warning('Vui lòng chọn điểm đến cho khách sạn.');
      return;
    }

    setSubmitting(true);

    try {
      if (editingHotel) {
        await adminService.updateHotel(editingHotel.id, form);
        await loadHotels();
        setEditingHotel(null);
        setForm(initialForm);
        toast.success('Đã cập nhật khách sạn thành công');
      } else {
        const createdHotel = await adminService.createHotel(form);
        toast.success('Đã tạo khách sạn thành công', {
          description: 'Hệ thống đang chuyển hướng tới cấu hình loại phòng.',
        });
        router.push(`/hotels/${createdHotel.id}`);
      }
    } catch (error: any) {
      toast.error('Không thể lưu khách sạn: ' + (error?.message || 'Có lỗi xảy ra'));
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

  const exportHotels = () => {
    downloadCsv('hotels.csv', filteredHotels, [
      { key: 'name', header: 'Khách sạn' },
      { key: 'destinationName', header: 'Điểm đến' },
      { key: 'address', header: 'Địa chỉ' },
      { key: 'starRating', header: 'Sao' },
      { key: 'roomCount', header: 'Loại phòng' },
      { key: 'availableRoomQty', header: 'Còn bán' },
      { key: 'totalRevenue', header: 'Doanh thu' },
    ]);
    toast.success('Đã xuất danh sách khách sạn');
  };

  if (loading && hotels.length === 0) {
    return (
      <div className="flex items-center justify-center h-full min-h-[50vh]">
        <div className="animate-spin rounded-full h-10 w-10 border-b-2 border-primary"></div>
      </div>
    );
  }

  return (
    <div className="px-4 lg:px-6 space-y-6">
      <div className="flex justify-between items-center gap-4 flex-wrap">
        <div>
          <span className="text-xs font-bold uppercase tracking-wider text-primary">Catalog quản trị</span>
          <h1 className="text-3xl font-extrabold tracking-tight mt-1">Khách sạn</h1>
          <p className="text-muted-foreground text-sm mt-2">
            Quản trị danh sách khách sạn và các dịch vụ phòng đi kèm trên hệ thống.
          </p>
        </div>
        <Button variant="outline" size="sm" onClick={exportHotels} className="gap-1.5 cursor-pointer">
          <Download className="h-4 w-4" /> Xuất CSV
        </Button>
      </div>

      {/* Stats and Revenues */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <MetricCard
          className="md:col-span-2"
          title="Tổng doanh thu khách sạn"
          value={formatCurrency(totalHotelRevenue)}
          description="Doanh số tích lũy từ các lượt đặt phòng thành công hiện tại."
          icon={<DollarSign className="h-4 w-4" />}
          theme="emerald"
        />

        <MetricCard
          title="Trạng thái dịch vụ"
          value={`${filteredHotels.length} đối tác`}
          description={`${filteredHotels.filter(h => h.isAvailable).length} hoạt động • ${filteredHotels.filter(h => !h.isAvailable).length} tạm dừng`}
          icon={<Briefcase className="h-4 w-4" />}
          theme="muted"
        />
      </div>

      {/* CRUD Form */}
      <Card>
        <CardHeader>
          <CardTitle className="text-lg font-bold">
            {editingHotel ? 'Cập nhật thông tin khách sạn' : 'Thêm khách sạn đối tác mới'}
          </CardTitle>
          <CardDescription>
            Tạo khách sạn trước, sau đó nhấn nút &ldquo;Chi tiết&rdquo; để cấu hình từng loại phòng và cập nhật giá bán.
          </CardDescription>
        </CardHeader>
        <CardContent>
          <form onSubmit={handleSubmit} className="space-y-4">
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              <div className="grid gap-2">
                <Label htmlFor="destinationId">Điểm đến</Label>
                <Select
                  value={String(form.destinationId)}
                  onValueChange={(val) => setForm((c) => ({ ...c, destinationId: Number(val) }))}
                >
                  <SelectTrigger id="destinationId">
                    <SelectValue placeholder="Chọn điểm đến" />
                  </SelectTrigger>
                  <SelectContent>
                    {destinations.map((d) => (
                      <SelectItem key={d.id} value={String(d.id)}>
                        {d.name}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>

              <div className="grid gap-2">
                <Label htmlFor="hotel-name">Tên khách sạn</Label>
                <Input
                  id="hotel-name"
                  value={form.name}
                  onChange={(e) => setForm((c) => ({ ...c, name: e.target.value }))}
                  placeholder="Ví dụ: Vinpearl Resort, InterContinental..."
                  required
                />
              </div>

              <div className="grid gap-2">
                <Label htmlFor="starRating">Xếp hạng sao (1 - 5)</Label>
                <Input
                  id="starRating"
                  type="number"
                  min={1}
                  max={5}
                  value={form.starRating}
                  onChange={(e) => setForm((c) => ({ ...c, starRating: Number(e.target.value) }))}
                  required
                />
              </div>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              <div className="grid gap-2 md:col-span-1">
                <Label htmlFor="address">Địa chỉ chi tiết</Label>
                <Input
                  id="address"
                  value={form.address}
                  onChange={(e) => setForm((c) => ({ ...c, address: e.target.value }))}
                  placeholder="Số nhà, tên đường, phường/xã..."
                  required
                />
              </div>
              <div className="grid gap-2 md:col-span-2">
                <Label htmlFor="description">Mô tả ngắn</Label>
                <Textarea
                  id="description"
                  value={form.description}
                  onChange={(e) => setForm((c) => ({ ...c, description: e.target.value }))}
                  placeholder="Thông tin giới thiệu về tiện ích khách sạn, hồ bơi, buffet ăn sáng..."
                  rows={2}
                />
              </div>
            </div>

            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pt-2">
              <div className="flex items-center space-x-2">
                <Switch
                  id="isAvailable"
                  checked={form.isAvailable}
                  onCheckedChange={(checked) => setForm((c) => ({ ...c, isAvailable: checked }))}
                />
                <Label htmlFor="isAvailable">Kích hoạt bán phòng trên hệ thống</Label>
              </div>

              <div className="flex gap-2 justify-end">
                {editingHotel && (
                  <Button
                    type="button"
                    variant="outline"
                    onClick={() => {
                      setEditingHotel(null);
                      setForm(initialForm);
                    }}
                    className="cursor-pointer"
                  >
                    Hủy sửa
                  </Button>
                )}
                <Button type="submit" disabled={submitting} className="cursor-pointer">
                  {submitting ? 'Đang lưu...' : editingHotel ? 'Lưu thay đổi' : 'Tạo & Cấu hình phòng'}
                </Button>
              </div>
            </div>
          </form>
        </CardContent>
      </Card>

      {/* Hotels Table */}
      <Card className="overflow-hidden">
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead className="pl-6">Khách sạn</TableHead>
              <TableHead>Địa điểm</TableHead>
              <TableHead>Địa chỉ</TableHead>
              <TableHead>Sao & Phòng</TableHead>
              <TableHead>Trạng thái</TableHead>
              <TableHead>Còn bán / Giá từ</TableHead>
              <TableHead>Doanh thu</TableHead>
              <TableHead className="pr-6 text-right">Thao tác</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {filteredHotels.length === 0 ? (
              <TableRow>
                <TableCell colSpan={8} className="text-center py-12 text-sm text-muted-foreground">
                  Không tìm thấy đối tác khách sạn nào phù hợp.
                </TableCell>
              </TableRow>
            ) : (
              filteredHotels.map((hotel) => (
                <TableRow key={hotel.id} className="hover:bg-muted/30">
                  <TableCell className="pl-6">
                    <div>
                      <span className="font-bold text-xs flex items-center gap-1">
                        <Hotel className="h-3.5 w-3.5 text-primary" /> {hotel.name}
                      </span>
                      <span className="text-[10px] text-muted-foreground font-semibold block mt-0.5 max-w-[200px] truncate">
                        {hotel.description || 'Chưa có mô tả'}
                      </span>
                    </div>
                  </TableCell>
                  <TableCell className="text-xs font-semibold">{hotel.destinationName}</TableCell>
                  <TableCell className="text-xs text-muted-foreground max-w-[150px] truncate">{hotel.address || 'Chưa có địa chỉ'}</TableCell>
                  <TableCell>
                    <div className="flex items-center gap-1 text-amber-500 text-xs font-bold">
                      <Star className="h-3 w-3 fill-current" /> {hotel.starRating} sao
                      <span className="text-muted-foreground font-normal">({hotel.roomCount} loại)</span>
                    </div>
                  </TableCell>
                  <TableCell>
                    {hotel.isAvailable ? (
                      <Badge variant="secondary" className="bg-emerald-500/10 text-emerald-600 dark:text-emerald-400">
                        Hoạt động
                      </Badge>
                    ) : (
                      <Badge variant="destructive" className="bg-destructive/10 text-destructive border-none">
                        Tạm dừng
                      </Badge>
                    )}
                  </TableCell>
                  <TableCell className="text-xs">
                    <p className="font-semibold text-muted-foreground">{hotel.availableRoomQty} phòng</p>
                    <p className="text-[10px] font-bold text-emerald-600 dark:text-emerald-400 mt-0.5">{formatCurrency(hotel.lowestPrice)}</p>
                  </TableCell>
                  <TableCell className="text-xs font-bold">{formatCurrency(hotel.totalRevenue)}</TableCell>
                  <TableCell className="pr-6 text-right">
                    <div className="flex items-center justify-end gap-1">
                      <Button
                        size="sm"
                        variant="ghost"
                        onClick={() => router.push(`/hotels/${hotel.id}`)}
                        className="h-8 text-xs cursor-pointer gap-1"
                      >
                        <Eye className="h-3.5 w-3.5" /> Chi tiết
                      </Button>
                      <Button
                        size="sm"
                        variant="ghost"
                        onClick={() => startEditing(hotel)}
                        className="h-8 w-8 p-0 cursor-pointer"
                      >
                        <Edit2 className="h-3.5 w-3.5 text-muted-foreground" />
                      </Button>
                    </div>
                  </TableCell>
                </TableRow>
              ))
            )}
          </TableBody>
        </Table>
      </Card>
    </div>
  );
}
