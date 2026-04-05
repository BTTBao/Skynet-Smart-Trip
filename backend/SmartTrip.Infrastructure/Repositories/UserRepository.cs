using Microsoft.EntityFrameworkCore;
using SmartTrip.Application.Interfaces.User;
using SmartTrip.Domain.Entities;

namespace SmartTrip.Infrastructure.Repositories
{
    public class UserRepository : IUserRepository
    {
        private readonly ApplicationDbContext _dbContext;

        public UserRepository(ApplicationDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public async Task<User?> GetUserByEmailAsync(string email) =>
            await _dbContext.Users
                .FirstOrDefaultAsync(u => u.Email.ToLower() == email.ToLower());

        public async Task<User?> GetUserByResetTokenAsync(string token) =>
            await _dbContext.Users
                .FirstOrDefaultAsync(u => u.PasswordResetToken == token);

        public async Task<User?> GetUserByRefreshTokenAsync(string token) =>
            await _dbContext.Users
                .FirstOrDefaultAsync(u => u.RefreshToken == token);

        public async Task<User?> GetUserByVerificationTokenAsync(string token) =>
            await _dbContext.Users
                .FirstOrDefaultAsync(u => u.EmailVerificationToken == token);

        public async Task<bool> AddUserAsync(User user)
        {
            await _dbContext.Users.AddAsync(user);
            return await _dbContext.SaveChangesAsync() > 0;
        }

        public async Task<bool> UpdateUserAsync(User user)
        {
            _dbContext.Users.Update(user);
            return await _dbContext.SaveChangesAsync() > 0;
        }
    }
}
