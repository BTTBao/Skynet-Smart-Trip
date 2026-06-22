using System.Globalization;
using System.Net;
using System.Text;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using SmartTrip.Application.DTOs.Admin;
using SmartTrip.Application.DTOs.Notifications;
using SmartTrip.Domain.Entities;

namespace SmartTrip.Infrastructure.Services.Admin;

public partial class AdminService
{
    private const int MaxExploreImages = 10;

    public async Task<List<AdminExplorePostDto>> GetExplorePostsAsync(string? search = null)
    {
        var normalizedSearch = search?.Trim().ToLowerInvariant();
        var posts = await _context.ExplorePosts
            .AsNoTracking()
            .Include(post => post.Author)
            .Include(post => post.Images)
            .Include(post => post.Likes)
            .Include(post => post.Saves)
            .Include(post => post.Comments)
            .OrderByDescending(post => post.CreatedAt)
            .ToListAsync();

        if (!string.IsNullOrWhiteSpace(normalizedSearch))
        {
            posts = posts
                .Where(post =>
                    (post.Title ?? string.Empty).ToLowerInvariant().Contains(normalizedSearch) ||
                    (post.Location ?? string.Empty).ToLowerInvariant().Contains(normalizedSearch) ||
                    (post.Province ?? string.Empty).ToLowerInvariant().Contains(normalizedSearch) ||
                    (post.Tags?.ToLowerInvariant().Contains(normalizedSearch) ?? false) ||
                    (post.Author?.FullName?.ToLowerInvariant().Contains(normalizedSearch) ?? false) ||
                    (post.Author?.Email?.ToLowerInvariant().Contains(normalizedSearch) ?? false))
                .ToList();
        }

        return posts.Select(MapExplorePost).ToList();
    }

    public async Task<AdminExplorePostDto> CreateExplorePostAsync(AdminExplorePostRequest request, int adminUserId)
    {
        ValidateExploreRequest(request);

        var authorExists = await _context.Users.AnyAsync(user => user.Id == adminUserId);
        if (!authorExists)
        {
            throw new BadHttpRequestException("Không tìm thấy tài khoản quản trị tạo bài.");
        }

        var imageUrls = NormalizeImageUrls(request.ImageUrls);
        var content = AppendExploreImageBlocks(request.Content.Trim(), imageUrls);
        var location = ResolveAdminExploreLocation(request);
        var post = new ExplorePost
        {
            AuthorId = adminUserId,
            Title = request.Title.Trim(),
            Excerpt = BuildExploreExcerpt(request.Content),
            Content = content,
            ThumbnailUrl = imageUrls.FirstOrDefault(),
            Location = location.Location,
            CitySlug = location.City,
            Province = location.Province,
            Region = location.Region,
            Latitude = request.Latitude,
            Longitude = request.Longitude,
            CostLevel = request.CostLevel,
            Tags = JoinExploreTags(request.Tags),
            LinkedTripCode = request.LinkedTripCode,
            IsVisible = request.IsVisible,
            AverageRating = 0m,
            RatingCount = 0,
            ViewCount = 0,
            CreatedAt = DateTime.UtcNow
        };

        SyncExploreImages(post, imageUrls);
        _context.ExplorePosts.Add(post);
        await _context.SaveChangesAsync();

        return await LoadExplorePostAsync(post.Id);
    }

    public async Task<AdminExplorePostDto> UpdateExplorePostAsync(int postId, AdminExplorePostRequest request)
    {
        ValidateExploreRequest(request);

        var post = await _context.ExplorePosts
            .Include(item => item.Author)
            .Include(item => item.Images)
            .Include(item => item.Likes)
            .Include(item => item.Saves)
            .Include(item => item.Comments)
            .FirstOrDefaultAsync(item => item.Id == postId);

        if (post is null)
        {
            throw new BadHttpRequestException("Không tìm thấy bài Explore.");
        }

        var imageUrls = NormalizeImageUrls(request.ImageUrls);
        var location = ResolveAdminExploreLocation(request);
        post.Title = request.Title.Trim();
        post.Excerpt = BuildExploreExcerpt(request.Content);
        post.Content = AppendExploreImageBlocks(request.Content.Trim(), imageUrls);
        post.ThumbnailUrl = imageUrls.FirstOrDefault();
        post.Location = location.Location;
        post.CitySlug = location.City;
        post.Province = location.Province;
        post.Region = location.Region;
        post.Latitude = request.Latitude;
        post.Longitude = request.Longitude;
        post.CostLevel = request.CostLevel;
        post.Tags = JoinExploreTags(request.Tags);
        post.LinkedTripCode = request.LinkedTripCode;
        post.IsVisible = request.IsVisible;
        post.UpdatedAt = DateTime.UtcNow;

        SyncExploreImages(post, imageUrls);
        await _context.SaveChangesAsync();

        return MapExplorePost(post);
    }

    public async Task<AdminExplorePostDto> UpdateExplorePostVisibilityAsync(int postId, bool isVisible)
    {
        var post = await _context.ExplorePosts
            .Include(item => item.Author)
            .Include(item => item.Images)
            .Include(item => item.Likes)
            .Include(item => item.Saves)
            .Include(item => item.Comments)
            .FirstOrDefaultAsync(item => item.Id == postId);

        if (post is null)
        {
            throw new BadHttpRequestException("Không tìm thấy bài Explore.");
        }

        post.IsVisible = isVisible;
        post.UpdatedAt = DateTime.UtcNow;
        await _context.SaveChangesAsync();

        return MapExplorePost(post);
    }

    public async Task DeleteExplorePostAsync(int postId)
    {
        var post = await _context.ExplorePosts.FirstOrDefaultAsync(item => item.Id == postId);
        if (post is null)
        {
            throw new BadHttpRequestException("Không tìm thấy bài Explore.");
        }

        _context.ExplorePosts.Remove(post);
        await _context.SaveChangesAsync();
    }

    public async Task<AdminNotificationStatsDto> GetNotificationsAsync(string? search = null)
    {
        var normalizedSearch = search?.Trim().ToLowerInvariant();
        var notifications = await _context.Notifications
            .AsNoTracking()
            .Include(notification => notification.User)
            .OrderByDescending(notification => notification.CreatedAt)
            .ThenByDescending(notification => notification.Id)
            .Take(300)
            .ToListAsync();

        if (!string.IsNullOrWhiteSpace(normalizedSearch))
        {
            notifications = notifications
                .Where(notification =>
                    NormalizeLegacyText(notification.Title).ToLowerInvariant().Contains(normalizedSearch) ||
                    NormalizeLegacyText(notification.Message).ToLowerInvariant().Contains(normalizedSearch) ||
                    (notification.Type?.ToLowerInvariant().Contains(normalizedSearch) ?? false) ||
                    NormalizeLegacyText(notification.User?.FullName).ToLowerInvariant().Contains(normalizedSearch) ||
                    (notification.User?.Email.ToLowerInvariant().Contains(normalizedSearch) ?? false))
                .ToList();
        }

        return new AdminNotificationStatsDto
        {
            TotalNotifications = notifications.Count,
            UnreadNotifications = notifications.Count(item => item.IsRead != true),
            ReadNotifications = notifications.Count(item => item.IsRead == true),
            TargetableUsers = await _context.Users.CountAsync(user => user.IsActive != false),
            Notifications = notifications.Select(MapAdminNotification).ToList()
        };
    }

    public async Task<AdminNotificationSendResultDto> SendNotificationAsync(AdminSendNotificationRequest request)
    {
        ValidateNotificationRequest(request);

        var channels = request.Channels
            .Select(channel => channel.Trim().ToLowerInvariant())
            .Where(channel => channel is "in_app" or "email" or "fcm")
            .ToHashSet(StringComparer.OrdinalIgnoreCase);
        var recipients = await ResolveNotificationRecipientsAsync(request);
        if (recipients.Count == 0)
        {
            throw new BadHttpRequestException("Không tìm thấy người nhận phù hợp.");
        }

        var result = new AdminNotificationSendResultDto
        {
            TargetedUsers = recipients.Count
        };

        foreach (var user in recipients)
        {
            var title = request.Title.Trim();
            var message = request.Message.Trim();
            var type = string.IsNullOrWhiteSpace(request.Type) ? "system" : request.Type.Trim();
            var referenceType = string.IsNullOrWhiteSpace(request.ReferenceType) ? null : request.ReferenceType.Trim();
            var actionUrl = string.IsNullOrWhiteSpace(request.ActionUrl) ? null : request.ActionUrl.Trim();

            try
            {
                if (channels.Contains("in_app"))
                {
                    var created = await _notificationService.CreateAsync(new CreateNotificationDto
                    {
                        UserId = user.Id,
                        Title = title,
                        Message = message,
                        Type = type,
                        ReferenceType = referenceType,
                        ReferenceId = request.ReferenceId,
                        ActionUrl = actionUrl,
                        SendPush = channels.Contains("fcm")
                    });

                    if (created != null)
                    {
                        result.InAppCreated += 1;
                        if (channels.Contains("fcm") && await _notificationService.ArePushNotificationsEnabledAsync(user.Id))
                        {
                            result.PushAttempted += 1;
                        }
                    }
                }
                else if (channels.Contains("fcm") && await _notificationService.ArePushNotificationsEnabledAsync(user.Id))
                {
                    result.PushAttempted += 1;
                    await _fcmPushService.SendToUserAsync(user.Id, new NotificationDto
                    {
                        Id = 0,
                        Title = title,
                        Message = message,
                        Type = type,
                        ReferenceType = referenceType,
                        ReferenceId = request.ReferenceId,
                        ActionUrl = actionUrl,
                        IsRead = false,
                        CreatedAt = DateTime.UtcNow
                    });
                }

                if (channels.Contains("email") && await _notificationService.AreEmailNotificationsEnabledAsync(user.Id))
                {
                    result.EmailAttempted += 1;
                    await _emailService.SendEmailAsync(
                        user.Email,
                        $"[SmartTrip] {title}",
                        BuildAdminNotificationEmail(user.FullName ?? user.Email, title, message, actionUrl));
                    result.EmailSent += 1;
                }
            }
            catch (Exception ex)
            {
                result.Failed += 1;
                result.Errors.Add($"{user.Email}: {ex.Message}");
                _logger.LogError(ex, "Failed to send admin notification to user {UserId}", user.Id);
            }
        }

        return result;
    }

    private async Task<AdminExplorePostDto> LoadExplorePostAsync(int postId)
    {
        var post = await _context.ExplorePosts
            .Include(item => item.Author)
            .Include(item => item.Images)
            .Include(item => item.Likes)
            .Include(item => item.Saves)
            .Include(item => item.Comments)
            .FirstAsync(item => item.Id == postId);

        return MapExplorePost(post);
    }

    private async Task<List<SmartTrip.Domain.Entities.User>> ResolveNotificationRecipientsAsync(AdminSendNotificationRequest request)
    {
        var mode = request.RecipientMode.Trim().ToLowerInvariant();
        var query = _context.Users.Where(user => user.IsActive != false);

        if (mode == "users")
        {
            var ids = request.UserIds.Where(id => id > 0).Distinct().ToList();
            query = query.Where(user => ids.Contains(user.Id));
        }
        else if (mode == "role")
        {
            var role = ParseUserRole(request.Role ?? "customer");
            query = role == SmartTrip.Domain.Enums.UserRole.Customer
                ? query.Where(user => user.Role == role || user.Role == SmartTrip.Domain.Enums.UserRole.User || user.Role == null)
                : query.Where(user => user.Role == role);
        }

        return await query
            .OrderBy(user => user.FullName ?? user.Email)
            .ToListAsync();
    }

    private static AdminExplorePostDto MapExplorePost(ExplorePost post)
    {
        var images = post.Images
            .OrderBy(image => image.SortOrder)
            .Select(image => image.ImageUrl)
            .Where(imageUrl => !string.IsNullOrWhiteSpace(imageUrl))
            .ToList();

        return new AdminExplorePostDto
        {
            Id = post.Id,
            Title = post.Title ?? string.Empty,
            Excerpt = post.Excerpt ?? string.Empty,
            Content = post.Content ?? string.Empty,
            ThumbnailUrl = post.ThumbnailUrl ?? images.FirstOrDefault() ?? string.Empty,
            ImageUrls = images,
            Location = post.Location ?? string.Empty,
            City = post.CitySlug ?? string.Empty,
            Province = post.Province ?? string.Empty,
            Region = post.Region ?? "north",
            Latitude = post.Latitude,
            Longitude = post.Longitude,
            AuthorName = post.Author?.FullName ?? post.Author?.UserName ?? post.Author?.Email ?? "Không rõ tác giả",
            CreatedAt = post.CreatedAt.ToLocalTime().ToString("dd/MM/yyyy HH:mm"),
            IsVisible = post.IsVisible,
            CostLevel = post.CostLevel,
            Likes = post.Likes.Count,
            Saves = post.Saves.Count,
            Views = post.ViewCount,
            CommentCount = post.Comments.Count,
            Rating = (double)post.AverageRating,
            RatingCount = post.RatingCount,
            Tags = SplitExploreTags(post.Tags),
            LinkedTripCode = post.LinkedTripCode
        };
    }

    private static AdminNotificationDto MapAdminNotification(Notification notification)
    {
        return new AdminNotificationDto
        {
            Id = notification.Id,
            UserId = notification.UserId,
            UserName = NormalizeLegacyText(notification.User?.FullName ?? notification.User?.UserName ?? notification.User?.Email ?? "Hệ thống"),
            UserEmail = notification.User?.Email ?? string.Empty,
            Title = NormalizeLegacyText(notification.Title),
            Message = NormalizeLegacyText(notification.Message),
            Type = notification.Type ?? "general",
            ReferenceType = notification.ReferenceType,
            ReferenceId = notification.ReferenceId,
            ActionUrl = notification.ActionUrl,
            IsRead = notification.IsRead == true,
            CreatedAt = notification.CreatedAt?.ToLocalTime().ToString("dd/MM/yyyy HH:mm") ?? "--"
        };
    }

    private static void ValidateExploreRequest(AdminExplorePostRequest request)
    {
        var title = request.Title?.Trim() ?? string.Empty;
        var content = request.Content?.Trim() ?? string.Empty;
        var location = request.Location?.Trim() ?? string.Empty;

        if (title.Length < 5 || title.Length > 200)
        {
            throw new BadHttpRequestException("Tiêu đề Explore phải từ 5 đến 200 ký tự.");
        }

        if (content.Length < 10 || content.Length > 10000)
        {
            throw new BadHttpRequestException("Nội dung Explore phải từ 10 đến 10000 ký tự.");
        }

        if (location.Length < 2 || location.Length > 120)
        {
            throw new BadHttpRequestException("Vị trí không được để trống và tối đa 120 ký tự.");
        }

        if (request.CostLevel < 1 || request.CostLevel > 4)
        {
            throw new BadHttpRequestException("Mức chi phí phải nằm trong khoảng từ 1 đến 4.");
        }

        if (request.ImageUrls.Count > MaxExploreImages)
        {
            throw new BadHttpRequestException($"Một bài Explore chỉ hỗ trợ tối đa {MaxExploreImages} ảnh.");
        }

        if (request.Latitude is < -90 or > 90)
        {
            throw new BadHttpRequestException("Vĩ độ phải nằm trong khoảng -90 đến 90.");
        }

        if (request.Longitude is < -180 or > 180)
        {
            throw new BadHttpRequestException("Kinh độ phải nằm trong khoảng -180 đến 180.");
        }
    }

    private static void ValidateNotificationRequest(AdminSendNotificationRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.Title) || request.Title.Trim().Length > 200)
        {
            throw new BadHttpRequestException("Tiêu đề thông báo không được trống và tối đa 200 ký tự.");
        }

        if (string.IsNullOrWhiteSpace(request.Message))
        {
            throw new BadHttpRequestException("Nội dung thông báo không được để trống.");
        }

        var hasValidChannel = request.Channels.Any(channel =>
            channel.Trim().ToLowerInvariant() is "in_app" or "email" or "fcm");
        if (!hasValidChannel)
        {
            throw new BadHttpRequestException("Vui lòng chọn ít nhất một kênh gửi hợp lệ.");
        }

        if (request.RecipientMode.Trim().Equals("users", StringComparison.OrdinalIgnoreCase) &&
            request.UserIds.All(id => id <= 0))
        {
            throw new BadHttpRequestException("Vui lòng chọn ít nhất một người nhận.");
        }
    }

    private static (string Location, string City, string Province, string Region) ResolveAdminExploreLocation(AdminExplorePostRequest request)
    {
        var location = request.Location.Trim();
        var city = string.IsNullOrWhiteSpace(request.City) ? SlugifyExplore(location) : SlugifyExplore(request.City);
        var province = string.IsNullOrWhiteSpace(request.Province) ? location : request.Province.Trim();
        var region = request.Region?.Trim().ToLowerInvariant();

        return (
            location,
            city,
            province,
            region is "north" or "central" or "south" ? region : "north");
    }

    private static void SyncExploreImages(ExplorePost post, IReadOnlyList<string> imageUrls)
    {
        post.Images.Clear();
        for (var i = 0; i < imageUrls.Count; i++)
        {
            post.Images.Add(new ExplorePostImage
            {
                ImageUrl = imageUrls[i],
                SortOrder = i
            });
        }
    }

    private static List<string> NormalizeImageUrls(IEnumerable<string>? imageUrls)
    {
        return (imageUrls ?? [])
            .Where(url => !string.IsNullOrWhiteSpace(url))
            .Select(url => url.Trim())
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .Take(MaxExploreImages)
            .ToList();
    }

    private static string BuildExploreExcerpt(string content)
    {
        var plain = content.Replace("\r", " ").Replace("\n", " ").Trim();
        return plain.Length <= 240 ? plain : $"{plain[..237]}...";
    }

    private static string AppendExploreImageBlocks(string content, IReadOnlyList<string> imageUrls)
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

    private static List<string> SplitExploreTags(string? tags)
    {
        return string.IsNullOrWhiteSpace(tags)
            ? []
            : tags.Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries).ToList();
    }

    private static string JoinExploreTags(IEnumerable<string>? tags)
    {
        return tags == null
            ? string.Empty
            : string.Join(",", tags
                .Where(tag => !string.IsNullOrWhiteSpace(tag))
                .Select(tag => tag.Trim())
                .Distinct(StringComparer.OrdinalIgnoreCase)
                .Take(20));
    }

    private static string BuildAdminNotificationEmail(string fullName, string title, string message, string? actionUrl)
    {
        var encodedTitle = WebUtility.HtmlEncode(title);
        var encodedMessage = WebUtility.HtmlEncode(message).Replace("\n", "<br/>");
        var button = string.IsNullOrWhiteSpace(actionUrl)
            ? string.Empty
            : $"<p><a href=\"{WebUtility.HtmlEncode(actionUrl)}\" style=\"display:inline-block;padding:12px 20px;border-radius:999px;background:#0f766e;color:#fff;text-decoration:none;font-weight:700;\">Mở SmartTrip</a></p>";

        return "<div style=\"font-family:Arial,sans-serif;line-height:1.6;color:#1f2937\">" +
            $"<p>Xin chào <strong>{WebUtility.HtmlEncode(fullName)}</strong>,</p>" +
            $"<h2>{encodedTitle}</h2>" +
            $"<p>{encodedMessage}</p>" +
            button +
            "<p style=\"margin-top:24px;color:#6b7280;font-size:13px\">Thông báo này được gửi từ hệ thống quản trị SmartTrip.</p>" +
            "</div>";
    }

    private static string NormalizeLegacyText(string? value)
    {
        if (string.IsNullOrEmpty(value))
        {
            return string.Empty;
        }

        if (!LooksLikeMojibake(value))
        {
            return value;
        }

        try
        {
            var decoded = Encoding.UTF8.GetString(Encoding.Latin1.GetBytes(value));
            return LooksLikeMojibake(decoded) ? value : decoded;
        }
        catch
        {
            return value;
        }
    }

    private static bool LooksLikeMojibake(string value)
    {
        return value.Contains('Ã') ||
               value.Contains('Ä') ||
               value.Contains('Â') ||
               value.Contains('Æ') ||
               value.Contains('º') ||
               value.Contains('»') ||
               value.Contains('\u0090') ||
               value.Contains('\u0091');
    }

    private static string SlugifyExplore(string? value)
    {
        var normalized = RemoveExploreDiacritics((value ?? string.Empty).Trim()).ToLowerInvariant();
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

    private static string RemoveExploreDiacritics(string value)
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
}
