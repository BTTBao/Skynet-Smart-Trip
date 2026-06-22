using System;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SmartTrip.Infrastructure.Migrations
{
    /// <inheritdoc />
    [DbContext(typeof(ApplicationDbContext))]
    [Migration("20260622100000_AddVehicleRentalModule")]
    public partial class AddVehicleRentalModule : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "VehicleRentalShops",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Name = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: false),
                    PhoneNumber = table.Column<string>(type: "varchar(20)", unicode: false, maxLength: 20, nullable: false),
                    Address = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: false),
                    DestinationId = table.Column<int>(type: "int", nullable: false),
                    Description = table.Column<string>(type: "nvarchar(1000)", maxLength: 1000, nullable: true),
                    ImageUrl = table.Column<string>(type: "varchar(500)", unicode: false, maxLength: 500, nullable: true),
                    IsActive = table.Column<bool>(type: "bit", nullable: false, defaultValue: true),
                    CreatedAt = table.Column<DateTime>(type: "datetime", nullable: false, defaultValueSql: "GETDATE()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_VehicleRentalShops", x => x.Id);
                    table.ForeignKey(
                        name: "FK_VehicleRentalShops_Destinations_DestinationId",
                        column: x => x.DestinationId,
                        principalTable: "Destinations",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "VehicleRentalOptions",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    VehicleRentalShopId = table.Column<int>(type: "int", nullable: false),
                    VehicleType = table.Column<string>(type: "varchar(30)", unicode: false, maxLength: 30, nullable: false),
                    MaxSeats = table.Column<int>(type: "int", nullable: true),
                    PricePerDay = table.Column<decimal>(type: "decimal(18,2)", nullable: false),
                    IsAvailable = table.Column<bool>(type: "bit", nullable: false, defaultValue: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_VehicleRentalOptions", x => x.Id);
                    table.ForeignKey(
                        name: "FK_VehicleRentalOptions_VehicleRentalShops_VehicleRentalShopId",
                        column: x => x.VehicleRentalShopId,
                        principalTable: "VehicleRentalShops",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_VehicleRentalShops_DestinationId",
                table: "VehicleRentalShops",
                column: "DestinationId");

            migrationBuilder.CreateIndex(
                name: "IX_VehicleRentalShops_IsActive",
                table: "VehicleRentalShops",
                column: "IsActive");

            migrationBuilder.CreateIndex(
                name: "IX_VehicleRentalOptions_VehicleRentalShopId",
                table: "VehicleRentalOptions",
                column: "VehicleRentalShopId");

            migrationBuilder.CreateIndex(
                name: "IX_VehicleRentalOptions_VehicleType",
                table: "VehicleRentalOptions",
                column: "VehicleType");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "VehicleRentalOptions");

            migrationBuilder.DropTable(
                name: "VehicleRentalShops");
        }
    }
}
