using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;
using SmartTrip.Application.DTOs.Admin;
using SmartTrip.Domain.Entities;
using SmartTrip.Domain.Enums;

namespace SmartTrip.Infrastructure.Services.Admin;

public partial class AdminService
{
    public async Task<AdminTransportScheduleDto> CreateTransportScheduleAsync(AdminCreateTransportScheduleRequest request)
    {
        await EnsureTransportReferenceAsync(request.CompanyId, request.FromDestinationId, request.ToDestinationId);
        EnsureTransportScheduleTimes(request.DepartureAt, request.ArrivalAt, request.TotalSeats);

        var schedule = new BusSchedule
        {
            CompanyId = request.CompanyId,
            FromDestId = request.FromDestinationId,
            ToDestId = request.ToDestinationId,
            DepartureTime = request.DepartureAt,
            ArrivalTime = request.ArrivalAt,
            Price = request.Price,
            CommissionRate = request.CommissionRate,
            TotalSeats = request.TotalSeats
        };

        _context.BusSchedules.Add(schedule);
        await _context.SaveChangesAsync();

        var seats = BuildSeats(schedule.Id, request.TotalSeats);
        _context.Seats.AddRange(seats);
        await _context.SaveChangesAsync();

        var createdSchedule = await _context.BusSchedules
            .Include(s => s.Company)
            .Include(s => s.FromDest)
            .Include(s => s.ToDest)
            .Include(s => s.Seats)
            .FirstAsync(s => s.Id == schedule.Id);

        return MapTransportSchedule(createdSchedule, DateTime.UtcNow);
    }

    public async Task<AdminTransportScheduleDto> UpdateTransportScheduleAsync(int scheduleId, AdminUpdateTransportScheduleRequest request)
    {
        await EnsureTransportReferenceAsync(request.CompanyId, request.FromDestinationId, request.ToDestinationId);
        EnsureTransportScheduleTimes(request.DepartureAt, request.ArrivalAt, request.TotalSeats);

        var schedule = await _context.BusSchedules
            .Include(s => s.Company)
            .Include(s => s.FromDest)
            .Include(s => s.ToDest)
            .Include(s => s.Seats)
            .FirstOrDefaultAsync(s => s.Id == scheduleId);

        if (schedule is null)
        {
            throw new BadHttpRequestException("Không tìm thấy lịch trình chuyến xe.");
        }

        schedule.CompanyId = request.CompanyId;
        schedule.FromDestId = request.FromDestinationId;
        schedule.ToDestId = request.ToDestinationId;
        schedule.DepartureTime = request.DepartureAt;
        schedule.ArrivalTime = request.ArrivalAt;
        schedule.Price = request.Price;
        schedule.CommissionRate = request.CommissionRate;
        schedule.TotalSeats = request.TotalSeats;

        var currentSeats = schedule.Seats.OrderBy(seat => seat.Id).ToList();
        if (request.TotalSeats > currentSeats.Count)
        {
            var newSeats = BuildSeats(schedule.Id, request.TotalSeats - currentSeats.Count, currentSeats.Count + 1);
            _context.Seats.AddRange(newSeats);
        }
        else if (request.TotalSeats < currentSeats.Count)
        {
            var removableSeats = currentSeats
                .Where(seat => seat.Status == SeatStatus.Available)
                .OrderByDescending(seat => seat.Id)
                .Take(currentSeats.Count - request.TotalSeats)
                .ToList();

            if (removableSeats.Count != currentSeats.Count - request.TotalSeats)
            {
                throw new BadHttpRequestException("Không thể giảm số ghế vì có ghế đang được giữ chỗ hoặc đã đặt.");
            }

            _context.Seats.RemoveRange(removableSeats);
        }

        await _context.SaveChangesAsync();

        var updatedSchedule = await _context.BusSchedules
            .Include(s => s.Company)
            .Include(s => s.FromDest)
            .Include(s => s.ToDest)
            .Include(s => s.Seats)
            .FirstAsync(s => s.Id == scheduleId);

        return MapTransportSchedule(updatedSchedule, DateTime.UtcNow);
    }

    public async Task DeleteTransportScheduleAsync(int scheduleId)
    {
        var schedule = await _context.BusSchedules
            .Include(s => s.Seats)
            .FirstOrDefaultAsync(s => s.Id == scheduleId);

        if (schedule is null)
        {
            throw new BadHttpRequestException("Không tìm thấy lịch trình chuyến xe.");
        }

        _context.Seats.RemoveRange(schedule.Seats);
        _context.BusSchedules.Remove(schedule);
        await _context.SaveChangesAsync();
    }

    public async Task<List<AdminTransportCompanyDto>> GetTransportCompaniesAsync()
    {
        var companies = await _context.BusCompanies
            .Include(company => company.BusSchedules)
            .OrderBy(company => company.Name)
            .ToListAsync();

        return companies.Select(MapTransportCompany).ToList();
    }

    public async Task<AdminTransportCompanyDto> CreateTransportCompanyAsync(AdminCreateTransportCompanyRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.Name))
        {
            throw new BadHttpRequestException("Tên nhà xe không được để trống.");
        }

        var company = new BusCompany
        {
            Name = request.Name.Trim(),
            Hotline = string.IsNullOrWhiteSpace(request.Hotline) ? null : request.Hotline.Trim(),
            LogoUrl = string.IsNullOrWhiteSpace(request.LogoUrl) ? null : request.LogoUrl.Trim()
        };

        _context.BusCompanies.Add(company);
        await _context.SaveChangesAsync();

        var createdCompany = await _context.BusCompanies
            .Include(item => item.BusSchedules)
            .FirstAsync(item => item.Id == company.Id);

        return MapTransportCompany(createdCompany);
    }

    public async Task<AdminTransportCompanyDto> UpdateTransportCompanyAsync(int companyId, AdminUpdateTransportCompanyRequest request)
    {
        var company = await _context.BusCompanies
            .Include(item => item.BusSchedules)
            .FirstOrDefaultAsync(item => item.Id == companyId);

        if (company is null)
        {
            throw new BadHttpRequestException("Không tìm thấy nhà xe.");
        }

        if (string.IsNullOrWhiteSpace(request.Name))
        {
            throw new BadHttpRequestException("Tên nhà xe không được để trống.");
        }

        company.Name = request.Name.Trim();
        company.Hotline = string.IsNullOrWhiteSpace(request.Hotline) ? null : request.Hotline.Trim();
        company.LogoUrl = string.IsNullOrWhiteSpace(request.LogoUrl) ? null : request.LogoUrl.Trim();

        await _context.SaveChangesAsync();

        return MapTransportCompany(company);
    }

    public async Task DeleteTransportCompanyAsync(int companyId)
    {
        var company = await _context.BusCompanies
            .Include(item => item.BusSchedules)
            .FirstOrDefaultAsync(item => item.Id == companyId);

        if (company is null)
        {
            throw new BadHttpRequestException("Không tìm thấy nhà xe.");
        }

        if (company.BusSchedules.Any())
        {
            throw new BadHttpRequestException("Không thể xóa nhà xe đang còn lịch trình hoạt động.");
        }

        _context.BusCompanies.Remove(company);
        await _context.SaveChangesAsync();
    }

    public async Task<List<AdminTransportSeatDto>> UpdateSeatMapAsync(int scheduleId, List<AdminUpdateSeatRequest> seats)
    {
        var schedule = await _context.BusSchedules
            .Include(item => item.Seats)
            .FirstOrDefaultAsync(item => item.Id == scheduleId);

        if (schedule is null)
        {
            throw new BadHttpRequestException("Không tìm thấy lịch trình chuyến xe.");
        }

        var seatDictionary = schedule.Seats.ToDictionary(seat => seat.Id);
        foreach (var seatRequest in seats)
        {
            if (!seatDictionary.TryGetValue(seatRequest.Id, out var seat))
            {
                throw new BadHttpRequestException("Có ghế không thuộc lịch trình đang chọn.");
            }

            seat.Status = ParseSeatStatus(seatRequest.Status);
        }

        await _context.SaveChangesAsync();

        return schedule.Seats
            .OrderBy(seat => seat.SeatNumber)
            .Select(seat => new AdminTransportSeatDto
            {
                Id = seat.Id,
                SeatNumber = seat.SeatNumber ?? $"S{seat.Id}",
                Status = (seat.Status ?? SeatStatus.Available).ToString().ToLowerInvariant()
            })
            .ToList();
    }

    public async Task<AdminBookingDetailDto> GetBookingDetailAsync(int bookingId)
    {
        var trip = await _context.Trips
            .Include(t => t.User)
            .Include(t => t.Destination)
            .Include(t => t.Payments)
            .Include(t => t.TripItineraries)
            .FirstOrDefaultAsync(t => t.Id == bookingId);

        if (trip is null)
        {
            throw new BadHttpRequestException("Không tìm thấy booking.");
        }

        var itinerary = new List<AdminBookingItineraryItemDto>();
        foreach (var item in trip.TripItineraries.OrderBy(itineraryItem => itineraryItem.DayNumber))
        {
            itinerary.Add(new AdminBookingItineraryItemDto
            {
                DayNumber = item.DayNumber ?? 0,
                ServiceType = item.ServiceType?.ToString() ?? "Unknown",
                ServiceName = await ResolveItineraryServiceNameAsync(item),
                Quantity = item.Quantity ?? 0,
                Amount = item.BookedPrice.GetValueOrDefault()
            });
        }

        var paymentHistory = trip.Payments
            .OrderByDescending(payment => payment.PaidAt)
            .Select(payment => new AdminBookingPaymentHistoryDto
            {
                TransactionId = payment.TransactionId ?? $"PAY-{payment.Id:D4}",
                PaymentMethod = payment.PaymentMethod?.ToString() ?? "Unknown",
                Amount = payment.Amount.GetValueOrDefault(),
                Status = MapPaymentStatus(payment.Status),
                PaidAt = payment.PaidAt?.ToLocalTime().ToString("dd/MM/yyyy HH:mm") ?? "--"
            })
            .ToList();

        var booking = MapBooking(trip);
        return new AdminBookingDetailDto
        {
            Id = booking.Id,
            DisplayId = booking.DisplayId,
            UserName = booking.UserName,
            UserCode = booking.UserCode,
            Destination = booking.Destination,
            TotalAmount = booking.TotalAmount,
            Summary = booking.Summary,
            PaymentStatus = booking.PaymentStatus,
            TripStatus = booking.TripStatus,
            CreatedAt = booking.CreatedAt,
            TripTitle = trip.Title ?? "Chưa đặt tiêu đề chuyến đi",
            TravelWindow = BuildTravelWindow(trip),
            Itinerary = itinerary,
            PaymentHistory = paymentHistory
        };
    }

    public async Task<AdminBookingDto> UpdateBookingStatusAsync(int bookingId, AdminUpdateBookingStatusRequest request)
    {
        var trip = await _context.Trips
            .Include(t => t.User)
            .Include(t => t.Destination)
            .Include(t => t.Payments)
            .Include(t => t.TripItineraries)
            .FirstOrDefaultAsync(t => t.Id == bookingId);

        if (trip is null)
        {
            throw new BadHttpRequestException("Không tìm thấy booking.");
        }

        var nextTripStatus = ParseTripStatus(request.TripStatus);
        var nextPaymentStatus = ParsePaymentStatus(request.PaymentStatus);

        trip.Status = nextTripStatus;

        var payment = trip.Payments
            .OrderByDescending(item => item.PaidAt ?? DateTime.MinValue)
            .FirstOrDefault();

        if (payment is null)
        {
            payment = new Payment
            {
                TripId = trip.Id,
                PaymentMethod = PaymentMethod.Card,
                TransactionId = $"ADMIN-{trip.Id}-{DateTime.UtcNow:yyyyMMddHHmmss}",
            };

            _context.Payments.Add(payment);
            trip.Payments.Add(payment);
        }

        payment.Status = nextPaymentStatus;
        payment.Amount = request.Amount ?? trip.TotalAmount;
        payment.PaidAt = DateTime.UtcNow;

        if (nextPaymentStatus is PaymentStatus.Cancelled or PaymentStatus.Refunded)
        {
            trip.Status = TripStatus.Cancelled;
        }

        if (nextPaymentStatus == PaymentStatus.Paid)
        {
            trip.Status = TripStatus.Paid;
        }

        await _context.SaveChangesAsync();

        return MapBooking(trip);
    }

    private static void ValidateAdminUserRequest(string name, string email)
    {
        if (string.IsNullOrWhiteSpace(name))
        {
            throw new BadHttpRequestException("Tên thành viên không được để trống.");
        }

        if (string.IsNullOrWhiteSpace(email))
        {
            throw new BadHttpRequestException("Email không được để trống.");
        }
    }

    private static string MapUserRole(UserRole? role)
    {
        return role switch
        {
            UserRole.Admin => "admin",
            UserRole.Staff => "staff",
            UserRole.Partner => "partner",
            UserRole.Customer => "customer",
            _ => "customer"
        };
    }

    private static UserRole ParseUserRole(string role)
    {
        return role.Trim().ToLowerInvariant() switch
        {
            "admin" => UserRole.Admin,
            "staff" => UserRole.Staff,
            "partner" => UserRole.Partner,
            "customer" => UserRole.Customer,
            _ => UserRole.User
        };
    }

    private static PaymentStatus ParsePaymentStatus(string status)
    {
        return status.Trim().ToLowerInvariant() switch
        {
            "paid" => PaymentStatus.Paid,
            "cancelled" => PaymentStatus.Cancelled,
            "refunded" => PaymentStatus.Refunded,
            "failed" => PaymentStatus.Failed,
            _ => PaymentStatus.Pending
        };
    }

    private static TripStatus ParseTripStatus(string status)
    {
        return status.Trim().ToLowerInvariant() switch
        {
            "paid" => TripStatus.Paid,
            "cancelled" => TripStatus.Cancelled,
            "draft" => TripStatus.Draft,
            _ => TripStatus.Pending
        };
    }

    private static SeatStatus ParseSeatStatus(string status)
    {
        return status.Trim().ToLowerInvariant() switch
        {
            "booked" => SeatStatus.Booked,
            "locked" => SeatStatus.Locked,
            _ => SeatStatus.Available
        };
    }

    private static AdminBookingDto MapBooking(Trip trip)
    {
        return new AdminBookingDto
        {
            Id = trip.Id,
            DisplayId = $"#SKN-{trip.Id:D4}",
            UserName = trip.User?.FullName ?? "Khách vãng lai",
            UserCode = trip.UserId.HasValue ? $"ID: SKY-{trip.UserId.Value:D4}" : "Khách chưa đăng nhập",
            Destination = trip.Destination?.Name ?? "Chưa xác định",
            TotalAmount = $"{trip.TotalAmount.GetValueOrDefault():N0}đ",
            Summary = BuildTripSummary(trip),
            PaymentStatus = GetBookingPaymentStatus(trip),
            TripStatus = MapTripStatus(trip.Status),
            CreatedAt = trip.CreatedAt?.ToLocalTime().ToString("dd/MM/yyyy HH:mm") ?? "--"
        };
    }

    private static AdminTransportScheduleDto MapTransportSchedule(BusSchedule schedule, DateTime now)
    {
        var occupiedSeats = GetOccupiedSeatCount(schedule);
        var totalSeats = GetTotalSeatCount(schedule);
        var ticketPrice = schedule.Price.GetValueOrDefault();
        var affiliateProfit = CalculateAffiliateProfit(schedule);

        return new AdminTransportScheduleDto
        {
            Id = schedule.Id,
            CompanyId = schedule.CompanyId ?? 0,
            FromDestinationId = schedule.FromDestId ?? 0,
            ToDestinationId = schedule.ToDestId ?? 0,
            Code = $"SK-{schedule.Id:D5}",
            CompanyName = schedule.Company?.Name ?? "Nhà xe chưa xác định",
            Route = $"{schedule.FromDest?.Name ?? "Chưa rõ"} → {schedule.ToDest?.Name ?? "Chưa rõ"}",
            DepartureTime = schedule.DepartureTime?.ToLocalTime().ToString("HH:mm") ?? "--:--",
            DepartureDate = schedule.DepartureTime?.ToLocalTime().ToString("dd/MM/yyyy") ?? "--/--/----",
            DepartureAt = schedule.DepartureTime?.ToString("O") ?? string.Empty,
            ArrivalAt = schedule.ArrivalTime?.ToString("O") ?? string.Empty,
            Status = GetTransportStatus(schedule, now),
            TicketPrice = $"{ticketPrice:N0}đ",
            AffiliateProfit = $"{affiliateProfit:N0}đ",
            PriceValue = ticketPrice,
            CommissionRate = schedule.CommissionRate ?? 0d,
            OccupiedSeats = occupiedSeats,
            TotalSeats = totalSeats,
            Seats = schedule.Seats
                .OrderBy(seat => seat.SeatNumber)
                .Select(seat => new AdminTransportSeatDto
                {
                    Id = seat.Id,
                    SeatNumber = seat.SeatNumber ?? $"S{seat.Id}",
                    Status = (seat.Status ?? SeatStatus.Available).ToString().ToLowerInvariant()
                })
                .ToList()
        };
    }

    private static AdminTransportCompanyDto MapTransportCompany(BusCompany company)
    {
        return new AdminTransportCompanyDto
        {
            Id = company.Id,
            Name = company.Name ?? "Nhà xe chưa đặt tên",
            Hotline = company.Hotline ?? "--",
            LogoUrl = company.LogoUrl ?? string.Empty,
            ScheduleCount = company.BusSchedules.Count,
            AverageCommissionRate = company.BusSchedules.Any()
                ? Math.Round(company.BusSchedules.Average(schedule => schedule.CommissionRate ?? 0d), 2)
                : 0
        };
    }

    private async Task EnsureTransportReferenceAsync(int companyId, int fromDestinationId, int toDestinationId)
    {
        if (fromDestinationId == toDestinationId)
        {
            throw new BadHttpRequestException("Điểm đi và điểm đến không được trùng nhau.");
        }

        var companyExists = await _context.BusCompanies.AnyAsync(company => company.Id == companyId);
        var fromExists = await _context.Destinations.AnyAsync(destination => destination.Id == fromDestinationId);
        var toExists = await _context.Destinations.AnyAsync(destination => destination.Id == toDestinationId);

        if (!companyExists || !fromExists || !toExists)
        {
            throw new BadHttpRequestException("Dữ liệu nhà xe hoặc điểm đến không hợp lệ.");
        }
    }

    private static void EnsureTransportScheduleTimes(DateTime departureAt, DateTime arrivalAt, int totalSeats)
    {
        if (arrivalAt <= departureAt)
        {
            throw new BadHttpRequestException("Thời gian đến phải lớn hơn thời gian khởi hành.");
        }

        if (totalSeats <= 0)
        {
            throw new BadHttpRequestException("Số ghế phải lớn hơn 0.");
        }
    }

    private static List<Seat> BuildSeats(int scheduleId, int count, int startingIndex = 1)
    {
        return Enumerable.Range(startingIndex, count)
            .Select(index => new Seat
            {
                ScheduleId = scheduleId,
                SeatNumber = $"S{index:00}",
                Status = SeatStatus.Available
            })
            .ToList();
    }

    private async Task<string> ResolveItineraryServiceNameAsync(TripItinerary itinerary)
    {
        if (!itinerary.ServiceId.HasValue)
        {
            return "Chưa liên kết dịch vụ";
        }

        if (itinerary.ServiceType == TripServiceType.Hotel)
        {
            return await _context.Hotels
                .Where(hotel => hotel.Id == itinerary.ServiceId.Value)
                .Select(hotel => hotel.Name)
                .FirstOrDefaultAsync() ?? "Khách sạn không xác định";
        }

        if (itinerary.ServiceType == TripServiceType.Bus)
        {
            var schedule = await _context.BusSchedules
                .Include(item => item.FromDest)
                .Include(item => item.ToDest)
                .FirstOrDefaultAsync(item => item.Id == itinerary.ServiceId.Value);

            return schedule is null
                ? "Chuyến xe không xác định"
                : $"{schedule.FromDest?.Name ?? "Chưa rõ"} → {schedule.ToDest?.Name ?? "Chưa rõ"}";
        }

        return "Dịch vụ chưa xác định";
    }

    private static string BuildTravelWindow(Trip trip)
    {
        if (!trip.StartDate.HasValue || !trip.EndDate.HasValue)
        {
            return "Chưa xác nhận lịch đi";
        }

        return $"{trip.StartDate.Value:dd/MM/yyyy} - {trip.EndDate.Value:dd/MM/yyyy}";
    }
}
