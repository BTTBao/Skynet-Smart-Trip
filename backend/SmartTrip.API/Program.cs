﻿using SmartTrip.API.Middlewares;
using SmartTrip.Application.Interfaces.User;
using SmartTrip.Infrastructure.Services.User;
using SmartTrip.Application.Interfaces.Chat;
using SmartTrip.Application.Services.Chat;
using SmartTrip.Application.Interfaces.Trip;
using SmartTrip.Application.Services.Trip;
using SmartTrip.Application.Services;
using SmartTrip.Domain.Entities;
using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);
LoadEnvFile(builder.Environment.ContentRootPath);

// Yêu cầu Configuration đọc thêm từ Environment Variables
builder.Configuration.AddEnvironmentVariables();
// Controllers
builder.Services.AddControllers();
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
builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("SmartTrip")));
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

// Middleware
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseCors("AllowAll");

app.UseStaticFiles(); // Cho phép truy cập file trong wwwroot (ảnh đại diện)

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

app.Run();

static void LoadEnvFile(string contentRootPath)
{
    var candidatePaths = new[]
    {
        Path.Combine(contentRootPath, ".env"),
        Path.Combine(contentRootPath, "..", ".env"),
        Path.Combine(contentRootPath, "..", "..", ".env")
    };

    foreach (var candidatePath in candidatePaths)
    {
        var fullPath = Path.GetFullPath(candidatePath);
        if (!File.Exists(fullPath))
        {
            continue;
        }

        DotNetEnv.Env.Load(fullPath);
        break;
    }
}
