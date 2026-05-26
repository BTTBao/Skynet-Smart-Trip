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
