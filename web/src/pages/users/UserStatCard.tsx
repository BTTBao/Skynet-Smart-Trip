interface UserStatCardProps {
  icon: string;
  iconBgClass: string;
  iconTextClass: string;
  iconFilled?: boolean;
  label: string;
  value: string;
  badge?: React.ReactNode;
  borderClass?: string;
}

export default function UserStatCard({
  icon,
  iconBgClass,
  iconTextClass,
  iconFilled = false,
  label,
  value,
  badge,
  borderClass = '',
}: UserStatCardProps) {
  return (
    <div
      className={`bg-surface-container-lowest p-8 rounded-xl flex flex-col justify-between hover:scale-[1.02] transition-transform shadow-sm ${borderClass}`}
    >
      <div className="flex justify-between items-start mb-4">
        <div className={`p-3 ${iconBgClass} rounded-2xl`}>
          <span
            className={`material-symbols-outlined ${iconTextClass}`}
            style={iconFilled ? { fontVariationSettings: "'FILL' 1, 'wght' 400, 'GRAD' 0, 'opsz' 24" } : {}}
          >
            {icon}
          </span>
        </div>
        {badge}
      </div>
      <div>
        <p className="text-on-surface-variant text-sm font-medium mb-1">{label}</p>
        <h3 className="text-4xl font-black text-on-surface">{value}</h3>
      </div>
    </div>
  );
}
