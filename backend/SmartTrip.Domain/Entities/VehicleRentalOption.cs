using SmartTrip.Domain.Enums;

namespace SmartTrip.Domain.Entities;

public class VehicleRentalOption
{
    public int Id { get; set; }

    public int VehicleRentalShopId { get; set; }

    public VehicleRentalType VehicleType { get; set; }

    public int? MaxSeats { get; set; }

    public decimal PricePerDay { get; set; }

    public bool IsAvailable { get; set; } = true;

    public virtual VehicleRentalShop VehicleRentalShop { get; set; } = null!;
}
