using SmartTrip.API.Middlewares;
using SmartTrip.Application.Interfaces.Trip;
using SmartTrip.Application.Interfaces.User;
using SmartTrip.Application.Services.Trip;
using SmartTrip.Application.Services;

var builder = WebApplication.CreateBuilder(args);

// Controllers
builder.Services.AddControllers();
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

app.UseCors();

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

app.Run();