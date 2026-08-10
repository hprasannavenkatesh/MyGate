using VehicleService.Domain.Enums;

namespace VehicleService.Application.DTOs;

public record ParkingSlotDto(
    Guid Id,
    string SlotNumber,
    VehicleType SlotType,
    Guid? BlockId,
    Guid? FlatId,       // NEW
    bool IsAllotted,     // NEW (Helper: true if FlatId has a value)
    bool IsOccupied);
    