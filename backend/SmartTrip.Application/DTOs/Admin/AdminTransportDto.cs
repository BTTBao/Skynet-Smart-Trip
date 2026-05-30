using System.Collections.Generic;

namespace SmartTrip.Application.DTOs.Admin;

public class AdminTransportStatsDto
{
    public int TotalSchedules { get; set; }
    public int TotalSchedulesThisMonth { get; set; }
    public decimal ExpectedRevenueThisMonth { get; set; }
    public decimal AffiliateRevenueThisMonth { get; set; }
    public double AverageOccupancyRate { get; set; }
    public double AffiliateGrowthRate { get; set; }
    public int ActiveSchedules { get; set; }
    public int UpcomingSchedules { get; set; }
    public int CompletedSchedules { get; set; }
    public int TotalCompanies { get; set; }
    public List<AdminTransportScheduleDto> Schedules { get; set; } = new();
}

public class AdminTransportScheduleDto
{
    public int Id { get; set; }
    public int CompanyId { get; set; }
    public int FromDestinationId { get; set; }
    public int ToDestinationId { get; set; }
    public string Code { get; set; } = string.Empty;
    public string CompanyName { get; set; } = string.Empty;
    public string Route { get; set; } = string.Empty;
    public string DepartureTime { get; set; } = string.Empty;
    public string DepartureDate { get; set; } = string.Empty;
    public string DepartureAt { get; set; } = string.Empty;
    public string ArrivalAt { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public string TicketPrice { get; set; } = string.Empty;
    public string AffiliateProfit { get; set; } = string.Empty;
    public decimal PriceValue { get; set; }
    public double CommissionRate { get; set; }
    public int OccupiedSeats { get; set; }
    public int TotalSeats { get; set; }
    public List<AdminTransportSeatDto> Seats { get; set; } = new();
}

public class AdminTransportSeatDto
{
    public int Id { get; set; }
    public string SeatNumber { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
}

public class AdminTransportCompanyDto
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Hotline { get; set; } = string.Empty;
    public string LogoUrl { get; set; } = string.Empty;
    public int ScheduleCount { get; set; }
    public double AverageCommissionRate { get; set; }
}

public class AdminCreateTransportScheduleRequest
{
    public int CompanyId { get; set; }
    public int FromDestinationId { get; set; }
    public int ToDestinationId { get; set; }
    public DateTime DepartureAt { get; set; }
    public DateTime ArrivalAt { get; set; }
    public decimal Price { get; set; }
    public double CommissionRate { get; set; }
    public int TotalSeats { get; set; }
}

public class AdminUpdateTransportScheduleRequest : AdminCreateTransportScheduleRequest
{
}

public class AdminCreateTransportCompanyRequest
{
    public string Name { get; set; } = string.Empty;
    public string Hotline { get; set; } = string.Empty;
    public string LogoUrl { get; set; } = string.Empty;
}

public class AdminUpdateTransportCompanyRequest : AdminCreateTransportCompanyRequest
{
}

public class AdminUpdateSeatRequest
{
    public int Id { get; set; }
    public string Status { get; set; } = string.Empty;
}
