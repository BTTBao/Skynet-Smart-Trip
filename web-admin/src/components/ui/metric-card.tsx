import * as React from "react"
import { cn } from "@/lib/utils"
import { ArrowUpRight, ArrowDownRight } from "lucide-react"

export type MetricCardTheme = 'emerald' | 'sky' | 'amber' | 'rose' | 'muted' | 'indigo'

interface MetricCardProps extends React.HTMLAttributes<HTMLDivElement> {
  title: string
  value: string | number
  description?: React.ReactNode
  icon?: React.ReactNode
  theme?: MetricCardTheme
  trend?: {
    value: string | number
    isPositive: boolean
    label?: string
  }
  footerAction?: React.ReactNode
}

const themeStyles: Record<
  MetricCardTheme,
  {
    iconWrapper: string
    hoverCard: string
    glow: string
  }
> = {
  emerald: {
    iconWrapper: "bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 border-emerald-500/20 dark:border-emerald-500/10",
    hoverCard: "hover:border-emerald-500/30 dark:hover:border-emerald-500/20",
    glow: "hover:shadow-emerald-500/[0.02] dark:hover:shadow-emerald-500/[0.01]",
  },
  sky: {
    iconWrapper: "bg-sky-500/10 text-sky-600 dark:text-sky-400 border-sky-500/20 dark:border-sky-500/10",
    hoverCard: "hover:border-sky-500/30 dark:hover:border-sky-500/20",
    glow: "hover:shadow-sky-500/[0.02] dark:hover:shadow-sky-500/[0.01]",
  },
  amber: {
    iconWrapper: "bg-amber-500/10 text-amber-600 dark:text-amber-400 border-amber-500/20 dark:border-amber-500/10",
    hoverCard: "hover:border-amber-500/30 dark:hover:border-amber-500/20",
    glow: "hover:shadow-amber-500/[0.02] dark:hover:shadow-amber-500/[0.01]",
  },
  rose: {
    iconWrapper: "bg-rose-500/10 text-rose-600 dark:text-rose-400 border-rose-500/20 dark:border-rose-500/10",
    hoverCard: "hover:border-rose-500/30 dark:hover:border-rose-500/20",
    glow: "hover:shadow-rose-500/[0.02] dark:hover:shadow-rose-500/[0.01]",
  },
  indigo: {
    iconWrapper: "bg-indigo-500/10 text-indigo-600 dark:text-indigo-400 border-indigo-500/20 dark:border-indigo-500/10",
    hoverCard: "hover:border-indigo-500/30 dark:hover:border-indigo-500/20",
    glow: "hover:shadow-indigo-500/[0.02] dark:hover:shadow-indigo-500/[0.01]",
  },
  muted: {
    iconWrapper: "bg-zinc-500/10 text-zinc-600 dark:text-zinc-400 border-zinc-500/20 dark:border-zinc-500/10",
    hoverCard: "hover:border-zinc-500/30 dark:hover:border-zinc-500/20",
    glow: "hover:shadow-zinc-500/[0.02] dark:hover:shadow-zinc-500/[0.01]",
  },
}

export function MetricCard({
  className,
  title,
  value,
  description,
  icon,
  theme = 'muted',
  trend,
  footerAction,
  ...props
}: MetricCardProps) {
  const styles = themeStyles[theme]

  return (
    <div
      className={cn(
        "group relative bg-card text-card-foreground flex flex-col justify-between rounded-xl border p-5 shadow-xs transition-all duration-300 hover:-translate-y-1 hover:shadow-lg",
        styles.hoverCard,
        styles.glow,
        className
      )}
      {...props}
    >
      {/* Background Decorative Radial Gradient Grid */}
      <div className="absolute inset-0 rounded-xl overflow-hidden pointer-events-none opacity-0 group-hover:opacity-100 transition-opacity duration-500">
        <div className="absolute -right-12 -top-12 w-40 h-40 bg-radial from-current/5 to-transparent blur-2xl" />
      </div>

      <div className="space-y-4">
        {/* Top Header */}
        <div className="flex items-start justify-between">
          <span className="text-[11px] font-bold uppercase tracking-wider text-muted-foreground/90 block pt-0.5">
            {title}
          </span>
          {icon && (
            <div className={cn(
              "flex items-center justify-center p-2 rounded-lg border transition-transform duration-300 group-hover:scale-105 group-hover:rotate-3 shrink-0",
              styles.iconWrapper
            )}>
              {icon}
            </div>
          )}
        </div>

        {/* Content body */}
        <div className="space-y-1">
          <div className="text-3xl font-black tracking-tight text-zinc-900 dark:text-zinc-50">
            {value}
          </div>
          
          {/* Trend & Description Section */}
          <div className="flex flex-wrap items-center gap-1.5 pt-1 text-xs">
            {trend && (
              <span className={cn(
                "inline-flex items-center gap-0.5 px-1.5 py-0.5 rounded-md font-bold text-[10px]",
                trend.isPositive 
                  ? "bg-emerald-500/10 text-emerald-600 dark:text-emerald-400" 
                  : "bg-rose-500/10 text-rose-600 dark:text-rose-400"
              )}>
                {trend.isPositive ? <ArrowUpRight className="h-3 w-3" /> : <ArrowDownRight className="h-3 w-3" />}
                {trend.value}
                {trend.label && <span className="ml-0.5 font-normal text-muted-foreground/80">{trend.label}</span>}
              </span>
            )}
            
            {description && (
              <span className="text-muted-foreground/85 font-medium leading-relaxed">
                {description}
              </span>
            )}
          </div>
        </div>
      </div>

      {/* Footer Action link if provided */}
      {footerAction && (
        <div className="border-t border-border/40 mt-4 pt-3 flex items-center justify-end text-xs font-semibold text-primary transition-colors duration-300">
          <div className="flex items-center gap-1 cursor-pointer group/action">
            {footerAction}
          </div>
        </div>
      )}
    </div>
  )
}
