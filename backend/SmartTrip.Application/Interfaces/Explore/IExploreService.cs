using SmartTrip.Application.DTOs.Explore;

namespace SmartTrip.Application.Interfaces.Explore;

public interface IExploreService
{
    Task<PagedResultDto<ExplorePostDto>> GetPostsAsync(ExplorePostQueryDto query, int? currentUserId);

    Task<ExplorePostDto?> GetPostByIdAsync(int postId, int? currentUserId);

    Task<ExplorePostDto> CreatePostAsync(CreateExplorePostDto request, int authorId);

    Task<ExploreToggleLikeDto> ToggleLikeAsync(int postId, int userId);

    Task<ExploreToggleSaveDto> ToggleSaveAsync(int postId, int userId);

    Task<PagedResultDto<ExploreCommentDto>> GetCommentsAsync(int postId, int page, int pageSize);

    Task<ExploreCommentDto> AddCommentAsync(int postId, CreateExploreCommentDto request, int userId);

    Task<ExploreRatingResultDto> RatePostAsync(int postId, RateExplorePostDto request, int userId);

    Task<ExploreFilterDataDto> GetFilterDataAsync();

    Task<IReadOnlyList<ExploreLocationOptionDto>> SearchLocationsAsync(string? keyword, string? region, int limit);
}
