using SmartTrip.Application.DTOs.User;

namespace SmartTrip.Application.Interfaces.User;

public interface IUserService
{
    Task<UserDto?> GetUserProfileAsync(int userId);
    Task<bool> UpdateUserProfileAsync(int userId, UserDto userDto);
}
