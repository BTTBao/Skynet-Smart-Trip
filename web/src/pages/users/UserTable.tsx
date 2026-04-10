import { useState } from 'react';

import type { AdminUser } from '../../services/adminService';

const statusConfig = {
  active: {
    label: 'Hoạt động',
    bgClass: 'bg-primary-container/10',
    textClass: 'text-primary-container',
    avatarClass: 'bg-primary-container/20 text-primary',
  },
  pending: {
    label: 'Đang chờ',
    bgClass: 'bg-secondary-container/10',
    textClass: 'text-secondary-container',
    avatarClass: 'bg-secondary-container/20 text-secondary',
  },
  blocked: {
    label: 'Đã khóa',
    bgClass: 'bg-error-container/20',
    textClass: 'text-error',
    avatarClass: 'bg-error-container/20 text-error',
  },
};

export default function UserTable({ users, total }: { users: AdminUser[]; total: number }) {
  const [currentPage, setCurrentPage] = useState(1);

  return (
    <>
      {/* Table Controls */}
      <div className="flex flex-wrap gap-4 items-center justify-between bg-surface-container-low p-6 rounded-xl">
        <div className="flex gap-4 items-center">
          <div className="relative">
            <select className="appearance-none bg-surface-container-lowest border-none py-3 pl-6 pr-12 rounded-full text-sm font-bold text-on-surface focus:ring-2 focus:ring-primary-container focus:outline-none cursor-pointer">
              <option>Tất cả trạng thái</option>
              <option>Đang hoạt động</option>
              <option>Ngừng hoạt động</option>
            </select>
            <span className="material-symbols-outlined absolute right-4 top-1/2 -translate-y-1/2 pointer-events-none text-on-surface-variant">
              expand_more
            </span>
          </div>
          <div className="relative">
            <select className="appearance-none bg-surface-container-lowest border-none py-3 pl-6 pr-12 rounded-full text-sm font-bold text-on-surface focus:ring-2 focus:ring-primary-container focus:outline-none cursor-pointer">
              <option>Theo ngày tham gia</option>
              <option>Mới nhất</option>
              <option>Cũ nhất</option>
            </select>
            <span className="material-symbols-outlined absolute right-4 top-1/2 -translate-y-1/2 pointer-events-none text-on-surface-variant">
              calendar_month
            </span>
          </div>
        </div>
        <div className="text-on-surface-variant text-sm font-medium">
          Hiển thị {users.length} trên {total} kết quả
        </div>
      </div>

      {/* Data Table */}
      <div className="bg-surface-container-lowest rounded-xl overflow-hidden shadow-sm">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead className="bg-surface-container-low">
              <tr>
                <th className="px-8 py-6 text-[10px] font-black uppercase tracking-widest text-on-surface-variant">
                  Thành viên
                </th>
                <th className="px-8 py-6 text-[10px] font-black uppercase tracking-widest text-on-surface-variant">
                  Email
                </th>
                <th className="px-8 py-6 text-[10px] font-black uppercase tracking-widest text-on-surface-variant">
                  Số điện thoại
                </th>
                <th className="px-8 py-6 text-[10px] font-black uppercase tracking-widest text-on-surface-variant">
                  Ngày tham gia
                </th>
                <th className="px-8 py-6 text-[10px] font-black uppercase tracking-widest text-on-surface-variant">
                  Trạng thái
                </th>
                <th className="px-8 py-6 text-right text-[10px] font-black uppercase tracking-widest text-on-surface-variant">
                  Hành động
                </th>
              </tr>
            </thead>
            <tbody>
              {users.map((user) => {
                const status = statusConfig[user.status] || statusConfig.active;
                
                const bgStyle = status.avatarClass;

                return (
                  <tr
                    key={user.id}
                    className="hover:bg-surface-container-low/50 transition-colors group"
                  >
                    <td className="px-8 py-6">
                      <div className="flex items-center gap-4">
                        <div
                          className={`w-12 h-12 rounded-full ${bgStyle} flex items-center justify-center group-hover:scale-110 transition-transform`}
                        >
                          <span className="material-symbols-outlined font-bold text-[20px]">
                            person
                          </span>
                        </div>
                        <div>
                          <p className="font-bold text-on-surface">{user.name}</p>
                          <p className="text-[10px] text-on-surface-variant">ID: {user.displayId}</p>
                        </div>
                      </div>
                    </td>
                    <td className="px-8 py-6 text-sm text-on-surface-variant font-medium">
                      {user.email}
                    </td>
                    <td className="px-8 py-6 text-sm text-on-surface-variant font-medium">
                      {user.phone}
                    </td>
                    <td className="px-8 py-6 text-sm text-on-surface-variant font-medium">
                      {user.joinDate}
                    </td>
                    <td className="px-8 py-6">
                      <span
                        className={`inline-flex items-center px-4 py-1.5 ${status.bgClass} ${status.textClass} text-xs font-bold rounded-full`}
                      >
                        {status.label}
                      </span>
                    </td>
                    <td className="px-8 py-6 text-right">
                      <button className="p-2 hover:bg-surface-container rounded-full transition-all cursor-pointer">
                        <span className="material-symbols-outlined">more_vert</span>
                      </button>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      </div>

      {/* Pagination */}
      <div className="flex items-center justify-between pb-10">
        <button
          onClick={() => setCurrentPage((p) => Math.max(1, p - 1))}
          className="flex items-center gap-2 px-6 py-3 bg-surface-container-low rounded-full font-bold text-on-surface hover:bg-surface-container transition-all cursor-pointer"
        >
          <span className="material-symbols-outlined text-sm">arrow_back</span>
          Trước
        </button>
        <div className="flex items-center gap-2">
          {[1, 2, 3].map((page) => (
            <button
              key={page}
              onClick={() => setCurrentPage(page)}
              className={`w-10 h-10 flex items-center justify-center rounded-full font-medium transition-all cursor-pointer ${
                currentPage === page
                  ? 'bg-primary-container text-white font-bold'
                  : 'hover:bg-surface-container'
              }`}
            >
              {page}
            </button>
          ))}
          <span className="mx-2 text-on-surface-variant">...</span>
          <button
            onClick={() => setCurrentPage(12)}
            className={`w-10 h-10 flex items-center justify-center rounded-full font-medium transition-all cursor-pointer ${
              currentPage === 12
                ? 'bg-primary-container text-white font-bold'
                : 'hover:bg-surface-container'
            }`}
          >
            12
          </button>
        </div>
        <button
          onClick={() => setCurrentPage((p) => Math.min(12, p + 1))}
          className="flex items-center gap-2 px-6 py-3 bg-surface-container-low rounded-full font-bold text-on-surface hover:bg-surface-container transition-all cursor-pointer"
        >
          Sau
          <span className="material-symbols-outlined text-sm">arrow_forward</span>
        </button>
      </div>
    </>
  );
}
