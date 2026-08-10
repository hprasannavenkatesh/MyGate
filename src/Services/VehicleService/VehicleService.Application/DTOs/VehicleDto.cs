using VehicleService.Domain.Enums;

namespace VehicleService.Application.DTOs;

public record VehicleDto(
    Guid Id,
    string VehicleNumber,
    VehicleType VehicleType,
    string? MakeModel,
    string? AssignedSlotNumber,
    bool HasParkingSlot);