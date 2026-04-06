namespace SmartTrip.Application.DTOs.User;

public class UpdateUserProfileRequestDto
{
    public string Name { get; set; } = string.Empty;
    public string? Phone { get; set; }
    public string? BirthDate { get; set; }
}

public class UserFavoriteDto
{
    public int WishId { get; set; }
    public string ItemType { get; set; } = string.Empty;
    public int ItemId { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Subtitle { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string? PriceLabel { get; set; }
    public string? StatusLabel { get; set; }
    public string? CreatedAt { get; set; }
}

public class CreateFavoriteRequestDto
{
    public string ItemType { get; set; } = string.Empty;
    public int ItemId { get; set; }
}

public class UserSettingsDto
{
    public string Email { get; set; } = string.Empty;
    public bool IsEmailVerified { get; set; }
    public bool PushNotificationEnabled { get; set; }
    public bool EmailOfferEnabled { get; set; }
    public bool DarkModeEnabled { get; set; }
    public string Language { get; set; } = "vi";
    public string Currency { get; set; } = "VND";
}

public class UpdateUserSettingsDto
{
    public bool PushNotificationEnabled { get; set; }
    public bool EmailOfferEnabled { get; set; }
    public bool DarkModeEnabled { get; set; }
    public string Language { get; set; } = "vi";
    public string Currency { get; set; } = "VND";
}

public class ChangePasswordRequestDto
{
    public string CurrentPassword { get; set; } = string.Empty;
    public string NewPassword { get; set; } = string.Empty;
    public string ConfirmNewPassword { get; set; } = string.Empty;
}

public class UserActionResultDto
{
    public bool Success { get; set; }
    public string Message { get; set; } = string.Empty;
}
