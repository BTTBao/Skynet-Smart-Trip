using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SmartTrip.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddExploreModule : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "ExplorePosts",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    AuthorId = table.Column<int>(type: "int", nullable: false),
                    Title = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: false),
                    Excerpt = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: false),
                    Content = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    ThumbnailUrl = table.Column<string>(type: "varchar(500)", unicode: false, maxLength: 500, nullable: true),
                    Location = table.Column<string>(type: "nvarchar(120)", maxLength: 120, nullable: false),
                    CitySlug = table.Column<string>(type: "varchar(80)", unicode: false, maxLength: 80, nullable: false),
                    Province = table.Column<string>(type: "nvarchar(120)", maxLength: 120, nullable: false),
                    Region = table.Column<string>(type: "varchar(20)", unicode: false, maxLength: 20, nullable: false),
                    CostLevel = table.Column<int>(type: "int", nullable: false, defaultValue: 2),
                    AverageRating = table.Column<decimal>(type: "decimal(3,2)", nullable: false, defaultValue: 0m),
                    RatingCount = table.Column<int>(type: "int", nullable: false, defaultValue: 0),
                    ViewCount = table.Column<int>(type: "int", nullable: false, defaultValue: 0),
                    Tags = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "datetime", nullable: false, defaultValueSql: "GETDATE()"),
                    UpdatedAt = table.Column<DateTime>(type: "datetime", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ExplorePosts", x => x.Id);
                    table.ForeignKey(
                        name: "FK_ExplorePosts_Users_AuthorId",
                        column: x => x.AuthorId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "ExploreComments",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    ExplorePostId = table.Column<int>(type: "int", nullable: false),
                    UserId = table.Column<int>(type: "int", nullable: false),
                    Content = table.Column<string>(type: "nvarchar(1000)", maxLength: 1000, nullable: false),
                    LikeCount = table.Column<int>(type: "int", nullable: false, defaultValue: 0),
                    CreatedAt = table.Column<DateTime>(type: "datetime", nullable: false, defaultValueSql: "GETDATE()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ExploreComments", x => x.Id);
                    table.ForeignKey(
                        name: "FK_ExploreComments_ExplorePosts_ExplorePostId",
                        column: x => x.ExplorePostId,
                        principalTable: "ExplorePosts",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_ExploreComments_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "ExplorePostImages",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    ExplorePostId = table.Column<int>(type: "int", nullable: false),
                    ImageUrl = table.Column<string>(type: "varchar(500)", unicode: false, maxLength: 500, nullable: false),
                    SortOrder = table.Column<int>(type: "int", nullable: false, defaultValue: 0)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ExplorePostImages", x => x.Id);
                    table.ForeignKey(
                        name: "FK_ExplorePostImages_ExplorePosts_ExplorePostId",
                        column: x => x.ExplorePostId,
                        principalTable: "ExplorePosts",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "ExplorePostLikes",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    ExplorePostId = table.Column<int>(type: "int", nullable: false),
                    UserId = table.Column<int>(type: "int", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime", nullable: false, defaultValueSql: "GETDATE()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ExplorePostLikes", x => x.Id);
                    table.ForeignKey(
                        name: "FK_ExplorePostLikes_ExplorePosts_ExplorePostId",
                        column: x => x.ExplorePostId,
                        principalTable: "ExplorePosts",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_ExplorePostLikes_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "ExplorePostRatings",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    ExplorePostId = table.Column<int>(type: "int", nullable: false),
                    UserId = table.Column<int>(type: "int", nullable: false),
                    Rating = table.Column<decimal>(type: "decimal(3,2)", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime", nullable: false, defaultValueSql: "GETDATE()"),
                    UpdatedAt = table.Column<DateTime>(type: "datetime", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ExplorePostRatings", x => x.Id);
                    table.ForeignKey(
                        name: "FK_ExplorePostRatings_ExplorePosts_ExplorePostId",
                        column: x => x.ExplorePostId,
                        principalTable: "ExplorePosts",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_ExplorePostRatings_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "ExplorePostSaves",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    ExplorePostId = table.Column<int>(type: "int", nullable: false),
                    UserId = table.Column<int>(type: "int", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime", nullable: false, defaultValueSql: "GETDATE()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ExplorePostSaves", x => x.Id);
                    table.ForeignKey(
                        name: "FK_ExplorePostSaves_ExplorePosts_ExplorePostId",
                        column: x => x.ExplorePostId,
                        principalTable: "ExplorePosts",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_ExplorePostSaves_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateIndex(
                name: "IX_ExploreComments_ExplorePostId_CreatedAt",
                table: "ExploreComments",
                columns: new[] { "ExplorePostId", "CreatedAt" });

            migrationBuilder.CreateIndex(
                name: "IX_ExploreComments_UserId",
                table: "ExploreComments",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_ExplorePostImages_ExplorePostId_SortOrder",
                table: "ExplorePostImages",
                columns: new[] { "ExplorePostId", "SortOrder" });

            migrationBuilder.CreateIndex(
                name: "IX_ExplorePostLikes_ExplorePostId",
                table: "ExplorePostLikes",
                column: "ExplorePostId");

            migrationBuilder.CreateIndex(
                name: "IX_ExplorePostLikes_UserId_ExplorePostId",
                table: "ExplorePostLikes",
                columns: new[] { "UserId", "ExplorePostId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_ExplorePostRatings_ExplorePostId",
                table: "ExplorePostRatings",
                column: "ExplorePostId");

            migrationBuilder.CreateIndex(
                name: "IX_ExplorePostRatings_UserId_ExplorePostId",
                table: "ExplorePostRatings",
                columns: new[] { "UserId", "ExplorePostId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_ExplorePosts_AuthorId",
                table: "ExplorePosts",
                column: "AuthorId");

            migrationBuilder.CreateIndex(
                name: "IX_ExplorePosts_AverageRating",
                table: "ExplorePosts",
                column: "AverageRating");

            migrationBuilder.CreateIndex(
                name: "IX_ExplorePosts_CitySlug",
                table: "ExplorePosts",
                column: "CitySlug");

            migrationBuilder.CreateIndex(
                name: "IX_ExplorePosts_CostLevel",
                table: "ExplorePosts",
                column: "CostLevel");

            migrationBuilder.CreateIndex(
                name: "IX_ExplorePosts_CreatedAt",
                table: "ExplorePosts",
                column: "CreatedAt");

            migrationBuilder.CreateIndex(
                name: "IX_ExplorePosts_Province",
                table: "ExplorePosts",
                column: "Province");

            migrationBuilder.CreateIndex(
                name: "IX_ExplorePosts_Region",
                table: "ExplorePosts",
                column: "Region");

            migrationBuilder.CreateIndex(
                name: "IX_ExplorePosts_ViewCount",
                table: "ExplorePosts",
                column: "ViewCount");

            migrationBuilder.CreateIndex(
                name: "IX_ExplorePostSaves_ExplorePostId",
                table: "ExplorePostSaves",
                column: "ExplorePostId");

            migrationBuilder.CreateIndex(
                name: "IX_ExplorePostSaves_UserId_ExplorePostId",
                table: "ExplorePostSaves",
                columns: new[] { "UserId", "ExplorePostId" },
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "ExploreComments");

            migrationBuilder.DropTable(
                name: "ExplorePostImages");

            migrationBuilder.DropTable(
                name: "ExplorePostLikes");

            migrationBuilder.DropTable(
                name: "ExplorePostRatings");

            migrationBuilder.DropTable(
                name: "ExplorePostSaves");

            migrationBuilder.DropTable(
                name: "ExplorePosts");
        }
    }
}
