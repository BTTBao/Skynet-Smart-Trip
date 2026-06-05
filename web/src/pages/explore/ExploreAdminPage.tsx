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

function StatCard({ label, value, icon }: { label: string; value: string; icon: string }) {
  return (
    <div className="rounded-[2rem] bg-white p-8 shadow-[0px_20px_40px_rgba(21,28,39,0.04)]">
      <div className="flex items-center justify-between">
        <p className="text-[11px] font-black uppercase tracking-wider text-on-surface-variant">{label}</p>
        <span className="material-symbols-outlined rounded-2xl bg-primary-container/10 p-3 text-primary-container">{icon}</span>
      </div>
      <h2 className="mt-4 text-4xl font-black text-on-surface">{value}</h2>
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
  const hasExploreImages = form.imageUrls.length > 0;

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
      <div className="rounded-[2rem] bg-white p-10 text-center shadow-[0px_20px_40px_rgba(21,28,39,0.04)]">
        <span className="material-symbols-outlined text-5xl text-error">error</span>
        <h1 className="mt-4 text-2xl font-black text-on-surface">Không thể tải Explore</h1>
        <p className="mt-2 text-sm text-on-surface-variant">{error}</p>
        <button onClick={() => { setLoading(true); loadPosts().finally(() => setLoading(false)); }} className="mt-6 rounded-full bg-primary-container px-6 py-3 text-sm font-bold text-white">Tải lại</button>
      </div>
    );
  }

  return (
    <div className="space-y-10">
      <div className="flex flex-col gap-6 xl:flex-row xl:items-end xl:justify-between">
        <div>
          <p className="text-[10px] font-black uppercase tracking-[0.2em] text-primary">Nội dung cộng đồng</p>
          <h1 className="mt-3 text-4xl font-black text-on-surface">Quản lý Explore</h1>
          <p className="mt-3 max-w-3xl text-sm text-on-surface-variant">Quản trị bài viết, ảnh, vị trí, tag và trạng thái hiển thị trong Explore.</p>
        </div>
        <button onClick={exportPosts} className="rounded-full bg-primary-container px-6 py-3 text-sm font-bold text-white">Xuất CSV</button>
      </div>

      <div className="grid grid-cols-1 gap-6 md:grid-cols-4">
        <StatCard label="Tổng bài" value={posts.length.toLocaleString()} icon="travel_explore" />
        <StatCard label="Đang hiển thị" value={visibleCount.toLocaleString()} icon="visibility" />
        <StatCard label="Đang ẩn" value={hiddenCount.toLocaleString()} icon="visibility_off" />
        <StatCard label="Tương tác" value={totalInteractions.toLocaleString()} icon="forum" />
      </div>

      <form onSubmit={handleSubmit} className="rounded-[2rem] bg-white p-8 shadow-[0px_20px_40px_rgba(21,28,39,0.04)] ring-1 ring-outline-variant/10">
        <div className="mb-6 flex flex-col gap-4 lg:flex-row lg:items-center lg:justify-between">
          <div>
            <h2 className="text-xl font-black text-on-surface">{editingPost ? 'Cập nhật bài Explore' : 'Tạo bài Explore'}</h2>
            {validationErrors.length > 0 ? <p className="mt-1 text-sm font-semibold text-error">{validationErrors[0]}</p> : null}
          </div>
          {editingPost ? <button type="button" onClick={resetForm} className="rounded-full bg-surface-container-low px-5 py-2.5 text-sm font-bold text-on-surface">Hủy sửa</button> : null}
        </div>

        <div className="grid grid-cols-1 gap-4 lg:grid-cols-4">
          <input value={form.title} onChange={(event) => setForm((current) => ({ ...current, title: event.target.value }))} placeholder="Tiêu đề" className="rounded-2xl bg-surface-container-low px-5 py-3 outline-none lg:col-span-2" required />
          <input value={form.location} onChange={(event) => setForm((current) => ({ ...current, location: event.target.value }))} placeholder="Vị trí" className="rounded-2xl bg-surface-container-low px-5 py-3 outline-none" required />
          <input value={form.province ?? ''} onChange={(event) => setForm((current) => ({ ...current, province: event.target.value }))} placeholder="Tỉnh/TP" className="rounded-2xl bg-surface-container-low px-5 py-3 outline-none" />
          <input value={form.city ?? ''} onChange={(event) => setForm((current) => ({ ...current, city: event.target.value }))} placeholder="Slug thành phố" className="rounded-2xl bg-surface-container-low px-5 py-3 outline-none" />
          <select value={form.region} onChange={(event) => setForm((current) => ({ ...current, region: event.target.value as AdminExplorePostRequest['region'] }))} className="rounded-2xl bg-surface-container-low px-5 py-3 outline-none">
            {regionOptions.map((region) => <option key={region.value} value={region.value}>{region.label}</option>)}
          </select>
          <input value={form.latitude ?? ''} onChange={(event) => setForm((current) => ({ ...current, latitude: event.target.value === '' ? null : Number(event.target.value) }))} type="number" step="any" placeholder="Vĩ độ" className="rounded-2xl bg-surface-container-low px-5 py-3 outline-none" />
          <input value={form.longitude ?? ''} onChange={(event) => setForm((current) => ({ ...current, longitude: event.target.value === '' ? null : Number(event.target.value) }))} type="number" step="any" placeholder="Kinh độ" className="rounded-2xl bg-surface-container-low px-5 py-3 outline-none" />
          <select value={form.costLevel} onChange={(event) => setForm((current) => ({ ...current, costLevel: Number(event.target.value) }))} className="rounded-2xl bg-surface-container-low px-5 py-3 outline-none">
            <option value={1}>Tiết kiệm</option>
            <option value={2}>Trung bình</option>
            <option value={3}>Cao cấp</option>
            <option value={4}>Sang trọng</option>
          </select>
          <label className="flex items-center justify-between rounded-2xl bg-surface-container-low px-5 py-3">
            <span className="text-sm font-bold text-on-surface">Hiển thị</span>
            <input checked={form.isVisible} onChange={(event) => setForm((current) => ({ ...current, isVisible: event.target.checked }))} type="checkbox" className="h-4 w-4 accent-[#10B981]" />
          </label>
        </div>

        <textarea value={form.content} onChange={(event) => setForm((current) => ({ ...current, content: event.target.value }))} placeholder="Nội dung" rows={6} className="mt-4 w-full rounded-2xl bg-surface-container-low px-5 py-4 outline-none" required />

        <div className="mt-4 grid grid-cols-1 gap-4 xl:grid-cols-2">
          <div className="rounded-2xl bg-surface-container-low p-5">
            <div className="flex gap-3">
              <input value={imageDraft} onChange={(event) => setImageDraft(event.target.value)} placeholder="URL ảnh" className="min-w-0 flex-1 rounded-full bg-white px-5 py-3 text-sm outline-none" />
              <button type="button" onClick={addImageUrl} className="rounded-full bg-primary-container px-5 py-3 text-sm font-bold text-white">Thêm</button>
              <label className="rounded-full bg-white px-5 py-3 text-sm font-bold text-on-surface">
                {uploading ? 'Đang tải' : 'Upload'}
                <input type="file" accept="image/png,image/jpeg,image/webp" onChange={handleUploadImage} className="hidden" disabled={uploading} />
              </label>
            </div>
            <div className="mt-4">
              {hasExploreImages ? (
                <div className="grid grid-cols-2 gap-3 sm:grid-cols-3 xl:grid-cols-4">
                  {form.imageUrls.map((url, index) => (
                    <div key={`${url}-${index}`} className="group overflow-hidden rounded-[1.4rem] bg-white ring-1 ring-outline-variant/10">
                      <div className="relative aspect-[4/3] w-full overflow-hidden">
                        <img src={url} alt="" className="h-full w-full object-cover transition-transform duration-200 group-hover:scale-105" />
                        <button
                          type="button"
                          onClick={() => removeImage(url)}
                          className="absolute right-2 top-2 rounded-full bg-white/95 px-2.5 py-1 text-xs font-black text-on-surface shadow-sm"
                        >
                          Xóa
                        </button>
                      </div>
                      <div className="flex items-center justify-between px-3 py-2">
                        <span className="text-[11px] font-bold text-on-surface-variant">Ảnh {index + 1}</span>
                        {index === 0 ? <span className="rounded-full bg-primary-container/10 px-2 py-1 text-[10px] font-black text-primary-container">Thumbnail</span> : null}
                      </div>
                    </div>
                  ))}
                </div>
              ) : (
                <div className="rounded-[1.4rem] border border-dashed border-outline-variant/20 bg-white px-5 py-8 text-center text-sm font-bold text-on-surface-variant">
                  Upload ảnh để xem preview tại đây
                </div>
              )}
            </div>
            <div className="hidden mt-4 flex flex-wrap gap-3">
              {form.imageUrls.map((url) => (
                <button key={url} type="button" onClick={() => setForm((current) => ({ ...current, imageUrls: current.imageUrls.filter((item) => item !== url) }))} className="group flex items-center gap-2 rounded-full bg-white px-4 py-2 text-xs font-bold text-on-surface">
                  <span className="max-w-[220px] truncate">{url}</span>
                  <span className="material-symbols-outlined text-sm text-error">close</span>
                </button>
              ))}
              {form.imageUrls.length === 0 ? <span className="text-sm text-on-surface-variant">Chưa có ảnh</span> : null}
            </div>
          </div>

          <div className="rounded-2xl bg-surface-container-low p-5">
            <div className="flex gap-3">
              <input value={tagDraft} onChange={(event) => setTagDraft(event.target.value)} placeholder="Tag" className="min-w-0 flex-1 rounded-full bg-white px-5 py-3 text-sm outline-none" />
              <button type="button" onClick={addTag} className="rounded-full bg-primary-container px-5 py-3 text-sm font-bold text-white">Thêm</button>
            </div>
            <div className="mt-4 flex flex-wrap gap-3">
              {form.tags.map((tag) => (
                <button key={tag} type="button" onClick={() => setForm((current) => ({ ...current, tags: current.tags.filter((item) => item !== tag) }))} className="rounded-full bg-white px-4 py-2 text-xs font-bold text-on-surface">
                  #{tag} <span className="text-error">×</span>
                </button>
              ))}
              {form.tags.length === 0 ? <span className="text-sm text-on-surface-variant">Chưa có tag</span> : null}
            </div>
          </div>
        </div>

        <div className="mt-6">
          <button type="submit" disabled={submitting || validationErrors.length > 0} className="rounded-full bg-primary-container px-8 py-3 text-sm font-bold text-white disabled:opacity-50">
            {submitting ? 'Đang lưu...' : editingPost ? 'Lưu thay đổi' : 'Tạo bài Explore'}
          </button>
        </div>
      </form>

      <div className="overflow-hidden rounded-[2rem] bg-white shadow-[0px_20px_40px_rgba(21,28,39,0.04)]">
        {filteredPosts.length === 0 ? (
          <div className="p-12 text-center">
            <span className="material-symbols-outlined text-5xl text-on-surface-variant">travel_explore</span>
            <p className="mt-4 text-lg font-black text-on-surface">Chưa có bài Explore</p>
            <p className="mt-2 text-sm text-on-surface-variant">{query.trim() ? 'Không có kết quả phù hợp.' : 'Danh sách hiện đang trống.'}</p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full border-collapse text-left">
              <thead>
                <tr className="bg-surface-container-low/50">
                  <th className="px-8 py-5 text-[11px] font-black uppercase tracking-widest text-on-surface-variant">Bài viết</th>
                  <th className="px-8 py-5 text-[11px] font-black uppercase tracking-widest text-on-surface-variant">Vị trí</th>
                  <th className="px-8 py-5 text-[11px] font-black uppercase tracking-widest text-on-surface-variant">Tương tác</th>
                  <th className="px-8 py-5 text-[11px] font-black uppercase tracking-widest text-on-surface-variant">Trạng thái</th>
                  <th className="px-8 py-5 text-right text-[11px] font-black uppercase tracking-widest text-on-surface-variant">Hành động</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-outline-variant/10">
                {filteredPosts.map((post) => (
                  <tr key={post.id}>
                    <td className="px-8 py-6">
                      <div className="flex items-center gap-4">
                        <div className="h-16 w-20 overflow-hidden rounded-2xl bg-surface-container-low">
                          {post.thumbnailUrl ? <img src={post.thumbnailUrl} alt="" className="h-full w-full object-cover" /> : null}
                        </div>
                        <div>
                          <p className="font-bold text-on-surface">{post.title}</p>
                          <p className="mt-1 text-xs text-on-surface-variant">{post.authorName} • {post.createdAt}</p>
                          <div className="mt-2 flex flex-wrap gap-2">
                            {post.tags.slice(0, 3).map((tag) => <span key={tag} className="rounded-full bg-surface-container-low px-3 py-1 text-[11px] font-bold text-on-surface-variant">#{tag}</span>)}
                          </div>
                        </div>
                      </div>
                    </td>
                    <td className="px-8 py-6">
                      <p className="text-sm font-bold text-on-surface">{post.location}</p>
                      <p className="mt-1 text-xs text-on-surface-variant">{post.province} • {post.region}</p>
                    </td>
                    <td className="px-8 py-6 text-sm text-on-surface-variant">{post.views} xem • {post.likes} thích • {post.commentCount} bình luận</td>
                    <td className="px-8 py-6">
                      <span className={`rounded-full px-4 py-1.5 text-xs font-bold ${post.isVisible ? 'bg-primary-container/10 text-primary-container' : 'bg-error-container text-error'}`}>{post.isVisible ? 'Đang hiển thị' : 'Đang ẩn'}</span>
                    </td>
                    <td className="px-8 py-6 text-right">
                      <div className="flex justify-end gap-2">
                        <button onClick={() => handleToggleVisibility(post)} className="rounded-full bg-surface-container-low px-4 py-2 text-xs font-bold text-on-surface">{post.isVisible ? 'Ẩn' : 'Hiện'}</button>
                        <button onClick={() => startEdit(post)} className="rounded-full bg-surface-container-low px-4 py-2 text-xs font-bold text-on-surface">Sửa</button>
                        <button onClick={() => handleDelete(post)} className="rounded-full bg-error-container px-4 py-2 text-xs font-bold text-error">Xóa</button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  );
}
