using SmartTrip.Domain.Enums;

namespace SmartTrip.Domain.Entities;

public class VehicleRentalShop
{
    public int Id { get; set; }

    public string Name { get; set; } = string.Empty;

    public string PhoneNumber { get; set; } = string.Empty;

    public string Address { get; set; } = string.Empty;

    public int DestinationId { get; set; }

    public string? Description { get; set; }

    public string? ImageUrl { get; set; }

    public bool IsActive { get; set; } = true;

    public DateTime CreatedAt { get; set; }

    public virtual Destination Destination { get; set; } = null!;

    public virtual ICollection<VehicleRentalOption> VehicleOptions { get; set; } =
        new List<VehicleRentalOption>();
}
