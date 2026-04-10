interface StatCardProps {
  label: string;
  value: string;
  icon: string;
  iconBgClass?: string;
  iconTextClass?: string;
  valueClass?: string;
  footer: React.ReactNode;
}

export default function StatCard({
  label,
  value,
  icon,
  iconBgClass = 'bg-surface-container',
  iconTextClass = 'text-on-surface',
  valueClass = 'text-on-surface',
  footer,
}: StatCardProps) {
  return (
    <div className="bg-surface-container-lowest p-8 rounded-xl shadow-[0px_20px_40px_rgba(21,28,39,0.03)] flex flex-col justify-between border-none group hover:scale-[1.02] transition-transform duration-300">
      <div>
        <div className="flex justify-between items-start mb-4">
          <span className="text-[11px] font-bold uppercase tracking-wider text-on-surface-variant/70">
            {label}
          </span>
          <div className={`w-8 h-8 rounded-lg ${iconBgClass} flex items-center justify-center ${iconTextClass}`}>
            <span className="material-symbols-outlined text-sm">{icon}</span>
          </div>
        </div>
        <h2 className={`text-[2.5rem] font-extrabold tracking-tight leading-tight ${valueClass}`}>
          {value}
        </h2>
      </div>
      <div className="mt-4 flex items-center gap-2">{footer}</div>
    </div>
  );
}
