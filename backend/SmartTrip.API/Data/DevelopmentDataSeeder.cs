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

        var destinationsToUpsert = new[]
        {
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
            },
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
                Description = "Hòn đảo yên bình với biển xanh, hải sản tươi và nhịp sống thư thái.",
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

        foreach (var dest in destinationsToUpsert)
        {
            Destination? existing = null;
            if (dest.Name == "Đà Lạt")
                existing = await context.Destinations.FirstOrDefaultAsync(d => d.Name == " Đà lạt" || d.Name == "Đà Lạt");
            else if (dest.Name == "Phú Quốc")
                existing = await context.Destinations.FirstOrDefaultAsync(d => d.Name == "Phú Quốc" || d.Name == "Phú Quốc");
            else if (dest.Name == "Đà Nẵng")
                existing = await context.Destinations.FirstOrDefaultAsync(d => d.Name == " Đà Nẵng" || d.Name == "Đà Nẵng");
            else if (dest.Name == "Hạ Long")
                existing = await context.Destinations.FirstOrDefaultAsync(d => d.Name == " Hạ Long" || d.Name == "Hạ Long");
            else if (dest.Name == "Hà Nội")
                existing = await context.Destinations.FirstOrDefaultAsync(d => d.Name == " Hà Nội" || d.Name == " Hà Nội" || d.Name == "Hà Nội");
            else if (dest.Name == "TP. Hồ Chí Minh")
                existing = await context.Destinations.FirstOrDefaultAsync(d => d.Name == "TP. Hồ Chí Minh" || d.Name == "TP. Hồ Chí Minh");
            else if (dest.Name == "Phú Quý")
                existing = await context.Destinations.FirstOrDefaultAsync(d => d.Name == "Phú Quý" || d.Name == "Phú Quý");
            else if (dest.Name == "Hội An")
                existing = await context.Destinations.FirstOrDefaultAsync(d => d.Name == "Hội An" || d.Name == "Hội An");
            else
                existing = await context.Destinations.FirstOrDefaultAsync(d => d.Name == dest.Name);

            if (existing != null)
            {
                existing.Name = dest.Name;
                existing.Description = dest.Description;
                existing.CoverImageUrl = dest.CoverImageUrl;
                existing.IsHot = dest.IsHot;
            }
            else
            {
                context.Destinations.Add(dest);
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

        // Upsert core hotels by name — always overwrite to fix stale/encoding issues
        {
            var destinations = await context.Destinations.OrderBy(d => d.Id).ToListAsync();
            if (destinations.Count >= 3)
            {
                (int idx, string name, string address, int star, string desc)[] coreHotels =
                [
                    (0, "Pine Valley Hotel", "12 Hồ Xuân Hương, Phường 3, Đà Lạt", 4, "Nằm ngay trung tâm Đà Lạt thơ mộng, Pine Valley Hotel mang đến không gian nghỉ dưỡng ấm cúng với kiến trúc châu Âu cổ điển. Mỗi phòng đều có ban công nhìn ra hồ Xuân Hương hoặc rừng thông bạt ngàn. Khách sạn có nhà hàng phục vụ ẩm thực Việt-Pháp, quầy bar rượu vang, và khu vực lửa trại lãng mạn mỗi tối."),
                    (1, "Ocean Pearl Resort", "88 Trần Hưng Đạo, Dương Đông, Phú Quốc", 5, "Resort 5 sao đẳng cấp quốc tế nằm ngay bờ biển cát trắng Phú Quốc. Với hệ thống bể bơi vô cực nhìn ra biển, nhà hàng hải sản tươi sống, và các villa riêng biệt, Ocean Pearl mang đến trải nghiệm nghỉ dưỡng xa hoa đích thực. Dịch vụ butler 24/7, spa cao cấp và các hoạt động lặn biển đẳng cấp."),
                    (2, "Dragon Bridge Stay", "45 Bạch Đằng, Hải Châu, Đà Nẵng", 4, "Khách sạn boutique sang trọng nằm ven sông Hàn, cách Cầu Rồng chỉ 200m. Từ sân thượng có thể chiêm ngưỡng Cầu Rồng phun lửa mỗi cuối tuần. Gần bãi biển Mỹ Khê, phố cổ Hội An và khu ẩm thực Bạch Đằng. Nhà hàng sân thượng view sông Hàn không thể bỏ lỡ."),
                    (0, "Terracotta Hotel & Resort", "Phân khu chức năng 7.9, KDL Hồ Tuyền Lâm, Đà Lạt", 4, "Khu nghỉ dưỡng nép mình bên hồ Tuyền Lâm thơ mộng. Một nơi yên tĩnh và thư giãn lý tưởng."),
                    (1, "Vinpearl Resort & Spa", "Bãi Dài, Gành Dầu, Phú Quốc", 5, "Resort cao cấp với các tiện ích chuẩn 5 sao, khu vui chơi VinWonders và Safari kế bên.")
                ];

                foreach (var (idx, name, address, star, desc) in coreHotels)
                {
                    var destId = destinations[idx].Id;
                    var existing = await context.Hotels.FirstOrDefaultAsync(h => h.Name == name);
                    if (existing != null)
                    {
                        existing.DestinationId = destId;
                        existing.Address = address;
                        existing.StarRating = star;
                        existing.Description = desc;
                        existing.IsAvailable = true;
                    }
                    else
                    {
                        context.Hotels.Add(new Hotel
                        {
                            DestinationId = destId,
                            Name = name,
                            Address = address,
                            StarRating = star,
                            Description = desc,
                            IsAvailable = true
                        });
                    }
                }

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
                new Amenity { Name = "Đưa đón sân bay", IconUrl = "airport_shuttle" }
            );
            await context.SaveChangesAsync();
        }

        // Upsert core rooms by hotel + room type
        {
            var hotels = await context.Hotels.OrderBy(h => h.Id).ToListAsync();
            if (hotels.Count >= 3)
            {
                (int hIdx, string roomType, int cap, decimal price, double rate, int qty)[] coreRooms =
                [
                    (0, "Phòng Standard",       2, 850000m,  0.10, 8),
                    (0, "Phòng Deluxe View Hồ", 2, 1250000m, 0.12, 6),
                    (0, "Suite Gia đình",        4, 2100000m, 0.15, 3),
                    (1, "Phòng Deluxe Biển",    2, 2450000m, 0.12, 10),
                    (1, "Pool Access Villa",     2, 4200000m, 0.15, 5),
                    (1, "Overwater Bungalow",    2, 7500000m, 0.18, 2),
                    (2, "Phòng City View",      2, 980000m,  0.10, 10),
                    (2, "Phòng River View",     2, 1480000m, 0.12, 6),
                    (2, "Suite Cầu Rồng",       4, 2800000m, 0.15, 2),
                ];

                foreach (var (hIdx, roomType, cap, price, rate, qty) in coreRooms)
                {
                    if (hIdx >= hotels.Count) continue;
                    var hId = hotels[hIdx].Id;
                    var existing = await context.Rooms.FirstOrDefaultAsync(r => r.HotelId == hId && r.RoomType == roomType);
                    if (existing != null)
                    {
                        existing.Capacity = cap;
                        existing.PricePerNight = price;
                        existing.CommissionRate = rate;
                        existing.AvailableQty = qty;
                    }
                    else
                    {
                        context.Rooms.Add(new Room { HotelId = hId, RoomType = roomType, Capacity = cap, PricePerNight = price, CommissionRate = rate, AvailableQty = qty });
                    }
                }

                if (hotels.Count > 3)
                {
                    var extras = new[] {
                        (3, "Phòng Standard",          1000000m, 0.10, 5),
                        (4, "Phòng Vinpearl Standard", 3500000m, 0.15, 15)
                    };
                    foreach (var (hIdx, rType, price, rate, qty) in extras)
                    {
                        if (hIdx >= hotels.Count) continue;
                        var hId = hotels[hIdx].Id;
                        var existing = await context.Rooms.FirstOrDefaultAsync(r => r.HotelId == hId && r.RoomType == rType);
                        if (existing == null)
                            context.Rooms.Add(new Room { HotelId = hId, RoomType = rType, Capacity = 2, PricePerNight = price, CommissionRate = rate, AvailableQty = qty });
                    }
                }

                await context.SaveChangesAsync();

                // Gán amenities cho từng hotel (chỉ khi chưa có)
                var amenities = await context.Amenities.OrderBy(a => a.Id).ToListAsync();
                if (amenities.Count >= 10)
                {
                    var h0 = await context.Hotels.Include(h => h.Amenities).FirstOrDefaultAsync(h => h.Id == hotels[0].Id);
                    var h1 = await context.Hotels.Include(h => h.Amenities).FirstOrDefaultAsync(h => h.Id == hotels[1].Id);
                    var h2 = await context.Hotels.Include(h => h.Amenities).FirstOrDefaultAsync(h => h.Id == hotels[2].Id);
                    if (h0 != null && !h0.Amenities.Any()) h0.Amenities = [amenities[0], amenities[1], amenities[2], amenities[3], amenities[4], amenities[8]];
                    if (h1 != null && !h1.Amenities.Any()) h1.Amenities = [amenities[0], amenities[1], amenities[2], amenities[3], amenities[4], amenities[5], amenities[6], amenities[7], amenities[8], amenities[9]];
                    if (h2 != null && !h2.Amenities.Any()) h2.Amenities = [amenities[0], amenities[1], amenities[2], amenities[3], amenities[4], amenities[7], amenities[8]];
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
        AddRoomSeed("Saigon Central Stay", "Suite Gia đình", 4, 1850000m, 0.12, 4);
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
                    new Review { UserId = demoUserId, TripId = trips[0].Id, TargetType = ReviewTargetType.Hotel, TargetId = hotels[2].Id, Rating = 4, Comment = "Vị trí đắc địa nhìn ra sông Hàn và Cầu Rồng! Mỗi cuối tuần xem lửa phun từ ban công phòng River View là kỷ niệm không thể quên. Nhà hàng sân thượng view đẹp hơn mong đợi.", CreatedAt = DateTime.UtcNow.AddDays(-8) },
                    new Review { UserId = demoUserId, TripId = trips[0].Id, TargetType = ReviewTargetType.Hotel, TargetId = hotels[2].Id, Rating = 4, Comment = "Gần bãi biển Mỹ Khê chỉ 10 phút xe taxi, gần Hội An 30 phút. Phòng City View tuy nhỏ hơn nhưng vẫn tiện nghi đầy đủ. Bữa sáng có các món ăn Đà Nẵng truyền thống rất ngon.", CreatedAt = DateTime.UtcNow.AddDays(-25) }
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
                var baseDate = DateTime.UtcNow.AddDays(1).Date;

                // Add multiples schedules for testing
                var newSchedules = new List<BusSchedule>();
                
                // Add schedules for Da Lat to Da Nang, for next 60 days
                for (int dayOffset = 0; dayOffset < 60; dayOffset++)
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
            var baseDate = DateTime.UtcNow.AddDays(1).Date;

            void AddDailyRoute(
                string companyName,
                string fromName,
                string toName,
                int departureHour,
                int durationHours,
                decimal price,
                int totalSeats,
                int totalDays = 60)
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
            
            // Additional routes for comprehensive data
            AddDailyRoute("Phuong Trang FUTA", "Hà Nội", "Đà Nẵng", 18, 14, 550000m, 36);
            AddDailyRoute("Phuong Trang FUTA", "Đà Nẵng", "Hà Nội", 18, 14, 550000m, 36);
            AddDailyRoute("Thanh Buoi Express", "TP. Hồ Chí Minh", "Đà Nẵng", 16, 18, 650000m, 34);
            AddDailyRoute("Thanh Buoi Express", "Đà Nẵng", "TP. Hồ Chí Minh", 16, 18, 650000m, 34);
            AddDailyRoute("Skynet Express", "Nha Trang", "Đà Lạt", 8, 4, 200000m, 29);
            AddDailyRoute("Skynet Express", "Đà Lạt", "Nha Trang", 14, 4, 200000m, 29);
            AddDailyRoute("Viet Travel Bus", "TP. Hồ Chí Minh", "Phú Quý", 22, 5, 450000m, 40); // Bus to port
            AddDailyRoute("Viet Travel Bus", "Phú Quý", "TP. Hồ Chí Minh", 10, 5, 450000m, 40);

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
                        Comment = $"Không gian ở {hotel.Name} rất thoải mái, phù hợp nghỉ dưỡng.",
                        CreatedAt = DateTime.UtcNow.AddDays(-hotel.Id)
                    },
                    new Review
                    {
                        UserId = demoUserId,
                        TargetType = ReviewTargetType.Hotel,
                        TargetId = hotel.Id,
                        Rating = 4,
                        Comment = "Dịch vụ tốt, phòng sạch sẽ và nhân viên thân thiện.",
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
                    Comment = $"Nha xe {company.Name} đúng giờ và phục vụ ổn định.",
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

        await SeedExpandedTestDataAsync(context, demoUser.Id, adminUser.Id);
        await SeedExploreAsync(context, demoUser.Id, adminUser.Id);
    }


    private static async Task SeedExpandedTestDataAsync(ApplicationDbContext context, int demoUserId, int adminUserId)
    {
        await SeedMoreDestinationsAsync(context);
        await SeedMoreBusCompaniesAsync(context);
        await SeedMoreHotelsAsync(context);
        await SeedMoreRoomsAsync(context);
        await SeedMoreBusSchedulesAsync(context);
        await SeedMoreReviewsAsync(context, demoUserId, adminUserId);
        await SeedMoreTripsAsync(context, demoUserId);
        await SeedMorePaymentsAsync(context);
        await SeedMoreWishlistsAsync(context, demoUserId);
    }

    private static async Task SeedMoreDestinationsAsync(ApplicationDbContext context)
    {
        var extraDestinations = new[]
        {
            new Destination { Name = "Vũng Tàu", Description = "Thành phố biển gần Sài Gòn, phù hợp đi cuối tuần, ăn hải sản và nghỉ dưỡng.", CoverImageUrl = "https://images.unsplash.com/photo-1500375592092-40eb2168fd21", IsHot = true },
            new Destination { Name = "Sapa", Description = "Thị trấn vùng cao với ruộng bậc thang, săn mây và khí hậu mát lạnh quanh năm.", CoverImageUrl = "https://images.unsplash.com/photo-1605640840605-14ac1855827b", IsHot = true },
            new Destination { Name = "Ninh Bình", Description = "Vùng di sản với Tràng An, Tam Cốc, Hang Múa và cảnh quan núi đá vôi ấn tượng.", CoverImageUrl = "https://images.unsplash.com/photo-1528181304800-259b08848526", IsHot = true },
            new Destination { Name = "Huế", Description = "Cố đô trầm mặc, giàu di sản và ẩm thực tinh tế.", CoverImageUrl = "https://images.unsplash.com/photo-1567521464027-f127ff144326", IsHot = true },
            new Destination { Name = "Quy Nhơn", Description = "Thành phố biển yên bình, bãi cát đẹp, đồ ăn ngon và chi phí dễ chịu.", CoverImageUrl = "https://images.unsplash.com/photo-1507525428034-b723cf961d3e", IsHot = true },
            new Destination { Name = "Cần Thơ", Description = "Thủ phủ miền Tây với chợ nổi, miệt vườn và nhịp sống sông nước.", CoverImageUrl = "https://images.unsplash.com/photo-1528127269322-539801943592", IsHot = false },
            new Destination { Name = "Mũi Né", Description = "Điểm đến nổi bật với đồi cát, biển và resort nghỉ dưỡng.", CoverImageUrl = "https://images.unsplash.com/photo-1544551763-46a013bb70d5", IsHot = true }
        };

        foreach (var destination in extraDestinations)
        {
            var exists = await context.Destinations.AnyAsync(item => item.Name == destination.Name);
            if (!exists)
            {
                context.Destinations.Add(destination);
            }
        }

        await context.SaveChangesAsync();
    }

    private static async Task SeedMoreBusCompaniesAsync(ApplicationDbContext context)
    {
        var extraCompanies = new[]
        {
            new BusCompany { Name = "Hoang Long Express", Hotline = "19007070", LogoUrl = "https://images.unsplash.com/photo-1517142089942-ba376ce32a2e" },
            new BusCompany { Name = "An Phu Travel", Hotline = "19008080", LogoUrl = "https://images.unsplash.com/photo-1544620347-c4fd4a3d5957" }
        };

        foreach (var company in extraCompanies)
        {
            var exists = await context.BusCompanies.AnyAsync(item => item.Name == company.Name);
            if (!exists)
            {
                context.BusCompanies.Add(company);
            }
        }

        await context.SaveChangesAsync();
    }

    private static async Task SeedMoreHotelsAsync(ApplicationDbContext context)
    {
        var destinations = await context.Destinations.ToListAsync();
        int? FindDestinationId(string name) => destinations.FirstOrDefault(item => item.Name == name)?.Id;

        var extraHotels = new[]
        {
            new Hotel { DestinationId = FindDestinationId("Vũng Tàu") ?? 0, Name = "Seaside Breeze Hotel", Address = "01 Trần Phú, Vũng Tàu", StarRating = 4, Description = "Khách sạn gần biển, phù hợp nghỉ cuối tuần và đi bộ ra bãi sau.", IsAvailable = true },
            new Hotel { DestinationId = FindDestinationId("Vũng Tàu") ?? 0, Name = "Cap Saint Jacques Boutique", Address = "169 Thùy Vân, Vũng Tàu", StarRating = 5, Description = "Khách sạn biển cao cấp với hồ bơi, nhà hàng và view hoàng hôn.", IsAvailable = true },
            new Hotel { DestinationId = FindDestinationId("Sapa") ?? 0, Name = "Cloud Valley Sapa", Address = "08 Fansipan, Sa Pa", StarRating = 4, Description = "Nơi lưu trú ấm áp, gần trung tâm và rất tiện săn mây.", IsAvailable = true },
            new Hotel { DestinationId = FindDestinationId("Sapa") ?? 0, Name = "Muong Hoa Retreat", Address = "Tả Van, Sa Pa", StarRating = 5, Description = "Resort nghỉ dưỡng giữa thung lũng ruộng bậc thang, yên tĩnh và đẹp.", IsAvailable = true },
            new Hotel { DestinationId = FindDestinationId("Ninh Bình") ?? 0, Name = "Trang An Heritage Hotel", Address = "45 Tràng An, Ninh Bình", StarRating = 4, Description = "Khách sạn gần các điểm tham quan nổi tiếng, thuận tiện di chuyển.", IsAvailable = true },
            new Hotel { DestinationId = FindDestinationId("Huế") ?? 0, Name = "Huong River Boutique", Address = "12 Lê Lợi, Huế", StarRating = 4, Description = "Lưu trú gần sông Hương, phù hợp khám phá trung tâm thành phố.", IsAvailable = true },
            new Hotel { DestinationId = FindDestinationId("Quy Nhơn") ?? 0, Name = "An Ya Sea Hotel", Address = "28 Nguyễn Huệ, Quy Nhơn", StarRating = 4, Description = "Khách sạn gần biển, phù hợp khách gia đình và nhóm bạn.", IsAvailable = true },
            new Hotel { DestinationId = FindDestinationId("Cần Thơ") ?? 0, Name = "Ninh Kieu Riverside Hotel", Address = "2 Hai Bà Trưng, Cần Thơ", StarRating = 5, Description = "Khách sạn trung tâm bên bờ sông, tiện đi chợ nổi và bến Ninh Kiều.", IsAvailable = true },
            new Hotel { DestinationId = FindDestinationId("Mũi Né") ?? 0, Name = "Dune Bay Resort", Address = "14 Nguyễn Đình Chiểu, Mũi Né", StarRating = 5, Description = "Resort nghỉ dưỡng sát biển, phù hợp gia đình và cặp đôi.", IsAvailable = true }
        };

        foreach (var hotel in extraHotels.Where(item => item.DestinationId > 0))
        {
            var exists = await context.Hotels.AnyAsync(item => item.Name == hotel.Name);
            if (!exists)
            {
                context.Hotels.Add(hotel);
            }
        }

        await context.SaveChangesAsync();
    }

    private static async Task SeedMoreRoomsAsync(ApplicationDbContext context)
    {
        var hotels = await context.Hotels.ToListAsync();
        int? GetHotelId(string hotelName) => hotels.FirstOrDefault(item => item.Name == hotelName)?.Id;

        var extraRooms = new[]
        {
            new Room { HotelId = GetHotelId("Seaside Breeze Hotel") ?? 0, RoomType = "Standard Sea View", Capacity = 2, PricePerNight = 980000m, CommissionRate = 0.10, AvailableQty = 8 },
            new Room { HotelId = GetHotelId("Seaside Breeze Hotel") ?? 0, RoomType = "Family Room", Capacity = 4, PricePerNight = 1550000m, CommissionRate = 0.12, AvailableQty = 4 },
            new Room { HotelId = GetHotelId("Cap Saint Jacques Boutique") ?? 0, RoomType = "Deluxe Ocean", Capacity = 2, PricePerNight = 1850000m, CommissionRate = 0.12, AvailableQty = 6 },
            new Room { HotelId = GetHotelId("Cap Saint Jacques Boutique") ?? 0, RoomType = "Suite Premier", Capacity = 3, PricePerNight = 3200000m, CommissionRate = 0.15, AvailableQty = 2 },
            new Room { HotelId = GetHotelId("Cloud Valley Sapa") ?? 0, RoomType = "Mountain View", Capacity = 2, PricePerNight = 1200000m, CommissionRate = 0.10, AvailableQty = 10 },
            new Room { HotelId = GetHotelId("Muong Hoa Retreat") ?? 0, RoomType = "Premium Bungalow", Capacity = 2, PricePerNight = 2400000m, CommissionRate = 0.15, AvailableQty = 5 },
            new Room { HotelId = GetHotelId("Trang An Heritage Hotel") ?? 0, RoomType = "Garden View", Capacity = 2, PricePerNight = 760000m, CommissionRate = 0.08, AvailableQty = 12 },
            new Room { HotelId = GetHotelId("Huong River Boutique") ?? 0, RoomType = "City View", Capacity = 2, PricePerNight = 1150000m, CommissionRate = 0.10, AvailableQty = 8 },
            new Room { HotelId = GetHotelId("An Ya Sea Hotel") ?? 0, RoomType = "Ocean Twin", Capacity = 2, PricePerNight = 1050000m, CommissionRate = 0.10, AvailableQty = 9 },
            new Room { HotelId = GetHotelId("Ninh Kieu Riverside Hotel") ?? 0, RoomType = "Riverside Suite", Capacity = 4, PricePerNight = 1980000m, CommissionRate = 0.12, AvailableQty = 3 },
            new Room { HotelId = GetHotelId("Dune Bay Resort") ?? 0, RoomType = "Beach Villa", Capacity = 2, PricePerNight = 2800000m, CommissionRate = 0.15, AvailableQty = 4 }
        };

        foreach (var room in extraRooms.Where(item => item.HotelId > 0))
        {
            var exists = await context.Rooms.AnyAsync(item => item.HotelId == room.HotelId && item.RoomType == room.RoomType);
            if (!exists)
            {
                context.Rooms.Add(room);
            }
        }

        await context.SaveChangesAsync();
    }

    private static async Task SeedMoreBusSchedulesAsync(ApplicationDbContext context)
    {
        var companies = await context.BusCompanies.OrderBy(c => c.Id).ToListAsync();
        var destinations = await context.Destinations.OrderBy(d => d.Id).ToListAsync();
        if (companies.Count == 0 || destinations.Count == 0)
        {
            return;
        }

        int? FindDestinationId(string name) => destinations.FirstOrDefault(item => item.Name == name)?.Id;
        int ResolveCompanyId(string name) => companies.FirstOrDefault(item => item.Name == name)?.Id ?? companies.First().Id;
        var startDate = DateTime.UtcNow.AddDays(1).Date;
        var routes = new List<BusSchedule>();

        void AddRoute(string company, string from, string to, int departureHour, int durationHours, decimal price, int seats, int totalDays = 45)
        {
            var fromId = FindDestinationId(from);
            var toId = FindDestinationId(to);
            if (!fromId.HasValue || !toId.HasValue)
            {
                return;
            }

            for (var i = 0; i < totalDays; i++)
            {
                var departure = startDate.AddDays(i).AddHours(departureHour);
                routes.Add(new BusSchedule
                {
                    CompanyId = ResolveCompanyId(company),
                    FromDestId = fromId.Value,
                    ToDestId = toId.Value,
                    DepartureTime = departure,
                    ArrivalTime = departure.AddHours(durationHours),
                    Price = price,
                    CommissionRate = 0.08,
                    TotalSeats = seats
                });
            }
        }

        AddRoute("Phuong Trang FUTA", "TP. Hồ Chí Minh", "Vũng Tàu", 7, 3, 140000m, 34);
        AddRoute("Phuong Trang FUTA", "Vũng Tàu", "TP. Hồ Chí Minh", 16, 3, 140000m, 34);
        AddRoute("Hoang Long Express", "TP. Hồ Chí Minh", "Sapa", 20, 30, 790000m, 40);
        AddRoute("Hoang Long Express", "Sapa", "TP. Hồ Chí Minh", 18, 30, 790000m, 40);
        AddRoute("An Phu Travel", "Hà Nội", "Ninh Bình", 8, 2, 160000m, 29);
        AddRoute("An Phu Travel", "Ninh Bình", "Hà Nội", 16, 2, 160000m, 29);
        AddRoute("Thanh Buoi Express", "Đà Nẵng", "Huế", 8, 3, 190000m, 30);
        AddRoute("Thanh Buoi Express", "Huế", "Đà Nẵng", 14, 3, 190000m, 30);
        AddRoute("Skynet Express", "TP. Hồ Chí Minh", "Quy Nhơn", 18, 13, 520000m, 36);
        AddRoute("Skynet Express", "Quy Nhơn", "TP. Hồ Chí Minh", 18, 13, 520000m, 36);
        AddRoute("Viet Travel Bus", "TP. Hồ Chí Minh", "Cần Thơ", 8, 3, 170000m, 30);
        AddRoute("Viet Travel Bus", "Cần Thơ", "TP. Hồ Chí Minh", 15, 3, 170000m, 30);
        AddRoute("An Phu Travel", "TP. Hồ Chí Minh", "Mũi Né", 6, 5, 220000m, 29);
        AddRoute("An Phu Travel", "Mũi Né", "TP. Hồ Chí Minh", 14, 5, 220000m, 29);

        foreach (var route in routes)
        {
            var exists = await context.BusSchedules.AnyAsync(item =>
                item.CompanyId == route.CompanyId &&
                item.FromDestId == route.FromDestId &&
                item.ToDestId == route.ToDestId &&
                item.DepartureTime == route.DepartureTime);

            if (!exists)
            {
                context.BusSchedules.Add(route);
            }
        }

        await context.SaveChangesAsync();
    }

    private static async Task SeedMoreReviewsAsync(ApplicationDbContext context, int demoUserId, int adminUserId)
    {
        var hotels = await context.Hotels.ToListAsync();
        var companies = await context.BusCompanies.ToListAsync();

        var reviewHotelNames = new[]
        {
            "Seaside Breeze Hotel",
            "Cloud Valley Sapa",
            "Trang An Heritage Hotel",
            "Huong River Boutique",
            "An Ya Sea Hotel",
            "Ninh Kieu Riverside Hotel",
            "Dune Bay Resort",
            "Cap Saint Jacques Boutique",
            "Muong Hoa Retreat"
        };

        var reviewTargets = hotels.Where(h => reviewHotelNames.Contains(h.Name)).ToList();
        foreach (var hotel in reviewTargets)
        {
            var exists = await context.Reviews.AnyAsync(item => item.TargetType == ReviewTargetType.Hotel && item.TargetId == hotel.Id && item.Comment.Contains(hotel.Name));
            if (!exists && demoUserId != 0)
            {
                context.Reviews.AddRange(
                    new Review
                    {
                        UserId = demoUserId,
                        TargetType = ReviewTargetType.Hotel,
                        TargetId = hotel.Id,
                        Rating = 5,
                        Comment = $"Khách sạn {hotel.Name} có vị trí tốt, dịch vụ ổn và rất hợp để test.",
                        CreatedAt = DateTime.UtcNow.AddDays(-hotel.Id)
                    },
                    new Review
                    {
                        UserId = adminUserId,
                        TargetType = ReviewTargetType.Hotel,
                        TargetId = hotel.Id,
                        Rating = 4,
                        Comment = $"Trải nghiệm tại {hotel.Name} khá tốt, phòng sạch và dễ tìm.",
                        CreatedAt = DateTime.UtcNow.AddDays(-hotel.Id - 1)
                    });
            }
        }

        var reviewCompanyNames = new[]
        {
            "Phuong Trang FUTA",
            "Thanh Buoi Express",
            "Hoang Long Express",
            "An Phu Travel"
        };

        foreach (var company in companies.Where(item => reviewCompanyNames.Contains(item.Name)))
        {
            var exists = await context.Reviews.AnyAsync(item => item.TargetType == ReviewTargetType.BusCompany && item.TargetId == company.Id);
            if (!exists && demoUserId != 0)
            {
                context.Reviews.Add(new Review
                {
                    UserId = demoUserId,
                    TargetType = ReviewTargetType.BusCompany,
                    TargetId = company.Id,
                    Rating = 4,
                    Comment = $"Nhà xe {company.Name} phù hợp để test dữ liệu chuyến đi.",
                    CreatedAt = DateTime.UtcNow.AddDays(-company.Id)
                });
            }
        }

        await context.SaveChangesAsync();
    }

    private static async Task SeedMoreTripsAsync(ApplicationDbContext context, int demoUserId)
    {
        if (demoUserId == 0)
        {
            return;
        }

        var destinations = await context.Destinations.ToListAsync();
        var vungTau = destinations.FirstOrDefault(item => item.Name == "Vũng Tàu");
        var sapa = destinations.FirstOrDefault(item => item.Name == "Sapa");
        var hue = destinations.FirstOrDefault(item => item.Name == "Huế");
        var quyNhon = destinations.FirstOrDefault(item => item.Name == "Quy Nhơn");

        var existing = await context.Trips.Select(item => item.Title).ToListAsync();
        var extraTrips = new List<Trip>();

        if (vungTau != null && !existing.Contains("Vung Tau Weekend Test"))
        {
            extraTrips.Add(new Trip
            {
                UserId = demoUserId,
                DestinationId = vungTau.Id,
                Title = "Vung Tau Weekend Test",
                StartDate = DateOnly.FromDateTime(DateTime.UtcNow.AddDays(5)),
                EndDate = DateOnly.FromDateTime(DateTime.UtcNow.AddDays(7)),
                TotalAmount = 2200000m,
                TotalProfit = 240000m,
                Status = TripStatus.Pending,
                CreatedAt = DateTime.UtcNow.AddDays(-2)
            });
        }

        if (sapa != null && !existing.Contains("Sapa Winter Test"))
        {
            extraTrips.Add(new Trip
            {
                UserId = demoUserId,
                DestinationId = sapa.Id,
                Title = "Sapa Winter Test",
                StartDate = DateOnly.FromDateTime(DateTime.UtcNow.AddDays(12)),
                EndDate = DateOnly.FromDateTime(DateTime.UtcNow.AddDays(15)),
                TotalAmount = 4800000m,
                TotalProfit = 520000m,
                Status = TripStatus.Pending,
                CreatedAt = DateTime.UtcNow.AddDays(-4)
            });
        }

        if (hue != null && !existing.Contains("Hue Heritage Test"))
        {
            extraTrips.Add(new Trip
            {
                UserId = demoUserId,
                DestinationId = hue.Id,
                Title = "Hue Heritage Test",
                StartDate = DateOnly.FromDateTime(DateTime.UtcNow.AddDays(18)),
                EndDate = DateOnly.FromDateTime(DateTime.UtcNow.AddDays(20)),
                TotalAmount = 3100000m,
                TotalProfit = 300000m,
                Status = TripStatus.Paid,
                CreatedAt = DateTime.UtcNow.AddDays(-6)
            });
        }

        if (quyNhon != null && !existing.Contains("Quy Nhon Sea Test"))
        {
            extraTrips.Add(new Trip
            {
                UserId = demoUserId,
                DestinationId = quyNhon.Id,
                Title = "Quy Nhon Sea Test",
                StartDate = DateOnly.FromDateTime(DateTime.UtcNow.AddDays(25)),
                EndDate = DateOnly.FromDateTime(DateTime.UtcNow.AddDays(28)),
                TotalAmount = 5600000m,
                TotalProfit = 620000m,
                Status = TripStatus.Pending,
                CreatedAt = DateTime.UtcNow.AddDays(-7)
            });
        }

        if (extraTrips.Count > 0)
        {
            context.Trips.AddRange(extraTrips);
            await context.SaveChangesAsync();
        }
    }

    private static async Task SeedMorePaymentsAsync(ApplicationDbContext context)
    {
        var trips = await context.Trips.OrderBy(t => t.Id).ToListAsync();
        var existing = await context.Payments.Select(item => item.TransactionId).ToListAsync();

        foreach (var trip in trips)
        {
            var transactionId = $"TEST-{trip.Id:0000}";
            if (existing.Contains(transactionId))
            {
                continue;
            }

            context.Payments.Add(new Payment
            {
                TripId = trip.Id,
                PaymentMethod = PaymentMethod.Momo,
                TransactionId = transactionId,
                Amount = trip.TotalAmount,
                Status = trip.Status == TripStatus.Paid ? PaymentStatus.Paid : PaymentStatus.Pending,
                PaidAt = DateTime.UtcNow.AddDays(-(trip.Id % 10))
            });
        }

        await context.SaveChangesAsync();
    }

    private static async Task SeedMoreWishlistsAsync(ApplicationDbContext context, int demoUserId)
    {
        if (demoUserId == 0)
        {
            return;
        }

                var hotelNames = new[]
        {
            "Seaside Breeze Hotel",
            "Cloud Valley Sapa",
            "Trang An Heritage Hotel",
            "Huong River Boutique",
            "An Ya Sea Hotel",
            "Ninh Kieu Riverside Hotel",
            "Dune Bay Resort"
        };

        var hotelIds = await context.Hotels
            .Where(h => hotelNames.Contains(h.Name))
            .Select(h => h.Id)
            .ToListAsync();
        var busIds = await context.BusSchedules
            .Where(s => s.DepartureTime > DateTime.UtcNow)
            .OrderBy(s => s.Id)
            .Select(s => s.Id)
            .Take(3)
            .ToListAsync();

        foreach (var hotelId in hotelIds)
        {
            var exists = await context.Wishlists.AnyAsync(item => item.UserId == demoUserId && item.ItemType == WishlistItemType.Hotel && item.ItemId == hotelId);
            if (!exists)
            {
                context.Wishlists.Add(new Wishlist
                {
                    UserId = demoUserId,
                    ItemType = WishlistItemType.Hotel,
                    ItemId = hotelId,
                    CreatedAt = DateTime.UtcNow
                });
            }
        }

        foreach (var busId in busIds)
        {
            var exists = await context.Wishlists.AnyAsync(item => item.UserId == demoUserId && item.ItemType == WishlistItemType.Bus && item.ItemId == busId);
            if (!exists)
            {
                context.Wishlists.Add(new Wishlist
                {
                    UserId = demoUserId,
                    ItemType = WishlistItemType.Bus,
                    ItemId = busId,
                    CreatedAt = DateTime.UtcNow
                });
            }
        }

        await context.SaveChangesAsync();
    }


    private static async Task SeedNationalTestDataAsync(ApplicationDbContext context)
    {
        var destinations = await context.Destinations.ToListAsync();
        int? FindDestinationId(string name) => destinations.FirstOrDefault(item => item.Name == name)?.Id;

        var additionalDestinations = new[]
        {
            new Destination { Name = "Đà Nẵng", Description = "Thành phố biển năng động, có cầu Rồng, biển Mỹ Khê và Sơn Trà.", CoverImageUrl = "https://images.unsplash.com/photo-1559592413-7cec4d0cae2b", IsHot = true },
            new Destination { Name = "Hà Nội", Description = "Thủ đô văn hóa, ẩm thực phong phú và nhiều điểm tham quan lịch sử.", CoverImageUrl = "https://images.unsplash.com/photo-1509030450996-dd1a26dda07a", IsHot = true },
            new Destination { Name = "TP. Hồ Chí Minh", Description = "Trung tâm kinh tế sôi động với nhiều lựa chọn giải trí và mua sắm.", CoverImageUrl = "https://images.unsplash.com/photo-1528127269322-539801943592", IsHot = true },
            new Destination { Name = "Hội An", Description = "Phố cổ di sản, phù hợp đi bộ, đạp xe và trải nghiệm ẩm thực địa phương.", CoverImageUrl = "https://images.unsplash.com/photo-1559592413-7cec4d0cae2b", IsHot = true },
            new Destination { Name = "Nha Trang", Description = "Thành phố biển nổi tiếng với đảo, lặn biển và resort nghỉ dưỡng.", CoverImageUrl = "https://images.unsplash.com/photo-1584347718919-6d60a16d80ff", IsHot = true }
        };

        foreach (var destination in additionalDestinations)
        {
            var exists = await context.Destinations.AnyAsync(item => item.Name == destination.Name);
            if (!exists)
            {
                context.Destinations.Add(destination);
            }
        }

        await context.SaveChangesAsync();

        var hotelSeeds = new[]
        {
            new { Destination = "Đà Nẵng", Name = "Han River Pearl Hotel", Address = "56 Bạch Đằng, Đà Nẵng", Stars = 4, Description = "Khách sạn ven sông Hàn, gần cầu Rồng và trung tâm." },
            new { Destination = "Đà Nẵng", Name = "My Khe Coast Hotel", Address = "88 Võ Nguyên Giáp, Đà Nẵng", Stars = 5, Description = "Lưu trú sát biển Mỹ Khê, phù hợp nghỉ dưỡng." },
            new { Destination = "Hà Nội", Name = "Hoan Kiem Heritage Hotel", Address = "15 Hàng Bè, Hoàn Kiếm, Hà Nội", Stars = 4, Description = "Khách sạn trung tâm, tiện khám phá phố cổ." },
            new { Destination = "Hà Nội", Name = "West Lake Serenity", Address = "32 đường Thanh Niên, Tây Hồ, Hà Nội", Stars = 5, Description = "Resort đô thị bên hồ Tây, yên tĩnh và sang trọng." },
            new { Destination = "TP. Hồ Chí Minh", Name = "Saigon Skyline Hotel", Address = "120 Lê Lợi, Quận 1, TP. Hồ Chí Minh", Stars = 4, Description = "Khách sạn trung tâm, thuận tiện công tác và du lịch." },
            new { Destination = "TP. Hồ Chí Minh", Name = "Ben Thanh Luxury Stay", Address = "28 Nguyễn An Ninh, Quận 1, TP. Hồ Chí Minh", Stars = 5, Description = "Lựa chọn cao cấp gần chợ Bến Thành." },
            new { Destination = "Hội An", Name = "Thu Bon Lantern Hotel", Address = "44 Trần Phú, Hội An", Stars = 4, Description = "Không gian phố cổ, thuận tiện đi bộ ngắm đèn lồng." },
            new { Destination = "Nha Trang", Name = "Coral Bay Premier", Address = "10 Trần Phú, Nha Trang", Stars = 5, Description = "Khách sạn biển cao cấp, phù hợp nghỉ dưỡng sang." }
        };

        foreach (var seed in hotelSeeds)
        {
            var destinationId = FindDestinationId(seed.Destination);
            if (!destinationId.HasValue)
            {
                continue;
            }

            var hotelExists = await context.Hotels.AnyAsync(item => item.Name == seed.Name);
            if (!hotelExists)
            {
                context.Hotels.Add(new Hotel
                {
                    DestinationId = destinationId.Value,
                    Name = seed.Name,
                    Address = seed.Address,
                    StarRating = seed.Stars,
                    Description = seed.Description,
                    IsAvailable = true
                });
            }
        }

        await context.SaveChangesAsync();

        var allHotels = await context.Hotels.ToListAsync();
        int? FindHotelId(string name) => allHotels.FirstOrDefault(item => item.Name == name)?.Id;

        var roomSeeds = new[]
        {
            ("Han River Pearl Hotel", "City View", 2, 980000m, 0.10, 10),
            ("Han River Pearl Hotel", "River View", 2, 1350000m, 0.12, 6),
            ("My Khe Coast Hotel", "Ocean View", 2, 2200000m, 0.15, 8),
            ("My Khe Coast Hotel", "Family Suite", 4, 3600000m, 0.18, 3),
            ("Hoan Kiem Heritage Hotel", "Standard", 2, 1100000m, 0.10, 12),
            ("West Lake Serenity", "Executive", 2, 2400000m, 0.15, 5),
            ("Saigon Skyline Hotel", "Superior", 2, 1250000m, 0.10, 10),
            ("Ben Thanh Luxury Stay", "Deluxe", 2, 3100000m, 0.15, 6),
            ("Thu Bon Lantern Hotel", "Balcony", 2, 1450000m, 0.12, 8),
            ("Coral Bay Premier", "Sea Front", 2, 2800000m, 0.15, 7)
        };

        foreach (var (hotelName, roomType, capacity, price, commission, qty) in roomSeeds)
        {
            var hotelId = FindHotelId(hotelName);
            if (!hotelId.HasValue)
            {
                continue;
            }

            var exists = await context.Rooms.AnyAsync(item => item.HotelId == hotelId.Value && item.RoomType == roomType);
            if (!exists)
            {
                context.Rooms.Add(new Room
                {
                    HotelId = hotelId.Value,
                    RoomType = roomType,
                    Capacity = capacity,
                    PricePerNight = price,
                    CommissionRate = commission,
                    AvailableQty = qty
                });
            }
        }

        await context.SaveChangesAsync();

        var allCompanies = await context.BusCompanies.ToListAsync();
        int ResolveCompanyId(string name) => allCompanies.FirstOrDefault(item => item.Name == name)?.Id ?? allCompanies.First().Id;
        var startDate = DateTime.UtcNow.AddDays(1).Date;
        var routes = new List<BusSchedule>();

        void AddRoute(string company, string from, string to, int departureHour, int durationHours, decimal price, int seats, int days = 30)
        {
            var fromId = FindDestinationId(from);
            var toId = FindDestinationId(to);
            if (!fromId.HasValue || !toId.HasValue)
            {
                return;
            }

            for (var i = 0; i < days; i++)
            {
                var departure = startDate.AddDays(i).AddHours(departureHour);
                routes.Add(new BusSchedule
                {
                    CompanyId = ResolveCompanyId(company),
                    FromDestId = fromId.Value,
                    ToDestId = toId.Value,
                    DepartureTime = departure,
                    ArrivalTime = departure.AddHours(durationHours),
                    Price = price,
                    CommissionRate = 0.08,
                    TotalSeats = seats
                });
            }
        }

        AddRoute("Phuong Trang FUTA", "TP. Hồ Chí Minh", "Đà Nẵng", 17, 18, 540000m, 36);
        AddRoute("Phuong Trang FUTA", "Đà Nẵng", "TP. Hồ Chí Minh", 17, 18, 540000m, 36);
        AddRoute("Thanh Buoi Express", "Hà Nội", "Hội An", 19, 18, 620000m, 34);
        AddRoute("Thanh Buoi Express", "Hội An", "Hà Nội", 19, 18, 620000m, 34);
        AddRoute("An Phu Travel", "TP. Hồ Chí Minh", "Nha Trang", 20, 8, 360000m, 40);
        AddRoute("An Phu Travel", "Nha Trang", "TP. Hồ Chí Minh", 20, 8, 360000m, 40);
        AddRoute("Hoang Long Express", "Hà Nội", "Huế", 18, 14, 560000m, 36);
        AddRoute("Hoang Long Express", "Huế", "Hà Nội", 18, 14, 560000m, 36);
        AddRoute("Viet Travel Bus", "TP. Hồ Chí Minh", "Vũng Tàu", 8, 3, 140000m, 30);
        AddRoute("Viet Travel Bus", "TP. Hồ Chí Minh", "Mũi Né", 6, 5, 220000m, 29);

        foreach (var route in routes)
        {
            var exists = await context.BusSchedules.AnyAsync(item => item.CompanyId == route.CompanyId && item.FromDestId == route.FromDestId && item.ToDestId == route.ToDestId && item.DepartureTime == route.DepartureTime);
            if (!exists)
            {
                context.BusSchedules.Add(route);
            }
        }

        await context.SaveChangesAsync();

        var tripSeeds = new[]
        {
            ("Đà Nẵng", "Da Nang Explore 4N3D", 4, 3, 6200000m, 680000m),
            ("Hà Nội", "Hanoi Heritage Weekend", 3, 2, 4200000m, 460000m),
            ("TP. Hồ Chí Minh", "Saigon City Break", 2, 1, 1800000m, 180000m),
            ("Nha Trang", "Nha Trang Beach Relax", 5, 4, 7600000m, 850000m),
            ("Hội An", "Hoi An Slow Travel", 3, 2, 3900000m, 410000m)
        };

        var demoUserId = await context.Users.Where(u => u.Email == "test@example.com").Select(u => u.Id).FirstOrDefaultAsync();
        if (demoUserId != 0)
        {
            foreach (var (destination, title, dayOffset, durationDays, amount, profit) in tripSeeds)
            {
                var destinationId = FindDestinationId(destination);
                if (!destinationId.HasValue)
                {
                    continue;
                }

                var exists = await context.Trips.AnyAsync(item => item.Title == title);
                if (!exists)
                {
                    context.Trips.Add(new Trip
                    {
                        UserId = demoUserId,
                        DestinationId = destinationId.Value,
                        Title = title,
                        StartDate = DateOnly.FromDateTime(DateTime.UtcNow.AddDays(dayOffset)),
                        EndDate = DateOnly.FromDateTime(DateTime.UtcNow.AddDays(dayOffset + durationDays)),
                        TotalAmount = amount,
                        TotalProfit = profit,
                        Status = TripStatus.Pending,
                        CreatedAt = DateTime.UtcNow.AddDays(-dayOffset)
                    });
                }
            }

            await context.SaveChangesAsync();
        }
    }

    private static async Task SeedExploreAsync(ApplicationDbContext context, int demoUserId, int adminUserId)
    {
        // Always delete and re-seed explore posts to fix stale/corrupted data
        var oldPosts = await context.ExplorePosts.ToListAsync();
        if (oldPosts.Any())
        {
            context.ExplorePosts.RemoveRange(oldPosts);
            await context.SaveChangesAsync();
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
                "bien,dao,ha-long,unesco",
                now.AddDays(-1)),
            new ExploreSeedPost(
                "Sa Pa trong sương giữa dãy Hoàng Liên Sơn",
                "Ruộng bậc thang, bản làng và khí hậu mát lạnh khiến Sa Pa luôn là điểm đến miền núi rất đáng đi.",
                "Sa Pa đẹp nhất vào mùa lúa chín và những ngày trời trong sau mưa. Hãy thử trekking bản Cát Cát, Tả Van và dậy sớm để săn mây trên đỉnh Ô Quy Hồ.",
                "https://images.unsplash.com/photo-1605640840605-14ac1855827b?w=1200",
                "Sa Pa",
                "sapa",
                "Lào Cai",
                "north",
                2,
                4.5m,
                3240,
                "nui,sapa,ban-lang,trekking",
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
                "pho-co,di-san,hoi-an,am-thuc",
                now.AddDays(-5)),
            new ExploreSeedPost(
                "Phú Quốc - hòn đảo ngọc của Việt Nam",
                "Biển xanh, cát trắng, hải sản tươi và nhiều lựa chọn nghỉ dưỡng cho mỗi lịch trình.",
                "Phú Quốc có đủ trải nghiệm từ nghỉ dưỡng ở bãi Kem, ngắm hoàng hôn Dinh Cậu đến khám phá các đảo nhỏ phía Nam. Nên thuê xe máy nếu muốn đi nhiều điểm trong ngày.",
                "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=1200",
                "Phú Quốc",
                "phu-quoc",
                "Kiên Giang",
                "south",
                3,
                4.6m,
                7650,
                "bien,dao,phu-quoc,resort",
                now.AddDays(-7)),
            new ExploreSeedPost(
                "Đà Lạt - thành phố ngàn hoa trong sương",
                "Không khí mát mẻ, đồi thông và những quán cà phê nhìn xuống thung lũng làm Đà Lạt rất dễ thương.",
                "Đà Lạt hợp cho chuyến đi chậm: sáng uống cà phê, trưa ghé vườn dâu, chiều ngắm hoàng hôn đồi Đa Phú. Buổi tối nhớ thử bánh căn và sữa đậu nành nóng.",
                "https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=1200",
                "Đà Lạt",
                "da-lat",
                "Lâm Đồng",
                "south",
                2,
                4.4m,
                4320,
                "da-lat,nui,ca-phe,lam-dong",
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
                "hue,co-do,di-san,am-thuc",
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
                "ninh-binh,trang-an,nui,tiet-kiem",
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
                "da-nang,bien,thanh-pho,son-tra",
                now.AddDays(-8))
        };

        foreach (var seed in posts)
        {
            var galleryUrls = GetExploreGalleryUrls(seed.CitySlug, seed.ImageUrl);
            var (latitude, longitude) = GetExploreCoordinates(seed.CitySlug);
            var post = new ExplorePost
            {
                AuthorId = seed.CreatedAt.Day % 2 == 0 ? demoUserId : adminUserId,
                Title = seed.Title,
                Excerpt = seed.Excerpt,
                Content = $"{seed.Content}\n\n{string.Join("\n", galleryUrls.Select(url => $"[image:{url}]"))}",
                ThumbnailUrl = galleryUrls[0],
                Location = seed.Location,
                CitySlug = seed.CitySlug,
                Province = seed.Province,
                Region = seed.Region,
                Latitude = latitude,
                Longitude = longitude,
                CostLevel = seed.CostLevel,
                AverageRating = seed.Rating,
                RatingCount = 2,
                ViewCount = seed.ViewCount,
                Tags = seed.Tags,
                CreatedAt = seed.CreatedAt
            };

            for (var imageIndex = 0; imageIndex < galleryUrls.Length; imageIndex++)
            {
                post.Images.Add(new ExplorePostImage
                {
                    ImageUrl = galleryUrls[imageIndex],
                    SortOrder = imageIndex
                });
            }

            context.ExplorePosts.Add(post);
        }

        await context.SaveChangesAsync();

        var savedPosts = await context.ExplorePosts.OrderBy(post => post.Id).ToListAsync();
        foreach (var post in savedPosts)
        {
            context.ExplorePostRatings.AddRange(
                new ExplorePostRating { ExplorePostId = post.Id, UserId = demoUserId, Rating = post.AverageRating, CreatedAt = post.CreatedAt.AddHours(2) },
                new ExplorePostRating { ExplorePostId = post.Id, UserId = adminUserId, Rating = post.AverageRating, CreatedAt = post.CreatedAt.AddHours(3) });

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

    private static string[] GetExploreGalleryUrls(string citySlug, string primaryImageUrl)
    {
        return citySlug switch
        {
            "ha-long" => new[]
            {
                primaryImageUrl,
                "https://images.unsplash.com/photo-1573270689103-d7a4e42b609c?auto=format&fit=crop&w=1200&q=80",
                "https://images.unsplash.com/photo-1528127269322-539801943592?auto=format&fit=crop&w=1200&q=80"
            },
            "sapa" => new[]
            {
                primaryImageUrl,
                "https://images.unsplash.com/photo-1521295121783-8a321d551ad2?auto=format&fit=crop&w=1200&q=80",
                "https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?auto=format&fit=crop&w=1200&q=80"
            },
            "hoi-an" => new[]
            {
                primaryImageUrl,
                "https://images.unsplash.com/photo-1522542550221-31fd19575a2d?auto=format&fit=crop&w=1200&q=80",
                "https://images.unsplash.com/photo-1516483638261-f4dbaf036963?auto=format&fit=crop&w=1200&q=80"
            },
            "phu-quoc" => new[]
            {
                primaryImageUrl,
                "https://images.unsplash.com/photo-1500375592092-40eb2168fd21?auto=format&fit=crop&w=1200&q=80",
                "https://images.unsplash.com/photo-1519046904884-53103b34b206?auto=format&fit=crop&w=1200&q=80"
            },
            "ninh-binh" => new[]
            {
                primaryImageUrl,
                "https://images.unsplash.com/photo-1500534314209-a25ddb2bd429?auto=format&fit=crop&w=1200&q=80",
                "https://images.unsplash.com/photo-1512453979798-5ea266f8880c?auto=format&fit=crop&w=1200&q=80"
            },
            "da-nang" => new[]
            {
                primaryImageUrl,
                "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=1200&q=80",
                "https://images.unsplash.com/photo-1493558103817-58b2924bce98?auto=format&fit=crop&w=1200&q=80"
            },
            "ha-giang" => new[]
            {
                primaryImageUrl,
                "https://images.unsplash.com/photo-1500534623283-312aade485b7?auto=format&fit=crop&w=1200&q=80",
                "https://images.unsplash.com/photo-1469474968028-56623f02e42e?auto=format&fit=crop&w=1200&q=80"
            },
            "quy-nhon" => new[]
            {
                primaryImageUrl,
                "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=1200&q=80",
                "https://images.unsplash.com/photo-1518509562904-e7ef99cdcc86?auto=format&fit=crop&w=1200&q=80"
            },
            _ => new[] { primaryImageUrl }
        };
    }

    private static (double? Latitude, double? Longitude) GetExploreCoordinates(string citySlug)
    {
        return citySlug switch
        {
            "ha-long" => (20.9101, 107.1839),
            "sapa" => (22.3364, 103.8438),
            "hoi-an" => (15.8801, 108.3380),
            "phu-quoc" => (10.2899, 103.9840),
            "ninh-binh" => (20.2506, 105.9745),
            "da-nang" => (16.0544, 108.2022),
            "ha-giang" => (22.8233, 104.9836),
            "quy-nhon" => (13.7820, 109.2197),
            _ => (null, null)
        };
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



