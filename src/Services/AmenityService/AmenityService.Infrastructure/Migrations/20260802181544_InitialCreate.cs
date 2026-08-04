using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace AmenityService.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class InitialCreate : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "Amenities",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    SocietyId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    Name = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    Description = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: true),
                    Location = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: true),
                    IsActive = table.Column<bool>(type: "bit", nullable: false),
                    IsBookable = table.Column<bool>(type: "bit", nullable: false),
                    SlotDurationMinutes = table.Column<int>(type: "int", nullable: false),
                    MaxBookingsPerDayPerUser = table.Column<int>(type: "int", nullable: false, defaultValue: 1),
                    AdvanceBookingDaysAllowed = table.Column<int>(type: "int", nullable: false, defaultValue: 7),
                    OperatingHoursStart = table.Column<TimeOnly>(type: "time", nullable: false),
                    OperatingHoursEnd = table.Column<TimeOnly>(type: "time", nullable: false),
                    CreatedAt = table.Column<DateTimeOffset>(type: "datetimeoffset", nullable: false),
                    UpdatedAt = table.Column<DateTimeOffset>(type: "datetimeoffset", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Amenities", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "AmenityBookings",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    AmenityId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    SocietyId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    UserId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    FlatNumber = table.Column<string>(type: "nvarchar(20)", maxLength: 20, nullable: false),
                    BookingDate = table.Column<DateOnly>(type: "date", nullable: false),
                    StartTime = table.Column<TimeOnly>(type: "time", nullable: false),
                    EndTime = table.Column<TimeOnly>(type: "time", nullable: false),
                    Status = table.Column<string>(type: "nvarchar(20)", maxLength: 20, nullable: false),
                    Notes = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: true),
                    ApprovedBy = table.Column<Guid>(type: "uniqueidentifier", nullable: true),
                    ApprovedAt = table.Column<DateTimeOffset>(type: "datetimeoffset", nullable: true),
                    RejectionReason = table.Column<string>(type: "nvarchar(300)", maxLength: 300, nullable: true),
                    CreatedAt = table.Column<DateTimeOffset>(type: "datetimeoffset", nullable: false),
                    UpdatedAt = table.Column<DateTimeOffset>(type: "datetimeoffset", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_AmenityBookings", x => x.Id);
                    table.ForeignKey(
                        name: "FK_AmenityBookings_Amenities_AmenityId",
                        column: x => x.AmenityId,
                        principalTable: "Amenities",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateIndex(
                name: "IX_Amenities_SocietyId",
                table: "Amenities",
                column: "SocietyId");

            migrationBuilder.CreateIndex(
                name: "IX_Amenities_SocietyId_IsActive",
                table: "Amenities",
                columns: new[] { "SocietyId", "IsActive" });

            migrationBuilder.CreateIndex(
                name: "IX_AmenityBookings_AmenityId",
                table: "AmenityBookings",
                column: "AmenityId");

            migrationBuilder.CreateIndex(
                name: "IX_AmenityBookings_AmenityId_BookingDate",
                table: "AmenityBookings",
                columns: new[] { "AmenityId", "BookingDate" });

            migrationBuilder.CreateIndex(
                name: "IX_AmenityBookings_SocietyId",
                table: "AmenityBookings",
                column: "SocietyId");

            migrationBuilder.CreateIndex(
                name: "IX_AmenityBookings_SocietyId_Status",
                table: "AmenityBookings",
                columns: new[] { "SocietyId", "Status" });

            migrationBuilder.CreateIndex(
                name: "IX_AmenityBookings_UserId",
                table: "AmenityBookings",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_AmenityBookings_UserId_AmenityId_BookingDate",
                table: "AmenityBookings",
                columns: new[] { "UserId", "AmenityId", "BookingDate" });

            migrationBuilder.CreateIndex(
                name: "IX_AmenityBookings_UserId_SocietyId",
                table: "AmenityBookings",
                columns: new[] { "UserId", "SocietyId" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "AmenityBookings");

            migrationBuilder.DropTable(
                name: "Amenities");
        }
    }
}
