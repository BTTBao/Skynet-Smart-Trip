import { useEffect, useMemo, useState } from 'react';
import { useAdminSearch, useToast } from '../../context';
import {
  adminService,
  type AdminExplorePost,
  type AdminExplorePostRequest,
} from '../../services/adminService';
import { downloadCsv } from '../../utils/adminActions';
import { getErrorMessage } from '../../utils/http';

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

function Field({
  label,
  required,
  children,
  className = '',
}: {
  label: string;
  required?: boolean;
  children: React.ReactNode;
  className?: string;
}) {
  return (
    <div className={`flex flex-col gap-1.5 min-w-0 ${className}`}>
      <span className="text-xs font-semibold text-slate-500 uppercase tracking-wider select-none">
        {label}
        {required && <span className="text-red-400 ml-0.5">*</span>}
      </span>
      {children}
    </div>
  );
}

const inputCls =
  'w-full rounded-xl border border-slate-200 bg-white px-4 py-2.5 text-sm font-medium text-on-surface outline-none transition focus:border-primary focus:ring-2 focus:ring-primary/20 placeholder:text-slate-400 min-w-0';
const selectCls =
  'w-full rounded-xl border border-slate-200 bg-white px-4 py-2.5 text-sm font-medium text-on-surface outline-none transition focus:border-primary focus:ring-2 focus:ring-primary/20 cursor-pointer min-w-0';

function StatCard({ label, value, icon }: { label: string; value: string; icon: string }) {
  return (
    <div className="bg-white rounded-2xl p-6 shadow-sm border border-slate-100 flex flex-col gap-4">
      <div className="flex items-center justify-between">
        <span className="material-symbols-outlined rounded-xl bg-primary/10 p-2.5 text-primary text-xl">{icon}</span>
      </div>
      <div>
        <p className="text-xs font-semibold text-slate-500 uppercase tracking-wider">{label}</p>
        <h2 className="mt-1 text-3xl font-black text-on-surface">{value}</h2>
      </div>
    </div>
  );
}

export default function ExploreAdminPage() {
  const { query } = useAdminSearch();
  const { showToast } = useToast();
  const [posts, setPosts] = useState<AdminExplorePost[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [editingPost, setEditingPost] = useState<AdminExplorePost | null>(null);
  const [form, setForm] = useState<AdminExplorePostRequest>(initialForm);
  const [imageDraft, setImageDraft] = useState('');
  const [tagDraft, setTagDraft] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const [uploading, setUploading] = useState(false);
  const [showGuide, setShowGuide] = useState(false);

  const loadPosts = async (search = query) => {
    const data = await adminService.getExplorePosts({ search: search.trim() || undefined });
    setPosts(data);
  };

  useEffect(() => {
    const fetchData = async () => {
      try {
        await loadPosts();
        setError(null);
      } catch (err) {
        const message = getErrorMessage(err);
        setError(message);
        showToast({ type: 'error', title: 'Không thể tải Explore', message });
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
      } catch (err) {
        const message = getErrorMessage(err);
        setError(message);
        showToast({ type: 'error', title: 'Không thể tìm Explore', message });
      }
    }, 250);

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
    if (form.latitude !== null && form.latitude !== undefined && (form.latitude < -90 || form.latitude > 90)) errors.push('Vĩ độ không hợp lệ.');
    if (form.longitude !== null && form.longitude !== undefined && (form.longitude < -180 || form.longitude > 180)) errors.push('Kinh độ không hợp lệ.');
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

  const handleSubmit = async (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    if (validationErrors.length > 0) {
      showToast({ type: 'error', title: 'Dữ liệu Explore chưa hợp lệ', message: validationErrors[0] });
      return;
    }

    setSubmitting(true);
    try {
      if (editingPost) {
        await adminService.updateExplorePost(editingPost.id, form);
      } else {
        await adminService.createExplorePost(form);
      }

      await loadPosts('');
      resetForm();
      showToast({
        type: 'success',
        title: editingPost ? 'Đã cập nhật bài Explore' : 'Đã tạo bài Explore',
      });
    } catch (err) {
      showToast({ type: 'error', title: 'Không thể lưu Explore', message: getErrorMessage(err) });
    } finally {
      setSubmitting(false);
    }
  };

  const handleToggleVisibility = async (post: AdminExplorePost) => {
    try {
      await adminService.updateExplorePostVisibility(post.id, !post.isVisible);
      await loadPosts();
      showToast({ type: 'success', title: !post.isVisible ? 'Đã bật hiển thị' : 'Đã tắt hiển thị', message: post.title });
    } catch (err) {
      showToast({ type: 'error', title: 'Không thể đổi trạng thái', message: getErrorMessage(err) });
    }
  };

  const handleDelete = async (post: AdminExplorePost) => {
    if (!window.confirm(`Xóa bài Explore "${post.title}"?`)) {
      return;
    }

    try {
      await adminService.deleteExplorePost(post.id);
      await loadPosts();
      if (editingPost?.id === post.id) resetForm();
      showToast({ type: 'success', title: 'Đã xóa bài Explore', message: post.title });
    } catch (err) {
      showToast({ type: 'error', title: 'Không thể xóa Explore', message: getErrorMessage(err) });
    }
  };

  const addImageUrl = () => {
    const url = imageDraft.trim();
    if (!url || form.imageUrls.includes(url) || form.imageUrls.length >= 10) {
      return;
    }
    setForm((current) => ({ ...current, imageUrls: [...current.imageUrls, url] }));
    setImageDraft('');
  };

  const addTag = () => {
    const tag = tagDraft.trim();
    if (!tag || form.tags.some((item) => item.toLowerCase() === tag.toLowerCase()) || form.tags.length >= 20) {
      return;
    }
    setForm((current) => ({ ...current, tags: [...current.tags, tag] }));
    setTagDraft('');
  };

  const handleUploadImage = async (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (!file) return;

    setUploading(true);
    try {
      const result = await adminService.uploadExplorePostImage(file);
      setForm((current) => ({ ...current, imageUrls: [...current.imageUrls, result.imageUrl].slice(0, 10) }));
      showToast({ type: 'success', title: 'Đã tải ảnh Explore' });
    } catch (err) {
      showToast({ type: 'error', title: 'Không thể tải ảnh', message: getErrorMessage(err) });
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
    showToast({ type: 'success', title: 'Đã xuất danh sách Explore' });
  };

  if (loading) {
    return <div className="flex min-h-[50vh] items-center justify-center"><div className="h-12 w-12 animate-spin rounded-full border-b-2 border-primary" /></div>;
  }

  if (error) {
    return (
      <div className="rounded-2xl bg-white p-10 text-center shadow-sm border border-slate-100">
        <span className="material-symbols-outlined text-5xl text-error">error</span>
        <h1 className="mt-4 text-2xl font-black text-on-surface">Không thể tải Explore</h1>
        <p className="mt-2 text-sm text-slate-500">{error}</p>
        <button onClick={() => { setLoading(true); loadPosts().finally(() => setLoading(false)); }} className="mt-6 rounded-full bg-primary px-6 py-2.5 text-sm font-bold text-white">Tải lại</button>
      </div>
    );
  }

  return (
    <div className="space-y-8">
      {/* Header */}
      <div className="flex flex-col xl:flex-row xl:items-start justify-between gap-4">
        <div>
          <p className="text-xs font-bold uppercase tracking-widest text-primary mb-1">Nội dung cộng đồng</p>
          <h1 className="text-3xl font-black text-on-surface">Quản lý Explore</h1>
          <p className="text-sm text-slate-500 mt-1 max-w-xl">Quản trị bài viết, ảnh, vị trí, tag và trạng thái hiển thị trong Explore.</p>
        </div>
        <div className="flex flex-wrap items-center gap-2">
          <button onClick={() => setShowGuide(true)} className="rounded-full bg-amber-500 hover:bg-amber-600 px-5 py-2.5 text-sm font-bold text-white transition-all shadow-sm">
            💡 Hướng dẫn
          </button>
          <button onClick={exportPosts} className="rounded-full bg-slate-100 text-slate-700 px-5 py-2.5 text-sm font-bold hover:bg-slate-200 transition">Xuất CSV</button>
        </div>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <StatCard label="Tổng bài" value={posts.length.toLocaleString()} icon="travel_explore" />
        <StatCard label="Đang hiển thị" value={visibleCount.toLocaleString()} icon="visibility" />
        <StatCard label="Đang ẩn" value={hiddenCount.toLocaleString()} icon="visibility_off" />
        <StatCard label="Tổng tương tác" value={totalInteractions.toLocaleString()} icon="forum" />
      </div>

      {/* Form */}
      <form onSubmit={handleSubmit} className="bg-white rounded-2xl p-6 shadow-sm border border-slate-100">
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 mb-5">
          <div>
            <h2 className="text-lg font-black text-on-surface">{editingPost ? 'Cập nhật bài Explore' : 'Tạo bài Explore mới'}</h2>
            {validationErrors.length > 0 ? (
              <p className="mt-0.5 text-sm font-semibold text-red-500">{validationErrors[0]}</p>
            ) : (
              <p className="mt-0.5 text-sm text-slate-400">Điền đầy đủ thông tin địa điểm, nội dung và ảnh.</p>
            )}
          </div>
          {editingPost ? (
            <button type="button" onClick={resetForm} className="rounded-full bg-slate-100 px-4 py-2 text-sm font-semibold text-slate-600 hover:bg-slate-200 transition">Hủy sửa</button>
          ) : null}
        </div>

        {/* Main fields */}
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
          <Field label="Tiêu đề bài viết" required className="sm:col-span-2">
            <input value={form.title} onChange={(e) => setForm((c) => ({ ...c, title: e.target.value }))} placeholder="Nhập tiêu đề..." className={inputCls} required />
          </Field>
          <Field label="Địa điểm" required>
            <input value={form.location} onChange={(e) => setForm((c) => ({ ...c, location: e.target.value }))} placeholder="Hồ Gươm, Hà Nội" className={inputCls} required />
          </Field>
          <Field label="Tỉnh / Thành phố">
            <input value={form.province ?? ''} onChange={(e) => setForm((c) => ({ ...c, province: e.target.value }))} placeholder="Hà Nội" className={inputCls} />
          </Field>
          <Field label="Slug thành phố">
            <input value={form.city ?? ''} onChange={(e) => setForm((c) => ({ ...c, city: e.target.value }))} placeholder="ha-noi" className={inputCls} />
          </Field>
          <Field label="Vùng miền" required>
            <select value={form.region} onChange={(e) => setForm((c) => ({ ...c, region: e.target.value as AdminExplorePostRequest['region'] }))} className={selectCls}>
              {regionOptions.map((region) => <option key={region.value} value={region.value}>{region.label}</option>)}
            </select>
          </Field>
          <Field label="Vĩ độ (Latitude)">
            <input value={form.latitude ?? ''} onChange={(e) => setForm((c) => ({ ...c, latitude: e.target.value === '' ? null : Number(e.target.value) }))} type="number" step="any" placeholder="21.0285" className={inputCls} />
          </Field>
          <Field label="Kinh độ (Longitude)">
            <input value={form.longitude ?? ''} onChange={(e) => setForm((c) => ({ ...c, longitude: e.target.value === '' ? null : Number(e.target.value) }))} type="number" step="any" placeholder="105.8542" className={inputCls} />
          </Field>
          <Field label="Mức chi phí" required>
            <select value={form.costLevel} onChange={(e) => setForm((c) => ({ ...c, costLevel: Number(e.target.value) }))} className={selectCls}>
              <option value={1}>$ · Tiết kiệm</option>
              <option value={2}>$$ · Trung bình</option>
              <option value={3}>$$$ · Cao cấp</option>
              <option value={4}>$$$$ · Sang trọng</option>
            </select>
          </Field>
        </div>

        {/* Content */}
        <div className="mt-4">
          <Field label="Nội dung bài viết" required>
            <textarea value={form.content} onChange={(e) => setForm((c) => ({ ...c, content: e.target.value }))} placeholder="Nhập nội dung bài viết..." rows={4} className={`${inputCls} resize-none`} required />
          </Field>
        </div>

        {/* Visibility toggle */}
        <div className="mt-4">
          <label className="inline-flex items-center gap-3 rounded-xl border border-slate-200 bg-white px-4 py-3 cursor-pointer hover:bg-slate-50 transition">
            <input checked={form.isVisible} onChange={(e) => setForm((c) => ({ ...c, isVisible: e.target.checked }))} type="checkbox" className="h-4 w-4 accent-emerald-500" />
            <span className="text-sm font-medium text-on-surface">Cho phép hiển thị trên Explore</span>
          </label>
        </div>

        {/* Images & Tags */}
        <div className="mt-4 grid grid-cols-1 gap-4 xl:grid-cols-2">
          {/* Images */}
          <div className="rounded-xl bg-slate-50 border border-slate-200 p-4">
            <p className="text-xs font-semibold text-slate-500 uppercase tracking-wider mb-3">Thư viện ảnh (tối đa 10)</p>
            <div className="flex gap-2">
              <input
                value={imageDraft}
                onChange={(e) => setImageDraft(e.target.value)}
                placeholder="Nhập URL ảnh..."
                className={`${inputCls} flex-1`}
                onKeyDown={(e) => { if (e.key === 'Enter') { e.preventDefault(); addImageUrl(); } }}
              />
              <button type="button" onClick={addImageUrl} className="rounded-xl bg-primary px-4 py-2.5 text-sm font-bold text-white shrink-0">Thêm</button>
              <label className="rounded-xl bg-white border border-slate-200 px-4 py-2.5 text-sm font-semibold text-slate-600 cursor-pointer hover:bg-slate-50 transition shrink-0">
                {uploading ? 'Đang tải...' : 'Upload'}
                <input type="file" accept="image/png,image/jpeg,image/webp" onChange={handleUploadImage} className="hidden" disabled={uploading} />
              </label>
            </div>
            <div className="mt-3 flex flex-wrap gap-2">
              {form.imageUrls.map((url) => (
                <button key={url} type="button" onClick={() => setForm((c) => ({ ...c, imageUrls: c.imageUrls.filter((item) => item !== url) }))} className="flex items-center gap-1.5 rounded-full bg-white border border-slate-200 px-3 py-1.5 text-xs font-medium text-slate-600 hover:border-red-300 hover:text-red-500 transition group">
                  <span className="max-w-[180px] truncate">{url}</span>
                  <span className="material-symbols-outlined text-sm text-slate-400 group-hover:text-red-400">close</span>
                </button>
              ))}
              {form.imageUrls.length === 0 ? <span className="text-xs text-slate-400">Chưa có ảnh nào được thêm</span> : null}
            </div>
          </div>

          {/* Tags */}
          <div className="rounded-xl bg-slate-50 border border-slate-200 p-4">
            <p className="text-xs font-semibold text-slate-500 uppercase tracking-wider mb-3">Thẻ từ khóa (tối đa 20)</p>
            <div className="flex gap-2">
              <input
                value={tagDraft}
                onChange={(e) => setTagDraft(e.target.value)}
                placeholder="bien, nui, resort..."
                className={`${inputCls} flex-1`}
                onKeyDown={(e) => { if (e.key === 'Enter') { e.preventDefault(); addTag(); } }}
              />
              <button type="button" onClick={addTag} className="rounded-xl bg-primary px-4 py-2.5 text-sm font-bold text-white shrink-0">Thêm</button>
            </div>
            <div className="mt-3 flex flex-wrap gap-2">
              {form.tags.map((tag) => (
                <button key={tag} type="button" onClick={() => setForm((c) => ({ ...c, tags: c.tags.filter((item) => item !== tag) }))} className="flex items-center gap-1 rounded-full bg-primary/10 text-primary border border-primary/20 px-3 py-1.5 text-xs font-semibold hover:bg-red-50 hover:text-red-500 hover:border-red-200 transition">
                  #{tag} <span className="ml-0.5">×</span>
                </button>
              ))}
              {form.tags.length === 0 ? <span className="text-xs text-slate-400">Chưa có thẻ từ khóa nào</span> : null}
            </div>
          </div>
        </div>

        <div className="mt-5">
          <button type="submit" disabled={submitting || validationErrors.length > 0} className="px-6 py-2.5 bg-primary text-white text-sm font-bold rounded-full disabled:opacity-50 hover:brightness-110 transition">
            {submitting ? 'Đang lưu...' : editingPost ? 'Lưu thay đổi' : 'Tạo bài viết'}
          </button>
        </div>
      </form>

      {/* Post Table */}
      <div className="bg-white rounded-2xl border border-slate-100 overflow-hidden shadow-sm">
        {filteredPosts.length === 0 ? (
          <div className="p-12 text-center">
            <span className="material-symbols-outlined text-4xl text-slate-300">travel_explore</span>
            <p className="mt-3 text-slate-500 font-medium">Chưa có bài Explore</p>
            <p className="mt-1 text-sm text-slate-400">{query.trim() ? 'Không có kết quả phù hợp.' : 'Danh sách hiện đang trống.'}</p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full border-collapse text-left">
              <thead className="bg-slate-50 border-b border-slate-100">
                <tr>
                  <th className="px-6 py-4 text-xs font-bold uppercase tracking-wider text-slate-500">Bài viết</th>
                  <th className="px-6 py-4 text-xs font-bold uppercase tracking-wider text-slate-500">Vị trí</th>
                  <th className="px-6 py-4 text-xs font-bold uppercase tracking-wider text-slate-500">Tương tác</th>
                  <th className="px-6 py-4 text-xs font-bold uppercase tracking-wider text-slate-500">Trạng thái</th>
                  <th className="px-6 py-4 text-right text-xs font-bold uppercase tracking-wider text-slate-500">Hành động</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-50">
                {filteredPosts.map((post) => (
                  <tr key={post.id} className="hover:bg-slate-50/70 transition-colors">
                    <td className="px-6 py-4">
                      <div className="flex items-center gap-3">
                        <div className="h-14 w-18 overflow-hidden rounded-xl bg-slate-100 shrink-0">
                          {post.thumbnailUrl ? <img src={post.thumbnailUrl} alt="" className="h-full w-full object-cover" /> : null}
                        </div>
                        <div className="min-w-0">
                          <p className="font-semibold text-on-surface text-sm truncate max-w-[200px]">{post.title}</p>
                          <p className="mt-0.5 text-xs text-slate-400 truncate max-w-[200px]">{post.authorName} · {post.createdAt}</p>
                          <div className="mt-1.5 flex flex-wrap gap-1">
                            {post.tags.slice(0, 3).map((tag) => <span key={tag} className="rounded-full bg-slate-100 px-2 py-0.5 text-[10px] font-semibold text-slate-500">#{tag}</span>)}
                          </div>
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-4">
                      <p className="text-sm font-semibold text-on-surface">{post.location}</p>
                      <p className="mt-0.5 text-xs text-slate-400">{post.province} · {post.region}</p>
                    </td>
                    <td className="px-6 py-4 text-xs text-slate-500">
                      <div className="flex flex-col gap-0.5">
                        <span>{post.views.toLocaleString()} lượt xem</span>
                        <span>{post.likes.toLocaleString()} thích</span>
                        <span>{post.commentCount.toLocaleString()} bình luận</span>
                      </div>
                    </td>
                    <td className="px-6 py-4">
                      <span className={`rounded-full px-3 py-1 text-xs font-semibold ${post.isVisible ? 'bg-emerald-50 text-emerald-700' : 'bg-slate-100 text-slate-500'}`}>
                        {post.isVisible ? 'Đang hiển thị' : 'Đang ẩn'}
                      </span>
                    </td>
                    <td className="px-6 py-4 text-right">
                      <div className="flex justify-end gap-2">
                        <button onClick={() => handleToggleVisibility(post)} className="rounded-full bg-slate-100 px-3 py-1.5 text-xs font-semibold text-slate-700 hover:bg-slate-200 transition">
                          {post.isVisible ? 'Ẩn' : 'Hiện'}
                        </button>
                        <button onClick={() => startEdit(post)} className="rounded-full bg-slate-100 px-3 py-1.5 text-xs font-semibold text-slate-700 hover:bg-slate-200 transition">Sửa</button>
                        <button onClick={() => handleDelete(post)} className="rounded-full bg-red-50 px-3 py-1.5 text-xs font-semibold text-red-600 hover:bg-red-100 transition">Xóa</button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* Guide Modal */}
      {showGuide && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-sm p-4">
          <div className="w-full max-w-2xl rounded-3xl bg-white p-8 shadow-2xl ring-1 ring-black/5">
            <div className="flex items-start justify-between border-b border-slate-100 pb-4">
              <div>
                <p className="text-xs font-black uppercase tracking-widest text-amber-600">Hướng dẫn sử dụng</p>
                <h3 className="mt-1 text-xl font-black text-slate-900">Vận hành Khám phá (Explore)</h3>
              </div>
              <button type="button" onClick={() => setShowGuide(false)} className="rounded-full bg-slate-100 hover:bg-slate-200 px-4 py-2 text-xs font-bold text-slate-900 transition-colors">Đóng</button>
            </div>
            <div className="mt-6 space-y-5 text-sm text-slate-600 leading-relaxed max-h-[55vh] overflow-y-auto pr-1">
              <div className="rounded-2xl bg-amber-50 p-5 border border-amber-100">
                <h4 className="font-bold text-amber-800 text-base">📍 Phân vùng địa lý &amp; Tọa độ</h4>
                <ul className="mt-3 list-disc list-inside space-y-2 text-amber-900 font-medium">
                  <li><strong>Vùng miền (Region):</strong> Bắc - Trung - Nam giúp định tuyến tab lọc bài viết trên Mobile App.</li>
                  <li><strong>Tọa độ (Lat/Long):</strong> Định vị chính xác địa điểm viết bài trên bản đồ ứng dụng, cho phép điều hướng trực tiếp bằng Google Maps.</li>
                  <li><strong>Slug thành phố (City):</strong> Nhãn định danh không dấu viết liền để liên kết với catalog hệ thống (ví dụ: <code>ha-noi</code>).</li>
                </ul>
              </div>
              <div>
                <h4 className="font-black text-slate-900 text-base">🖼️ Chi phí, Media &amp; Tags</h4>
                <ul className="mt-2 list-disc list-inside space-y-2">
                  <li><strong>Mức chi phí (Cost Level):</strong> Chọn từ 1 ($) đến 4 ($$$$) để hiển thị nhãn tài chính trên bài viết.</li>
                  <li><strong>Quản lý ảnh:</strong> Hỗ trợ tối đa 10 ảnh. Bấm Upload để tải lên Cloud, hoặc chèn URL thủ công. Ảnh đầu tiên làm ảnh bìa.</li>
                  <li><strong>Tags từ khóa:</strong> Nhấn Enter hoặc nút "Thêm" để gắn thẻ phân loại bài viết. Click vào tag để xóa.</li>
                </ul>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
