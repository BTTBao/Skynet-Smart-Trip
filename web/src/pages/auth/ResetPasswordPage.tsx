import { useState } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import { useToast } from '../../context';
import { authService } from '../../services/authService';
import { getErrorMessage } from '../../utils/http';

export default function ResetPasswordPage() {
  const [searchParams] = useSearchParams();
  const navigate = useNavigate();
  const { showToast } = useToast();
  const [newPassword, setNewPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [submitting, setSubmitting] = useState(false);

  const token = searchParams.get('token') ?? '';

  const handleSubmit = async (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault();

    if (!token) {
      showToast({ type: 'error', title: 'Thiếu token reset mật khẩu' });
      return;
    }

    if (newPassword !== confirmPassword) {
      showToast({ type: 'error', title: 'Mật khẩu xác nhận không khớp' });
      return;
    }

    setSubmitting(true);

    try {
      await authService.resetPassword({ token, newPassword });
      showToast({
        type: 'success',
        title: 'Đặt lại mật khẩu thành công',
        message: 'Bạn có thể đăng nhập lại bằng mật khẩu mới.',
      });
      navigate('/login', { replace: true });
    } catch (error) {
      showToast({
        type: 'error',
        title: 'Không thể đặt lại mật khẩu',
        message: getErrorMessage(error),
      });
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="min-h-screen bg-[linear-gradient(135deg,_#f9f9ff_0%,_#eef4ff_42%,_#ffffff_100%)] px-6 py-10">
      <div className="mx-auto flex min-h-[calc(100vh-5rem)] max-w-xl items-center">
        <section className="w-full rounded-[2.5rem] bg-white p-10 shadow-[0px_30px_80px_rgba(21,28,39,0.12)] ring-1 ring-outline-variant/20">
          <p className="text-[11px] font-black uppercase tracking-[0.25em] text-primary">SmartTrip Security</p>
          <h1 className="mt-4 text-3xl font-black text-on-surface">Đặt lại mật khẩu</h1>
          <p className="mt-3 text-sm text-on-surface-variant">Nhập mật khẩu mới để hoàn tất quy trình reset từ email hoặc link admin.</p>

          <form onSubmit={handleSubmit} className="mt-8 space-y-5">
            <input
              value={newPassword}
              onChange={(event) => setNewPassword(event.target.value)}
              type="password"
              placeholder="Mật khẩu mới"
              className="w-full rounded-[1.5rem] bg-surface-container-low px-5 py-4 outline-none"
              required
            />
            <input
              value={confirmPassword}
              onChange={(event) => setConfirmPassword(event.target.value)}
              type="password"
              placeholder="Xác nhận mật khẩu mới"
              className="w-full rounded-[1.5rem] bg-surface-container-low px-5 py-4 outline-none"
              required
            />
            <button type="submit" disabled={submitting} className="w-full rounded-full bg-primary-container px-6 py-4 text-sm font-bold text-white disabled:opacity-50">
              {submitting ? 'Đang cập nhật...' : 'Cập nhật mật khẩu'}
            </button>
          </form>
        </section>
      </div>
    </div>
  );
}
