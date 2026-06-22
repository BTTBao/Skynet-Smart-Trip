import { fetchClient } from '@/lib/fetchClient';

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
  actualRevenue: string;
  actualRevenueValue: number;
  actualProfit: string;
  actualProfitValue: number;
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
  availableRoomQty: number;
  lowestPrice: number;
  totalRevenue: number;
  totalProfit: number;
  bookedRoomQty: number;
}

export interface AdminHotelRequest {
  destinationId: number;
  name: string;
  address: string;
  starRating: number;
  description: string;
  isAvailable: boolean;
}

export interface AdminRoom {
  id: number;
  hotelId: number;
  roomType: string;
  capacity: number;
  pricePerNight: number;
  commissionRate: number;
  availableQty: number;
  isSelling: boolean;
  imageUrls: string[];
  totalRevenue: number;
  totalProfit: number;
  bookedRoomQty: number;
  bookingCount: number;
}

export interface AdminHotelDetail extends AdminHotel {
  rooms: AdminRoom[];
}

export interface AdminRoomRequest {
  roomType: string;
  capacity: number;
  pricePerNight: number;
  commissionRate: number;
  availableQty: number;
  imageUrls: string[];
}

export interface AdminImageUploadResult {
  imageUrl: string;
  relativeUrl: string;
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

export type VehicleRentalType = 'ManualMotorbike' | 'Scooter' | 'Car' | 'MultiSeatCar';

export interface AdminVehicleRentalOption {
  id: number;
  vehicleType: VehicleRentalType;
  vehicleTypeLabel: string;
  maxSeats?: number | null;
  pricePerDay: number;
  isAvailable: boolean;
}

export interface AdminVehicleRentalShop {
  id: number;
  name: string;
  phoneNumber: string;
  address: string;
  destinationId: number;
  destinationName: string;
  description: string;
  imageUrl: string;
  isActive: boolean;
  createdAt: string;
  optionCount: number;
  minPricePerDay: number;
  vehicleTypeLabels: string[];
  vehicleOptions: AdminVehicleRentalOption[];
}

export interface AdminVehicleRentalOptionRequest {
  vehicleType: VehicleRentalType;
  maxSeats?: number | null;
  pricePerDay: number;
  isAvailable: boolean;
}

export interface AdminVehicleRentalShopRequest {
  name: string;
  phoneNumber: string;
  address: string;
  destinationId: number;
  description: string;
  imageUrl: string;
  isActive: boolean;
  vehicleOptions: AdminVehicleRentalOptionRequest[];
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

export interface AdminExplorePost {
  id: number;
  title: string;
  excerpt: string;
  content: string;
  thumbnailUrl: string;
  imageUrls: string[];
  location: string;
  city: string;
  province: string;
  region: 'north' | 'central' | 'south';
  latitude?: number | null;
  longitude?: number | null;
  authorName: string;
  createdAt: string;
  isVisible: boolean;
  costLevel: number;
  likes: number;
  saves: number;
  views: number;
  commentCount: number;
  rating: number;
  ratingCount: number;
  tags: string[];
}

export interface AdminExplorePostRequest {
  title: string;
  content: string;
  location: string;
  city?: string;
  province?: string;
  region?: 'north' | 'central' | 'south';
  latitude?: number | null;
  longitude?: number | null;
  costLevel: number;
  isVisible: boolean;
  imageUrls: string[];
  tags: string[];
}

export interface AdminNotification {
  id: number;
  userId?: number | null;
  userName: string;
  userEmail: string;
  title: string;
  message: string;
  type: string;
  referenceType?: string | null;
  referenceId?: number | null;
  actionUrl?: string | null;
  isRead: boolean;
  createdAt: string;
}

export interface AdminNotificationStats {
  totalNotifications: number;
  unreadNotifications: number;
  readNotifications: number;
  targetableUsers: number;
  notifications: AdminNotification[];
}

export interface AdminSendNotificationRequest {
  recipientMode: 'all' | 'active' | 'role' | 'users';
  userIds: number[];
  role?: AdminUser['role'];
  channels: Array<'in_app' | 'email' | 'fcm'>;
  title: string;
  message: string;
  type: string;
  referenceType?: string;
  referenceId?: number | null;
  actionUrl?: string;
}

export interface AdminNotificationSendResult {
  targetedUsers: number;
  inAppCreated: number;
  pushAttempted: number;
  emailAttempted: number;
  emailSent: number;
  failed: number;
  errors: string[];
}

const looksLikeMojibake = (value: string) =>
  /[ÃÄÂÆº»\u0090\u0091]/.test(value);

const normalizeLegacyText = (value?: string | null) => {
  if (!value || !looksLikeMojibake(value)) {
    return value ?? '';
  }

  try {
    const bytes = Uint8Array.from(value, (char) => char.charCodeAt(0) & 0xff);
    const decoded = new TextDecoder('utf-8').decode(bytes);
    return looksLikeMojibake(decoded) ? value : decoded;
  } catch {
    return value;
  }
};

const normalizeNotification = (notification: AdminNotification): AdminNotification => ({
  ...notification,
  userName: normalizeLegacyText(notification.userName),
  title: normalizeLegacyText(notification.title),
  message: normalizeLegacyText(notification.message),
});

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
  totalProfit: string;
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
  totalProfit: number;
  totalBookings: number;
  newCustomers: number;
  paidBookings: number;
  pendingBookings: number;
  cancelledBookings: number;
  bookings: AdminBooking[];
}

export const adminService = {
  getDashboardStats: async (params?: { startDate?: string; endDate?: string }): Promise<AdminDashboardStats> => {
    return fetchClient.get<AdminDashboardStats>('/admin/dashboard', { params });
  },

  getUsers: async (params?: { search?: string }): Promise<AdminUserStats> => {
    return fetchClient.get<AdminUserStats>('/admin/users', { params });
  },

  createUser: async (payload: AdminCreateUserRequest): Promise<AdminUser> => {
    return fetchClient.post<AdminUser>('/admin/users', payload);
  },

  updateUser: async (userId: number, payload: AdminUpdateUserRequest): Promise<AdminUser> => {
    return fetchClient.put<AdminUser>(`/admin/users/${userId}`, payload);
  },

  updateUserStatus: async (userId: number, isActive: boolean): Promise<AdminUser> => {
    return fetchClient.patch<AdminUser>(`/admin/users/${userId}/status`, { isActive });
  },

  resetUserPassword: async (userId: number): Promise<AdminUserPasswordReset> => {
    return fetchClient.post<AdminUserPasswordReset>(`/admin/users/${userId}/reset-password`);
  },

  deleteUser: async (userId: number): Promise<void> => {
    await fetchClient.delete(`/admin/users/${userId}`);
  },

  getTransportStats: async (): Promise<AdminTransportStats> => {
    return fetchClient.get<AdminTransportStats>('/admin/transport');
  },

  createTransportSchedule: async (
    payload: AdminCreateTransportScheduleRequest
  ): Promise<AdminTransportSchedule> => {
    return fetchClient.post<AdminTransportSchedule>('/admin/transport/schedules', payload);
  },

  updateTransportSchedule: async (
    scheduleId: number,
    payload: AdminUpdateTransportScheduleRequest
  ): Promise<AdminTransportSchedule> => {
    return fetchClient.put<AdminTransportSchedule>(`/admin/transport/schedules/${scheduleId}`, payload);
  },

  deleteTransportSchedule: async (scheduleId: number): Promise<void> => {
    await fetchClient.delete(`/admin/transport/schedules/${scheduleId}`);
  },

  getTransportCompanies: async (): Promise<AdminTransportCompany[]> => {
    return fetchClient.get<AdminTransportCompany[]>('/admin/transport/companies');
  },

  createTransportCompany: async (
    payload: AdminCreateTransportCompanyRequest
  ): Promise<AdminTransportCompany> => {
    return fetchClient.post<AdminTransportCompany>('/admin/transport/companies', payload);
  },

  updateTransportCompany: async (
    companyId: number,
    payload: AdminUpdateTransportCompanyRequest
  ): Promise<AdminTransportCompany> => {
    return fetchClient.put<AdminTransportCompany>(`/admin/transport/companies/${companyId}`, payload);
  },

  deleteTransportCompany: async (companyId: number): Promise<void> => {
    await fetchClient.delete(`/admin/transport/companies/${companyId}`);
  },

  updateSeatMap: async (
    scheduleId: number,
    payload: AdminUpdateSeatRequest[]
  ): Promise<AdminTransportSeat[]> => {
    return fetchClient.put<AdminTransportSeat[]>(`/admin/transport/schedules/${scheduleId}/seats`, payload);
  },

  getBookingStats: async (): Promise<AdminBookingStats> => {
    return fetchClient.get<AdminBookingStats>('/admin/bookings');
  },

  getBookingDetail: async (bookingId: number): Promise<AdminBookingDetail> => {
    return fetchClient.get<AdminBookingDetail>(`/admin/bookings/${bookingId}`);
  },

  updateBookingStatus: async (
    bookingId: number,
    payload: AdminUpdateBookingStatusRequest
  ): Promise<AdminBooking> => {
    return fetchClient.patch<AdminBooking>(`/admin/bookings/${bookingId}/status`, payload);
  },

  getDestinations: async (): Promise<AdminDestination[]> => {
    const data = await fetchClient.get<AdminDestination[]>('/admin/destinations');
    return Array.isArray(data) ? data.map((item) => normalizeDestination(item as Record<string, unknown>)) : [];
  },

  createDestination: async (payload: AdminDestinationRequest): Promise<AdminDestination> => {
    return fetchClient.post<AdminDestination>('/admin/destinations', payload);
  },

  updateDestination: async (destinationId: number, payload: AdminDestinationRequest): Promise<AdminDestination> => {
    return fetchClient.put<AdminDestination>(`/admin/destinations/${destinationId}`, payload);
  },

  deleteDestination: async (destinationId: number): Promise<void> => {
    await fetchClient.delete(`/admin/destinations/${destinationId}`);
  },

  getHotels: async (): Promise<AdminHotel[]> => {
    return fetchClient.get<AdminHotel[]>('/admin/hotels');
  },

  getHotelDetail: async (hotelId: number): Promise<AdminHotelDetail> => {
    return fetchClient.get<AdminHotelDetail>(`/admin/hotels/${hotelId}`);
  },

  createHotel: async (payload: AdminHotelRequest): Promise<AdminHotel> => {
    return fetchClient.post<AdminHotel>('/admin/hotels', payload);
  },

  updateHotel: async (hotelId: number, payload: AdminHotelRequest): Promise<AdminHotel> => {
    return fetchClient.put<AdminHotel>(`/admin/hotels/${hotelId}`, payload);
  },

  deleteHotel: async (hotelId: number): Promise<void> => {
    await fetchClient.delete(`/admin/hotels/${hotelId}`);
  },

  createRoom: async (hotelId: number, payload: AdminRoomRequest): Promise<AdminRoom> => {
    return fetchClient.post<AdminRoom>(`/admin/hotels/${hotelId}/rooms`, payload);
  },

  updateRoom: async (roomId: number, payload: AdminRoomRequest): Promise<AdminRoom> => {
    return fetchClient.put<AdminRoom>(`/admin/rooms/${roomId}`, payload);
  },

  uploadRoomImage: async (file: File): Promise<AdminImageUploadResult> => {
    return uploadAdminImage('/admin/uploads/room-images', file);
  },

  uploadDestinationCoverImage: async (file: File): Promise<AdminImageUploadResult> => {
    return uploadAdminImage('/admin/uploads/destination-covers', file);
  },

  uploadTransportCompanyLogo: async (file: File): Promise<AdminImageUploadResult> => {
    return uploadAdminImage('/admin/uploads/transport-company-logos', file);
  },

  uploadVehicleRentalImage: async (file: File): Promise<AdminImageUploadResult> => {
    return uploadAdminImage('/admin/uploads/vehicle-rental-images', file);
  },

  getVehicleRentalShops: async (): Promise<AdminVehicleRentalShop[]> => {
    return fetchClient.get<AdminVehicleRentalShop[]>('/admin/vehicle-rental/shops');
  },

  getVehicleRentalShopDetail: async (shopId: number): Promise<AdminVehicleRentalShop> => {
    return fetchClient.get<AdminVehicleRentalShop>(`/admin/vehicle-rental/shops/${shopId}`);
  },

  createVehicleRentalShop: async (payload: AdminVehicleRentalShopRequest): Promise<AdminVehicleRentalShop> => {
    return fetchClient.post<AdminVehicleRentalShop>('/admin/vehicle-rental/shops', payload);
  },

  updateVehicleRentalShop: async (
    shopId: number,
    payload: AdminVehicleRentalShopRequest
  ): Promise<AdminVehicleRentalShop> => {
    return fetchClient.put<AdminVehicleRentalShop>(`/admin/vehicle-rental/shops/${shopId}`, payload);
  },

  deleteVehicleRentalShop: async (shopId: number): Promise<void> => {
    await fetchClient.delete(`/admin/vehicle-rental/shops/${shopId}`);
  },

  deleteRoom: async (roomId: number): Promise<void> => {
    await fetchClient.delete(`/admin/rooms/${roomId}`);
  },

  getPromotions: async (): Promise<AdminPromotion[]> => {
    return fetchClient.get<AdminPromotion[]>('/admin/promotions');
  },

  createPromotion: async (payload: AdminPromotionRequest): Promise<AdminPromotion> => {
    return fetchClient.post<AdminPromotion>('/admin/promotions', payload);
  },

  updatePromotion: async (promotionId: number, payload: AdminPromotionRequest): Promise<AdminPromotion> => {
    return fetchClient.put<AdminPromotion>(`/admin/promotions/${promotionId}`, payload);
  },

  deletePromotion: async (promotionId: number): Promise<void> => {
    await fetchClient.delete(`/admin/promotions/${promotionId}`);
  },

  getReportSummary: async (): Promise<AdminReportSummary> => {
    return fetchClient.get<AdminReportSummary>('/admin/reports/summary');
  },

  getExplorePosts: async (params?: { search?: string }): Promise<AdminExplorePost[]> => {
    return fetchClient.get<AdminExplorePost[]>('/admin/explore/posts', { params });
  },

  createExplorePost: async (payload: AdminExplorePostRequest): Promise<AdminExplorePost> => {
    return fetchClient.post<AdminExplorePost>('/admin/explore/posts', payload);
  },

  updateExplorePost: async (postId: number, payload: AdminExplorePostRequest): Promise<AdminExplorePost> => {
    return fetchClient.put<AdminExplorePost>(`/admin/explore/posts/${postId}`, payload);
  },

  updateExplorePostVisibility: async (postId: number, isVisible: boolean): Promise<AdminExplorePost> => {
    return fetchClient.patch<AdminExplorePost>(`/admin/explore/posts/${postId}/visibility`, { isVisible });
  },

  deleteExplorePost: async (postId: number): Promise<void> => {
    await fetchClient.delete(`/admin/explore/posts/${postId}`);
  },

  uploadExplorePostImage: async (file: File): Promise<{ imageUrl: string; relativeUrl: string }> => {
    return uploadAdminImage('/explore/posts/images', file);
  },

  getNotifications: async (params?: { search?: string }): Promise<AdminNotificationStats> => {
    const response = await fetchClient.get<AdminNotificationStats>('/admin/notifications', { params });
    return {
      ...response,
      notifications: response.notifications.map(normalizeNotification),
    };
  },

  sendNotification: async (payload: AdminSendNotificationRequest): Promise<AdminNotificationSendResult> => {
    return fetchClient.post<AdminNotificationSendResult>('/admin/notifications/send', payload);
  },
};

async function uploadAdminImage(path: string, file: File): Promise<AdminImageUploadResult> {
  const formData = new FormData();
  formData.append('file', file);
  const result = await fetchClient.post<Record<string, unknown>>(path, formData);
  return {
    imageUrl: String(result.imageUrl ?? result.ImageUrl ?? ''),
    relativeUrl: String(
      result.relativeUrl ?? result.RelativeUrl ?? result.imagePath ?? result.ImagePath ?? ''
    ),
  };
}

function normalizeDestination(raw: Record<string, unknown>): AdminDestination {
  return {
    id: Number(raw.id ?? raw.Id ?? 0),
    name: String(raw.name ?? raw.Name ?? ''),
    description: String(raw.description ?? raw.Description ?? ''),
    coverImageUrl: String(raw.coverImageUrl ?? raw.CoverImageUrl ?? ''),
    isHot: Boolean(raw.isHot ?? raw.IsHot ?? false),
    hotelCount: Number(raw.hotelCount ?? raw.HotelCount ?? 0),
    tripCount: Number(raw.tripCount ?? raw.TripCount ?? 0),
  };
}
