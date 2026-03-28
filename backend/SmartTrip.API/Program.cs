<<<<<<< Updated upstream
﻿using SmartTrip.API.Middlewares;
=======
using SmartTrip.Application.Interfaces.User;
using SmartTrip.Infrastructure.Services.User;
using SmartTrip.Application.Interfaces.Chat;
using SmartTrip.Application.Services.Chat;
using SmartTrip.Domain.Entities;
using Microsoft.EntityFrameworkCore;
>>>>>>> Stashed changes

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();
<<<<<<< Updated upstream
=======
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
>>>>>>> Stashed changes
builder.Services.AddEndpointsApiExplorer();

builder.Services.AddInfrastructure(builder.Configuration);

builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(policy =>
    {
        policy.AllowAnyOrigin().AllowAnyMethod().AllowAnyHeader();
    });
});

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerConfiguration();

builder.Services.AddApplicationServices();
builder.Services.AddJwtAuthentication(builder.Configuration);

builder.Services.AddAuthorization();

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

<<<<<<< Updated upstream
app.UseCors();

app.UseAuthentication();
=======
app.UseCors("AllowAll");

app.UseStaticFiles(); // Cho phép truy cập file trong wwwroot (ảnh đại diện)

>>>>>>> Stashed changes
app.UseAuthorization();

app.MapControllers();

app.Run();
