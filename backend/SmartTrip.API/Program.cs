using SmartTrip.API.Filters;
using SmartTrip.API.Middlewares;
using SmartTrip.Application.Interfaces.User;
using SmartTrip.Infrastructure.Services.User;
using SmartTrip.Application.Interfaces.Chat;
using SmartTrip.Application.Interfaces.Trip;
using SmartTrip.Application.Services.Chat;
using SmartTrip.Application.Services.Trip;
using SmartTrip.Application.Services;
using SmartTrip.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using SmartTrip.API.Data;
var builder = WebApplication.CreateBuilder(args);
LoadEnvFile(builder.Environment.ContentRootPath);

// Yêu cầu Configuration đọc thêm từ Environment Variables
builder.Configuration.AddEnvironmentVariables();
var apiPort = Environment.GetEnvironmentVariable("API_PORT");
if (int.TryParse(apiPort, out var parsedApiPort) && parsedApiPort > 0)
{
    var apiUrl = $"http://localhost:{parsedApiPort}";
    builder.WebHost.UseUrls(apiUrl);
    builder.Configuration["Urls"] = apiUrl;
}
builder.Logging.ClearProviders();
builder.Logging.AddConsole();
builder.Logging.AddDebug();

// Controllers
builder.Services.AddControllers(options =>
{
    options.Filters.Add(new ImageStorageExceptionFilter());
});
builder.Services.AddScoped<IUserService, UserService>(); // đưa vào ServiceExtensions cho gọn
builder.Services.AddScoped<IChatService, ChatService>(); // đưa vào ServiceExtensions cho gọn
builder.Services.AddHttpContextAccessor(); // Để lấy URL đầy đủ của ảnh

// CORS
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll",
        builder =>
        {
            builder.AllowAnyOrigin()
                   .AllowAnyMethod()
                   .AllowAnyHeader();   
        });
});
var connectionString = builder.Configuration.GetConnectionString("SmartTrip");
var dbPassword = Environment.GetEnvironmentVariable("DB_PASSWORD");
if (!string.IsNullOrEmpty(dbPassword))
{
    connectionString = connectionString?.Replace("Password= ;", $"Password={dbPassword};");
}
if (!string.IsNullOrWhiteSpace(connectionString))
{
    builder.Configuration["ConnectionStrings:SmartTrip"] = connectionString;
}
// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.AddEndpointsApiExplorer();

// Dependency Injection (Services)
builder.Services.AddScoped<IUserService, UserService>(); // đưa vào ServiceExtensions cho gọn
builder.Services.AddScoped<ITripServiceOptionService, TripServiceOptionService>(); // đưa vào ServiceExtensions cho gọn
builder.Services.AddScoped<IItineraryService, ItineraryService>(); // đưa vào ServiceExtensions cho gọn
builder.Services.AddScoped<ITripService, TripService>(); // đưa vào ServiceExtensions cho gọn

// Infrastructure
builder.Services.AddInfrastructure(builder.Configuration);

// Swagger
builder.Services.AddSwaggerConfiguration();

builder.Services.AddCustomApiBehavior();

// Application + Auth
builder.Services.AddApplicationServices();
builder.Services.AddJwtAuthentication(builder.Configuration);
builder.Services.AddAuthorization();

var app = builder.Build();

if (args.Contains("--eval-chatbot"))
{
    using (var scope = app.Services.CreateScope())
    {
        var chatService = scope.ServiceProvider.GetRequiredService<IChatService>();
        var aiService = scope.ServiceProvider.GetRequiredService<IGrokAiService>();
        var runner = new SmartTrip.API.Utilities.ChatbotEvalRunner(chatService, aiService);
        await runner.RunEvaluationAsync();
    }
    return;
}

using (var scope = app.Services.CreateScope())
{
    var dbContext = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
    await dbContext.Database.MigrateAsync();
    if (app.Environment.IsDevelopment())
    {
        await DevelopmentDataSeeder.SeedAsync(dbContext);
    }
}

// Middleware
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseCors("AllowAll");

app.UseStaticFiles(); // Phuc vu static asset san co; anh upload moi duoc luu tren Firebase Storage.

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

app.Run();

static void LoadEnvFile(string contentRootPath)
{
    var directory = new DirectoryInfo(contentRootPath);
    var envFiles = new Stack<string>();

    while (directory is not null)
    {
        var envPath = Path.Combine(directory.FullName, ".env");
        if (File.Exists(envPath))
        {
            envFiles.Push(envPath);
        }

        directory = directory.Parent;
    }

    if (envFiles.Count == 0)
    {
        return;
    }

    var mergedValues = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
    while (envFiles.Count > 0)
    {
        foreach (var pair in DotNetEnv.Env.LoadContents(File.ReadAllText(envFiles.Pop())))
        {
            mergedValues[pair.Key] = pair.Value;
        }
    }

    foreach (var pair in mergedValues)
    {
        if (!string.IsNullOrWhiteSpace(Environment.GetEnvironmentVariable(pair.Key)))
        {
            continue;
        }

        Environment.SetEnvironmentVariable(pair.Key, pair.Value);
    }
}
