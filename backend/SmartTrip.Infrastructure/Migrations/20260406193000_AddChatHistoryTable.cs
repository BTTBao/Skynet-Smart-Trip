using System;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SmartTrip.Infrastructure.Migrations
{
    [DbContext(typeof(ApplicationDbContext))]
    [Migration("20260406193000_AddChatHistoryTable")]
    public partial class AddChatHistoryTable : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql(
                @"
IF OBJECT_ID(N'[ChatHistories]', N'U') IS NULL
BEGIN
    CREATE TABLE [ChatHistories]
    (
        [Id] INT NOT NULL IDENTITY(1,1),
        [UserId] INT NOT NULL,
        [UserMessage] NVARCHAR(MAX) NOT NULL,
        [BotResponse] NVARCHAR(MAX) NOT NULL,
        [ResponseType] NVARCHAR(50) NULL,
        [ResponseDataJson] NVARCHAR(MAX) NULL,
        [DetectedIntent] NVARCHAR(50) NULL,
        [SessionId] VARCHAR(100) NULL,
        [CreatedAt] DATETIME NOT NULL CONSTRAINT [DF_ChatHistories_CreatedAt] DEFAULT (GETDATE()),
        CONSTRAINT [PK_ChatHistories] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_ChatHistories_Users_UserId] FOREIGN KEY ([UserId]) REFERENCES [Users]([Id]) ON DELETE CASCADE
    );

    CREATE INDEX [IX_ChatHistories_UserId] ON [ChatHistories]([UserId]);
    CREATE INDEX [IX_ChatHistories_UserId_SessionId_CreatedAt] ON [ChatHistories]([UserId], [SessionId], [CreatedAt]);
END");
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql(
                @"
IF OBJECT_ID(N'[ChatHistories]', N'U') IS NOT NULL
BEGIN
    DROP TABLE [ChatHistories];
END");
        }
    }
}
