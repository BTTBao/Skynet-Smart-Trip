using Microsoft.EntityFrameworkCore;
using SmartTrip.Domain.Entities;

public interface IApplicationDbContext
{
    DbSet<Amenity> Amenities { get; set; }
    DbSet<BlogPost> BlogPosts { get; set; }
    DbSet<BusCompany> BusCompanies { get; set; }
    DbSet<BusSchedule> BusSchedules { get; set; }
    DbSet<Destination> Destinations { get; set; }
    DbSet<Gallery> Galleries { get; set; }
    DbSet<Hotel> Hotels { get; set; }
    DbSet<Invoice> Invoices { get; set; }
    DbSet<Notification> Notifications { get; set; }
    DbSet<Payment> Payments { get; set; }
    DbSet<Promotion> Promotions { get; set; }
    DbSet<Review> Reviews { get; set; }
    DbSet<Room> Rooms { get; set; }
    DbSet<Seat> Seats { get; set; }
    DbSet<SmartTrip.Domain.Entities.Trip> Trips { get; set; }
    DbSet<TripItinerary> TripItineraries { get; set; }
    DbSet<SmartTrip.Domain.Entities.User> Users { get; set; }
    DbSet<UserWallet> UserWallets { get; set; }
    DbSet<Wishlist> Wishlists { get; set; }

    Task<int> SaveChangesAsync(CancellationToken cancellationToken = default);
}
