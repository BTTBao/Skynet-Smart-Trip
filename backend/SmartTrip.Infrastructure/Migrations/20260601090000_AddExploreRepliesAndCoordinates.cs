using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SmartTrip.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddExploreRepliesAndCoordinates : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<double>(
                name: "Latitude",
                table: "ExplorePosts",
                type: "float",
                nullable: true);

            migrationBuilder.AddColumn<double>(
                name: "Longitude",
                table: "ExplorePosts",
                type: "float",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "ParentCommentId",
                table: "ExploreComments",
                type: "int",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_ExploreComments_ParentCommentId",
                table: "ExploreComments",
                column: "ParentCommentId");

            migrationBuilder.AddForeignKey(
                name: "FK_ExploreComments_ExploreComments_ParentCommentId",
                table: "ExploreComments",
                column: "ParentCommentId",
                principalTable: "ExploreComments",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_ExploreComments_ExploreComments_ParentCommentId",
                table: "ExploreComments");

            migrationBuilder.DropIndex(
                name: "IX_ExploreComments_ParentCommentId",
                table: "ExploreComments");

            migrationBuilder.DropColumn(
                name: "Latitude",
                table: "ExplorePosts");

            migrationBuilder.DropColumn(
                name: "Longitude",
                table: "ExplorePosts");

            migrationBuilder.DropColumn(
                name: "ParentCommentId",
                table: "ExploreComments");
        }
    }
}
