using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SmartTrip.Infrastructure.Migrations
{
    /// <inheritdoc />
    [DbContext(typeof(ApplicationDbContext))]
    [Migration("20260621090000_AddChatHistoryTelemetryColumns")]
    public partial class AddChatHistoryTelemetryColumns : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "ClassifierDetails",
                table: "ChatHistories",
                type: "nvarchar(max)",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "ErrorLog",
                table: "ChatHistories",
                type: "nvarchar(1000)",
                maxLength: 1000,
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "IsFallbackUsed",
                table: "ChatHistories",
                type: "bit",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "IsJsonValid",
                table: "ChatHistories",
                type: "bit",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "LatencyMs",
                table: "ChatHistories",
                type: "int",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "ClassifierDetails",
                table: "ChatHistories");

            migrationBuilder.DropColumn(
                name: "ErrorLog",
                table: "ChatHistories");

            migrationBuilder.DropColumn(
                name: "IsFallbackUsed",
                table: "ChatHistories");

            migrationBuilder.DropColumn(
                name: "IsJsonValid",
                table: "ChatHistories");

            migrationBuilder.DropColumn(
                name: "LatencyMs",
                table: "ChatHistories");
        }
    }
}