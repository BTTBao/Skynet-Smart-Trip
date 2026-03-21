-- 1. Tạo Database
CREATE DATABASE SkynetSmartTrip;
GO
USE SkynetSmartTrip;
GO

---------------------------------------------------------
-- CỤM 1: NGƯỜI DÙNG & TƯƠNG TÁC
---------------------------------------------------------

CREATE TABLE USERS (
    user_id INT PRIMARY KEY IDENTITY(1,1),
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255),
    full_name NVARCHAR(100),
    phone VARCHAR(20),
    avatar_url VARCHAR(255),
    auth_provider NVARCHAR(20) DEFAULT 'LOCAL', -- LOCAL, GOOGLE, APPLE
    social_id VARCHAR(255),
    role NVARCHAR(20) DEFAULT 'USER', -- USER, ADMIN
    is_active BIT DEFAULT 1,
    created_at DATETIME DEFAULT GETDATE()
);

CREATE TABLE USER_WALLETS (
    wallet_id INT PRIMARY KEY IDENTITY(1,1),
    user_id INT FOREIGN KEY REFERENCES USERS(user_id),
    balance DECIMAL(18, 2) DEFAULT 0,
    loyalty_points INT DEFAULT 0
);

---------------------------------------------------------
-- CỤM 2: ĐIỂM ĐẾN & NỘI DUNG
---------------------------------------------------------

CREATE TABLE DESTINATIONS (
    dest_id INT PRIMARY KEY IDENTITY(1,1),
    name NVARCHAR(100) NOT NULL,
    description NVARCHAR(MAX),
    cover_image_url VARCHAR(255),
    is_hot BIT DEFAULT 0
);

CREATE TABLE GALLERIES (
    photo_id INT PRIMARY KEY IDENTITY(1,1),
    reference_type NVARCHAR(50), -- HOTEL, ROOM, DESTINATION
    reference_id INT,
    image_url VARCHAR(255)
);

CREATE TABLE BLOG_POSTS (
    post_id INT PRIMARY KEY IDENTITY(1,1),
    author_id INT FOREIGN KEY REFERENCES USERS(user_id),
    destination_id INT FOREIGN KEY REFERENCES DESTINATIONS(dest_id),
    title NVARCHAR(255),
    content_html NVARCHAR(MAX),
    thumbnail_url VARCHAR(255),
    published_at DATETIME DEFAULT GETDATE()
);

---------------------------------------------------------
-- CỤM 3: KHÁCH SẠN (ACCOMMODATION)
---------------------------------------------------------

CREATE TABLE AMENITIES (
    amenity_id INT PRIMARY KEY IDENTITY(1,1),
    name NVARCHAR(100),
    icon_url VARCHAR(255)
);

CREATE TABLE HOTELS (
    hotel_id INT PRIMARY KEY IDENTITY(1,1),
    destination_id INT FOREIGN KEY REFERENCES DESTINATIONS(dest_id),
    name NVARCHAR(200) NOT NULL,
    address NVARCHAR(255),
    star_rating INT CHECK (star_rating BETWEEN 1 AND 5),
    description NVARCHAR(MAX),
    is_available BIT DEFAULT 1
);

CREATE TABLE HOTEL_AMENITY_MAPPING (
    hotel_id INT FOREIGN KEY REFERENCES HOTELS(hotel_id),
    amenity_id INT FOREIGN KEY REFERENCES AMENITIES(amenity_id),
    PRIMARY KEY (hotel_id, amenity_id)
);

CREATE TABLE ROOMS (
    room_id INT PRIMARY KEY IDENTITY(1,1),
    hotel_id INT FOREIGN KEY REFERENCES HOTELS(hotel_id),
    room_type NVARCHAR(100),
    capacity INT,
    price_per_night DECIMAL(18, 2),
    commission_rate FLOAT,
    available_qty INT
);

---------------------------------------------------------
-- CỤM 4: NHÀ XE (TRANSPORTATION)
---------------------------------------------------------

CREATE TABLE BUS_COMPANIES (
    company_id INT PRIMARY KEY IDENTITY(1,1),
    name NVARCHAR(100),
    hotline VARCHAR(20),
    logo_url VARCHAR(255)
);

CREATE TABLE BUS_SCHEDULES (
    schedule_id INT PRIMARY KEY IDENTITY(1,1),
    company_id INT FOREIGN KEY REFERENCES BUS_COMPANIES(company_id),
    from_dest_id INT FOREIGN KEY REFERENCES DESTINATIONS(dest_id),
    to_dest_id INT FOREIGN KEY REFERENCES DESTINATIONS(dest_id),
    departure_time DATETIME,
    arrival_time DATETIME,
    price DECIMAL(18, 2),
    commission_rate FLOAT,
    total_seats INT
);

CREATE TABLE SEATS (
    seat_id INT PRIMARY KEY IDENTITY(1,1),
    schedule_id INT FOREIGN KEY REFERENCES BUS_SCHEDULES(schedule_id),
    seat_number VARCHAR(10),
    status NVARCHAR(20) DEFAULT 'AVAILABLE' -- AVAILABLE, LOCKED, BOOKED
);

---------------------------------------------------------
-- CỤM 5: LỊCH TRÌNH & THANH TOÁN (CORE)
---------------------------------------------------------

CREATE TABLE PROMOTIONS (
    promo_id INT PRIMARY KEY IDENTITY(1,1),
    code VARCHAR(50) UNIQUE,
    discount_percent FLOAT,
    max_discount_amount DECIMAL(18, 2),
    valid_until DATETIME,
    usage_limit INT,
    used_count INT DEFAULT 0
);

CREATE TABLE TRIPS (
    trip_id INT PRIMARY KEY IDENTITY(1,1),
    user_id INT FOREIGN KEY REFERENCES USERS(user_id),
    destination_id INT FOREIGN KEY REFERENCES DESTINATIONS(dest_id),
    title NVARCHAR(200),
    start_date DATE,
    end_date DATE,
    total_amount DECIMAL(18, 2) DEFAULT 0,
    total_profit DECIMAL(18, 2) DEFAULT 0,
    status NVARCHAR(50) DEFAULT 'DRAFT', -- DRAFT, PENDING, PAID, CANCELLED
    created_at DATETIME DEFAULT GETDATE()
);

CREATE TABLE TRIP_ITINERARIES (
    itinerary_id INT PRIMARY KEY IDENTITY(1,1),
    trip_id INT FOREIGN KEY REFERENCES TRIPS(trip_id),
    day_number INT,
    service_type NVARCHAR(20), -- HOTEL, BUS
    service_id INT,
    quantity INT DEFAULT 1,
    booked_price DECIMAL(18, 2),
    booked_commission_rate FLOAT
);

CREATE TABLE PAYMENTS (
    payment_id INT PRIMARY KEY IDENTITY(1,1),
    trip_id INT FOREIGN KEY REFERENCES TRIPS(trip_id),
    payment_method NVARCHAR(50), -- MOMO, VNPAY, CARD
    transaction_id VARCHAR(100),
    amount DECIMAL(18, 2),
    status NVARCHAR(50),
    paid_at DATETIME DEFAULT GETDATE()
);

---------------------------------------------------------
-- CỤM 6: HẬU MÃI & ĐÁNH GIÁ
---------------------------------------------------------

CREATE TABLE REVIEWS (
    review_id INT PRIMARY KEY IDENTITY(1,1),
    user_id INT FOREIGN KEY REFERENCES USERS(user_id),
    trip_id INT FOREIGN KEY REFERENCES TRIPS(trip_id),
    target_type NVARCHAR(20), -- HOTEL, BUS_COMPANY
    target_id INT,
    rating INT CHECK (rating BETWEEN 1 AND 5),
    comment NVARCHAR(MAX),
    created_at DATETIME DEFAULT GETDATE()
);

CREATE TABLE INVOICES (
    invoice_id INT PRIMARY KEY IDENTITY(1,1),
    trip_id INT FOREIGN KEY REFERENCES TRIPS(trip_id),
    invoice_number VARCHAR(50) UNIQUE,
    tax_amount DECIMAL(18, 2),
    pdf_url VARCHAR(255),
    issued_at DATETIME DEFAULT GETDATE()
);

CREATE TABLE WISHLISTS (
    wish_id INT PRIMARY KEY IDENTITY(1,1),
    user_id INT FOREIGN KEY REFERENCES USERS(user_id),
    item_type NVARCHAR(20), -- HOTEL, BUS
    item_id INT,
    created_at DATETIME DEFAULT GETDATE()
);

CREATE TABLE NOTIFICATIONS (
    noti_id INT PRIMARY KEY IDENTITY(1,1),
    user_id INT FOREIGN KEY REFERENCES USERS(user_id),
    title NVARCHAR(200),
    message NVARCHAR(MAX),
    is_read BIT DEFAULT 0,
    created_at DATETIME DEFAULT GETDATE()
);
GO