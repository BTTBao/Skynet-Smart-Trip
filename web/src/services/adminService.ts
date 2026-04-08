import apiClient from './apiClient';

export interface AdminRecentBooking {
  id: string;
  initials: string;
  name: string;
  destination: string;
  amount: string;
  status: 'paid' | 'pending' | 'cancelled';
}

export interface AdminDashboardStats {
  totalRevenue: number;
  totalProfit: number;
  totalUsers: number;
  newUsersToday: number;
  activeTrips: number;
  recentBookings: AdminRecentBooking[];
}

export interface AdminUser {
  id: number;
  displayId: string;
  name: string;
  email: string;
  phone: string;
  joinDate: string;
  status: 'active' | 'blocked';
  avatarBg?: string;
}

export interface AdminUserStats {
  totalUsers: number;
  activeUsers: number;
  newUsers: number;
  blockedUsers: number;
  users: AdminUser[];
}

export const adminService = {
  getDashboardStats: async (): Promise<AdminDashboardStats> => {
    const response = await apiClient.get<AdminDashboardStats>('/admin/dashboard');
    return response.data;
  },

  getUsers: async (): Promise<AdminUserStats> => {
    const response = await apiClient.get<AdminUserStats>('/admin/users');
    return response.data;
  }
};
