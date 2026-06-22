import type { Metadata } from "next";
import "./globals.css";

import { ThemeProvider } from "@/components/theme-provider";
import { SidebarConfigProvider } from "@/contexts/sidebar-context";
import { AuthProvider } from "@/contexts/AuthContext";
import { AdminSearchProvider } from "@/contexts/AdminSearchContext";
import { inter } from "@/lib/fonts";

export const metadata: Metadata = {
  title: "Skynet Smart Trip Admin",
  description: "Dashboard quản trị hệ thống Skynet Smart Trip",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="vi" className={`${inter.variable} antialiased`} suppressHydrationWarning>
      <body className={inter.className} suppressHydrationWarning>
        <ThemeProvider defaultTheme="system" storageKey="nextjs-ui-theme">
          <SidebarConfigProvider>
            <AuthProvider>
              <AdminSearchProvider>
                {children}
              </AdminSearchProvider>
            </AuthProvider>
          </SidebarConfigProvider>
        </ThemeProvider>
      </body>
    </html>
  );
}


