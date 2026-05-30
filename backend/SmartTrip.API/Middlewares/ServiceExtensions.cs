using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using SmartTrip.Application.Configurations;
using SmartTrip.Application.Interfaces.Admin;
using SmartTrip.Application.Interfaces.Chat;
using SmartTrip.Application.Interfaces.Catalog;
using SmartTrip.Application.Interfaces.Auth;
using SmartTrip.Application.Interfaces.Email;
using SmartTrip.Application.Interfaces.Payment;
using SmartTrip.Application.Interfaces.User;
using SmartTrip.Application.Services.Auth;
using SmartTrip.Application.Services.Catalog;
using SmartTrip.Application.Services.Chat;
using SmartTrip.Application.Services.Email;
using SmartTrip.Infrastructure.Repositories;
using SmartTrip.Infrastructure.Services.Admin;
using SmartTrip.Infrastructure.Services.AI;
using SmartTrip.Infrastructure.Services.Payment;
using SmartTrip.Infrastructure.Services.User;
using System.Text;

namespace SmartTrip.API.Middlewares;

public static class ServiceExtensions
{
    public static IServiceCollection AddInfrastructure(this IServiceCollection services, IConfiguration configuration)
    {
        var connectionString = configuration.GetConnectionString("SmartTrip");
        var dbPassword = Environment.GetEnvironmentVariable("DB_PASSWORD");

        if (!string.IsNullOrWhiteSpace(dbPassword))
        {
            connectionString = connectionString?.Replace("Password= ;", $"Password={dbPassword};");
        }

        services.AddDbContext<ApplicationDbContext>(options =>
            options.UseSqlServer(connectionString));
        services.AddScoped<IApplicationDbContext>(provider => 
            provider.GetRequiredService<ApplicationDbContext>());

        services.Configure<GoogleAuthSettings>(configuration.GetSection("GoogleAuthSettings"));
        services.Configure<PayOsSettings>(options =>
        {
            options.ClientId = configuration["PayOs:ClientId"] ?? configuration["PAYOS_CLIENT_ID"] ?? string.Empty;
            options.ApiKey = configuration["PayOs:ApiKey"] ?? configuration["PAYOS_API_KEY"] ?? string.Empty;
            options.ChecksumKey = configuration["PayOs:ChecksumKey"] ?? configuration["PAYOS_CHECKSUM_KEY"] ?? string.Empty;
            options.BaseUrl = configuration["PayOs:BaseUrl"] ?? "https://api-merchant.payos.vn";
        });

        return services;
    }

    public static IServiceCollection AddApplicationServices(this IServiceCollection services)
    {
        services.AddScoped<IUserRepository, UserRepository>();
        services.AddScoped<IUserService, UserService>();
        services.AddScoped<IChatService, ChatService>();
        services.AddScoped<IChatRepository, ChatRepository>();
        services.AddScoped<IAuthService, AuthService>();
        services.AddScoped<ICatalogService, CatalogService>();
        services.AddSingleton<ITokenService, TokenService>();
        services.AddScoped<IEmailService, EmailService>();
        services.AddHttpClient<IGrokAiService, GrokAiService>();
        services.AddHttpClient<IPaymentService, PayOsPaymentService>((provider, client) =>
        {
            var settings = provider.GetRequiredService<Microsoft.Extensions.Options.IOptions<PayOsSettings>>().Value;
            client.BaseAddress = new Uri(settings.BaseUrl);
            client.Timeout = TimeSpan.FromSeconds(30);
        });
        services.AddHttpContextAccessor();

        // Admin
        services.AddScoped<IAdminService, AdminService>();

        return services;
    }

    public static IServiceCollection AddJwtAuthentication(this IServiceCollection services, IConfiguration configuration)
    {
        var jwtKey = configuration["Jwt:Key"] ?? throw new ArgumentException("Missing Jwt Key");
        services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
            .AddJwtBearer(options =>
            {
                options.TokenValidationParameters = new TokenValidationParameters
                {
                    ValidateIssuer = true,
                    ValidateAudience = true,
                    ValidateLifetime = true,
                    ValidateIssuerSigningKey = true,
                    ValidIssuer = configuration["Jwt:Issuer"],
                    ValidAudience = configuration["Jwt:Audience"],
                    IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey)),
                    ClockSkew = TimeSpan.Zero
                };
            });

        return services;
    }

    public static IServiceCollection AddSwaggerConfiguration(this IServiceCollection services)
    {
        services.AddSwaggerGen(c =>
        {
            c.SwaggerDoc("v1", new OpenApiInfo { Title = "SmartTrip API", Version = "v1" });

            c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
            {
                Description = "Nhập: Bearer + [token]",
                Name = "Authorization",
                In = ParameterLocation.Header,
                Type = SecuritySchemeType.ApiKey,
                Scheme = "Bearer"
            });

            c.AddSecurityRequirement(new OpenApiSecurityRequirement
            {
                {
                    new OpenApiSecurityScheme
                    {
                        Reference = new OpenApiReference { Type = ReferenceType.SecurityScheme, Id = "Bearer" }
                    },
                    Array.Empty<string>()
                }
            });
        });

        return services;
    }

    public static IServiceCollection AddCustomApiBehavior(this IServiceCollection services)
    {
        services.Configure<ApiBehaviorOptions>(options =>
        {
            options.InvalidModelStateResponseFactory = context =>
            {
                var firstError = context.ModelState
                    .Values
                    .SelectMany(v => v.Errors)
                    .FirstOrDefault()?.ErrorMessage;

                return new BadRequestObjectResult(new
                {
                    success = false,
                    message = firstError
                });
            };
        });

        return services;
    }
}
