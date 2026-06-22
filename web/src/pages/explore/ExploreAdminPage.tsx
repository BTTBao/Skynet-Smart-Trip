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
  { value: 'north', label: 'Mien Bac' },
  { value: 'central', label: 'Mien Trung' },
  { value: 'south', label: 'Mien Nam' },
] as const;

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
        showToast({ type: 'error', title: 'Khong the tai Explore', message });
      } finally {
        setLoading(false);
      }
    };

    void fetchData();
  }, []);

  useEffect(() => {
    const handle = window.setTimeout(async () => {
      try {
        await loadPosts();
        setError(null);
      } catch (err) {
        const message = getErrorMessage(err);
        setError(message);
        showToast({ type: 'error', title: 'Khong the tim Explore', message });
      }
    }, 250);

    return () => window.clearTimeout(handle);
  }, [query]);

  const visibleCount = posts.filter((post) => post.isVisible).length;
  const hiddenCount = posts.length - visibleCount;
  const totalInteractions = posts.reduce((sum, post) => sum + post.likes + post.saves + post.commentCount, 0);
  const hasExploreImages = form.imageUrls.length > 0;

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
    if (form.title.trim().length < 5) errors.push('Tieu de toi thieu 5 ky tu.');
    if (form.content.trim().length < 10) errors.push('Noi dung toi thieu 10 ky tu.');
    if (form.location.trim().length < 2) errors.push('Vi tri khong duoc de trong.');
    if (form.costLevel < 1 || form.costLevel > 4) errors.push('Muc chi phi phai tu 1 den 4.');
    if (form.latitude !== null && form.latitude !== undefined && (form.latitude < -90 || form.latitude > 90)) errors.push('Vi do khong hop le.');
    if (form.longitude !== null && form.longitude !== undefined && (form.longitude < -180 || form.longitude > 180)) errors.push('Kinh do khong hop le.');
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
      showToast({ type: 'error', title: 'Du lieu Explore chua hop le', message: validationErrors[0] });
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
      showToast({ type: 'success', title: editingPost ? 'Da cap nhat bai Explore' : 'Da tao bai Explore' });
    } catch (err) {
      showToast({ type: 'error', title: 'Khong the luu Explore', message: getErrorMessage(err) });
    } finally {
      setSubmitting(false);
    }
  };

  const handleToggleVisibility = async (post: AdminExplorePost) => {
    try {
      await adminService.updateExplorePostVisibility(post.id, !post.isVisible);
      await loadPosts();
      showToast({ type: 'success', title: !post.isVisible ? 'Da bat hien thi' : 'Da tat hien thi', message: post.title });
    } catch (err) {
      showToast({ type: 'error', title: 'Khong the doi trang thai', message: getErrorMessage(err) });
    }
  };

  const handleDelete = async (post: AdminExplorePost) => {
    if (!window.confirm(`Xoa bai Explore "${post.title}"?`)) {
      return;
    }

    try {
      await adminService.deleteExplorePost(post.id);
      await loadPosts();
      if (editingPost?.id === post.id) resetForm();
      showToast({ type: 'success', title: 'Da xoa bai Explore', message: post.title });
    } catch (err) {
      showToast({ type: 'error', title: 'Khong the xoa Explore', message: getErrorMessage(err) });
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
    setForm((current) => ({ ...current, imageUrls: current.imageUrls.filter((item) => item !== imageUrl) }));
  };

  const handleUploadImage = async (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (!file) return;

    setUploading(true);
    try {
      const result = await adminService.uploadExplorePostImage(file);
      setForm((current) => ({ ...current, imageUrls: [...current.imageUrls, result.imageUrl].slice(0, 10) }));
      showToast({ type: 'success', title: 'Da tai anh Explore' });
    } catch (err) {
      showToast({ type: 'error', title: 'Khong the tai anh', message: getErrorMessage(err) });
    } finally {
      setUploading(false);
      event.target.value = '';
    }
  };

  const exportPosts = () => {
    downloadCsv('explore-posts.csv', filteredPosts, [
      { key: 'title', header: 'Tieu de' },
      { key: 'location', header: 'Vi tri' },
      { key: 'province', header: 'Tinh/TP' },
      { key: 'authorName', header: 'Tac gia' },
      { key: 'views', header: 'Luot xem' },
      { key: 'isVisible', header: 'Hien thi' },
    ]);
    showToast({ type: 'success', title: 'Da xuat danh sach Explore' });
  };

  if (loading) {
    return <div className="flex min-h-[50vh] items-center justify-center"><div className="h-12 w-12 animate-spin rounded-full border-b-2 border-primary" /></div>;
  }

  if (error) {
    return (
      <div className="rounded-2xl border border-slate-100 bg-white p-10 text-center shadow-sm">
        <span className="material-symbols-outlined text-5xl text-error">error</span>
        <h1 className="mt-4 text-2xl font-black text-on-surface">Khong the tai Explore</h1>
        <p className="mt-2 text-sm text-slate-500">{error}</p>
        <button onClick={() => { setLoading(true); loadPosts().finally(() => setLoading(false)); }} className="mt-6 rounded-full bg-primary px-6 py-2.5 text-sm font-bold text-white">Tai lai</button>
      </div>
    );
  }

  return (
    <div className="space-y-8">
      <div className="flex flex-col justify-between gap-4 xl:flex-row xl:items-start">
        <div>
          <p className="mb-1 text-xs font-bold uppercase tracking-widest text-primary">Noi dung cong dong</p>
          <h1 className="text-3xl font-black text-on-surface">Quan ly Explore</h1>
          <p className="mt-1 max-w-xl text-sm text-slate-500">Quan tri bai viet, anh, vi tri, tag va trang thai hien thi trong Explore.</p>
        </div>
        <div className="flex flex-wrap items-center gap-2">
          <button onClick={() => setShowGuide(true)} className="rounded-full bg-amber-500 px-5 py-2.5 text-sm font-bold text-white shadow-sm transition hover:bg-amber-600">Huong dan</button>
          <button onClick={exportPosts} className="rounded-full bg-slate-100 px-5 py-2.5 text-sm font-bold text-slate-700 transition hover:bg-slate-200">Xuat CSV</button>
        </div>
      </div>

      <div className="grid grid-cols-2 gap-4 lg:grid-cols-4">
        <StatCard label="Tong bai" value={posts.length.toLocaleString()} icon="travel_explore" />
        <StatCard label="Dang hien thi" value={visibleCount.toLocaleString()} icon="visibility" />
        <StatCard label="Dang an" value={hiddenCount.toLocaleString()} icon="visibility_off" />
        <StatCard label="Tong tuong tac" value={totalInteractions.toLocaleString()} icon="forum" />
      </div>

      <form onSubmit={handleSubmit} className="rounded-2xl border border-slate-100 bg-white p-6 shadow-sm">
        <div className="mb-5 flex flex-col justify-between gap-3 sm:flex-row sm:items-center">
          <div>
            <h2 className="text-lg font-black text-on-surface">{editingPost ? 'Cap nhat bai Explore' : 'Tao bai Explore moi'}</h2>
            {validationErrors.length > 0 ? (
              <p className="mt-0.5 text-sm font-semibold text-red-500">{validationErrors[0]}</p>
            ) : (
              <p className="mt-0.5 text-sm text-slate-400">Dien thong tin dia diem, noi dung va anh.</p>
            )}
          </div>
          {editingPost ? (
            <button type="button" onClick={resetForm} className="rounded-full bg-slate-100 px-4 py-2 text-sm font-semibold text-slate-600 transition hover:bg-slate-200">Huy sua</button>
          ) : null}
        </div>

        <div className="grid grid-cols-1 gap-4 lg:grid-cols-4">
          <Field label="Tieu de" required><input value={form.title} onChange={(e) => setForm((c) => ({ ...c, title: e.target.value }))} className={inputCls} required /></Field>
          <Field label="Vi tri" required><input value={form.location} onChange={(e) => setForm((c) => ({ ...c, location: e.target.value }))} className={inputCls} required /></Field>
          <Field label="Thanh pho"><input value={form.city ?? ''} onChange={(e) => setForm((c) => ({ ...c, city: e.target.value }))} className={inputCls} /></Field>
          <Field label="Tinh/TP"><input value={form.province ?? ''} onChange={(e) => setForm((c) => ({ ...c, province: e.target.value }))} className={inputCls} /></Field>
          <Field label="Vung mien">
            <select value={form.region ?? 'north'} onChange={(e) => setForm((c) => ({ ...c, region: e.target.value as AdminExplorePostRequest['region'] }))} className={inputCls}>
              {regionOptions.map((option) => <option key={option.value} value={option.value}>{option.label}</option>)}
            </select>
          </Field>
          <Field label="Chi phi">
            <input value={form.costLevel} onChange={(e) => setForm((c) => ({ ...c, costLevel: Number(e.target.value) }))} type="number" min={1} max={4} className={inputCls} />
          </Field>
          <Field label="Vi do"><input value={form.latitude ?? ''} onChange={(e) => setForm((c) => ({ ...c, latitude: e.target.value === '' ? null : Number(e.target.value) }))} type="number" step="any" className={inputCls} /></Field>
          <Field label="Kinh do"><input value={form.longitude ?? ''} onChange={(e) => setForm((c) => ({ ...c, longitude: e.target.value === '' ? null : Number(e.target.value) }))} type="number" step="any" className={inputCls} /></Field>
        </div>
        <div className="mt-4">
          <Field label="Noi dung bai viet" required><textarea value={form.content} onChange={(e) => setForm((c) => ({ ...c, content: e.target.value }))} rows={4} className={`${inputCls} resize-none`} required /></Field>
        </div>

        <div className="mt-4">
          <label className="inline-flex cursor-pointer items-center gap-3 rounded-xl border border-slate-200 bg-white px-4 py-3 transition hover:bg-slate-50">
            <input checked={form.isVisible} onChange={(e) => setForm((c) => ({ ...c, isVisible: e.target.checked }))} type="checkbox" className="h-4 w-4 accent-emerald-500" />
            <span className="text-sm font-medium text-on-surface">Cho phep hien thi tren Explore</span>
          </label>
        </div>

        <div className="mt-4 grid grid-cols-1 gap-4 xl:grid-cols-2">
          <div className="rounded-xl border border-slate-200 bg-slate-50 p-4">
            <p className="mb-3 text-xs font-semibold uppercase tracking-wider text-slate-500">Thu vien anh toi da 10</p>
            <div className="flex gap-2">
              <input value={imageDraft} onChange={(e) => setImageDraft(e.target.value)} placeholder="Nhap URL anh..." className={`${inputCls} flex-1`} onKeyDown={(e) => { if (e.key === 'Enter') { e.preventDefault(); addImageUrl(); } }} />
              <button type="button" onClick={addImageUrl} className="shrink-0 rounded-xl bg-primary px-4 py-2.5 text-sm font-bold text-white">Them</button>
              <label className="shrink-0 cursor-pointer rounded-xl border border-slate-200 bg-white px-4 py-2.5 text-sm font-semibold text-slate-600 transition hover:bg-slate-50">
                {uploading ? 'Dang tai...' : 'Upload'}
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
                        <button type="button" onClick={() => removeImage(url)} className="absolute right-2 top-2 rounded-full bg-white/95 px-2.5 py-1 text-xs font-black text-on-surface shadow-sm">Xoa</button>
                      </div>
                      <div className="flex items-center justify-between px-3 py-2">
                        <span className="text-[11px] font-bold text-on-surface-variant">Anh {index + 1}</span>
                        {index === 0 ? <span className="rounded-full bg-primary-container/10 px-2 py-1 text-[10px] font-black text-primary-container">Thumbnail</span> : null}
                      </div>
                    </div>
                  ))}
                </div>
              ) : (
                <div className="rounded-[1.4rem] border border-dashed border-outline-variant/20 bg-white px-5 py-8 text-center text-sm font-bold text-on-surface-variant">Upload anh de xem preview tai day</div>
              )}
            </div>
          </div>

          <div className="rounded-xl border border-slate-200 bg-slate-50 p-4">
            <p className="mb-3 text-xs font-semibold uppercase tracking-wider text-slate-500">The tu khoa toi da 20</p>
            <div className="flex gap-2">
              <input value={tagDraft} onChange={(e) => setTagDraft(e.target.value)} placeholder="bien, nui, resort..." className={`${inputCls} flex-1`} onKeyDown={(e) => { if (e.key === 'Enter') { e.preventDefault(); addTag(); } }} />
              <button type="button" onClick={addTag} className="shrink-0 rounded-xl bg-primary px-4 py-2.5 text-sm font-bold text-white">Them</button>
            </div>
            <div className="mt-3 flex flex-wrap gap-2">
              {form.tags.map((tag) => (
                <button key={tag} type="button" onClick={() => setForm((c) => ({ ...c, tags: c.tags.filter((item) => item !== tag) }))} className="rounded-full border border-primary/20 bg-primary/10 px-3 py-1.5 text-xs font-semibold text-primary transition hover:border-red-200 hover:bg-red-50 hover:text-red-500">#{tag}</button>
              ))}
              {form.tags.length === 0 ? <span className="text-xs text-slate-400">Chua co tag nao</span> : null}
            </div>
          </div>
        </div>

        <div className="mt-5">
          <button type="submit" disabled={submitting || validationErrors.length > 0} className="rounded-full bg-primary px-6 py-2.5 text-sm font-bold text-white transition hover:brightness-110 disabled:opacity-50">
            {submitting ? 'Dang luu...' : editingPost ? 'Luu thay doi' : 'Tao bai viet'}
          </button>
        </div>
      </form>

      <div className="overflow-hidden rounded-2xl border border-slate-100 bg-white shadow-sm">
        {filteredPosts.length === 0 ? (
          <div className="p-12 text-center">
            <span className="material-symbols-outlined text-4xl text-slate-300">travel_explore</span>
            <p className="mt-3 font-medium text-slate-500">Chua co bai Explore</p>
            <p className="mt-1 text-sm text-slate-400">{query.trim() ? 'Khong co ket qua phu hop.' : 'Danh sach hien dang trong.'}</p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full border-collapse text-left">
              <thead className="border-b border-slate-100 bg-slate-50">
                <tr>
                  <th className="px-6 py-4 text-xs font-bold uppercase tracking-wider text-slate-500">Bai viet</th>
                  <th className="px-6 py-4 text-xs font-bold uppercase tracking-wider text-slate-500">Vi tri</th>
                  <th className="px-6 py-4 text-xs font-bold uppercase tracking-wider text-slate-500">Tuong tac</th>
                  <th className="px-6 py-4 text-xs font-bold uppercase tracking-wider text-slate-500">Trang thai</th>
                  <th className="px-6 py-4 text-right text-xs font-bold uppercase tracking-wider text-slate-500">Hanh dong</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-50">
                {filteredPosts.map((post) => (
                  <tr key={post.id} className="transition-colors hover:bg-slate-50/70">
                    <td className="px-6 py-4">
                      <div className="flex items-center gap-3">
                        <div className="h-14 w-20 shrink-0 overflow-hidden rounded-xl bg-slate-100">
                          {post.thumbnailUrl ? <img src={post.thumbnailUrl} alt="" className="h-full w-full object-cover" /> : null}
                        </div>
                        <div className="min-w-0">
                          <p className="max-w-[220px] truncate text-sm font-semibold text-on-surface">{post.title}</p>
                          <p className="mt-0.5 max-w-[220px] truncate text-xs text-slate-400">{post.authorName} . {post.createdAt}</p>
                          <div className="mt-1.5 flex flex-wrap gap-1">
                            {post.tags.slice(0, 3).map((tag) => <span key={tag} className="rounded-full bg-slate-100 px-2 py-0.5 text-[10px] font-semibold text-slate-500">#{tag}</span>)}
                          </div>
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-4">
                      <p className="text-sm font-semibold text-on-surface">{post.location}</p>
                      <p className="mt-0.5 text-xs text-slate-400">{post.province} . {post.region}</p>
                    </td>
                    <td className="px-6 py-4 text-xs text-slate-500">
                      <div className="flex flex-col gap-0.5">
                        <span>{post.views.toLocaleString()} luot xem</span>
                        <span>{post.likes.toLocaleString()} thich</span>
                        <span>{post.commentCount.toLocaleString()} binh luan</span>
                      </div>
                    </td>
                    <td className="px-6 py-4">
                      <span className={`rounded-full px-3 py-1 text-xs font-semibold ${post.isVisible ? 'bg-emerald-50 text-emerald-700' : 'bg-slate-100 text-slate-500'}`}>
                        {post.isVisible ? 'Dang hien thi' : 'Dang an'}
                      </span>
                    </td>
                    <td className="px-6 py-4 text-right">
                      <div className="flex justify-end gap-2">
                        <button onClick={() => handleToggleVisibility(post)} className="rounded-full bg-slate-100 px-3 py-1.5 text-xs font-semibold text-slate-700 transition hover:bg-slate-200">{post.isVisible ? 'An' : 'Hien'}</button>
                        <button onClick={() => startEdit(post)} className="rounded-full bg-slate-100 px-3 py-1.5 text-xs font-semibold text-slate-700 transition hover:bg-slate-200">Sua</button>
                        <button onClick={() => handleDelete(post)} className="rounded-full bg-red-50 px-3 py-1.5 text-xs font-semibold text-red-600 transition hover:bg-red-100">Xoa</button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {showGuide && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 p-4 backdrop-blur-sm">
          <div className="w-full max-w-2xl rounded-3xl bg-white p-8 shadow-2xl ring-1 ring-black/5">
            <div className="flex items-start justify-between border-b border-slate-100 pb-4">
              <div>
                <p className="text-xs font-black uppercase tracking-widest text-amber-600">Huong dan su dung</p>
                <h3 className="mt-1 text-xl font-black text-slate-900">Van hanh Explore</h3>
              </div>
              <button type="button" onClick={() => setShowGuide(false)} className="rounded-full bg-slate-100 px-4 py-2 text-xs font-bold text-slate-900 transition-colors hover:bg-slate-200">Dong</button>
            </div>
            <div className="mt-6 max-h-[55vh] space-y-5 overflow-y-auto pr-1 text-sm leading-relaxed text-slate-600">
              <div className="rounded-2xl border border-amber-100 bg-amber-50 p-5">
                <h4 className="text-base font-bold text-amber-800">Toa do, media va tag</h4>
                <ul className="mt-3 list-inside list-disc space-y-2 font-medium text-amber-900">
                  <li>Region dung cho tab loc tren mobile.</li>
                  <li>Anh dau tien duoc xem la thumbnail.</li>
                  <li>Tag giup tim kiem va gom nhom noi dung explore.</li>
                </ul>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

const inputCls = 'w-full rounded-xl border border-slate-200 bg-white px-4 py-2.5 text-sm font-medium text-on-surface outline-none transition focus:border-primary focus:ring-2 focus:ring-primary/20 placeholder:text-slate-400 min-w-0';

function Field({ label, required, children }: { label: string; required?: boolean; children: React.ReactNode }) {
  return (
    <div className="flex min-w-0 flex-col gap-1.5">
      <span className="select-none text-xs font-semibold uppercase tracking-wider text-slate-500">
        {label}
        {required ? <span className="ml-0.5 text-red-400">*</span> : null}
      </span>
      {children}
    </div>
  );
}

function StatCard({ label, value, icon }: { label: string; value: string; icon: string }) {
  return (
    <div className="flex flex-col gap-4 rounded-2xl border border-slate-100 bg-white p-6 shadow-sm">
      <span className="material-symbols-outlined w-fit rounded-xl bg-primary/10 p-2.5 text-xl text-primary">{icon}</span>
      <div>
        <p className="text-xs font-semibold uppercase tracking-wider text-slate-500">{label}</p>
        <h2 className="mt-1 text-3xl font-black text-on-surface">{value}</h2>
      </div>
    </div>
  );
}
