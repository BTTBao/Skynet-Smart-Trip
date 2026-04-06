USE [SkynetSmartTrip];
GO

SET NOCOUNT ON;
GO

BEGIN TRANSACTION;
GO

/* Destinations */
IF NOT EXISTS (SELECT 1 FROM Destinations WHERE Name = N'Da Nang')
BEGIN
    INSERT INTO Destinations (Name, Description, CoverImageUrl, IsHot)
    VALUES
        (N'Da Nang', N'Beach city with food, bridges, and easy access to nearby attractions.', 'https://images.example.com/danang.jpg', 1),
        (N'Hoi An', N'Ancient town known for lantern streets and riverside cafes.', 'https://images.example.com/hoian.jpg', 1),
        (N'Hue', N'Historic city with citadel, royal cuisine, and cultural landmarks.', 'https://images.example.com/hue.jpg', 0);
END
GO

/* Users */
IF NOT EXISTS (SELECT 1 FROM Users WHERE Email = 'admin@skynettrip.local')
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
        ('admin@skynettrip.local', NULL, N'System Admin', '0901000001', 'https://images.example.com/users/admin.jpg', N'Local', NULL, N'Admin', 1, GETDATE(), NULL, NULL, 1, GETDATE(), NULL, NULL, NULL, NULL),
        ('alice@skynettrip.local', NULL, N'Alice Nguyen', '0901000002', 'https://images.example.com/users/alice.jpg', N'Local', NULL, N'User', 1, GETDATE(), NULL, NULL, 1, GETDATE(), NULL, NULL, NULL, NULL),
        ('bob@skynettrip.local', NULL, N'Bob Tran', '0901000003', 'https://images.example.com/users/bob.jpg', N'Google', 'google-bob-001', N'User', 1, GETDATE(), NULL, NULL, 1, GETDATE(), NULL, NULL, NULL, NULL);
END
GO

/* Wallets */
IF NOT EXISTS (SELECT 1 FROM UserWallets uw INNER JOIN Users u ON u.Id = uw.UserId WHERE u.Email = 'alice@skynettrip.local')
BEGIN
    INSERT INTO UserWallets (UserId, Balance, LoyaltyPoints)
    SELECT u.Id, v.Balance, v.LoyaltyPoints
    FROM Users u
    INNER JOIN
    (
        VALUES
            ('admin@skynettrip.local', CAST(5000000.00 AS decimal(18,2)), 1000),
            ('alice@skynettrip.local', CAST(2500000.00 AS decimal(18,2)), 350),
            ('bob@skynettrip.local', CAST(1750000.00 AS decimal(18,2)), 180)
    ) v(Email, Balance, LoyaltyPoints) ON v.Email = u.Email;
END
GO

/* Amenities */
IF NOT EXISTS (SELECT 1 FROM Amenities WHERE Name = N'Free Wifi')
BEGIN
    INSERT INTO Amenities (Name, IconUrl)
    VALUES
        (N'Free Wifi', 'https://images.example.com/icons/wifi.png'),
        (N'Swimming Pool', 'https://images.example.com/icons/pool.png'),
        (N'Breakfast', 'https://images.example.com/icons/breakfast.png'),
        (N'Airport Shuttle', 'https://images.example.com/icons/shuttle.png');
END
GO

/* Bus companies */
IF NOT EXISTS (SELECT 1 FROM BusCompanies WHERE Name = N'Skynet Express')
BEGIN
    INSERT INTO BusCompanies (Name, Hotline, LogoUrl)
    VALUES
        (N'Skynet Express', '19001001', 'https://images.example.com/bus/skynet-express.png'),
        (N'Central Travel Bus', '19001002', 'https://images.example.com/bus/central-travel.png');
END
GO

/* Promotions */
IF NOT EXISTS (SELECT 1 FROM Promotions WHERE Code = 'WELCOME10')
BEGIN
    INSERT INTO Promotions (Code, DiscountPercent, MaxDiscountAmount, ValidUntil, UsageLimit, UsedCount)
    VALUES
        ('WELCOME10', 10, 300000.00, DATEADD(DAY, 60, GETDATE()), 500, 12),
        ('SUMMER15', 15, 500000.00, DATEADD(DAY, 90, GETDATE()), 300, 24);
END
GO

DECLARE @DaNangId int = (SELECT TOP 1 Id FROM Destinations WHERE Name = N'Da Nang');
DECLARE @HoiAnId int = (SELECT TOP 1 Id FROM Destinations WHERE Name = N'Hoi An');
DECLARE @HueId int = (SELECT TOP 1 Id FROM Destinations WHERE Name = N'Hue');
DECLARE @AdminId int = (SELECT TOP 1 Id FROM Users WHERE Email = 'admin@skynettrip.local');
DECLARE @AliceId int = (SELECT TOP 1 Id FROM Users WHERE Email = 'alice@skynettrip.local');
DECLARE @BobId int = (SELECT TOP 1 Id FROM Users WHERE Email = 'bob@skynettrip.local');
DECLARE @WifiId int = (SELECT TOP 1 Id FROM Amenities WHERE Name = N'Free Wifi');
DECLARE @PoolId int = (SELECT TOP 1 Id FROM Amenities WHERE Name = N'Swimming Pool');
DECLARE @BreakfastId int = (SELECT TOP 1 Id FROM Amenities WHERE Name = N'Breakfast');
DECLARE @ShuttleId int = (SELECT TOP 1 Id FROM Amenities WHERE Name = N'Airport Shuttle');
DECLARE @SkynetBusId int = (SELECT TOP 1 Id FROM BusCompanies WHERE Name = N'Skynet Express');
DECLARE @CentralBusId int = (SELECT TOP 1 Id FROM BusCompanies WHERE Name = N'Central Travel Bus');
GO

/* Hotels */
IF NOT EXISTS (SELECT 1 FROM Hotels WHERE Name = N'Sea Light Da Nang Hotel')
BEGIN
    INSERT INTO Hotels (DestinationId, Name, Address, StarRating, Description, IsAvailable)
    VALUES
        ((SELECT TOP 1 Id FROM Destinations WHERE Name = N'Da Nang'), N'Sea Light Da Nang Hotel', N'12 Vo Nguyen Giap, Da Nang', 4, N'Hotel near My Khe beach, suitable for family and couple trips.', 1),
        ((SELECT TOP 1 Id FROM Destinations WHERE Name = N'Hoi An'), N'Lantern Riverside Resort', N'85 Bach Dang, Hoi An', 4, N'Riverside stay close to the old quarter and night market.', 1),
        ((SELECT TOP 1 Id FROM Destinations WHERE Name = N'Hue'), N'Imperial Garden Hue', N'09 Le Loi, Hue', 5, N'Comfortable hotel with classic Hue style and city access.', 1);
END
GO

DECLARE @SeaLightHotelId int = (SELECT TOP 1 Id FROM Hotels WHERE Name = N'Sea Light Da Nang Hotel');
DECLARE @LanternHotelId int = (SELECT TOP 1 Id FROM Hotels WHERE Name = N'Lantern Riverside Resort');
DECLARE @ImperialHotelId int = (SELECT TOP 1 Id FROM Hotels WHERE Name = N'Imperial Garden Hue');
GO

/* Hotel amenity mapping */
IF NOT EXISTS (SELECT 1 FROM HotelAmenityMapping WHERE HotelId = (SELECT TOP 1 Id FROM Hotels WHERE Name = N'Sea Light Da Nang Hotel') AND AmenityId = (SELECT TOP 1 Id FROM Amenities WHERE Name = N'Free Wifi'))
BEGIN
    INSERT INTO HotelAmenityMapping (HotelId, AmenityId)
    VALUES
        ((SELECT TOP 1 Id FROM Hotels WHERE Name = N'Sea Light Da Nang Hotel'), (SELECT TOP 1 Id FROM Amenities WHERE Name = N'Free Wifi')),
        ((SELECT TOP 1 Id FROM Hotels WHERE Name = N'Sea Light Da Nang Hotel'), (SELECT TOP 1 Id FROM Amenities WHERE Name = N'Swimming Pool')),
        ((SELECT TOP 1 Id FROM Hotels WHERE Name = N'Sea Light Da Nang Hotel'), (SELECT TOP 1 Id FROM Amenities WHERE Name = N'Breakfast')),
        ((SELECT TOP 1 Id FROM Hotels WHERE Name = N'Lantern Riverside Resort'), (SELECT TOP 1 Id FROM Amenities WHERE Name = N'Free Wifi')),
        ((SELECT TOP 1 Id FROM Hotels WHERE Name = N'Lantern Riverside Resort'), (SELECT TOP 1 Id FROM Amenities WHERE Name = N'Breakfast')),
        ((SELECT TOP 1 Id FROM Hotels WHERE Name = N'Imperial Garden Hue'), (SELECT TOP 1 Id FROM Amenities WHERE Name = N'Free Wifi')),
        ((SELECT TOP 1 Id FROM Hotels WHERE Name = N'Imperial Garden Hue'), (SELECT TOP 1 Id FROM Amenities WHERE Name = N'Airport Shuttle'));
END
GO

/* Rooms */
IF NOT EXISTS (SELECT 1 FROM Rooms WHERE HotelId = (SELECT TOP 1 Id FROM Hotels WHERE Name = N'Sea Light Da Nang Hotel') AND RoomType = N'Deluxe Double')
BEGIN
    INSERT INTO Rooms (HotelId, RoomType, Capacity, PricePerNight, CommissionRate, AvailableQty)
    VALUES
        ((SELECT TOP 1 Id FROM Hotels WHERE Name = N'Sea Light Da Nang Hotel'), N'Deluxe Double', 2, 850000.00, 0.12, 12),
        ((SELECT TOP 1 Id FROM Hotels WHERE Name = N'Sea Light Da Nang Hotel'), N'Family Suite', 4, 1450000.00, 0.12, 5),
        ((SELECT TOP 1 Id FROM Hotels WHERE Name = N'Lantern Riverside Resort'), N'Superior Twin', 2, 920000.00, 0.10, 8),
        ((SELECT TOP 1 Id FROM Hotels WHERE Name = N'Lantern Riverside Resort'), N'River View Suite', 3, 1600000.00, 0.10, 4),
        ((SELECT TOP 1 Id FROM Hotels WHERE Name = N'Imperial Garden Hue'), N'Deluxe King', 2, 980000.00, 0.11, 10);
END
GO

/* Bus schedules */
IF NOT EXISTS (SELECT 1 FROM BusSchedules WHERE CompanyId = (SELECT TOP 1 Id FROM BusCompanies WHERE Name = N'Skynet Express') AND FromDestId = (SELECT TOP 1 Id FROM Destinations WHERE Name = N'Da Nang') AND ToDestId = (SELECT TOP 1 Id FROM Destinations WHERE Name = N'Hoi An'))
BEGIN
    INSERT INTO BusSchedules (CompanyId, FromDestId, ToDestId, DepartureTime, ArrivalTime, Price, CommissionRate, TotalSeats)
    VALUES
        ((SELECT TOP 1 Id FROM BusCompanies WHERE Name = N'Skynet Express'), (SELECT TOP 1 Id FROM Destinations WHERE Name = N'Da Nang'), (SELECT TOP 1 Id FROM Destinations WHERE Name = N'Hoi An'), DATEADD(HOUR, 8, CAST(CAST(DATEADD(DAY, 2, GETDATE()) AS date) AS datetime)), DATEADD(HOUR, 9, CAST(CAST(DATEADD(DAY, 2, GETDATE()) AS date) AS datetime)), 180000.00, 0.08, 16),
        ((SELECT TOP 1 Id FROM BusCompanies WHERE Name = N'Central Travel Bus'), (SELECT TOP 1 Id FROM Destinations WHERE Name = N'Hoi An'), (SELECT TOP 1 Id FROM Destinations WHERE Name = N'Hue'), DATEADD(MINUTE, 810, CAST(CAST(DATEADD(DAY, 3, GETDATE()) AS date) AS datetime)), DATEADD(MINUTE, 990, CAST(CAST(DATEADD(DAY, 3, GETDATE()) AS date) AS datetime)), 260000.00, 0.07, 20);
END
GO

DECLARE @DaNangHoiAnScheduleId int =
(
    SELECT TOP 1 Id
    FROM BusSchedules
    WHERE CompanyId = (SELECT TOP 1 Id FROM BusCompanies WHERE Name = N'Skynet Express')
      AND FromDestId = (SELECT TOP 1 Id FROM Destinations WHERE Name = N'Da Nang')
      AND ToDestId = (SELECT TOP 1 Id FROM Destinations WHERE Name = N'Hoi An')
);
GO

/* Seats */
IF NOT EXISTS (SELECT 1 FROM Seats WHERE ScheduleId = (SELECT TOP 1 Id FROM BusSchedules WHERE CompanyId = (SELECT TOP 1 Id FROM BusCompanies WHERE Name = N'Skynet Express') AND FromDestId = (SELECT TOP 1 Id FROM Destinations WHERE Name = N'Da Nang') AND ToDestId = (SELECT TOP 1 Id FROM Destinations WHERE Name = N'Hoi An')) AND SeatNumber = 'A01')
BEGIN
    INSERT INTO Seats (ScheduleId, SeatNumber, Status)
    VALUES
        ((SELECT TOP 1 Id FROM BusSchedules WHERE CompanyId = (SELECT TOP 1 Id FROM BusCompanies WHERE Name = N'Skynet Express') AND FromDestId = (SELECT TOP 1 Id FROM Destinations WHERE Name = N'Da Nang') AND ToDestId = (SELECT TOP 1 Id FROM Destinations WHERE Name = N'Hoi An')), 'A01', N'Available'),
        ((SELECT TOP 1 Id FROM BusSchedules WHERE CompanyId = (SELECT TOP 1 Id FROM BusCompanies WHERE Name = N'Skynet Express') AND FromDestId = (SELECT TOP 1 Id FROM Destinations WHERE Name = N'Da Nang') AND ToDestId = (SELECT TOP 1 Id FROM Destinations WHERE Name = N'Hoi An')), 'A02', N'Booked'),
        ((SELECT TOP 1 Id FROM BusSchedules WHERE CompanyId = (SELECT TOP 1 Id FROM BusCompanies WHERE Name = N'Skynet Express') AND FromDestId = (SELECT TOP 1 Id FROM Destinations WHERE Name = N'Da Nang') AND ToDestId = (SELECT TOP 1 Id FROM Destinations WHERE Name = N'Hoi An')), 'A03', N'Locked'),
        ((SELECT TOP 1 Id FROM BusSchedules WHERE CompanyId = (SELECT TOP 1 Id FROM BusCompanies WHERE Name = N'Skynet Express') AND FromDestId = (SELECT TOP 1 Id FROM Destinations WHERE Name = N'Da Nang') AND ToDestId = (SELECT TOP 1 Id FROM Destinations WHERE Name = N'Hoi An')), 'B01', N'Available'),
        ((SELECT TOP 1 Id FROM BusSchedules WHERE CompanyId = (SELECT TOP 1 Id FROM BusCompanies WHERE Name = N'Skynet Express') AND FromDestId = (SELECT TOP 1 Id FROM Destinations WHERE Name = N'Da Nang') AND ToDestId = (SELECT TOP 1 Id FROM Destinations WHERE Name = N'Hoi An')), 'B02', N'Available'),
        ((SELECT TOP 1 Id FROM BusSchedules WHERE CompanyId = (SELECT TOP 1 Id FROM BusCompanies WHERE Name = N'Skynet Express') AND FromDestId = (SELECT TOP 1 Id FROM Destinations WHERE Name = N'Da Nang') AND ToDestId = (SELECT TOP 1 Id FROM Destinations WHERE Name = N'Hoi An')), 'B03', N'Booked');
END
GO

/* Trips */
IF NOT EXISTS (SELECT 1 FROM Trips WHERE Title = N'Alice summer trip Da Nang - Hoi An')
BEGIN
    INSERT INTO Trips (UserId, DestinationId, Title, StartDate, EndDate, TotalAmount, TotalProfit, Status, CreatedAt)
    VALUES
        ((SELECT TOP 1 Id FROM Users WHERE Email = 'alice@skynettrip.local'), (SELECT TOP 1 Id FROM Destinations WHERE Name = N'Da Nang'), N'Alice summer trip Da Nang - Hoi An', CAST('2026-05-10' AS date), CAST('2026-05-13' AS date), 3560000.00, 420000.00, N'Paid', GETDATE()),
        ((SELECT TOP 1 Id FROM Users WHERE Email = 'bob@skynettrip.local'), (SELECT TOP 1 Id FROM Destinations WHERE Name = N'Hue'), N'Bob heritage weekend in Hue', CAST('2026-06-01' AS date), CAST('2026-06-03' AS date), 2240000.00, 250000.00, N'Pending', GETDATE());
END
GO

DECLARE @AliceTripId int = (SELECT TOP 1 Id FROM Trips WHERE Title = N'Alice summer trip Da Nang - Hoi An');
DECLARE @BobTripId int = (SELECT TOP 1 Id FROM Trips WHERE Title = N'Bob heritage weekend in Hue');
DECLARE @SeaLightDeluxeRoomId int = (SELECT TOP 1 Id FROM Rooms WHERE HotelId = (SELECT TOP 1 Id FROM Hotels WHERE Name = N'Sea Light Da Nang Hotel') AND RoomType = N'Deluxe Double');
GO

/* Trip itineraries */
IF NOT EXISTS (SELECT 1 FROM TripItineraries WHERE TripId = (SELECT TOP 1 Id FROM Trips WHERE Title = N'Alice summer trip Da Nang - Hoi An') AND DayNumber = 1 AND ServiceType = 1)
BEGIN
    INSERT INTO TripItineraries (TripId, DayNumber, ServiceType, ServiceId, Quantity, BookedPrice, BookedCommissionRate)
    VALUES
        ((SELECT TOP 1 Id FROM Trips WHERE Title = N'Alice summer trip Da Nang - Hoi An'), 1, 1, (SELECT TOP 1 Id FROM Rooms WHERE HotelId = (SELECT TOP 1 Id FROM Hotels WHERE Name = N'Sea Light Da Nang Hotel') AND RoomType = N'Deluxe Double'), 2, 1700000.00, 0.12),
        ((SELECT TOP 1 Id FROM Trips WHERE Title = N'Alice summer trip Da Nang - Hoi An'), 2, 2, (SELECT TOP 1 Id FROM BusSchedules WHERE CompanyId = (SELECT TOP 1 Id FROM BusCompanies WHERE Name = N'Skynet Express') AND FromDestId = (SELECT TOP 1 Id FROM Destinations WHERE Name = N'Da Nang') AND ToDestId = (SELECT TOP 1 Id FROM Destinations WHERE Name = N'Hoi An')), 2, 360000.00, 0.08),
        ((SELECT TOP 1 Id FROM Trips WHERE Title = N'Bob heritage weekend in Hue'), 1, 1, (SELECT TOP 1 Id FROM Rooms WHERE HotelId = (SELECT TOP 1 Id FROM Hotels WHERE Name = N'Imperial Garden Hue') AND RoomType = N'Deluxe King'), 2, 1960000.00, 0.11);
END
GO

/* Payments */
IF NOT EXISTS (SELECT 1 FROM Payments WHERE TransactionId = 'TXN-ALICE-0001')
BEGIN
    INSERT INTO Payments (TripId, PaymentMethod, TransactionId, Amount, Status, PaidAt)
    VALUES
        ((SELECT TOP 1 Id FROM Trips WHERE Title = N'Alice summer trip Da Nang - Hoi An'), 2, 'TXN-ALICE-0001', 3560000.00, 2, GETDATE()),
        ((SELECT TOP 1 Id FROM Trips WHERE Title = N'Bob heritage weekend in Hue'), 1, 'TXN-BOB-0001', 1120000.00, 1, NULL);
END
GO

/* Invoices */
IF NOT EXISTS (SELECT 1 FROM Invoices WHERE InvoiceNumber = 'INV-2026-0001')
BEGIN
    INSERT INTO Invoices (TripId, InvoiceNumber, TaxAmount, PdfUrl, IssuedAt)
    VALUES
        ((SELECT TOP 1 Id FROM Trips WHERE Title = N'Alice summer trip Da Nang - Hoi An'), 'INV-2026-0001', 320000.00, 'https://files.example.com/invoices/inv-2026-0001.pdf', GETDATE()),
        ((SELECT TOP 1 Id FROM Trips WHERE Title = N'Bob heritage weekend in Hue'), 'INV-2026-0002', 210000.00, 'https://files.example.com/invoices/inv-2026-0002.pdf', GETDATE());
END
GO

/* Reviews */
IF NOT EXISTS (SELECT 1 FROM Reviews WHERE UserId = (SELECT TOP 1 Id FROM Users WHERE Email = 'alice@skynettrip.local') AND TripId = (SELECT TOP 1 Id FROM Trips WHERE Title = N'Alice summer trip Da Nang - Hoi An') AND TargetType = 1)
BEGIN
    INSERT INTO Reviews (UserId, TripId, TargetType, TargetId, Rating, Comment, CreatedAt)
    VALUES
        ((SELECT TOP 1 Id FROM Users WHERE Email = 'alice@skynettrip.local'), (SELECT TOP 1 Id FROM Trips WHERE Title = N'Alice summer trip Da Nang - Hoi An'), 1, (SELECT TOP 1 Id FROM Hotels WHERE Name = N'Sea Light Da Nang Hotel'), 5, N'Clean room, helpful staff, and close to the beach.', GETDATE()),
        ((SELECT TOP 1 Id FROM Users WHERE Email = 'alice@skynettrip.local'), (SELECT TOP 1 Id FROM Trips WHERE Title = N'Alice summer trip Da Nang - Hoi An'), 2, (SELECT TOP 1 Id FROM BusCompanies WHERE Name = N'Skynet Express'), 4, N'Bus was on time and seats were comfortable.', GETDATE());
END
GO

/* Wishlists */
IF NOT EXISTS (SELECT 1 FROM Wishlists WHERE UserId = (SELECT TOP 1 Id FROM Users WHERE Email = 'bob@skynettrip.local') AND ItemType = 1 AND ItemId = (SELECT TOP 1 Id FROM Hotels WHERE Name = N'Lantern Riverside Resort'))
BEGIN
    INSERT INTO Wishlists (UserId, ItemType, ItemId, CreatedAt)
    VALUES
        ((SELECT TOP 1 Id FROM Users WHERE Email = 'bob@skynettrip.local'), 1, (SELECT TOP 1 Id FROM Hotels WHERE Name = N'Lantern Riverside Resort'), GETDATE()),
        ((SELECT TOP 1 Id FROM Users WHERE Email = 'alice@skynettrip.local'), 2, (SELECT TOP 1 Id FROM BusSchedules WHERE CompanyId = (SELECT TOP 1 Id FROM BusCompanies WHERE Name = N'Central Travel Bus') AND FromDestId = (SELECT TOP 1 Id FROM Destinations WHERE Name = N'Hoi An') AND ToDestId = (SELECT TOP 1 Id FROM Destinations WHERE Name = N'Hue')), GETDATE());
END
GO

/* Blog posts */
IF NOT EXISTS (SELECT 1 FROM BlogPosts WHERE Title = N'3 days in Da Nang and Hoi An')
BEGIN
    INSERT INTO BlogPosts (AuthorId, DestinationId, Title, ContentHtml, ThumbnailUrl, PublishedAt)
    VALUES
        ((SELECT TOP 1 Id FROM Users WHERE Email = 'admin@skynettrip.local'), (SELECT TOP 1 Id FROM Destinations WHERE Name = N'Da Nang'), N'3 days in Da Nang and Hoi An', N'<p>Suggested route for food, beach, and old town experiences.</p>', 'https://images.example.com/blog/danang-hoian.jpg', GETDATE()),
        ((SELECT TOP 1 Id FROM Users WHERE Email = 'admin@skynettrip.local'), (SELECT TOP 1 Id FROM Destinations WHERE Name = N'Hue'), N'Hue weekend guide', N'<p>Citadel, pagoda, and royal cuisine in a compact itinerary.</p>', 'https://images.example.com/blog/hue-guide.jpg', GETDATE());
END
GO

/* Notifications */
IF NOT EXISTS (SELECT 1 FROM Notifications WHERE UserId = (SELECT TOP 1 Id FROM Users WHERE Email = 'alice@skynettrip.local') AND Title = N'Payment received')
BEGIN
    INSERT INTO Notifications (UserId, Title, Message, IsRead, CreatedAt)
    VALUES
        ((SELECT TOP 1 Id FROM Users WHERE Email = 'alice@skynettrip.local'), N'Payment received', N'Your payment for the Da Nang - Hoi An trip was confirmed successfully.', 0, GETDATE()),
        ((SELECT TOP 1 Id FROM Users WHERE Email = 'bob@skynettrip.local'), N'Pending payment', N'Please complete the remaining payment for your Hue booking.', 0, GETDATE());
END
GO

/* Galleries */
IF NOT EXISTS (SELECT 1 FROM Galleries WHERE ReferenceType = 3 AND ReferenceId = (SELECT TOP 1 Id FROM Destinations WHERE Name = N'Da Nang'))
BEGIN
    INSERT INTO Galleries (ReferenceType, ReferenceId, ImageUrl)
    VALUES
        (3, (SELECT TOP 1 Id FROM Destinations WHERE Name = N'Da Nang'), 'https://images.example.com/gallery/danang-01.jpg'),
        (3, (SELECT TOP 1 Id FROM Destinations WHERE Name = N'Hoi An'), 'https://images.example.com/gallery/hoian-01.jpg'),
        (1, (SELECT TOP 1 Id FROM Hotels WHERE Name = N'Sea Light Da Nang Hotel'), 'https://images.example.com/gallery/hotel-sealight-01.jpg'),
        (2, (SELECT TOP 1 Id FROM Rooms WHERE HotelId = (SELECT TOP 1 Id FROM Hotels WHERE Name = N'Sea Light Da Nang Hotel') AND RoomType = N'Deluxe Double'), 'https://images.example.com/gallery/room-deluxe-01.jpg');
END
GO

COMMIT TRANSACTION;
GO

PRINT 'Sample seed data inserted successfully.';
GO
