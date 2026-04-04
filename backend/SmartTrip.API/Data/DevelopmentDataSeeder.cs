using Microsoft.EntityFrameworkCore;
using SmartTrip.Domain.Entities;
using SmartTrip.Domain.Enums;

namespace SmartTrip.API.Data;

public static class DevelopmentDataSeeder
{
    public static async Task SeedAsync(ApplicationDbContext context)
    {
        if (!await context.Users.AnyAsync())
        {
            var demoUser = new User
            {
                Email = "test@example.com",
                PasswordHash = BCrypt.Net.BCrypt.HashPassword("123456"),
                FullName = "Nguyen Van Test",
                Phone = "0123456789",
                AvatarUrl = "https://i.pravatar.cc/150?u=smarttrip-demo",
                AuthProvider = AuthProvider.Local,
                Role = UserRole.User,
                IsActive = true,
                CreatedAt = DateTime.UtcNow
            };

            var adminUser = new User
            {
                Email = "admin@smarttrip.vn",
                PasswordHash = BCrypt.Net.BCrypt.HashPassword("123456"),
                FullName = "SmartTrip Admin",
                Phone = "0987654321",
                AvatarUrl = "https://i.pravatar.cc/150?u=smarttrip-admin",
                AuthProvider = AuthProvider.Local,
                Role = UserRole.Admin,
                IsActive = true,
                CreatedAt = DateTime.UtcNow
            };

            context.Users.AddRange(demoUser, adminUser);
            await context.SaveChangesAsync();

            context.UserWallets.AddRange(
                new UserWallet
                {
                    UserId = demoUser.Id,
                    Balance = 1500000m,
                    LoyaltyPoints = 620
                },
                new UserWallet
                {
                    UserId = adminUser.Id,
                    Balance = 3000000m,
                    LoyaltyPoints = 1200
                });

            await context.SaveChangesAsync();
        }

        if (!await context.Destinations.AnyAsync())
        {
            context.Destinations.AddRange(
                new Destination
                {
                    Name = "Da Lat",
                    Description = "Thanh pho ngan hoa va khi hau mat me quanh nam.",
                    CoverImageUrl = "https://images.unsplash.com/photo-1506744038136-46273834b3fb",
                    IsHot = true
                },
                new Destination
                {
                    Name = "Phu Quoc",
                    Description = "Dao ngoc voi bien dep va nhieu resort chat luong.",
                    CoverImageUrl = "https://images.unsplash.com/photo-1507525428034-b723cf961d3e",
                    IsHot = true
                },
                new Destination
                {
                    Name = "Da Nang",
                    Description = "Thanh pho bien hien dai, gan Hoi An va Ba Na Hills.",
                    CoverImageUrl = "https://images.unsplash.com/photo-1493558103817-58b2924bce98",
                    IsHot = true
                });

            await context.SaveChangesAsync();
        }

        if (!await context.BusCompanies.AnyAsync())
        {
            context.BusCompanies.AddRange(
                new BusCompany
                {
                    Name = "Skynet Express",
                    Hotline = "19001001",
                    LogoUrl = "https://images.unsplash.com/photo-1517142089942-ba376ce32a2e"
                },
                new BusCompany
                {
                    Name = "Viet Travel Bus",
                    Hotline = "19001002",
                    LogoUrl = "https://images.unsplash.com/photo-1544620347-c4fd4a3d5957"
                });

            await context.SaveChangesAsync();
        }

        if (!await context.Promotions.AnyAsync())
        {
            context.Promotions.AddRange(
                new Promotion
                {
                    Code = "WELCOME10",
                    DiscountPercent = 10,
                    MaxDiscountAmount = 100000m,
                    ValidUntil = DateTime.UtcNow.AddMonths(2),
                    UsageLimit = 100,
                    UsedCount = 5
                },
                new Promotion
                {
                    Code = "SUMMER20",
                    DiscountPercent = 20,
                    MaxDiscountAmount = 250000m,
                    ValidUntil = DateTime.UtcNow.AddMonths(1),
                    UsageLimit = 50,
                    UsedCount = 12
                },
                new Promotion
                {
                    Code = "HOTEL5",
                    DiscountPercent = 5,
                    MaxDiscountAmount = 50000m,
                    ValidUntil = DateTime.UtcNow.AddDays(20),
                    UsageLimit = 200,
                    UsedCount = 40
                });

            await context.SaveChangesAsync();
        }

        if (!await context.Hotels.AnyAsync())
        {
            var destinations = await context.Destinations.OrderBy(d => d.Id).ToListAsync();
            if (destinations.Count >= 3)
            {
                context.Hotels.AddRange(
                    new Hotel
                    {
                        DestinationId = destinations[0].Id,
                        Name = "Pine Valley Hotel",
                        Address = "12 Ho Xuan Huong, Da Lat",
                        StarRating = 4,
                        Description = "Khach san am cung gan trung tam Da Lat.",
                        IsAvailable = true
                    },
                    new Hotel
                    {
                        DestinationId = destinations[1].Id,
                        Name = "Ocean Pearl Resort",
                        Address = "88 Tran Hung Dao, Phu Quoc",
                        StarRating = 5,
                        Description = "Resort view bien phu hop nghi duong.",
                        IsAvailable = true
                    },
                    new Hotel
                    {
                        DestinationId = destinations[2].Id,
                        Name = "Dragon Bridge Stay",
                        Address = "45 Bach Dang, Da Nang",
                        StarRating = 4,
                        Description = "Khach san ven song gan cau Rong.",
                        IsAvailable = true
                    });

                await context.SaveChangesAsync();
            }
        }

        if (!await context.BusSchedules.AnyAsync())
        {
            var companyId = await context.BusCompanies
                .OrderBy(c => c.Id)
                .Select(c => c.Id)
                .FirstOrDefaultAsync();

            var destinations = await context.Destinations.OrderBy(d => d.Id).ToListAsync();
            if (companyId != 0 && destinations.Count >= 2)
            {
                context.BusSchedules.AddRange(
                    new BusSchedule
                    {
                        CompanyId = companyId,
                        FromDestId = destinations[2].Id,
                        ToDestId = destinations[0].Id,
                        DepartureTime = DateTime.UtcNow.AddDays(2).Date.AddHours(22),
                        ArrivalTime = DateTime.UtcNow.AddDays(3).Date.AddHours(5),
                        Price = 320000m,
                        CommissionRate = 0.08,
                        TotalSeats = 36
                    },
                    new BusSchedule
                    {
                        CompanyId = companyId,
                        FromDestId = destinations[2].Id,
                        ToDestId = destinations[1].Id,
                        DepartureTime = DateTime.UtcNow.AddDays(4).Date.AddHours(21),
                        ArrivalTime = DateTime.UtcNow.AddDays(5).Date.AddHours(6),
                        Price = 450000m,
                        CommissionRate = 0.1,
                        TotalSeats = 40
                    });

                await context.SaveChangesAsync();
            }
        }

        if (!await context.Trips.AnyAsync())
        {
            var demoUserId = await context.Users
                .Where(u => u.Email == "test@example.com")
                .Select(u => u.Id)
                .FirstOrDefaultAsync();

            var destinations = await context.Destinations.OrderBy(d => d.Id).ToListAsync();
            if (demoUserId != 0 && destinations.Count >= 2)
            {
                context.Trips.AddRange(
                    new Trip
                    {
                        UserId = demoUserId,
                        DestinationId = destinations[0].Id,
                        Title = "Da Lat Weekend Escape",
                        StartDate = DateOnly.FromDateTime(DateTime.UtcNow.AddDays(7)),
                        EndDate = DateOnly.FromDateTime(DateTime.UtcNow.AddDays(10)),
                        TotalAmount = 3200000m,
                        TotalProfit = 350000m,
                        Status = TripStatus.Paid,
                        CreatedAt = DateTime.UtcNow.AddDays(-15)
                    },
                    new Trip
                    {
                        UserId = demoUserId,
                        DestinationId = destinations[1].Id,
                        Title = "Phu Quoc Summer Trip",
                        StartDate = DateOnly.FromDateTime(DateTime.UtcNow.AddDays(20)),
                        EndDate = DateOnly.FromDateTime(DateTime.UtcNow.AddDays(24)),
                        TotalAmount = 7800000m,
                        TotalProfit = 900000m,
                        Status = TripStatus.Pending,
                        CreatedAt = DateTime.UtcNow.AddDays(-5)
                    });

                await context.SaveChangesAsync();
            }
        }

        if (!await context.TripItineraries.AnyAsync())
        {
            var trips = await context.Trips
                .OrderBy(t => t.Id)
                .ToListAsync();
            var hotels = await context.Hotels
                .OrderBy(h => h.Id)
                .ToListAsync();
            var busSchedules = await context.BusSchedules
                .OrderBy(s => s.Id)
                .ToListAsync();

            if (trips.Count >= 2)
            {
                if (hotels.Count >= 2)
                {
                    context.TripItineraries.AddRange(
                        new TripItinerary
                        {
                            TripId = trips[0].Id,
                            DayNumber = 1,
                            ServiceType = TripServiceType.Hotel,
                            ServiceId = hotels[0].Id,
                            Quantity = 2,
                            BookedPrice = 1600000m,
                            BookedCommissionRate = 0.1
                        },
                        new TripItinerary
                        {
                            TripId = trips[1].Id,
                            DayNumber = 1,
                            ServiceType = TripServiceType.Hotel,
                            ServiceId = hotels[1].Id,
                            Quantity = 3,
                            BookedPrice = 4200000m,
                            BookedCommissionRate = 0.12
                        });
                }

                if (busSchedules.Count >= 2)
                {
                    context.TripItineraries.AddRange(
                        new TripItinerary
                        {
                            TripId = trips[0].Id,
                            DayNumber = 1,
                            ServiceType = TripServiceType.Bus,
                            ServiceId = busSchedules[0].Id,
                            Quantity = 2,
                            BookedPrice = 640000m,
                            BookedCommissionRate = 0.08
                        },
                        new TripItinerary
                        {
                            TripId = trips[1].Id,
                            DayNumber = 1,
                            ServiceType = TripServiceType.Bus,
                            ServiceId = busSchedules[1].Id,
                            Quantity = 3,
                            BookedPrice = 1350000m,
                            BookedCommissionRate = 0.1
                        });
                }

                await context.SaveChangesAsync();
            }
        }

        if (!await context.Payments.AnyAsync())
        {
            var trips = await context.Trips
                .OrderBy(t => t.Id)
                .ToListAsync();

            if (trips.Count >= 2)
            {
                context.Payments.AddRange(
                    new Payment
                    {
                        TripId = trips[0].Id,
                        PaymentMethod = PaymentMethod.Momo,
                        TransactionId = $"MOMO-{trips[0].Id:0000}",
                        Amount = trips[0].TotalAmount,
                        Status = PaymentStatus.Paid,
                        PaidAt = DateTime.UtcNow.AddDays(-14)
                    },
                    new Payment
                    {
                        TripId = trips[1].Id,
                        PaymentMethod = PaymentMethod.Vnpay,
                        TransactionId = $"VNPAY-{trips[1].Id:0000}",
                        Amount = trips[1].TotalAmount,
                        Status = PaymentStatus.Pending,
                        PaidAt = DateTime.UtcNow.AddDays(-4)
                    });

                await context.SaveChangesAsync();
            }
        }

        if (!await context.Invoices.AnyAsync())
        {
            var trips = await context.Trips
                .OrderBy(t => t.Id)
                .ToListAsync();

            if (trips.Count >= 2)
            {
                context.Invoices.AddRange(
                    new Invoice
                    {
                        TripId = trips[0].Id,
                        InvoiceNumber = $"INV-{trips[0].Id:0000}",
                        TaxAmount = 320000m,
                        PdfUrl = $"https://smarttrip.local/invoices/INV-{trips[0].Id:0000}.pdf",
                        IssuedAt = DateTime.UtcNow.AddDays(-14)
                    },
                    new Invoice
                    {
                        TripId = trips[1].Id,
                        InvoiceNumber = $"INV-{trips[1].Id:0000}",
                        TaxAmount = 780000m,
                        PdfUrl = $"https://smarttrip.local/invoices/INV-{trips[1].Id:0000}.pdf",
                        IssuedAt = DateTime.UtcNow.AddDays(-4)
                    });

                await context.SaveChangesAsync();
            }
        }

        if (!await context.Wishlists.AnyAsync())
        {
            var demoUserId = await context.Users
                .Where(u => u.Email == "test@example.com")
                .Select(u => u.Id)
                .FirstOrDefaultAsync();

            var firstHotelId = await context.Hotels
                .OrderBy(h => h.Id)
                .Select(h => h.Id)
                .FirstOrDefaultAsync();

            var firstBusScheduleId = await context.BusSchedules
                .OrderBy(s => s.Id)
                .Select(s => s.Id)
                .FirstOrDefaultAsync();

            if (demoUserId != 0)
            {
                if (firstHotelId != 0)
                {
                    context.Wishlists.Add(new Wishlist
                    {
                        UserId = demoUserId,
                        ItemType = WishlistItemType.Hotel,
                        ItemId = firstHotelId,
                        CreatedAt = DateTime.UtcNow.AddDays(-3)
                    });
                }

                if (firstBusScheduleId != 0)
                {
                    context.Wishlists.Add(new Wishlist
                    {
                        UserId = demoUserId,
                        ItemType = WishlistItemType.Bus,
                        ItemId = firstBusScheduleId,
                        CreatedAt = DateTime.UtcNow.AddDays(-1)
                    });
                }

                await context.SaveChangesAsync();
            }
        }
    }
}
