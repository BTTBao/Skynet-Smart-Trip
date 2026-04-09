using System;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SmartTrip.Infrastructure.Migrations
{
    [DbContext(typeof(ApplicationDbContext))]
    [Migration("20260406110000_AddUserBirthDate")]
    public partial class AddUserBirthDate : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql(
                """
                IF COL_LENGTH('dbo.Users', 'BirthDate') IS NULL
                BEGIN
                    ALTER TABLE [dbo].[Users] ADD [BirthDate] date NULL;
                END
                """);

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

            migrationBuilder.Sql(
                """
                IF COL_LENGTH('dbo.Users', 'BirthDate') IS NOT NULL
                BEGIN
                    ALTER TABLE [dbo].[Users] DROP COLUMN [BirthDate];
                END
                """);
        }
    }
}
