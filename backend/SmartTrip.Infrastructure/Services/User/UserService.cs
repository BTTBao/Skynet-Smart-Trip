using SmartTrip.Application.DTOs.User;
using SmartTrip.Application.Interfaces.User;
using SmartTrip.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;

namespace SmartTrip.Infrastructure.Services.User;

public class UserService : IUserService
{
    private readonly ApplicationDbContext _context;
    private readonly IWebHostEnvironment _environment;
    private readonly IHttpContextAccessor _httpContextAccessor;

    public UserService(ApplicationDbContext context, IWebHostEnvironment environment, IHttpContextAccessor httpContextAccessor)
    {
        _context = context;
        _environment = environment;
        _httpContextAccessor = httpContextAccessor;
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
            MemberTier = "Gold Member",
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

    public async Task<string?> UploadAvatarAsync(int userId, IFormFile file)
    {
        var user = await _context.Users.FindAsync(userId);
        if (user == null) return null;

        string wwwRootPath = _environment.WebRootPath;
        if (string.IsNullOrEmpty(wwwRootPath)) 
        {
            wwwRootPath = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot");
        }

        string fileName = $"avatar_{userId}_{DateTime.Now.Ticks}{Path.GetExtension(file.FileName)}";
        string filePath = Path.Combine(wwwRootPath, "uploads", "avatars", fileName);

        // Đảm bảo thư mục tồn tại
        Directory.CreateDirectory(Path.GetDirectoryName(filePath)!);

        using (var fileStream = new FileStream(filePath, FileMode.Create))
        {
            await file.CopyToAsync(fileStream);
        }

        // Tạo URL đầy đủ
        var request = _httpContextAccessor.HttpContext?.Request;
        string baseUrl = $"{request?.Scheme}://{request?.Host}{request?.PathBase}";
        string avatarUrl = $"{baseUrl}/uploads/avatars/{fileName}";

        // Cập nhật DB
        user.AvatarUrl = avatarUrl;
        await _context.SaveChangesAsync();

        return avatarUrl;
    }
}
