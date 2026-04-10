import { useLocation } from 'react-router-dom';

const pageTitles: Record<string, string> = {
  '/destinations': 'Điểm đến',
  '/hotels': 'Khách sạn & Phòng',
  '/transport': 'Chuyển xe',
  '/promotions': 'Khuyến mãi',
  '/bookings': 'Đặt chỗ (Chuyến đi)',
  '/reports': 'Báo cáo doanh thu',
};

export default function PlaceholderPage() {
  const location = useLocation();
  const title = pageTitles[location.pathname] || 'Trang đang phát triển';

  return (
    <div className="flex flex-col items-center justify-center h-[70vh] text-center">
      <div className="w-24 h-24 bg-surface-container-high rounded-full flex items-center justify-center mb-6 shadow-sm">
        <span className="material-symbols-outlined text-5xl text-outline">
          construction
        </span>
      </div>
      <h2 className="text-3xl font-bold text-on-surface mb-3">{title}</h2>
      <p className="text-on-surface-variant max-w-md">
        Trang này hiện đang trong quá trình xây dựng và sẽ sớm được hoàn thiện. 
        Dữ liệu sẽ được kết nối với cơ sở dữ liệu trong các bản cập nhật tiếp theo.
      </p>
      <button 
        onClick={() => window.history.back()}
        className="mt-8 px-6 py-3 bg-surface-container-low text-on-surface font-bold rounded-full hover:bg-surface-container transition-all"
      >
        Quay lại
      </button>
    </div>
  );
}
