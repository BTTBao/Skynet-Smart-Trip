const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN'];
const revenueHeights = ['h-3/4', 'h-2/3', 'h-[90%]', 'h-4/5', 'h-full', 'h-[85%]'];
const profitHeights = ['h-1/4', 'h-1/5', 'h-1/3', 'h-1/4', 'h-[40%]', 'h-[35%]'];

export default function RevenueChart() {
  return (
    <div className="lg:col-span-2 bg-surface-container-lowest p-10 rounded-xl shadow-[0px_20px_40px_rgba(21,28,39,0.03)] flex flex-col">
      {/* Header */}
      <div className="flex justify-between items-end mb-10">
        <div>
          <h3 className="text-xl font-bold text-on-surface">Phân tích tài chính</h3>
          <p className="text-sm text-on-surface-variant mt-1">
            So sánh doanh thu và lợi nhuận 6 tháng gần nhất
          </p>
        </div>
        <div className="flex items-center gap-6">
          <div className="flex items-center gap-2">
            <div className="w-3 h-3 rounded-full bg-tertiary-container" />
            <span className="text-[11px] font-bold uppercase text-on-surface-variant">Doanh thu</span>
          </div>
          <div className="flex items-center gap-2">
            <div className="w-3 h-3 rounded-full bg-primary-container" />
            <span className="text-[11px] font-bold uppercase text-on-surface-variant">Lợi nhuận</span>
          </div>
        </div>
      </div>

      {/* Chart bars */}
      <div className="flex-1 min-h-[300px] flex items-end justify-between gap-4 px-4 border-b border-outline-variant/10">
        {months.map((month, i) => (
          <div key={month} className="flex-1 flex flex-col items-center gap-2 group">
            <div className="w-full flex justify-center items-end gap-1 h-48">
              <div
                className={`w-6 bg-tertiary-container/30 rounded-t-lg ${revenueHeights[i]} group-hover:brightness-110 transition-all duration-500`}
              />
              <div
                className={`w-6 bg-primary-container rounded-t-lg ${profitHeights[i]} group-hover:brightness-110 transition-all duration-500`}
              />
            </div>
            <span className="text-[10px] font-bold text-on-surface-variant">{month}</span>
          </div>
        ))}
      </div>
    </div>
  );
}
