"use client";

import { useEffect, useMemo, useState } from 'react';
import { useAdminSearch } from '@/contexts/AdminSearchContext';
import {
  adminService,
  type AdminDestination,
  type AdminVehicleRentalOptionRequest,
  type AdminVehicleRentalShop,
  type AdminVehicleRentalShopRequest,
  type VehicleRentalType,
} from '@/services/adminService';
import { downloadCsv, getPageNumbers } from '@/utils/adminActions';
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
  Car,
  MapPin,
  Phone,
  Plus,
  Trash2,
  Edit2,
  Download,
  ImageIcon,
  ChevronLeft,
  ChevronRight,
  Bike,
} from 'lucide-react';
import Image from 'next/image';
import { ConfirmDialog } from '@/components/ui/confirm-dialog';

const PAGE_SIZE = 6;

const VEHICLE_TYPE_OPTIONS: Array<{ value: VehicleRentalType; label: string }> = [
  { value: 'ManualMotorbike', label: 'Xe số' },
  { value: 'Scooter', label: 'Xe tay ga' },
  { value: 'Car', label: 'Xe ô tô' },
  { value: 'MultiSeatCar', label: 'Xe nhiều chỗ' },
];

const createEmptyOption = (): AdminVehicleRentalOptionRequest => ({
  vehicleType: 'ManualMotorbike',
  maxSeats: null,
  pricePerDay: 0,
  isAvailable: true,
});

const initialForm: AdminVehicleRentalShopRequest = {
  name: '',
  phoneNumber: '',
  address: '',
  destinationId: 0,
  description: '',
  imageUrl: '',
  isActive: true,
  vehicleOptions: [createEmptyOption()],
};

const formatCurrency = (value: number) =>
  `${new Intl.NumberFormat('vi-VN').format(value)}đ`;

export default function VehicleRentalAdminPage() {
  const { query } = useAdminSearch();
  const [shops, setShops] = useState<AdminVehicleRentalShop[]>([]);
  const [destinations, setDestinations] = useState<AdminDestination[]>([]);
  const [loading, setLoading] = useState(true);
  const [currentPage, setCurrentPage] = useState(1);
  const [editingShop, setEditingShop] = useState<AdminVehicleRentalShop | null>(null);
  const [form, setForm] = useState<AdminVehicleRentalShopRequest>(initialForm);
  const [submitting, setSubmitting] = useState(false);
  const [uploadingImage, setUploadingImage] = useState(false);
  const [deleteConfirmOpen, setDeleteConfirmOpen] = useState(false);
  const [shopToDelete, setShopToDelete] = useState<AdminVehicleRentalShop | null>(null);

  const loadData = async () => {
    try {
      const destinationData = await adminService.getDestinations();
      setDestinations(destinationData);
    } catch (error: any) {
      toast.error('Không thể tải danh sách điểm đến: ' + (error?.message || 'Lỗi kết nối'));
    }

    try {
      const shopData = await adminService.getVehicleRentalShops();
      setShops(shopData);
    } catch (error: any) {
      toast.error('Không thể tải danh sách cửa hàng thuê xe: ' + (error?.message || 'Lỗi kết nối'));
    }
  };

  useEffect(() => {
    const fetchData = async () => {
      setLoading(true);
      await loadData();
      setLoading(false);
    };

    fetchData();
  }, []);

  const filteredShops = useMemo(() => {
    const keyword = query.trim().toLowerCase();
    return shops.filter((shop) =>
      keyword.length === 0 ||
      shop.name.toLowerCase().includes(keyword) ||
      shop.destinationName.toLowerCase().includes(keyword) ||
      shop.address.toLowerCase().includes(keyword) ||
      shop.phoneNumber.includes(keyword)
    );
  }, [shops, query]);

  useEffect(() => {
    setCurrentPage(1);
  }, [query]);

  const totalPages = Math.max(1, Math.ceil(filteredShops.length / PAGE_SIZE));
  const currentPageClamped = Math.min(currentPage, totalPages);
  const paginatedShops = filteredShops.slice((currentPageClamped - 1) * PAGE_SIZE, currentPageClamped * PAGE_SIZE);
  const pageNumbers = getPageNumbers(currentPageClamped, totalPages);

  const activeCount = shops.filter((shop) => shop.isActive).length;
  const hasImagePreview = form.imageUrl.trim().length > 0;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (form.destinationId === 0) {
      toast.warning('Vui lòng chọn điểm đến.');
      return;
    }

    if (form.name.trim().length === 0) {
      toast.warning('Vui lòng điền tên cửa hàng.');
      return;
    }

    if (form.vehicleOptions.length === 0) {
      toast.warning('Cần ít nhất một loại xe cho thuê.');
      return;
    }

    if (form.vehicleOptions.some((option) => option.pricePerDay <= 0)) {
      toast.warning('Giá thuê theo ngày phải lớn hơn 0.');
      return;
    }

    setSubmitting(true);

    try {
      if (editingShop) {
        await adminService.updateVehicleRentalShop(editingShop.id, form);
        toast.success('Đã cập nhật cửa hàng thuê xe thành công');
      } else {
        await adminService.createVehicleRentalShop(form);
        toast.success('Đã tạo cửa hàng thuê xe mới thành công');
      }

      await loadData();
      setEditingShop(null);
      setForm(initialForm);
    } catch (error: any) {
      toast.error('Không thể lưu cửa hàng: ' + (error?.message || 'Có lỗi xảy ra'));
    } finally {
      setSubmitting(false);
    }
  };

  const handleDelete = (shop: AdminVehicleRentalShop) => {
    setShopToDelete(shop);
    setDeleteConfirmOpen(true);
  };

  const handleConfirmDelete = async () => {
    if (!shopToDelete) return;

    try {
      await adminService.deleteVehicleRentalShop(shopToDelete.id);
      await loadData();
      if (editingShop?.id === shopToDelete.id) {
        setEditingShop(null);
        setForm(initialForm);
      }
      toast.success('Đã xóa cửa hàng thuê xe thành công');
    } catch (error: any) {
      toast.error('Không thể xóa cửa hàng: ' + (error?.message || 'Có lỗi xảy ra'));
    } finally {
      setShopToDelete(null);
    }
  };

  const handleImageUpload = async (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (!file) return;

    setUploadingImage(true);
    try {
      const result = await adminService.uploadVehicleRentalImage(file);
      setForm((current) => ({ ...current, imageUrl: result.imageUrl }));
      toast.success('Đã tải ảnh lên Firebase thành công');
    } catch (error: any) {
      toast.error('Tải ảnh thất bại: ' + (error?.message || 'Có lỗi xảy ra'));
    } finally {
      setUploadingImage(false);
      event.target.value = '';
    }
  };

  const startEdit = (shop: AdminVehicleRentalShop) => {
    setEditingShop(shop);
    setForm({
      name: shop.name,
      phoneNumber: shop.phoneNumber,
      address: shop.address,
      destinationId: shop.destinationId,
      description: shop.description,
      imageUrl: shop.imageUrl,
      isActive: shop.isActive,
      vehicleOptions: shop.vehicleOptions.length > 0
        ? shop.vehicleOptions.map((option) => ({
            vehicleType: option.vehicleType,
            maxSeats: option.maxSeats ?? null,
            pricePerDay: option.pricePerDay,
            isAvailable: option.isAvailable,
          }))
        : [createEmptyOption()],
    });
  };

  const updateOption = (
    index: number,
    patch: Partial<AdminVehicleRentalOptionRequest>
  ) => {
    setForm((current) => ({
      ...current,
      vehicleOptions: current.vehicleOptions.map((option, optionIndex) =>
        optionIndex === index ? { ...option, ...patch } : option
      ),
    }));
  };

  const addOption = () => {
    setForm((current) => ({
      ...current,
      vehicleOptions: [...current.vehicleOptions, createEmptyOption()],
    }));
  };

  const removeOption = (index: number) => {
    setForm((current) => ({
      ...current,
      vehicleOptions: current.vehicleOptions.filter((_, optionIndex) => optionIndex !== index),
    }));
  };

  const exportShops = () => {
    downloadCsv('vehicle-rental-shops.csv', filteredShops, [
      { key: 'name', header: 'Cửa hàng' },
      { key: 'destinationName', header: 'Điểm đến' },
      { key: 'phoneNumber', header: 'Số điện thoại' },
      { key: 'address', header: 'Địa chỉ' },
      { key: 'optionCount', header: 'Số loại xe' },
      { key: 'minPricePerDay', header: 'Giá từ' },
      { key: 'isActive', header: 'Hoạt động' },
    ]);
    toast.success('Xuất file CSV danh sách thuê xe thành công');
  };

  if (loading && shops.length === 0) {
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
          <span className="text-xs font-bold uppercase tracking-wider text-primary">Catalog dịch vụ</span>
          <h1 className="text-3xl font-extrabold tracking-tight mt-1">Thuê xe tự lái</h1>
          <p className="text-muted-foreground text-sm mt-2">
            Quản lý cửa hàng cho thuê xe máy, ô tô tự lái theo từng điểm đến du lịch.
          </p>
        </div>
        <Button variant="outline" size="sm" onClick={exportShops} className="gap-1.5 cursor-pointer">
          <Download className="h-4 w-4" /> Xuất CSV
        </Button>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <MetricCard
          title="Tổng cửa hàng"
          value={`${shops.length} đối tác`}
          description="Các cửa hàng thuê xe trên hệ thống"
          icon={<Car className="h-4 w-4" />}
          theme="muted"
        />

        <MetricCard
          title="Đang hoạt động"
          value={`${activeCount} cửa hàng`}
          description="Cửa hàng đang nhận khách thuê xe"
          icon={<Bike className="h-4 w-4" />}
          theme="emerald"
        />

        <MetricCard
          title="Khớp tìm kiếm"
          value={`${filteredShops.length} cửa hàng`}
          description="Theo bộ lọc tìm kiếm hiện tại"
          icon={<MapPin className="h-4 w-4" />}
          theme="sky"
        />
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
        <div className="lg:col-span-8">
          <Card>
            <CardHeader className="flex flex-row items-center justify-between">
              <div>
                <CardTitle className="text-lg font-bold">
                  {editingShop ? 'Chỉnh sửa cửa hàng' : 'Tạo mới cửa hàng thuê xe'}
                </CardTitle>
                <CardDescription>
                  Cập nhật thông tin liên hệ, điểm đến, ảnh đại diện và các loại xe cho thuê.
                </CardDescription>
              </div>
              {editingShop && (
                <Button
                  variant="outline"
                  size="sm"
                  onClick={() => {
                    setEditingShop(null);
                    setForm(initialForm);
                  }}
                  className="cursor-pointer"
                >
                  Hủy sửa
                </Button>
              )}
            </CardHeader>
            <CardContent>
              <form onSubmit={handleSubmit} className="space-y-4">
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div className="grid gap-2">
                    <Label htmlFor="shop-name">Tên cửa hàng</Label>
                    <Input
                      id="shop-name"
                      value={form.name}
                      onChange={(e) => setForm((c) => ({ ...c, name: e.target.value }))}
                      placeholder="Ví dụ: Anh Tuấn Thuê Xe Đà Lạt"
                      required
                    />
                  </div>

                  <div className="grid gap-2">
                    <Label htmlFor="shop-phone">Số điện thoại</Label>
                    <Input
                      id="shop-phone"
                      value={form.phoneNumber}
                      onChange={(e) => setForm((c) => ({ ...c, phoneNumber: e.target.value }))}
                      placeholder="0901234567"
                      required
                    />
                  </div>
                </div>

                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div className="grid gap-2">
                    <Label htmlFor="shop-destination">Điểm đến</Label>
                    <Select
                      value={form.destinationId > 0 ? String(form.destinationId) : undefined}
                      onValueChange={(value) => setForm((c) => ({ ...c, destinationId: Number(value) }))}
                    >
                      <SelectTrigger id="shop-destination" className="w-full">
                        <SelectValue placeholder={destinations.length === 0 ? 'Chưa có điểm đến' : 'Chọn điểm đến'} />
                      </SelectTrigger>
                      <SelectContent position="popper" className="z-[100]">
                        {destinations.map((destination) => (
                          <SelectItem key={destination.id} value={String(destination.id)}>
                            {destination.name}
                          </SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                  </div>

                  <div className="flex items-center space-x-2 pt-8">
                    <Switch
                      id="shop-active"
                      checked={form.isActive}
                      onCheckedChange={(checked) => setForm((c) => ({ ...c, isActive: checked }))}
                    />
                    <Label htmlFor="shop-active" className="font-bold">
                      Cửa hàng đang hoạt động
                    </Label>
                  </div>
                </div>

                <div className="grid gap-2">
                  <Label htmlFor="shop-address">Địa chỉ</Label>
                  <Input
                    id="shop-address"
                    value={form.address}
                    onChange={(e) => setForm((c) => ({ ...c, address: e.target.value }))}
                    placeholder="123 Đường 3 Tháng 2, Phường 1, Đà Lạt"
                    required
                  />
                </div>

                <div className="grid gap-2">
                  <Label>Ảnh cửa hàng (Upload Firebase)</Label>
                  <div className="flex gap-2">
                    <Input
                      value={form.imageUrl}
                      onChange={(e) => setForm((c) => ({ ...c, imageUrl: e.target.value }))}
                      placeholder="https://firebasestorage.googleapis.com/..."
                      className="flex-1"
                    />
                    <Label className="cursor-pointer inline-flex items-center justify-center rounded-lg border border-input bg-background px-3 text-xs font-semibold shadow-xs hover:bg-accent hover:text-accent-foreground select-none h-9">
                      {uploadingImage ? 'Đang tải...' : 'Upload'}
                      <input
                        type="file"
                        accept="image/*"
                        disabled={uploadingImage}
                        onChange={handleImageUpload}
                        className="hidden"
                      />
                    </Label>
                  </div>
                </div>

                {hasImagePreview && (
                  <div className="relative h-44 w-full rounded-lg overflow-hidden border mt-2">
                    <Image
                      src={form.imageUrl}
                      alt="Shop Preview"
                      fill
                      className="object-cover"
                    />
                  </div>
                )}

                <div className="grid gap-2">
                  <Label htmlFor="shop-desc">Mô tả dịch vụ</Label>
                  <Textarea
                    id="shop-desc"
                    value={form.description}
                    onChange={(e) => setForm((c) => ({ ...c, description: e.target.value }))}
                    placeholder="Cho thuê xe máy số, tay ga giá tốt, giao xe tận nơi..."
                    rows={3}
                  />
                </div>

                <div className="space-y-3 border-t pt-4">
                  <div className="flex items-center justify-between">
                    <Label className="text-sm font-bold">Loại xe cho thuê</Label>
                    <Button type="button" variant="outline" size="sm" onClick={addOption} className="gap-1 cursor-pointer">
                      <Plus className="h-3.5 w-3.5" /> Thêm loại xe
                    </Button>
                  </div>

                  {form.vehicleOptions.map((option, index) => (
                    <div key={index} className="grid grid-cols-1 md:grid-cols-12 gap-2 items-end p-3 rounded-lg border bg-muted/20">
                      <div className="md:col-span-3 grid gap-1.5">
                        <Label className="text-xs">Loại xe</Label>
                        <Select
                          value={option.vehicleType}
                          onValueChange={(value) =>
                            updateOption(index, { vehicleType: value as VehicleRentalType })
                          }
                        >
                          <SelectTrigger className="h-9">
                            <SelectValue />
                          </SelectTrigger>
                          <SelectContent>
                            {VEHICLE_TYPE_OPTIONS.map((typeOption) => (
                              <SelectItem key={typeOption.value} value={typeOption.value}>
                                {typeOption.label}
                              </SelectItem>
                            ))}
                          </SelectContent>
                        </Select>
                      </div>

                      <div className="md:col-span-2 grid gap-1.5">
                        <Label className="text-xs">Số chỗ</Label>
                        <Input
                          type="number"
                          min={1}
                          value={option.maxSeats ?? ''}
                          onChange={(e) =>
                            updateOption(index, {
                              maxSeats: e.target.value ? Number(e.target.value) : null,
                            })
                          }
                          placeholder="Tùy chọn"
                          className="h-9"
                        />
                      </div>

                      <div className="md:col-span-3 grid gap-1.5">
                        <Label className="text-xs">Giá / ngày (VNĐ)</Label>
                        <Input
                          type="number"
                          min={1}
                          value={option.pricePerDay || ''}
                          onChange={(e) =>
                            updateOption(index, { pricePerDay: Number(e.target.value) || 0 })
                          }
                          placeholder="120000"
                          className="h-9"
                          required
                        />
                      </div>

                      <div className="md:col-span-3 flex items-center gap-2 pb-1">
                        <Switch
                          checked={option.isAvailable}
                          onCheckedChange={(checked) => updateOption(index, { isAvailable: checked })}
                        />
                        <Label className="text-xs">Còn xe</Label>
                      </div>

                      <div className="md:col-span-1 flex justify-end">
                        <Button
                          type="button"
                          variant="ghost"
                          size="sm"
                          onClick={() => removeOption(index)}
                          disabled={form.vehicleOptions.length <= 1}
                          className="h-9 w-9 p-0 text-destructive hover:bg-destructive/10 cursor-pointer"
                        >
                          <Trash2 className="h-4 w-4" />
                        </Button>
                      </div>
                    </div>
                  ))}
                </div>

                <div className="flex justify-end gap-2 pt-2 border-t">
                  <Button type="submit" disabled={submitting} className="cursor-pointer">
                    {submitting ? 'Đang lưu...' : editingShop ? 'Lưu thay đổi' : 'Tạo cửa hàng'}
                  </Button>
                </div>
              </form>
            </CardContent>
          </Card>
        </div>

        <div className="lg:col-span-4">
          <Card className="h-full flex flex-col justify-between overflow-hidden">
            <div className="relative h-48 bg-muted border-b flex items-center justify-center">
              {hasImagePreview ? (
                <Image
                  src={form.imageUrl}
                  alt=""
                  fill
                  className="object-cover"
                />
              ) : (
                <ImageIcon className="h-10 w-10 text-muted-foreground" />
              )}
              {!form.isActive && (
                <Badge className="absolute left-3 top-3 bg-muted-foreground text-white font-bold border-none shadow-sm">
                  Tạm dừng
                </Badge>
              )}
            </div>
            <CardContent className="pt-4 flex-1 flex flex-col justify-between">
              <div className="space-y-2">
                <h3 className="font-extrabold text-sm">{form.name || 'Tên cửa hàng'}</h3>
                <p className="text-xs text-muted-foreground flex items-center gap-1">
                  <Phone className="h-3 w-3" /> {form.phoneNumber || 'Chưa có SĐT'}
                </p>
                <p className="text-xs text-muted-foreground line-clamp-3 leading-relaxed">
                  {form.description || 'Chưa có mô tả dịch vụ.'}
                </p>
                <div className="flex flex-wrap gap-1 pt-1">
                  {form.vehicleOptions.map((option, index) => {
                    const label = VEHICLE_TYPE_OPTIONS.find((item) => item.value === option.vehicleType)?.label ?? option.vehicleType;
                    return (
                      <Badge key={index} variant="secondary" className="text-[10px]">
                        {label}
                        {option.pricePerDay > 0 ? ` • ${formatCurrency(option.pricePerDay)}` : ''}
                      </Badge>
                    );
                  })}
                </div>
              </div>
              <div className="text-[10px] text-muted-foreground font-semibold pt-4">
                * Xem trước cách hiển thị thẻ thuê xe trên ứng dụng Smart Trip.
              </div>
            </CardContent>
          </Card>
        </div>
      </div>

      <Card>
        <CardContent className="p-0">
          <div className="overflow-x-auto">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead className="pl-6">Ảnh</TableHead>
                  <TableHead>Cửa hàng</TableHead>
                  <TableHead>Điểm đến</TableHead>
                  <TableHead>Liên hệ</TableHead>
                  <TableHead>Loại xe</TableHead>
                  <TableHead className="text-right">Giá từ</TableHead>
                  <TableHead className="text-center">Trạng thái</TableHead>
                  <TableHead className="pr-6 text-right">Thao tác</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {filteredShops.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={8} className="text-center py-12 text-sm text-muted-foreground">
                      Không tìm thấy cửa hàng thuê xe nào.
                    </TableCell>
                  </TableRow>
                ) : (
                  paginatedShops.map((shop) => (
                    <TableRow key={shop.id} className="hover:bg-muted/30">
                      <TableCell className="pl-6 py-4">
                        <div className="relative h-10 w-14 bg-muted rounded-md overflow-hidden border shrink-0">
                          {shop.imageUrl ? (
                            <Image
                              src={shop.imageUrl}
                              alt={shop.name}
                              fill
                              sizes="60px"
                              className="object-cover"
                            />
                          ) : (
                            <div className="flex h-full w-full items-center justify-center">
                              <ImageIcon className="h-4 w-4 text-muted-foreground" />
                            </div>
                          )}
                        </div>
                      </TableCell>
                      <TableCell>
                        <div className="space-y-1">
                          <span className="font-extrabold text-xs text-primary block">{shop.name}</span>
                          <p className="text-[11px] text-muted-foreground line-clamp-1 max-w-[200px]">{shop.address}</p>
                        </div>
                      </TableCell>
                      <TableCell className="text-xs font-semibold">{shop.destinationName}</TableCell>
                      <TableCell className="text-xs">{shop.phoneNumber}</TableCell>
                      <TableCell>
                        <div className="flex flex-wrap gap-1 max-w-[180px]">
                          {shop.vehicleTypeLabels.map((label) => (
                            <Badge key={label} variant="outline" className="text-[10px] font-medium">
                              {label}
                            </Badge>
                          ))}
                        </div>
                      </TableCell>
                      <TableCell className="text-right text-xs font-bold">
                        {shop.minPricePerDay > 0 ? formatCurrency(shop.minPricePerDay) : '--'}
                      </TableCell>
                      <TableCell className="text-center">
                        {shop.isActive ? (
                          <Badge className="bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 border-none font-bold">
                            Hoạt động
                          </Badge>
                        ) : (
                          <Badge variant="outline" className="text-muted-foreground">
                            Tạm dừng
                          </Badge>
                        )}
                      </TableCell>
                      <TableCell className="pr-6 text-right">
                        <div className="flex justify-end gap-1.5">
                          <Button
                            size="sm"
                            variant="ghost"
                            onClick={() => startEdit(shop)}
                            className="h-8 w-8 p-0 cursor-pointer"
                          >
                            <Edit2 className="h-3.5 w-3.5 text-muted-foreground" />
                          </Button>
                          <Button
                            size="sm"
                            variant="ghost"
                            onClick={() => handleDelete(shop)}
                            className="h-8 w-8 p-0 text-destructive hover:bg-destructive/10 cursor-pointer"
                          >
                            <Trash2 className="h-3.5 w-3.5" />
                          </Button>
                        </div>
                      </TableCell>
                    </TableRow>
                  ))
                )}
              </TableBody>
            </Table>
          </div>

          <div className="flex items-center justify-between px-6 py-4 border-t">
            <Button
              size="sm"
              variant="outline"
              onClick={() => setCurrentPage((page) => Math.max(1, page - 1))}
              disabled={currentPageClamped === 1}
              className="gap-1 cursor-pointer h-8 text-xs"
            >
              <ChevronLeft className="h-3.5 w-3.5" /> Trước
            </Button>
            <div className="flex items-center gap-1.5">
              {pageNumbers.map((page) => (
                <Button
                  key={page}
                  size="sm"
                  variant={currentPageClamped === page ? 'default' : 'ghost'}
                  onClick={() => setCurrentPage(page)}
                  className="w-8 h-8 p-0 text-xs cursor-pointer"
                >
                  {page}
                </Button>
              ))}
            </div>
            <Button
              size="sm"
              variant="outline"
              onClick={() => setCurrentPage((page) => Math.min(totalPages, page + 1))}
              disabled={currentPageClamped === totalPages}
              className="gap-1 cursor-pointer h-8 text-xs"
            >
              Sau <ChevronRight className="h-3.5 w-3.5" />
            </Button>
          </div>
        </CardContent>
      </Card>

      <ConfirmDialog
        isOpen={deleteConfirmOpen}
        title="Xóa cửa hàng thuê xe?"
        description={
          shopToDelete
            ? `Bạn có chắc chắn muốn xóa ${shopToDelete.name}? Tất cả loại xe liên quan cũng sẽ bị xóa.`
            : ""
        }
        onConfirm={handleConfirmDelete}
        onClose={() => setDeleteConfirmOpen(false)}
      />
    </div>
  );
}
