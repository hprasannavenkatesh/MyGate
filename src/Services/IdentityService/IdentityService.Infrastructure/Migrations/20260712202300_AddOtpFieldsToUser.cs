using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace IdentityService.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddOtpFieldsToUser : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<DateTime>(
                name: "OtpExpiresAt",
                table: "Users",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "OtpHash",
                table: "Users",
                type: "nvarchar(max)",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "OtpExpiresAt",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "OtpHash",
                table: "Users");
        }
    }
}
