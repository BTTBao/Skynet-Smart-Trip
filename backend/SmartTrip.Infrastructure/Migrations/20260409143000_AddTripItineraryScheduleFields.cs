using System;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SmartTrip.Infrastructure.Migrations
{
    [DbContext(typeof(ApplicationDbContext))]
    [Migration("20260409143000_AddTripItineraryScheduleFields")]
    public partial class AddTripItineraryScheduleFields : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<TimeOnly>(
                name: "DepartureTime",
                table: "TripItineraries",
                type: "time",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "ServiceAddress",
                table: "TripItineraries",
                type: "nvarchar(500)",
                maxLength: 500,
                nullable: true);

            migrationBuilder.AddColumn<DateOnly>(
                name: "ServiceDate",
                table: "TripItineraries",
                type: "date",
                nullable: true);
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "DepartureTime",
                table: "TripItineraries");

            migrationBuilder.DropColumn(
                name: "ServiceAddress",
                table: "TripItineraries");

            migrationBuilder.DropColumn(
                name: "ServiceDate",
                table: "TripItineraries");
        }
    }
}
