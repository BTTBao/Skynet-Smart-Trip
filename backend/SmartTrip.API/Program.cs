using SmartTrip.Application.Interfaces.Trip;
using SmartTrip.Application.Interfaces.User;
using SmartTrip.Application.Services.Trip;
using SmartTrip.Application.Services.User;
using SmartTrip.Infrastructure;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.

builder.Services.AddControllers();
builder.Services.AddScoped<IUserService, UserService>();
builder.Services.AddScoped<ITripServiceOptionService, TripServiceOptionService>();
builder.Services.AddScoped<IItineraryService, ItineraryService>();
builder.Services.AddScoped<ITripService, TripService>();
builder.Services.AddInfrastructure(builder.Configuration);
builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(policy =>
        policy.AllowAnyOrigin().AllowAnyHeader().AllowAnyMethod());
});
// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseCors();
app.UseAuthorization();

app.MapControllers();

app.Run();
