using Microsoft.EntityFrameworkCore;
using SmartTrip.Domain.Entities;
using SmartTrip.Domain.Enums;

namespace SmartTrip.API.Data;

public static class DevelopmentDataSeeder
{
    private const string DevPassword = "12345678";

    public static async Task SeedAsync(ApplicationDbContext context)
    {
        var adminUser = await context.Users.FirstOrDefaultAsync(user => user.Email == "admin@smarttrip.vn");
        if (adminUser is null)
        {
            adminUser = new User
            {
                Email = "admin@smarttrip.vn",
            };
            context.Users.Add(adminUser);
        }

        adminUser.PasswordHash = BCrypt.Net.BCrypt.HashPassword(DevPassword);
        adminUser.FullName = "SmartTrip Admin";
        adminUser.Phone = "0987654321";
        adminUser.AvatarUrl = "https://i.pravatar.cc/150?u=smarttrip-admin";
        adminUser.AuthProvider = AuthProvider.Local;
        adminUser.Role = UserRole.Admin;
        adminUser.IsActive = true;
        adminUser.IsEmailVerified = true;
        adminUser.CreatedAt ??= DateTime.UtcNow;

        var demoUser = await context.Users.FirstOrDefaultAsync(user => user.Email == "test@example.com");
        if (demoUser is null)
        {
            demoUser = new User
            {
                Email = "test@example.com",
                CreatedAt = DateTime.UtcNow,
            };
            context.Users.Add(demoUser);
        }

        demoUser.PasswordHash = BCrypt.Net.BCrypt.HashPassword(DevPassword);
        demoUser.FullName = "Nguyen Van Test";
        demoUser.Phone = "0123456789";
        demoUser.AvatarUrl = "https://i.pravatar.cc/150?u=smarttrip-demo";
        demoUser.AuthProvider = AuthProvider.Local;
        demoUser.Role = UserRole.User;
        demoUser.IsActive = true;
        demoUser.IsEmailVerified = true;
        demoUser.CreatedAt ??= DateTime.UtcNow;

        await context.SaveChangesAsync();

        var demoWallet = await context.UserWallets.FirstOrDefaultAsync(wallet => wallet.UserId == demoUser.Id);
        if (demoWallet is null)
        {
            context.UserWallets.Add(new UserWallet
            {
                UserId = demoUser.Id,
                Balance = 1500000m,
                LoyaltyPoints = 620
            });
        }

        var adminWallet = await context.UserWallets.FirstOrDefaultAsync(wallet => wallet.UserId == adminUser.Id);
        if (adminWallet is null)
        {
            context.UserWallets.Add(new UserWallet
            {
                UserId = adminUser.Id,
                Balance = 3000000m,
                LoyaltyPoints = 1200
            });
        }

        await context.SaveChangesAsync();

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
                        Address = "12 Hồ Xuân Hương, Phường 3, Đà Lạt",
                        StarRating = 4,
                        Description = "Nằm ngay trung tâm Đà Lạt thơ mộng, Pine Valley Hotel mang đến không gian nghỉ dưỡng ấm cúng với kiến trúc châu Âu cổ điển. Mỗi phòng đều có ban công nhìn ra hồ Xuân Hương hoặc rừng thông bạt ngàn. Khách sạn có nhà hàng phục vụ ẩm thực Việt-Pháp, quầy bar rượu vang, và khu vực lửa trại lãng mạn mỗi tối.",
                        IsAvailable = true
                    },
                    new Hotel
                    {
                        DestinationId = destinations[1].Id,
                        Name = "Ocean Pearl Resort",
                        Address = "88 Trần Hưng Đạo, Dương Đông, Phú Quốc",
                        StarRating = 5,
                        Description = "Resort 5 sao đẳng cấp quốc tế nằm ngay bờ biển trắng mịn Phú Quốc. Với hệ thống bể bơi vô cực nhìn ra biển, nhà hàng hải sản tươi sống, và các villa riêng biệt, Ocean Pearl mang đến trải nghiệm nghỉ dưỡng xa xỉ đích thực. Dịch vụ butler 24/7, spa cao cấp và các hoạt động lặn biển đẳng cấp.",
                        IsAvailable = true
                    },
                    new Hotel
                    {
                        DestinationId = destinations[2].Id,
                        Name = "Dragon Bridge Stay",
                        Address = "45 Bạch Đằng, Hải Châu, Đà Nẵng",
                        StarRating = 4,
                        Description = "Khách sạn boutique sang trọng nằm ven sông Hàn, cách Cầu Rồng chỉ 200m. Từ tầng thượng có thể chiêm ngưỡng Cầu Rồng phun lửa mỗi cuối tuần. Gần bãi biển Mỹ Khê, phố cổ Hội An và khu ẩm thực Bạch Đằng. Nhà hàng tầng thượng view sông Hàn không thể bỏ lỡ.",
                        IsAvailable = true
                    });

                await context.SaveChangesAsync();
            }
        }

        if (!await context.Amenities.AnyAsync())
        {
            context.Amenities.AddRange(
                new Amenity { Name = "Hồ bơi", IconUrl = "pool" },
                new Amenity { Name = "WiFi miễn phí", IconUrl = "wifi" },
                new Amenity { Name = "Điều hòa", IconUrl = "ac_unit" },
                new Amenity { Name = "Bãi đỗ xe", IconUrl = "local_parking" },
                new Amenity { Name = "Nhà hàng", IconUrl = "restaurant" },
                new Amenity { Name = "Phòng gym", IconUrl = "fitness_center" },
                new Amenity { Name = "Spa", IconUrl = "spa" },
                new Amenity { Name = "Bar", IconUrl = "local_bar" },
                new Amenity { Name = "Dịch vụ phòng 24/7", IconUrl = "room_service" },
                new Amenity { Name = "Đón tiễn sân bay", IconUrl = "airport_shuttle" }
            );
            await context.SaveChangesAsync();
        }

        if (!await context.Rooms.AnyAsync())
        {
            var hotels = await context.Hotels.OrderBy(h => h.Id).ToListAsync();
            if (hotels.Count >= 3)
            {
                // Pine Valley Hotel (4 sao - Đà Lạt)
                context.Rooms.AddRange(
                    new Room { HotelId = hotels[0].Id, RoomType = "Phòng Standard", Capacity = 2, PricePerNight = 850000m, CommissionRate = 0.10, AvailableQty = 8 },
                    new Room { HotelId = hotels[0].Id, RoomType = "Phòng Deluxe View Hồ", Capacity = 2, PricePerNight = 1250000m, CommissionRate = 0.12, AvailableQty = 6 },
                    new Room { HotelId = hotels[0].Id, RoomType = "Suite Gia Đình", Capacity = 4, PricePerNight = 2100000m, CommissionRate = 0.15, AvailableQty = 3 }
                );

                // Ocean Pearl Resort (5 sao - Phú Quốc)
                context.Rooms.AddRange(
                    new Room { HotelId = hotels[1].Id, RoomType = "Phòng Deluxe Biển", Capacity = 2, PricePerNight = 2450000m, CommissionRate = 0.12, AvailableQty = 10 },
                    new Room { HotelId = hotels[1].Id, RoomType = "Pool Access Villa", Capacity = 2, PricePerNight = 4200000m, CommissionRate = 0.15, AvailableQty = 5 },
                    new Room { HotelId = hotels[1].Id, RoomType = "Overwater Bungalow", Capacity = 2, PricePerNight = 7500000m, CommissionRate = 0.18, AvailableQty = 2 }
                );

                // Dragon Bridge Stay (4 sao - Đà Nẵng)
                context.Rooms.AddRange(
                    new Room { HotelId = hotels[2].Id, RoomType = "Phòng City View", Capacity = 2, PricePerNight = 980000m, CommissionRate = 0.10, AvailableQty = 10 },
                    new Room { HotelId = hotels[2].Id, RoomType = "Phòng River View", Capacity = 2, PricePerNight = 1480000m, CommissionRate = 0.12, AvailableQty = 6 },
                    new Room { HotelId = hotels[2].Id, RoomType = "Suite Cầu Rồng", Capacity = 4, PricePerNight = 2800000m, CommissionRate = 0.15, AvailableQty = 2 }
                );

                await context.SaveChangesAsync();

                // Gán amenities cho từng hotel
                var amenities = await context.Amenities.OrderBy(a => a.Id).ToListAsync();
                if (amenities.Count >= 10)
                {
                    hotels[0].Amenities = new List<Amenity> { amenities[0], amenities[1], amenities[2], amenities[3], amenities[4], amenities[8] };
                    hotels[1].Amenities = new List<Amenity> { amenities[0], amenities[1], amenities[2], amenities[3], amenities[4], amenities[5], amenities[6], amenities[7], amenities[8], amenities[9] };
                    hotels[2].Amenities = new List<Amenity> { amenities[0], amenities[1], amenities[2], amenities[3], amenities[4], amenities[7], amenities[8] };
                    await context.SaveChangesAsync();
                }
            }
        }

        if (!await context.Galleries.AnyAsync())
        {
            var hotels = await context.Hotels.OrderBy(h => h.Id).ToListAsync();
            if (hotels.Count >= 3)
            {
                // Pine Valley Hotel - Đà Lạt
                context.Galleries.AddRange(
                    new Gallery { ReferenceType = GalleryReferenceType.Hotel, ReferenceId = hotels[0].Id, ImageUrl = "https://images.unsplash.com/photo-1566073771259-6a8506099945?auto=format&fit=crop&w=1200&q=80" },
                    new Gallery { ReferenceType = GalleryReferenceType.Hotel, ReferenceId = hotels[0].Id, ImageUrl = "https://images.unsplash.com/photo-1578645510447-e20b4311e3ce?auto=format&fit=crop&w=1200&q=80" },
                    new Gallery { ReferenceType = GalleryReferenceType.Hotel, ReferenceId = hotels[0].Id, ImageUrl = "https://images.unsplash.com/photo-1571003123894-1f0594d2b5d9?auto=format&fit=crop&w=1200&q=80" },
                    new Gallery { ReferenceType = GalleryReferenceType.Hotel, ReferenceId = hotels[0].Id, ImageUrl = "https://images.unsplash.com/photo-1590073844006-33379778ae09?auto=format&fit=crop&w=1200&q=80" },
                    // Ocean Pearl Resort - Phú Quốc
                    new Gallery { ReferenceType = GalleryReferenceType.Hotel, ReferenceId = hotels[1].Id, ImageUrl = "https://images.unsplash.com/photo-1499793983690-e29da59ef1c2?auto=format&fit=crop&w=1200&q=80" },
                    new Gallery { ReferenceType = GalleryReferenceType.Hotel, ReferenceId = hotels[1].Id, ImageUrl = "https://images.unsplash.com/photo-1542314831-c6a4d14d837e?auto=format&fit=crop&w=1200&q=80" },
                    new Gallery { ReferenceType = GalleryReferenceType.Hotel, ReferenceId = hotels[1].Id, ImageUrl = "https://images.unsplash.com/photo-1582268611958-ebfd161ef9cf?auto=format&fit=crop&w=1200&q=80" },
                    new Gallery { ReferenceType = GalleryReferenceType.Hotel, ReferenceId = hotels[1].Id, ImageUrl = "https://images.unsplash.com/photo-1564501049412-61c2a3083791?auto=format&fit=crop&w=1200&q=80" },
                    // Dragon Bridge Stay - Đà Nẵng
                    new Gallery { ReferenceType = GalleryReferenceType.Hotel, ReferenceId = hotels[2].Id, ImageUrl = "https://images.unsplash.com/photo-1551882547-ff40c63fe5fa?auto=format&fit=crop&w=1200&q=80" },
                    new Gallery { ReferenceType = GalleryReferenceType.Hotel, ReferenceId = hotels[2].Id, ImageUrl = "https://images.unsplash.com/photo-1611892440504-42a792e24d32?auto=format&fit=crop&w=1200&q=80" },
                    new Gallery { ReferenceType = GalleryReferenceType.Hotel, ReferenceId = hotels[2].Id, ImageUrl = "https://images.unsplash.com/photo-1631049307264-da0ec9d70304?auto=format&fit=crop&w=1200&q=80" },
                    new Gallery { ReferenceType = GalleryReferenceType.Hotel, ReferenceId = hotels[2].Id, ImageUrl = "https://images.unsplash.com/photo-1586611292717-f828b167408c?auto=format&fit=crop&w=1200&q=80" }
                );
                await context.SaveChangesAsync();
            }
        }

        if (!await context.Reviews.AnyAsync())
        {
            var hotels = await context.Hotels.OrderBy(h => h.Id).ToListAsync();
            var demoUserId = await context.Users.Where(u => u.Email == "test@example.com").Select(u => u.Id).FirstOrDefaultAsync();
            var trips = await context.Trips.OrderBy(t => t.Id).ToListAsync();

            if (hotels.Count >= 3 && demoUserId != 0 && trips.Count >= 1)
            {
                context.Reviews.AddRange(
                    // Reviews for Pine Valley Hotel
                    new Review { UserId = demoUserId, TripId = trips[0].Id, TargetType = ReviewTargetType.Hotel, TargetId = hotels[0].Id, Rating = 5, Comment = "Không gian tuyệt vời, nhân viên vô cùng nhiệt tình! View hồ Xuân Hương từ ban công phòng Deluxe rất lãng mạn. Bữa sáng buffet phong phú. Chắc chắn sẽ quay lại!", CreatedAt = DateTime.UtcNow.AddDays(-10) },
                    new Review { UserId = demoUserId, TripId = trips[0].Id, TargetType = ReviewTargetType.Hotel, TargetId = hotels[0].Id, Rating = 4, Comment = "Phòng sạch sẽ, ấm cúng. Vị trí cực kỳ thuận tiện, đi bộ ra chợ Đà Lạt 5 phút. Chỉ tiếc là WiFi hơi yếu ở tầng thấp.", CreatedAt = DateTime.UtcNow.AddDays(-20) },
                    new Review { UserId = demoUserId, TripId = trips[0].Id, TargetType = ReviewTargetType.Hotel, TargetId = hotels[0].Id, Rating = 5, Comment = "Buổi tối lửa trại ở sân vườn rất thú vị! Nhà hàng khách sạn nấu món Pháp-Việt ngon tuyệt vời. Giá cả hợp lý so với chất lượng.", CreatedAt = DateTime.UtcNow.AddDays(-30) },
                    // Reviews for Ocean Pearl Resort
                    new Review { UserId = demoUserId, TripId = trips[0].Id, TargetType = ReviewTargetType.Hotel, TargetId = hotels[1].Id, Rating = 5, Comment = "Thiên đường nghỉ dưỡng! Overwater Bungalow view biển tuyệt đẹp, butler phục vụ tận tâm 24/7. Spa và hồ bơi vô cực nhìn ra biển là điểm nhấn không thể quên. Xứng đáng với từng đồng tiền bỏ ra.", CreatedAt = DateTime.UtcNow.AddDays(-5) },
                    new Review { UserId = demoUserId, TripId = trips[0].Id, TargetType = ReviewTargetType.Hotel, TargetId = hotels[1].Id, Rating = 5, Comment = "Trải nghiệm 5 sao thực sự! Hải sản tươi sống tại nhà hàng resort cực kỳ ngon. Beach butler mang đồ uống tận nơi. Lặn biển có hướng dẫn viên chuyên nghiệp.", CreatedAt = DateTime.UtcNow.AddDays(-15) },
                    // Reviews for Dragon Bridge Stay
                    new Review { UserId = demoUserId, TripId = trips[0].Id, TargetType = ReviewTargetType.Hotel, TargetId = hotels[2].Id, Rating = 4, Comment = "Vị trí đắc địa nhìn ra sông Hàn và Cầu Rồng! Mỗi cuối tuần xem lửa phun từ ban công phòng River View là kỷ niệm không thể quên. Nhà hàng tầng thượng view đẹp hơn mong đợi.", CreatedAt = DateTime.UtcNow.AddDays(-8) },
                    new Review { UserId = demoUserId, TripId = trips[0].Id, TargetType = ReviewTargetType.Hotel, TargetId = hotels[2].Id, Rating = 4, Comment = "Gần biển Mỹ Khê chỉ 10 phút xe taxi, gần Hội An 30 phút. Phòng City View tuy nhỏ hơn nhưng vẫn tiện nghi đầy đủ. Bữa sáng có các món ăn Đà Nẵng truyền thống rất ngon.", CreatedAt = DateTime.UtcNow.AddDays(-25) }
                );
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

        if (!await context.Seats.AnyAsync())
        {
            var schedules = await context.BusSchedules.ToListAsync();
            foreach (var schedule in schedules)
            {
                var seats = new List<Seat>();
                int totalSeats = schedule.TotalSeats ?? 30;
                for (int i = 1; i <= totalSeats; i++)
                {
                    seats.Add(new Seat
                    {
                        ScheduleId = schedule.Id,
                        SeatNumber = $"S{i:02}",
                        Status = SeatStatus.Available
                    });
                }
                context.Seats.AddRange(seats);
            }
            await context.SaveChangesAsync();
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
