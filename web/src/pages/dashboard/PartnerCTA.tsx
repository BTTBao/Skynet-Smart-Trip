export default function PartnerCTA() {
  return (
    <div className="bg-primary-container rounded-xl p-10 text-white flex flex-col justify-between relative overflow-hidden shadow-xl shadow-primary-container/20">
      <div className="relative z-10">
        <h3 className="text-2xl font-black mb-4 leading-tight">Mở rộng mạng lưới đối tác</h3>
        <p className="text-white/80 text-sm leading-relaxed mb-8">
          Tăng thêm 25% lợi nhuận Affiliate bằng cách kích hoạt gói đối tác Kim Cương ngay hôm nay.
        </p>
        <button className="bg-white text-primary-container px-6 py-3 rounded-full font-bold text-sm shadow-lg hover:scale-105 transition-transform active:scale-95 cursor-pointer">
          Nâng cấp ngay
        </button>
      </div>

      {/* Decorative glass shapes */}
      <div className="absolute -right-10 -bottom-10 w-48 h-48 bg-white/10 rounded-full blur-3xl" />
      <div className="absolute -left-10 top-0 w-32 h-32 bg-white/5 rounded-full blur-2xl" />
      <span className="material-symbols-outlined absolute right-8 top-8 text-white/10 text-8xl rotate-12">
        auto_awesome
      </span>
    </div>
  );
}
