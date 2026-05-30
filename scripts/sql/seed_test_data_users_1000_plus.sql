USE SkynetSmartTrip;
GO

SET NOCOUNT ON;
GO

BEGIN TRY
    BEGIN TRANSACTION;

    DECLARE @Users TABLE
    (
        RowNo INT IDENTITY(1,1) PRIMARY KEY,
        UserId INT NOT NULL,
        FullName NVARCHAR(100) NULL,
        Email VARCHAR(100) NULL
    );

    INSERT INTO @Users (UserId, FullName, Email)
    SELECT Id, FullName, Email
    FROM dbo.Users
    WHERE Id >= 1000 AND ISNULL(IsActive, 0) = 1
    ORDER BY Id;

    IF NOT EXISTS (SELECT 1 FROM @Users)
    BEGIN
        THROW 50000, 'Khong tim thay user active co Id >= 1000.', 1;
    END;

    DECLARE @DefaultDestinationId INT;
    SELECT TOP (1) @DefaultDestinationId = Id
    FROM dbo.Destinations
    ORDER BY Id;

    IF @DefaultDestinationId IS NULL
    BEGIN
        THROW 50001, 'Bang Destinations chua co du lieu.', 1;
    END;

    DECLARE @Hotels TABLE
    (
        RowNo INT IDENTITY(1,1) PRIMARY KEY,
        HotelId INT NOT NULL,
        DestinationId INT NULL,
        HotelName NVARCHAR(200) NULL,
        BasePrice DECIMAL(18,2) NOT NULL
    );

    INSERT INTO @Hotels (HotelId, DestinationId, HotelName, BasePrice)
    SELECT
        h.Id,
        COALESCE(h.DestinationId, @DefaultDestinationId),
        h.Name,
        COALESCE(MIN(r.PricePerNight), CAST(850000 + (h.Id * 1000) AS DECIMAL(18,2)))
    FROM dbo.Hotels h
    LEFT JOIN dbo.Rooms r ON r.HotelId = h.Id
    GROUP BY h.Id, h.DestinationId, h.Name
    ORDER BY h.Id;

    IF NOT EXISTS (SELECT 1 FROM @Hotels)
    BEGIN
        THROW 50002, 'Bang Hotels chua co du lieu.', 1;
    END;

    DECLARE @Buses TABLE
    (
        RowNo INT IDENTITY(1,1) PRIMARY KEY,
        ScheduleId INT NOT NULL,
        FromDestId INT NULL,
        ToDestId INT NULL,
        Price DECIMAL(18,2) NOT NULL
    );

    INSERT INTO @Buses (ScheduleId, FromDestId, ToDestId, Price)
    SELECT
        s.Id,
        COALESCE(s.FromDestId, @DefaultDestinationId),
        COALESCE(s.ToDestId, @DefaultDestinationId),
        COALESCE(s.Price, CAST(180000 + (s.Id * 500) AS DECIMAL(18,2)))
    FROM dbo.BusSchedules s
    ORDER BY s.Id;

    IF NOT EXISTS (SELECT 1 FROM @Buses)
    BEGIN
        THROW 50003, 'Bang BusSchedules chua co du lieu.', 1;
    END;

    DECLARE @HotelCount INT = (SELECT COUNT(*) FROM @Hotels);
    DECLARE @BusCount INT = (SELECT COUNT(*) FROM @Buses);
    DECLARE @UserCount INT = (SELECT COUNT(*) FROM @Users);

    DECLARE
        @Index INT = 1,
        @UserId INT,
        @HotelAId INT,
        @HotelADestinationId INT,
        @HotelAPrice DECIMAL(18,2),
        @HotelBId INT,
        @HotelBDestinationId INT,
        @HotelBPrice DECIMAL(18,2),
        @BusAId INT,
        @BusAToDestinationId INT,
        @BusAPrice DECIMAL(18,2),
        @BusBId INT,
        @BusBToDestinationId INT,
        @BusBPrice DECIMAL(18,2),
        @PaidTripId INT,
        @PendingTripId INT,
        @PaidTripTitle NVARCHAR(200),
        @PendingTripTitle NVARCHAR(200),
        @PastStartDate DATE,
        @PastEndDate DATE,
        @FutureStartDate DATE,
        @FutureEndDate DATE,
        @PaidTripAmount DECIMAL(18,2),
        @PendingTripAmount DECIMAL(18,2),
        @PaidTripProfit DECIMAL(18,2),
        @PendingTripProfit DECIMAL(18,2),
        @InvoiceNumber VARCHAR(50),
        @TransactionId VARCHAR(100);

    WHILE @Index <= @UserCount
    BEGIN
        SELECT @UserId = UserId
        FROM @Users
        WHERE RowNo = @Index;

        SELECT
            @HotelAId = HotelId,
            @HotelADestinationId = DestinationId,
            @HotelAPrice = BasePrice
        FROM @Hotels
        WHERE RowNo = ((@Index - 1) % @HotelCount) + 1;

        SELECT
            @HotelBId = HotelId,
            @HotelBDestinationId = DestinationId,
            @HotelBPrice = BasePrice
        FROM @Hotels
        WHERE RowNo = (@Index % @HotelCount) + 1;

        SELECT
            @BusAId = ScheduleId,
            @BusAToDestinationId = ToDestId,
            @BusAPrice = Price
        FROM @Buses
        WHERE RowNo = ((@Index - 1) % @BusCount) + 1;

        SELECT
            @BusBId = ScheduleId,
            @BusBToDestinationId = ToDestId,
            @BusBPrice = Price
        FROM @Buses
        WHERE RowNo = (@Index % @BusCount) + 1;

        IF NOT EXISTS (SELECT 1 FROM dbo.UserWallets WHERE UserId = @UserId)
        BEGIN
            INSERT INTO dbo.UserWallets (UserId, Balance, LoyaltyPoints)
            VALUES (@UserId, 0, 150 + (@Index * 35));
        END;

        IF NOT EXISTS (SELECT 1 FROM dbo.Rooms WHERE HotelId = @HotelAId)
        BEGIN
            INSERT INTO dbo.Rooms (HotelId, RoomType, Capacity, PricePerNight, CommissionRate, AvailableQty)
            VALUES (@HotelAId, N'Seed Standard', 2, @HotelAPrice, 0.10, 8);
        END;

        IF NOT EXISTS (SELECT 1 FROM dbo.Rooms WHERE HotelId = @HotelBId)
        BEGIN
            INSERT INTO dbo.Rooms (HotelId, RoomType, Capacity, PricePerNight, CommissionRate, AvailableQty)
            VALUES (@HotelBId, N'Seed Deluxe', 2, @HotelBPrice, 0.12, 6);
        END;

        SET @PastStartDate = DATEADD(DAY, -20 - @Index, CAST(GETDATE() AS DATE));
        SET @PastEndDate = DATEADD(DAY, 2, @PastStartDate);
        SET @FutureStartDate = DATEADD(DAY, 12 + @Index, CAST(GETDATE() AS DATE));
        SET @FutureEndDate = DATEADD(DAY, 3, @FutureStartDate);

        SET @PaidTripTitle = CONCAT(N'Test Paid Trip U', @UserId);
        SET @PendingTripTitle = CONCAT(N'Test Pending Trip U', @UserId);

        SET @PaidTripAmount = (@HotelAPrice * 2) + (@BusAPrice * 2);
        SET @PendingTripAmount = (@HotelBPrice * 3) + (@BusBPrice * 2);
        SET @PaidTripProfit = ROUND(@PaidTripAmount * 0.12, 2);
        SET @PendingTripProfit = ROUND(@PendingTripAmount * 0.10, 2);

        SELECT @PaidTripId = Id
        FROM dbo.Trips
        WHERE UserId = @UserId
          AND Title = @PaidTripTitle;

        IF @PaidTripId IS NULL
        BEGIN
            INSERT INTO dbo.Trips
            (
                UserId,
                DestinationId,
                Title,
                StartDate,
                EndDate,
                TotalAmount,
                TotalProfit,
                Status,
                CreatedAt
            )
            VALUES
            (
                @UserId,
                COALESCE(@HotelADestinationId, @BusAToDestinationId, @DefaultDestinationId),
                @PaidTripTitle,
                @PastStartDate,
                @PastEndDate,
                @PaidTripAmount,
                @PaidTripProfit,
                'Paid',
                DATEADD(DAY, -25 - @Index, GETDATE())
            );

            SET @PaidTripId = SCOPE_IDENTITY();
        END;

        SELECT @PendingTripId = Id
        FROM dbo.Trips
        WHERE UserId = @UserId
          AND Title = @PendingTripTitle;

        IF @PendingTripId IS NULL
        BEGIN
            INSERT INTO dbo.Trips
            (
                UserId,
                DestinationId,
                Title,
                StartDate,
                EndDate,
                TotalAmount,
                TotalProfit,
                Status,
                CreatedAt
            )
            VALUES
            (
                @UserId,
                COALESCE(@HotelBDestinationId, @BusBToDestinationId, @DefaultDestinationId),
                @PendingTripTitle,
                @FutureStartDate,
                @FutureEndDate,
                @PendingTripAmount,
                @PendingTripProfit,
                'Pending',
                DATEADD(DAY, -4 - @Index, GETDATE())
            );

            SET @PendingTripId = SCOPE_IDENTITY();
        END;

        IF NOT EXISTS
        (
            SELECT 1
            FROM dbo.TripItineraries
            WHERE TripId = @PaidTripId
              AND ServiceType = 1
              AND ServiceId = @HotelAId
        )
        BEGIN
            INSERT INTO dbo.TripItineraries
            (
                TripId,
                DayNumber,
                ServiceType,
                ServiceId,
                Quantity,
                BookedPrice,
                BookedCommissionRate
            )
            VALUES
            (
                @PaidTripId,
                1,
                1,
                @HotelAId,
                1,
                @HotelAPrice * 2,
                0.12
            );
        END;

        IF NOT EXISTS
        (
            SELECT 1
            FROM dbo.TripItineraries
            WHERE TripId = @PaidTripId
              AND ServiceType = 2
              AND ServiceId = @BusAId
        )
        BEGIN
            INSERT INTO dbo.TripItineraries
            (
                TripId,
                DayNumber,
                ServiceType,
                ServiceId,
                Quantity,
                BookedPrice,
                BookedCommissionRate
            )
            VALUES
            (
                @PaidTripId,
                1,
                2,
                @BusAId,
                2,
                @BusAPrice * 2,
                0.08
            );
        END;

        IF NOT EXISTS
        (
            SELECT 1
            FROM dbo.TripItineraries
            WHERE TripId = @PendingTripId
              AND ServiceType = 1
              AND ServiceId = @HotelBId
        )
        BEGIN
            INSERT INTO dbo.TripItineraries
            (
                TripId,
                DayNumber,
                ServiceType,
                ServiceId,
                Quantity,
                BookedPrice,
                BookedCommissionRate
            )
            VALUES
            (
                @PendingTripId,
                1,
                1,
                @HotelBId,
                1,
                @HotelBPrice * 3,
                0.10
            );
        END;

        IF NOT EXISTS
        (
            SELECT 1
            FROM dbo.TripItineraries
            WHERE TripId = @PendingTripId
              AND ServiceType = 2
              AND ServiceId = @BusBId
        )
        BEGIN
            INSERT INTO dbo.TripItineraries
            (
                TripId,
                DayNumber,
                ServiceType,
                ServiceId,
                Quantity,
                BookedPrice,
                BookedCommissionRate
            )
            VALUES
            (
                @PendingTripId,
                2,
                2,
                @BusBId,
                2,
                @BusBPrice * 2,
                0.08
            );
        END;

        SET @InvoiceNumber = CONCAT('INV-U', @UserId, '-PAID');

        IF NOT EXISTS (SELECT 1 FROM dbo.Invoices WHERE InvoiceNumber = @InvoiceNumber)
        BEGIN
            INSERT INTO dbo.Invoices
            (
                TripId,
                InvoiceNumber,
                TaxAmount,
                PdfUrl,
                IssuedAt
            )
            VALUES
            (
                @PaidTripId,
                @InvoiceNumber,
                ROUND(@PaidTripAmount * 0.08, 2),
                CONCAT('https://files.example.com/invoices/', @InvoiceNumber, '.pdf'),
                DATEADD(DAY, 1, CAST(@PastEndDate AS DATETIME))
            );
        END;

        SET @TransactionId = CONCAT('TXN-U', @UserId, '-PAID');

        IF NOT EXISTS (SELECT 1 FROM dbo.Payments WHERE TransactionId = @TransactionId)
        BEGIN
            INSERT INTO dbo.Payments
            (
                TripId,
                PaymentMethod,
                TransactionId,
                Amount,
                Status,
                PaidAt
            )
            VALUES
            (
                @PaidTripId,
                CASE WHEN (@Index % 3) = 1 THEN 1
                     WHEN (@Index % 3) = 2 THEN 2
                     ELSE 3
                END,
                @TransactionId,
                @PaidTripAmount,
                2,
                DATEADD(DAY, -18 - @Index, GETDATE())
            );
        END;

        IF NOT EXISTS
        (
            SELECT 1
            FROM dbo.Wishlists
            WHERE UserId = @UserId
              AND ItemType = 1
              AND ItemId = @HotelAId
        )
        BEGIN
            INSERT INTO dbo.Wishlists (UserId, ItemType, ItemId, CreatedAt)
            VALUES (@UserId, 1, @HotelAId, DATEADD(DAY, -6 - @Index, GETDATE()));
        END;

        IF NOT EXISTS
        (
            SELECT 1
            FROM dbo.Wishlists
            WHERE UserId = @UserId
              AND ItemType = 2
              AND ItemId = @BusAId
        )
        BEGIN
            INSERT INTO dbo.Wishlists (UserId, ItemType, ItemId, CreatedAt)
            VALUES (@UserId, 2, @BusAId, DATEADD(DAY, -5 - @Index, GETDATE()));
        END;

        SET @PaidTripId = NULL;
        SET @PendingTripId = NULL;
        SET @Index += 1;
    END;

    COMMIT TRANSACTION;

    PRINT 'Seed du lieu mau cho user Id >= 1000 thanh cong.';
    PRINT 'Moi user se co: 2 trip, hotel/bus itinerary, payment, invoice, favorites, wallet.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    THROW;
END CATCH;
GO

SELECT
    u.Id AS UserId,
    u.Email,
    (SELECT COUNT(*) FROM dbo.Trips t WHERE t.UserId = u.Id) AS TripsCount,
    (SELECT COUNT(*) FROM dbo.Wishlists w WHERE w.UserId = u.Id) AS FavoritesCount,
    (SELECT COUNT(*) FROM dbo.Payments p INNER JOIN dbo.Trips t ON t.Id = p.TripId WHERE t.UserId = u.Id) AS PaymentsCount
FROM dbo.Users u
WHERE u.Id >= 1000
ORDER BY u.Id;
GO
