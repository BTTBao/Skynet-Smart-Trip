using Microsoft.EntityFrameworkCore;
using SmartTrip.Domain.Entities;
using SmartTrip.Domain.Enums;

namespace SmartTrip.API.Data;

public static class DevelopmentDataSeeder
{
    private const string DevPassword = "12345678";

    public static async Task SeedAsync(ApplicationDbContext context)
    {
        await EnsureLegacySchemaCompatibilityAsync(context);

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
                    Name = "Đà Lạt",
                    Description = "Thành phố ngàn hoa và khí hậu mát mẻ quanh năm.",
                    CoverImageUrl = "https://images.unsplash.com/photo-1506744038136-46273834b3fb",
                    IsHot = true
                },
                new Destination
                {
                    Name = "Phú Quốc",
                    Description = "Đảo ngọc với biển đẹp và nhiều resort chất lượng.",
                    CoverImageUrl = "https://images.unsplash.com/photo-1507525428034-b723cf961d3e",
                    IsHot = true
                },
                new Destination
                {
                    Name = "Đà Nẵng",
                    Description = "Thành phố biển hiện đại, gần Hội An và Bà Nà Hills.",
                    CoverImageUrl = "https://images.unsplash.com/photo-1493558103817-58b2924bce98",
                    IsHot = true
                },
                new Destination
                {
                    Name = "Nha Trang",
                    Description = "Thành phố biển sôi động với các hoạt động lặn ngắm san hô hấp dẫn.",
                    CoverImageUrl = "https://images.unsplash.com/photo-1584347718919-6d60a16d80ff",
                    IsHot = true
                },
                new Destination
                {
                    Name = "Hạ Long",
                    Description = "Kỳ quan thiên nhiên thế giới với hàng nghìn hòn đảo đá vôi.",
                    CoverImageUrl = "https://images.unsplash.com/photo-1559811814-e2c59a5ebcc2",
                    IsHot = false
                });

            await context.SaveChangesAsync();
        }

        var destinationSeedPool = new[]
        {
            new Destination
            {
                Name = "Hà Nội",
                Description = "Thủ đô với phố cổ, hồ Hoàn Kiếm và nhiều trải nghiệm văn hóa ẩm thực.",
                CoverImageUrl = "https://images.unsplash.com/photo-1509030450996-dd1a26dda07a",
                IsHot = true
            },
            new Destination
            {
                Name = "TP. Hồ Chí Minh",
                Description = "Thành phố năng động với ẩm thực phong phú, nhịp sống sôi động và nhiều điểm vui chơi.",
                CoverImageUrl = "https://images.unsplash.com/photo-1528127269322-539801943592",
                IsHot = true
            },
            new Destination
            {
                Name = "Phú Quý",
                Description = "Hòn đảo yên bình với biển xanh, hải sản tươi và nhịp sống thư thả.",
                CoverImageUrl = "https://images.unsplash.com/photo-1507525428034-b723cf961d3e",
                IsHot = true
            },
            new Destination
            {
                Name = "Hội An",
                Description = "Phố cổ lãng mạn nổi bật với đèn lồng, ẩm thực địa phương và không khí chậm rãi.",
                CoverImageUrl = "https://images.unsplash.com/photo-1559592413-7cec4d0cae2b",
                IsHot = true
            }
        };

        foreach (var destination in destinationSeedPool)
        {
            var exists = await context.Destinations.AnyAsync(item => item.Name == destination.Name);
            if (!exists)
            {
                context.Destinations.Add(destination);
            }
        }

        await context.SaveChangesAsync();

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

        var busCompanySeedPool = new[]
        {
            new BusCompany
            {
                Name = "Phuong Trang FUTA",
                Hotline = "19006067",
                LogoUrl = "https://images.unsplash.com/photo-1544620347-c4fd4a3d5957"
            },
            new BusCompany
            {
                Name = "Thanh Buoi Express",
                Hotline = "19006079",
                LogoUrl = "https://images.unsplash.com/photo-1517142089942-ba376ce32a2e"
            }
        };

        foreach (var company in busCompanySeedPool)
        {
            var exists = await context.BusCompanies.AnyAsync(item => item.Name == company.Name);
            if (!exists)
            {
                context.BusCompanies.Add(company);
            }
        }

        await context.SaveChangesAsync();

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
                    },
                    new Hotel
                    {
                        DestinationId = destinations[0].Id,
                        Name = "Terracotta Hotel & Resort",
                        Address = "Phân khu chức năng 7.9, KDL Hồ Tuyền Lâm, Đà Lạt",
                        StarRating = 4,
                        Description = "Khu nghỉ dưỡng nép mình bên hồ Tuyền Lâm thơ mộng. Một nơi yên tĩnh và thư giãn lý tưởng.",
                        IsAvailable = true
                    },
                    new Hotel
                    {
                        DestinationId = destinations[1].Id,
                        Name = "Vinpearl Resort & Spa",
                        Address = "Bãi Dài, Gành Dầu, Phú Quốc",
                        StarRating = 5,
                        Description = "Resort cao cấp với các tiện ích chuẩn 5 sao, khu vui chơi VinWonders và Safari kế bên.",
                        IsAvailable = true
                    });

                await context.SaveChangesAsync();
            }
        }

        var allDestinations = await context.Destinations.ToListAsync();
        int? FindDestinationId(string destinationName)
            => allDestinations.FirstOrDefault(item => item.Name == destinationName)?.Id;

        var hotelSeedPool = new List<Hotel>
        {
            new()
            {
                DestinationId = FindDestinationId("Hà Nội") ?? 0,
                Name = "Old Quarter Garden Hotel",
                Address = "18 Hàng Bạc, Hoàn Kiếm, Hà Nội",
                StarRating = 4,
                Description = "Khách sạn ấm cúng ngay khu phố cổ, thuận tiện đi bộ hồ Hoàn Kiếm và khám phá ẩm thực đêm.",
                IsAvailable = true
            },
            new()
            {
                DestinationId = FindDestinationId("TP. Hồ Chí Minh") ?? 0,
                Name = "Saigon Central Stay",
                Address = "92 Nguyễn Huệ, Quận 1, TP. Hồ Chí Minh",
                StarRating = 4,
                Description = "Khách sạn trung tâm phù hợp cho du lịch tự túc, gần phố đi bộ và nhiều quán ăn nổi tiếng.",
                IsAvailable = true
            },
            new()
            {
                DestinationId = FindDestinationId("Phú Quý") ?? 0,
                Name = "Phu Quy Sea View",
                Address = "Lô 5 Tam Thanh, Phú Quý, Bình Thuận",
                StarRating = 3,
                Description = "Chỗ nghỉ gần biển với không gian giản dị, phù hợp cho nhóm bạn và khách thích khám phá đảo.",
                IsAvailable = true
            },
            new()
            {
                DestinationId = FindDestinationId("Hội An") ?? 0,
                Name = "Lantern Riverside Hotel",
                Address = "21 Bạch Đằng, Hội An, Quảng Nam",
                StarRating = 4,
                Description = "Khách sạn sát sông, thuận tiện dạo phố cổ, ngắm đèn lồng và thưởng thức cà phê ven sông.",
                IsAvailable = true
            }
        };

        foreach (var hotel in hotelSeedPool.Where(item => item.DestinationId > 0))
        {
            var exists = await context.Hotels.AnyAsync(item => item.Name == hotel.Name);
            if (!exists)
            {
                context.Hotels.Add(hotel);
            }
        }

        await context.SaveChangesAsync();

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

                if (hotels.Count > 3)
                {
                    context.Rooms.AddRange(
                        new Room { HotelId = hotels[3].Id, RoomType = "Phòng Standard", Capacity = 2, PricePerNight = 1000000m, CommissionRate = 0.10, AvailableQty = 5 },
                        new Room { HotelId = hotels[4].Id, RoomType = "Phòng Vinpearl Standard", Capacity = 2, PricePerNight = 3500000m, CommissionRate = 0.15, AvailableQty = 15 }
                    );
                }

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

        var allHotels = await context.Hotels.ToListAsync();
        Hotel? FindHotel(string hotelName)
            => allHotels.FirstOrDefault(item => item.Name == hotelName);

        var roomSeedPool = new List<Room>();
        void AddRoomSeed(string hotelName, string roomType, int capacity, decimal price, double commissionRate, int qty)
        {
            var hotel = FindHotel(hotelName);
            if (hotel == null)
            {
                return;
            }

            roomSeedPool.Add(new Room
            {
                HotelId = hotel.Id,
                RoomType = roomType,
                Capacity = capacity,
                PricePerNight = price,
                CommissionRate = commissionRate,
                AvailableQty = qty
            });
        }

        AddRoomSeed("Old Quarter Garden Hotel", "Phòng Standard", 2, 920000m, 0.10, 8);
        AddRoomSeed("Old Quarter Garden Hotel", "Phòng Family", 4, 1650000m, 0.12, 4);
        AddRoomSeed("Saigon Central Stay", "Phòng City View", 2, 980000m, 0.10, 10);
        AddRoomSeed("Saigon Central Stay", "Suite Gia Đình", 4, 1850000m, 0.12, 4);
        AddRoomSeed("Phu Quy Sea View", "Phòng Tiêu Chuẩn", 2, 650000m, 0.08, 6);
        AddRoomSeed("Phu Quy Sea View", "Phòng Nhìn Biển", 4, 1200000m, 0.10, 3);
        AddRoomSeed("Lantern Riverside Hotel", "Phòng Deluxe", 2, 1100000m, 0.10, 7);
        AddRoomSeed("Lantern Riverside Hotel", "Phòng Balcony", 3, 1450000m, 0.12, 4);

        foreach (var room in roomSeedPool)
        {
            var exists = await context.Rooms.AnyAsync(item =>
                item.HotelId == room.HotelId && item.RoomType == room.RoomType);
            if (!exists)
            {
                context.Rooms.Add(room);
            }
        }

        await context.SaveChangesAsync();

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
            var companies = await context.BusCompanies.OrderBy(c => c.Id).ToListAsync();
            var destinations = await context.Destinations.OrderBy(d => d.Id).ToListAsync();
            
            if (companies.Count > 0 && destinations.Count >= 3)
            {
                var companyId = companies[0].Id;
                var baseDate = DateTime.UtcNow.AddDays(2).Date;

                // Add multiples schedules for testing
                var newSchedules = new List<BusSchedule>();
                
                // Add schedules for Da Lat to Da Nang, for next 10 days
                for (int dayOffset = 0; dayOffset < 10; dayOffset++)
                {
                    var currentDate = baseDate.AddDays(dayOffset);
                    newSchedules.Add(new BusSchedule
                    {
                        CompanyId = companyId,
                        FromDestId = destinations[0].Id, // Da Lat
                        ToDestId = destinations[2].Id, // Da Nang
                        DepartureTime = currentDate.AddHours(8), // 08:00 AM
                        ArrivalTime = currentDate.AddHours(14), // 02:00 PM
                        Price = 280000m,
                        CommissionRate = 0.08,
                        TotalSeats = 40
                    });
                    newSchedules.Add(new BusSchedule
                    {
                        CompanyId = companyId,
                        FromDestId = destinations[0].Id,
                        ToDestId = destinations[2].Id,
                        DepartureTime = currentDate.AddHours(14), // 02:00 PM
                        ArrivalTime = currentDate.AddHours(20), // 08:00 PM
                        Price = 300000m,
                        CommissionRate = 0.08,
                        TotalSeats = 40
                    });
                    newSchedules.Add(new BusSchedule
                    {
                        CompanyId = companies.Count > 1 ? companies[1].Id : companyId,
                        FromDestId = destinations[0].Id,
                        ToDestId = destinations[2].Id,
                        DepartureTime = currentDate.AddHours(22), // 10:00 PM
                        ArrivalTime = currentDate.AddDays(1).AddHours(4), // 04:00 AM next day
                        Price = 320000m,
                        CommissionRate = 0.08,
                        TotalSeats = 36
                    });

                    // Reverse route Da Nang to Da Lat
                    newSchedules.Add(new BusSchedule
                    {
                        CompanyId = companyId,
                        FromDestId = destinations[2].Id,
                        ToDestId = destinations[0].Id,
                        DepartureTime = currentDate.AddHours(8),
                        ArrivalTime = currentDate.AddHours(14),
                        Price = 280000m,
                        CommissionRate = 0.08,
                        TotalSeats = 40
                    });

                    // Route Da Nang to Da Nang (For UI testing)
                    newSchedules.Add(new BusSchedule
                    {
                        CompanyId = companyId,
                        FromDestId = destinations[2].Id, // Da Nang
                        ToDestId = destinations[2].Id, // Da Nang
                        DepartureTime = currentDate.AddHours(9),
                        ArrivalTime = currentDate.AddHours(10),
                        Price = 150000m,
                        CommissionRate = 0.08,
                        TotalSeats = 20
                    });

                    newSchedules.Add(new BusSchedule
                    {
                        CompanyId = companies.Count > 1 ? companies[1].Id : companyId,
                        FromDestId = destinations[2].Id, // Da Nang
                        ToDestId = destinations[2].Id, // Da Nang
                        DepartureTime = currentDate.AddHours(15),
                        ArrivalTime = currentDate.AddHours(16),
                        Price = 120000m,
                        CommissionRate = 0.08,
                        TotalSeats = 30
                    });
                }

                // Add schedules for Da Nang to Phu Quoc
                newSchedules.Add(new BusSchedule
                {
                    CompanyId = companyId,
                    FromDestId = destinations[2].Id,
                    ToDestId = destinations[1].Id,
                    DepartureTime = baseDate.AddHours(21),
                    ArrivalTime = baseDate.AddDays(1).AddHours(6),
                    Price = 450000m,
                    CommissionRate = 0.1,
                    TotalSeats = 40
                });

                context.BusSchedules.AddRange(newSchedules);
                await context.SaveChangesAsync();
            }
        }

        var allCompanies = await context.BusCompanies.OrderBy(item => item.Id).ToListAsync();
        var allDestinationsForRoutes = await context.Destinations.OrderBy(item => item.Id).ToListAsync();
        int? FindRouteDestinationId(string destinationName)
            => allDestinationsForRoutes.FirstOrDefault(item => item.Name == destinationName)?.Id;
        int ResolveCompanyId(string preferredName)
            => allCompanies.FirstOrDefault(item => item.Name == preferredName)?.Id
                ?? allCompanies.First().Id;

        if (allCompanies.Count > 0 && allDestinationsForRoutes.Count > 0)
        {
            var routeSeedPool = new List<BusSchedule>();
            var baseDate = DateTime.UtcNow.AddDays(2).Date;

            void AddDailyRoute(
                string companyName,
                string fromName,
                string toName,
                int departureHour,
                int durationHours,
                decimal price,
                int totalSeats,
                int totalDays = 10)
            {
                var fromId = FindRouteDestinationId(fromName);
                var toId = FindRouteDestinationId(toName);
                if (!fromId.HasValue || !toId.HasValue)
                {
                    return;
                }

                for (var dayOffset = 0; dayOffset < totalDays; dayOffset++)
                {
                    var departure = baseDate.AddDays(dayOffset).AddHours(departureHour);
                    routeSeedPool.Add(new BusSchedule
                    {
                        CompanyId = ResolveCompanyId(companyName),
                        FromDestId = fromId.Value,
                        ToDestId = toId.Value,
                        DepartureTime = departure,
                        ArrivalTime = departure.AddHours(durationHours),
                        Price = price,
                        CommissionRate = 0.08,
                        TotalSeats = totalSeats
                    });
                }
            }

            AddDailyRoute("Phuong Trang FUTA", "TP. Hồ Chí Minh", "Đà Lạt", 22, 7, 320000m, 36);
            AddDailyRoute("Thanh Buoi Express", "TP. Hồ Chí Minh", "Đà Lạt", 23, 7, 340000m, 34);
            AddDailyRoute("Phuong Trang FUTA", "Đà Lạt", "TP. Hồ Chí Minh", 22, 7, 320000m, 36);
            AddDailyRoute("Thanh Buoi Express", "Đà Lạt", "TP. Hồ Chí Minh", 23, 7, 340000m, 34);
            AddDailyRoute("Phuong Trang FUTA", "TP. Hồ Chí Minh", "Nha Trang", 21, 8, 360000m, 40);
            AddDailyRoute("Phuong Trang FUTA", "Nha Trang", "TP. Hồ Chí Minh", 21, 8, 360000m, 40);
            AddDailyRoute("Skynet Express", "Đà Nẵng", "Hội An", 8, 1, 180000m, 20);
            AddDailyRoute("Viet Travel Bus", "Đà Nẵng", "Hội An", 15, 1, 150000m, 24);
            AddDailyRoute("Skynet Express", "Hội An", "Đà Nẵng", 9, 1, 180000m, 20);
            AddDailyRoute("Viet Travel Bus", "Hội An", "Đà Nẵng", 16, 1, 150000m, 24);
            AddDailyRoute("Phuong Trang FUTA", "Hà Nội", "Hạ Long", 7, 3, 220000m, 29);
            AddDailyRoute("Phuong Trang FUTA", "Hạ Long", "Hà Nội", 15, 3, 220000m, 29);

            foreach (var schedule in routeSeedPool)
            {
                var exists = await context.BusSchedules.AnyAsync(item =>
                    item.CompanyId == schedule.CompanyId &&
                    item.FromDestId == schedule.FromDestId &&
                    item.ToDestId == schedule.ToDestId &&
                    item.DepartureTime == schedule.DepartureTime);

                if (!exists)
                {
                    context.BusSchedules.Add(schedule);
                }
            }

            await context.SaveChangesAsync();
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
                            BookedCommissionRate = 0.1,
                            ServiceDate = trips[0].StartDate,
                            HotelCheckOutDate = trips[0].EndDate
                        },
                        new TripItinerary
                        {
                            TripId = trips[1].Id,
                            DayNumber = 1,
                            ServiceType = TripServiceType.Hotel,
                            ServiceId = hotels[1].Id,
                            Quantity = 3,
                            BookedPrice = 4200000m,
                            BookedCommissionRate = 0.12,
                            ServiceDate = trips[1].StartDate,
                            HotelCheckOutDate = trips[1].EndDate
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

        if (!await context.Reviews.AnyAsync())
        {
            var demoUserId = await context.Users
                .Where(u => u.Email == "test@example.com")
                .Select(u => u.Id)
                .FirstOrDefaultAsync();
            var hotels = await context.Hotels.OrderBy(h => h.Id).ToListAsync();
            var companies = await context.BusCompanies.OrderBy(c => c.Id).ToListAsync();

            foreach (var hotel in hotels)
            {
                context.Reviews.AddRange(
                    new Review
                    {
                        UserId = demoUserId,
                        TargetType = ReviewTargetType.Hotel,
                        TargetId = hotel.Id,
                        Rating = 5,
                        Comment = $"Khong gian o {hotel.Name} rat thoai mai, phu hop nghi duong.",
                        CreatedAt = DateTime.UtcNow.AddDays(-hotel.Id)
                    },
                    new Review
                    {
                        UserId = demoUserId,
                        TargetType = ReviewTargetType.Hotel,
                        TargetId = hotel.Id,
                        Rating = 4,
                        Comment = "Dich vu tot, phong sach se va nhan vien than thien.",
                        CreatedAt = DateTime.UtcNow.AddDays(-hotel.Id - 2)
                    });
            }

            foreach (var company in companies)
            {
                context.Reviews.Add(new Review
                {
                    UserId = demoUserId,
                    TargetType = ReviewTargetType.BusCompany,
                    TargetId = company.Id,
                    Rating = 4,
                    Comment = $"Nha xe {company.Name} dung gio va phuc vu on dinh.",
                    CreatedAt = DateTime.UtcNow.AddDays(-company.Id - 1)
                });
            }

            await context.SaveChangesAsync();
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

        await SeedExploreAsync(context, demoUser.Id, adminUser.Id);
    }

    private static async Task SeedExploreAsync(ApplicationDbContext context, int demoUserId, int adminUserId)
    {
        if (await context.ExplorePosts.AnyAsync())
        {
            return;
        }

        var now = DateTime.UtcNow;
        var posts = new[]
        {
            new ExploreSeedPost(
                "Khám phá Vịnh Hạ Long - kỳ quan thiên nhiên thế giới",
                "Vịnh Hạ Long với hàng nghìn hòn đảo đá vôi, làn nước xanh ngọc và những đêm ngủ trên du thuyền đáng nhớ.",
                "Vịnh Hạ Long là một trong những biểu tượng du lịch Việt Nam. Du khách nên dành ít nhất hai ngày để đi thuyền qua các cụm đảo, ghé hang Sửng Sốt và ngắm hoàng hôn trên vịnh.",
                "https://images.unsplash.com/photo-1528127269322-539801943592?w=1200",
                "Hạ Long",
                "ha-long",
                "Quảng Ninh",
                "north",
                3,
                4.7m,
                1820,
                "biển,đảo,hạ-long,unesco",
                now.AddDays(-1)),
            new ExploreSeedPost(
                "Sa Pa trong sương giữa dãy Hoàng Liên Sơn",
                "Ruộng bậc thang, bản làng và khí hậu mát lạnh khiến Sa Pa luôn là điểm đến miền núi rất đáng đi.",
                "Sa Pa đẹp nhất vào mùa lúa chín và những ngày trời trong sau mưa. Hãy thử trekking bản Cát Cát, Tả Van và dậy sớm để săn mây trên đèo Ô Quy Hồ.",
                "https://images.unsplash.com/photo-1605640840605-14ac1855827b?w=1200",
                "Sa Pa",
                "sapa",
                "Lào Cai",
                "north",
                2,
                4.5m,
                3240,
                "núi,sapa,bản-làng,trekking",
                now.AddDays(-3)),
            new ExploreSeedPost(
                "Hội An - phố cổ nghìn tuổi lung linh ánh đèn",
                "Nhịp sống chậm, kiến trúc cổ và những con phố đèn lồng tạo nên một Hội An rất riêng.",
                "Hội An phù hợp để đi bộ, ăn cao lầu, uống cà phê trong phố cổ và đạp xe ra làng rau Trà Quế. Buổi tối là thời điểm đẹp nhất để chụp ảnh ven sông Hoài.",
                "https://images.unsplash.com/photo-1559592413-7cec4d0cae2b?w=1200",
                "Hội An",
                "hoi-an",
                "Quảng Nam",
                "central",
                2,
                4.8m,
                5120,
                "phố-cổ,di-sản,hội-an,ẩm-thực",
                now.AddDays(-5)),
            new ExploreSeedPost(
                "Phú Quốc - hòn đảo ngọc của Việt Nam",
                "Biển xanh, cát trắng, hải sản tươi và nhiều lựa chọn nghỉ dưỡng cho mọi lịch trình.",
                "Phú Quốc có đủ trải nghiệm từ nghỉ dưỡng ở bãi Kem, ngắm hoàng hôn Dinh Cậu đến khám phá các đảo nhỏ phía Nam. Nên thuê xe máy nếu muốn đi nhiều điểm trong ngày.",
                "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=1200",
                "Phú Quốc",
                "phu-quoc",
                "Kiên Giang",
                "south",
                3,
                4.6m,
                7650,
                "biển,đảo,phú-quốc,resort",
                now.AddDays(-7)),
            new ExploreSeedPost(
                "Đà Lạt - thành phố ngàn hoa trong sương",
                "Không khí mát mẻ, đồi thông và những quán cà phê nhìn xuống thung lũng làm Đà Lạt rất dễ thương.",
                "Đà Lạt hợp cho chuyến đi chậm: sáng uống cà phê, trưa ghé vườn dâu, chiều ngắm hoàng hôn ở đồi Đa Phú. Buổi tối nhớ thử bánh căn và sữa đậu nành nóng.",
                "https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=1200",
                "Đà Lạt",
                "da-lat",
                "Lâm Đồng",
                "south",
                2,
                4.4m,
                4320,
                "đà-lạt,núi,cà-phê,lâm-đồng",
                now.AddDays(-2)),
            new ExploreSeedPost(
                "Huế - cố đô dịu dàng bên sông Hương",
                "Di sản cung đình, ẩm thực tinh tế và nhịp sống chậm khiến Huế là một điểm dừng rất khác.",
                "Một ngày ở Huế nên bắt đầu với Đại Nội, tiếp tục bằng lăng Minh Mạng hoặc Khải Định và kết thúc bằng bún bò, chè Huế bên bờ sông Hương.",
                "https://images.unsplash.com/photo-1567521464027-f127ff144326?w=1200",
                "Huế",
                "hue",
                "Thừa Thiên Huế",
                "central",
                2,
                4.5m,
                3890,
                "huế,cố-đô,di-sản,ẩm-thực",
                now.AddDays(-4)),
            new ExploreSeedPost(
                "Ninh Bình - Tràng An giữa núi đá và đồng lúa",
                "Đi thuyền qua hang động, leo Hang Múa và ngắm mùa lúa là những trải nghiệm rất đáng nhớ.",
                "Ninh Bình dễ đi từ Hà Nội trong hai ngày một đêm. Tràng An, Tam Cốc, Hang Múa và chùa Bái Đính là các điểm phù hợp cho người lần đầu ghé.",
                "https://images.unsplash.com/photo-1528181304800-259b08848526?w=1200",
                "Ninh Bình",
                "ninh-binh",
                "Ninh Bình",
                "north",
                1,
                4.6m,
                2760,
                "ninh-bình,tràng-an,núi,tiết-kiệm",
                now.AddDays(-6)),
            new ExploreSeedPost(
                "Đà Nẵng - thành phố biển đáng sống",
                "Biển Mỹ Khê, cầu Rồng, Sơn Trà và khoảng cách gần Hội An giúp Đà Nẵng rất dễ lên lịch.",
                "Đà Nẵng phù hợp cho cả nghỉ dưỡng và khám phá. Hãy dành một buổi sáng ở bán đảo Sơn Trà, chiều tắm biển Mỹ Khê và tối xem cầu Rồng cuối tuần.",
                "https://images.unsplash.com/photo-1559592413-7cec4d0cae2b?w=1200",
                "Đà Nẵng",
                "da-nang",
                "Đà Nẵng",
                "central",
                2,
                4.6m,
                5870,
                "đà-nẵng,biển,thành-phố,sơn-trà",
                now.AddDays(-8))
        };

        foreach (var seed in posts)
        {
            var post = new ExplorePost
            {
                AuthorId = seed.CreatedAt.Day % 2 == 0 ? demoUserId : adminUserId,
                Title = seed.Title,
                Excerpt = seed.Excerpt,
                Content = $"{seed.Content}\n\n[image:{seed.ImageUrl}]",
                ThumbnailUrl = seed.ImageUrl,
                Location = seed.Location,
                CitySlug = seed.CitySlug,
                Province = seed.Province,
                Region = seed.Region,
                CostLevel = seed.CostLevel,
                AverageRating = seed.Rating,
                RatingCount = 3,
                ViewCount = seed.ViewCount,
                Tags = seed.Tags,
                CreatedAt = seed.CreatedAt
            };

            post.Images.Add(new ExplorePostImage
            {
                ImageUrl = seed.ImageUrl,
                SortOrder = 0
            });

            context.ExplorePosts.Add(post);
        }

        await context.SaveChangesAsync();

        var savedPosts = await context.ExplorePosts.OrderBy(post => post.Id).ToListAsync();
        foreach (var post in savedPosts)
        {
            context.ExplorePostRatings.AddRange(
                new ExplorePostRating { ExplorePostId = post.Id, UserId = demoUserId, Rating = post.AverageRating, CreatedAt = post.CreatedAt.AddHours(2) },
                new ExplorePostRating { ExplorePostId = post.Id, UserId = adminUserId, Rating = Math.Min(5m, post.AverageRating + 0.2m), CreatedAt = post.CreatedAt.AddHours(3) });

            context.ExplorePostLikes.Add(new ExplorePostLike
            {
                ExplorePostId = post.Id,
                UserId = demoUserId,
                CreatedAt = post.CreatedAt.AddHours(4)
            });

            if (post.Id % 2 == 0)
            {
                context.ExplorePostSaves.Add(new ExplorePostSave
                {
                    ExplorePostId = post.Id,
                    UserId = demoUserId,
                    CreatedAt = post.CreatedAt.AddHours(5)
                });
            }

            context.ExploreComments.AddRange(
                new ExploreComment
                {
                    ExplorePostId = post.Id,
                    UserId = demoUserId,
                    Content = "Bài viết rất hữu ích, mình đã lưu lại cho chuyến đi sắp tới.",
                    LikeCount = 8,
                    CreatedAt = post.CreatedAt.AddHours(6)
                },
                new ExploreComment
                {
                    ExplorePostId = post.Id,
                    UserId = adminUserId,
                    Content = "Gợi ý lịch trình rõ ràng và ảnh minh họa đẹp.",
                    LikeCount = 4,
                    CreatedAt = post.CreatedAt.AddHours(8)
                });
        }

        await context.SaveChangesAsync();
    }

    private static async Task EnsureLegacySchemaCompatibilityAsync(ApplicationDbContext context)
    {
        await context.Database.ExecuteSqlRawAsync(
            """
            IF OBJECT_ID(N'[dbo].[BusCompanies]', N'U') IS NOT NULL
               AND COL_LENGTH(N'dbo.BusCompanies', N'CommissionRate') IS NULL
            BEGIN
                ALTER TABLE [dbo].[BusCompanies] ADD [CommissionRate] float NULL;
            END
            """);
    }

    private sealed record ExploreSeedPost(
        string Title,
        string Excerpt,
        string Content,
        string ImageUrl,
        string Location,
        string CitySlug,
        string Province,
        string Region,
        int CostLevel,
        decimal Rating,
        int ViewCount,
        string Tags,
        DateTime CreatedAt);
}
