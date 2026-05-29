using System;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SmartTrip.Infrastructure.Migrations
{
    [DbContext(typeof(ApplicationDbContext))]
    [Migration("20260527143000_AddPayOsPaymentFields")]
    public partial class AddPayOsPaymentFields : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AlterColumn<DateTime>(
                name: "PaidAt",
                table: "Payments",
                type: "datetime",
                nullable: true,
                oldClrType: typeof(DateTime),
                oldType: "datetime",
                oldNullable: true,
                oldDefaultValueSql: "GETDATE()");

            migrationBuilder.AddColumn<string>(
                name: "CancelUrl",
                table: "Payments",
                type: "varchar(2048)",
                unicode: false,
                maxLength: 2048,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "CheckoutUrl",
                table: "Payments",
                type: "varchar(2048)",
                unicode: false,
                maxLength: 2048,
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "CreatedAt",
                table: "Payments",
                type: "datetime",
                nullable: true,
                defaultValueSql: "GETDATE()");

            migrationBuilder.AddColumn<string>(
                name: "Description",
                table: "Payments",
                type: "nvarchar(255)",
                maxLength: 255,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "MetadataJson",
                table: "Payments",
                type: "nvarchar(max)",
                nullable: true);

            migrationBuilder.AddColumn<long>(
                name: "OrderCode",
                table: "Payments",
                type: "bigint",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "PaymentLinkId",
                table: "Payments",
                type: "varchar(100)",
                unicode: false,
                maxLength: 100,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "QrCode",
                table: "Payments",
                type: "nvarchar(max)",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "RawResponseJson",
                table: "Payments",
                type: "nvarchar(max)",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "ReturnUrl",
                table: "Payments",
                type: "varchar(2048)",
                unicode: false,
                maxLength: 2048,
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "UpdatedAt",
                table: "Payments",
                type: "datetime",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_Payments_OrderCode",
                table: "Payments",
                column: "OrderCode",
                unique: true,
                filter: "[OrderCode] IS NOT NULL");
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_Payments_OrderCode",
                table: "Payments");

            migrationBuilder.DropColumn(
                name: "CancelUrl",
                table: "Payments");

            migrationBuilder.DropColumn(
                name: "CheckoutUrl",
                table: "Payments");

            migrationBuilder.DropColumn(
                name: "CreatedAt",
                table: "Payments");

            migrationBuilder.DropColumn(
                name: "Description",
                table: "Payments");

            migrationBuilder.DropColumn(
                name: "MetadataJson",
                table: "Payments");

            migrationBuilder.DropColumn(
                name: "OrderCode",
                table: "Payments");

            migrationBuilder.DropColumn(
                name: "PaymentLinkId",
                table: "Payments");

            migrationBuilder.DropColumn(
                name: "QrCode",
                table: "Payments");

            migrationBuilder.DropColumn(
                name: "RawResponseJson",
                table: "Payments");

            migrationBuilder.DropColumn(
                name: "ReturnUrl",
                table: "Payments");

            migrationBuilder.DropColumn(
                name: "UpdatedAt",
                table: "Payments");

            migrationBuilder.AlterColumn<DateTime>(
                name: "PaidAt",
                table: "Payments",
                type: "datetime",
                nullable: true,
                defaultValueSql: "GETDATE()",
                oldClrType: typeof(DateTime),
                oldType: "datetime",
                oldNullable: true);
        }
    }
}
