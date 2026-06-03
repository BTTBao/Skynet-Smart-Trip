namespace SmartTrip.Application.DTOs.Explore;

public class PagedResultDto<T>
{
    public IReadOnlyList<T> Items { get; set; } = [];

    public int Page { get; set; }

    public int PageSize { get; set; }

    public int TotalItems { get; set; }

    public int TotalPages { get; set; }

    public bool HasNextPage => Page < TotalPages;
}

public class ExplorePostDto
{
    public int Id { get; set; }

    public string Title { get; set; } = string.Empty;

    public string Excerpt { get; set; } = string.Empty;

    public string Content { get; set; } = string.Empty;

    public string ThumbnailUrl { get; set; } = string.Empty;

    public List<string> ImageUrls { get; set; } = [];

    public string Location { get; set; } = string.Empty;

    public string City { get; set; } = string.Empty;

    public string Province { get; set; } = string.Empty;

    public string Region { get; set; } = string.Empty;

    public double? Latitude { get; set; }

    public double? Longitude { get; set; }

    public string AuthorName { get; set; } = string.Empty;

    public string AuthorAvatar { get; set; } = string.Empty;

    public DateTime PublishedAt { get; set; }

    public int Likes { get; set; }

    public int Saves { get; set; }

    public int Views { get; set; }

    public double Rating { get; set; }

    public int RatingCount { get; set; }

    public int PriceLevel { get; set; }

    public bool IsLiked { get; set; }

    public bool IsBookmarked { get; set; }

    public List<ExploreCommentDto> Comments { get; set; } = [];

    public List<string> Tags { get; set; } = [];
}

public class ExploreCommentDto
{
    public int Id { get; set; }

    public int? ParentCommentId { get; set; }

    public string AuthorName { get; set; } = string.Empty;

    public string AuthorAvatar { get; set; } = string.Empty;

    public string Content { get; set; } = string.Empty;

    public string? ImageUrl { get; set; }

    public DateTime CreatedAt { get; set; }

    public int Likes { get; set; }

    public List<ExploreCommentDto> Replies { get; set; } = [];
}

public class ExplorePostQueryDto
{
    public string? Keyword { get; set; }

    public string? City { get; set; }

    public string? Cities { get; set; }

    public string? Province { get; set; }

    public string? Region { get; set; }

    public double? Latitude { get; set; }

    public double? Longitude { get; set; }

    public double? MinRating { get; set; }

    public int? CostLevel { get; set; }

    public string? CostLevels { get; set; }

    public string SortBy { get; set; } = "newest";

    public int Page { get; set; } = 1;

    public int PageSize { get; set; } = 10;
}

public class CreateExplorePostDto
{
    public string Title { get; set; } = string.Empty;

    public string Content { get; set; } = string.Empty;

    public string Location { get; set; } = string.Empty;

    public string? City { get; set; }

    public string? Province { get; set; }

    public string? Region { get; set; }

    public double? Latitude { get; set; }

    public double? Longitude { get; set; }

    public int CostLevel { get; set; } = 2;

    public List<string> ImageUrls { get; set; } = [];

    public List<string> Tags { get; set; } = [];
}

public class CreateExploreCommentDto
{
    public string Content { get; set; } = string.Empty;

    public int? ParentCommentId { get; set; }

    public string? ImageUrl { get; set; }
}

public class RateExplorePostDto
{
    public double Rating { get; set; }
}

public class ExploreToggleLikeDto
{
    public bool IsLiked { get; set; }

    public int LikeCount { get; set; }
}

public class ExploreToggleSaveDto
{
    public bool IsSaved { get; set; }

    public int SaveCount { get; set; }
}

public class ExploreRatingResultDto
{
    public double Rating { get; set; }

    public double AverageRating { get; set; }

    public int RatingCount { get; set; }
}

public class ExploreFilterDataDto
{
    public IReadOnlyList<ExploreSortOptionDto> SortOptions { get; set; } = [];

    public IReadOnlyList<double> RatingOptions { get; set; } = [];

    public IReadOnlyList<ExploreLocationOptionDto> Locations { get; set; } = [];

    public IReadOnlyList<ExploreRegionOptionDto> Regions { get; set; } = [];

    public IReadOnlyList<ExploreCostOptionDto> CostLevels { get; set; } = [];
}

public class ExploreSortOptionDto
{
    public string Value { get; set; } = string.Empty;

    public string Label { get; set; } = string.Empty;
}

public class ExploreLocationOptionDto
{
    public string Slug { get; set; } = string.Empty;

    public string Name { get; set; } = string.Empty;

    public string Province { get; set; } = string.Empty;

    public string Region { get; set; } = string.Empty;
}

public class ExploreRegionOptionDto
{
    public string Value { get; set; } = string.Empty;

    public string Label { get; set; } = string.Empty;
}

public class ExploreCostOptionDto
{
    public int Value { get; set; }

    public string Label { get; set; } = string.Empty;
}
