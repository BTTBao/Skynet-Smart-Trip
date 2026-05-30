import type { AdminRecentBooking } from '../../services/adminService';

const statusConfig = {
  paid: { label: 'Đã thanh toán', bgClass: 'bg-[#10B981]/10', textClass: 'text-[#10B981]' },
  pending: { label: 'Chờ thanh toán', bgClass: 'bg-[#F97316]/10', textClass: 'text-[#F97316]' },
  cancelled: { label: 'Đã hủy', bgClass: 'bg-[#6B7280]/10', textClass: 'text-[#6B7280]' },
};

export default function RecentBookings({ bookings }: { bookings: AdminRecentBooking[] }) {
  return (
    <section className="bg-white rounded-xl shadow-[0px_20px_40px_rgba(21,28,39,0.03)] overflow-hidden">
      {/* Header */}
      <div className="p-10 flex justify-between items-center">
        <h3 className="text-xl font-bold text-on-surface">Đặt chỗ gần đây</h3>
        <button className="text-sm font-bold text-primary flex items-center gap-1 hover:underline cursor-pointer">
          Xem tất cả
          <span className="material-symbols-outlined text-[18px]">arrow_right_alt</span>
        </button>
      </div>

      {/* Table */}
      <div className="overflow-x-auto">
        <table className="w-full text-left border-collapse">
          <thead>
            <tr className="bg-surface-container-low/50">
              <th className="px-10 py-5 text-[11px] font-black uppercase tracking-wider text-on-surface-variant/70">
                Mã đặt chỗ
              </th>
              <th className="px-6 py-5 text-[11px] font-black uppercase tracking-wider text-on-surface-variant/70">
                Tên khách hàng
              </th>
              <th className="px-6 py-5 text-[11px] font-black uppercase tracking-wider text-on-surface-variant/70">
                Điểm đến
              </th>
              <th className="px-6 py-5 text-[11px] font-black uppercase tracking-wider text-on-surface-variant/70">
                Tổng tiền
              </th>
              <th className="px-10 py-5 text-[11px] font-black uppercase tracking-wider text-on-surface-variant/70">
                Trạng thái thanh toán
              </th>
            </tr>
          </thead>
          <tbody className="divide-y divide-outline-variant/10">
            {bookings.map((booking) => {
              const status = statusConfig[booking.status];
              return (
                <tr key={booking.id} className="hover:bg-surface-container-low/30 transition-colors group">
                  <td className="px-10 py-6 text-sm font-bold text-on-surface">{booking.id}</td>
                  <td className="px-6 py-6">
                    <div className="flex items-center gap-3">
                      <div className="w-8 h-8 rounded-full bg-surface-container-high flex items-center justify-center text-[10px] font-bold">
                        {booking.initials}
                      </div>
                      <span className="text-sm font-medium text-on-surface">{booking.name}</span>
                    </div>
                  </td>
                  <td className="px-6 py-6 text-sm text-on-surface-variant">{booking.destination}</td>
                  <td className="px-6 py-6 text-sm font-bold text-on-surface">{booking.amount}</td>
                  <td className="px-10 py-6">
                    <span
                      className={`inline-flex items-center px-4 py-1 rounded-full text-[10px] font-black uppercase ${status.bgClass} ${status.textClass}`}
                    >
                      {status.label}
                    </span>
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>
    </section>
  );
}
