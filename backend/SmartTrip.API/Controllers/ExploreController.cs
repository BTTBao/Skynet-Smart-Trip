using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SmartTrip.Application.DTOs.Explore;
using SmartTrip.Application.Interfaces.Explore;
using System.Security.Claims;

namespace SmartTrip.API.Controllers;

[ApiController]
[Route("api/explore")]
public class ExploreController : ControllerBase
{
    private readonly IExploreService _exploreService;
    private readonly IWebHostEnvironment _environment;

    public ExploreController(IExploreService exploreService, IWebHostEnvironment environment)
    {
        _exploreService = exploreService;
        _environment = environment;
    }

    [HttpGet("posts")]
    public async Task<IActionResult> GetPosts([FromQuery] ExplorePostQueryDto query)
    {
        var posts = await _exploreService.GetPostsAsync(query, GetCurrentUserId());
        return Ok(posts);
    }

    [HttpGet("posts/{postId:int}")]
    public async Task<IActionResult> GetPostById(int postId)
    {
        try
        {
            var post = await _exploreService.GetPostByIdAsync(postId, GetCurrentUserId());
            return post == null
                ? NotFound(new { message = $"Explore post {postId} was not found." })
                : Ok(post);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [Authorize]
    [HttpPost("posts")]
    public async Task<IActionResult> CreatePost([FromBody] CreateExplorePostDto request)
    {
        var userId = GetCurrentUserId();
        if (userId == null)
        {
            return Unauthorized();
        }

        try
        {
            var post = await _exploreService.CreatePostAsync(request, userId.Value);
            return CreatedAtAction(nameof(GetPostById), new { postId = post.Id }, post);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
    }

    [Authorize]
    [HttpPost("posts/images")]
    [Consumes("multipart/form-data")]
    [RequestSizeLimit(10 * 1024 * 1024)]
    public async Task<IActionResult> UploadPostImage([FromForm] UploadExplorePostImageRequest request)
    {
        var userId = GetCurrentUserId();
        if (userId == null)
        {
            return Unauthorized();
        }

        var file = request.File;
        if (file == null || file.Length == 0)
        {
            return BadRequest(new { message = "Image file is required." });
        }

        if (file.Length > 5 * 1024 * 1024)
        {
            return BadRequest(new { message = "Image file must be 5MB or smaller." });
        }

        var extension = Path.GetExtension(file.FileName).ToLowerInvariant();
        var allowedExtensions = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
        {
            ".jpg",
            ".jpeg",
            ".png",
            ".webp"
        };
        if (!allowedExtensions.Contains(extension))
        {
            return BadRequest(new { message = "Only JPG, PNG, or WEBP images are supported." });
        }

        var webRoot = _environment.WebRootPath;
        if (string.IsNullOrWhiteSpace(webRoot))
        {
            webRoot = Path.Combine(_environment.ContentRootPath, "wwwroot");
        }

        var uploadDirectory = Path.Combine(webRoot, "uploads", "explore");
        Directory.CreateDirectory(uploadDirectory);

        var fileName = $"{userId.Value}-{DateTime.UtcNow:yyyyMMddHHmmssfff}-{Guid.NewGuid():N}{extension}";
        var filePath = Path.Combine(uploadDirectory, fileName);

        await using (var stream = System.IO.File.Create(filePath))
        {
            await file.CopyToAsync(stream);
        }

        var relativeUrl = $"/uploads/explore/{fileName}";
        var absoluteUrl = $"{Request.Scheme}://{Request.Host}{relativeUrl}";

        return Ok(new { imageUrl = absoluteUrl, relativeUrl });
    }

    [Authorize]
    [HttpPost("posts/{postId:int}/like")]
    public async Task<IActionResult> ToggleLike(int postId)
    {
        return await RunAuthenticatedToggle(userId => _exploreService.ToggleLikeAsync(postId, userId));
    }

    [Authorize]
    [HttpPost("posts/{postId:int}/save")]
    public async Task<IActionResult> ToggleSave(int postId)
    {
        return await RunAuthenticatedToggle(userId => _exploreService.ToggleSaveAsync(postId, userId));
    }

    [HttpGet("posts/{postId:int}/comments")]
    public async Task<IActionResult> GetComments(int postId, [FromQuery] int page = 1, [FromQuery] int pageSize = 20)
    {
        try
        {
            var comments = await _exploreService.GetCommentsAsync(postId, page, pageSize);
            return Ok(comments);
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
    }

    [Authorize]
    [HttpPost("posts/{postId:int}/comments")]
    public async Task<IActionResult> AddComment(int postId, [FromBody] CreateExploreCommentDto request)
    {
        var userId = GetCurrentUserId();
        if (userId == null)
        {
            return Unauthorized();
        }

        try
        {
            var comment = await _exploreService.AddCommentAsync(postId, request, userId.Value);
            return CreatedAtAction(nameof(GetComments), new { postId }, comment);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
    }

    [Authorize]
    [HttpPost("posts/{postId:int}/rating")]
    public async Task<IActionResult> RatePost(int postId, [FromBody] RateExplorePostDto request)
    {
        var userId = GetCurrentUserId();
        if (userId == null)
        {
            return Unauthorized();
        }

        try
        {
            var rating = await _exploreService.RatePostAsync(postId, request, userId.Value);
            return Ok(rating);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
    }

    [HttpGet("filters")]
    public async Task<IActionResult> GetFilterData()
    {
        return Ok(await _exploreService.GetFilterDataAsync());
    }

    [HttpGet("locations")]
    public async Task<IActionResult> SearchLocations(
        [FromQuery] string? keyword,
        [FromQuery] string? region,
        [FromQuery] int limit = 12)
    {
        return Ok(await _exploreService.SearchLocationsAsync(keyword, region, limit));
    }

    private async Task<IActionResult> RunAuthenticatedToggle<T>(Func<int, Task<T>> action)
    {
        var userId = GetCurrentUserId();
        if (userId == null)
        {
            return Unauthorized();
        }

        try
        {
            return Ok(await action(userId.Value));
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
    }

    private int? GetCurrentUserId()
    {
        var rawUserId = User.FindFirstValue(ClaimTypes.NameIdentifier)
            ?? User.FindFirstValue(ClaimTypes.Name)
            ?? User.FindFirstValue(ClaimTypes.Sid)
            ?? User.FindFirstValue("sub");

        return int.TryParse(rawUserId, out var userId) ? userId : null;
    }
}

public sealed class UploadExplorePostImageRequest
{
    public IFormFile? File { get; set; }
}
