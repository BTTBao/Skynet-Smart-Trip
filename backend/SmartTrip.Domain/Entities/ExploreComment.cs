namespace SmartTrip.Domain.Entities;

public class ExploreComment
{
    public int Id { get; set; }

    public int ExplorePostId { get; set; }

    public int? ParentCommentId { get; set; }

    public int UserId { get; set; }

    public string Content { get; set; } = string.Empty;

    public int LikeCount { get; set; }

    public DateTime CreatedAt { get; set; }
    
    public string? ImageUrl { get; set; }

    public virtual ExplorePost ExplorePost { get; set; } = null!;

    public virtual ExploreComment? ParentComment { get; set; }

    public virtual ICollection<ExploreComment> Replies { get; set; } = new List<ExploreComment>();

    public virtual User User { get; set; } = null!;
}
