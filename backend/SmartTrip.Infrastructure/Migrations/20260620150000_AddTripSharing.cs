using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SmartTrip.Infrastructure.Migrations
{
    /// <inheritdoc />
    [DbContext(typeof(ApplicationDbContext))]
    [Migration("20260620150000_AddTripSharing")]
    public partial class AddTripSharing : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "ShareCode",
                table: "Trips",
                type: "varchar(20)",
                unicode: false,
                maxLength: 20,
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "SharedFromTripId",
                table: "Trips",
                type: "int",
                nullable: true);

            migrationBuilder.Sql("UPDATE Trips SET ShareCode = CONCAT('TRIP-', RIGHT('00000000' + CONVERT(varchar(8), Id), 8)) WHERE ShareCode IS NULL");

            migrationBuilder.CreateIndex(
                name: "IX_Trips_ShareCode",
                table: "Trips",
                column: "ShareCode",
                unique: true,
                filter: "[ShareCode] IS NOT NULL");

            migrationBuilder.CreateIndex(
                name: "IX_Trips_SharedFromTripId",
                table: "Trips",
                column: "SharedFromTripId");

            migrationBuilder.CreateIndex(
                name: "IX_Trips_UserId_SharedFromTripId",
                table: "Trips",
                columns: new[] { "UserId", "SharedFromTripId" },
                unique: true,
                filter: "[SharedFromTripId] IS NOT NULL");

            migrationBuilder.AddForeignKey(
                name: "FK_Trips_Trips_SharedFromTripId",
                table: "Trips",
                column: "SharedFromTripId",
                principalTable: "Trips",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Trips_Trips_SharedFromTripId",
                table: "Trips");

            migrationBuilder.DropIndex(
                name: "IX_Trips_ShareCode",
                table: "Trips");

            migrationBuilder.DropIndex(
                name: "IX_Trips_SharedFromTripId",
                table: "Trips");

            migrationBuilder.DropIndex(
                name: "IX_Trips_UserId_SharedFromTripId",
                table: "Trips");

            migrationBuilder.DropColumn(
                name: "ShareCode",
                table: "Trips");

            migrationBuilder.DropColumn(
                name: "SharedFromTripId",
                table: "Trips");
        }
    }
}
