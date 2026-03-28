<<<<<<< Updated upstream
=======
using System;
using System.Collections.Generic;
using Microsoft.EntityFrameworkCore;

>>>>>>> Stashed changes
namespace SmartTrip.Domain.Entities;

using Microsoft.EntityFrameworkCore;

public partial class ApplicationDbContext : DbContext
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

<<<<<<< Updated upstream
=======
    protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
#warning To protect potentially sensitive information in your connection string, you should move it out of source code. You can avoid scaffolding the connection string by using the Name= syntax to read it from configuration - see https://go.microsoft.com/fwlink/?linkid=2131148. For more guidance on storing connection strings, see https://go.microsoft.com/fwlink/?LinkId=723263.
        => optionsBuilder.UseSqlServer("Server=MYLOVE\\SQLEXPRESS;Database=SkynetSmartTrip;Trusted_Connection=True;TrustServerCertificate=True;");

>>>>>>> Stashed changes
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
            entity.Property(e => e.CreatedAt).HasDefaultValueSql("GETDATE()").HasColumnType("datetime");
            entity.Property(e => e.IsRead).HasDefaultValue(false);
            entity.Property(e => e.Title).HasMaxLength(200);

            entity.HasOne(d => d.User).WithMany(p => p.Notifications).HasForeignKey(d => d.UserId);
        });

        modelBuilder.Entity<Payment>(entity =>
        {
            entity.Property(e => e.Amount).HasColumnType("decimal(18, 2)");
            entity.Property(e => e.PaidAt).HasDefaultValueSql("GETDATE()").HasColumnType("datetime");
            entity.Property(e => e.PaymentMethod).HasMaxLength(50);
            entity.Property(e => e.Status).HasMaxLength(50);
            entity.Property(e => e.TransactionId).HasMaxLength(100).IsUnicode(false);

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
            entity.Property(e => e.Status).HasMaxLength(50).HasConversion<string>().HasDefaultValue(SmartTrip.Domain.Enums.TripStatus.Draft);
            entity.Property(e => e.Title).HasMaxLength(200);
            entity.Property(e => e.TotalAmount).HasDefaultValue(0m).HasColumnType("decimal(18, 2)");
            entity.Property(e => e.TotalProfit).HasDefaultValue(0m).HasColumnType("decimal(18, 2)");

            entity.HasOne(d => d.Destination).WithMany(p => p.Trips).HasForeignKey(d => d.DestinationId);
            entity.HasOne(d => d.User).WithMany(p => p.Trips).HasForeignKey(d => d.UserId);
        });

        modelBuilder.Entity<TripItinerary>(entity =>
        {
            entity.Property(e => e.BookedPrice).HasColumnType("decimal(18, 2)");
            entity.Property(e => e.Quantity).HasDefaultValue(1);
            entity.Property(e => e.ServiceType).HasMaxLength(20);

            entity.HasOne(d => d.Trip).WithMany(p => p.TripItineraries).HasForeignKey(d => d.TripId);
        });

        modelBuilder.Entity<User>(entity =>
        {
            entity.HasIndex(e => e.Email).IsUnique();
            entity.Property(e => e.AuthProvider).HasMaxLength(20).HasConversion<string>().HasDefaultValue(SmartTrip.Domain.Enums.AuthProvider.Local);
            entity.Property(e => e.AvatarUrl).HasMaxLength(255).IsUnicode(false);
            entity.Property(e => e.CreatedAt).HasDefaultValueSql("GETDATE()").HasColumnType("datetime");
            entity.Property(e => e.Email).HasMaxLength(100).IsUnicode(false);
            entity.Property(e => e.FullName).HasMaxLength(100);
            entity.Property(e => e.IsActive).HasDefaultValue(true);
            entity.Property(e => e.PasswordHash).HasMaxLength(255).IsUnicode(false);
            entity.Property(e => e.Phone).HasMaxLength(20).IsUnicode(false);
            entity.Property(e => e.Role).HasMaxLength(20).HasConversion<string>().HasDefaultValue(SmartTrip.Domain.Enums.UserRole.User);
            entity.Property(e => e.SocialId).HasMaxLength(255).IsUnicode(false);
        });

        modelBuilder.Entity<UserWallet>(entity =>
        {
            entity.Property(e => e.Balance).HasDefaultValue(0m).HasColumnType("decimal(18, 2)");
            entity.Property(e => e.LoyaltyPoints).HasDefaultValue(0);

            entity.HasOne(d => d.User).WithMany(p => p.UserWallets).HasForeignKey(d => d.UserId);
        });

        modelBuilder.Entity<Wishlist>(entity =>
        {
            entity.HasKey(e => e.WishId);
            entity.Property(e => e.CreatedAt).HasDefaultValueSql("GETDATE()").HasColumnType("datetime");
            entity.Property(e => e.ItemType).HasMaxLength(20);

            entity.HasOne(d => d.User).WithMany(p => p.Wishlists).HasForeignKey(d => d.UserId);
        });
    }
}