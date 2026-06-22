"use client"

import * as React from "react"
import {
  LayoutDashboard,
  Users,
  MapPin,
  Hotel,
  Bus,
  Car,
  FileText,
  Compass,
  Bell,
  Tag,
  BarChart3,
} from "lucide-react"
import Link from "next/link"
import { Logo } from "@/components/logo"
import { useAuth } from "@/contexts/AuthContext"

import { NavMain } from "@/components/nav-main"
import { NavUser } from "@/components/nav-user"
import {
  Sidebar,
  SidebarContent,
  SidebarFooter,
  SidebarHeader,
  SidebarMenu,
  SidebarMenuButton,
  SidebarMenuItem,
} from "@/components/ui/sidebar"

const data = {
  navGroups: [
    {
      label: "Quản trị hệ thống",
      items: [
        {
          title: "Dashboard",
          url: "/dashboard",
          icon: LayoutDashboard,
        },
        {
          title: "Người dùng",
          url: "/users",
          icon: Users,
        },
        {
          title: "Điểm đến",
          url: "/destinations",
          icon: MapPin,
        },
        {
          title: "Khách sạn",
          url: "/hotels",
          icon: Hotel,
        },
        {
          title: "Vận chuyển",
          url: "/transport",
          icon: Bus,
        },
        {
          title: "Thuê xe tự lái",
          url: "/vehicle-rental",
          icon: Car,
        },
        {
          title: "Đặt chỗ",
          url: "/bookings",
          icon: FileText,
        },
        {
          title: "Khám phá",
          url: "/explore",
          icon: Compass,
        },
        {
          title: "Thông báo",
          url: "/notifications",
          icon: Bell,
        },
        {
          title: "Khuyến mãi",
          url: "/promotions",
          icon: Tag,
        },
        {
          title: "Báo cáo",
          url: "/reports",
          icon: BarChart3,
        },
      ],
    },
  ],
}

export function AppSidebar({ ...props }: React.ComponentProps<typeof Sidebar>) {
  const { user } = useAuth()

  const userData = user
    ? {
        name: user.fullName || "Admin",
        email: user.email || "admin@skynet.com",
        avatar: "",
      }
    : {
        name: "Skynet Admin",
        email: "admin@skynet.com",
        avatar: "",
      }

  return (
    <Sidebar {...props}>
      <SidebarHeader>
        <SidebarMenu>
          <SidebarMenuItem>
            <SidebarMenuButton size="lg" asChild>
              <Link href="/dashboard">
                <div className="flex aspect-square size-8 items-center justify-center rounded-lg bg-primary text-primary-foreground">
                  <Logo size={24} className="text-current" />
                </div>
                <div className="grid flex-1 text-left text-sm leading-tight">
                  <span className="truncate font-semibold">Skynet Smart Trip</span>
                  <span className="truncate text-xs">Hệ thống quản trị</span>
                </div>
              </Link>
            </SidebarMenuButton>
          </SidebarMenuItem>
        </SidebarMenu>
      </SidebarHeader>
      <SidebarContent>
        {data.navGroups.map((group) => (
          <NavMain key={group.label} label={group.label} items={group.items} />
        ))}
      </SidebarContent>
      <SidebarFooter>
        <NavUser user={userData} />
      </SidebarFooter>
    </Sidebar>
  )
}
