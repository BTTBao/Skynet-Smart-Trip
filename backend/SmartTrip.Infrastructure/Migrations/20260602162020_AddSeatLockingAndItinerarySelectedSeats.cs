using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SmartTrip.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddSeatLockingAndItinerarySelectedSeats : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "SelectedSeats",
                table: "TripItineraries",
                type: "nvarchar(max)",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "LockedByTripId",
                table: "Seats",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "LockedUntil",
                table: "Seats",
                type: "datetime2",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "SelectedSeats",
                table: "TripItineraries");

            migrationBuilder.DropColumn(
                name: "LockedByTripId",
                table: "Seats");

            migrationBuilder.DropColumn(
                name: "LockedUntil",
                table: "Seats");
        }
    }
}
