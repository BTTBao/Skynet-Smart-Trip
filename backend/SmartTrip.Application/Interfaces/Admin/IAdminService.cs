using System.Threading.Tasks;
using SmartTrip.Application.DTOs.Admin;

namespace SmartTrip.Application.Interfaces.Admin;

public interface IAdminService
{
    Task<AdminDashboardDto> GetDashboardStatsAsync();
    Task<AdminUserStatsDto> GetUsersAsync();
}
