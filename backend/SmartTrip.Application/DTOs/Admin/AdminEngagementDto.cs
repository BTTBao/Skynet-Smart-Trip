namespace SmartTrip.Application.DTOs.Admin;

public class AdminExplorePostDto
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
    public string CreatedAt { get; set; } = string.Empty;
    public bool IsVisible { get; set; }
    public int CostLevel { get; set; }
    public int Likes { get; set; }
    public int Saves { get; set; }
    public int Views { get; set; }
    public int CommentCount { get; set; }
    public double Rating { get; set; }
    public int RatingCount { get; set; }
    public List<string> Tags { get; set; } = [];
}

public class AdminExplorePostRequest
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
    public bool IsVisible { get; set; } = true;
    public List<string> ImageUrls { get; set; } = [];
    public List<string> Tags { get; set; } = [];
}

public class AdminExploreVisibilityRequest
{
    public bool IsVisible { get; set; }
}

public class AdminNotificationDto
{
    public int Id { get; set; }
    public int? UserId { get; set; }
    public string UserName { get; set; } = string.Empty;
    public string UserEmail { get; set; } = string.Empty;
    public string Title { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
    public string Type { get; set; } = string.Empty;
    public string? ReferenceType { get; set; }
    public int? ReferenceId { get; set; }
    public string? ActionUrl { get; set; }
    public bool IsRead { get; set; }
    public string CreatedAt { get; set; } = string.Empty;
}

public class AdminNotificationStatsDto
{
    public int TotalNotifications { get; set; }
    public int UnreadNotifications { get; set; }
    public int ReadNotifications { get; set; }
    public int TargetableUsers { get; set; }
    public List<AdminNotificationDto> Notifications { get; set; } = [];
}

public class AdminSendNotificationRequest
{
    public string RecipientMode { get; set; } = "all";
    public List<int> UserIds { get; set; } = [];
    public string? Role { get; set; }
    public List<string> Channels { get; set; } = ["in_app"];
    public string Title { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
    public string Type { get; set; } = "system";
    public string? ReferenceType { get; set; }
    public int? ReferenceId { get; set; }
    public string? ActionUrl { get; set; }
}

public class AdminNotificationSendResultDto
{
    public int TargetedUsers { get; set; }
    public int InAppCreated { get; set; }
    public int PushAttempted { get; set; }
    public int EmailAttempted { get; set; }
    public int EmailSent { get; set; }
    public int Failed { get; set; }
    public List<string> Errors { get; set; } = [];
}
