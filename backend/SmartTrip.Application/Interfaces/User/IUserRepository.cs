using SmartTrip.Domain.Entities;

namespace SmartTrip.Application.Interfaces.User
{
    public interface IUserRepository
    {
        Task<Domain.Entities.User?> GetUserByEmailAsync(string email);
        Task<Domain.Entities.User?> GetUserByResetTokenAsync(string token);
        Task<Domain.Entities.User?> GetUserByRefreshTokenAsync(string token);
        Task<Domain.Entities.User?> GetUserByVerificationTokenAsync(string token);
        Task<bool> AddUserAsync(Domain.Entities.User user);
        Task<bool> UpdateUserAsync(Domain.Entities.User user);
    }
}
