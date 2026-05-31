namespace SmartTrip.Domain.Entities;

public class ExplorePost
{
    public int Id { get; set; }

    public int AuthorId { get; set; }

    public string Title { get; set; } = string.Empty;

    public string Excerpt { get; set; } = string.Empty;

    public string Content { get; set; } = string.Empty;

    public string? ThumbnailUrl { get; set; }

    public string Location { get; set; } = string.Empty;

    public string CitySlug { get; set; } = string.Empty;

    public string Province { get; set; } = string.Empty;

    public string Region { get; set; } = string.Empty;

    public double? Latitude { get; set; }

    public double? Longitude { get; set; }

    public int CostLevel { get; set; }

    public decimal AverageRating { get; set; }

    public int RatingCount { get; set; }

    public int ViewCount { get; set; }

    public string? Tags { get; set; }

    public DateTime CreatedAt { get; set; }

    public DateTime? UpdatedAt { get; set; }

    public virtual User Author { get; set; } = null!;

    public virtual ICollection<ExplorePostImage> Images { get; set; } = new List<ExplorePostImage>();

    public virtual ICollection<ExplorePostLike> Likes { get; set; } = new List<ExplorePostLike>();

    public virtual ICollection<ExplorePostSave> Saves { get; set; } = new List<ExplorePostSave>();

    public virtual ICollection<ExplorePostRating> Ratings { get; set; } = new List<ExplorePostRating>();

    public virtual ICollection<ExploreComment> Comments { get; set; } = new List<ExploreComment>();
}
