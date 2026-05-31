namespace SmartTrip.Domain.Entities;

public class ExplorePostRating
{
    public int Id { get; set; }

    public int ExplorePostId { get; set; }

    public int UserId { get; set; }

    public decimal Rating { get; set; }

    public DateTime CreatedAt { get; set; }

    public DateTime? UpdatedAt { get; set; }

    public virtual ExplorePost ExplorePost { get; set; } = null!;

    public virtual User User { get; set; } = null!;
}
