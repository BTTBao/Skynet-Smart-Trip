using SmartTrip.Application.DTOs.Admin;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace SmartTrip.Application.Interfaces.Admin;

public interface IAdminService
{
    Task<AdminDashboardDto> GetDashboardStatsAsync(DateOnly? startDate = null, DateOnly? endDate = null);
    Task<AdminUserStatsDto> GetUsersAsync(string? search = null);
    Task<AdminUserDto> CreateUserAsync(AdminCreateUserRequest request);
    Task<AdminUserDto> UpdateUserAsync(int userId, AdminUpdateUserRequest request);
    Task<AdminUserDto> UpdateUserStatusAsync(int userId, bool isActive);
    Task<AdminUserPasswordResetDto> ResetUserPasswordAsync(int userId);
    Task DeleteUserAsync(int userId);
    Task<AdminTransportStatsDto> GetTransportStatsAsync();
    Task<AdminTransportScheduleDto> CreateTransportScheduleAsync(AdminCreateTransportScheduleRequest request);
    Task<AdminTransportScheduleDto> UpdateTransportScheduleAsync(int scheduleId, AdminUpdateTransportScheduleRequest request);
    Task DeleteTransportScheduleAsync(int scheduleId);
    Task<List<AdminTransportCompanyDto>> GetTransportCompaniesAsync();
    Task<AdminTransportCompanyDto> CreateTransportCompanyAsync(AdminCreateTransportCompanyRequest request);
    Task<AdminTransportCompanyDto> UpdateTransportCompanyAsync(int companyId, AdminUpdateTransportCompanyRequest request);
    Task DeleteTransportCompanyAsync(int companyId);
    Task<List<AdminTransportSeatDto>> UpdateSeatMapAsync(int scheduleId, List<AdminUpdateSeatRequest> seats);
    Task<AdminBookingStatsDto> GetBookingStatsAsync();
    Task<AdminBookingDetailDto> GetBookingDetailAsync(int bookingId);
    Task<AdminBookingDto> UpdateBookingStatusAsync(int bookingId, AdminUpdateBookingStatusRequest request);
    Task<List<AdminDestinationDto>> GetDestinationsAsync();
    Task<AdminDestinationDto> CreateDestinationAsync(AdminDestinationRequest request);
    Task<AdminDestinationDto> UpdateDestinationAsync(int destinationId, AdminDestinationRequest request);
    Task DeleteDestinationAsync(int destinationId);
    Task<List<AdminHotelDto>> GetHotelsAsync();
    Task<AdminHotelDto> CreateHotelAsync(AdminHotelRequest request);
    Task<AdminHotelDto> UpdateHotelAsync(int hotelId, AdminHotelRequest request);
    Task DeleteHotelAsync(int hotelId);
    Task<List<AdminPromotionDto>> GetPromotionsAsync();
    Task<AdminPromotionDto> CreatePromotionAsync(AdminPromotionRequest request);
    Task<AdminPromotionDto> UpdatePromotionAsync(int promotionId, AdminPromotionRequest request);
    Task DeletePromotionAsync(int promotionId);
    Task<AdminReportSummaryDto> GetReportSummaryAsync();
}
