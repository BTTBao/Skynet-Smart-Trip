using SmartTrip.Application.DTOs.User;
using SmartTrip.Application.Interfaces.User;
using SmartTrip.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace SmartTrip.Application.Services.User;

public class UserService : IUserService
{
    private readonly ApplicationDbContext _context;

    public UserService(ApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<UserDto?> GetUserProfileAsync(int userId)
    {
        var user = await _context.Users.FindAsync(userId);
        if (user == null) return null;

        return new UserDto
        {
            UserId = user.UserId,
            Name = user.FullName ?? "",
            Email = user.Email,
            Phone = user.Phone,
            AvatarUrl = user.AvatarUrl,
            MemberTier = "Gold Member", // Quy tắc tính tier có thể thêm sau
            TripsCount = 12,
            Coins = 450,
            Vouchers = 15
        };
    }

    public async Task<bool> UpdateUserProfileAsync(int userId, UserDto userDto)
    {
        var user = await _context.Users.FindAsync(userId);
        if (user == null) return false;

        user.FullName = userDto.Name;
        user.Phone = userDto.Phone;
        user.AvatarUrl = userDto.AvatarUrl;

        await _context.SaveChangesAsync();
        return true;
    }
}
