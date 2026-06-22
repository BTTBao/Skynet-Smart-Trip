using System;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SmartTrip.Infrastructure.Migrations
{
    /// <inheritdoc />
    [DbContext(typeof(ApplicationDbContext))]
    [Migration("20260606010000_AddHotelCheckOutDateToTripItineraries")]
    public partial class AddHotelCheckOutDateToTripItineraries : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql("""
                IF COL_LENGTH('TripItineraries', 'HotelCheckOutDate') IS NULL
                BEGIN
                    ALTER TABLE [TripItineraries] ADD [HotelCheckOutDate] date NULL;
                END
                """);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql("""
                IF COL_LENGTH('TripItineraries', 'HotelCheckOutDate') IS NOT NULL
                BEGIN
                    ALTER TABLE [TripItineraries] DROP COLUMN [HotelCheckOutDate];
                END
                """);
        }
    }
}
