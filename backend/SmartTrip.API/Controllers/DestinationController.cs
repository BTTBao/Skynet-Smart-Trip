using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SmartTrip.Domain.Entities;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace SmartTrip.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class DestinationController : ControllerBase
{
    private readonly ApplicationDbContext _context;

    public DestinationController(ApplicationDbContext context)
    {
        _context = context;
    }

    [HttpGet]
    public async Task<IActionResult> GetDestinations()
    {
        var destinations = await _context.Destinations
            .OrderBy(d => d.Name)
            .Select(d => new
            {
                Id = d.Id,
                Name = d.Name,
                Description = d.Description ?? string.Empty,
                CoverImageUrl = d.CoverImageUrl ?? string.Empty,
                IsHot = d.IsHot ?? false
            })
            .ToListAsync();

        return Ok(destinations);
    }
}
