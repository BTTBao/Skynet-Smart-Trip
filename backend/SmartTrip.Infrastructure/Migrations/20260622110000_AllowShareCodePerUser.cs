using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SmartTrip.Infrastructure.Migrations
{
    /// <inheritdoc />
    [DbContext(typeof(ApplicationDbContext))]
    [Migration("20260622110000_AllowShareCodePerUser")]
    public partial class AllowShareCodePerUser : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_Trips_ShareCode",
                table: "Trips");

            migrationBuilder.CreateIndex(
                name: "IX_Trips_UserId_ShareCode",
                table: "Trips",
                columns: new[] { "UserId", "ShareCode" },
                unique: true,
                filter: "[ShareCode] IS NOT NULL AND [UserId] IS NOT NULL");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_Trips_UserId_ShareCode",
                table: "Trips");

            migrationBuilder.CreateIndex(
                name: "IX_Trips_ShareCode",
                table: "Trips",
                column: "ShareCode",
                unique: true,
                filter: "[ShareCode] IS NOT NULL");
        }
    }
}
