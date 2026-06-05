USE [SkynetSmartTrip];
GO

SET NOCOUNT ON;
GO

BEGIN TRANSACTION;
GO

/* =========================
   1. DESTINATIONS
   ========================= */
IF NOT EXISTS (SELECT 1 FROM Destinations)
BEGIN
    INSERT INTO Destinations (Name, Description, CoverImageUrl, IsHot)
    VALUES
        (N'Đà Lạt', N'Thành phố sương mù với khí hậu mát mẻ, đồi thông, hồ nước và nhiều quán cà phê đẹp.', 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=1200&q=80', 1),
        (N'Phú Quốc', N'Đảo ngọc nổi tiếng với biển xanh, resort cao cấp, chợ đêm và các tour cano khám phá đảo.', 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=1200&q=80', 1),
        (N'Đà Nẵng', N'Thành phố biển hiện đại, thuận tiện kết hợp Hội An, Bà Nà Hills và bán đảo Sơn Trà.', 'https://images.unsplash.com/photo-1493558103817-58b2924bce98?auto=format&fit=crop&w=1200&q=80', 1),
        (N'Nha Trang', N'Điểm đến biển sôi động với nhiều hoạt động lặn biển, vui chơi trên đảo và ẩm thực hải sản.', 'https://images.unsplash.com/photo-1584347718919-6d60a16d80ff?auto=format&fit=crop&w=1200&q=80', 1),
        (N'Hạ Long', N'Kỳ quan thiên nhiên thế giới với vịnh biển, du thuyền, hang động và view biển đẹp.', 'https://images.unsplash.com/photo-1559811814-e2c59a5ebcc2?auto=format&fit=crop&w=1200&q=80', 1),
        (N'Hà Nội', N'Thủ đô với phố cổ, hồ Hoàn Kiếm, nhiều bảo tàng, quán cà phê và trải nghiệm ẩm thực đặc trưng.', 'https://images.unsplash.com/photo-1509030450996-dd1a26dda07a?auto=format&fit=crop&w=1200&q=80', 1),
        (N'TP. Hồ Chí Minh', N'Thành phố năng động với nhịp sống sôi động, nhiều lựa chọn ẩm thực và vui chơi về đêm.', 'https://images.unsplash.com/photo-1528127269322-539801943592?auto=format&fit=crop&w=1200&q=80', 1),
        (N'Phú Quý', N'Hòn đảo yên bình của Bình Thuận với biển trong, hải sản tươi và nhịp sống thư thái.', 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=1200&q=80', 1),
        (N'Hội An', N'Phố cổ lãng mạn với đèn lồng, nhà cổ, cà phê ven sông và nhiều hoạt động chụp ảnh đẹp.', 'https://images.unsplash.com/photo-1559592413-7cec4d0cae2b?auto=format&fit=crop&w=1200&q=80', 1),
        (N'Huế', N'Cố đô với đại nội, lăng tẩm, chùa Thiên Mụ và nền ẩm thực cung đình đặc sắc.', 'https://images.unsplash.com/photo-1518509562904-e7ef99cdcc86?auto=format&fit=crop&w=1200&q=80', 0);
END
GO

/* =========================
   2. USERS + WALLETS
   ========================= */
IF NOT EXISTS (SELECT 1 FROM Users WHERE Email = 'admin@smarttrip.vn')
BEGIN
    INSERT INTO Users
    (
        Email,
        PasswordHash,
        FullName,
        Phone,
        AvatarUrl,
        AuthProvider,
        SocialId,
        Role,
        IsActive,
        CreatedAt,
        EmailVerificationToken,
        EmailVerificationTokenExpiry,
        IsEmailVerified,
        LastLoginAt,
        PasswordResetToken,
        PasswordResetTokenExpiry,
        RefreshToken,
        RefreshTokenExpiry
    )
    VALUES
        ('admin@smarttrip.vn', '$2a$11$pLsa4uzSIjxkt1ZngspHIOVGFpV4x5vvhqIurh/FAkifzFFZ549s2', N'SmartTrip Admin', '0987654321', 'https://i.pravatar.cc/150?u=smarttrip-admin', N'Local', NULL, N'Admin', 1, GETDATE(), NULL, NULL, 1, GETDATE(), NULL, NULL, NULL, NULL),
        ('test@example.com', '$2a$11$pLsa4uzSIjxkt1ZngspHIOVGFpV4x5vvhqIurh/FAkifzFFZ549s2', N'Nguyễn Văn Test', '0123456789', 'https://i.pravatar.cc/150?u=smarttrip-demo', N'Local', NULL, N'User', 1, GETDATE(), NULL, NULL, 1, GETDATE(), NULL, NULL, NULL, NULL),
        ('traveler01@smarttrip.vn', NULL, N'Trần Minh Anh', '0903123456', 'https://i.pravatar.cc/150?u=traveler01', N'Google', 'google-traveler-01', N'User', 1, GETDATE(), NULL, NULL, 1, GETDATE(), NULL, NULL, NULL, NULL);
END
GO

IF NOT EXISTS (SELECT 1 FROM UserWallets)
BEGIN
    INSERT INTO UserWallets (UserId, Balance, LoyaltyPoints)
    SELECT Id, Balance, LoyaltyPoints
    FROM
    (
        SELECT u.Id, CAST(3000000.00 AS decimal(18,2)) AS Balance, 1200 AS LoyaltyPoints
        FROM Users u WHERE u.Email = 'admin@smarttrip.vn'
        UNION ALL
        SELECT u.Id, CAST(1500000.00 AS decimal(18,2)), 620
        FROM Users u WHERE u.Email = 'test@example.com'
        UNION ALL
        SELECT u.Id, CAST(2200000.00 AS decimal(18,2)), 410
        FROM Users u WHERE u.Email = 'traveler01@smarttrip.vn'
    ) src;
END
GO

/* =========================
   3. AMENITIES
   ========================= */
IF NOT EXISTS (SELECT 1 FROM Amenities)
BEGIN
    INSERT INTO Amenities (Name, IconUrl)
    VALUES
        (N'Hồ bơi', 'pool'),
        (N'WiFi miễn phí', 'wifi'),
        (N'Điều hòa', 'ac_unit'),
        (N'Bãi đỗ xe', 'local_parking'),
        (N'Nhà hàng', 'restaurant'),
        (N'Phòng gym', 'fitness_center'),
        (N'Spa', 'spa'),
        (N'Bar', 'local_bar'),
        (N'Dịch vụ phòng 24/7', 'room_service'),
        (N'Đón tiễn sân bay', 'airport_shuttle'),
        (N'Bữa sáng', 'free_breakfast'),
        (N'View biển', 'beach_access');
END
GO

/* =========================
   4. BUS COMPANIES + PROMOTIONS
   ========================= */
IF NOT EXISTS (SELECT 1 FROM BusCompanies)
BEGIN
    INSERT INTO BusCompanies (Name, Hotline, LogoUrl)
    VALUES
        (N'Skynet Express', '19001001', 'https://images.unsplash.com/photo-1517142089942-ba376ce32a2e?auto=format&fit=crop&w=800&q=80'),
        (N'Viet Travel Bus', '19001002', 'https://images.unsplash.com/photo-1544620347-c4fd4a3d5957?auto=format&fit=crop&w=800&q=80'),
        (N'Phuong Trang FUTA', '19006067', 'https://images.unsplash.com/photo-1517142089942-ba376ce32a2e?auto=format&fit=crop&w=800&q=80'),
        (N'Thành Bưởi Express', '19006079', 'https://images.unsplash.com/photo-1544620347-c4fd4a3d5957?auto=format&fit=crop&w=800&q=80');
END
GO

IF NOT EXISTS (SELECT 1 FROM Promotions)
BEGIN
    INSERT INTO Promotions (Code, DiscountPercent, MaxDiscountAmount, ValidUntil, UsageLimit, UsedCount)
    VALUES
        ('WELCOME10', 10, 100000.00, DATEADD(DAY, 60, GETDATE()), 100, 5),
        ('SUMMER20', 20, 250000.00, DATEADD(DAY, 45, GETDATE()), 50, 12),
        ('HOTEL5', 5, 50000.00, DATEADD(DAY, 30, GETDATE()), 200, 40);
END
GO

/* =========================
   5. HOTELS
   ========================= */
IF NOT EXISTS (SELECT 1 FROM Hotels)
BEGIN
    INSERT INTO Hotels (DestinationId, Name, Address, StarRating, Description, IsAvailable)
    VALUES
        ((SELECT Id FROM Destinations WHERE Name = N'Đà Lạt'), N'Pine Valley Hotel', N'12 Hồ Xuân Hương, Phường 3, Đà Lạt', 4, N'Khách sạn trung tâm phù hợp cặp đôi và nhóm bạn, gần hồ Xuân Hương và chợ Đà Lạt.', 1),
        ((SELECT Id FROM Destinations WHERE Name = N'Đà Lạt'), N'Terracotta Hotel & Resort Đà Lạt', N'Phân khu 7.9, Hồ Tuyền Lâm, Đà Lạt', 4, N'Khu nghỉ dưỡng yên tĩnh cạnh hồ Tuyền Lâm, hợp khách gia đình và khách thích nghỉ dưỡng.', 1),
        ((SELECT Id FROM Destinations WHERE Name = N'Phú Quốc'), N'Ocean Pearl Resort', N'99 Trần Hưng Đạo, Dương Đông, Phú Quốc', 5, N'Resort ven biển với hồ bơi lớn, bãi biển riêng và dịch vụ cao cấp.', 1),
        ((SELECT Id FROM Destinations WHERE Name = N'Phú Quốc'), N'Vinpearl Resort & Spa Phú Quốc', N'Bãi Dài, Gành Dầu, Phú Quốc', 5, N'Khu nghỉ dưỡng tiêu chuẩn cao gần VinWonders và Safari, phù hợp gia đình.', 1),
        ((SELECT Id FROM Destinations WHERE Name = N'Đà Nẵng'), N'Dragon Bridge Stay', N'45 Bạch Đằng, Hải Châu, Đà Nẵng', 4, N'Khách sạn ven sông Hàn, thuận tiện xem cầu Rồng và di chuyển ra biển Mỹ Khê.', 1),
        ((SELECT Id FROM Destinations WHERE Name = N'Đà Nẵng'), N'Sea Light Da Nang Hotel', N'12 Võ Nguyên Giáp, Sơn Trà, Đà Nẵng', 4, N'Khách sạn gần biển Mỹ Khê, phù hợp khách đi nghỉ hè và khách gia đình.', 1),
        ((SELECT Id FROM Destinations WHERE Name = N'Hội An'), N'Lantern Riverside Hotel', N'21 Bạch Đằng, Hội An, Quảng Nam', 4, N'Khách sạn sát sông, tiện dạo phố cổ và khám phá chợ đêm Hội An.', 1),
        ((SELECT Id FROM Destinations WHERE Name = N'Huế'), N'Imperial Garden Hue', N'09 Lê Lợi, TP. Huế', 4, N'Khách sạn phong cách cổ điển, phù hợp cho hành trình khám phá cố đô.', 1),
        ((SELECT Id FROM Destinations WHERE Name = N'Hà Nội'), N'Old Quarter Garden Hotel', N'18 Hàng Bạc, Hoàn Kiếm, Hà Nội', 4, N'Khách sạn ấm cúng tại phố cổ, thuận tiện đi bộ hồ Hoàn Kiếm và phố đi bộ.', 1),
        ((SELECT Id FROM Destinations WHERE Name = N'TP. Hồ Chí Minh'), N'Saigon Central Stay', N'92 Nguyễn Huệ, Quận 1, TP. Hồ Chí Minh', 4, N'Khách sạn trung tâm cho khách công tác và khách du lịch tự túc.', 1),
        ((SELECT Id FROM Destinations WHERE Name = N'Phú Quý'), N'Phu Quy Sea View', N'Lô 5 Tam Thanh, Phú Quý, Bình Thuận', 3, N'Khách sạn nhỏ gần biển, phù hợp nhóm bạn đi khám phá đảo.', 1),
        ((SELECT Id FROM Destinations WHERE Name = N'Nha Trang'), N'Coral Bay Nha Trang Hotel', N'22 Trần Phú, Nha Trang', 4, N'Khách sạn gần biển, thuận tiện đi tour đảo và tắm biển buổi sáng.', 1),
        ((SELECT Id FROM Destinations WHERE Name = N'Hạ Long'), N'Ha Long Harbor View Hotel', N'01 Hạ Long, Bãi Cháy, Hạ Long', 4, N'Khách sạn view vịnh, tiện di chuyển ra cảng và khu vui chơi Sun World.', 1);
END
GO

/* =========================
   6. HOTEL AMENITIES
   ========================= */
IF NOT EXISTS (SELECT 1 FROM HotelAmenityMapping)
BEGIN
    INSERT INTO HotelAmenityMapping (HotelId, AmenityId)
    SELECT h.Id, a.Id
    FROM Hotels h
    CROSS JOIN Amenities a
    WHERE
        (
            h.Name IN (N'Ocean Pearl Resort', N'Vinpearl Resort & Spa Phú Quốc')
            AND a.Name IN (N'Hồ bơi', N'WiFi miễn phí', N'Nhà hàng', N'Spa', N'Bar', N'Bữa sáng', N'View biển', N'Đón tiễn sân bay')
        )
        OR
        (
            h.Name IN (N'Sea Light Da Nang Hotel', N'Dragon Bridge Stay', N'Coral Bay Nha Trang Hotel', N'Ha Long Harbor View Hotel')
            AND a.Name IN (N'WiFi miễn phí', N'Điều hòa', N'Nhà hàng', N'Bãi đỗ xe', N'Bữa sáng')
        )
        OR
        (
            h.Name IN (N'Pine Valley Hotel', N'Terracotta Hotel & Resort Đà Lạt', N'Old Quarter Garden Hotel', N'Lantern Riverside Hotel', N'Imperial Garden Hue', N'Saigon Central Stay', N'Phu Quy Sea View')
            AND a.Name IN (N'WiFi miễn phí', N'Điều hòa', N'Nhà hàng', N'Bữa sáng')
        );
END
GO

/* =========================
   7. ROOMS
   ========================= */
IF NOT EXISTS (SELECT 1 FROM Rooms)
BEGIN
    INSERT INTO Rooms (HotelId, RoomType, Capacity, PricePerNight, CommissionRate, AvailableQty)
    VALUES
        ((SELECT Id FROM Hotels WHERE Name = N'Pine Valley Hotel'), N'Phòng Standard', 2, 850000.00, 0.10, 8),
        ((SELECT Id FROM Hotels WHERE Name = N'Pine Valley Hotel'), N'Phòng Deluxe View Hồ', 2, 1250000.00, 0.12, 6),
        ((SELECT Id FROM Hotels WHERE Name = N'Terracotta Hotel & Resort Đà Lạt'), N'Phòng Superior', 2, 1100000.00, 0.10, 10),
        ((SELECT Id FROM Hotels WHERE Name = N'Terracotta Hotel & Resort Đà Lạt'), N'Suite Gia Đình', 4, 2100000.00, 0.14, 4),
        ((SELECT Id FROM Hotels WHERE Name = N'Ocean Pearl Resort'), N'Phòng Deluxe Biển', 2, 2450000.00, 0.12, 10),
        ((SELECT Id FROM Hotels WHERE Name = N'Ocean Pearl Resort'), N'Pool Access Villa', 2, 4200000.00, 0.15, 5),
        ((SELECT Id FROM Hotels WHERE Name = N'Vinpearl Resort & Spa Phú Quốc'), N'Phòng Standard', 2, 3500000.00, 0.15, 12),
        ((SELECT Id FROM Hotels WHERE Name = N'Vinpearl Resort & Spa Phú Quốc'), N'Villa 2 Phòng Ngủ', 4, 7200000.00, 0.18, 3),
        ((SELECT Id FROM Hotels WHERE Name = N'Dragon Bridge Stay'), N'Phòng City View', 2, 980000.00, 0.10, 10),
        ((SELECT Id FROM Hotels WHERE Name = N'Dragon Bridge Stay'), N'Phòng River View', 2, 1480000.00, 0.12, 6),
        ((SELECT Id FROM Hotels WHERE Name = N'Sea Light Da Nang Hotel'), N'Deluxe Double', 2, 850000.00, 0.12, 12),
        ((SELECT Id FROM Hotels WHERE Name = N'Sea Light Da Nang Hotel'), N'Family Suite', 4, 1450000.00, 0.12, 5),
        ((SELECT Id FROM Hotels WHERE Name = N'Lantern Riverside Hotel'), N'Phòng Deluxe', 2, 1100000.00, 0.10, 7),
        ((SELECT Id FROM Hotels WHERE Name = N'Lantern Riverside Hotel'), N'Phòng Balcony', 3, 1450000.00, 0.12, 4),
        ((SELECT Id FROM Hotels WHERE Name = N'Imperial Garden Hue'), N'Deluxe King', 2, 980000.00, 0.11, 10),
        ((SELECT Id FROM Hotels WHERE Name = N'Old Quarter Garden Hotel'), N'Phòng Standard', 2, 920000.00, 0.10, 8),
        ((SELECT Id FROM Hotels WHERE Name = N'Old Quarter Garden Hotel'), N'Phòng Family', 4, 1650000.00, 0.12, 4),
        ((SELECT Id FROM Hotels WHERE Name = N'Saigon Central Stay'), N'Phòng City View', 2, 980000.00, 0.10, 10),
        ((SELECT Id FROM Hotels WHERE Name = N'Saigon Central Stay'), N'Suite Gia Đình', 4, 1850000.00, 0.12, 4),
        ((SELECT Id FROM Hotels WHERE Name = N'Phu Quy Sea View'), N'Phòng Tiêu Chuẩn', 2, 650000.00, 0.08, 6),
        ((SELECT Id FROM Hotels WHERE Name = N'Phu Quy Sea View'), N'Phòng Nhìn Biển', 4, 1200000.00, 0.10, 3),
        ((SELECT Id FROM Hotels WHERE Name = N'Coral Bay Nha Trang Hotel'), N'Phòng Superior', 2, 960000.00, 0.10, 10),
        ((SELECT Id FROM Hotels WHERE Name = N'Coral Bay Nha Trang Hotel'), N'Family Ocean View', 4, 1750000.00, 0.12, 4),
        ((SELECT Id FROM Hotels WHERE Name = N'Ha Long Harbor View Hotel'), N'Phòng Standard', 2, 1150000.00, 0.10, 9),
        ((SELECT Id FROM Hotels WHERE Name = N'Ha Long Harbor View Hotel'), N'Phòng View Vịnh', 2, 1680000.00, 0.12, 5);
END
GO

/* =========================
   8. BUS SCHEDULES
   ========================= */
IF NOT EXISTS (SELECT 1 FROM BusSchedules)
BEGIN
    DECLARE @RouteSeed TABLE
    (
        CompanyName nvarchar(100),
        FromName nvarchar(100),
        ToName nvarchar(100),
        DepartureHour int,
        DurationHours int,
        Price decimal(18,2),
        TotalSeats int,
        TotalDays int
    );

    INSERT INTO @RouteSeed (CompanyName, FromName, ToName, DepartureHour, DurationHours, Price, TotalSeats, TotalDays)
    VALUES
        (N'Phuong Trang FUTA', N'TP. Hồ Chí Minh', N'Đà Lạt', 22, 7, 320000.00, 36, 12),
        (N'Thành Bưởi Express', N'TP. Hồ Chí Minh', N'Đà Lạt', 23, 7, 340000.00, 34, 12),
        (N'Phuong Trang FUTA', N'Đà Lạt', N'TP. Hồ Chí Minh', 22, 7, 320000.00, 36, 12),
        (N'Thành Bưởi Express', N'Đà Lạt', N'TP. Hồ Chí Minh', 23, 7, 340000.00, 34, 12),
        (N'Phuong Trang FUTA', N'TP. Hồ Chí Minh', N'Nha Trang', 21, 8, 360000.00, 40, 12),
        (N'Phuong Trang FUTA', N'Nha Trang', N'TP. Hồ Chí Minh', 21, 8, 360000.00, 40, 12),
        (N'Skynet Express', N'Đà Nẵng', N'Hội An', 8, 1, 180000.00, 20, 12),
        (N'Viet Travel Bus', N'Đà Nẵng', N'Hội An', 15, 1, 150000.00, 24, 12),
        (N'Skynet Express', N'Hội An', N'Đà Nẵng', 9, 1, 180000.00, 20, 12),
        (N'Viet Travel Bus', N'Hội An', N'Đà Nẵng', 16, 1, 150000.00, 24, 12),
        (N'Phuong Trang FUTA', N'Hà Nội', N'Hạ Long', 7, 3, 220000.00, 29, 12),
        (N'Phuong Trang FUTA', N'Hạ Long', N'Hà Nội', 15, 3, 220000.00, 29, 12),
        (N'Phuong Trang FUTA', N'TP. Hồ Chí Minh', N'Hà Nội', 18, 32, 950000.00, 36, 8),
        (N'Phuong Trang FUTA', N'Hà Nội', N'TP. Hồ Chí Minh', 17, 32, 950000.00, 36, 8),
        (N'Viet Travel Bus', N'Đà Nẵng', N'Huế', 8, 3, 260000.00, 24, 10),
        (N'Viet Travel Bus', N'Huế', N'Đà Nẵng', 14, 3, 260000.00, 24, 10),
        (N'Skynet Express', N'TP. Hồ Chí Minh', N'Phú Quý', 20, 8, 450000.00, 28, 8);

    ;WITH DayOffsets AS
    (
        SELECT 0 AS DayOffset
        UNION ALL
        SELECT DayOffset + 1
        FROM DayOffsets
        WHERE DayOffset + 1 < 12
    )
    INSERT INTO BusSchedules (CompanyId, FromDestId, ToDestId, DepartureTime, ArrivalTime, Price, CommissionRate, TotalSeats)
    SELECT
        bc.Id,
        fd.Id,
        td.Id,
        DATEADD(HOUR, r.DepartureHour, CAST(DATEADD(DAY, d.DayOffset + 2, CAST(GETDATE() AS date)) AS datetime)),
        DATEADD(HOUR, r.DepartureHour + r.DurationHours, CAST(DATEADD(DAY, d.DayOffset + 2, CAST(GETDATE() AS date)) AS datetime)),
        r.Price,
        0.08,
        r.TotalSeats
    FROM @RouteSeed r
    INNER JOIN BusCompanies bc ON bc.Name = r.CompanyName
    INNER JOIN Destinations fd ON fd.Name = r.FromName
    INNER JOIN Destinations td ON td.Name = r.ToName
    INNER JOIN DayOffsets d ON d.DayOffset < r.TotalDays
    OPTION (MAXRECURSION 100);
END
GO

/* =========================
   9. SEATS
   ========================= */
IF NOT EXISTS (SELECT 1 FROM Seats)
BEGIN
    ;WITH Numbers AS
    (
        SELECT 1 AS SeatNo
        UNION ALL
        SELECT SeatNo + 1
        FROM Numbers
        WHERE SeatNo < 40
    )
    INSERT INTO Seats (ScheduleId, SeatNumber, Status)
    SELECT
        s.Id,
        CONCAT('S', RIGHT(CONCAT('00', n.SeatNo), 2)),
        N'Available'
    FROM BusSchedules s
    INNER JOIN Numbers n ON n.SeatNo <= ISNULL(s.TotalSeats, 30)
    OPTION (MAXRECURSION 100);

    UPDATE TOP (3) Seats
    SET Status = N'Booked'
    WHERE ScheduleId = (SELECT TOP 1 Id FROM BusSchedules ORDER BY DepartureTime)
      AND SeatNumber IN ('S01', 'S02', 'S03');

    UPDATE TOP (2) Seats
    SET Status = N'Locked',
        LockedUntil = DATEADD(MINUTE, 15, GETDATE())
    WHERE ScheduleId = (SELECT TOP 1 Id FROM BusSchedules ORDER BY DepartureTime)
      AND SeatNumber IN ('S04', 'S05');
END
GO

/* =========================
   10. TRIPS + ITINERARIES
   ========================= */
IF NOT EXISTS (SELECT 1 FROM Trips)
BEGIN
    INSERT INTO Trips (UserId, DestinationId, Title, StartDate, EndDate, TotalAmount, TotalProfit, Status, CreatedAt)
    VALUES
        ((SELECT Id FROM Users WHERE Email = 'test@example.com'), (SELECT Id FROM Destinations WHERE Name = N'Đà Lạt'), N'Đà Lạt cuối tuần 3N2Đ', CAST(DATEADD(DAY, 7, GETDATE()) AS date), CAST(DATEADD(DAY, 10, GETDATE()) AS date), 3200000.00, 350000.00, N'Paid', DATEADD(DAY, -10, GETDATE())),
        ((SELECT Id FROM Users WHERE Email = 'test@example.com'), (SELECT Id FROM Destinations WHERE Name = N'Phú Quốc'), N'Phú Quốc nghỉ dưỡng 4N3Đ', CAST(DATEADD(DAY, 20, GETDATE()) AS date), CAST(DATEADD(DAY, 24, GETDATE()) AS date), 7800000.00, 900000.00, N'Pending', DATEADD(DAY, -5, GETDATE())),
        ((SELECT Id FROM Users WHERE Email = 'traveler01@smarttrip.vn'), (SELECT Id FROM Destinations WHERE Name = N'Đà Nẵng'), N'Đà Nẵng - Hội An 3N2Đ', CAST(DATEADD(DAY, 12, GETDATE()) AS date), CAST(DATEADD(DAY, 15, GETDATE()) AS date), 4100000.00, 480000.00, N'Paid', DATEADD(DAY, -3, GETDATE()));
END
GO

IF NOT EXISTS (SELECT 1 FROM TripItineraries)
BEGIN
    INSERT INTO TripItineraries
    (
        TripId,
        DayNumber,
        ServiceType,
        ServiceId,
        Quantity,
        BookedPrice,
        BookedCommissionRate,
        ServiceDate,
        DepartureTime,
        ServiceAddress,
        SelectedSeats
    )
    VALUES
        (
            (SELECT Id FROM Trips WHERE Title = N'Đà Lạt cuối tuần 3N2Đ'),
            1,
            1,
            (SELECT TOP 1 Id FROM Rooms WHERE HotelId = (SELECT Id FROM Hotels WHERE Name = N'Pine Valley Hotel') AND RoomType = N'Phòng Deluxe View Hồ'),
            1,
            2500000.00,
            0.12,
            CAST(DATEADD(DAY, 7, GETDATE()) AS date),
            NULL,
            N'12 Hồ Xuân Hương, Phường 3, Đà Lạt',
            NULL
        ),
        (
            (SELECT Id FROM Trips WHERE Title = N'Đà Lạt cuối tuần 3N2Đ'),
            1,
            2,
            (SELECT TOP 1 Id FROM BusSchedules WHERE FromDestId = (SELECT Id FROM Destinations WHERE Name = N'TP. Hồ Chí Minh') AND ToDestId = (SELECT Id FROM Destinations WHERE Name = N'Đà Lạt') ORDER BY DepartureTime),
            2,
            640000.00,
            0.08,
            CAST(DATEADD(DAY, 7, GETDATE()) AS date),
            '22:00',
            N'Bến xe Miền Đông',
            N'S01,S02'
        ),
        (
            (SELECT Id FROM Trips WHERE Title = N'Phú Quốc nghỉ dưỡng 4N3Đ'),
            1,
            1,
            (SELECT TOP 1 Id FROM Rooms WHERE HotelId = (SELECT Id FROM Hotels WHERE Name = N'Ocean Pearl Resort') AND RoomType = N'Phòng Deluxe Biển'),
            1,
            7350000.00,
            0.12,
            CAST(DATEADD(DAY, 20, GETDATE()) AS date),
            NULL,
            N'99 Trần Hưng Đạo, Dương Đông, Phú Quốc',
            NULL
        ),
        (
            (SELECT Id FROM Trips WHERE Title = N'Đà Nẵng - Hội An 3N2Đ'),
            1,
            1,
            (SELECT TOP 1 Id FROM Rooms WHERE HotelId = (SELECT Id FROM Hotels WHERE Name = N'Sea Light Da Nang Hotel') AND RoomType = N'Deluxe Double'),
            1,
            1700000.00,
            0.12,
            CAST(DATEADD(DAY, 12, GETDATE()) AS date),
            NULL,
            N'12 Võ Nguyên Giáp, Sơn Trà, Đà Nẵng',
            NULL
        ),
        (
            (SELECT Id FROM Trips WHERE Title = N'Đà Nẵng - Hội An 3N2Đ'),
            2,
            2,
            (SELECT TOP 1 Id FROM BusSchedules WHERE FromDestId = (SELECT Id FROM Destinations WHERE Name = N'Đà Nẵng') AND ToDestId = (SELECT Id FROM Destinations WHERE Name = N'Hội An') ORDER BY DepartureTime),
            2,
            360000.00,
            0.08,
            CAST(DATEADD(DAY, 13, GETDATE()) AS date),
            '08:00',
            N'Trung tâm Đà Nẵng',
            N'S01,S02'
        );
END
GO

/* =========================
   11. PAYMENTS + INVOICES
   ========================= */
IF NOT EXISTS (SELECT 1 FROM Payments)
BEGIN
    INSERT INTO Payments
    (
        TripId,
        PaymentMethod,
        TransactionId,
        Amount,
        Status,
        PaidAt,
        OrderCode,
        Description,
        CheckoutUrl,
        CreatedAt,
        UpdatedAt
    )
    VALUES
        ((SELECT Id FROM Trips WHERE Title = N'Đà Lạt cuối tuần 3N2Đ'), 1, 'TXN-DALAT-0001', 3200000.00, 2, GETDATE(), 202606050001, N'Thanh toán chuyến Đà Lạt', NULL, GETDATE(), GETDATE()),
        ((SELECT Id FROM Trips WHERE Title = N'Phú Quốc nghỉ dưỡng 4N3Đ'), 2, 'TXN-PQ-0001', 3900000.00, 1, NULL, 202606050002, N'Thanh toán cọc chuyến Phú Quốc', NULL, GETDATE(), GETDATE()),
        ((SELECT Id FROM Trips WHERE Title = N'Đà Nẵng - Hội An 3N2Đ'), 4, 'TXN-DNHA-0001', 4100000.00, 2, GETDATE(), 202606050003, N'Thanh toán chuyến Đà Nẵng - Hội An', 'https://pay.example.com/mock/202606050003', GETDATE(), GETDATE());
END
GO

IF NOT EXISTS (SELECT 1 FROM Invoices)
BEGIN
    INSERT INTO Invoices (TripId, InvoiceNumber, TaxAmount, PdfUrl, IssuedAt)
    VALUES
        ((SELECT Id FROM Trips WHERE Title = N'Đà Lạt cuối tuần 3N2Đ'), 'INV-2026-0001', 280000.00, 'https://files.example.com/invoices/inv-2026-0001.pdf', GETDATE()),
        ((SELECT Id FROM Trips WHERE Title = N'Phú Quốc nghỉ dưỡng 4N3Đ'), 'INV-2026-0002', 520000.00, 'https://files.example.com/invoices/inv-2026-0002.pdf', GETDATE()),
        ((SELECT Id FROM Trips WHERE Title = N'Đà Nẵng - Hội An 3N2Đ'), 'INV-2026-0003', 310000.00, 'https://files.example.com/invoices/inv-2026-0003.pdf', GETDATE());
END
GO

/* =========================
   12. REVIEWS + WISHLISTS
   ========================= */
IF NOT EXISTS (SELECT 1 FROM Reviews)
BEGIN
    INSERT INTO Reviews (UserId, TripId, TargetType, TargetId, Rating, Comment, CreatedAt)
    VALUES
        ((SELECT Id FROM Users WHERE Email = 'test@example.com'), (SELECT Id FROM Trips WHERE Title = N'Đà Lạt cuối tuần 3N2Đ'), 1, (SELECT Id FROM Hotels WHERE Name = N'Pine Valley Hotel'), 5, N'Phòng sạch, vị trí đẹp, đi bộ ra hồ khá tiện. Nhân viên hỗ trợ nhiệt tình.', DATEADD(DAY, -8, GETDATE())),
        ((SELECT Id FROM Users WHERE Email = 'test@example.com'), (SELECT Id FROM Trips WHERE Title = N'Phú Quốc nghỉ dưỡng 4N3Đ'), 1, (SELECT Id FROM Hotels WHERE Name = N'Ocean Pearl Resort'), 5, N'Không gian đẹp, bãi biển sạch và buffet sáng khá ổn cho kỳ nghỉ dưỡng.', DATEADD(DAY, -4, GETDATE())),
        ((SELECT Id FROM Users WHERE Email = 'traveler01@smarttrip.vn'), (SELECT Id FROM Trips WHERE Title = N'Đà Nẵng - Hội An 3N2Đ'), 1, (SELECT Id FROM Hotels WHERE Name = N'Sea Light Da Nang Hotel'), 4, N'Khách sạn gần biển, giá hợp lý, phù hợp cho chuyến đi ngắn ngày.', DATEADD(DAY, -2, GETDATE())),
        ((SELECT Id FROM Users WHERE Email = 'traveler01@smarttrip.vn'), (SELECT Id FROM Trips WHERE Title = N'Đà Nẵng - Hội An 3N2Đ'), 2, (SELECT Id FROM BusCompanies WHERE Name = N'Skynet Express'), 4, N'Xe chạy đúng giờ, ghế ngồi ổn, nhân viên hỗ trợ tốt.', DATEADD(DAY, -2, GETDATE()));
END
GO

IF NOT EXISTS (SELECT 1 FROM Wishlists)
BEGIN
    INSERT INTO Wishlists (UserId, ItemType, ItemId, CreatedAt)
    VALUES
        ((SELECT Id FROM Users WHERE Email = 'test@example.com'), 1, (SELECT Id FROM Hotels WHERE Name = N'Old Quarter Garden Hotel'), GETDATE()),
        ((SELECT Id FROM Users WHERE Email = 'test@example.com'), 1, (SELECT Id FROM Hotels WHERE Name = N'Coral Bay Nha Trang Hotel'), GETDATE()),
        ((SELECT Id FROM Users WHERE Email = 'traveler01@smarttrip.vn'), 2, (SELECT TOP 1 Id FROM BusSchedules WHERE FromDestId = (SELECT Id FROM Destinations WHERE Name = N'Hà Nội') AND ToDestId = (SELECT Id FROM Destinations WHERE Name = N'Hạ Long') ORDER BY DepartureTime), GETDATE());
END
GO

/* =========================
   13. BLOGS + NOTIFICATIONS
   ========================= */
IF NOT EXISTS (SELECT 1 FROM BlogPosts)
BEGIN
    INSERT INTO BlogPosts (AuthorId, DestinationId, Title, ContentHtml, ThumbnailUrl, PublishedAt)
    VALUES
        ((SELECT Id FROM Users WHERE Email = 'admin@smarttrip.vn'), (SELECT Id FROM Destinations WHERE Name = N'Đà Lạt'), N'Lịch trình Đà Lạt 3 ngày 2 đêm cho nhóm bạn', N'<p>Gợi ý săn mây, quán cà phê đẹp, ăn uống và chi phí phù hợp cho nhóm bạn trẻ.</p>', 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=1200&q=80', GETDATE()),
        ((SELECT Id FROM Users WHERE Email = 'admin@smarttrip.vn'), (SELECT Id FROM Destinations WHERE Name = N'Đà Nẵng'), N'Ăn gì ở Đà Nẵng nếu chỉ có 2 ngày?', N'<p>Tổng hợp các món nên thử như mì Quảng, bánh tráng cuốn thịt heo, hải sản và lịch trình ngắn ngày.</p>', 'https://images.unsplash.com/photo-1493558103817-58b2924bce98?auto=format&fit=crop&w=1200&q=80', GETDATE()),
        ((SELECT Id FROM Users WHERE Email = 'admin@smarttrip.vn'), (SELECT Id FROM Destinations WHERE Name = N'Hà Nội'), N'Đi Hà Nội lần đầu nên ở đâu?', N'<p>Gợi ý khu vực phố cổ, Ba Đình, Hồ Tây và cách chọn khách sạn theo nhu cầu.</p>', 'https://images.unsplash.com/photo-1509030450996-dd1a26dda07a?auto=format&fit=crop&w=1200&q=80', GETDATE());
END
GO

IF NOT EXISTS (SELECT 1 FROM Notifications)
BEGIN
    INSERT INTO Notifications (UserId, Title, Message, IsRead, CreatedAt)
    VALUES
        ((SELECT Id FROM Users WHERE Email = 'test@example.com'), N'Đặt chỗ thành công', N'Chuyến đi Đà Lạt của bạn đã được xác nhận thành công.', 0, GETDATE()),
        ((SELECT Id FROM Users WHERE Email = 'test@example.com'), N'Khuyến mãi mùa hè', N'Mã SUMMER20 đang áp dụng cho nhiều khách sạn và tuyến xe nổi bật.', 0, GETDATE()),
        ((SELECT Id FROM Users WHERE Email = 'traveler01@smarttrip.vn'), N'Nhắc thanh toán', N'Bạn còn một khoản thanh toán chờ xử lý cho chuyến Phú Quốc.', 0, GETDATE());
END
GO

/* =========================
   14. GALLERIES
   ========================= */
IF NOT EXISTS (SELECT 1 FROM Galleries)
BEGIN
    INSERT INTO Galleries (ReferenceType, ReferenceId, ImageUrl)
    VALUES
        (3, (SELECT Id FROM Destinations WHERE Name = N'Đà Lạt'), 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=1200&q=80'),
        (3, (SELECT Id FROM Destinations WHERE Name = N'Phú Quốc'), 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=1200&q=80'),
        (3, (SELECT Id FROM Destinations WHERE Name = N'Đà Nẵng'), 'https://images.unsplash.com/photo-1493558103817-58b2924bce98?auto=format&fit=crop&w=1200&q=80'),
        (3, (SELECT Id FROM Destinations WHERE Name = N'Hà Nội'), 'https://images.unsplash.com/photo-1509030450996-dd1a26dda07a?auto=format&fit=crop&w=1200&q=80'),
        (3, (SELECT Id FROM Destinations WHERE Name = N'Hội An'), 'https://images.unsplash.com/photo-1559592413-7cec4d0cae2b?auto=format&fit=crop&w=1200&q=80'),
        (1, (SELECT Id FROM Hotels WHERE Name = N'Pine Valley Hotel'), 'https://images.unsplash.com/photo-1566073771259-6a8506099945?auto=format&fit=crop&w=1200&q=80'),
        (1, (SELECT Id FROM Hotels WHERE Name = N'Ocean Pearl Resort'), 'https://images.unsplash.com/photo-1499793983690-e29da59ef1c2?auto=format&fit=crop&w=1200&q=80'),
        (1, (SELECT Id FROM Hotels WHERE Name = N'Dragon Bridge Stay'), 'https://images.unsplash.com/photo-1551882547-ff40c63fe5fa?auto=format&fit=crop&w=1200&q=80'),
        (1, (SELECT Id FROM Hotels WHERE Name = N'Old Quarter Garden Hotel'), 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?auto=format&fit=crop&w=1200&q=80'),
        (1, (SELECT Id FROM Hotels WHERE Name = N'Phu Quy Sea View'), 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=1200&q=80'),
        (2, (SELECT Id FROM Rooms WHERE HotelId = (SELECT Id FROM Hotels WHERE Name = N'Sea Light Da Nang Hotel') AND RoomType = N'Deluxe Double'), 'https://images.unsplash.com/photo-1631049307264-da0ec9d70304?auto=format&fit=crop&w=1200&q=80'),
        (2, (SELECT Id FROM Rooms WHERE HotelId = (SELECT Id FROM Hotels WHERE Name = N'Pine Valley Hotel') AND RoomType = N'Phòng Deluxe View Hồ'), 'https://images.unsplash.com/photo-1578645510447-e20b4311e3ce?auto=format&fit=crop&w=1200&q=80');
END
GO

COMMIT TRANSACTION;
GO

PRINT N'Sample seed data inserted successfully.';
GO
