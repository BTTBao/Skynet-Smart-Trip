using Microsoft.EntityFrameworkCore;
using SmartTrip.Application.Interfaces;
using SmartTrip.Domain.Entities;

public partial class ApplicationDbContext : DbContext, IApplicationDbContext
{
    public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options)
        : base(options)
    {
    }

    public virtual DbSet<Amenity> Amenities { get; set; }
    public virtual DbSet<BlogPost> BlogPosts { get; set; }
    public virtual DbSet<BusCompany> BusCompanies { get; set; }
    public virtual DbSet<BusSchedule> BusSchedules { get; set; }
    public virtual DbSet<Destination> Destinations { get; set; }
    public virtual DbSet<ExplorePost> ExplorePosts { get; set; }
    public virtual DbSet<ExplorePostImage> ExplorePostImages { get; set; }
    public virtual DbSet<ExplorePostLike> ExplorePostLikes { get; set; }
    public virtual DbSet<ExplorePostSave> ExplorePostSaves { get; set; }
    public virtual DbSet<ExplorePostRating> ExplorePostRatings { get; set; }
    public virtual DbSet<ExploreComment> ExploreComments { get; set; }
    public virtual DbSet<Gallery> Galleries { get; set; }
    public virtual DbSet<Hotel> Hotels { get; set; }
    public virtual DbSet<Invoice> Invoices { get; set; }
    public virtual DbSet<Notification> Notifications { get; set; }
    public virtual DbSet<UserFcmToken> UserFcmTokens { get; set; }
    public virtual DbSet<Payment> Payments { get; set; }
    public virtual DbSet<Promotion> Promotions { get; set; }
    public virtual DbSet<Review> Reviews { get; set; }
    public virtual DbSet<Room> Rooms { get; set; }
    public virtual DbSet<Seat> Seats { get; set; }
    public virtual DbSet<Trip> Trips { get; set; }
    public virtual DbSet<TripItinerary> TripItineraries { get; set; }
    public virtual DbSet<User> Users { get; set; }
    public virtual DbSet<UserWallet> UserWallets { get; set; }
    public virtual DbSet<VehicleRentalOption> VehicleRentalOptions { get; set; }
    public virtual DbSet<VehicleRentalShop> VehicleRentalShops { get; set; }
    public virtual DbSet<Wishlist> Wishlists { get; set; }
    public virtual DbSet<ChatHistory> ChatHistories { get; set; }
    public virtual DbSet<UserPreference> UserPreferences { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Amenity>(entity =>
        {
            entity.Property(e => e.IconUrl).HasMaxLength(255).IsUnicode(false);
            entity.Property(e => e.Name).HasMaxLength(100);
        });

        modelBuilder.Entity<BlogPost>(entity =>
        {
            entity.Property(e => e.PublishedAt).HasDefaultValueSql("GETDATE()").HasColumnType("datetime");
            entity.Property(e => e.ThumbnailUrl).HasMaxLength(255).IsUnicode(false);
            entity.Property(e => e.Title).HasMaxLength(255);

            entity.HasOne(d => d.Author).WithMany(p => p.BlogPosts).HasForeignKey(d => d.AuthorId);
            entity.HasOne(d => d.Destination).WithMany(p => p.BlogPosts).HasForeignKey(d => d.DestinationId);
        });

        modelBuilder.Entity<BusCompany>(entity =>
        {
            entity.Property(e => e.Hotline).HasMaxLength(20).IsUnicode(false);
            entity.Property(e => e.LogoUrl).HasMaxLength(255).IsUnicode(false);
            entity.Property(e => e.Name).HasMaxLength(100);
        });

        modelBuilder.Entity<BusSchedule>(entity =>
        {
            entity.Property(e => e.ArrivalTime).HasColumnType("datetime");
            entity.Property(e => e.DepartureTime).HasColumnType("datetime");
            entity.Property(e => e.Price).HasColumnType("decimal(18, 2)");

            entity.HasOne(d => d.Company).WithMany(p => p.BusSchedules).HasForeignKey(d => d.CompanyId);
            entity.HasOne(d => d.FromDest).WithMany(p => p.BusScheduleFromDests).HasForeignKey(d => d.FromDestId);
            entity.HasOne(d => d.ToDest).WithMany(p => p.BusScheduleToDests).HasForeignKey(d => d.ToDestId);
        });

        modelBuilder.Entity<Destination>(entity =>
        {
            entity.Property(e => e.CoverImageUrl).HasMaxLength(255).IsUnicode(false);
            entity.Property(e => e.IsHot).HasDefaultValue(false);
            entity.Property(e => e.Name).HasMaxLength(100);
        });

        modelBuilder.Entity<ExplorePost>(entity =>
        {
            entity.Property(e => e.Title).HasMaxLength(200).IsRequired();
            entity.Property(e => e.Excerpt).HasMaxLength(500).IsRequired();
            entity.Property(e => e.Content).IsRequired();
            entity.Property(e => e.ThumbnailUrl).HasMaxLength(500).IsUnicode(false);
            entity.Property(e => e.Location).HasMaxLength(120).IsRequired();
            entity.Property(e => e.CitySlug).HasMaxLength(80).IsUnicode(false).IsRequired();
            entity.Property(e => e.Province).HasMaxLength(120).IsRequired();
            entity.Property(e => e.Region).HasMaxLength(20).IsUnicode(false).IsRequired();
            entity.Property(e => e.Latitude);
            entity.Property(e => e.Longitude);
            entity.Property(e => e.CostLevel).HasDefaultValue(2);
            entity.Property(e => e.AverageRating).HasDefaultValue(0m).HasColumnType("decimal(3, 2)");
            entity.Property(e => e.RatingCount).HasDefaultValue(0);
            entity.Property(e => e.ViewCount).HasDefaultValue(0);
            entity.Property(e => e.IsVisible).HasDefaultValue(true);
            entity.Property(e => e.Tags).HasMaxLength(500);
            entity.Property(e => e.CreatedAt).HasDefaultValueSql("GETDATE()").HasColumnType("datetime");
            entity.Property(e => e.UpdatedAt).HasColumnType("datetime");

            entity.HasIndex(e => e.CreatedAt);
            entity.HasIndex(e => e.Province);
            entity.HasIndex(e => e.Region);
            entity.HasIndex(e => e.CitySlug);
            entity.HasIndex(e => e.CostLevel);
            entity.HasIndex(e => e.AverageRating);
            entity.HasIndex(e => e.ViewCount);
            entity.HasIndex(e => e.IsVisible);

            entity.HasOne(e => e.Author)
                .WithMany(u => u.ExplorePosts)
                .HasForeignKey(e => e.AuthorId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        modelBuilder.Entity<ExplorePostImage>(entity =>
        {
            entity.Property(e => e.ImageUrl).HasMaxLength(500).IsUnicode(false).IsRequired();
            entity.Property(e => e.SortOrder).HasDefaultValue(0);

            entity.HasIndex(e => new { e.ExplorePostId, e.SortOrder });

            entity.HasOne(e => e.ExplorePost)
                .WithMany(p => p.Images)
                .HasForeignKey(e => e.ExplorePostId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<ExplorePostLike>(entity =>
        {
            entity.Property(e => e.CreatedAt).HasDefaultValueSql("GETDATE()").HasColumnType("datetime");
            entity.HasIndex(e => new { e.UserId, e.ExplorePostId }).IsUnique();

            entity.HasOne(e => e.ExplorePost)
                .WithMany(p => p.Likes)
                .HasForeignKey(e => e.ExplorePostId)
                .OnDelete(DeleteBehavior.Cascade);
            entity.HasOne(e => e.User)
                .WithMany(u => u.ExplorePostLikes)
                .HasForeignKey(e => e.UserId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        modelBuilder.Entity<ExplorePostSave>(entity =>
        {
            entity.Property(e => e.CreatedAt).HasDefaultValueSql("GETDATE()").HasColumnType("datetime");
            entity.HasIndex(e => new { e.UserId, e.ExplorePostId }).IsUnique();

            entity.HasOne(e => e.ExplorePost)
                .WithMany(p => p.Saves)
                .HasForeignKey(e => e.ExplorePostId)
                .OnDelete(DeleteBehavior.Cascade);
            entity.HasOne(e => e.User)
                .WithMany(u => u.ExplorePostSaves)
                .HasForeignKey(e => e.UserId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        modelBuilder.Entity<ExplorePostRating>(entity =>
        {
            entity.Property(e => e.Rating).HasColumnType("decimal(3, 2)");
            entity.Property(e => e.CreatedAt).HasDefaultValueSql("GETDATE()").HasColumnType("datetime");
            entity.Property(e => e.UpdatedAt).HasColumnType("datetime");
            entity.HasIndex(e => new { e.UserId, e.ExplorePostId }).IsUnique();

            entity.HasOne(e => e.ExplorePost)
                .WithMany(p => p.Ratings)
                .HasForeignKey(e => e.ExplorePostId)
                .OnDelete(DeleteBehavior.Cascade);
            entity.HasOne(e => e.User)
                .WithMany(u => u.ExplorePostRatings)
                .HasForeignKey(e => e.UserId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        modelBuilder.Entity<ExploreComment>(entity =>
        {
            entity.Property(e => e.Content).HasMaxLength(1000).IsRequired();
            entity.Property(e => e.LikeCount).HasDefaultValue(0);
            entity.Property(e => e.CreatedAt).HasDefaultValueSql("GETDATE()").HasColumnType("datetime");
            entity.HasIndex(e => new { e.ExplorePostId, e.CreatedAt });
            entity.HasIndex(e => e.ParentCommentId);

            entity.HasOne(e => e.ExplorePost)
                .WithMany(p => p.Comments)
                .HasForeignKey(e => e.ExplorePostId)
                .OnDelete(DeleteBehavior.Cascade);
            entity.HasOne(e => e.ParentComment)
                .WithMany(e => e.Replies)
                .HasForeignKey(e => e.ParentCommentId)
                .OnDelete(DeleteBehavior.Restrict);
            entity.HasOne(e => e.User)
                .WithMany(u => u.ExploreComments)
                .HasForeignKey(e => e.UserId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        modelBuilder.Entity<Gallery>(entity =>
        {
            entity.Property(e => e.ImageUrl).HasMaxLength(255).IsUnicode(false);
            entity.Property(e => e.ReferenceType).HasMaxLength(50);
        });

        modelBuilder.Entity<Hotel>(entity =>
        {
            entity.Property(e => e.Address).HasMaxLength(255);
            entity.Property(e => e.IsAvailable).HasDefaultValue(true);
            entity.Property(e => e.Name).HasMaxLength(200);

            entity.HasOne(d => d.Destination).WithMany(p => p.Hotels).HasForeignKey(d => d.DestinationId);

            entity.HasMany(d => d.Amenities).WithMany(p => p.Hotels)
                .UsingEntity<Dictionary<string, object>>(
                    "HotelAmenityMapping",
                    r => r.HasOne<Amenity>().WithMany().HasForeignKey("AmenityId").OnDelete(DeleteBehavior.ClientSetNull),
                    l => l.HasOne<Hotel>().WithMany().HasForeignKey("HotelId").OnDelete(DeleteBehavior.ClientSetNull),
                    j => j.HasKey("HotelId", "AmenityId")
                );
        });

        modelBuilder.Entity<Invoice>(entity =>
        {
            entity.HasIndex(e => e.InvoiceNumber).IsUnique();
            entity.Property(e => e.InvoiceNumber).HasMaxLength(50).IsUnicode(false);
            entity.Property(e => e.IssuedAt).HasDefaultValueSql("GETDATE()").HasColumnType("datetime");
            entity.Property(e => e.PdfUrl).HasMaxLength(255).IsUnicode(false);
            entity.Property(e => e.TaxAmount).HasColumnType("decimal(18, 2)");

            entity.HasOne(d => d.Trip).WithMany(p => p.Invoices).HasForeignKey(d => d.TripId);
        });

        modelBuilder.Entity<Notification>(entity =>
        {
            entity.Property(e => e.ActionUrl).HasMaxLength(255);
            entity.Property(e => e.CreatedAt).HasDefaultValueSql("GETDATE()").HasColumnType("datetime");
            entity.Property(e => e.IsRead).HasDefaultValue(false);
            entity.Property(e => e.ReferenceType).HasMaxLength(50).IsUnicode(false);
            entity.Property(e => e.Title).HasMaxLength(200);
            entity.Property(e => e.Type).HasMaxLength(80).IsUnicode(false);

            entity.HasOne(d => d.User).WithMany(p => p.Notifications).HasForeignKey(d => d.UserId);
        });

        modelBuilder.Entity<UserFcmToken>(entity =>
        {
            entity.Property(e => e.Token).HasMaxLength(512).IsUnicode(false).IsRequired();
            entity.Property(e => e.Platform).HasMaxLength(30).IsUnicode(false).IsRequired();
            entity.Property(e => e.DeviceId).HasMaxLength(120).IsUnicode(false);
            entity.Property(e => e.CreatedAt).HasDefaultValueSql("GETDATE()").HasColumnType("datetime");
            entity.Property(e => e.UpdatedAt).HasDefaultValueSql("GETDATE()").HasColumnType("datetime");
            entity.Property(e => e.LastUsedAt).HasColumnType("datetime");
            entity.Property(e => e.IsActive).HasDefaultValue(true);

            entity.HasIndex(e => e.Token).IsUnique();
            entity.HasIndex(e => new { e.UserId, e.IsActive });

            entity.HasOne(e => e.User)
                .WithMany(u => u.FcmTokens)
                .HasForeignKey(e => e.UserId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<Payment>(entity =>
        {
            entity.Property(e => e.Amount).HasColumnType("decimal(18, 2)");
            entity.Property(e => e.CancelUrl).HasMaxLength(2048).IsUnicode(false);
            entity.Property(e => e.CheckoutUrl).HasMaxLength(2048).IsUnicode(false);
            entity.Property(e => e.CreatedAt).HasDefaultValueSql("GETDATE()").HasColumnType("datetime");
            entity.Property(e => e.Description).HasMaxLength(255);
            entity.Property(e => e.MetadataJson).HasColumnType("nvarchar(max)");
            entity.Property(e => e.OrderCode).IsRequired(false);
            entity.Property(e => e.PaidAt).HasColumnType("datetime");
            entity.Property(e => e.PaymentLinkId).HasMaxLength(100).IsUnicode(false);
            entity.Property(e => e.PaymentMethod).HasMaxLength(50);
            entity.Property(e => e.QrCode).HasColumnType("nvarchar(max)");
            entity.Property(e => e.RawResponseJson).HasColumnType("nvarchar(max)");
            entity.Property(e => e.ReturnUrl).HasMaxLength(2048).IsUnicode(false);
            entity.Property(e => e.Status).HasMaxLength(50);
            entity.Property(e => e.TransactionId).HasMaxLength(100).IsUnicode(false);
            entity.Property(e => e.UpdatedAt).HasColumnType("datetime");

            entity.HasIndex(e => e.OrderCode).IsUnique().HasFilter("[OrderCode] IS NOT NULL");

            entity.HasOne(d => d.Trip).WithMany(p => p.Payments).HasForeignKey(d => d.TripId);
        });

        modelBuilder.Entity<Promotion>(entity =>
        {
            entity.HasIndex(e => e.Code).IsUnique();
            entity.Property(e => e.Code).HasMaxLength(50).IsUnicode(false);
            entity.Property(e => e.MaxDiscountAmount).HasColumnType("decimal(18, 2)");
            entity.Property(e => e.UsedCount).HasDefaultValue(0);
            entity.Property(e => e.ValidUntil).HasColumnType("datetime");
        });

        modelBuilder.Entity<Review>(entity =>
        {
            entity.Property(e => e.CreatedAt).HasDefaultValueSql("GETDATE()").HasColumnType("datetime");
            entity.Property(e => e.TargetType).HasMaxLength(20);

            entity.HasOne(d => d.Trip).WithMany(p => p.Reviews).HasForeignKey(d => d.TripId);
            entity.HasOne(d => d.User).WithMany(p => p.Reviews).HasForeignKey(d => d.UserId);
        });

        modelBuilder.Entity<Room>(entity =>
        {
            entity.Property(e => e.PricePerNight).HasColumnType("decimal(18, 2)");
            entity.Property(e => e.RoomType).HasMaxLength(100);

            entity.HasOne(d => d.Hotel).WithMany(p => p.Rooms).HasForeignKey(d => d.HotelId);
        });

        modelBuilder.Entity<Seat>(entity =>
        {
            entity.Property(e => e.SeatNumber).HasMaxLength(10).IsUnicode(false);
            entity.Property(e => e.Status).HasMaxLength(20).HasConversion<string>().HasDefaultValue(SmartTrip.Domain.Enums.SeatStatus.Available);

            entity.HasOne(d => d.Schedule).WithMany(p => p.Seats).HasForeignKey(d => d.ScheduleId);
        });

        modelBuilder.Entity<Trip>(entity =>
        {
            entity.Property(e => e.CreatedAt).HasDefaultValueSql("GETDATE()").HasColumnType("datetime");
            entity.Property(e => e.ShareCode).HasMaxLength(20).IsUnicode(false);
            entity.Property(e => e.Status).HasMaxLength(50).HasConversion<string>().HasDefaultValue(SmartTrip.Domain.Enums.TripStatus.Draft);
            entity.Property(e => e.Title).HasMaxLength(200);
            entity.Property(e => e.TotalAmount).HasDefaultValue(0m).HasColumnType("decimal(18, 2)");
            entity.Property(e => e.TotalProfit).HasDefaultValue(0m).HasColumnType("decimal(18, 2)");
            entity.HasIndex(e => new { e.UserId, e.ShareCode }).IsUnique().HasFilter("[ShareCode] IS NOT NULL AND [UserId] IS NOT NULL");
            entity.HasIndex(e => new { e.UserId, e.SharedFromTripId }).IsUnique().HasFilter("[SharedFromTripId] IS NOT NULL");

            entity.HasOne(d => d.Destination).WithMany(p => p.Trips).HasForeignKey(d => d.DestinationId);
            entity.HasOne(d => d.SharedFromTrip).WithMany(p => p.SharedTrips).HasForeignKey(d => d.SharedFromTripId).OnDelete(DeleteBehavior.Restrict);
            entity.HasOne(d => d.User).WithMany(p => p.Trips).HasForeignKey(d => d.UserId);
        });

        modelBuilder.Entity<TripItinerary>(entity =>
        {
            entity.Property(e => e.BookedPrice).HasColumnType("decimal(18, 2)");
            entity.Property(e => e.DepartureTime).HasColumnType("time");
            entity.Property(e => e.Quantity).HasDefaultValue(1);
            entity.Property(e => e.AdultCount).HasDefaultValue(1);
            entity.Property(e => e.ChildCount).HasDefaultValue(0);
            entity.Property(e => e.InfantCount).HasDefaultValue(0);
            entity.Property(e => e.ServiceAddress).HasMaxLength(500);
            entity.Property(e => e.ServiceDate).HasColumnType("date");
            entity.Property(e => e.HotelCheckOutDate).HasColumnType("date");
            entity.Property(e => e.ServiceType).HasMaxLength(20);

            entity.HasOne(d => d.Trip).WithMany(p => p.TripItineraries).HasForeignKey(d => d.TripId);
        });

        modelBuilder.Entity<User>(entity =>
        {
            entity.HasIndex(e => e.Email).IsUnique();
            entity.HasIndex(e => e.UserName).IsUnique().HasFilter("[UserName] IS NOT NULL");
            entity.HasIndex(e => e.IdentityNumber).IsUnique().HasFilter("[IdentityNumber] IS NOT NULL");
            entity.Property(e => e.AuthProvider).HasMaxLength(20).HasConversion<string>().HasDefaultValue(SmartTrip.Domain.Enums.AuthProvider.Local);
            entity.Property(e => e.AvatarUrl).HasMaxLength(255).IsUnicode(false);
            entity.Property(e => e.BirthDate).HasColumnType("date");
            entity.Property(e => e.IdentityNumber).HasMaxLength(20).IsUnicode(false);
            entity.Property(e => e.IdentityCardPhotoUrl).HasMaxLength(500).IsUnicode(false);
            entity.Property(e => e.CreatedAt).HasDefaultValueSql("GETDATE()").HasColumnType("datetime");
            entity.Property(e => e.Email).HasMaxLength(100).IsUnicode(false);
            entity.Property(e => e.FullName).HasMaxLength(100);
            entity.Property(e => e.IsActive).HasDefaultValue(true);
            entity.Property(e => e.PasswordHash).HasMaxLength(255).IsUnicode(false);
            entity.Property(e => e.Phone).HasMaxLength(20).IsUnicode(false);
            entity.Property(e => e.Role).HasMaxLength(20).HasConversion<string>().HasDefaultValue(SmartTrip.Domain.Enums.UserRole.User);
            entity.Property(e => e.SocialId).HasMaxLength(255).IsUnicode(false);
            entity.Property(e => e.UserName).HasMaxLength(50).IsUnicode(false);
        });

        modelBuilder.Entity<UserWallet>(entity =>
        {
            entity.Property(e => e.Balance).HasDefaultValue(0m).HasColumnType("decimal(18, 2)");
            entity.Property(e => e.LoyaltyPoints).HasDefaultValue(0);

            entity.HasOne(d => d.User).WithMany(p => p.UserWallets).HasForeignKey(d => d.UserId);
        });

        modelBuilder.Entity<VehicleRentalShop>(entity =>
        {
            entity.Property(e => e.Name).HasMaxLength(200).IsRequired();
            entity.Property(e => e.PhoneNumber).HasMaxLength(20).IsUnicode(false).IsRequired();
            entity.Property(e => e.Address).HasMaxLength(500).IsRequired();
            entity.Property(e => e.Description).HasMaxLength(1000);
            entity.Property(e => e.ImageUrl).HasMaxLength(500).IsUnicode(false);
            entity.Property(e => e.IsActive).HasDefaultValue(true);
            entity.Property(e => e.MonthlyAgreementFee).HasColumnType("decimal(18, 2)").HasDefaultValue(0m);
            entity.Property(e => e.IsMonthlyFeePaid).HasDefaultValue(false);
            entity.Property(e => e.MonthlyFeePaidAt).HasColumnType("datetime");
            entity.Property(e => e.IsDeleted).HasDefaultValue(false);
            entity.Property(e => e.DeletedAt).HasColumnType("datetime");
            entity.Property(e => e.CreatedAt).HasDefaultValueSql("GETDATE()").HasColumnType("datetime");

            entity.HasIndex(e => e.DestinationId);
            entity.HasIndex(e => e.IsActive);
            entity.HasIndex(e => e.IsDeleted);

            entity.HasOne(e => e.Destination)
                .WithMany(d => d.VehicleRentalShops)
                .HasForeignKey(e => e.DestinationId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        modelBuilder.Entity<VehicleRentalOption>(entity =>
        {
            entity.Property(e => e.VehicleType).HasMaxLength(30).HasConversion<string>();
            entity.Property(e => e.PricePerDay).HasColumnType("decimal(18, 2)");
            entity.Property(e => e.IsAvailable).HasDefaultValue(true);

            entity.HasIndex(e => e.VehicleRentalShopId);
            entity.HasIndex(e => e.VehicleType);

            entity.HasOne(e => e.VehicleRentalShop)
                .WithMany(s => s.VehicleOptions)
                .HasForeignKey(e => e.VehicleRentalShopId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<Wishlist>(entity =>
        {
            entity.HasKey(e => e.WishId);
            entity.Property(e => e.CreatedAt).HasDefaultValueSql("GETDATE()").HasColumnType("datetime");
            entity.Property(e => e.ItemType).HasMaxLength(20);

            entity.HasOne(d => d.User).WithMany(p => p.Wishlists).HasForeignKey(d => d.UserId);
        });

        modelBuilder.Entity<ChatHistory>(entity =>
        {
            entity.Property(e => e.CreatedAt).HasDefaultValueSql("GETDATE()").HasColumnType("datetime");
            entity.Property(e => e.UserMessage).IsRequired();
            entity.Property(e => e.BotResponse).IsRequired();
            entity.Property(e => e.ResponseType).HasMaxLength(50);
            entity.Property(e => e.DetectedIntent).HasMaxLength(50);
            entity.Property(e => e.SessionId).HasMaxLength(100).IsUnicode(false);

            entity.HasOne(d => d.User).WithMany().HasForeignKey(d => d.UserId);
        });

        modelBuilder.Entity<UserPreference>(entity =>
        {
            entity.Property(e => e.PreferenceKey).HasMaxLength(100).IsRequired();
            entity.Property(e => e.PreferenceValue).HasMaxLength(500).IsRequired();
            entity.Property(e => e.UpdatedAt).HasDefaultValueSql("GETDATE()").HasColumnType("datetime");

            entity.HasOne(d => d.User).WithMany().HasForeignKey(d => d.UserId);

            entity.HasIndex(e => new { e.UserId, e.PreferenceKey }).IsUnique();
        });
    }
}
