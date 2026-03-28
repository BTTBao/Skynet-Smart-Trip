using SmartTrip.Application.DTOs.User;
using SmartTrip.Application.Interfaces.User;

namespace SmartTrip.Application.Services;

public class UserService : IUserService
{
    public Task<UserDto?> GetUserProfileAsync(int userId)
    {
        return Task.FromResult<UserDto?>(null);
    }

    public Task<bool> UpdateUserProfileAsync(int userId, UserDto userDto)
    {
        return Task.FromResult(false);
    }
}
