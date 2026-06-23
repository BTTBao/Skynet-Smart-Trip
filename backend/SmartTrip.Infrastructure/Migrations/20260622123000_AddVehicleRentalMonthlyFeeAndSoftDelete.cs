using System;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SmartTrip.Infrastructure.Migrations
{
    [DbContext(typeof(ApplicationDbContext))]
    [Migration("20260622123000_AddVehicleRentalMonthlyFeeAndSoftDelete")]
    public partial class AddVehicleRentalMonthlyFeeAndSoftDelete : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<bool>(
                name: "IsDeleted",
                table: "VehicleRentalShops",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<bool>(
                name: "IsMonthlyFeePaid",
                table: "VehicleRentalShops",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<DateTime>(
                name: "DeletedAt",
                table: "VehicleRentalShops",
                type: "datetime",
                nullable: true);

            migrationBuilder.AddColumn<decimal>(
                name: "MonthlyAgreementFee",
                table: "VehicleRentalShops",
                type: "decimal(18,2)",
                nullable: false,
                defaultValue: 0m);

            migrationBuilder.AddColumn<DateTime>(
                name: "MonthlyFeePaidAt",
                table: "VehicleRentalShops",
                type: "datetime",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_VehicleRentalShops_IsDeleted",
                table: "VehicleRentalShops",
                column: "IsDeleted");
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_VehicleRentalShops_IsDeleted",
                table: "VehicleRentalShops");

            migrationBuilder.DropColumn(
                name: "IsDeleted",
                table: "VehicleRentalShops");

            migrationBuilder.DropColumn(
                name: "IsMonthlyFeePaid",
                table: "VehicleRentalShops");

            migrationBuilder.DropColumn(
                name: "DeletedAt",
                table: "VehicleRentalShops");

            migrationBuilder.DropColumn(
                name: "MonthlyAgreementFee",
                table: "VehicleRentalShops");

            migrationBuilder.DropColumn(
                name: "MonthlyFeePaidAt",
                table: "VehicleRentalShops");
        }
    }
}
