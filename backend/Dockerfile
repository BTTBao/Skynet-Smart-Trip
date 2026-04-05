# Stage 1: Build
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /app

# Copy các file .csproj của từng project và restore dependencies
COPY ["SmartTrip.API/SmartTrip.API.csproj", "SmartTrip.API/"]
COPY ["SmartTrip.Application/SmartTrip.Application.csproj", "SmartTrip.Application/"]
COPY ["SmartTrip.Domain/SmartTrip.Domain.csproj", "SmartTrip.Domain/"]
COPY ["SmartTrip.Infrastructure/SmartTrip.Infrastructure.csproj", "SmartTrip.Infrastructure/"]
RUN dotnet restore "SmartTrip.API/SmartTrip.API.csproj"

# Copy toàn bộ source code của backend và tiến hành build
COPY . .
WORKDIR "/app/SmartTrip.API"
RUN dotnet publish "SmartTrip.API.csproj" -c Release -o /app/publish /p:UseAppHost=false

# Stage 2: Serve
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS final
WORKDIR /app
COPY --from=build /app/publish .

# Mở port cho API (mặc định .NET 8 sử dụng port 8080)
EXPOSE 8080

ENTRYPOINT ["dotnet", "SmartTrip.API.dll"]