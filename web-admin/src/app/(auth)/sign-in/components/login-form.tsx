"use client"

import React, { useState } from "react"
import { useRouter } from "next/navigation"
import { useAuth } from "@/contexts/AuthContext"
import { cn } from "@/lib/utils"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { AlertTriangle } from "lucide-react"

export function LoginForm({
  className,
  ...props
}: React.ComponentProps<"form">) {
  const { login } = useAuth()
  const router = useRouter()
  const [email, setEmail] = useState("admin@smarttrip.vn")
  const [password, setPassword] = useState("12345678")
  const [error, setError] = useState<string | null>(null)
  const [loading, setLoading] = useState(false)

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setError(null)
    setLoading(true)

    try {
      await login({ email, password })
      router.push("/dashboard")
    } catch (err: any) {
      console.error(err)
      setError(err?.message || "Đăng nhập thất bại. Vui lòng kiểm tra lại tài khoản hoặc mật khẩu.")
    } finally {
      setLoading(false)
    }
  }

  return (
    <form className={cn("flex flex-col gap-6", className)} onSubmit={handleSubmit} {...props}>
      <div className="flex flex-col items-center gap-2 text-center">
        <h1 className="text-2xl font-bold">Đăng nhập hệ thống</h1>
        <p className="text-muted-foreground text-sm text-balance">
          Nhập email và mật khẩu của bạn để truy cập trang quản trị
        </p>
      </div>
      
      {error && (
        <div className="flex gap-2 items-center p-3 text-xs rounded-lg bg-destructive/10 text-destructive border border-destructive/20">
          <AlertTriangle className="h-4 w-4 shrink-0" />
          <span>{error}</span>
        </div>
      )}

      <div className="grid gap-6">
        <div className="grid gap-3">
          <Label htmlFor="email">Email</Label>
          <Input 
            id="email" 
            type="email" 
            placeholder="admin@smarttrip.com" 
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            required 
            disabled={loading}
          />
        </div>
        <div className="grid gap-3">
          <Label htmlFor="password">Mật khẩu</Label>
          <Input 
            id="password" 
            type="password" 
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            required 
            disabled={loading}
          />
        </div>
        <Button type="submit" className="w-full cursor-pointer" disabled={loading}>
          {loading ? "Đang đăng nhập..." : "Đăng nhập"}
        </Button>
      </div>
    </form>
  )
}
