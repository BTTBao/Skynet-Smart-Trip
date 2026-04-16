import { useState } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import { useAuth, useToast } from '../../context';
import { getErrorMessage } from '../../utils/http';

export default function LoginPage() {
  const navigate = useNavigate();
  const location = useLocation();
  const { login } = useAuth();
  const { showToast } = useToast();
  const [email, setEmail] = useState('admin@smarttrip.vn');
  const [password, setPassword] = useState('12345678');
  const [isSubmitting, setIsSubmitting] = useState(false);

  const from = (location.state as { from?: { pathname?: string } } | null)?.from?.pathname || '/';

  const handleSubmit = async (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    setIsSubmitting(true);

    try {
      await login({ email, password });
      showToast({
        type: 'success',
        title: 'Đăng nhập thành công',
        message: 'Phiên quản trị đã sẵn sàng.',
      });
      navigate(from, { replace: true });
    } catch (error) {
      showToast({
        type: 'error',
        title: 'Không thể đăng nhập',
        message: getErrorMessage(error, 'Vui lòng kiểm tra lại email hoặc mật khẩu.'),
      });
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="min-h-screen bg-[radial-gradient(circle_at_top_left,_rgba(16,185,129,0.18),_transparent_35%),linear-gradient(135deg,_#f9f9ff_0%,_#eef4ff_42%,_#ffffff_100%)] px-6 py-10">
      <div className="mx-auto grid min-h-[calc(100vh-5rem)] max-w-6xl grid-cols-1 items-center gap-10 lg:grid-cols-[1.1fr_0.9fr]">
        <section className="rounded-[2.5rem] bg-on-surface px-10 py-12 text-white shadow-[0px_30px_80px_rgba(21,28,39,0.22)]">
          <p className="text-[11px] font-black uppercase tracking-[0.25em] text-primary-fixed">Skynet Smart Trip</p>
          <h1 className="mt-5 max-w-xl text-5xl font-black leading-tight">
            Trung tâm điều phối admin cho người dùng, booking và vận tải.
          </h1>
          <p className="mt-6 max-w-2xl text-sm leading-7 text-white/75">
            Đăng nhập để quản lý doanh thu, điều phối lịch trình, chăm sóc booking và theo dõi toàn bộ vận hành của hệ thống.
          </p>

          <div className="mt-10 grid gap-4 md:grid-cols-3">
            {[
              { icon: 'query_stats', label: 'Dashboard động', text: 'Theo dõi báo cáo và feed hoạt động theo thời gian.' },
              { icon: 'groups', label: 'RBAC quản trị', text: 'Kiểm soát tài khoản khách hàng, staff và đối tác.' },
              { icon: 'directions_bus', label: 'Điều phối chuyến', text: 'Quản lý lịch trình, nhà xe, sơ đồ ghế và booking.' },
            ].map((item) => (
              <div key={item.label} className="rounded-[2rem] bg-white/5 p-5 ring-1 ring-white/10">
                <span className="material-symbols-outlined rounded-2xl bg-white/10 p-3 text-primary-fixed">{item.icon}</span>
                <h2 className="mt-4 text-sm font-bold">{item.label}</h2>
                <p className="mt-2 text-xs leading-6 text-white/70">{item.text}</p>
              </div>
            ))}
          </div>
        </section>

        <section className="rounded-[2.5rem] bg-white p-8 shadow-[0px_30px_80px_rgba(21,28,39,0.12)] ring-1 ring-outline-variant/20 md:p-10">
          <div className="mb-8">
            <p className="text-[11px] font-black uppercase tracking-[0.25em] text-primary">Admin Access</p>
            <h2 className="mt-3 text-3xl font-black text-on-surface">Đăng nhập hệ thống</h2>
            <p className="mt-3 text-sm text-on-surface-variant">
              Dùng tài khoản quản trị để truy cập giao diện điều hành nội bộ.
            </p>
          </div>

          <form onSubmit={handleSubmit} className="space-y-5">
            <label className="block">
              <span className="mb-2 block text-sm font-bold text-on-surface">Email</span>
              <input
                value={email}
                onChange={(event) => setEmail(event.target.value)}
                type="email"
                className="w-full rounded-[1.5rem] border border-outline-variant/20 bg-surface-container-low px-5 py-4 outline-none transition-all focus:border-primary-container"
                placeholder="admin@smarttrip.vn"
                required
              />
            </label>

            <label className="block">
              <span className="mb-2 block text-sm font-bold text-on-surface">Mật khẩu</span>
              <input
                value={password}
                onChange={(event) => setPassword(event.target.value)}
                type="password"
                className="w-full rounded-[1.5rem] border border-outline-variant/20 bg-surface-container-low px-5 py-4 outline-none transition-all focus:border-primary-container"
                placeholder="Nhập mật khẩu"
                required
              />
            </label>

            <div className="rounded-[1.5rem] bg-surface-container-low px-5 py-4 text-xs leading-6 text-on-surface-variant">
              Gợi ý môi trường dev: <span className="font-bold text-on-surface">admin@smarttrip.vn / 12345678</span>
            </div>

            <button
              type="submit"
              disabled={isSubmitting}
              className="flex w-full items-center justify-center gap-2 rounded-full bg-primary-container px-6 py-4 text-sm font-bold text-white shadow-lg shadow-primary-container/25 transition-all hover:brightness-110 disabled:cursor-not-allowed disabled:opacity-60"
            >
              <span className="material-symbols-outlined text-[18px]">lock_open</span>
              {isSubmitting ? 'Đang đăng nhập...' : 'Vào trang quản trị'}
            </button>
          </form>
        </section>
      </div>
    </div>
  );
}
