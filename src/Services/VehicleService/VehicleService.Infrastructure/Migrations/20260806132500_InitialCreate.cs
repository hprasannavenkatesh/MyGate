using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace VehicleService.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class InitialCreate : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "ParkingSlots",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    SocietyId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    SlotNumber = table.Column<string>(type: "nvarchar(20)", maxLength: 20, nullable: false),
                    SlotType = table.Column<int>(type: "int", nullable: false),
                    BlockId = table.Column<Guid>(type: "uniqueidentifier", nullable: true),
                    FlatId = table.Column<Guid>(type: "uniqueidentifier", nullable: true),
                    BlockName = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    IsOccupied = table.Column<bool>(type: "bit", nullable: false),
                    CreatedAt = table.Column<DateTimeOffset>(type: "datetimeoffset", nullable: false),
                    UpdatedAt = table.Column<DateTimeOffset>(type: "datetimeoffset", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ParkingSlots", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "Vehicles",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    SocietyId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    OwnerId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    FlatId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    VehicleType = table.Column<int>(type: "int", nullable: false),
                    Category = table.Column<int>(type: "int", nullable: false),
                    VehicleNumber = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    MakeModel = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    CheckInTime = table.Column<DateTimeOffset>(type: "datetimeoffset", nullable: true),
                    ExpectedCheckOutTime = table.Column<DateTimeOffset>(type: "datetimeoffset", nullable: true),
                    ParkingSlotId = table.Column<Guid>(type: "uniqueidentifier", nullable: true),
                    CreatedAt = table.Column<DateTimeOffset>(type: "datetimeoffset", nullable: false),
                    UpdatedAt = table.Column<DateTimeOffset>(type: "datetimeoffset", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Vehicles", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Vehicles_ParkingSlots_ParkingSlotId",
                        column: x => x.ParkingSlotId,
                        principalTable: "ParkingSlots",
                        principalColumn: "Id");
                });

            migrationBuilder.CreateIndex(
                name: "IX_ParkingSlots_BlockId",
                table: "ParkingSlots",
                column: "BlockId");

            migrationBuilder.CreateIndex(
                name: "IX_ParkingSlots_FlatId",
                table: "ParkingSlots",
                column: "FlatId");

            migrationBuilder.CreateIndex(
                name: "IX_ParkingSlots_SocietyId_SlotNumber",
                table: "ParkingSlots",
                columns: new[] { "SocietyId", "SlotNumber" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Vehicles_ParkingSlotId",
                table: "Vehicles",
                column: "ParkingSlotId",
                unique: true,
                filter: "[ParkingSlotId] IS NOT NULL");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "Vehicles");

            migrationBuilder.DropTable(
                name: "ParkingSlots");
        }
    }
}
