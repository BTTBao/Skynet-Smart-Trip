"use client"

import * as React from "react"
import { Separator } from "@/components/ui/separator"
import { SidebarTrigger } from "@/components/ui/sidebar"
import { ModeToggle } from "@/components/mode-toggle"
import { useAdminSearch } from "@/contexts/AdminSearchContext"
import { usePathname } from "next/navigation"
import { Input } from "@/components/ui/input"
import { Search } from "lucide-react"

export function SiteHeader() {
  const { query, setQuery, clearQuery } = useAdminSearch()
  const pathname = usePathname()

  React.useEffect(() => {
    clearQuery()
  }, [pathname])

  const getPlaceholder = (path: string) => {
    if (path === '/users') return 'Tìm kiếm người dùng, email...'
    if (path === '/transport') return 'Tìm lịch trình, mã chuyến, nhà xe...'
    if (path === '/explore') return 'Tìm bài viết, vị trí, tag...'
    if (path === '/notifications') return 'Tìm thông báo, tiêu đề...'
    if (path === '/bookings') return 'Tìm booking, khách hàng, điểm đến...'
    return 'Tìm kiếm...'
  }

  return (
    <header className="flex h-(--header-height) shrink-0 items-center gap-2 border-b transition-[width,height] ease-linear group-has-data-[collapsible=icon]/sidebar-wrapper:h-(--header-height)">
      <div className="flex w-full items-center gap-1 px-4 py-3 lg:gap-2 lg:px-6">
        <SidebarTrigger className="-ml-1" />
        <Separator
          orientation="vertical"
          className="mx-2 data-[orientation=vertical]:h-4"
        />
        <div className="relative flex-1 max-w-sm">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
          <Input
            type="search"
            placeholder={getPlaceholder(pathname)}
            className="pl-9 rounded-full bg-muted/40 border-none h-9 w-full focus-visible:ring-1 focus-visible:ring-primary/20"
            value={query}
            onChange={(e) => setQuery(e.target.value)}
          />
        </div>
        <div className="ml-auto flex items-center gap-2">
          <ModeToggle />
        </div>
      </div>
    </header>
  )
}
