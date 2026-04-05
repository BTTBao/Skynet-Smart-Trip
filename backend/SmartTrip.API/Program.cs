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
using System.Text;
LoadDotEnvIntoEnvironmentVariables(Directory.GetCurrentDirectory());
var builder = WebApplication.CreateBuilder(args);

// Controllers
builder.Services.AddControllers();
builder.Services.AddScoped<IUserService, UserService>();
builder.Services.AddScoped<IChatService, ChatService>();    
builder.Services.AddHttpContextAccessor(); // Để lấy URL đầy đủ của ảnh

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
builder.Services.AddScoped<IUserService, UserService>();
builder.Services.AddScoped<ITripServiceOptionService, TripServiceOptionService>();
builder.Services.AddScoped<IItineraryService, ItineraryService>();
builder.Services.AddScoped<ITripService, TripService>();

// Infrastructure
builder.Services.AddInfrastructure(builder.Configuration);

// CORS
builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader();
    });
});

// Swagger
builder.Services.AddSwaggerConfiguration();

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

app.UseAuthorization();

app.MapControllers();

app.Run();

static void LoadDotEnvIntoEnvironmentVariables(string startDirectory)
{
    var directory = new DirectoryInfo(startDirectory);

    while (directory is not null)
    {
        var envPath = Path.Combine(directory.FullName, ".env");
        if (File.Exists(envPath))
        {
            foreach (var rawLine in File.ReadAllLines(envPath, Encoding.UTF8))
            {
                var line = rawLine.Trim();
                if (string.IsNullOrWhiteSpace(line) || line.StartsWith('#'))
                {
                    continue;
                }

                var separatorIndex = line.IndexOf('=');
                if (separatorIndex <= 0)
                {
                    continue;
                }

                var key = line[..separatorIndex].Trim();
                var value = line[(separatorIndex + 1)..].Trim().Trim('"');

                if (string.IsNullOrWhiteSpace(key) || !string.IsNullOrWhiteSpace(Environment.GetEnvironmentVariable(key)))
                {
                    continue;
                }

                Environment.SetEnvironmentVariable(key, value);
            }

            return;
        }

        directory = directory.Parent;
    }
}
