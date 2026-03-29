namespace SmartTrip.Application.Interfaces.User
{
    public interface IUserRepository
    {
        Task<Domain.Entities.User?> GetUserByEmailAsync(string email);
        Task<bool> AddUserAsync(Domain.Entities.User user);
        Task<bool> UpdateUserAsync(Domain.Entities.User user);
    }
}
