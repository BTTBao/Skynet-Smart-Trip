using System;
using System.Collections.Generic;
using Microsoft.EntityFrameworkCore;

namespace SmartTrip.Domain.Entities;

public partial class ApplicationDbContext : DbContext
{
    public ApplicationDbContext()
    {
    }

    public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options)
        : base(options)
    {
    }

    public virtual DbSet<Amenity> Amenities { get; set; }

    public virtual DbSet<BlogPost> BlogPosts { get; set; }

    public virtual DbSet<BusCompany> BusCompanies { get; set; }

    public virtual DbSet<BusSchedule> BusSchedules { get; set; }

    public virtual DbSet<Destination> Destinations { get; set; }

    public virtual DbSet<Gallery> Galleries { get; set; }

    public virtual DbSet<Hotel> Hotels { get; set; }

    public virtual DbSet<Invoice> Invoices { get; set; }

    public virtual DbSet<Notification> Notifications { get; set; }

    public virtual DbSet<Payment> Payments { get; set; }

    public virtual DbSet<Promotion> Promotions { get; set; }

    public virtual DbSet<Review> Reviews { get; set; }

    public virtual DbSet<Room> Rooms { get; set; }

    public virtual DbSet<Seat> Seats { get; set; }

    public virtual DbSet<Trip> Trips { get; set; }

    public virtual DbSet<TripItinerary> TripItineraries { get; set; }

    public virtual DbSet<User> Users { get; set; }

    public virtual DbSet<UserWallet> UserWallets { get; set; }

    public virtual DbSet<Wishlist> Wishlists { get; set; }

    protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
#warning To protect potentially sensitive information in your connection string, you should move it out of source code. You can avoid scaffolding the connection string by using the Name= syntax to read it from configuration - see https://go.microsoft.com/fwlink/?linkid=2131148. For more guidance on storing connection strings, see https://go.microsoft.com/fwlink/?LinkId=723263.
        => optionsBuilder.UseSqlServer("Server=localhost,1434;Database=SkynetSmartTrip;User Id=sa;Password=@Abcd@1234;TrustServerCertificate=True;");

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Amenity>(entity =>
        {
            entity.HasKey(e => e.AmenityId).HasName("PK__AMENITIE__E908452D9ECC4C9B");

            entity.ToTable("AMENITIES");

            entity.Property(e => e.AmenityId).HasColumnName("amenity_id");
            entity.Property(e => e.IconUrl)
                .HasMaxLength(255)
                .IsUnicode(false)
                .HasColumnName("icon_url");
            entity.Property(e => e.Name)
                .HasMaxLength(100)
                .HasColumnName("name");
        });

        modelBuilder.Entity<BlogPost>(entity =>
        {
            entity.HasKey(e => e.PostId).HasName("PK__BLOG_POS__3ED78766138FCFD8");

            entity.ToTable("BLOG_POSTS");

            entity.Property(e => e.PostId).HasColumnName("post_id");
            entity.Property(e => e.AuthorId).HasColumnName("author_id");
            entity.Property(e => e.ContentHtml).HasColumnName("content_html");
            entity.Property(e => e.DestinationId).HasColumnName("destination_id");
            entity.Property(e => e.PublishedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime")
                .HasColumnName("published_at");
            entity.Property(e => e.ThumbnailUrl)
                .HasMaxLength(255)
                .IsUnicode(false)
                .HasColumnName("thumbnail_url");
            entity.Property(e => e.Title)
                .HasMaxLength(255)
                .HasColumnName("title");

            entity.HasOne(d => d.Author).WithMany(p => p.BlogPosts)
                .HasForeignKey(d => d.AuthorId)
                .HasConstraintName("FK__BLOG_POST__autho__47DBAE45");

            entity.HasOne(d => d.Destination).WithMany(p => p.BlogPosts)
                .HasForeignKey(d => d.DestinationId)
                .HasConstraintName("FK__BLOG_POST__desti__48CFD27E");
        });

        modelBuilder.Entity<BusCompany>(entity =>
        {
            entity.HasKey(e => e.CompanyId).HasName("PK__BUS_COMP__3E2672358894F765");

            entity.ToTable("BUS_COMPANIES");

            entity.Property(e => e.CompanyId).HasColumnName("company_id");
            entity.Property(e => e.Hotline)
                .HasMaxLength(20)
                .IsUnicode(false)
                .HasColumnName("hotline");
            entity.Property(e => e.LogoUrl)
                .HasMaxLength(255)
                .IsUnicode(false)
                .HasColumnName("logo_url");
            entity.Property(e => e.Name)
                .HasMaxLength(100)
                .HasColumnName("name");
        });

        modelBuilder.Entity<BusSchedule>(entity =>
        {
            entity.HasKey(e => e.ScheduleId).HasName("PK__BUS_SCHE__C46A8A6F61FF1F96");

            entity.ToTable("BUS_SCHEDULES");

            entity.Property(e => e.ScheduleId).HasColumnName("schedule_id");
            entity.Property(e => e.ArrivalTime)
                .HasColumnType("datetime")
                .HasColumnName("arrival_time");
            entity.Property(e => e.CommissionRate).HasColumnName("commission_rate");
            entity.Property(e => e.CompanyId).HasColumnName("company_id");
            entity.Property(e => e.DepartureTime)
                .HasColumnType("datetime")
                .HasColumnName("departure_time");
            entity.Property(e => e.FromDestId).HasColumnName("from_dest_id");
            entity.Property(e => e.Price)
                .HasColumnType("decimal(18, 2)")
                .HasColumnName("price");
            entity.Property(e => e.ToDestId).HasColumnName("to_dest_id");
            entity.Property(e => e.TotalSeats).HasColumnName("total_seats");

            entity.HasOne(d => d.Company).WithMany(p => p.BusSchedules)
                .HasForeignKey(d => d.CompanyId)
                .HasConstraintName("FK__BUS_SCHED__compa__5BE2A6F2");

            entity.HasOne(d => d.FromDest).WithMany(p => p.BusScheduleFromDests)
                .HasForeignKey(d => d.FromDestId)
                .HasConstraintName("FK__BUS_SCHED__from___5CD6CB2B");

            entity.HasOne(d => d.ToDest).WithMany(p => p.BusScheduleToDests)
                .HasForeignKey(d => d.ToDestId)
                .HasConstraintName("FK__BUS_SCHED__to_de__5DCAEF64");
        });

        modelBuilder.Entity<Destination>(entity =>
        {
            entity.HasKey(e => e.DestId).HasName("PK__DESTINAT__3C2885877DF042DA");

            entity.ToTable("DESTINATIONS");

            entity.Property(e => e.DestId).HasColumnName("dest_id");
            entity.Property(e => e.CoverImageUrl)
                .HasMaxLength(255)
                .IsUnicode(false)
                .HasColumnName("cover_image_url");
            entity.Property(e => e.Description).HasColumnName("description");
            entity.Property(e => e.IsHot)
                .HasDefaultValue(false)
                .HasColumnName("is_hot");
            entity.Property(e => e.Name)
                .HasMaxLength(100)
                .HasColumnName("name");
        });

        modelBuilder.Entity<Gallery>(entity =>
        {
            entity.HasKey(e => e.PhotoId).HasName("PK__GALLERIE__CB48C83D116CBEC4");

            entity.ToTable("GALLERIES");

            entity.Property(e => e.PhotoId).HasColumnName("photo_id");
            entity.Property(e => e.ImageUrl)
                .HasMaxLength(255)
                .IsUnicode(false)
                .HasColumnName("image_url");
            entity.Property(e => e.ReferenceId).HasColumnName("reference_id");
            entity.Property(e => e.ReferenceType)
                .HasMaxLength(50)
                .HasColumnName("reference_type");
        });

        modelBuilder.Entity<Hotel>(entity =>
        {
            entity.HasKey(e => e.HotelId).HasName("PK__HOTELS__45FE7E261ABC277F");

            entity.ToTable("HOTELS");

            entity.Property(e => e.HotelId).HasColumnName("hotel_id");
            entity.Property(e => e.Address)
                .HasMaxLength(255)
                .HasColumnName("address");
            entity.Property(e => e.Description).HasColumnName("description");
            entity.Property(e => e.DestinationId).HasColumnName("destination_id");
            entity.Property(e => e.IsAvailable)
                .HasDefaultValue(true)
                .HasColumnName("is_available");
            entity.Property(e => e.Name)
                .HasMaxLength(200)
                .HasColumnName("name");
            entity.Property(e => e.StarRating).HasColumnName("star_rating");

            entity.HasOne(d => d.Destination).WithMany(p => p.Hotels)
                .HasForeignKey(d => d.DestinationId)
                .HasConstraintName("FK__HOTELS__destinat__4E88ABD4");

            entity.HasMany(d => d.Amenities).WithMany(p => p.Hotels)
                .UsingEntity<Dictionary<string, object>>(
                    "HotelAmenityMapping",
                    r => r.HasOne<Amenity>().WithMany()
                        .HasForeignKey("AmenityId")
                        .OnDelete(DeleteBehavior.ClientSetNull)
                        .HasConstraintName("FK__HOTEL_AME__ameni__5441852A"),
                    l => l.HasOne<Hotel>().WithMany()
                        .HasForeignKey("HotelId")
                        .OnDelete(DeleteBehavior.ClientSetNull)
                        .HasConstraintName("FK__HOTEL_AME__hotel__534D60F1"),
                    j =>
                    {
                        j.HasKey("HotelId", "AmenityId").HasName("PK__HOTEL_AM__8B6EFA74AF68D81E");
                        j.ToTable("HOTEL_AMENITY_MAPPING");
                        j.IndexerProperty<int>("HotelId").HasColumnName("hotel_id");
                        j.IndexerProperty<int>("AmenityId").HasColumnName("amenity_id");
                    });
        });

        modelBuilder.Entity<Invoice>(entity =>
        {
            entity.HasKey(e => e.InvoiceId).HasName("PK__INVOICES__F58DFD490B16E25F");

            entity.ToTable("INVOICES");

            entity.HasIndex(e => e.InvoiceNumber, "UQ__INVOICES__8081A63A2087F6B0").IsUnique();

            entity.Property(e => e.InvoiceId).HasColumnName("invoice_id");
            entity.Property(e => e.InvoiceNumber)
                .HasMaxLength(50)
                .IsUnicode(false)
                .HasColumnName("invoice_number");
            entity.Property(e => e.IssuedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime")
                .HasColumnName("issued_at");
            entity.Property(e => e.PdfUrl)
                .HasMaxLength(255)
                .IsUnicode(false)
                .HasColumnName("pdf_url");
            entity.Property(e => e.TaxAmount)
                .HasColumnType("decimal(18, 2)")
                .HasColumnName("tax_amount");
            entity.Property(e => e.TripId).HasColumnName("trip_id");

            entity.HasOne(d => d.Trip).WithMany(p => p.Invoices)
                .HasForeignKey(d => d.TripId)
                .HasConstraintName("FK__INVOICES__trip_i__7E37BEF6");
        });

        modelBuilder.Entity<Notification>(entity =>
        {
            entity.HasKey(e => e.NotiId).HasName("PK__NOTIFICA__FDA4F30AA58EFFCF");

            entity.ToTable("NOTIFICATIONS");

            entity.Property(e => e.NotiId).HasColumnName("noti_id");
            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime")
                .HasColumnName("created_at");
            entity.Property(e => e.IsRead)
                .HasDefaultValue(false)
                .HasColumnName("is_read");
            entity.Property(e => e.Message).HasColumnName("message");
            entity.Property(e => e.Title)
                .HasMaxLength(200)
                .HasColumnName("title");
            entity.Property(e => e.UserId).HasColumnName("user_id");

            entity.HasOne(d => d.User).WithMany(p => p.Notifications)
                .HasForeignKey(d => d.UserId)
                .HasConstraintName("FK__NOTIFICAT__user___05D8E0BE");
        });

        modelBuilder.Entity<Payment>(entity =>
        {
            entity.HasKey(e => e.PaymentId).HasName("PK__PAYMENTS__ED1FC9EA47D6D051");

            entity.ToTable("PAYMENTS");

            entity.Property(e => e.PaymentId).HasColumnName("payment_id");
            entity.Property(e => e.Amount)
                .HasColumnType("decimal(18, 2)")
                .HasColumnName("amount");
            entity.Property(e => e.PaidAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime")
                .HasColumnName("paid_at");
            entity.Property(e => e.PaymentMethod)
                .HasMaxLength(50)
                .HasColumnName("payment_method");
            entity.Property(e => e.Status)
                .HasMaxLength(50)
                .HasColumnName("status");
            entity.Property(e => e.TransactionId)
                .HasMaxLength(100)
                .IsUnicode(false)
                .HasColumnName("transaction_id");
            entity.Property(e => e.TripId).HasColumnName("trip_id");

            entity.HasOne(d => d.Trip).WithMany(p => p.Payments)
                .HasForeignKey(d => d.TripId)
                .HasConstraintName("FK__PAYMENTS__trip_i__73BA3083");
        });

        modelBuilder.Entity<Promotion>(entity =>
        {
            entity.HasKey(e => e.PromoId).HasName("PK__PROMOTIO__84EB4CA59A820481");

            entity.ToTable("PROMOTIONS");

            entity.HasIndex(e => e.Code, "UQ__PROMOTIO__357D4CF99F93BAFB").IsUnique();

            entity.Property(e => e.PromoId).HasColumnName("promo_id");
            entity.Property(e => e.Code)
                .HasMaxLength(50)
                .IsUnicode(false)
                .HasColumnName("code");
            entity.Property(e => e.DiscountPercent).HasColumnName("discount_percent");
            entity.Property(e => e.MaxDiscountAmount)
                .HasColumnType("decimal(18, 2)")
                .HasColumnName("max_discount_amount");
            entity.Property(e => e.UsageLimit).HasColumnName("usage_limit");
            entity.Property(e => e.UsedCount)
                .HasDefaultValue(0)
                .HasColumnName("used_count");
            entity.Property(e => e.ValidUntil)
                .HasColumnType("datetime")
                .HasColumnName("valid_until");
        });

        modelBuilder.Entity<Review>(entity =>
        {
            entity.HasKey(e => e.ReviewId).HasName("PK__REVIEWS__60883D90C9234D4C");

            entity.ToTable("REVIEWS");

            entity.Property(e => e.ReviewId).HasColumnName("review_id");
            entity.Property(e => e.Comment).HasColumnName("comment");
            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime")
                .HasColumnName("created_at");
            entity.Property(e => e.Rating).HasColumnName("rating");
            entity.Property(e => e.TargetId).HasColumnName("target_id");
            entity.Property(e => e.TargetType)
                .HasMaxLength(20)
                .HasColumnName("target_type");
            entity.Property(e => e.TripId).HasColumnName("trip_id");
            entity.Property(e => e.UserId).HasColumnName("user_id");

            entity.HasOne(d => d.Trip).WithMany(p => p.Reviews)
                .HasForeignKey(d => d.TripId)
                .HasConstraintName("FK__REVIEWS__trip_id__787EE5A0");

            entity.HasOne(d => d.User).WithMany(p => p.Reviews)
                .HasForeignKey(d => d.UserId)
                .HasConstraintName("FK__REVIEWS__user_id__778AC167");
        });

        modelBuilder.Entity<Room>(entity =>
        {
            entity.HasKey(e => e.RoomId).HasName("PK__ROOMS__19675A8AA64416C8");

            entity.ToTable("ROOMS");

            entity.Property(e => e.RoomId).HasColumnName("room_id");
            entity.Property(e => e.AvailableQty).HasColumnName("available_qty");
            entity.Property(e => e.Capacity).HasColumnName("capacity");
            entity.Property(e => e.CommissionRate).HasColumnName("commission_rate");
            entity.Property(e => e.HotelId).HasColumnName("hotel_id");
            entity.Property(e => e.PricePerNight)
                .HasColumnType("decimal(18, 2)")
                .HasColumnName("price_per_night");
            entity.Property(e => e.RoomType)
                .HasMaxLength(100)
                .HasColumnName("room_type");

            entity.HasOne(d => d.Hotel).WithMany(p => p.Rooms)
                .HasForeignKey(d => d.HotelId)
                .HasConstraintName("FK__ROOMS__hotel_id__571DF1D5");
        });

        modelBuilder.Entity<Seat>(entity =>
        {
            entity.HasKey(e => e.SeatId).HasName("PK__SEATS__906DED9CE9F241CD");

            entity.ToTable("SEATS");

            entity.Property(e => e.SeatId).HasColumnName("seat_id");
            entity.Property(e => e.ScheduleId).HasColumnName("schedule_id");
            entity.Property(e => e.SeatNumber)
                .HasMaxLength(10)
                .IsUnicode(false)
                .HasColumnName("seat_number");
            entity.Property(e => e.Status)
                .HasMaxLength(20)
                .HasDefaultValue("AVAILABLE")
                .HasColumnName("status");

            entity.HasOne(d => d.Schedule).WithMany(p => p.Seats)
                .HasForeignKey(d => d.ScheduleId)
                .HasConstraintName("FK__SEATS__schedule___60A75C0F");
        });

        modelBuilder.Entity<Trip>(entity =>
        {
            entity.HasKey(e => e.TripId).HasName("PK__TRIPS__302A5D9EA780364F");

            entity.ToTable("TRIPS");

            entity.Property(e => e.TripId).HasColumnName("trip_id");
            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime")
                .HasColumnName("created_at");
            entity.Property(e => e.DestinationId).HasColumnName("destination_id");
            entity.Property(e => e.EndDate).HasColumnName("end_date");
            entity.Property(e => e.StartDate).HasColumnName("start_date");
            entity.Property(e => e.Status)
                .HasMaxLength(50)
                .HasDefaultValue("DRAFT")
                .HasColumnName("status");
            entity.Property(e => e.Title)
                .HasMaxLength(200)
                .HasColumnName("title");
            entity.Property(e => e.TotalAmount)
                .HasDefaultValue(0m)
                .HasColumnType("decimal(18, 2)")
                .HasColumnName("total_amount");
            entity.Property(e => e.TotalProfit)
                .HasDefaultValue(0m)
                .HasColumnType("decimal(18, 2)")
                .HasColumnName("total_profit");
            entity.Property(e => e.UserId).HasColumnName("user_id");

            entity.HasOne(d => d.Destination).WithMany(p => p.Trips)
                .HasForeignKey(d => d.DestinationId)
                .HasConstraintName("FK__TRIPS__destinati__693CA210");

            entity.HasOne(d => d.User).WithMany(p => p.Trips)
                .HasForeignKey(d => d.UserId)
                .HasConstraintName("FK__TRIPS__user_id__68487DD7");
        });

        modelBuilder.Entity<TripItinerary>(entity =>
        {
            entity.HasKey(e => e.ItineraryId).HasName("PK__TRIP_ITI__6E8B21D662A99E3F");

            entity.ToTable("TRIP_ITINERARIES");

            entity.Property(e => e.ItineraryId).HasColumnName("itinerary_id");
            entity.Property(e => e.BookedCommissionRate).HasColumnName("booked_commission_rate");
            entity.Property(e => e.BookedPrice)
                .HasColumnType("decimal(18, 2)")
                .HasColumnName("booked_price");
            entity.Property(e => e.DayNumber).HasColumnName("day_number");
            entity.Property(e => e.Quantity)
                .HasDefaultValue(1)
                .HasColumnName("quantity");
            entity.Property(e => e.ServiceId).HasColumnName("service_id");
            entity.Property(e => e.ServiceType)
                .HasMaxLength(20)
                .HasColumnName("service_type");
            entity.Property(e => e.TripId).HasColumnName("trip_id");

            entity.HasOne(d => d.Trip).WithMany(p => p.TripItineraries)
                .HasForeignKey(d => d.TripId)
                .HasConstraintName("FK__TRIP_ITIN__trip___6FE99F9F");
        });

        modelBuilder.Entity<User>(entity =>
        {
            entity.HasKey(e => e.UserId).HasName("PK__USERS__B9BE370F4DC32CFE");

            entity.ToTable("USERS");

            entity.HasIndex(e => e.Email, "UQ__USERS__AB6E61648136EE68").IsUnique();

            entity.Property(e => e.UserId).HasColumnName("user_id");
            entity.Property(e => e.AuthProvider)
                .HasMaxLength(20)
                .HasDefaultValue("LOCAL")
                .HasColumnName("auth_provider");
            entity.Property(e => e.AvatarUrl)
                .HasMaxLength(255)
                .IsUnicode(false)
                .HasColumnName("avatar_url");
            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime")
                .HasColumnName("created_at");
            entity.Property(e => e.Email)
                .HasMaxLength(100)
                .IsUnicode(false)
                .HasColumnName("email");
            entity.Property(e => e.FullName)
                .HasMaxLength(100)
                .HasColumnName("full_name");
            entity.Property(e => e.IsActive)
                .HasDefaultValue(true)
                .HasColumnName("is_active");
            entity.Property(e => e.PasswordHash)
                .HasMaxLength(255)
                .IsUnicode(false)
                .HasColumnName("password_hash");
            entity.Property(e => e.Phone)
                .HasMaxLength(20)
                .IsUnicode(false)
                .HasColumnName("phone");
            entity.Property(e => e.Role)
                .HasMaxLength(20)
                .HasDefaultValue("USER")
                .HasColumnName("role");
            entity.Property(e => e.SocialId)
                .HasMaxLength(255)
                .IsUnicode(false)
                .HasColumnName("social_id");
        });

        modelBuilder.Entity<UserWallet>(entity =>
        {
            entity.HasKey(e => e.WalletId).HasName("PK__USER_WAL__0EE6F041864A3BEA");

            entity.ToTable("USER_WALLETS");

            entity.Property(e => e.WalletId).HasColumnName("wallet_id");
            entity.Property(e => e.Balance)
                .HasDefaultValue(0m)
                .HasColumnType("decimal(18, 2)")
                .HasColumnName("balance");
            entity.Property(e => e.LoyaltyPoints)
                .HasDefaultValue(0)
                .HasColumnName("loyalty_points");
            entity.Property(e => e.UserId).HasColumnName("user_id");

            entity.HasOne(d => d.User).WithMany(p => p.UserWallets)
                .HasForeignKey(d => d.UserId)
                .HasConstraintName("FK__USER_WALL__user___3E52440B");
        });

        modelBuilder.Entity<Wishlist>(entity =>
        {
            entity.HasKey(e => e.WishId).HasName("PK__WISHLIST__4F227CA0DADDABED");

            entity.ToTable("WISHLISTS");

            entity.Property(e => e.WishId).HasColumnName("wish_id");
            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime")
                .HasColumnName("created_at");
            entity.Property(e => e.ItemId).HasColumnName("item_id");
            entity.Property(e => e.ItemType)
                .HasMaxLength(20)
                .HasColumnName("item_type");
            entity.Property(e => e.UserId).HasColumnName("user_id");

            entity.HasOne(d => d.User).WithMany(p => p.Wishlists)
                .HasForeignKey(d => d.UserId)
                .HasConstraintName("FK__WISHLISTS__user___02084FDA");
        });

        OnModelCreatingPartial(modelBuilder);
    }

    partial void OnModelCreatingPartial(ModelBuilder modelBuilder);
}
