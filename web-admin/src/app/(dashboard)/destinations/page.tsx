"use client";

import { useEffect, useMemo, useState } from 'react';
import { useAdminSearch } from '@/contexts/AdminSearchContext';
import {
  adminService,
  type AdminDestination,
  type AdminDestinationRequest,
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
import { Switch } from "@/components/ui/switch";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import {
  MapPin,
  Flame,
  Plus,
  Trash2,
  Edit2,
  Upload,
  Download,
  ImageIcon,
} from 'lucide-react';
import Image from 'next/image';
import { ConfirmDialog } from '@/components/ui/confirm-dialog';

const initialForm: AdminDestinationRequest = {
  name: '',
  description: '',
  coverImageUrl: '',
  isHot: false,
};

export default function DestinationsAdminPage() {
  const { query } = useAdminSearch();
  const [destinations, setDestinations] = useState<AdminDestination[]>([]);
  const [loading, setLoading] = useState(true);
  const [editingDestination, setEditingDestination] = useState<AdminDestination | null>(null);
  const [form, setForm] = useState<AdminDestinationRequest>(initialForm);
  const [submitting, setSubmitting] = useState(false);
  const [uploadingCover, setUploadingCover] = useState(false);
  const [deleteConfirmOpen, setDeleteConfirmOpen] = useState(false);
  const [destinationToDelete, setDestinationToDelete] = useState<AdminDestination | null>(null);

  const loadDestinations = async () => {
    try {
      const data = await adminService.getDestinations();
      setDestinations(data);
    } catch (error: any) {
      toast.error('Không thể tải điểm đến: ' + (error?.message || 'Lỗi kết nối'));
    }
  };

  useEffect(() => {
    const fetchData = async () => {
      setLoading(true);
      await loadDestinations();
      setLoading(false);
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

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (form.name.trim().length === 0) {
      toast.warning('Vui lòng điền tên điểm đến.');
      return;
    }

    setSubmitting(true);

    try {
      if (editingDestination) {
        await adminService.updateDestination(editingDestination.id, form);
        toast.success('Đã cập nhật điểm đến thành công');
      } else {
        await adminService.createDestination(form);
        toast.success('Đã tạo điểm đến mới thành công');
      }

      await loadDestinations();
      setEditingDestination(null);
      setForm(initialForm);
    } catch (error: any) {
      toast.error('Không thể lưu điểm đến: ' + (error?.message || 'Có lỗi xảy ra'));
    } finally {
      setSubmitting(false);
    }
  };

  const handleDelete = (destination: AdminDestination) => {
    setDestinationToDelete(destination);
    setDeleteConfirmOpen(true);
  };

  const handleConfirmDelete = async () => {
    if (!destinationToDelete) return;
    try {
      await adminService.deleteDestination(destinationToDelete.id);
      await loadDestinations();
      toast.success('Đã xóa điểm đến thành công');
    } catch (error: any) {
      toast.error('Không thể xóa điểm đến: ' + (error?.message || 'Có lỗi xảy ra'));
    } finally {
      setDestinationToDelete(null);
    }
  };

  const handleCoverUpload = async (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (!file) return;

    setUploadingCover(true);
    try {
      const result = await adminService.uploadDestinationCoverImage(file);
      setForm((current) => ({ ...current, coverImageUrl: result.imageUrl }));
      toast.success('Đã tải ảnh cover lên thành công');
    } catch (error: any) {
      toast.error('Tải ảnh cover thất bại: ' + (error?.message || 'Có lỗi xảy ra'));
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
      { key: 'name', header: 'Điểm đến' },
      { key: 'description', header: 'Mô tả' },
      { key: 'hotelCount', header: 'Khách sạn' },
      { key: 'tripCount', header: 'Chuyến đi' },
      { key: 'isHot', header: 'Nổi bật' },
    ]);
    toast.success('Xuất file CSV danh sách điểm đến thành công');
  };

  if (loading && destinations.length === 0) {
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
          <span className="text-xs font-bold uppercase tracking-wider text-primary">Catalog địa lý</span>
          <h1 className="text-3xl font-extrabold tracking-tight mt-1">Danh mục điểm đến</h1>
          <p className="text-muted-foreground text-sm mt-2">
            Định nghĩa các tỉnh thành du lịch, gắn cờ điểm đến nổi bật (Hot) và cập nhật hình ảnh giới thiệu vùng miền.
          </p>
        </div>
        <Button variant="outline" size="sm" onClick={exportDestinations} className="gap-1.5 cursor-pointer">
          <Download className="h-4 w-4" /> Xuất CSV
        </Button>
      </div>

      {/* Metrics Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <MetricCard
          title="Tổng số điểm đến"
          value={`${destinations.length} địa điểm`}
          description="Các tỉnh thành đang khai thác"
          icon={<MapPin className="h-4 w-4" />}
          theme="muted"
        />

        <MetricCard
          title="Điểm đến nổi bật (Hot)"
          value={`${hotCount} địa điểm`}
          description="Đánh dấu quảng bá đặc biệt"
          icon={<Flame className="h-4 w-4" />}
          theme="amber"
        />

        <MetricCard
          title="Khớp tìm kiếm"
          value={`${filteredDestinations.length} địa điểm`}
          description="Theo bộ lọc tìm kiếm hiện tại"
          icon={<MapPin className="h-4 w-4" />}
          theme="sky"
        />
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
        {/* CRUD Form */}
        <div className="lg:col-span-8">
          <Card>
            <CardHeader className="flex flex-row items-center justify-between">
              <div>
                <CardTitle className="text-lg font-bold">
                  {editingDestination ? 'Chỉnh sửa điểm đến' : 'Tạo mới điểm đến'}
                </CardTitle>
                <CardDescription>Cập nhật tên gọi, mô tả tóm tắt giới thiệu và ảnh đại diện điểm đến.</CardDescription>
              </div>
              {editingDestination && (
                <Button
                  variant="outline"
                  size="sm"
                  onClick={() => {
                    setEditingDestination(null);
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
                    <Label htmlFor="dest-name">Tên điểm đến</Label>
                    <Input
                      id="dest-name"
                      value={form.name}
                      onChange={(e) => setForm((c) => ({ ...c, name: e.target.value }))}
                      placeholder="Ví dụ: Sa Pa, Vịnh Hạ Long..."
                      required
                    />
                  </div>

                  <div className="flex items-center space-x-2 pt-8">
                    <Switch
                      id="dest-hot"
                      checked={form.isHot}
                      onCheckedChange={(checked) => setForm((c) => ({ ...c, isHot: checked }))}
                    />
                    <Label htmlFor="dest-hot" className="font-bold flex items-center gap-1">
                      Điểm du lịch Hot <Flame className="h-4 w-4 text-amber-500" />
                    </Label>
                  </div>
                </div>

                <div className="grid gap-2">
                  <Label>Ảnh nền cover (URL hoặc Tải lên)</Label>
                  <div className="flex gap-2">
                    <Input
                      value={form.coverImageUrl}
                      onChange={(e) => setForm((c) => ({ ...c, coverImageUrl: e.target.value }))}
                      placeholder="https://..."
                      className="flex-1"
                    />
                    <Label className="cursor-pointer inline-flex items-center justify-center rounded-lg border border-input bg-background px-3 text-xs font-semibold shadow-xs hover:bg-accent hover:text-accent-foreground select-none h-9">
                      {uploadingCover ? 'Đang tải...' : 'Upload'}
                      <input
                        type="file"
                        accept="image/*"
                        disabled={uploadingCover}
                        onChange={handleCoverUpload}
                        className="hidden"
                      />
                    </Label>
                  </div>
                </div>

                {hasCoverPreview && (
                  <div className="relative h-44 w-full rounded-lg overflow-hidden border mt-2">
                    <Image
                      src={form.coverImageUrl}
                      alt="Cover Preview"
                      fill
                      className="object-cover"
                    />
                  </div>
                )}

                <div className="grid gap-2">
                  <Label htmlFor="dest-desc">Mô tả giới thiệu điểm đến</Label>
                  <Textarea
                    id="dest-desc"
                    value={form.description}
                    onChange={(e) => setForm((c) => ({ ...c, description: e.target.value }))}
                    placeholder="Mô tả tóm tắt vẻ đẹp, khí hậu, các hoạt động vui chơi du lịch đặc trưng..."
                    rows={4}
                  />
                </div>

                <div className="flex justify-end gap-2 pt-2 border-t">
                  <Button type="submit" disabled={submitting} className="cursor-pointer">
                    {submitting ? 'Đang lưu...' : editingDestination ? 'Lưu thay đổi' : 'Tạo điểm đến'}
                  </Button>
                </div>
              </form>
            </CardContent>
          </Card>
        </div>

        {/* Small preview card */}
        <div className="lg:col-span-4">
          <Card className="h-full flex flex-col justify-between overflow-hidden">
            <div className="relative h-48 bg-muted border-b flex items-center justify-center">
              {hasCoverPreview ? (
                <Image
                  src={form.coverImageUrl}
                  alt=""
                  fill
                  className="object-cover"
                />
              ) : (
                <ImageIcon className="h-10 w-10 text-muted-foreground" />
              )}
              {form.isHot && (
                <Badge className="absolute left-3 top-3 bg-amber-500 text-white font-bold gap-1 border-none shadow-sm">
                  <Flame className="h-3.5 w-3.5 fill-current" /> HOT
                </Badge>
              )}
            </div>
            <CardContent className="pt-4 flex-1 flex flex-col justify-between">
              <div className="space-y-2">
                <h3 className="font-extrabold text-sm">{form.name || 'Tên điểm du lịch'}</h3>
                <p className="text-xs text-muted-foreground line-clamp-3 leading-relaxed">
                  {form.description || 'Chưa có mô tả chi tiết cho điểm đến này.'}
                </p>
              </div>
              <div className="text-[10px] text-muted-foreground font-semibold pt-4">
                * Xem trước cách hiển thị thẻ địa điểm trên ứng dụng di động Smart Trip.
              </div>
            </CardContent>
          </Card>
        </div>
      </div>

      {/* Destinations List Table */}
      <Card>
        <CardContent className="p-0">
          <div className="overflow-x-auto">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead className="pl-6">Điểm du lịch</TableHead>
                  <TableHead>Mô tả chi tiết</TableHead>
                  <TableHead className="text-center">Số khách sạn</TableHead>
                  <TableHead className="text-center">Chuyến xe</TableHead>
                  <TableHead className="text-center">Trạng thái Hot</TableHead>
                  <TableHead className="pr-6 text-right">Thao tác</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {filteredDestinations.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={6} className="text-center py-12 text-sm text-muted-foreground">
                      Không tìm thấy điểm đến du lịch nào.
                    </TableCell>
                  </TableRow>
                ) : (
                  filteredDestinations.map((d) => (
                    <TableRow key={d.id} className="hover:bg-muted/30">
                      <TableCell className="pl-6 py-4">
                        <div className="flex items-center gap-2.5">
                          <div className="relative h-10 w-14 bg-muted rounded-md overflow-hidden border shrink-0">
                            {d.coverImageUrl && (
                              <Image
                                src={d.coverImageUrl}
                                alt=""
                                fill
                                sizes="60px"
                                className="object-cover"
                              />
                            )}
                          </div>
                          <span className="font-extrabold text-xs text-primary">{d.name}</span>
                        </div>
                      </TableCell>
                      <TableCell className="max-w-[300px]">
                        <p className="text-xs text-muted-foreground truncate">{d.description || '--'}</p>
                      </TableCell>
                      <TableCell className="text-center text-xs font-semibold">
                        {d.hotelCount} đối tác
                      </TableCell>
                      <TableCell className="text-center text-xs font-semibold">
                        {d.tripCount} chuyến
                      </TableCell>
                      <TableCell className="text-center">
                        {d.isHot ? (
                          <Badge className="bg-amber-500/10 text-amber-600 dark:text-amber-400 border-none font-bold gap-0.5">
                            <Flame className="h-3 w-3 fill-current" /> Hot
                          </Badge>
                        ) : (
                          <Badge variant="outline" className="text-muted-foreground">
                            Bình thường
                          </Badge>
                        )}
                      </TableCell>
                      <TableCell className="pr-6 text-right">
                        <div className="flex justify-end gap-1.5">
                          <Button
                            size="sm"
                            variant="ghost"
                            onClick={() => startEdit(d)}
                            className="h-8 w-8 p-0 cursor-pointer"
                          >
                            <Edit2 className="h-3.5 w-3.5 text-muted-foreground" />
                          </Button>
                          <Button
                            size="sm"
                            variant="ghost"
                            onClick={() => handleDelete(d)}
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
        </CardContent>
      </Card>

      <ConfirmDialog
        isOpen={deleteConfirmOpen}
        title="Xóa điểm du lịch?"
        description={destinationToDelete ? `Bạn có chắc chắn muốn xóa điểm đến ${destinationToDelete.name}? Điều này sẽ ảnh hưởng tới khách sạn và lịch xe liên quan.` : ""}
        onConfirm={handleConfirmDelete}
        onClose={() => setDeleteConfirmOpen(false)}
      />
    </div>
  );
}
