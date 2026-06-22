using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SmartTrip.API.Utilities;
using SmartTrip.Application.DTOs.Admin;
using SmartTrip.Application.Interfaces.Admin;
using SmartTrip.Application.Interfaces.Storage;
using System.Security.Claims;
using System.Threading.Tasks;

namespace SmartTrip.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Roles = "Admin,Staff")]
public class AdminController : ControllerBase
{
    private const long MaxImageSizeBytes = 5 * 1024 * 1024;

    private readonly IAdminService _adminService;
    private readonly IImageStorageService _imageStorageService;

    public AdminController(IAdminService adminService, IImageStorageService imageStorageService)
    {
        _adminService = adminService;
        _imageStorageService = imageStorageService;
    }

    [HttpPost("uploads/room-images")]
    [Consumes("multipart/form-data")]
    [RequestSizeLimit(10 * 1024 * 1024)]
    public async Task<IActionResult> UploadRoomImage([FromForm] AdminImageUploadRequest request)
    {
        var validationError = ValidateImageFile(request.File, "anh phong");
        if (validationError != null) return validationError;

        var upload = await UploadImageAsync(request.File!, "admin/rooms");

        return Ok(new
        {
            imageUrl = upload.ImageUrl,
            imagePath = upload.ImagePath,
            fileName = upload.FileName,
            relativeUrl = upload.ImagePath
        });
    }

    [HttpPost("uploads/destination-covers")]
    [Consumes("multipart/form-data")]
    [RequestSizeLimit(10 * 1024 * 1024)]
    public async Task<IActionResult> UploadDestinationCover([FromForm] AdminImageUploadRequest request)
    {
        var validationError = ValidateImageFile(request.File, "anh cover diem den");
        if (validationError != null) return validationError;

        var upload = await UploadImageAsync(request.File!, "destinations/covers");
        return Ok(new
        {
            imageUrl = upload.ImageUrl,
            imagePath = upload.ImagePath,
            fileName = upload.FileName,
            relativeUrl = upload.ImagePath
        });
    }

    [HttpPost("uploads/transport-company-logos")]
    [Consumes("multipart/form-data")]
    [RequestSizeLimit(10 * 1024 * 1024)]
    public async Task<IActionResult> UploadTransportCompanyLogo([FromForm] AdminImageUploadRequest request)
    {
        var validationError = ValidateImageFile(request.File, "logo nha xe");
        if (validationError != null) return validationError;

        var upload = await UploadImageAsync(request.File!, "transport/companies/logos");
        return Ok(new
        {
            imageUrl = upload.ImageUrl,
            imagePath = upload.ImagePath,
            fileName = upload.FileName,
            relativeUrl = upload.ImagePath
        });
    }

    [HttpPost("uploads/vehicle-rental-images")]
    [Consumes("multipart/form-data")]
    [RequestSizeLimit(10 * 1024 * 1024)]
    public async Task<IActionResult> UploadVehicleRentalImage([FromForm] AdminImageUploadRequest request)
    {
        var validationError = ValidateImageFile(request.File, "anh thue xe");
        if (validationError != null) return validationError;

        var upload = await UploadImageAsync(request.File!, "vehicle-rental/shops");
        return Ok(new
        {
            imageUrl = upload.ImageUrl,
            imagePath = upload.ImagePath,
            fileName = upload.FileName,
            relativeUrl = upload.ImagePath
        });
    }

    [HttpGet("dashboard")]
    public async Task<IActionResult> GetDashboardStats([FromQuery] DateOnly? startDate, [FromQuery] DateOnly? endDate)
    {
        var stats = await _adminService.GetDashboardStatsAsync(startDate, endDate);
        return Ok(stats);
    }

    [HttpGet("users")]
    public async Task<IActionResult> GetUsers([FromQuery] string? search)
    {
        var users = await _adminService.GetUsersAsync(search);
        return Ok(users);
    }

    [HttpPost("users")]
    public async Task<IActionResult> CreateUser([FromBody] AdminCreateUserRequest request)
    {
        var user = await _adminService.CreateUserAsync(request);
        return Ok(user);
    }

    [HttpPut("users/{userId:int}")]
    public async Task<IActionResult> UpdateUser(int userId, [FromBody] AdminUpdateUserRequest request)
    {
        var user = await _adminService.UpdateUserAsync(userId, request);
        return Ok(user);
    }

    [HttpPatch("users/{userId:int}/status")]
    public async Task<IActionResult> UpdateUserStatus(int userId, [FromBody] AdminUpdateUserStatusRequest request)
    {
        var user = await _adminService.UpdateUserStatusAsync(userId, request.IsActive);
        return Ok(user);
    }

    [HttpPost("users/{userId:int}/reset-password")]
    public async Task<IActionResult> ResetUserPassword(int userId)
    {
        var payload = await _adminService.ResetUserPasswordAsync(userId);
        return Ok(payload);
    }

    [HttpDelete("users/{userId:int}")]
    public async Task<IActionResult> DeleteUser(int userId)
    {
        await _adminService.DeleteUserAsync(userId);
        return NoContent();
    }

    [HttpGet("transport")]
    public async Task<IActionResult> GetTransportStats()
    {
        var transportStats = await _adminService.GetTransportStatsAsync();
        return Ok(transportStats);
    }

    [HttpPost("transport/schedules")]
    public async Task<IActionResult> CreateTransportSchedule([FromBody] AdminCreateTransportScheduleRequest request)
    {
        var schedule = await _adminService.CreateTransportScheduleAsync(request);
        return Ok(schedule);
    }

    [HttpPut("transport/schedules/{scheduleId:int}")]
    public async Task<IActionResult> UpdateTransportSchedule(int scheduleId, [FromBody] AdminUpdateTransportScheduleRequest request)
    {
        var schedule = await _adminService.UpdateTransportScheduleAsync(scheduleId, request);
        return Ok(schedule);
    }

    [HttpDelete("transport/schedules/{scheduleId:int}")]
    public async Task<IActionResult> DeleteTransportSchedule(int scheduleId)
    {
        await _adminService.DeleteTransportScheduleAsync(scheduleId);
        return NoContent();
    }

    [HttpGet("transport/companies")]
    public async Task<IActionResult> GetTransportCompanies()
    {
        var companies = await _adminService.GetTransportCompaniesAsync();
        return Ok(companies);
    }

    [HttpPost("transport/companies")]
    public async Task<IActionResult> CreateTransportCompany([FromBody] AdminCreateTransportCompanyRequest request)
    {
        var company = await _adminService.CreateTransportCompanyAsync(request);
        return Ok(company);
    }

    [HttpPut("transport/companies/{companyId:int}")]
    public async Task<IActionResult> UpdateTransportCompany(int companyId, [FromBody] AdminUpdateTransportCompanyRequest request)
    {
        var company = await _adminService.UpdateTransportCompanyAsync(companyId, request);
        return Ok(company);
    }

    [HttpDelete("transport/companies/{companyId:int}")]
    public async Task<IActionResult> DeleteTransportCompany(int companyId)
    {
        await _adminService.DeleteTransportCompanyAsync(companyId);
        return NoContent();
    }

    [HttpPut("transport/schedules/{scheduleId:int}/seats")]
    public async Task<IActionResult> UpdateSeatMap(int scheduleId, [FromBody] List<AdminUpdateSeatRequest> seats)
    {
        var updatedSeats = await _adminService.UpdateSeatMapAsync(scheduleId, seats);
        return Ok(updatedSeats);
    }

    [HttpGet("bookings")]
    public async Task<IActionResult> GetBookingStats()
    {
        var bookingStats = await _adminService.GetBookingStatsAsync();
        return Ok(bookingStats);
    }

    [HttpGet("bookings/{bookingId:int}")]
    public async Task<IActionResult> GetBookingDetail(int bookingId)
    {
        var booking = await _adminService.GetBookingDetailAsync(bookingId);
        return Ok(booking);
    }

    [HttpPatch("bookings/{bookingId:int}/status")]
    public async Task<IActionResult> UpdateBookingStatus(int bookingId, [FromBody] AdminUpdateBookingStatusRequest request)
    {
        var booking = await _adminService.UpdateBookingStatusAsync(bookingId, request);
        return Ok(booking);
    }

    [HttpGet("destinations")]
    public async Task<IActionResult> GetDestinations()
    {
        var destinations = await _adminService.GetDestinationsAsync();
        return Ok(destinations);
    }

    [HttpPost("destinations")]
    public async Task<IActionResult> CreateDestination([FromBody] AdminDestinationRequest request)
    {
        var destination = await _adminService.CreateDestinationAsync(request);
        return Ok(destination);
    }

    [HttpPut("destinations/{destinationId:int}")]
    public async Task<IActionResult> UpdateDestination(int destinationId, [FromBody] AdminDestinationRequest request)
    {
        var destination = await _adminService.UpdateDestinationAsync(destinationId, request);
        return Ok(destination);
    }

    [HttpDelete("destinations/{destinationId:int}")]
    public async Task<IActionResult> DeleteDestination(int destinationId)
    {
        await _adminService.DeleteDestinationAsync(destinationId);
        return NoContent();
    }

    [HttpGet("hotels")]
    public async Task<IActionResult> GetHotels()
    {
        var hotels = await _adminService.GetHotelsAsync();
        return Ok(hotels);
    }

    [HttpGet("hotels/{hotelId:int}")]
    public async Task<IActionResult> GetHotelDetail(int hotelId)
    {
        var hotel = await _adminService.GetHotelDetailAsync(hotelId);
        return Ok(hotel);
    }

    [HttpPost("hotels")]
    public async Task<IActionResult> CreateHotel([FromBody] AdminHotelRequest request)
    {
        var hotel = await _adminService.CreateHotelAsync(request);
        return Ok(hotel);
    }

    [HttpPut("hotels/{hotelId:int}")]
    public async Task<IActionResult> UpdateHotel(int hotelId, [FromBody] AdminHotelRequest request)
    {
        var hotel = await _adminService.UpdateHotelAsync(hotelId, request);
        return Ok(hotel);
    }

    [HttpPost("hotels/{hotelId:int}/rooms")]
    public async Task<IActionResult> CreateRoom(int hotelId, [FromBody] AdminRoomRequest request)
    {
        var room = await _adminService.CreateRoomAsync(hotelId, request);
        return Ok(room);
    }

    [HttpPut("rooms/{roomId:int}")]
    public async Task<IActionResult> UpdateRoom(int roomId, [FromBody] AdminRoomRequest request)
    {
        var room = await _adminService.UpdateRoomAsync(roomId, request);
        return Ok(room);
    }

    [HttpDelete("rooms/{roomId:int}")]
    public async Task<IActionResult> DeleteRoom(int roomId)
    {
        await _adminService.DeleteRoomAsync(roomId);
        return NoContent();
    }

    [HttpDelete("hotels/{hotelId:int}")]
    public async Task<IActionResult> DeleteHotel(int hotelId)
    {
        await _adminService.DeleteHotelAsync(hotelId);
        return NoContent();
    }

    [HttpGet("promotions")]
    public async Task<IActionResult> GetPromotions()
    {
        var promotions = await _adminService.GetPromotionsAsync();
        return Ok(promotions);
    }

    [HttpPost("promotions")]
    public async Task<IActionResult> CreatePromotion([FromBody] AdminPromotionRequest request)
    {
        var promotion = await _adminService.CreatePromotionAsync(request);
        return Ok(promotion);
    }

    [HttpPut("promotions/{promotionId:int}")]
    public async Task<IActionResult> UpdatePromotion(int promotionId, [FromBody] AdminPromotionRequest request)
    {
        var promotion = await _adminService.UpdatePromotionAsync(promotionId, request);
        return Ok(promotion);
    }

    [HttpDelete("promotions/{promotionId:int}")]
    public async Task<IActionResult> DeletePromotion(int promotionId)
    {
        await _adminService.DeletePromotionAsync(promotionId);
        return NoContent();
    }

    [HttpGet("vehicle-rental/shops")]
    public async Task<IActionResult> GetVehicleRentalShops()
    {
        var shops = await _adminService.GetVehicleRentalShopsAsync();
        return Ok(shops);
    }

    [HttpGet("vehicle-rental/shops/{shopId:int}")]
    public async Task<IActionResult> GetVehicleRentalShopDetail(int shopId)
    {
        var shop = await _adminService.GetVehicleRentalShopDetailAsync(shopId);
        return Ok(shop);
    }

    [HttpPost("vehicle-rental/shops")]
    public async Task<IActionResult> CreateVehicleRentalShop([FromBody] AdminVehicleRentalShopRequest request)
    {
        var shop = await _adminService.CreateVehicleRentalShopAsync(request);
        return Ok(shop);
    }

    [HttpPut("vehicle-rental/shops/{shopId:int}")]
    public async Task<IActionResult> UpdateVehicleRentalShop(int shopId, [FromBody] AdminVehicleRentalShopRequest request)
    {
        var shop = await _adminService.UpdateVehicleRentalShopAsync(shopId, request);
        return Ok(shop);
    }

    [HttpDelete("vehicle-rental/shops/{shopId:int}")]
    public async Task<IActionResult> DeleteVehicleRentalShop(int shopId)
    {
        await _adminService.DeleteVehicleRentalShopAsync(shopId);
        return NoContent();
    }

    [HttpGet("reports/summary")]
    public async Task<IActionResult> GetReportSummary()
    {
        var report = await _adminService.GetReportSummaryAsync();
        return Ok(report);
    }

    [HttpGet("explore/posts")]
    public async Task<IActionResult> GetExplorePosts([FromQuery] string? search)
    {
        var posts = await _adminService.GetExplorePostsAsync(search);
        return Ok(posts);
    }

    [HttpPost("explore/posts")]
    public async Task<IActionResult> CreateExplorePost([FromBody] AdminExplorePostRequest request)
    {
        var post = await _adminService.CreateExplorePostAsync(request, GetCurrentUserId());
        return Ok(post);
    }

    [HttpPut("explore/posts/{postId:int}")]
    public async Task<IActionResult> UpdateExplorePost(int postId, [FromBody] AdminExplorePostRequest request)
    {
        var post = await _adminService.UpdateExplorePostAsync(postId, request);
        return Ok(post);
    }

    [HttpPatch("explore/posts/{postId:int}/visibility")]
    public async Task<IActionResult> UpdateExplorePostVisibility(int postId, [FromBody] AdminExploreVisibilityRequest request)
    {
        var post = await _adminService.UpdateExplorePostVisibilityAsync(postId, request.IsVisible);
        return Ok(post);
    }

    [HttpDelete("explore/posts/{postId:int}")]
    public async Task<IActionResult> DeleteExplorePost(int postId)
    {
        await _adminService.DeleteExplorePostAsync(postId);
        return NoContent();
    }

    [HttpGet("notifications")]
    public async Task<IActionResult> GetNotifications([FromQuery] string? search)
    {
        var notifications = await _adminService.GetNotificationsAsync(search);
        return Ok(notifications);
    }

    [HttpPost("notifications/send")]
    public async Task<IActionResult> SendNotification([FromBody] AdminSendNotificationRequest request)
    {
        var result = await _adminService.SendNotificationAsync(request);
        return Ok(result);
    }

    [HttpGet("payments")]
    public async Task<IActionResult> GetPayments()
    {
        var payments = await _adminService.GetPaymentHistoryAsync();
        return Ok(payments);
    }

    [HttpGet("reviews")]
    public async Task<IActionResult> GetReviews()
    {
        var reviews = await _adminService.GetReviewsAsync();
        return Ok(reviews);
    }

    [HttpDelete("reviews/{reviewId:int}")]
    public async Task<IActionResult> DeleteReview(int reviewId)
    {
        await _adminService.DeleteReviewAsync(reviewId);
        return NoContent();
    }

    private async Task<ImageStorageUploadResult> UploadImageAsync(IFormFile file, string folder)
    {
        await using var stream = file.OpenReadStream();
        if (!ImageUploadValidation.TryValidateImageStream(stream, file.FileName, out var errorMessage, out var resolvedContentType))
        {
            throw new ArgumentException(errorMessage ?? "Chi ho tro anh JPG, PNG hoac WEBP.");
        }

        return await _imageStorageService.UploadImageAsync(
            stream,
            file.FileName,
            resolvedContentType ?? file.ContentType,
            folder,
            HttpContext.RequestAborted);
    }

    private IActionResult? ValidateImageFile(IFormFile? file, string displayName)
    {
        if (file == null || file.Length == 0)
        {
            return BadRequest(new { message = $"Vui long chon {displayName}." });
        }

        if (file.Length > MaxImageSizeBytes)
        {
            return BadRequest(new { message = $"{displayName} khong duoc vuot qua 5MB." });
        }

        if (!ImageUploadValidation.TryValidateImageFile(file, out var errorMessage, out _))
        {
            return BadRequest(new { message = errorMessage ?? "Chi ho tro anh JPG, PNG hoac WEBP." });
        }

        return null;
    }

    private int GetCurrentUserId()
    {
        var rawUserId = User.FindFirstValue(ClaimTypes.NameIdentifier)
            ?? User.FindFirstValue(ClaimTypes.Name)
            ?? User.FindFirstValue(ClaimTypes.Sid)
            ?? User.FindFirstValue("sub");

        if (!int.TryParse(rawUserId, out var userId) || userId <= 0)
        {
            throw new UnauthorizedAccessException("Invalid admin token.");
        }

        return userId;
    }
}