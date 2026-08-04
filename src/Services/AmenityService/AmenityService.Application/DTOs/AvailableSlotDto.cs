namespace AmenityService.Application.DTOs;

public record AvailableSlotDto(
    string StartTime,
    string EndTime,
    bool IsAvailable);