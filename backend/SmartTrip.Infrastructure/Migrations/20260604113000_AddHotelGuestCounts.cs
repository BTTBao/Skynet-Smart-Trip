using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SmartTrip.Infrastructure.Migrations;

public partial class AddHotelGuestCounts : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.AddColumn<int>(
            name: "AdultCount",
            table: "TripItineraries",
            type: "int",
            nullable: false,
            defaultValue: 1);

        migrationBuilder.AddColumn<int>(
            name: "ChildCount",
            table: "TripItineraries",
            type: "int",
            nullable: false,
            defaultValue: 0);

        migrationBuilder.AddColumn<int>(
            name: "InfantCount",
            table: "TripItineraries",
            type: "int",
            nullable: false,
            defaultValue: 0);
    }

    protected override void Down(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.DropColumn(name: "AdultCount", table: "TripItineraries");
        migrationBuilder.DropColumn(name: "ChildCount", table: "TripItineraries");
        migrationBuilder.DropColumn(name: "InfantCount", table: "TripItineraries");
    }
}
