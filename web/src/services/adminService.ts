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
  startDate: string;
  endDate: string;
  chartSeries: AdminDashboardChartPoint[];
  activityFeed: AdminActivityFeedItem[];
  recentBookings: AdminRecentBooking[];
}

export interface AdminDashboardChartPoint {
  label: string;
  revenue: number;
  profit: number;
  bookings: number;
}

export interface AdminActivityFeedItem {
  id: string;
  type: 'user' | 'booking' | 'payment';
  title: string;
  description: string;
  occurredAt: string;
}

export interface AdminUser {
  id: number;
  displayId: string;
  name: string;
  email: string;
  phone: string;
  joinDate: string;
  lastLoginAt: string;
  role: 'customer' | 'staff' | 'partner' | 'admin';
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

export interface AdminCreateUserRequest {
  name: string;
  email: string;
  phone: string;
  role: AdminUser['role'];
  isActive: boolean;
}

export interface AdminUpdateUserRequest extends AdminCreateUserRequest {}

export interface AdminUserPasswordReset {
  resetLink: string;
  emailSent: boolean;
}

export interface AdminTransportSchedule {
  id: number;
  companyId: number;
  fromDestinationId: number;
  toDestinationId: number;
  code: string;
  companyName: string;
  route: string;
  departureTime: string;
  departureDate: string;
  departureAt: string;
  arrivalAt: string;
  status: 'running' | 'upcoming' | 'completed';
  ticketPrice: string;
  affiliateProfit: string;
  priceValue: number;
  commissionRate: number;
  occupiedSeats: number;
  totalSeats: number;
  seats: AdminTransportSeat[];
}

export interface AdminTransportSeat {
  id: number;
  seatNumber: string;
  status: 'available' | 'locked' | 'booked';
}

export interface AdminTransportCompany {
  id: number;
  name: string;
  hotline: string;
  logoUrl: string;
  scheduleCount: number;
  averageCommissionRate: number;
}

export interface AdminCreateTransportScheduleRequest {
  companyId: number;
  fromDestinationId: number;
  toDestinationId: number;
  departureAt: string;
  arrivalAt: string;
  price: number;
  commissionRate: number;
  totalSeats: number;
}

export interface AdminUpdateTransportScheduleRequest extends AdminCreateTransportScheduleRequest {}

export interface AdminCreateTransportCompanyRequest {
  name: string;
  hotline: string;
  logoUrl: string;
}

export interface AdminUpdateTransportCompanyRequest extends AdminCreateTransportCompanyRequest {}

export interface AdminUpdateSeatRequest {
  id: number;
  status: AdminTransportSeat['status'];
}

export interface AdminDestination {
  id: number;
  name: string;
  description: string;
  coverImageUrl: string;
  isHot: boolean;
  hotelCount: number;
  tripCount: number;
}

export interface AdminDestinationRequest {
  name: string;
  description: string;
  coverImageUrl: string;
  isHot: boolean;
}

export interface AdminHotel {
  id: number;
  destinationId: number;
  destinationName: string;
  name: string;
  address: string;
  starRating: number;
  description: string;
  isAvailable: boolean;
  roomCount: number;
}

export interface AdminHotelRequest {
  destinationId: number;
  name: string;
  address: string;
  starRating: number;
  description: string;
  isAvailable: boolean;
}

export interface AdminPromotion {
  id: number;
  code: string;
  discountPercent: number;
  maxDiscountAmount: number;
  validUntil: string;
  usageLimit: number;
  usedCount: number;
  isActive: boolean;
}

export interface AdminPromotionRequest {
  code: string;
  discountPercent: number;
  maxDiscountAmount: number;
  validUntil: string;
  usageLimit: number;
}

export interface AdminReportBreakdown {
  label: string;
  value: number;
}

export interface AdminReportSummary {
  totalRevenue: number;
  totalProfit: number;
  totalUsers: number;
  totalBookings: number;
  totalSchedules: number;
  topDestinations: AdminReportBreakdown[];
  revenueByPaymentStatus: AdminReportBreakdown[];
}

export interface AdminTransportStats {
  totalSchedules: number;
  totalSchedulesThisMonth: number;
  expectedRevenueThisMonth: number;
  affiliateRevenueThisMonth: number;
  averageOccupancyRate: number;
  affiliateGrowthRate: number;
  activeSchedules: number;
  upcomingSchedules: number;
  completedSchedules: number;
  totalCompanies: number;
  schedules: AdminTransportSchedule[];
}

export interface AdminBooking {
  id: number;
  displayId: string;
  userName: string;
  userCode: string;
  destination: string;
  totalAmount: string;
  summary: string;
  paymentStatus: 'paid' | 'pending' | 'cancelled';
  tripStatus: 'paid' | 'pending' | 'cancelled';
  createdAt: string;
}

export interface AdminBookingDetail extends AdminBooking {
  tripTitle: string;
  travelWindow: string;
  itinerary: AdminBookingItineraryItem[];
  paymentHistory: AdminBookingPaymentHistoryItem[];
}

export interface AdminBookingItineraryItem {
  dayNumber: number;
  serviceType: string;
  serviceName: string;
  quantity: number;
  amount: number;
}

export interface AdminBookingPaymentHistoryItem {
  transactionId: string;
  paymentMethod: string;
  amount: number;
  status: string;
  paidAt: string;
}

export interface AdminUpdateBookingStatusRequest {
  paymentStatus: 'paid' | 'pending' | 'cancelled' | 'refunded';
  tripStatus: 'paid' | 'pending' | 'cancelled';
  amount?: number;
}

export interface AdminBookingStats {
  totalRevenue: number;
  totalBookings: number;
  newCustomers: number;
  paidBookings: number;
  pendingBookings: number;
  cancelledBookings: number;
  bookings: AdminBooking[];
}

export const adminService = {
  getDashboardStats: async (params?: { startDate?: string; endDate?: string }): Promise<AdminDashboardStats> => {
    const response = await apiClient.get<AdminDashboardStats>('/admin/dashboard', { params });
    return response.data;
  },

  getUsers: async (params?: { search?: string }): Promise<AdminUserStats> => {
    const response = await apiClient.get<AdminUserStats>('/admin/users', { params });
    return response.data;
  },

  createUser: async (payload: AdminCreateUserRequest): Promise<AdminUser> => {
    const response = await apiClient.post<AdminUser>('/admin/users', payload);
    return response.data;
  },

  updateUser: async (userId: number, payload: AdminUpdateUserRequest): Promise<AdminUser> => {
    const response = await apiClient.put<AdminUser>(`/admin/users/${userId}`, payload);
    return response.data;
  },

  updateUserStatus: async (userId: number, isActive: boolean): Promise<AdminUser> => {
    const response = await apiClient.patch<AdminUser>(`/admin/users/${userId}/status`, { isActive });
    return response.data;
  },

  resetUserPassword: async (userId: number): Promise<AdminUserPasswordReset> => {
    const response = await apiClient.post<AdminUserPasswordReset>(`/admin/users/${userId}/reset-password`);
    return response.data;
  },

  deleteUser: async (userId: number) => {
    await apiClient.delete(`/admin/users/${userId}`);
  },

  getTransportStats: async (): Promise<AdminTransportStats> => {
    const response = await apiClient.get<AdminTransportStats>('/admin/transport');
    return response.data;
  },

  createTransportSchedule: async (
    payload: AdminCreateTransportScheduleRequest
  ): Promise<AdminTransportSchedule> => {
    const response = await apiClient.post<AdminTransportSchedule>('/admin/transport/schedules', payload);
    return response.data;
  },

  updateTransportSchedule: async (
    scheduleId: number,
    payload: AdminUpdateTransportScheduleRequest
  ): Promise<AdminTransportSchedule> => {
    const response = await apiClient.put<AdminTransportSchedule>(`/admin/transport/schedules/${scheduleId}`, payload);
    return response.data;
  },

  deleteTransportSchedule: async (scheduleId: number) => {
    await apiClient.delete(`/admin/transport/schedules/${scheduleId}`);
  },

  getTransportCompanies: async (): Promise<AdminTransportCompany[]> => {
    const response = await apiClient.get<AdminTransportCompany[]>('/admin/transport/companies');
    return response.data;
  },

  createTransportCompany: async (
    payload: AdminCreateTransportCompanyRequest
  ): Promise<AdminTransportCompany> => {
    const response = await apiClient.post<AdminTransportCompany>('/admin/transport/companies', payload);
    return response.data;
  },

  updateTransportCompany: async (
    companyId: number,
    payload: AdminUpdateTransportCompanyRequest
  ): Promise<AdminTransportCompany> => {
    const response = await apiClient.put<AdminTransportCompany>(`/admin/transport/companies/${companyId}`, payload);
    return response.data;
  },

  deleteTransportCompany: async (companyId: number) => {
    await apiClient.delete(`/admin/transport/companies/${companyId}`);
  },

  updateSeatMap: async (
    scheduleId: number,
    payload: AdminUpdateSeatRequest[]
  ): Promise<AdminTransportSeat[]> => {
    const response = await apiClient.put<AdminTransportSeat[]>(`/admin/transport/schedules/${scheduleId}/seats`, payload);
    return response.data;
  },

  getBookingStats: async (): Promise<AdminBookingStats> => {
    const response = await apiClient.get<AdminBookingStats>('/admin/bookings');
    return response.data;
  },

  getBookingDetail: async (bookingId: number): Promise<AdminBookingDetail> => {
    const response = await apiClient.get<AdminBookingDetail>(`/admin/bookings/${bookingId}`);
    return response.data;
  },

  updateBookingStatus: async (
    bookingId: number,
    payload: AdminUpdateBookingStatusRequest
  ): Promise<AdminBooking> => {
    const response = await apiClient.patch<AdminBooking>(`/admin/bookings/${bookingId}/status`, payload);
    return response.data;
  },

  getDestinations: async (): Promise<AdminDestination[]> => {
    const response = await apiClient.get<AdminDestination[]>('/admin/destinations');
    return response.data;
  },

  createDestination: async (payload: AdminDestinationRequest): Promise<AdminDestination> => {
    const response = await apiClient.post<AdminDestination>('/admin/destinations', payload);
    return response.data;
  },

  updateDestination: async (destinationId: number, payload: AdminDestinationRequest): Promise<AdminDestination> => {
    const response = await apiClient.put<AdminDestination>(`/admin/destinations/${destinationId}`, payload);
    return response.data;
  },

  deleteDestination: async (destinationId: number) => {
    await apiClient.delete(`/admin/destinations/${destinationId}`);
  },

  getHotels: async (): Promise<AdminHotel[]> => {
    const response = await apiClient.get<AdminHotel[]>('/admin/hotels');
    return response.data;
  },

  createHotel: async (payload: AdminHotelRequest): Promise<AdminHotel> => {
    const response = await apiClient.post<AdminHotel>('/admin/hotels', payload);
    return response.data;
  },

  updateHotel: async (hotelId: number, payload: AdminHotelRequest): Promise<AdminHotel> => {
    const response = await apiClient.put<AdminHotel>(`/admin/hotels/${hotelId}`, payload);
    return response.data;
  },

  deleteHotel: async (hotelId: number) => {
    await apiClient.delete(`/admin/hotels/${hotelId}`);
  },

  getPromotions: async (): Promise<AdminPromotion[]> => {
    const response = await apiClient.get<AdminPromotion[]>('/admin/promotions');
    return response.data;
  },

  createPromotion: async (payload: AdminPromotionRequest): Promise<AdminPromotion> => {
    const response = await apiClient.post<AdminPromotion>('/admin/promotions', payload);
    return response.data;
  },

  updatePromotion: async (promotionId: number, payload: AdminPromotionRequest): Promise<AdminPromotion> => {
    const response = await apiClient.put<AdminPromotion>(`/admin/promotions/${promotionId}`, payload);
    return response.data;
  },

  deletePromotion: async (promotionId: number) => {
    await apiClient.delete(`/admin/promotions/${promotionId}`);
  },

  getReportSummary: async (): Promise<AdminReportSummary> => {
    const response = await apiClient.get<AdminReportSummary>('/admin/reports/summary');
    return response.data;
  },
};
