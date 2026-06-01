namespace SmartTrip.Domain.Entities;

public class ExplorePostImage
{
    public int Id { get; set; }

    public int ExplorePostId { get; set; }

    public string ImageUrl { get; set; } = string.Empty;

    public int SortOrder { get; set; }

    public virtual ExplorePost ExplorePost { get; set; } = null!;
}
