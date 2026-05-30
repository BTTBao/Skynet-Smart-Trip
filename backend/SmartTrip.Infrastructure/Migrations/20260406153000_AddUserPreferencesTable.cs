using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SmartTrip.Infrastructure.Migrations
{
    [DbContext(typeof(ApplicationDbContext))]
    [Migration("20260406153000_AddUserPreferencesTable")]
    public partial class AddUserPreferencesTable : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql(
                """
                IF OBJECT_ID(N'[dbo].[UserPreferences]', N'U') IS NULL
                BEGIN
                    CREATE TABLE [dbo].[UserPreferences]
                    (
                        [Id] int NOT NULL IDENTITY,
                        [UserId] int NOT NULL,
                        [PreferenceKey] nvarchar(100) NOT NULL,
                        [PreferenceValue] nvarchar(500) NOT NULL,
                        [UpdatedAt] datetime NOT NULL CONSTRAINT [DF_UserPreferences_UpdatedAt] DEFAULT (GETDATE()),
                        CONSTRAINT [PK_UserPreferences] PRIMARY KEY ([Id]),
                        CONSTRAINT [FK_UserPreferences_Users_UserId] FOREIGN KEY ([UserId]) REFERENCES [dbo].[Users] ([Id]) ON DELETE CASCADE
                    );

                    CREATE UNIQUE INDEX [IX_UserPreferences_UserId_PreferenceKey]
                        ON [dbo].[UserPreferences] ([UserId], [PreferenceKey]);
                END
                """);
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql(
                """
                IF OBJECT_ID(N'[dbo].[UserPreferences]', N'U') IS NOT NULL
                BEGIN
                    DROP TABLE [dbo].[UserPreferences];
                END
                """);
        }
    }
}
