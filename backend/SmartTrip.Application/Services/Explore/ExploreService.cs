using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using SmartTrip.Application.DTOs.Notifications;
using SmartTrip.Application.DTOs.Explore;
using SmartTrip.Application.Interfaces;
using SmartTrip.Application.Interfaces.Explore;
using SmartTrip.Application.Interfaces.Notifications;
using SmartTrip.Domain.Entities;
using System.Globalization;
using System.Text;

namespace SmartTrip.Application.Services.Explore;

public class ExploreService : IExploreService
{
    private const int MaxPageSize = 50;
    private const int MaxImages = 10;
    private const string DefaultAvatar = "https://i.pravatar.cc/150?u=smarttrip";

    private readonly IApplicationDbContext _context;
    private readonly INotificationService _notificationService;
    private readonly ILogger<ExploreService> _logger;

    public ExploreService(
        IApplicationDbContext context,
        INotificationService notificationService,
        ILogger<ExploreService> logger)
    {
        _context = context;
        _notificationService = notificationService;
        _logger = logger;
    }

    public async Task<PagedResultDto<ExplorePostDto>> GetPostsAsync(ExplorePostQueryDto query, int? currentUserId)
    {
        var page = Math.Max(1, query.Page);
        var pageSize = Math.Clamp(query.PageSize <= 0 ? 10 : query.PageSize, 1, MaxPageSize);

        var postsQuery = ApplyFilters(_context.ExplorePosts.AsNoTracking(), query);
        postsQuery = ApplySort(postsQuery, query.SortBy);

        var totalItems = await postsQuery.CountAsync();
        var posts = await postsQuery
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(post => new ExplorePostDto
            {
                Id = post.Id,
                Title = post.Title,
                Excerpt = post.Excerpt,
                Content = post.Content,
                ThumbnailUrl = post.ThumbnailUrl ?? post.Images
                    .OrderBy(image => image.SortOrder)
                    .Select(image => image.ImageUrl)
                    .FirstOrDefault() ?? string.Empty,
                ImageUrls = post.Images
                    .OrderBy(image => image.SortOrder)
                    .Select(image => image.ImageUrl)
                    .ToList(),
                Location = post.Location,
                City = post.CitySlug,
                Province = post.Province,
                Region = post.Region,
                Latitude = post.Latitude,
                Longitude = post.Longitude,
                AuthorName = post.Author.FullName ?? post.Author.UserName ?? post.Author.Email,
                AuthorAvatar = post.Author.AvatarUrl ?? DefaultAvatar,
                PublishedAt = post.CreatedAt,
                Likes = post.Likes.Count,
                Saves = post.Saves.Count,
                Views = post.ViewCount,
                Rating = (double)post.AverageRating,
                RatingCount = post.RatingCount,
                PriceLevel = post.CostLevel,
                IsLiked = currentUserId.HasValue && post.Likes.Any(like => like.UserId == currentUserId.Value),
                IsBookmarked = currentUserId.HasValue && post.Saves.Any(save => save.UserId == currentUserId.Value),
                Tags = SplitTags(post.Tags),
            })
            .ToListAsync();

        return new PagedResultDto<ExplorePostDto>
        {
            Items = posts,
            Page = page,
            PageSize = pageSize,
            TotalItems = totalItems,
            TotalPages = totalItems == 0 ? 0 : (int)Math.Ceiling(totalItems / (double)pageSize)
        };
    }

    public async Task<ExplorePostDto?> GetPostByIdAsync(int postId, int? currentUserId)
    {
        if (postId <= 0)
        {
            throw new ArgumentException("Explore post id is invalid.");
        }

        var post = await _context.ExplorePosts.FirstOrDefaultAsync(item => item.Id == postId);
        if (post == null)
        {
            return null;
        }

        post.ViewCount += 1;
        await _context.SaveChangesAsync();

        return await MapPostAsync(postId, currentUserId, includeComments: true);
    }

    public async Task<ExplorePostDto> CreatePostAsync(CreateExplorePostDto request, int authorId)
    {
        ValidateCreatePost(request);

        var userExists = await _context.Users.AnyAsync(user => user.Id == authorId);
        if (!userExists)
        {
            throw new KeyNotFoundException($"User {authorId} was not found.");
        }

        var location = ResolveLocation(request.Location, request.City, request.Province, request.Region);
        var imageUrls = request.ImageUrls
            .Where(url => !string.IsNullOrWhiteSpace(url))
            .Select(url => url.Trim())
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .Take(MaxImages)
            .ToList();

        var content = AppendImageBlocks(request.Content.Trim(), imageUrls);
        var post = new ExplorePost
        {
            AuthorId = authorId,
            Title = request.Title.Trim(),
            Excerpt = BuildExcerpt(request.Content),
            Content = content,
            ThumbnailUrl = imageUrls.FirstOrDefault(),
            Location = location.Name,
            CitySlug = location.Slug,
            Province = location.Province,
            Region = location.Region,
            Latitude = request.Latitude,
            Longitude = request.Longitude,
            CostLevel = request.CostLevel,
            Tags = JoinTags(request.Tags),
            AverageRating = 0m,
            RatingCount = 0,
            ViewCount = 0,
            CreatedAt = DateTime.UtcNow,
        };

        for (var i = 0; i < imageUrls.Count; i++)
        {
            post.Images.Add(new ExplorePostImage
            {
                ImageUrl = imageUrls[i],
                SortOrder = i
            });
        }

        _context.ExplorePosts.Add(post);
        await _context.SaveChangesAsync();

        return await MapPostAsync(post.Id, authorId, includeComments: true)
            ?? throw new InvalidOperationException("Explore post was created but could not be loaded.");
    }

    public async Task<ExploreToggleLikeDto> ToggleLikeAsync(int postId, int userId)
    {
        await EnsurePostAndUserExistAsync(postId, userId);

        var existing = await _context.ExplorePostLikes
            .FirstOrDefaultAsync(like => like.ExplorePostId == postId && like.UserId == userId);

        var isLiked = existing == null;
        if (existing == null)
        {
            _context.ExplorePostLikes.Add(new ExplorePostLike
            {
                ExplorePostId = postId,
                UserId = userId,
                CreatedAt = DateTime.UtcNow
            });
        }
        else
        {
            _context.ExplorePostLikes.Remove(existing);
        }

        await _context.SaveChangesAsync();
        var likeCount = await _context.ExplorePostLikes.CountAsync(like => like.ExplorePostId == postId);

        return new ExploreToggleLikeDto
        {
            IsLiked = isLiked,
            LikeCount = likeCount
        };
    }

    public async Task<ExploreToggleSaveDto> ToggleSaveAsync(int postId, int userId)
    {
        await EnsurePostAndUserExistAsync(postId, userId);

        var existing = await _context.ExplorePostSaves
            .FirstOrDefaultAsync(save => save.ExplorePostId == postId && save.UserId == userId);

        var isSaved = existing == null;
        if (existing == null)
        {
            _context.ExplorePostSaves.Add(new ExplorePostSave
            {
                ExplorePostId = postId,
                UserId = userId,
                CreatedAt = DateTime.UtcNow
            });
        }
        else
        {
            _context.ExplorePostSaves.Remove(existing);
        }

        await _context.SaveChangesAsync();
        var saveCount = await _context.ExplorePostSaves.CountAsync(save => save.ExplorePostId == postId);

        return new ExploreToggleSaveDto
        {
            IsSaved = isSaved,
            SaveCount = saveCount
        };
    }

    public async Task<PagedResultDto<ExploreCommentDto>> GetCommentsAsync(int postId, int page, int pageSize)
    {
        if (!await _context.ExplorePosts.AnyAsync(post => post.Id == postId))
        {
            throw new KeyNotFoundException($"Explore post {postId} was not found.");
        }

        page = Math.Max(1, page);
        pageSize = Math.Clamp(pageSize <= 0 ? 20 : pageSize, 1, MaxPageSize);

        var query = _context.ExploreComments
            .AsNoTracking()
            .Where(comment => comment.ExplorePostId == postId)
            .Where(comment => comment.ParentCommentId == null)
            .OrderByDescending(comment => comment.CreatedAt);

        var totalItems = await query.CountAsync();
        var rootComments = await query
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(comment => new ExploreCommentDto
            {
                Id = comment.Id,
                ParentCommentId = comment.ParentCommentId,
                AuthorName = comment.User.FullName ?? comment.User.UserName ?? comment.User.Email,
                AuthorAvatar = comment.User.AvatarUrl ?? DefaultAvatar,
                Content = comment.Content,
                ImageUrl = comment.ImageUrl,
                CreatedAt = comment.CreatedAt,
                Likes = comment.LikeCount
            })
            .ToListAsync();
        await AttachRepliesAsync(rootComments);

        return new PagedResultDto<ExploreCommentDto>
        {
            Items = rootComments,
            Page = page,
            PageSize = pageSize,
            TotalItems = totalItems,
            TotalPages = totalItems == 0 ? 0 : (int)Math.Ceiling(totalItems / (double)pageSize)
        };
    }

    public async Task<ExploreCommentDto> AddCommentAsync(int postId, CreateExploreCommentDto request, int userId)
    {
        var content = request.Content?.Trim() ?? string.Empty;
        if (string.IsNullOrWhiteSpace(content))
        {
            throw new ArgumentException("Comment content is required.");
        }

        if (content.Length > 1000)
        {
            throw new ArgumentException("Comment content must be 1000 characters or fewer.");
        }

        await EnsurePostAndUserExistAsync(postId, userId);
        if (request.ParentCommentId.HasValue)
        {
            var parentExists = await _context.ExploreComments.AnyAsync(comment =>
                comment.Id == request.ParentCommentId.Value &&
                comment.ExplorePostId == postId &&
                comment.ParentCommentId == null);
            if (!parentExists)
            {
                throw new ArgumentException("Parent comment is invalid.");
            }
        }

        var post = await _context.ExplorePosts
            .AsNoTracking()
            .Where(item => item.Id == postId)
            .Select(item => new { item.AuthorId, item.Title })
            .FirstAsync();
        var parentCommentAuthorId = request.ParentCommentId.HasValue
            ? await _context.ExploreComments
                .AsNoTracking()
                .Where(item => item.Id == request.ParentCommentId.Value)
                .Select(item => (int?)item.UserId)
                .FirstOrDefaultAsync()
            : null;

        var comment = new ExploreComment
        {
            ExplorePostId = postId,
            ParentCommentId = request.ParentCommentId,
            UserId = userId,
            Content = content,
            ImageUrl = request.ImageUrl,
            LikeCount = 0,
            CreatedAt = DateTime.UtcNow
        };

        _context.ExploreComments.Add(comment);
        await _context.SaveChangesAsync();

        await TryNotifyCommentTargetsAsync(
            post.AuthorId,
            parentCommentAuthorId,
            postId,
            post.Title,
            userId,
            request.ParentCommentId.HasValue);

        return await _context.ExploreComments
            .AsNoTracking()
            .Where(item => item.Id == comment.Id)
            .Select(item => new ExploreCommentDto
            {
                Id = item.Id,
                ParentCommentId = item.ParentCommentId,
                AuthorName = item.User.FullName ?? item.User.UserName ?? item.User.Email,
                AuthorAvatar = item.User.AvatarUrl ?? DefaultAvatar,
                Content = item.Content,
                ImageUrl = item.ImageUrl,
                CreatedAt = item.CreatedAt,
                Likes = item.LikeCount,
                Replies = new List<ExploreCommentDto>()
            })
            .FirstAsync();
    }

    private async Task TryNotifyCommentTargetsAsync(
        int postOwnerId,
        int? parentCommentAuthorId,
        int postId,
        string postTitle,
        int actorUserId,
        bool isReply)
    {
        if (isReply &&
            parentCommentAuthorId.HasValue &&
            parentCommentAuthorId.Value > 0 &&
            parentCommentAuthorId.Value != actorUserId)
        {
            await TryCreateExploreNotificationAsync(new CreateNotificationDto
            {
                UserId = parentCommentAuthorId.Value,
                Title = "Bình luận của bạn có phản hồi mới",
                Message = $"Có người vừa phản hồi bình luận trong bài viết \"{postTitle}\".",
                Type = "explore.comment_replied",
                ReferenceType = "explore_post",
                ReferenceId = postId,
                ActionUrl = $"/explore/posts/{postId}"
            });
        }

        if (postOwnerId == actorUserId || parentCommentAuthorId == postOwnerId)
        {
            return;
        }

        await TryCreateExploreNotificationAsync(new CreateNotificationDto
        {
            UserId = postOwnerId,
            Title = isReply ? "Bài viết có phản hồi mới" : "Bài viết có bình luận mới",
            Message = isReply
                ? $"Bài viết \"{postTitle}\" vừa có thêm phản hồi trong phần bình luận."
                : $"Bài viết \"{postTitle}\" vừa có bình luận mới.",
            Type = isReply ? "explore.comment_replied" : "explore.comment_created",
            ReferenceType = "explore_post",
            ReferenceId = postId,
            ActionUrl = $"/explore/posts/{postId}"
        });
    }

    private async Task TryCreateExploreNotificationAsync(CreateNotificationDto notification)
    {
        try
        {
            await _notificationService.CreateAsync(notification);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to create explore notification {Type} for user {UserId}", notification.Type, notification.UserId);
        }
    }

    public async Task<ExploreRatingResultDto> RatePostAsync(int postId, RateExplorePostDto request, int userId)
    {
        if (request.Rating < 1 || request.Rating > 5)
        {
            throw new ArgumentException("Rating must be between 1 and 5.");
        }

        await EnsurePostAndUserExistAsync(postId, userId);

        var existing = await _context.ExplorePostRatings
            .FirstOrDefaultAsync(rating => rating.ExplorePostId == postId && rating.UserId == userId);

        if (existing == null)
        {
            _context.ExplorePostRatings.Add(new ExplorePostRating
            {
                ExplorePostId = postId,
                UserId = userId,
                Rating = (decimal)request.Rating,
                CreatedAt = DateTime.UtcNow
            });
        }
        else
        {
            existing.Rating = (decimal)request.Rating;
            existing.UpdatedAt = DateTime.UtcNow;
        }

        await _context.SaveChangesAsync();
        await RefreshRatingSummaryAsync(postId);

        var summary = await _context.ExplorePosts
            .AsNoTracking()
            .Where(post => post.Id == postId)
            .Select(post => new { post.AverageRating, post.RatingCount })
            .FirstAsync();

        return new ExploreRatingResultDto
        {
            Rating = request.Rating,
            AverageRating = (double)summary.AverageRating,
            RatingCount = summary.RatingCount
        };
    }

    public Task<ExploreFilterDataDto> GetFilterDataAsync()
    {
        var data = new ExploreFilterDataDto
        {
            SortOptions =
            [
                new ExploreSortOptionDto { Value = "newest", Label = "Moi nhat" },
                new ExploreSortOptionDto { Value = "mostViewed", Label = "Xem nhieu nhat" },
                new ExploreSortOptionDto { Value = "topRated", Label = "Danh gia cao nhat" }
            ],
            RatingOptions = [3.0, 3.5, 4.0, 4.5],
            Locations = LocationCatalog
                .Select(location => new ExploreLocationOptionDto
                {
                    Slug = location.Slug,
                    Name = location.Name,
                    Province = location.Province,
                    Region = location.Region
                })
                .ToList(),
            Regions =
            [
                new ExploreRegionOptionDto { Value = "north", Label = "Mien Bac" },
                new ExploreRegionOptionDto { Value = "central", Label = "Mien Trung" },
                new ExploreRegionOptionDto { Value = "south", Label = "Mien Nam" }
            ],
            CostLevels =
            [
                new ExploreCostOptionDto { Value = 1, Label = "Tiet kiem" },
                new ExploreCostOptionDto { Value = 2, Label = "Trung binh" },
                new ExploreCostOptionDto { Value = 3, Label = "Cao cap" },
                new ExploreCostOptionDto { Value = 4, Label = "Sang trong" }
            ]
        };

        return Task.FromResult(data);
    }

    public Task<IReadOnlyList<ExploreLocationOptionDto>> SearchLocationsAsync(string? keyword, string? region, int limit)
    {
        limit = Math.Clamp(limit <= 0 ? 12 : limit, 1, 50);
        var normalizedKeyword = NormalizeForSearch(keyword);
        var normalizedRegion = region?.Trim().ToLowerInvariant();

        var locations = LocationCatalog.AsEnumerable();
        if (!string.IsNullOrWhiteSpace(normalizedRegion))
        {
            locations = locations.Where(location => location.Region.Equals(normalizedRegion, StringComparison.OrdinalIgnoreCase));
        }

        if (!string.IsNullOrWhiteSpace(normalizedKeyword))
        {
            locations = locations.Where(location =>
                NormalizeForSearch(location.Name).Contains(normalizedKeyword) ||
                NormalizeForSearch(location.Province).Contains(normalizedKeyword) ||
                location.Slug.Contains(normalizedKeyword, StringComparison.OrdinalIgnoreCase));
        }

        var result = locations
            .Take(limit)
            .Select(location => new ExploreLocationOptionDto
            {
                Slug = location.Slug,
                Name = location.Name,
                Province = location.Province,
                Region = location.Region
            })
            .ToList()
            .AsReadOnly();

        return Task.FromResult<IReadOnlyList<ExploreLocationOptionDto>>(result);
    }

    private async Task<ExplorePostDto?> MapPostAsync(int postId, int? currentUserId, bool includeComments)
    {
        var post = await _context.ExplorePosts
            .AsNoTracking()
            .Where(item => item.Id == postId)
            .Select(item => new ExplorePostDto
            {
                Id = item.Id,
                Title = item.Title,
                Excerpt = item.Excerpt,
                Content = item.Content,
                ThumbnailUrl = item.ThumbnailUrl ?? item.Images
                    .OrderBy(image => image.SortOrder)
                    .Select(image => image.ImageUrl)
                    .FirstOrDefault() ?? string.Empty,
                ImageUrls = item.Images
                    .OrderBy(image => image.SortOrder)
                    .Select(image => image.ImageUrl)
                    .ToList(),
                Location = item.Location,
                City = item.CitySlug,
                Province = item.Province,
                Region = item.Region,
                Latitude = item.Latitude,
                Longitude = item.Longitude,
                AuthorName = item.Author.FullName ?? item.Author.UserName ?? item.Author.Email,
                AuthorAvatar = item.Author.AvatarUrl ?? DefaultAvatar,
                PublishedAt = item.CreatedAt,
                Likes = item.Likes.Count,
                Saves = item.Saves.Count,
                Views = item.ViewCount,
                Rating = (double)item.AverageRating,
                RatingCount = item.RatingCount,
                PriceLevel = item.CostLevel,
                IsLiked = currentUserId.HasValue && item.Likes.Any(like => like.UserId == currentUserId.Value),
                IsBookmarked = currentUserId.HasValue && item.Saves.Any(save => save.UserId == currentUserId.Value),
                Tags = SplitTags(item.Tags)
            })
            .FirstOrDefaultAsync();

        if (post == null || !includeComments)
        {
            return post;
        }

        post.Comments = await _context.ExploreComments
            .AsNoTracking()
            .Where(comment => comment.ExplorePostId == postId)
            .Where(comment => comment.ParentCommentId == null)
            .OrderByDescending(comment => comment.CreatedAt)
            .Take(20)
            .Select(comment => new ExploreCommentDto
            {
                Id = comment.Id,
                ParentCommentId = comment.ParentCommentId,
                AuthorName = comment.User.FullName ?? comment.User.UserName ?? comment.User.Email,
                AuthorAvatar = comment.User.AvatarUrl ?? DefaultAvatar,
                Content = comment.Content,
                ImageUrl = comment.ImageUrl,
                CreatedAt = comment.CreatedAt,
                Likes = comment.LikeCount
            })
            .ToListAsync();
        await AttachRepliesAsync(post.Comments);

        return post;
    }

    private async Task AttachRepliesAsync(List<ExploreCommentDto> rootComments)
    {
        if (rootComments.Count == 0)
        {
            return;
        }

        var rootIds = rootComments.Select(comment => comment.Id).ToList();
        var replies = await _context.ExploreComments
            .AsNoTracking()
            .Where(comment => comment.ParentCommentId.HasValue && rootIds.Contains(comment.ParentCommentId.Value))
            .OrderBy(comment => comment.CreatedAt)
            .Select(comment => new ExploreCommentDto
            {
                Id = comment.Id,
                ParentCommentId = comment.ParentCommentId,
                AuthorName = comment.User.FullName ?? comment.User.UserName ?? comment.User.Email,
                AuthorAvatar = comment.User.AvatarUrl ?? DefaultAvatar,
                Content = comment.Content,
                ImageUrl = comment.ImageUrl,
                CreatedAt = comment.CreatedAt,
                Likes = comment.LikeCount,
                Replies = new List<ExploreCommentDto>()
            })
            .ToListAsync();

        var grouped = replies
            .Where(reply => reply.ParentCommentId.HasValue)
            .GroupBy(reply => reply.ParentCommentId!.Value)
            .ToDictionary(group => group.Key, group => group.ToList());

        foreach (var comment in rootComments)
        {
            comment.Replies = grouped.TryGetValue(comment.Id, out var commentReplies)
                ? commentReplies
                : [];
        }
    }

    private IQueryable<ExplorePost> ApplyFilters(IQueryable<ExplorePost> query, ExplorePostQueryDto filter)
    {
        var keyword = filter.Keyword?.Trim().ToLowerInvariant();
        if (!string.IsNullOrWhiteSpace(keyword))
        {
            query = query.Where(post =>
                post.Title.ToLower().Contains(keyword) ||
                post.Excerpt.ToLower().Contains(keyword) ||
                post.Content.ToLower().Contains(keyword) ||
                post.Location.ToLower().Contains(keyword) ||
                post.Province.ToLower().Contains(keyword) ||
                post.CitySlug.ToLower().Contains(keyword) ||
                (post.Tags != null && post.Tags.ToLower().Contains(keyword)));
        }

        var cities = ParseStringSet(filter.Cities);
        if (!string.IsNullOrWhiteSpace(filter.City))
        {
            cities.Add(filter.City.Trim().ToLowerInvariant());
        }

        if (cities.Count > 0)
        {
            query = query.Where(post => cities.Contains(post.CitySlug));
        }

        if (!string.IsNullOrWhiteSpace(filter.Province))
        {
            var province = filter.Province.Trim().ToLowerInvariant();
            query = query.Where(post => post.Province.ToLower() == province || post.Location.ToLower() == province);
        }

        if (!string.IsNullOrWhiteSpace(filter.Region))
        {
            var region = filter.Region.Trim().ToLowerInvariant();
            query = query.Where(post => post.Region.ToLower() == region);
        }

        if (filter.MinRating.HasValue)
        {
            query = query.Where(post => (double)post.AverageRating >= filter.MinRating.Value);
        }

        var costLevels = ParseIntSet(filter.CostLevels);
        if (filter.CostLevel.HasValue)
        {
            costLevels.Add(filter.CostLevel.Value);
        }

        if (costLevels.Count > 0)
        {
            query = query.Where(post => costLevels.Contains(post.CostLevel));
        }

        return query;
    }

    private static IQueryable<ExplorePost> ApplySort(IQueryable<ExplorePost> query, string? sortBy)
    {
        return sortBy?.Trim() switch
        {
            "mostViewed" => query.OrderByDescending(post => post.ViewCount).ThenByDescending(post => post.CreatedAt),
            "topRated" => query.OrderByDescending(post => post.AverageRating).ThenByDescending(post => post.RatingCount),
            _ => query.OrderByDescending(post => post.CreatedAt)
        };
    }

    private async Task EnsurePostAndUserExistAsync(int postId, int userId)
    {
        if (!await _context.ExplorePosts.AnyAsync(post => post.Id == postId))
        {
            throw new KeyNotFoundException($"Explore post {postId} was not found.");
        }

        if (!await _context.Users.AnyAsync(user => user.Id == userId))
        {
            throw new KeyNotFoundException($"User {userId} was not found.");
        }
    }

    private async Task RefreshRatingSummaryAsync(int postId)
    {
        var post = await _context.ExplorePosts.FirstAsync(item => item.Id == postId);
        var ratings = await _context.ExplorePostRatings
            .Where(rating => rating.ExplorePostId == postId)
            .Select(rating => rating.Rating)
            .ToListAsync();

        post.RatingCount = ratings.Count;
        post.AverageRating = ratings.Count == 0 ? 0m : Math.Round(ratings.Average(), 2);
        await _context.SaveChangesAsync();
    }

    private static void ValidateCreatePost(CreateExplorePostDto request)
    {
        var title = request.Title?.Trim() ?? string.Empty;
        var content = request.Content?.Trim() ?? string.Empty;
        var location = request.Location?.Trim() ?? string.Empty;

        if (title.Length < 5 || title.Length > 200)
        {
            throw new ArgumentException("Title must be between 5 and 200 characters.");
        }

        if (content.Length < 10 || content.Length > 10000)
        {
            throw new ArgumentException("Content must be between 10 and 10000 characters.");
        }

        if (location.Length < 2 || location.Length > 120)
        {
            throw new ArgumentException("Location is required and must be 120 characters or fewer.");
        }

        if (request.CostLevel < 1 || request.CostLevel > 4)
        {
            throw new ArgumentException("CostLevel must be between 1 and 4.");
        }

        if (request.ImageUrls.Count > MaxImages)
        {
            throw new ArgumentException($"A post can contain at most {MaxImages} images.");
        }

        if (request.Latitude is < -90 or > 90)
        {
            throw new ArgumentException("Latitude must be between -90 and 90.");
        }

        if (request.Longitude is < -180 or > 180)
        {
            throw new ArgumentException("Longitude must be between -180 and 180.");
        }
    }

    private static LocationInfo ResolveLocation(string locationName, string? city, string? province, string? region)
    {
        var rawLocation = locationName.Trim();
        var normalizedCity = city?.Trim().ToLowerInvariant();
        var normalizedLocation = NormalizeForSearch(rawLocation);

        var match = LocationCatalog.FirstOrDefault(item =>
            item.Slug.Equals(normalizedCity, StringComparison.OrdinalIgnoreCase) ||
            NormalizeForSearch(item.Name) == normalizedLocation ||
            NormalizeForSearch(item.Province) == normalizedLocation);

        if (match != null)
        {
            return match;
        }

        var resolvedProvince = string.IsNullOrWhiteSpace(province) ? rawLocation : province.Trim();
        var resolvedRegion = NormalizeRegion(region);
        return new LocationInfo(
            Slugify(rawLocation),
            rawLocation,
            resolvedProvince,
            resolvedRegion);
    }

    private static string NormalizeRegion(string? region)
    {
        var normalized = region?.Trim().ToLowerInvariant();
        return normalized is "north" or "central" or "south" ? normalized : "north";
    }

    private static string BuildExcerpt(string content)
    {
        var plain = content
            .Replace("\r", " ")
            .Replace("\n", " ")
            .Trim();

        return plain.Length <= 240 ? plain : $"{plain[..237]}...";
    }

    private static string AppendImageBlocks(string content, IReadOnlyList<string> imageUrls)
    {
        if (imageUrls.Count == 0)
        {
            return content;
        }

        var builder = new StringBuilder(content);
        foreach (var imageUrl in imageUrls)
        {
            if (content.Contains($"[image:{imageUrl}]", StringComparison.OrdinalIgnoreCase))
            {
                continue;
            }

            builder.AppendLine();
            builder.AppendLine();
            builder.Append("[image:");
            builder.Append(imageUrl);
            builder.Append(']');
        }

        return builder.ToString();
    }

    private static HashSet<string> ParseStringSet(string? value)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return [];
        }

        return value.Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
            .Select(item => item.ToLowerInvariant())
            .ToHashSet(StringComparer.OrdinalIgnoreCase);
    }

    private static HashSet<int> ParseIntSet(string? value)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return [];
        }

        return value.Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
            .Select(item => int.TryParse(item, out var parsed) ? parsed : 0)
            .Where(item => item > 0)
            .ToHashSet();
    }

    private static List<string> SplitTags(string? tags)
    {
        if (string.IsNullOrWhiteSpace(tags))
        {
            return [];
        }

        return tags.Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
            .ToList();
    }

    private static string JoinTags(IEnumerable<string>? tags)
    {
        if (tags == null)
        {
            return string.Empty;
        }

        return string.Join(",", tags
            .Where(tag => !string.IsNullOrWhiteSpace(tag))
            .Select(tag => tag.Trim())
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .Take(20));
    }

    private static string NormalizeForSearch(string? value)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return string.Empty;
        }

        return RemoveDiacritics(value.Trim()).ToLowerInvariant();
    }

    private static string Slugify(string value)
    {
        var normalized = NormalizeForSearch(value);
        var builder = new StringBuilder();

        foreach (var character in normalized)
        {
            if (char.IsLetterOrDigit(character))
            {
                builder.Append(character);
            }
            else if (builder.Length > 0 && builder[^1] != '-')
            {
                builder.Append('-');
            }
        }

        return builder.ToString().Trim('-');
    }

    private static string RemoveDiacritics(string value)
    {
        var normalized = value.Normalize(NormalizationForm.FormD);
        var builder = new StringBuilder();

        foreach (var character in normalized)
        {
            var unicodeCategory = CharUnicodeInfo.GetUnicodeCategory(character);
            if (unicodeCategory != UnicodeCategory.NonSpacingMark)
            {
                builder.Append(character == 'đ' ? 'd' : character == 'Đ' ? 'D' : character);
            }
        }

        return builder.ToString().Normalize(NormalizationForm.FormC);
    }

    private sealed record LocationInfo(string Slug, string Name, string Province, string Region);

    private static readonly IReadOnlyList<LocationInfo> LocationCatalog =
    [
        new("ha-noi", "Hà Nội", "Hà Nội", "north"),
        new("ha-long", "Hạ Long", "Quảng Ninh", "north"),
        new("sapa", "Sa Pa", "Lào Cai", "north"),
        new("ninh-binh", "Ninh Bình", "Ninh Bình", "north"),
        new("da-nang", "Đà Nẵng", "Đà Nẵng", "central"),
        new("hue", "Huế", "Thừa Thiên Huế", "central"),
        new("hoi-an", "Hội An", "Quảng Nam", "central"),
        new("quang-binh", "Quảng Bình", "Quảng Bình", "central"),
        new("phu-quoc", "Phú Quốc", "Kiên Giang", "south"),
        new("da-lat", "Đà Lạt", "Lâm Đồng", "south"),
        new("ho-chi-minh", "TP. Hồ Chí Minh", "TP. Hồ Chí Minh", "south"),
        new("can-tho", "Cần Thơ", "Cần Thơ", "south")
    ];
}

