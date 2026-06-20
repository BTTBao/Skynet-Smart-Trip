"use client";

import { useEffect, useMemo, useState } from 'react';
import { useAdminSearch } from '@/contexts/AdminSearchContext';
import {
  adminService,
  type AdminExplorePost,
  type AdminExplorePostRequest,
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
  Compass,
  MapPin,
  Eye,
  EyeOff,
  Heart,
  MessageSquare,
  Upload,
  Plus,
  Trash2,
  Edit2,
  Tag,
  Download,
  Info,
} from 'lucide-react';
import Image from 'next/image';
import { ConfirmDialog } from '@/components/ui/confirm-dialog';

const initialForm: AdminExplorePostRequest = {
  title: '',
  content: '',
  location: '',
  city: '',
  province: '',
  region: 'north',
  latitude: null,
  longitude: null,
  costLevel: 2,
  isVisible: true,
  imageUrls: [],
  tags: [],
};

const regionOptions = [
  { value: 'north', label: 'Miền Bắc' },
  { value: 'central', label: 'Miền Trung' },
  { value: 'south', label: 'Miền Nam' },
] as const;

export default function ExploreAdminPage() {
  const { query } = useAdminSearch();
  const [posts, setPosts] = useState<AdminExplorePost[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [editingPost, setEditingPost] = useState<AdminExplorePost | null>(null);
  const [form, setForm] = useState<AdminExplorePostRequest>(initialForm);
  const [imageDraft, setImageDraft] = useState('');
  const [tagDraft, setTagDraft] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const [uploading, setUploading] = useState(false);
  const [deleteConfirmOpen, setDeleteConfirmOpen] = useState(false);
  const [postToDelete, setPostToDelete] = useState<AdminExplorePost | null>(null);

  const hasExploreImages = form.imageUrls.length > 0;

  const loadPosts = async (search = query) => {
    const data = await adminService.getExplorePosts({ search: search.trim() || undefined });
    setPosts(data);
  };

  useEffect(() => {
    const fetchData = async () => {
      try {
        setLoading(true);
        await loadPosts();
        setError(null);
      } catch (err: any) {
        const msg = err?.message || 'Không thể kết nối máy chủ';
        setError(msg);
        toast.error('Không thể tải bài Explore: ' + msg);
      } finally {
        setLoading(false);
      }
    };

    fetchData();
  }, []);

  useEffect(() => {
    const handle = window.setTimeout(async () => {
      try {
        await loadPosts();
        setError(null);
      } catch (err: any) {
        toast.error('Tìm kiếm thất bại: ' + (err?.message || 'Có lỗi xảy ra'));
      }
    }, 300);

    return () => window.clearTimeout(handle);
  }, [query]);

  const visibleCount = posts.filter((post) => post.isVisible).length;
  const hiddenCount = posts.length - visibleCount;
  const totalInteractions = posts.reduce((sum, post) => sum + post.likes + post.saves + post.commentCount, 0);

  const filteredPosts = useMemo(() => {
    const keyword = query.trim().toLowerCase();
    return posts.filter((post) =>
      keyword.length === 0 ||
      post.title.toLowerCase().includes(keyword) ||
      post.location.toLowerCase().includes(keyword) ||
      post.province.toLowerCase().includes(keyword) ||
      post.tags.some((tag) => tag.toLowerCase().includes(keyword))
    );
  }, [posts, query]);

  const validationErrors = useMemo(() => {
    const errors: string[] = [];
    if (form.title.trim().length < 5) errors.push('Tiêu đề tối thiểu 5 ký tự.');
    if (form.content.trim().length < 10) errors.push('Nội dung tối thiểu 10 ký tự.');
    if (form.location.trim().length < 2) errors.push('Vị trí không được để trống.');
    if (form.costLevel < 1 || form.costLevel > 4) errors.push('Mức chi phí phải từ 1 đến 4.');
    return errors;
  }, [form]);

  const resetForm = () => {
    setEditingPost(null);
    setForm(initialForm);
    setImageDraft('');
    setTagDraft('');
  };

  const startEdit = (post: AdminExplorePost) => {
    setEditingPost(post);
    setForm({
      title: post.title,
      content: post.content,
      location: post.location,
      city: post.city,
      province: post.province,
      region: post.region,
      latitude: post.latitude ?? null,
      longitude: post.longitude ?? null,
      costLevel: post.costLevel,
      isVisible: post.isVisible,
      imageUrls: post.imageUrls,
      tags: post.tags,
    });
    setImageDraft('');
    setTagDraft('');
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (validationErrors.length > 0) {
      toast.warning(validationErrors[0]);
      return;
    }

    setSubmitting(true);
    try {
      if (editingPost) {
        await adminService.updateExplorePost(editingPost.id, form);
        toast.success('Đã cập nhật bài Explore thành công');
      } else {
        await adminService.createExplorePost(form);
        toast.success('Đã tạo bài Explore mới thành công');
      }

      await loadPosts('');
      resetForm();
    } catch (err: any) {
      toast.error('Không thể lưu bài Explore: ' + (err?.message || 'Có lỗi xảy ra'));
    } finally {
      setSubmitting(false);
    }
  };

  const handleToggleVisibility = async (post: AdminExplorePost) => {
    try {
      await adminService.updateExplorePostVisibility(post.id, !post.isVisible);
      await loadPosts();
      toast.success(post.isVisible ? 'Đã ẩn bài Explore' : 'Đã hiển thị bài Explore');
    } catch (err: any) {
      toast.error('Không thể cập nhật trạng thái hiển thị: ' + (err?.message || 'Lỗi'));
    }
  };

  const handleDelete = (post: AdminExplorePost) => {
    setPostToDelete(post);
    setDeleteConfirmOpen(true);
  };

  const handleConfirmDelete = async () => {
    if (!postToDelete) return;
    try {
      await adminService.deleteExplorePost(postToDelete.id);
      await loadPosts();
      if (editingPost?.id === postToDelete.id) resetForm();
      toast.success('Đã xóa bài viết Explore thành công');
    } catch (err: any) {
      toast.error('Không thể xóa bài viết: ' + (err?.message || 'Có lỗi xảy ra'));
    } finally {
      setPostToDelete(null);
    }
  };

  const addImageUrl = () => {
    const url = imageDraft.trim();
    if (!url || form.imageUrls.includes(url) || form.imageUrls.length >= 10) return;
    setForm((current) => ({ ...current, imageUrls: [...current.imageUrls, url] }));
    setImageDraft('');
  };

  const addTag = () => {
    const tag = tagDraft.trim();
    if (!tag || form.tags.some((t) => t.toLowerCase() === tag.toLowerCase()) || form.tags.length >= 20) return;
    setForm((current) => ({ ...current, tags: [...current.tags, tag] }));
    setTagDraft('');
  };

  const removeImage = (imageUrl: string) => {
    setForm((current) => ({
      ...current,
      imageUrls: current.imageUrls.filter((item) => item !== imageUrl),
    }));
  };

  const handleUploadImage = async (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (!file) return;

    setUploading(true);
    try {
      const result = await adminService.uploadExplorePostImage(file);
      setForm((current) => ({ ...current, imageUrls: [...current.imageUrls, result.imageUrl].slice(0, 10) }));
      toast.success('Đã tải ảnh lên thành công');
    } catch (err: any) {
      toast.error('Tải ảnh thất bại: ' + (err?.message || 'Lỗi kết nối'));
    } finally {
      setUploading(false);
      event.target.value = '';
    }
  };

  const exportPosts = () => {
    downloadCsv('explore-posts.csv', filteredPosts, [
      { key: 'title', header: 'Tiêu đề' },
      { key: 'location', header: 'Vị trí' },
      { key: 'province', header: 'Tỉnh/TP' },
      { key: 'authorName', header: 'Tác giả' },
      { key: 'views', header: 'Lượt xem' },
      { key: 'isVisible', header: 'Hiển thị' },
    ]);
    toast.success('Xuất file CSV bài viết thành công');
  };

  if (loading && posts.length === 0) {
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
          <span className="text-xs font-bold uppercase tracking-wider text-primary">Nội dung cộng đồng</span>
          <h1 className="text-3xl font-extrabold tracking-tight mt-1">Quản lý bài viết Explore</h1>
          <p className="text-muted-foreground text-sm mt-2">
            Điều chỉnh bài viết du lịch cộng đồng, gắn thẻ bài viết và điều phối hiển thị trên ứng dụng.
          </p>
        </div>
        <Button variant="outline" size="sm" onClick={exportPosts} className="gap-1.5 cursor-pointer">
          <Download className="h-4 w-4" /> Xuất CSV
        </Button>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <MetricCard
          title="Tổng số bài viết"
          value={posts.length}
          description="Bài đăng khám phá/chia sẻ"
          icon={<Compass className="h-4 w-4" />}
          theme="muted"
        />

        <MetricCard
          title="Đang hiển thị"
          value={visibleCount}
          description="Công khai trên ứng dụng"
          icon={<Eye className="h-4 w-4" />}
          theme="emerald"
        />

        <MetricCard
          title="Lưu ẩn"
          value={hiddenCount}
          description="Lưu nháp/tạm khóa hiển thị"
          icon={<EyeOff className="h-4 w-4" />}
          theme="amber"
        />

        <MetricCard
          title="Tổng tương tác"
          value={totalInteractions.toLocaleString()}
          description="Lượt thích và bình luận"
          icon={<Heart className="h-4 w-4" />}
          theme="sky"
        />
      </div>

      {/* CRUD Form */}
      <Card>
        <CardHeader className="flex flex-row items-center justify-between">
          <div>
            <CardTitle className="text-lg font-bold">
              {editingPost ? 'Cập nhật bài viết' : 'Viết bài viết Explore mới'}
            </CardTitle>
            <CardDescription>Nhập chi tiết về địa điểm nổi tiếng, vùng miền và chèn ảnh minh họa.</CardDescription>
          </div>
          {editingPost && (
            <Button variant="outline" size="sm" onClick={resetForm} className="cursor-pointer">
              Hủy sửa
            </Button>
          )}
        </CardHeader>
        <CardContent>
          <form onSubmit={handleSubmit} className="space-y-4">
            <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
              <div className="grid gap-2 md:col-span-2">
                <Label htmlFor="post-title">Tiêu đề bài viết</Label>
                <Input
                  id="post-title"
                  value={form.title}
                  onChange={(e) => setForm((c) => ({ ...c, title: e.target.value }))}
                  placeholder="Ví dụ: Review 3 ngày 2 đêm tại Hà Giang..."
                  required
                />
              </div>

              <div className="grid gap-2">
                <Label htmlFor="post-location">Địa điểm (Vị trí)</Label>
                <Input
                  id="post-location"
                  value={form.location}
                  onChange={(e) => setForm((c) => ({ ...c, location: e.target.value }))}
                  placeholder="Ví dụ: Cột cờ Lũng Cú"
                  required
                />
              </div>

              <div className="grid gap-2">
                <Label htmlFor="post-province">Tỉnh / Thành phố</Label>
                <Input
                  id="post-province"
                  value={form.province}
                  onChange={(e) => setForm((c) => ({ ...c, province: e.target.value }))}
                  placeholder="Ví dụ: Hà Giang"
                />
              </div>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
              <div className="grid gap-2">
                <Label htmlFor="post-city">Slug thành phố</Label>
                <Input
                  id="post-city"
                  value={form.city}
                  onChange={(e) => setForm((c) => ({ ...c, city: e.target.value }))}
                  placeholder="ha-giang"
                />
              </div>

              <div className="grid gap-2">
                <Label htmlFor="post-region">Vùng miền</Label>
                <Select
                  value={form.region}
                  onValueChange={(val) => setForm((c) => ({ ...c, region: val as any }))}
                >
                  <SelectTrigger id="post-region">
                    <SelectValue placeholder="Chọn vùng miền" />
                  </SelectTrigger>
                  <SelectContent>
                    {regionOptions.map((r) => (
                      <SelectItem key={r.value} value={r.value}>
                        {r.label}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>

              <div className="grid gap-2">
                <Label htmlFor="post-lat">Vĩ độ (Latitude)</Label>
                <Input
                  id="post-lat"
                  type="number"
                  step="any"
                  value={form.latitude ?? ''}
                  onChange={(e) => setForm((c) => ({ ...c, latitude: e.target.value === '' ? null : Number(e.target.value) }))}
                  placeholder="23.364"
                />
              </div>

              <div className="grid gap-2">
                <Label htmlFor="post-lng">Kinh độ (Longitude)</Label>
                <Input
                  id="post-lng"
                  type="number"
                  step="any"
                  value={form.longitude ?? ''}
                  onChange={(e) => setForm((c) => ({ ...c, longitude: e.target.value === '' ? null : Number(e.target.value) }))}
                  placeholder="105.297"
                />
              </div>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
              <div className="grid gap-2">
                <Label htmlFor="post-cost">Mức chi phí</Label>
                <Select
                  value={String(form.costLevel)}
                  onValueChange={(val) => setForm((c) => ({ ...c, costLevel: Number(val) }))}
                >
                  <SelectTrigger id="post-cost">
                    <SelectValue placeholder="Mức chi phí" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="1">Tiết kiệm</SelectItem>
                    <SelectItem value="2">Trung bình</SelectItem>
                    <SelectItem value="3">Cao cấp</SelectItem>
                    <SelectItem value="4">Sang trọng</SelectItem>
                  </SelectContent>
                </Select>
              </div>

              <div className="flex items-center space-x-2 pt-8">
                <Switch
                  id="post-visible"
                  checked={form.isVisible}
                  onCheckedChange={(checked) => setForm((c) => ({ ...c, isVisible: checked }))}
                />
                <Label htmlFor="post-visible">Hiện bài viết</Label>
              </div>
            </div>

            <div className="grid gap-2">
              <Label htmlFor="post-content">Nội dung bài viết</Label>
              <Textarea
                id="post-content"
                value={form.content}
                onChange={(e) => setForm((c) => ({ ...c, content: e.target.value }))}
                placeholder="Chia sẻ kinh nghiệm du lịch, những lưu ý, quán ăn ngon tại điểm đến..."
                rows={6}
                required
              />
            </div>

            {/* Photos & Tags grids */}
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              {/* Photo Album */}
              <div className="space-y-3 p-4 rounded-xl border bg-muted/20">
                <div className="flex justify-between items-center">
                  <span className="text-xs font-bold text-muted-foreground">Album ảnh (tối đa 10)</span>
                  <div className="flex gap-2">
                    <Label className="cursor-pointer inline-flex items-center justify-center rounded-lg border bg-background px-3 h-8 text-xs font-semibold hover:bg-accent select-none shadow-xs">
                      <Upload className="h-3 w-3 mr-1" /> {uploading ? 'Đang tải...' : 'Upload'}
                      <input
                        type="file"
                        accept="image/*"
                        disabled={uploading || form.imageUrls.length >= 10}
                        onChange={handleUploadImage}
                        className="hidden"
                      />
                    </Label>
                  </div>
                </div>

                <div className="flex gap-2">
                  <Input
                    value={imageDraft}
                    onChange={(e) => setImageDraft(e.target.value)}
                    placeholder="Nhập link ảnh ngoài..."
                    className="h-8 text-xs"
                  />
                  <Button type="button" variant="outline" size="sm" onClick={addImageUrl} className="h-8 cursor-pointer">
                    Thêm link
                  </Button>
                </div>

                {hasExploreImages ? (
                  <div className="grid grid-cols-4 gap-2 mt-2">
                    {form.imageUrls.map((url, idx) => (
                      <div key={url + idx} className="relative aspect-square rounded-md overflow-hidden bg-muted group border">
                        <Image
                          src={url}
                          alt=""
                          fill
                          sizes="80px"
                          className="object-cover"
                        />
                        <button
                          type="button"
                          onClick={() => removeImage(url)}
                          className="absolute right-0.5 top-0.5 bg-black/60 text-white rounded-full p-1 opacity-0 group-hover:opacity-100 transition-opacity"
                        >
                          <Trash2 className="h-2.5 w-2.5" />
                        </button>
                      </div>
                    ))}
                  </div>
                ) : (
                  <div className="text-center py-6 text-xs text-muted-foreground border border-dashed rounded-lg">
                    Chưa có ảnh nào được chọn
                  </div>
                )}
              </div>

              {/* Tags Grid */}
              <div className="space-y-3 p-4 rounded-xl border bg-muted/20">
                <span className="text-xs font-bold text-muted-foreground block">Hashtags / Nhãn đính kèm</span>
                <div className="flex gap-2">
                  <Input
                    value={tagDraft}
                    onChange={(e) => setTagDraft(e.target.value)}
                    placeholder="Ví dụ: dalat, phuot, chill..."
                    className="h-8 text-xs"
                  />
                  <Button type="button" variant="outline" size="sm" onClick={addTag} className="h-8 cursor-pointer">
                    Thêm tag
                  </Button>
                </div>

                <div className="flex flex-wrap gap-1.5 mt-2 min-h-[48px] content-start">
                  {form.tags.map((tag) => (
                    <Badge key={tag} variant="secondary" className="gap-1 pr-1.5 py-0.5 text-[10px]">
                      #{tag}
                      <button
                        type="button"
                        onClick={() => setForm((c) => ({ ...c, tags: c.tags.filter((t) => t !== tag) }))}
                        className="text-muted-foreground hover:text-foreground font-bold"
                      >
                        ×
                      </button>
                    </Badge>
                  ))}
                  {form.tags.length === 0 && (
                    <span className="text-xs text-muted-foreground italic">Chưa gắn tag nào</span>
                  )}
                </div>
              </div>
            </div>

            <div className="flex justify-end gap-2 pt-2 border-t">
              <Button type="submit" disabled={submitting} className="cursor-pointer">
                {submitting ? 'Đang lưu...' : editingPost ? 'Lưu thay đổi' : 'Đăng bài viết'}
              </Button>
            </div>
          </form>
        </CardContent>
      </Card>

      {/* Explore Posts list */}
      <Card>
        <CardContent className="p-0">
          <div className="overflow-x-auto">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead className="pl-6">Bài viết</TableHead>
                  <TableHead>Địa điểm</TableHead>
                  <TableHead>Thống kê tương tác</TableHead>
                  <TableHead>Trạng thái</TableHead>
                  <TableHead className="pr-6 text-right">Thao tác</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {filteredPosts.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={5} className="text-center py-12 text-sm text-muted-foreground">
                      Không có bài viết Explore nào phù hợp với tìm kiếm.
                    </TableCell>
                  </TableRow>
                ) : (
                  filteredPosts.map((post) => (
                    <TableRow key={post.id} className="hover:bg-muted/30">
                      <TableCell className="pl-6 py-4">
                        <div className="flex items-center gap-3">
                          <div className="relative h-14 w-20 bg-muted rounded-md overflow-hidden border shrink-0">
                            {post.thumbnailUrl && (
                              <Image
                                src={post.thumbnailUrl}
                                alt=""
                                fill
                                sizes="80px"
                                className="object-cover"
                              />
                            )}
                          </div>
                          <div className="min-w-0">
                            <span className="font-bold text-xs block truncate max-w-[280px]">{post.title}</span>
                            <span className="text-[10px] text-muted-foreground font-semibold block mt-0.5">
                              Tác giả: {post.authorName} • {post.createdAt}
                            </span>
                            <div className="flex flex-wrap gap-1 mt-1.5">
                              {post.tags.slice(0, 3).map((tag) => (
                                <Badge key={tag} variant="outline" className="text-[9px] px-1.5 py-0">
                                  #{tag}
                                </Badge>
                              ))}
                            </div>
                          </div>
                        </div>
                      </TableCell>
                      <TableCell>
                        <div>
                          <p className="text-xs font-bold flex items-center gap-1">
                            <MapPin className="h-3 w-3 text-primary" /> {post.location}
                          </p>
                          <p className="text-[10px] text-muted-foreground font-semibold block mt-0.5">
                            {post.province} ({post.region})
                          </p>
                        </div>
                      </TableCell>
                      <TableCell>
                        <div className="flex items-center gap-3 text-xs text-muted-foreground font-semibold">
                          <span className="flex items-center gap-0.5"><Eye className="h-3.5 w-3.5" /> {post.views}</span>
                          <span className="flex items-center gap-0.5"><Heart className="h-3.5 w-3.5 text-rose-500" /> {post.likes}</span>
                          <span className="flex items-center gap-0.5"><MessageSquare className="h-3.5 w-3.5" /> {post.commentCount}</span>
                        </div>
                      </TableCell>
                      <TableCell>
                        {post.isVisible ? (
                          <Badge variant="secondary" className="bg-emerald-500/10 text-emerald-600 dark:text-emerald-400">
                            Đang hiển thị
                          </Badge>
                        ) : (
                          <Badge variant="outline">Đang ẩn</Badge>
                        )}
                      </TableCell>
                      <TableCell className="pr-6 text-right">
                        <div className="flex items-center justify-end gap-1">
                          <Button
                            size="sm"
                            variant="ghost"
                            onClick={() => handleToggleVisibility(post)}
                            className="h-8 text-xs cursor-pointer gap-1"
                          >
                            {post.isVisible ? <EyeOff className="h-3.5 w-3.5" /> : <Eye className="h-3.5 w-3.5" />}
                            {post.isVisible ? 'Ẩn' : 'Hiện'}
                          </Button>
                          <Button
                            size="sm"
                            variant="ghost"
                            onClick={() => startEdit(post)}
                            className="h-8 w-8 p-0 cursor-pointer"
                          >
                            <Edit2 className="h-3.5 w-3.5 text-muted-foreground" />
                          </Button>
                          <Button
                            size="sm"
                            variant="ghost"
                            onClick={() => handleDelete(post)}
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
        title="Xóa bài viết Explore?"
        description={postToDelete ? `Bạn có chắc chắn muốn xóa bài viết "${postToDelete.title}"?` : ""}
        onConfirm={handleConfirmDelete}
        onClose={() => setDeleteConfirmOpen(false)}
      />
    </div>
  );
}
