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
using SmartTrip.Application.Interfaces.Explore;
using SmartTrip.Application.Interfaces.Notifications;
using SmartTrip.Application.Interfaces.Payment;
using SmartTrip.Application.Interfaces.Storage;
using SmartTrip.Application.Interfaces.User;
using SmartTrip.Application.Services.Auth;
using SmartTrip.Application.Services.Catalog;
using SmartTrip.Application.Services.Chat;
using SmartTrip.Application.Services.Email;
using SmartTrip.Application.Services.Explore;
using SmartTrip.Application.Services.Notifications;
using SmartTrip.Infrastructure.Repositories;
using SmartTrip.Infrastructure.Services.Admin;
using SmartTrip.Infrastructure.Services.AI;
using SmartTrip.Infrastructure.Services.Payment;
using SmartTrip.Infrastructure.Services.Notifications;
using SmartTrip.Infrastructure.Services.Storage;
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
            options.UseSqlServer(
                connectionString,
                sqlOptions => sqlOptions.EnableRetryOnFailure(
                    maxRetryCount: 5,
                    maxRetryDelay: TimeSpan.FromSeconds(10),
                    errorNumbersToAdd: null)));
        services.AddScoped<IApplicationDbContext>(provider => 
            provider.GetRequiredService<ApplicationDbContext>());

        services.Configure<GoogleAuthSettings>(configuration.GetSection("GoogleAuthSettings"));
        services.Configure<PayOsSettings>(options =>
        {
            options.ClientId = FirstNonEmpty(
                configuration["PayOs:ClientId"],
                configuration["PAYOS_CLIENT_ID"],
                Environment.GetEnvironmentVariable("PAYOS_CLIENT_ID"));
            options.ApiKey = FirstNonEmpty(
                configuration["PayOs:ApiKey"],
                configuration["PAYOS_API_KEY"],
                Environment.GetEnvironmentVariable("PAYOS_API_KEY"));
            options.ChecksumKey = FirstNonEmpty(
                configuration["PayOs:ChecksumKey"],
                configuration["PAYOS_CHECKSUM_KEY"],
                Environment.GetEnvironmentVariable("PAYOS_CHECKSUM_KEY"));
            options.BaseUrl = FirstNonEmpty(
                configuration["PayOs:BaseUrl"],
                "https://api-merchant.payos.vn");
        });
        services.Configure<VnPaySettings>(options =>
        {
            options.TmnCode = FirstNonEmpty(
                configuration["VnPay:TmnCode"],
                configuration["VNPAY_TMN_CODE"],
                Environment.GetEnvironmentVariable("VNPAY_TMN_CODE"));
            options.HashSecret = FirstNonEmpty(
                configuration["VnPay:HashSecret"],
                configuration["VNPAY_HASH_SECRET"],
                Environment.GetEnvironmentVariable("VNPAY_HASH_SECRET"));
            options.PaymentUrl = FirstNonEmpty(
                configuration["VnPay:PaymentUrl"],
                configuration["VNPAY_PAYMENT_URL"],
                Environment.GetEnvironmentVariable("VNPAY_PAYMENT_URL"),
                "https://sandbox.vnpayment.vn/paymentv2/vpcpay.html");
            options.ReturnUrl = FirstNonEmpty(
                configuration["VnPay:ReturnUrl"],
                configuration["VNPAY_RETURN_URL"],
                Environment.GetEnvironmentVariable("VNPAY_RETURN_URL"));
            options.IpnUrl = FirstNonEmpty(
                configuration["VnPay:IpnUrl"],
                configuration["VNPAY_IPN_URL"],
                Environment.GetEnvironmentVariable("VNPAY_IPN_URL"));
            options.Version = FirstNonEmpty(configuration["VnPay:Version"], "2.1.0");
            options.Command = FirstNonEmpty(configuration["VnPay:Command"], "pay");
            options.CurrCode = FirstNonEmpty(configuration["VnPay:CurrCode"], "VND");
            options.Locale = FirstNonEmpty(configuration["VnPay:Locale"], "vn");
            options.OrderType = FirstNonEmpty(configuration["VnPay:OrderType"], "other");
            options.ExpireMinutes = int.TryParse(FirstNonEmpty(configuration["VnPay:ExpireMinutes"], "15"), out var expireMinutes)
                ? expireMinutes
                : 15;
        });

        return services;
    }

    private static string FirstNonEmpty(params string?[] values)
    {
        foreach (var value in values)
        {
            if (!string.IsNullOrWhiteSpace(value))
            {
                return value.Trim().Trim('"', '\'');
            }
        }

        return string.Empty;
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
        services.AddScoped<IExploreService, ExploreService>();
        services.AddScoped<IFcmPushService, FcmPushService>();
        services.AddScoped<IImageStorageService, FirebaseImageStorageService>();
        services.AddScoped<INotificationService, NotificationService>();
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
