using SmartTrip.Domain.Enums;
using System;
using System.Collections.Generic;

namespace SmartTrip.Domain.Entities;

public class User
{
    public int Id { get; set; }

    public string Email { get; set; } = null!;

    public string? UserName { get; set; }

    public string? PasswordHash { get; set; }

    public string? FullName { get; set; }

    public string? Phone { get; set; }

    public string? AvatarUrl { get; set; }

    public DateTime? BirthDate { get; set; }

    public AuthProvider? AuthProvider { get; set; }

    public string? SocialId { get; set; }

    public UserRole? Role { get; set; }

    public bool? IsActive { get; set; }

    public bool IsEmailVerified { get; set; } = false;

    public string? EmailVerificationToken { get; set; }

    public DateTime? EmailVerificationTokenExpiry { get; set; }

    public string? PasswordResetToken { get; set; }

    public DateTime? PasswordResetTokenExpiry { get; set; }

    public string? RefreshToken { get; set; }

    public DateTime? RefreshTokenExpiry { get; set; }

    public DateTime? LastLoginAt { get; set; }

    public DateTime? CreatedAt { get; set; }

    public virtual ICollection<BlogPost> BlogPosts { get; set; } = new List<BlogPost>();

    public virtual ICollection<Notification> Notifications { get; set; } = new List<Notification>();

    public virtual ICollection<Review> Reviews { get; set; } = new List<Review>();

    public virtual ICollection<Trip> Trips { get; set; } = new List<Trip>();

    public virtual ICollection<UserWallet> UserWallets { get; set; } = new List<UserWallet>();

    public virtual ICollection<Wishlist> Wishlists { get; set; } = new List<Wishlist>();
}
