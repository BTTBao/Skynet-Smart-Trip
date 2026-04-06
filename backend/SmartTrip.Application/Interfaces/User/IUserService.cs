using SmartTrip.Application.DTOs.User;

namespace SmartTrip.Application.Interfaces.User;

public interface IUserService
{
    Task<UserDto?> GetUserProfileAsync(int userId);
    Task<ActivityHistoryDto?> GetActivityHistoryAsync(int userId);
    Task<bool> UpdateUserProfileAsync(int userId, UpdateUserProfileRequestDto request);
    Task<string?> UploadAvatarAsync(int userId, Microsoft.AspNetCore.Http.IFormFile file);
    Task<List<UserFavoriteDto>> GetFavoritesAsync(int userId);
    Task<UserFavoriteDto?> AddFavoriteAsync(int userId, CreateFavoriteRequestDto request);
    Task<bool> RemoveFavoriteAsync(int userId, int wishId);
    Task<UserSettingsDto?> GetUserSettingsAsync(int userId);
    Task<UserSettingsDto?> UpdateUserSettingsAsync(int userId, UpdateUserSettingsDto request);
    Task<UserActionResultDto> ChangePasswordAsync(int userId, ChangePasswordRequestDto request);
}
