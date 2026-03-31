using SmartTrip.Domain.Entities;

namespace SmartTrip.Application.Interfaces.Auth
{
    public interface ITokenService
    {
        string GenerateAccessToken(Domain.Entities.User user, int expireMinutes);
        string GenerateRefreshToken();
    }
}
